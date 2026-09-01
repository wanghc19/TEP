#!/usr/bin/perl
use strict;
use warnings;
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use FindBin qw($RealBin);
use File::Spec;
use IO::Handle ();
use POSIX qw(:sys_wait_h setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC alarm clock_gettime sleep time);

@ARGV == 0 or die "run_preflight.pl accepts no arguments\n";

my $RUN_ID = 'resource-preflight-001';
my $EXECUTION_ID = 'execution-003';
my $DEADLINE_EPOCH = 1788280898;
my $RSS_LIMIT_BYTES = 3221225472;
my $MATLAB = '/Applications/MATLAB_R2023b.app/bin/matlab';
my $BATCH = "run_i4_1c_core('resource-preflight-001','execution-003')";
my $start = time();
my $start_monotonic = clock_gettime(CLOCK_MONOTONIC);
my $remaining = $DEADLINE_EPOCH - $start;
$remaining > 0 or die "WALL_HARD_LIMIT_REACHED\n";
$remaining = 2700 if $remaining > 2700;
my $monotonic_deadline = $start_monotonic + $remaining;
my $child = 0;
my $wall_reached = 0;
my $peak_rss = 0;
my $resource_handle;
my $resource_event_index = 0;
my $publication_aborted = 0;
my $summary_committed = 0;
my $summary_path = '';
$SIG{ALRM} = sub {
  kill 'KILL', -$child if $child > 1;
  kill 'KILL', $child if $child > 1;
  my $now = clock_gettime(CLOCK_MONOTONIC);
  if ($summary_path ne '' && -e $summary_path) {
    $summary_committed = 1;
    return;
  }
  if (defined($resource_handle) && !$summary_committed) {
    $publication_aborted = 1;
    eval {
      append_resource_event($resource_handle, \$resource_event_index,
        'WALL_LIMIT', $now - $start_monotonic, $peak_rss,
        'WALL_HARD_LIMIT_REACHED', -1, -1);
      $resource_handle->sync or die "cannot sync resource ledger: $!\n";
    };
  }
  syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
  $wall_reached = 1;
  if (defined($resource_handle) && !$summary_committed) {
    POSIX::_exit(2);
  }
};
alarm($remaining);

chdir $RealBin or die "cannot chdir: $!\n";
my $output_parent = File::Spec->catdir($RealBin, 'output');
mkdir $output_parent if !-e $output_parent;
-d $output_parent or die "output parent unavailable\n";
my $run_dir = File::Spec->catdir($output_parent, $RUN_ID);
mkdir $run_dir if !-e $run_dir;
-d $run_dir or die "preflight run directory unavailable\n";
my $output_dir = File::Spec->catdir($run_dir, $EXECUTION_ID);
!(-e $output_dir) or die "OUTPUT_COLLISION: $RUN_ID/$EXECUTION_ID\n";
mkdir $output_dir or die "cannot claim preflight execution: $!\n";
my $log_path = File::Spec->catfile($output_dir, 'run.log');
$summary_path = File::Spec->catfile($output_dir, 'preflight-summary.tsv');

$child = fork();
defined $child or die "fork failed: $!\n";
if ($child == 0) {
  setpgid(0, 0) == 0 or die "setpgid failed: $!\n";
  open STDOUT, '>>', $log_path or die "cannot open run.log: $!\n";
  open STDERR, '>&', \*STDOUT or die "cannot redirect stderr: $!\n";
  exec {$MATLAB} $MATLAB, '-batch', $BATCH;
  die "exec MATLAB failed: $!\n";
}
setpgid($child, $child);

