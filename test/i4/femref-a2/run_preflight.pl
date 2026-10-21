#!/usr/bin/perl
use strict;
use warnings;
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use FindBin qw($RealBin);
use File::Spec;
use IO::Handle ();
use POSIX qw(:sys_wait_h setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC alarm clock_gettime sleep);

@ARGV == 0 or die "run_preflight.pl accepts no arguments\n";

my $RUN_ID = 'resource-preflight-001';
my $EXECUTION_ID = 'execution-002';
my $TOTAL_WALL_LIMIT_SECONDS = 2700;
my $PRIOR_WALL_SECONDS = 18.226698;
my $WALL_LIMIT_SECONDS =
  $TOTAL_WALL_LIMIT_SECONDS - $PRIOR_WALL_SECONDS;
my $PRIOR_RSS_BYTES = 1084440576;
my $RSS_LIMIT_BYTES = 3221225472;
my $MATLAB = '/Applications/MATLAB_R2023b.app/bin/matlab';
my $BATCH =
  "run_i4_1b('resource-preflight-001','execution-002')";
my $start = clock_gettime(CLOCK_MONOTONIC);
my $deadline = $start + $WALL_LIMIT_SECONDS;
my $child = 0;
my $wall_reached = 0;
my $resource_handle;
my $resource_event_index = 0;
my $summary_path = '';
my $summary_committed = 0;
my $publication_aborted = 0;
my $peak_rss_bytes = 0;
$SIG{ALRM} = sub {
  kill 'KILL', -$child if $child > 1;
  kill 'KILL', $child if $child > 1;
  my $now = clock_gettime(CLOCK_MONOTONIC);
  if ($summary_path ne '' && -e $summary_path) {
    $summary_committed = 1;
    return;
  }
  if (defined($resource_handle) && !$summary_committed &&
      !($summary_path ne '' && -e $summary_path)) {
    eval {
      append_resource_event($resource_handle, \$resource_event_index,
        'WALL_LIMIT', $now - $start, $peak_rss_bytes,
        'WALL_HARD_LIMIT_REACHED', -1, -1);
      $resource_handle->sync or die "cannot sync resource ledger: $!\n";
    };
  }
  syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
  $wall_reached = 1;
  if (defined($resource_handle) && !$summary_committed) {
    $publication_aborted = 1;
    POSIX::_exit(2);
  }
};
alarm($deadline - clock_gettime(CLOCK_MONOTONIC));

chdir $RealBin or die "cannot chdir to experiment directory: $!\n";
my $output_parent = File::Spec->catdir($RealBin, 'output');
if (!-e $output_parent) {
  mkdir $output_parent or die "cannot create output parent: $!\n";
}
-d $output_parent or die "output parent is unavailable\n";
my $run_dir = File::Spec->catdir($output_parent, $RUN_ID);
if (!-e $run_dir) {
  mkdir $run_dir or die "cannot create resource-preflight-001: $!\n";
}
-d $run_dir or die "resource-preflight-001 is not a directory\n";
my $output_dir = File::Spec->catdir($run_dir, $EXECUTION_ID);
!(-e $output_dir) or die
  "OUTPUT_COLLISION: resource-preflight-001/execution-002 exists\n";
mkdir $output_dir or die "cannot claim preflight execution: $!\n";
my $log_path = File::Spec->catfile($output_dir, 'preflight.log');
$summary_path = File::Spec->catfile($output_dir, 'preflight-summary.tsv');

$child = fork();
defined $child or die "fork failed: $!\n";
if ($child == 0) {
  setpgid(0, 0) == 0 or die "child setpgid failed: $!\n";
  open STDOUT, '>>', $log_path or die "cannot open preflight.log: $!\n";
  open STDERR, '>&', \*STDOUT or die "cannot redirect stderr: $!\n";
  exec {$MATLAB} $MATLAB, '-batch', $BATCH;
  die "exec MATLAB failed: $!\n";
}
setpgid($child, $child);

