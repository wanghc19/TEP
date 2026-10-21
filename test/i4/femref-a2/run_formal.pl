#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Spec;
use IO::Handle ();
use POSIX qw(:sys_wait_h setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC alarm clock_gettime sleep);

@ARGV == 0 or die "run_formal.pl accepts no arguments\n";

my $RUN_ID = 'run-001';
my $EXECUTION_ID = 'execution-001';
my $WALL_LIMIT_SECONDS = 2700;
my $RSS_LIMIT_BYTES = 3221225472;
my $MATLAB = '/Applications/MATLAB_R2023b.app/bin/matlab';
my $BATCH = "run_i4_1b('run-001','execution-001')";
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
  mkdir $run_dir or die "cannot create output/run-001: $!\n";
}
-d $run_dir or die "output/run-001 is not a directory\n";
my $output_dir = File::Spec->catdir($run_dir, $EXECUTION_ID);
!(-e $output_dir) or
  die "OUTPUT_COLLISION: output/run-001/execution-001 exists\n";
mkdir $output_dir or
  die "cannot claim output/run-001/execution-001: $!\n";
my $log_path = File::Spec->catfile($output_dir, 'run.log');
$summary_path = File::Spec->catfile($output_dir, 'run-summary.csv');

$child = fork();
defined $child or die "fork failed: $!\n";
if ($child == 0) {
  setpgid(0, 0) == 0 or die "child setpgid failed: $!\n";
  open STDOUT, '>>', $log_path or die "cannot open run.log: $!\n";
  open STDERR, '>&', \*STDOUT or die "cannot redirect stderr: $!\n";
  exec {$MATLAB} $MATLAB, '-batch', $BATCH;
  die "exec MATLAB failed: $!\n";
}
setpgid($child, $child);

my $controller_terminal = 'RUNNING';
my $child_reaped = 0;
my $wait_status;
my $dedicated_group_seen = 0;

while (1) {
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
  for my $pid (keys %{$targets}) {
    $rss_bytes += $table->{$pid}->{rss_kib} * 1024;
  }
  $peak_rss_bytes = $rss_bytes if $rss_bytes > $peak_rss_bytes;

  if ($rss_bytes >= $RSS_LIMIT_BYTES) {
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
  sleep 1;
}

if (!$child_reaped) {
  my $reaped = waitpid($child, 0);
  if ($reaped == $child) {
    $child_reaped = 1;
    $wait_status = $?;
  }
}
my $now = fresh_deadline_check($deadline, \$controller_terminal);
$controller_terminal = 'WALL_HARD_LIMIT_REACHED' if $wall_reached;
my $exit_code = defined($wait_status) ? ($wait_status >> 8) : -1;
my $signal = defined($wait_status) ? ($wait_status & 127) : -1;
if ($controller_terminal eq 'NATURAL_EXIT' &&
    (!$dedicated_group_seen || $exit_code != 0 || $signal != 0)) {
  $controller_terminal = 'MATLAB_EXIT_NONZERO';
}

my $draft = read_terminal_draft($output_dir);
my $resource_path = File::Spec->catfile($output_dir, 'resource.tsv');
$resource_handle = open_resource_ledger($resource_path);
append_resource_event($resource_handle, \$resource_event_index,
  'TARGET_EXIT', clock_gettime(CLOCK_MONOTONIC) - $start, $peak_rss_bytes,
  'PUBLICATION_PENDING', $exit_code, $signal);
$resource_handle->sync or die "cannot sync resource ledger: $!\n";
publication_deadline_ok() or exit 2;

my ($summary_handle, $summary_partial, $elapsed_offset);
my $publication_ok = eval {
  ($summary_handle, $summary_partial, $elapsed_offset) =
    prepare_summary($output_dir, $draft, $peak_rss_bytes,
      $controller_terminal);
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
  patch_summary_elapsed($summary_handle, $elapsed_offset, $final_elapsed);
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
      ppid => $ppid + 0,
      pgid => $pgid + 0,
      rss_kib => $rss_kib + 0,
      state => $state,
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
    whole_command_elapsed_seconds aggregate_peak_rss_bytes
    controller_terminal matlab_exit_code matlab_signal)) . "\n");
  return $handle;
}