my $terminal = 'RUNNING';
my $wait_status;
my $reaped = 0;
my $group_seen = 0;
my $current_stage = 'startup';
my %stage_peak;
my @stage_order;
my $log_offset = 0;
while (1) {
  update_stage($log_path, \$log_offset, \$current_stage,
    \%stage_peak, \@stage_order);
  if (!deadline_ok()) {
    $terminal = 'WALL_HARD_LIMIT_REACHED';
    stop_target($child, {});
    last;
  }
  my $table = process_table();
  if (!defined $table) {
    $terminal = 'RSS_ENFORCEMENT_UNAVAILABLE';
    stop_target($child, {});
    last;
  }
  my $targets = target_pids($table, $child);
  if (exists $table->{$child}) {
    if ($table->{$child}->{pgid} != $child) {
      $terminal = 'DEDICATED_PROCESS_GROUP_UNAVAILABLE';
      stop_target($child, $targets);
      last;
    }
    $group_seen = 1;
  }
  my $rss = 0;
  $rss += $table->{$_}->{rss_kib} * 1024 for keys %{$targets};
  $peak_rss = $rss if $rss > $peak_rss;
  if ($current_stage ne 'startup') {
    $stage_peak{$current_stage} = $rss
      if $rss > ($stage_peak{$current_stage} // 0);
  }
  if ($rss >= $RSS_LIMIT_BYTES) {
    $terminal = 'RSS_HARD_LIMIT_REACHED';
    stop_target($child, $targets);
    last;
  }
  if (!$reaped) {
    my $got = waitpid($child, WNOHANG);
    if ($got == $child) {
      $reaped = 1;
      $wait_status = $?;
    } elsif ($got == -1) {
      $terminal = 'CHILD_REAP_UNAVAILABLE';
      stop_target($child, $targets);
      last;
    }
  }
  if ($reaped && !keys %{$targets}) {
    $terminal = 'NATURAL_EXIT';
    last;
  }
  sleep 0.25;
}
if (!$reaped) {
  my $got = waitpid($child, 0);
  if ($got == $child) {
    $reaped = 1;
    $wait_status = $?;
  }
}
my $exit_code = defined($wait_status) ? ($wait_status >> 8) : -1;
my $signal = defined($wait_status) ? ($wait_status & 127) : -1;
if ($terminal eq 'NATURAL_EXIT' &&
    (!$group_seen || $exit_code != 0 || $signal != 0)) {
  $terminal = 'MATLAB_EXIT_NONZERO';
}
my $science_terminal = read_preflight_terminal($log_path);
if ($terminal eq 'NATURAL_EXIT' &&
    $science_terminal ne 'PREFLIGHT_COMPLETE') {
  $terminal = 'PREFLIGHT_OUTPUT_INCOMPLETE';
}
my $resource_path = File::Spec->catfile($output_dir, 'resource.tsv');
$resource_handle = open_resource_ledger($resource_path);
my $resource_ok = eval {
  for my $stage (@stage_order) {
    append_resource_event($resource_handle, \$resource_event_index,
      "STAGE_PEAK:$stage", fresh_elapsed(), $stage_peak{$stage},
      'OBSERVED_STAGE_PEAK', $exit_code, $signal);
  }
  append_resource_event($resource_handle, \$resource_event_index,
    'TARGET_EXIT', fresh_elapsed(), $peak_rss, 'PUBLICATION_PENDING',
    $exit_code, $signal);
  $resource_handle->sync or die "cannot sync resource ledger: $!\n";
  1;
};
if (!$resource_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $exit_code, $signal);
  exit 2;
}
publication_deadline_ok($exit_code, $signal) or exit 2;

my ($summary_handle, $summary_partial, $elapsed_offset);
my $publication_ok = eval {
  ($summary_handle, $summary_partial, $elapsed_offset) =
    prepare_summary($science_terminal, $peak_rss, $terminal);
  1;
};
if (!$publication_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $exit_code, $signal);
  exit 2;
}
publication_deadline_ok($exit_code, $signal) or exit 2;

my $final_elapsed = fresh_elapsed();
$publication_ok = eval {
  patch_summary_elapsed($summary_handle, $elapsed_offset, $final_elapsed);
  append_resource_event($resource_handle, \$resource_event_index,
    'WHOLE_COMMAND_TERMINAL', $final_elapsed, $peak_rss, $terminal,
    $exit_code, $signal);
  $resource_handle->sync or die "cannot sync resource ledger: $!\n";
  1;
};
if (!$publication_ok) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $exit_code, $signal);
  exit 2;
}
publication_deadline_ok($exit_code, $signal) or exit 2;
if (!rename $summary_partial, $summary_path) {
  publication_failure('CANONICAL_PUBLICATION_FAILURE',
    $exit_code, $signal);
  exit 2;
}
$summary_committed = 1;
alarm(0);
close $resource_handle;
exit($terminal eq 'NATURAL_EXIT' ? 0 : 2);

sub deadline_ok {
  if ($wall_reached || time() >= $DEADLINE_EPOCH ||
      clock_gettime(CLOCK_MONOTONIC) >= $monotonic_deadline) {
    syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
    return 0;
  }
  return 1;
}