my $controller_terminal = 'RUNNING';
my $child_reaped = 0;
my $wait_status;
my $dedicated_group_seen = 0;
my $log_offset = 0;
my $current_stage = 'startup';
my %stage_stats = (
  startup => {
    classes => 'controller,matlab-startup', internal_bytes => 0,
    matlab_peak_rss_bytes => 0, aggregate_peak_rss_bytes => 0,
  },
);
my @stage_order = ('startup');

while (1) {
  read_stage_markers($log_path, \$log_offset, \$current_stage,
    \%stage_stats, \@stage_order);
  my $table = process_table();
  my $targets = defined($table) ? target_pids($table, $child) : {};
  my $now = fresh_deadline_check($deadline, \$controller_terminal);
  $controller_terminal = 'WALL_HARD_LIMIT_REACHED' if $wall_reached;
  if ($controller_terminal eq 'WALL_HARD_LIMIT_REACHED') {
    stop_target($child, $targets);
    last;
  }
  if (!defined $table) {
    $controller_terminal = 'RSS_ENFORCEMENT_UNAVAILABLE';
    stop_target($child, {});
    last;
  }
  if (exists $table->{$child}) {
    if ($table->{$child}->{pgid} != $child) {
      $controller_terminal = 'DEDICATED_PROCESS_GROUP_UNAVAILABLE';
      stop_target($child, {$child => 1});
      last;
    }
    $dedicated_group_seen = 1;
  }
  my $rss_bytes = 0;
  my $matlab_rss_bytes = 0;
  for my $pid (keys %{$targets}) {
    my $value = $table->{$pid}->{rss_kib} * 1024;
    $rss_bytes += $value;
    $matlab_rss_bytes = $value if $value > $matlab_rss_bytes;
  }
  $peak_rss_bytes = $rss_bytes if $rss_bytes > $peak_rss_bytes;
  my $cumulative_rss_bytes = $peak_rss_bytes > $PRIOR_RSS_BYTES ?
    $peak_rss_bytes : $PRIOR_RSS_BYTES;
  record_stage_rss(\%stage_stats, $current_stage,
    $matlab_rss_bytes, $rss_bytes);
  if ($cumulative_rss_bytes >= $RSS_LIMIT_BYTES) {
    $controller_terminal = 'RSS_HARD_LIMIT_REACHED';
    stop_target($child, $targets);
    last;
  }
  if (!$child_reaped) {
    my $reaped = waitpid($child, WNOHANG);
    if ($reaped == $child) {
      $child_reaped = 1;
      $wait_status = $?;
    } elsif ($reaped == -1) {
      $controller_terminal = 'CHILD_REAP_UNAVAILABLE';
      stop_target($child, $targets);
      last;
    }
  }
  $now = fresh_deadline_check($deadline, \$controller_terminal);
  $controller_terminal = 'WALL_HARD_LIMIT_REACHED' if $wall_reached;
  if ($controller_terminal eq 'WALL_HARD_LIMIT_REACHED') {
    stop_target($child, $targets);
    last;
  }
  if ($child_reaped && !keys %{$targets}) {
    $controller_terminal = 'NATURAL_EXIT';
    last;
  }
  sleep 0.25;
}

if (!$child_reaped) {
  my $reaped = waitpid($child, 0);
  if ($reaped == $child) {
    $child_reaped = 1;
    $wait_status = $?;
  }
}
read_stage_markers($log_path, \$log_offset, \$current_stage,
  \%stage_stats, \@stage_order);
my $exit_code = defined($wait_status) ? ($wait_status >> 8) : -1;
my $signal = defined($wait_status) ? ($wait_status & 127) : -1;
if ($controller_terminal eq 'NATURAL_EXIT' &&
    (!$dedicated_group_seen || $exit_code != 0 || $signal != 0)) {
  $controller_terminal = 'MATLAB_EXIT_NONZERO';
}
my $preflight_terminal = read_preflight_terminal($log_path);
if ($controller_terminal eq 'NATURAL_EXIT' &&
    $preflight_terminal ne 'PREFLIGHT_COMPLETE') {
  $controller_terminal = 'PREFLIGHT_OUTPUT_INCOMPLETE';
}
my $resource_path = File::Spec->catfile($output_dir, 'resource.tsv');
$resource_handle = open_resource_ledger($resource_path);
append_resource_event($resource_handle, \$resource_event_index,
  'TARGET_EXIT', clock_gettime(CLOCK_MONOTONIC) - $start, $peak_rss_bytes,
  'PUBLICATION_PENDING', $exit_code, $signal);