sub append_resource_event {
  my ($handle, $index, $kind, $elapsed, $peak, $terminal,
      $exit_code, $signal) = @_;
  ${$index}++;
  write_all($handle, join("\t", ${$index}, $kind,
    sprintf('%.9f', $elapsed), $peak, $terminal,
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

sub read_terminal_draft {
  my ($dir) = @_;
  my %draft = (
    execution_id => $EXECUTION_ID,
    scientific_terminal => '',
    terminal_class => 'OPERATIONAL_FAILURE',
    attempted_solves => '',
    completed_solves => '',
    planned_solves => '',
    collection_size => '',
    lambda_ref_p2 => '',
    k_ref_p2 => '',
    first_failure => '',
    matlab_elapsed_seconds => '',
    claim_boundary =>
      'EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY',
  );
  my $path = File::Spec->catfile($dir, 'work', 'matlab-terminal.tsv');
  return \%draft if !-f $path;
  open my $handle, '<', $path or return \%draft;
  while (my $line = <$handle>) {
    chomp $line;
    my ($key, $value) = split /\t/, $line, 2;
    $draft{$key} = $value if defined($value) && exists $draft{$key};
  }
  close $handle;
  return \%draft;
}

sub csv_value {
  my ($value) = @_;
  $value = '' if !defined $value;
  $value =~ s/"/""/g;
  return qq{"$value"} if $value =~ /[",\r\n]/;
  return $value;
}

sub prepare_summary {
  my ($dir, $draft, $peak, $controller) = @_;
  if ($controller ne 'NATURAL_EXIT') {
    $draft->{terminal_class} = 'RESOURCE_FAILURE'
      if $controller eq 'WALL_HARD_LIMIT_REACHED' ||
         $controller eq 'RSS_HARD_LIMIT_REACHED';
    $draft->{terminal_class} = 'OPERATIONAL_FAILURE'
      if $draft->{terminal_class} ne 'RESOURCE_FAILURE';
    $draft->{scientific_terminal} = $controller;
  }
  my @header = qw(run_id execution_id scientific_terminal terminal_class
    attempted_solves completed_solves planned_solves collection_size
    lambda_ref_p2 k_ref_p2 first_failure claim_boundary
    matlab_elapsed_seconds whole_command_elapsed_seconds
    aggregate_peak_rss_bytes controller_terminal);
  my @row = ($RUN_ID, $draft->{execution_id},
    $draft->{scientific_terminal}, $draft->{terminal_class},
    $draft->{attempted_solves}, $draft->{completed_solves},
    $draft->{planned_solves}, $draft->{collection_size},
    $draft->{lambda_ref_p2}, $draft->{k_ref_p2},
    $draft->{first_failure}, $draft->{claim_boundary},
    $draft->{matlab_elapsed_seconds}, '00000000000000000000',
    $peak, $controller);
  my $path = File::Spec->catfile($dir, 'run-summary.csv');
  my $partial = "$path.partial";
  my $content = join(',', @header) . "\n" .
    join(',', map { csv_value($_) } @row) . "\n";
  my $placeholder = '00000000000000000000';
  my $offset = index($content, $placeholder);
  $offset >= 0 or die "summary elapsed placeholder is unavailable\n";
  sysopen my $handle, $partial, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create summary: $!\n";
  write_all($handle, $content);
  $handle->sync or die "cannot sync summary temporary leaf: $!\n";
  !(-e $path) or die "run summary already exists\n";
  return ($handle, $partial, $offset);
}

sub patch_summary_elapsed {
  my ($handle, $offset, $elapsed) = @_;
  my $text = sprintf('%020.9f', $elapsed);
  length($text) == 20 or die "summary elapsed field overflow\n";
  sysseek($handle, $offset, 0) == $offset
    or die "cannot seek summary elapsed field: $!\n";
  write_all($handle, $text);
  $handle->sync or die "cannot sync final summary temporary leaf: $!\n";
  close $handle or die "cannot close final summary temporary leaf: $!\n";
}