sub process_table {
  open my $handle, '-|', '/bin/ps', '-axo',
    'pid=,ppid=,pgid=,rss=' or return;
  my %table;
  while (my $line = <$handle>) {
    $line =~ s/^\s+|\s+$//g;
    next if $line eq '';
    my ($pid, $ppid, $pgid, $rss) = split /\s+/, $line;
    return if !defined($rss) || grep { $_ !~ /^\d+$/ }
      ($pid, $ppid, $pgid, $rss);
    $table{$pid + 0} = {ppid => $ppid + 0, pgid => $pgid + 0,
      rss_kib => $rss + 0};
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
  $target{$_} = 1 for grep { $table->{$_}->{pgid} == $root } keys %{$table};
  return \%target;
}

sub stop_target {
  my ($root, $targets) = @_;
  kill 'KILL', -$root if $root > 1;
  kill 'KILL', $root if $root > 1;
  kill 'KILL', $_ for grep { $_ > 1 } keys %{$targets};
}

sub update_stage {
  my ($path, $offset, $current, $peaks, $order) = @_;
  return if !-e $path;
  open my $handle, '<', $path or return;
  seek $handle, ${$offset}, 0 or return;
  while (my $line = <$handle>) {
    my $stage;
    if ($line =~ /^CORE_MARKER\t([^\t]+)\t([A-Z0-9_]+_(?:BEGIN|END)|RELEASED)/) {
      $stage = "$1/$2";
    }
    if (defined $stage) {
      ${$current} = $stage;
      if (!exists $peaks->{$stage}) {
        $peaks->{$stage} = 0;
        push @{$order}, $stage;
      }
    }
  }
  ${$offset} = tell $handle;
  close $handle;
}

sub read_preflight_terminal {
  my ($path) = @_;
  return 'UNAVAILABLE' if !-e $path;
  open my $handle, '<', $path or return 'UNAVAILABLE';
  my $value = 'UNAVAILABLE';
  while (my $line = <$handle>) {
    $value = $1 if $line =~ /^PREFLIGHT_TERMINAL\t([^\s]+)/;
  }
  close $handle;
  return $value;
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

sub fresh_elapsed {
  return clock_gettime(CLOCK_MONOTONIC) - $start_monotonic;
}

sub open_resource_ledger {
  my ($path) = @_;
  sysopen my $handle, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create resource ledger: $!\n";
  write_all($handle, join("\t", qw(event_index event_kind
    whole_command_elapsed_seconds aggregate_peak_rss_bytes
    controller_terminal matlab_exit_code matlab_signal)) . "\n");
  return $handle;
}

sub append_resource_event {
  my ($handle, $index, $kind, $elapsed, $peak, $event_terminal,
      $exit_code, $signal) = @_;
  ${$index}++;
  write_all($handle, join("\t", ${$index}, $kind,
    sprintf('%.9f', $elapsed), $peak, $event_terminal,
    $exit_code, $signal) . "\n");
}

sub append_wall_event {
  my ($exit_code, $signal) = @_;
  $publication_aborted = 1;
  append_resource_event($resource_handle, \$resource_event_index,
    'WALL_LIMIT', fresh_elapsed(), $peak_rss,
    'WALL_HARD_LIMIT_REACHED', $exit_code, $signal);
  $resource_handle->sync or die "cannot sync wall event: $!\n";
  syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
}

sub publication_deadline_ok {
  my ($exit_code, $signal) = @_;
  if ($wall_reached || $publication_aborted ||
      time() >= $DEADLINE_EPOCH ||
      clock_gettime(CLOCK_MONOTONIC) >= $monotonic_deadline) {
    append_wall_event($exit_code, $signal) if !$publication_aborted;
    return 0;
  }
  return 1;
}

sub publication_failure {
  my ($failure_terminal, $exit_code, $signal) = @_;
  return if $publication_aborted;
  $publication_aborted = 1;
  eval {
    append_resource_event($resource_handle, \$resource_event_index,
      'PUBLICATION_FAILURE', fresh_elapsed(), $peak_rss,
      $failure_terminal, $exit_code, $signal);
    $resource_handle->sync;
  };
  syswrite(STDERR, "$failure_terminal\n");
}

sub prepare_summary {
  my ($science, $peak, $controller) = @_;
  my $partial = "$summary_path.partial";
  my $placeholder = '00000000000000000000';
  my $content = "run_id\texecution_id\tcontroller_terminal\t" .
    "scientific_terminal\telapsed_seconds\taggregate_peak_rss_bytes\n" .
    "$RUN_ID\t$EXECUTION_ID\t$controller\t$science\t" .
    "$placeholder\t$peak\n";
  my $offset = index($content, $placeholder);
  sysopen my $handle, $partial, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create preflight summary: $!\n";
  write_all($handle, $content);
  $handle->sync or die "cannot sync preflight summary partial: $!\n";
  !(-e $summary_path) or die "preflight summary already exists\n";
  return ($handle, $partial, $offset);
}

sub patch_summary_elapsed {
  my ($handle, $offset, $elapsed) = @_;
  my $text = sprintf('%020.9f', $elapsed);
  length($text) == 20 or die "summary elapsed field overflow\n";
  sysseek($handle, $offset, 0) == $offset
    or die "cannot seek summary elapsed field: $!\n";
  write_all($handle, $text);
  $handle->sync or die "cannot sync final summary partial: $!\n";
  close $handle or die "cannot close final summary partial: $!\n";
}