$resource_handle->sync or die "cannot sync resource ledger: $!\n";
publication_deadline_ok() or exit 2;

my $publication_ok = eval {
  write_residency($output_dir, \%stage_stats, \@stage_order);
  1;
};
if (!$publication_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $peak_rss_bytes, $exit_code, $signal);
  exit 2;
}
publication_deadline_ok() or exit 2;

my ($summary_handle, $summary_partial, $current_elapsed_offset,
  $cumulative_elapsed_offset);
$publication_ok = eval {
  ($summary_handle, $summary_partial, $current_elapsed_offset,
    $cumulative_elapsed_offset) =
    prepare_summary($output_dir, $preflight_terminal,
      $peak_rss_bytes, $controller_terminal);
  1;
};
if (!$publication_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $peak_rss_bytes, $exit_code, $signal);
  exit 2;
}
publication_deadline_ok() or exit 2;

my $final_now = clock_gettime(CLOCK_MONOTONIC);
if ($final_now >= $deadline || $wall_reached) {
  append_wall_event($final_now, $peak_rss_bytes, $exit_code, $signal);
  exit 2;
}
my $final_elapsed = $final_now - $start;
$publication_ok = eval {
  patch_summary_elapsed($summary_handle, $current_elapsed_offset,
    $cumulative_elapsed_offset, $final_elapsed);
  append_resource_event($resource_handle, \$resource_event_index,
    'WHOLE_COMMAND_TERMINAL', $final_elapsed, $peak_rss_bytes,
    $controller_terminal,
    $exit_code, $signal);
  $resource_handle->sync or die "cannot sync resource ledger: $!\n";
  1;
};
if (!$publication_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $peak_rss_bytes, $exit_code, $signal);
  exit 2;
}
publication_deadline_ok() or exit 2;
if (!rename $summary_partial, $summary_path) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $peak_rss_bytes, $exit_code, $signal);
  exit 2;
}
$summary_committed = 1;
alarm(0);
close $resource_handle;
exit($controller_terminal eq 'NATURAL_EXIT' ? 0 : 2);

sub fresh_deadline_check {
  my ($absolute_deadline, $terminal) = @_;
  my $now = clock_gettime(CLOCK_MONOTONIC);
  ${$terminal} = 'WALL_HARD_LIMIT_REACHED'
    if $now >= $absolute_deadline;
  return $now;
}

sub process_table {
  open my $handle, '-|', '/bin/ps', '-axo',
    'pid=,ppid=,pgid=,rss=,state=' or return;
  my %table;
  while (my $line = <$handle>) {
    next if $line =~ /^\s*$/;
    $line =~ s/^\s+|\s+$//g;
    my ($pid, $ppid, $pgid, $rss_kib, $state) = split /\s+/, $line, 5;
    if (!defined($state) || $pid !~ /^\d+$/ || $ppid !~ /^\d+$/ ||
        $pgid !~ /^\d+$/ || $rss_kib !~ /^\d+$/) {
      close $handle;
      return;
    }
    $table{$pid + 0} = {
      ppid => $ppid + 0, pgid => $pgid + 0,
      rss_kib => $rss_kib + 0, state => $state,
    };
  }
  close($handle) or return;
  return \%table;
}

sub target_pids {
  my ($table, $root) = @_;
  my %target;
  $target{$root} = 1 if exists $table->{$root};
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    for my $pid (keys %{$table}) {
      if (exists $target{$table->{$pid}->{ppid}} && !exists $target{$pid}) {
        $target{$pid} = 1;
        $changed = 1;
      }
    }
  }
  for my $pid (keys %{$table}) {
    $target{$pid} = 1 if $table->{$pid}->{pgid} == $root;
  }
  return \%target;
}

