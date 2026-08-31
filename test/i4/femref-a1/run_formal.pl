#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use File::Spec;
use POSIX qw(:sys_wait_h setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC alarm clock_gettime sleep);

@ARGV == 0 or die "run_formal.pl accepts no arguments\n";

my $RUN_ID = 'run-007';
my $EXECUTION_ID = 'execution-001';
my $WALL_LIMIT_SECONDS = 2700;
my $RSS_LIMIT_BYTES = 2147483648;
my $MATLAB = '/Applications/MATLAB_R2023b.app/bin/matlab';
my $BATCH = "run_i4_1a('run-007')";
my $start = clock_gettime(CLOCK_MONOTONIC);
my $deadline = $start + $WALL_LIMIT_SECONDS;
my $child = 0;
$SIG{ALRM} = sub {
  kill 'KILL', -$child if $child > 1;
  kill 'KILL', $child if $child > 1;
  syswrite(STDERR, "WALL_HARD_LIMIT_REACHED\n");
  POSIX::_exit(2);
};
alarm($deadline - clock_gettime(CLOCK_MONOTONIC));

chdir $RealBin or die "cannot chdir to experiment directory: $!\n";
my $output_parent = File::Spec->catdir($RealBin, 'output');
-d $output_parent or die "output parent is unavailable\n";
my $run_dir = File::Spec->catdir($output_parent, $RUN_ID);
if (!-e $run_dir) {
  mkdir $run_dir or die "cannot create output/run-007: $!\n";
}
-d $run_dir or die "output/run-007 is not a directory\n";
my $output_dir = File::Spec->catdir($run_dir, $EXECUTION_ID);
!(-e $output_dir) or
  die "OUTPUT_COLLISION: output/run-007/execution-001 exists\n";
mkdir $output_dir or
  die "cannot claim output/run-007/execution-001: $!\n";
my $log_path = File::Spec->catfile($output_dir, 'run.log');

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

my $peak_rss_bytes = 0;
my $controller_terminal = 'RUNNING';
my $child_reaped = 0;
my $wait_status;
my $dedicated_group_seen = 0;

while (1) {
  my $table = process_table();
  my $targets = defined($table) ? target_pids($table, $child) : {};
  my $now = fresh_deadline_check($deadline, \$controller_terminal);
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
my $exit_code = defined($wait_status) ? ($wait_status >> 8) : -1;
my $signal = defined($wait_status) ? ($wait_status & 127) : -1;
if ($controller_terminal eq 'NATURAL_EXIT' &&
    (!$dedicated_group_seen || $exit_code != 0 || $signal != 0)) {
  $controller_terminal = 'MATLAB_EXIT_NONZERO';
}

my $draft = read_terminal_draft($output_dir);
$now = fresh_deadline_check($deadline, \$controller_terminal);
my $final_terminal = $controller_terminal;
my $final_elapsed = $now - $start;
write_resource($output_dir, $final_elapsed, $peak_rss_bytes,
  $final_terminal, $exit_code, $signal);
write_summary($output_dir, $draft, $final_elapsed, $peak_rss_bytes,
  $final_terminal);
exit($final_terminal eq 'NATURAL_EXIT' ? 0 : 2);

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

sub write_resource {
  my ($dir, $elapsed, $peak, $terminal, $exit_code, $signal) = @_;
  my $path = File::Spec->catfile($dir, 'resource.tsv');
  my $partial = "$path.partial";
  open my $handle, '>', $partial or die "cannot write resource record: $!\n";
  print {$handle} join("\t",
    qw(whole_command_elapsed_seconds aggregate_peak_rss_bytes
       controller_terminal matlab_exit_code matlab_signal)), "\n";
  print {$handle} join("\t",
    sprintf('%.9f', $elapsed), $peak, $terminal, $exit_code, $signal), "\n";
  close $handle or die "cannot close resource record: $!\n";
  rename $partial, $path or die "cannot publish resource record: $!\n";
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
    lambda_ref_fem => '',
    k_ref_fem => '',
    first_failure => '',
    matlab_elapsed_seconds => '',
    claim_boundary =>
      'EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY',
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

sub write_summary {
  my ($dir, $draft, $elapsed, $peak, $controller) = @_;
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
    lambda_ref_fem k_ref_fem first_failure claim_boundary
    matlab_elapsed_seconds whole_command_elapsed_seconds
    aggregate_peak_rss_bytes controller_terminal);
  my @row = ($RUN_ID, $draft->{execution_id},
    $draft->{scientific_terminal}, $draft->{terminal_class},
    $draft->{attempted_solves}, $draft->{completed_solves},
    $draft->{planned_solves}, $draft->{collection_size},
    $draft->{lambda_ref_fem}, $draft->{k_ref_fem},
    $draft->{first_failure}, $draft->{claim_boundary},
    $draft->{matlab_elapsed_seconds}, sprintf('%.9f', $elapsed),
    $peak, $controller);
  my $path = File::Spec->catfile($dir, 'run-summary.csv');
  my $partial = "$path.partial";
  open my $handle, '>', $partial or die "cannot write summary: $!\n";
  print {$handle} join(',', @header), "\n";
  print {$handle} join(',', map { csv_value($_) } @row), "\n";
  close $handle or die "cannot close summary: $!\n";
  rename $partial, $path or die "cannot publish summary: $!\n";
}
