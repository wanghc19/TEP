#!/usr/bin/perl
use strict;
use warnings;
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use FindBin qw($RealBin);
use File::Spec;
use POSIX qw(:sys_wait_h setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC alarm clock_gettime sleep);

@ARGV == 0 or die "run_profile_postprocess.pl accepts no arguments\n";

my $RUN_ID = 'run-008';
my $EXECUTION_ID = 'execution-001';
my $PROFILE_ID = 'profile-001';
my $PRIOR_WALL_SECONDS = 92.655067;
my $PROFILE_WALL_LIMIT_SECONDS = 2607.344933;
my $PRIOR_PEAK_RSS_BYTES = 1073594368;
my $RSS_LIMIT_BYTES = 3221225472;
my $MATLAB = '/Applications/MATLAB_R2023b.app/bin/matlab';
my @COMMAND = ($MATLAB, '-batch', 'profile_postprocess');
my $start = clock_gettime(CLOCK_MONOTONIC);
my $deadline = $start + $PROFILE_WALL_LIMIT_SECONDS;
my $child = 0;
my $target_live = 0;
my $wall_alarm_fired = 0;
$SIG{ALRM} = sub {
  $wall_alarm_fired = 1;
  kill 'KILL', -$child if $target_live && $child > 1;
  kill 'KILL', $child if $target_live && $child > 1;
};
alarm($deadline - clock_gettime(CLOCK_MONOTONIC));

chdir $RealBin or die "cannot chdir to experiment directory: $!\n";
my $execution_dir = File::Spec->catdir(
  $RealBin, 'output', $RUN_ID, $EXECUTION_ID
);
-d $execution_dir or die "run-008/execution-001 is unavailable\n";
my $review_dir = File::Spec->catdir($execution_dir, 'review-audit');
if (!-e $review_dir) {
  mkdir $review_dir or die "cannot create review-audit directory: $!\n";
}
-d $review_dir or die "review-audit is not a directory\n";
my $profile_dir = File::Spec->catdir($review_dir, $PROFILE_ID);
!(-e $profile_dir) or die "OUTPUT_COLLISION: profile-001 exists\n";
mkdir $profile_dir or die "cannot claim profile-001: $!\n";
my $profile_path = File::Spec->catfile($profile_dir, 'profile.json');

$child = fork();
defined $child or die "fork failed: $!\n";
if ($child == 0) {
  setpgid(0, 0) == 0 or die "child setpgid failed: $!\n";
  exec {$MATLAB} @COMMAND;
  die "exec profile postprocess failed: $!\n";
}
$target_live = 1;
setpgid($child, $child);

my $peak_rss_bytes = 0;
my $controller_terminal = 'RUNNING';
my $child_reaped = 0;
my $wait_status;
my $dedicated_group_seen = 0;

while (1) {
  my $now = clock_gettime(CLOCK_MONOTONIC);
  if ($wall_alarm_fired || $now >= $deadline) {
    $controller_terminal = 'WALL_HARD_LIMIT_REACHED';
    stop_target($child, {});
    last;
  }
  my $table = process_table();
  my $targets = defined($table) ? target_pids($table, $child) : {};
  $now = clock_gettime(CLOCK_MONOTONIC);
  if ($wall_alarm_fired || $now >= $deadline) {
    $controller_terminal = 'WALL_HARD_LIMIT_REACHED';
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
  $now = clock_gettime(CLOCK_MONOTONIC);
  if ($wall_alarm_fired || $now >= $deadline) {
    $controller_terminal = 'WALL_HARD_LIMIT_REACHED';
    stop_target($child, $targets);
    last;
  }
  if ($child_reaped && !keys %{$targets}) {
    $target_live = 0;
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
my $now = clock_gettime(CLOCK_MONOTONIC);
if ($wall_alarm_fired || $now >= $deadline) {
  $controller_terminal = 'WALL_HARD_LIMIT_REACHED';
}
if (!$child_reaped || kill(0, -$child)) {
  stop_target($child, {});
  die "TARGET_STOP_UNCONFIRMED\n";
}
$target_live = 0;
my $exit_code = defined($wait_status) ? ($wait_status >> 8) : -1;
my $signal = defined($wait_status) ? ($wait_status & 127) : -1;
if ($controller_terminal eq 'NATURAL_EXIT' &&
    (!$dedicated_group_seen || $exit_code != 0 || $signal != 0)) {
  $controller_terminal = 'MATLAB_EXIT_NONZERO';
}
if ($controller_terminal eq 'NATURAL_EXIT' && !-f $profile_path) {
  $controller_terminal = 'PROFILE_JSON_MISSING';
}
$now = clock_gettime(CLOCK_MONOTONIC);
if ($wall_alarm_fired || $now >= $deadline) {
  $controller_terminal = 'WALL_HARD_LIMIT_REACHED';
}
my $profile_elapsed = $now - $start;
my $cumulative_wall = $PRIOR_WALL_SECONDS + $profile_elapsed;
my $cumulative_peak = maximum($PRIOR_PEAK_RSS_BYTES, $peak_rss_bytes);
write_resource($profile_dir, $profile_elapsed, $cumulative_wall,
  $peak_rss_bytes, $cumulative_peak, $controller_terminal,
  $exit_code, $signal);
exit($controller_terminal eq 'NATURAL_EXIT' ? 0 : 2);

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

sub maximum {
  my $result = shift;
  for my $value (@_) {
    $result = $value if $value > $result;
  }
  return $result;
}

sub write_resource {
  my ($dir, $profile_elapsed, $cumulative_wall, $profile_peak,
      $cumulative_peak, $terminal, $exit_code, $signal) = @_;
  my $path = File::Spec->catfile($dir, 'resource.tsv');
  sysopen my $handle, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
    or die "cannot create resource.tsv: $!\n";
  print {$handle} join("\t", qw(
    prior_wall_seconds profile001_wall_seconds cumulative_wall_seconds
    prior_peak_rss_bytes profile001_peak_rss_bytes cumulative_peak_rss_bytes
    controller_terminal matlab_exit_code matlab_signal)), "\n";
  print {$handle} join("\t",
    sprintf('%.6f', $PRIOR_WALL_SECONDS),
    sprintf('%.9f', $profile_elapsed),
    sprintf('%.9f', $cumulative_wall),
    $PRIOR_PEAK_RSS_BYTES, $profile_peak, $cumulative_peak,
    $terminal, $exit_code, $signal), "\n";
  close $handle or die "cannot close resource.tsv: $!\n";
}