sub stop_target {
  my ($root, $targets) = @_;
  kill 'KILL', -$root if $root > 1;
  kill 'KILL', $root if $root > 1;
  for my $pid (keys %{$targets}) {
    kill 'KILL', $pid if $pid > 1;
  }
}

sub read_stage_markers {
  my ($path, $offset, $current, $stats, $order) = @_;
  return if !-f $path;
  open my $handle, '<', $path or return;
  seek $handle, ${$offset}, 0 or do { close $handle; return; };
  while (my $line = <$handle>) {
    if ($line =~ /^PREFLIGHT_STAGE\t([^\t]+)\t([^\t]+)\t(\d+)\s*$/) {
      my ($stage, $classes, $bytes) = ($1, $2, $3 + 0);
      if (!exists $stats->{$stage}) {
        push @{$order}, $stage;
        $stats->{$stage} = {
          classes => $classes, internal_bytes => $bytes,
          matlab_peak_rss_bytes => 0, aggregate_peak_rss_bytes => 0,
        };
      } else {
        $stats->{$stage}->{classes} = $classes;
        $stats->{$stage}->{internal_bytes} = $bytes;
      }
      ${$current} = $stage;
    }
  }
  ${$offset} = tell $handle;
  close $handle;
}

sub record_stage_rss {
  my ($stats, $stage, $matlab, $aggregate) = @_;
  return if !exists $stats->{$stage};
  $stats->{$stage}->{matlab_peak_rss_bytes} = $matlab
    if $matlab > $stats->{$stage}->{matlab_peak_rss_bytes};
  $stats->{$stage}->{aggregate_peak_rss_bytes} = $aggregate
    if $aggregate > $stats->{$stage}->{aggregate_peak_rss_bytes};
}

sub read_preflight_terminal {
  my ($path) = @_;
  return '' if !-f $path;
  open my $handle, '<', $path or return '';
  my $terminal = '';
  while (my $line = <$handle>) {
    $terminal = $1 if $line =~ /^PREFLIGHT_TERMINAL\t([^\s]+)\s*$/;
  }
  close $handle;
  return $terminal;
}

sub exclusive_handle {
  my ($path) = @_;
  sysopen my $handle, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create $path: $!\n";
  return $handle;
}

sub write_all {
  my ($handle, $text) = @_;
  my $offset = 0;
  while ($offset < length($text)) {
    my $written = syswrite($handle, $text, length($text) - $offset, $offset);
    defined($written) && $written > 0
      or die "cannot write publication leaf: $!\n";
    $offset += $written;
  }
}

sub open_resource_ledger {
  my ($path) = @_;
  sysopen my $handle, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create resource ledger: $!\n";
  write_all($handle, join("\t", qw(event_index event_kind
    prior_elapsed_seconds current_execution_elapsed_seconds
    cumulative_elapsed_seconds prior_aggregate_peak_rss_bytes
    current_aggregate_peak_rss_bytes cumulative_aggregate_peak_rss_bytes
    controller_terminal matlab_exit_code matlab_signal)) . "\n");
  return $handle;
}

sub append_resource_event {
  my ($handle, $index, $kind, $elapsed, $peak, $terminal,
      $exit_code, $signal) = @_;
  my $cumulative_elapsed = $PRIOR_WALL_SECONDS + $elapsed;
  my $cumulative_peak = $peak > $PRIOR_RSS_BYTES ?
    $peak : $PRIOR_RSS_BYTES;
  ${$index}++;
  write_all($handle, join("\t", ${$index}, $kind,
    sprintf('%.9f', $PRIOR_WALL_SECONDS), sprintf('%.9f', $elapsed),
    sprintf('%.9f', $cumulative_elapsed), $PRIOR_RSS_BYTES,
    $peak, $cumulative_peak, $terminal,
    $exit_code, $signal) . "\n");
}

sub append_wall_event {
  my ($now, $peak, $exit_code, $signal) = @_;
  $publication_aborted = 1;
  append_resource_event($resource_handle, \$resource_event_index,
    'WALL_LIMIT', $now - $start, $peak, 'WALL_HARD_LIMIT_REACHED',
    $exit_code, $signal);
  $resource_handle->sync or die "cannot sync wall event: $!\n";
  syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
}

sub publication_deadline_ok {
  my $now = clock_gettime(CLOCK_MONOTONIC);
  if ($wall_reached || $publication_aborted || $now >= $deadline) {
    append_wall_event($now, $peak_rss_bytes, $exit_code, $signal)
      if !$publication_aborted;
    return 0;
  }
  return 1;
}

sub publication_failure {
  my ($terminal, $peak, $exit_code, $signal) = @_;
  return if $publication_aborted;
  $publication_aborted = 1;
  eval {
    append_resource_event($resource_handle, \$resource_event_index,
      'PUBLICATION_FAILURE', clock_gettime(CLOCK_MONOTONIC) - $start,
      $peak, $terminal,
      $exit_code, $signal);
    $resource_handle->sync;
  };
  syswrite(STDERR, "$terminal\n");
}

sub write_residency {
  my ($dir, $stats, $order) = @_;
  my $path = File::Spec->catfile($dir, 'residency.tsv');
  my $handle = exclusive_handle($path);
  print {$handle} join("\t", qw(stage simultaneously_live_classes
    internal_object_bytes matlab_peak_rss_bytes
    aggregate_process_tree_peak_rss_bytes)), "\n";
  for my $stage (@{$order}) {
    my $row = $stats->{$stage};
    print {$handle} join("\t", $stage, $row->{classes},
      $row->{internal_bytes}, $row->{matlab_peak_rss_bytes},
      $row->{aggregate_peak_rss_bytes}), "\n";
  }
  close $handle or die "cannot close residency.tsv: $!\n";
}

sub prepare_summary {
  my ($dir, $preflight, $peak, $controller) = @_;
  my $path = File::Spec->catfile($dir, 'preflight-summary.tsv');
  my $partial = "$path.partial";
  my $current_placeholder = '11111111111111111111';
  my $cumulative_placeholder = '22222222222222222222';
  my $cumulative_peak = $peak > $PRIOR_RSS_BYTES ?
    $peak : $PRIOR_RSS_BYTES;
  my $content = join("\t", qw(run_id execution_id preflight_terminal
    controller_terminal prior_elapsed_seconds
    current_execution_elapsed_seconds cumulative_elapsed_seconds
    prior_aggregate_peak_rss_bytes current_aggregate_peak_rss_bytes
    cumulative_aggregate_peak_rss_bytes)) . "\n" .
    join("\t", $RUN_ID, $EXECUTION_ID, $preflight,
      $controller, sprintf('%.9f', $PRIOR_WALL_SECONDS),
      $current_placeholder, $cumulative_placeholder,
      $PRIOR_RSS_BYTES, $peak, $cumulative_peak) . "\n";
  my $current_offset = index($content, $current_placeholder);
  my $cumulative_offset = index($content, $cumulative_placeholder);
  $current_offset >= 0 && $cumulative_offset >= 0
    or die "summary elapsed placeholders are unavailable\n";
  sysopen my $handle, $partial, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create summary temporary leaf: $!\n";
  write_all($handle, $content);
  $handle->sync or die "cannot sync summary temporary leaf: $!\n";
  !(-e $path) or die "preflight summary already exists\n";
  return ($handle, $partial, $current_offset, $cumulative_offset);
}

sub patch_summary_elapsed {
  my ($handle, $current_offset, $cumulative_offset, $elapsed) = @_;
  my $current_text = sprintf('%020.9f', $elapsed);
  my $cumulative_text = sprintf('%020.9f',
    $PRIOR_WALL_SECONDS + $elapsed);
  length($current_text) == 20 && length($cumulative_text) == 20
    or die "summary elapsed fields overflow\n";
  sysseek($handle, $current_offset, 0) == $current_offset
    or die "cannot seek current summary elapsed field: $!\n";
  write_all($handle, $current_text);
  sysseek($handle, $cumulative_offset, 0) == $cumulative_offset
    or die "cannot seek cumulative summary elapsed field: $!\n";
  write_all($handle, $cumulative_text);
  $handle->sync or die "cannot sync final summary temporary leaf: $!\n";
  close $handle or die "cannot close final summary temporary leaf: $!\n";
}
