#!/usr/bin/perl

# Purpose: Enforce the two external resource limits for the fixed I4.1a
# representation-gate-003 diagnostic and publish controller-only evidence.
# Main algorithm: Claim one external leaf, establish a released dedicated
# MATLAB process group with a CLOEXEC exec handshake, then monitor one immutable
# wall deadline and full-process-table aggregate RSS until target death.
# Based on: design-4-1a.md Sections 25--27.
# Main changes: This is the fixed no-argument external controller for gate 003.
# Numerical goal: Run zero scientific eigensolves and expose no reference data.

use strict;
use warnings;

use Errno qw(EACCES EINTR ESRCH);
use Fcntl qw(FD_CLOEXEC F_GETFD F_SETFD O_CREAT O_EXCL O_WRONLY);
use FindBin qw($Bin);
use IO::Handle;
use Math::BigInt;
use POSIX qw(strftime WNOHANG);
use Time::HiRes qw(alarm clock_gettime CLOCK_MONOTONIC sleep);

my $DIAGNOSTIC_ID = 'representation-gate-003';
my $MATLAB_PATH = '/Applications/MATLAB_R2023b.app/bin/matlab';
my $MATLAB_BATCH =
  q{run_i4_1a('representation-gate-003','representation-diagnostic')};
my $WALL_LIMIT_SECONDS = 1800;
my $RSS_LIMIT_BYTES = Math::BigInt->new('2147483648');
my $SAMPLE_INTERVAL_SECONDS = 1.0;
my $CLAIM_BOUNDARY = 'EXTERNAL_WALL_AND_AGGREGATE_RSS_CONTROL_ONLY';
my @PS_COMMAND = ('/bin/ps', '-axo',
  'pid=,ppid=,pgid=,rss=,lstart=,state=,command=');
my $PS_ROW_PATTERN = qr{^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+
  (\S+\s+\S+\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})\s+
  (\S+)\s+(.+?)\s*$}x;

@ARGV == 0 or die "This fixed watchdog accepts no arguments.\n";
$SIG{PIPE} = 'IGNORE';
STDOUT->autoflush(1);
STDERR->autoflush(1);

my $script_start = LOCAL_monotonic();
my $start_utc = LOCAL_utc();
my $experiment_dir = $Bin;
my $science_dir = "$experiment_dir/diagnostics/$DIAGNOSTIC_ID";
my $watchdog_parent = "$experiment_dir/watchdog";
my $external_dir = "$watchdog_parent/$DIAGNOSTIC_ID";
my $samples_partial = "$external_dir/samples.tsv.partial";
my $samples_final = "$external_dir/samples.tsv";
my $summary_final = "$external_dir/watchdog-summary.tsv";
my $stdout_path = "$external_dir/matlab.stdout.log";
my $stderr_path = "$external_dir/matlab.stderr.log";

chdir($experiment_dir)
  or die "Cannot enter fixed experiment directory: $!\n";
-e $science_dir and die "DIAGNOSTIC_COLLISION: $science_dir exists.\n";
-e $external_dir and die "WATCHDOG_COLLISION: $external_dir exists.\n";
if (!-e $watchdog_parent) {
  mkdir($watchdog_parent, 0700)
    or die "Cannot create watchdog parent directory: $!\n";
}
-d $watchdog_parent
  or die "Watchdog parent path is not a directory.\n";
mkdir($external_dir, 0700)
  or die "Cannot atomically claim watchdog leaf: $!\n";

my ($samples_fh, $matlab_stdout_fh, $matlab_stderr_fh);
my $science_consumed = 0;
my $child_pid;
my $dedicated_pgid;
my $supervisor_pgid = getpgrp(0);
my $dedicated_pgid_was_verified = 0;
my $child_reaped = 0;
my $child_wait_status;
my $target_start;
my $release_sent = 0;
my $root_start_identity;
my $deadline;
my $target_stop_time;
my $target_dead_time;
my $ledger_finalized_time;
my $sample_count = 0;
my $unavailable_sample_count = 0;
my $aggregate_peak;
my $last_sample_elapsed;
my $last_valid_table;
my %known_identity;
my %pid_reuse_excluded;
my $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
my $stop_reason = 'PRELAUNCH_FAILURE';
my $wall_alarm_fired = 0;
my $wall_alarm_time;
my $alarm_group_kill_sent = 0;
my $alarm_guard_failed = 0;
my $child_blocking_reap_safe = 0;
my $fatal_message = '';
my ($exec_status_read, $exec_status_write);
my ($exec_release_read, $exec_release_write);

my $sample_header = join("\t", qw(
  sequence utc elapsed_seconds sample_gap_seconds matlab_root_pid
  process_group_id live_pid_count pid_rss_kib_pairs aggregate_rss_bytes
  sample_status decision
));
my $summary_header = join("\t", qw(
  diagnostic_id status stop_reason start_utc end_utc elapsed_seconds
  wall_limit_seconds rss_limit_bytes matlab_root_pid process_group_id
  sample_count unavailable_sample_count aggregate_peak_rss_bytes
  child_wait_status child_exit_code child_signal
  diagnostic_namespace_present claim_boundary
));

eval {
  $samples_fh = LOCAL_open_exclusive($samples_partial);
  $matlab_stdout_fh = LOCAL_open_exclusive($stdout_path);
  $matlab_stderr_fh = LOCAL_open_exclusive($stderr_path);
  LOCAL_write_and_flush($samples_fh, "$sample_header\n");
  LOCAL_write_and_flush(*STDOUT, "$sample_header\n");

  pipe($exec_status_read, $exec_status_write)
    or die "PRELAUNCH_FAILURE:exec_status pipe: $!\n";
  pipe($exec_release_read, $exec_release_write)
    or die "PRELAUNCH_FAILURE:exec_release pipe: $!\n";
  my $descriptor_flags = fcntl($exec_status_write, F_GETFD, 0);
  defined($descriptor_flags)
    or die "PRELAUNCH_FAILURE:F_GETFD exec_status: $!\n";
  fcntl($exec_status_write, F_SETFD,
    $descriptor_flags | FD_CLOEXEC)
    or die "PRELAUNCH_FAILURE:F_SETFD FD_CLOEXEC: $!\n";

  $child_pid = fork();
  defined($child_pid) or die "PRELAUNCH_FAILURE:fork: $!\n";
  if ($child_pid == 0) {
    close($samples_fh);
    close($exec_status_read);
    close($exec_release_write);
    LOCAL_child_main($exec_status_write, $exec_release_read,
      $matlab_stdout_fh, $matlab_stderr_fh);
  }

  $child_pid > 1
    or die "PRELAUNCH_FAILURE:child PID must exceed one.\n";
  my $parent_setpgid = POSIX::setpgid($child_pid, $child_pid);
  my $parent_setpgid_eacces =
    (!defined($parent_setpgid) || $parent_setpgid != 0) && $!{EACCES};
  if ((!defined($parent_setpgid) || $parent_setpgid != 0) &&
      !$parent_setpgid_eacces) {
    die "PRELAUNCH_FAILURE:parent setpgid: $!\n";
  }

  close($exec_status_write);
  close($exec_release_read);
  close($matlab_stdout_fh);
  close($matlab_stderr_fh);
  undef($matlab_stdout_fh);
  undef($matlab_stderr_fh);

  my $ready_line = LOCAL_read_status_line($exec_status_read);
  defined($ready_line) &&
      $ready_line =~ /^PGID_READY:(\d+):(\d+)$/
    or die "PRELAUNCH_FAILURE:invalid PGID_READY handshake.\n";
  my ($ready_pid, $ready_pgid) = ($1, $2);
  my $parent_observed_pgid = getpgrp($child_pid);
  $ready_pid == $child_pid && $ready_pgid == $child_pid &&
      $parent_observed_pgid == $child_pid &&
      $child_pid != $supervisor_pgid
    or die "PRELAUNCH_FAILURE:dedicated PGID verification failed.\n";
  $dedicated_pgid = $child_pid;
  $dedicated_pgid_was_verified = 1;

  $target_start = LOCAL_monotonic();
  LOCAL_write_all($exec_release_write, "EXEC_GO\n");
  $release_sent = 1;
  $deadline = $target_start + $WALL_LIMIT_SECONDS;
  close($exec_release_write)
    or die "PRELAUNCH_FAILURE:cannot close release pipe: $!\n";
  undef($exec_release_write);

  my $exec_payload = LOCAL_read_to_eof($exec_status_read);
  close($exec_status_read);
  $exec_payload eq ''
    or die "PRELAUNCH_FAILURE:$exec_payload\n";
  my $early_wait = waitpid($child_pid, WNOHANG);
  if ($early_wait == $child_pid) {
    $child_reaped = 1;
    $child_wait_status = $?;
    die "PRELAUNCH_FAILURE:child exited before exec confirmation.\n";
  }
  $early_wait == 0
    or die "PRELAUNCH_FAILURE:child exited before exec confirmation.\n";
  getpgrp($child_pid) == $dedicated_pgid
    or die "PRELAUNCH_FAILURE:post-exec PGID verification failed.\n";
  $science_consumed = 1;

  $SIG{ALRM} = sub {
    $wall_alarm_fired = 1;
    $wall_alarm_time = LOCAL_monotonic();
    $target_stop_time = $wall_alarm_time
      if !defined($target_stop_time);
    if (defined($child_pid) && defined($dedicated_pgid) &&
        $child_pid > 1 && $dedicated_pgid == $child_pid &&
        $dedicated_pgid != $supervisor_pgid &&
        $dedicated_pgid_was_verified) {
      my $kill_count = kill('KILL', -$dedicated_pgid);
      if ($kill_count == 0 && !$!{ESRCH}) {
        $alarm_guard_failed = 1;
      } else {
        $alarm_group_kill_sent = 1;
      }
    } else {
      $alarm_guard_failed = 1;
      LOCAL_positive_child_cleanup();
    }
  };

  my $remaining = $deadline - LOCAL_monotonic();
  if ($remaining <= 0) {
    $target_stop_time = LOCAL_monotonic();
    LOCAL_issue_group_kill($last_valid_table, \%known_identity);
    $alarm_group_kill_sent = 1;
    $wall_alarm_fired = 1;
    $wall_alarm_time = LOCAL_monotonic();
  } else {
    alarm($remaining);
  }

  while (1) {
    if ($alarm_guard_failed) {
      $stop_reason = 'KILL_GUARD_FAILED';
      $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
      $target_stop_time = LOCAL_monotonic()
        if !defined($target_stop_time);
      my $cleanup_ok =
        eval { LOCAL_issue_group_kill($last_valid_table, \%known_identity); 1; };
      $fatal_message = $@ || 'kill cleanup could not be confirmed'
        if !$cleanup_ok;
      LOCAL_record_unavailable_sample('OPERATIONAL_INTEGRITY_KILL');
      last;
    }
    if ($wall_alarm_fired || LOCAL_monotonic() >= $deadline) {
      if (!$alarm_group_kill_sent) {
        $target_stop_time = LOCAL_monotonic()
          if !defined($target_stop_time);
        LOCAL_issue_group_kill($last_valid_table, \%known_identity);
      } else {
        LOCAL_positive_cleanup($last_valid_table, \%known_identity);
      }
      $final_status = 'WALL_HARD_LIMIT_KILLED';
      $stop_reason = 'WALL_HARD_LIMIT_REACHED';
      LOCAL_record_unavailable_sample('WALL_HARD_LIMIT_KILL');
      last;
    }

    LOCAL_poll_child();
    my ($table, $table_error) = LOCAL_process_table();
    if ($wall_alarm_fired || LOCAL_monotonic() >= $deadline) {
      if (!$alarm_group_kill_sent) {
        $target_stop_time = LOCAL_monotonic()
          if !defined($target_stop_time);
        LOCAL_issue_group_kill($last_valid_table, \%known_identity);
      } else {
        LOCAL_positive_cleanup($last_valid_table, \%known_identity);
      }
      $final_status = 'WALL_HARD_LIMIT_KILLED';
      $stop_reason = 'WALL_HARD_LIMIT_REACHED';
      LOCAL_record_unavailable_sample('WALL_HARD_LIMIT_KILL');
      last;
    }
    if (defined($table_error)) {
      $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
      $stop_reason = 'RSS_AUTHORITY_LOST';
      $target_stop_time = LOCAL_monotonic();
      LOCAL_issue_group_kill(undef, \%known_identity);
      LOCAL_record_unavailable_sample('OPERATIONAL_INTEGRITY_KILL');
      last;
    }

    my ($sample, $authority_error) =
      LOCAL_authoritative_sample($table, \%known_identity);
    if ($wall_alarm_fired || LOCAL_monotonic() >= $deadline) {
      if (!$alarm_group_kill_sent) {
        $target_stop_time = LOCAL_monotonic()
          if !defined($target_stop_time);
        LOCAL_issue_group_kill($table, \%known_identity);
      } else {
        LOCAL_positive_cleanup($table, \%known_identity);
      }
      $final_status = 'WALL_HARD_LIMIT_KILLED';
      $stop_reason = 'WALL_HARD_LIMIT_REACHED';
      LOCAL_record_unavailable_sample('WALL_HARD_LIMIT_KILL');
      last;
    }
    if (defined($authority_error)) {
      $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
      $stop_reason = $authority_error;
      $target_stop_time = LOCAL_monotonic();
      LOCAL_issue_group_kill($table, \%known_identity);
      LOCAL_record_unavailable_sample('OPERATIONAL_INTEGRITY_KILL');
      last;
    }
    $last_valid_table = $table;

    if ($wall_alarm_fired || LOCAL_monotonic() >= $deadline) {
      if (!$alarm_group_kill_sent) {
        $target_stop_time = LOCAL_monotonic()
          if !defined($target_stop_time);
        LOCAL_issue_group_kill($table, \%known_identity);
      } else {
        LOCAL_positive_cleanup($table, \%known_identity);
      }
      $final_status = 'WALL_HARD_LIMIT_KILLED';
      $stop_reason = 'WALL_HARD_LIMIT_REACHED';
      LOCAL_record_sample($sample, 'WALL_HARD_LIMIT_KILL');
      last;
    }

    if ($sample->{aggregate_rss_bytes}->bcmp($RSS_LIMIT_BYTES) >= 0) {
      $target_stop_time = LOCAL_monotonic();
      $final_status = 'RSS_HARD_LIMIT_KILLED';
      $stop_reason = 'RSS_HARD_LIMIT_REACHED';
      LOCAL_issue_group_kill($table, \%known_identity);
      LOCAL_record_sample($sample, 'RSS_HARD_LIMIT_KILL');
      last;
    }

    if ($child_reaped && $sample->{live_pid_count} == 0 &&
        LOCAL_target_dead($table, \%known_identity)) {
      LOCAL_record_sample($sample, 'NATURAL_EXIT_OBSERVED');
      $final_status = 'TARGET_EXITED';
      $stop_reason = 'NATURAL_EXIT';
      $target_dead_time = LOCAL_monotonic();
      last;
    }

    LOCAL_record_sample($sample, '');
    sleep($SAMPLE_INTERVAL_SECONDS);
  }

  alarm(0);
  my $reap_confirmed = LOCAL_reap_child_without_hang();
  if (!$reap_confirmed) {
    $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
    $stop_reason = 'REAP_CONFIRMATION_FAILED'
      if $stop_reason ne 'KILL_GUARD_FAILED';
  }

  if (!defined($target_dead_time)) {
    my ($confirmation_table, $confirmation_error) = LOCAL_process_table();
    if (!$reap_confirmed || defined($confirmation_error) ||
        !LOCAL_target_dead($confirmation_table, \%known_identity)) {
      $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
      $stop_reason = 'REAP_CONFIRMATION_FAILED'
        if $stop_reason ne 'KILL_GUARD_FAILED';
    } else {
      $target_dead_time = LOCAL_monotonic();
    }
  }
  1;
} or do {
  $fatal_message = $@ || 'unclassified watchdog failure';
  alarm(0);
  my $released_unconfirmed = !$science_consumed && $release_sent &&
    $dedicated_pgid_was_verified;
  if ($science_consumed || $released_unconfirmed) {
    $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
    if ($released_unconfirmed) {
      $stop_reason = 'PRELAUNCH_FAILURE';
    } elsif ($fatal_message =~ /TARGET_LEFT_DEDICATED_PGID/) {
      $stop_reason = 'TARGET_LEFT_DEDICATED_PGID';
    } elsif ($stop_reason eq 'KILL_GUARD_FAILED' ||
        $fatal_message =~ /KILL_GUARD_FAILED/) {
      $stop_reason = 'KILL_GUARD_FAILED';
    } else {
      $stop_reason = 'RSS_AUTHORITY_LOST';
    }
    $target_stop_time = LOCAL_monotonic()
      if !defined($target_stop_time);
    my $cleanup_ok =
      eval { LOCAL_issue_group_kill($last_valid_table, \%known_identity); 1; };
    if (!$cleanup_ok) {
      my $cleanup_message = $@ || 'kill cleanup could not be confirmed';
      $fatal_message .= " | cleanup: $cleanup_message";
    }
  } else {
    $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
    $stop_reason = 'PRELAUNCH_FAILURE';
    if (defined($exec_release_write)) {
      eval { LOCAL_write_all($exec_release_write, "ABORT\n"); };
      close($exec_release_write);
      undef($exec_release_write);
    }
    LOCAL_positive_child_cleanup();
  }
  my $reap_confirmed = LOCAL_reap_child_without_hang();
  if (!$reap_confirmed && $science_consumed &&
      $stop_reason ne 'KILL_GUARD_FAILED') {
    $stop_reason = 'REAP_CONFIRMATION_FAILED';
  }
  if ($science_consumed || $released_unconfirmed) {
    my ($confirmation_table, $confirmation_error) = LOCAL_process_table();
    if (!$reap_confirmed || defined($confirmation_error) ||
        !LOCAL_target_dead($confirmation_table, \%known_identity)) {
      $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
      $stop_reason = 'REAP_CONFIRMATION_FAILED'
        if $science_consumed && $stop_reason ne 'KILL_GUARD_FAILED';
    } else {
      $target_dead_time = LOCAL_monotonic();
    }
  } elsif ($reap_confirmed) {
    $target_dead_time = LOCAL_monotonic();
  }
};

if (defined($samples_fh)) {
  close($samples_fh) or do {
    $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
    $stop_reason = 'RSS_AUTHORITY_LOST';
  };
  if (!rename($samples_partial, $samples_final)) {
    $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
    $stop_reason = 'RSS_AUTHORITY_LOST';
  }
}

my $end_utc = LOCAL_utc();
my $elapsed_origin = defined($target_start) && $science_consumed
  ? $target_start : $script_start;
my $elapsed_end = defined($target_stop_time) ? $target_stop_time :
  (defined($target_dead_time) ? $target_dead_time : LOCAL_monotonic());
my $elapsed_seconds = $elapsed_end - $elapsed_origin;
my ($child_exit_code, $child_signal) = ('', '');
if (defined($child_wait_status)) {
  $child_exit_code = ($child_wait_status >> 8) & 255;
  $child_signal = $child_wait_status & 127;
}
my $summary_row = join("\t", map { LOCAL_tsv($_) } (
  $DIAGNOSTIC_ID, $final_status, $stop_reason, $start_utc, $end_utc,
  LOCAL_number($elapsed_seconds), $WALL_LIMIT_SECONDS,
  $RSS_LIMIT_BYTES->bstr(), defined($child_pid) ? $child_pid : '',
  defined($dedicated_pgid) ? $dedicated_pgid : '', $sample_count,
  $unavailable_sample_count,
  defined($aggregate_peak) ? $aggregate_peak->bstr() : '',
  defined($child_wait_status) ? $child_wait_status : '',
  $child_exit_code, $child_signal, -e $science_dir ? 1 : 0,
  $CLAIM_BOUNDARY
));
eval {
  LOCAL_atomic_summary($summary_header, $summary_row);
  $ledger_finalized_time = LOCAL_monotonic();
  1;
} or do {
  $final_status = 'WATCHDOG_OPERATIONAL_INCOMPLETE';
  print STDERR "WATCHDOG_OPERATIONAL_INCOMPLETE: summary publication failed: $@";
};
print STDERR "WATCHDOG_STATUS=$final_status STOP_REASON=$stop_reason\n";
print STDERR "TARGET_STOP_MONOTONIC=" . LOCAL_number($target_stop_time) . "\n"
  if defined($target_stop_time);
print STDERR "TARGET_DEAD_MONOTONIC=" . LOCAL_number($target_dead_time) . "\n"
  if defined($target_dead_time);
print STDERR "LEDGER_FINALIZED_MONOTONIC=" .
  LOCAL_number($ledger_finalized_time) . "\n"
  if defined($ledger_finalized_time);
print STDERR "WATCHDOG_DETAIL=" . LOCAL_tsv($fatal_message) . "\n"
  if $fatal_message ne '';

exit($final_status eq 'TARGET_EXITED' ? 0 :
  ($final_status =~ /_HARD_LIMIT_KILLED$/ ? 2 : 1));

sub LOCAL_child_main {
  my ($status_write, $release_read, $stdout_fh, $stderr_fh) = @_;
  my $pid = $$;
  my $set_result = POSIX::setpgid(0, 0);
  if (!defined($set_result) || $set_result != 0 || getpgrp(0) != $pid) {
    LOCAL_child_status($status_write, "EXEC_ERROR:$!:setpgid failed\n");
    POSIX::_exit(111);
  }
  LOCAL_child_status($status_write, "PGID_READY:$pid:" . getpgrp(0) . "\n")
    or POSIX::_exit(111);
  my $release = LOCAL_read_status_line($release_read);
  close($release_read);
  if (!defined($release) || $release ne 'EXEC_GO') {
    POSIX::_exit(112);
  }
  if (!open(STDOUT, '>&', $stdout_fh) || !open(STDERR, '>&', $stderr_fh)) {
    LOCAL_child_status($status_write, "EXEC_ERROR:$!:redirect failed\n");
    POSIX::_exit(113);
  }
  close($stdout_fh);
  close($stderr_fh);
  {
    no warnings 'exec';
    exec {$MATLAB_PATH} $MATLAB_PATH, '-batch', $MATLAB_BATCH;
  }
  LOCAL_child_status($status_write,
    "EXEC_ERROR:$!:exec $MATLAB_PATH failed\n");
  POSIX::_exit(114);
}

sub LOCAL_child_status {
  my ($handle, $text) = @_;
  my $okay = eval { LOCAL_write_all($handle, $text); 1; };
  return $okay ? 1 : 0;
}

sub LOCAL_poll_child {
  return if $child_reaped;
  my $waited_pid = waitpid($child_pid, WNOHANG);
  if ($waited_pid == $child_pid) {
    $child_reaped = 1;
    $child_wait_status = $?;
  } elsif ($waited_pid == -1) {
    die "RSS_AUTHORITY_LOST:waitpid failed: $!\n";
  }
}

sub LOCAL_reap_child_without_hang {
  return 1 if $child_reaped;
  return 0 if !defined($child_pid) || $child_pid <= 1;
  my $wait_options = $child_blocking_reap_safe ? 0 : WNOHANG;
  my $waited_pid = waitpid($child_pid, $wait_options);
  if ($waited_pid == $child_pid) {
    $child_reaped = 1;
    $child_wait_status = $?;
    return 1;
  }
  return 0;
}

sub LOCAL_process_table {
  my %table;
  my $ps_fh;
  if (!open($ps_fh, '-|', @PS_COMMAND)) {
    return (undef, "ps launch failed: $!");
  }
  while (my $line = <$ps_fh>) {
    chomp($line);
    next if $line =~ /^\s*$/;
    if ($line !~ $PS_ROW_PATTERN) {
      close($ps_fh);
      return (undef, 'ambiguous full-table ps row');
    }
    my ($pid, $ppid, $pgid, $rss_kib, $start_identity, $state,
      $command) = ($1, $2, $3, $4, $5, $6, $7);
    if ($pid <= 0 || $ppid < 0 || $pgid < 0 || $rss_kib < 0 ||
        $start_identity eq '' || $state eq '' || $command eq '') {
      close($ps_fh);
      return (undef, 'invalid full-table ps field');
    }
    exists($table{$pid}) and do {
      close($ps_fh);
      return (undef, 'duplicate PID in full-table ps output');
    };
    $table{$pid} = {
      pid => 0 + $pid,
      ppid => 0 + $ppid,
      pgid => 0 + $pgid,
      rss_kib => 0 + $rss_kib,
      start_identity => $start_identity,
      state => $state,
      command => $command,
      live => $state !~ /^[ZX]/
    };
  }
  if (!close($ps_fh)) {
    return (undef, 'full-table ps exited unsuccessfully');
  }
  return (\%table, undef);
}

sub LOCAL_authoritative_sample {
  my ($table, $known) = @_;
  my $root = $table->{$child_pid};
  if (!defined($target_start)) {
    return (undef, 'RSS_AUTHORITY_LOST');
  }
  if (!defined($root_start_identity) &&
      (!defined($root) || !$root->{live})) {
    return (undef, 'RSS_AUTHORITY_LOST');
  }
  if (defined($root) && $root->{live}) {
    if (!defined($root_start_identity)) {
      $root_start_identity = $root->{start_identity};
    } elsif ($root->{start_identity} ne $root_start_identity) {
      if (!$child_reaped) {
        return (undef, 'RSS_AUTHORITY_LOST');
      }
      $root = undef;
    }
  }
  if (defined($root) && $root->{live}) {
    if (!exists($known->{"$child_pid\0$root->{start_identity}"})) {
      $known->{"$child_pid\0$root->{start_identity}"} = {
        %$root, first_seen_pgid => $root->{pgid},
        first_seen_parent_chain => "$child_pid"
      };
    }
  } elsif (!$child_reaped) {
    return (undef, 'RSS_AUTHORITY_LOST');
  }

  my %descendant;
  $descendant{$child_pid} = 1 if defined($root) && $root->{live};
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    for my $pid (keys(%$table)) {
      my $record = $table->{$pid};
      next if !$record->{live} || $descendant{$pid};
      if ($descendant{$record->{ppid}}) {
        $descendant{$pid} = 1;
        $changed = 1;
      }
    }
  }

  my %current_target;
  for my $pid (keys(%$table)) {
    my $record = $table->{$pid};
    next if !$record->{live};
    if ($descendant{$pid} || $record->{pgid} == $dedicated_pgid) {
      $current_target{$pid} = 1;
      my $identity_key = "$pid\0$record->{start_identity}";
      if (!exists($known->{$identity_key})) {
        $known->{$identity_key} = {
          %$record, first_seen_pgid => $record->{pgid},
          first_seen_parent_chain =>
            LOCAL_parent_chain($table, $pid, \%descendant)
        };
      }
    }
  }

  for my $identity_key (keys(%$known)) {
    my $entry = $known->{$identity_key};
    my $record = $table->{$entry->{pid}};
    next if !defined($record) || !$record->{live};
    next if $record->{start_identity} eq $entry->{start_identity};
    my $reuse_key = "$entry->{pid}\0$record->{start_identity}";
    if (!$pid_reuse_excluded{$reuse_key}) {
      $pid_reuse_excluded{$reuse_key} = 1;
      print STDERR "PID_REUSED_EXCLUDED pid=$entry->{pid}\n";
    }
  }

  for my $identity_key (keys(%$known)) {
    my $entry = $known->{$identity_key};
    my $record = $table->{$entry->{pid}};
    next if !defined($record) || !$record->{live};
    next if $record->{start_identity} ne $entry->{start_identity};
    $current_target{$entry->{pid}} = 1;
    if ($record->{pgid} != $dedicated_pgid) {
      return (undef, 'TARGET_LEFT_DEDICATED_PGID');
    }
  }

  my $aggregate = Math::BigInt->new(0);
  my @pairs;
  for my $pid (sort { $a <=> $b } keys(%current_target)) {
    my $record = $table->{$pid};
    defined($record) && $record->{live}
      or return (undef, 'RSS_AUTHORITY_LOST');
    $aggregate->badd($record->{rss_kib});
    push(@pairs, "$pid:$record->{rss_kib}");
  }
  $aggregate->bmul(1024);
  $aggregate->is_neg()
    and return (undef, 'RSS_AUTHORITY_LOST');
  return ({
    live_pid_count => scalar(@pairs),
    pid_rss_kib_pairs => join(';', @pairs),
    aggregate_rss_bytes => $aggregate
  }, undef);
}

sub LOCAL_parent_chain {
  my ($table, $pid, $descendant) = @_;
  my @chain = ($pid);
  my %seen = ($pid => 1);
  while (defined($table->{$pid}) && $pid != $child_pid) {
    $pid = $table->{$pid}{ppid};
    last if !$descendant->{$pid} || $seen{$pid};
    push(@chain, $pid);
    $seen{$pid} = 1;
  }
  return join('>', @chain);
}

sub LOCAL_issue_group_kill {
  my ($table, $known) = @_;
  my $guard_pass = defined($dedicated_pgid) && defined($child_pid) &&
    $dedicated_pgid == $child_pid && $dedicated_pgid > 1 &&
    $dedicated_pgid != $supervisor_pgid &&
    $dedicated_pgid_was_verified;
  if (!$guard_pass) {
    LOCAL_positive_cleanup($table, $known);
    die "KILL_GUARD_FAILED:negative process-group guard failed.\n";
  }
  my $kill_count = kill('KILL', -$dedicated_pgid);
  if ($kill_count == 0 && !$!{ESRCH}) {
    LOCAL_positive_cleanup($table, $known);
    die "KILL_GUARD_FAILED:negative process-group kill failed: $!\n";
  }
  LOCAL_positive_cleanup($table, $known);
  if (!$child_blocking_reap_safe) {
    die "KILL_GUARD_FAILED:target termination could not be confirmed.\n";
  }
}

sub LOCAL_positive_cleanup {
  my ($table, $known) = @_;
  if (defined($table)) {
    for my $identity_key (keys(%$known)) {
      my $entry = $known->{$identity_key};
      my $record = $table->{$entry->{pid}};
      next if !defined($record) || !$record->{live};
      next if $record->{start_identity} ne $entry->{start_identity};
      kill('KILL', $entry->{pid}) if $entry->{pid} > 1;
    }
  }
  LOCAL_positive_child_cleanup();
}

sub LOCAL_positive_child_cleanup {
  if ($child_reaped) {
    $child_blocking_reap_safe = 1;
    return 1;
  }
  return 0 if !defined($child_pid) || $child_pid <= 1;
  my $kill_count = kill('KILL', $child_pid);
  if ($kill_count > 0 || $!{ESRCH}) {
    $child_blocking_reap_safe = 1;
    return 1;
  }
  return 0;
}

sub LOCAL_target_dead {
  my ($table, $known) = @_;
  return 0 if !defined($table);
  for my $record (values(%$table)) {
    return 0 if $record->{live} && $record->{pgid} == $dedicated_pgid;
  }
  for my $identity_key (keys(%$known)) {
    my $entry = $known->{$identity_key};
    my $record = $table->{$entry->{pid}};
    next if !defined($record) || !$record->{live};
    return 0 if $record->{start_identity} eq $entry->{start_identity};
  }
  my $group_exists = kill(0, -$dedicated_pgid);
  return 0 if $group_exists;
  return 0 if !$!{ESRCH};
  return 1;
}

sub LOCAL_record_sample {
  my ($sample, $decision) = @_;
  my $elapsed = LOCAL_monotonic() - $target_start;
  my $gap = defined($last_sample_elapsed)
    ? $elapsed - $last_sample_elapsed : '';
  $last_sample_elapsed = $elapsed;
  ++$sample_count;
  my $row = join("\t", map { LOCAL_tsv($_) } (
    $sample_count, LOCAL_utc(), LOCAL_number($elapsed),
    $gap eq '' ? '' : LOCAL_number($gap), $child_pid, $dedicated_pgid,
    $sample->{live_pid_count}, $sample->{pid_rss_kib_pairs},
    $sample->{aggregate_rss_bytes}->bstr(), 'SAMPLE_OK', $decision
  ));
  LOCAL_write_and_flush($samples_fh, "$row\n");
  LOCAL_write_and_flush(*STDOUT, "$row\n");
  if (!defined($aggregate_peak) ||
      $sample->{aggregate_rss_bytes}->bcmp($aggregate_peak) > 0) {
    $aggregate_peak = $sample->{aggregate_rss_bytes}->copy();
  }
}

sub LOCAL_record_unavailable_sample {
  my ($decision) = @_;
  my $elapsed = defined($target_start)
    ? LOCAL_monotonic() - $target_start : LOCAL_monotonic() - $script_start;
  my $gap = defined($last_sample_elapsed)
    ? $elapsed - $last_sample_elapsed : '';
  $last_sample_elapsed = $elapsed;
  ++$sample_count;
  ++$unavailable_sample_count;
  my $row = join("\t", map { LOCAL_tsv($_) } (
    $sample_count, LOCAL_utc(), LOCAL_number($elapsed),
    $gap eq '' ? '' : LOCAL_number($gap),
    defined($child_pid) ? $child_pid : '',
    defined($dedicated_pgid) ? $dedicated_pgid : '',
    '', '', '', 'SAMPLE_UNAVAILABLE', $decision
  ));
  LOCAL_write_and_flush($samples_fh, "$row\n");
  LOCAL_write_and_flush(*STDOUT, "$row\n");
}

sub LOCAL_open_exclusive {
  my ($path) = @_;
  sysopen(my $handle, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)
    or die "PRELAUNCH_FAILURE:cannot create $path: $!\n";
  $handle->autoflush(1);
  return $handle;
}

sub LOCAL_atomic_summary {
  my ($header, $row) = @_;
  my $temporary_path =
    "$watchdog_parent/.representation-gate-003-summary-$$.partial";
  my $handle = LOCAL_open_exclusive($temporary_path);
  LOCAL_write_and_flush($handle, "$header\n$row\n");
  close($handle) or die "Cannot close watchdog summary temporary: $!\n";
  rename($temporary_path, $summary_final)
    or die "Cannot atomically publish watchdog summary: $!\n";
}

sub LOCAL_read_status_line {
  my ($handle) = @_;
  my $line = '';
  while (1) {
    my $character = '';
    my $count = sysread($handle, $character, 1);
    if (!defined($count)) {
      next if $!{EINTR};
      die "PRELAUNCH_FAILURE:status read failed: $!\n";
    }
    return undef if $count == 0 && $line eq '';
    last if $count == 0 || $character eq "\n";
    $line .= $character;
  }
  return $line;
}

sub LOCAL_read_to_eof {
  my ($handle) = @_;
  my $payload = '';
  while (1) {
    my $chunk = '';
    my $count = sysread($handle, $chunk, 4096);
    if (!defined($count)) {
      next if $!{EINTR};
      die "PRELAUNCH_FAILURE:exec-status read failed: $!\n";
    }
    last if $count == 0;
    $payload .= $chunk;
  }
  $payload =~ s/[\r\n]+$//;
  return $payload;
}

sub LOCAL_write_and_flush {
  my ($handle, $text) = @_;
  LOCAL_write_all($handle, $text);
  $handle->flush() or die "required log flush failed: $!\n";
}

sub LOCAL_write_all {
  my ($handle, $text) = @_;
  my $offset = 0;
  while ($offset < length($text)) {
    my $count = syswrite($handle, $text, length($text) - $offset, $offset);
    if (!defined($count)) {
      next if $!{EINTR};
      die "required log write failed: $!\n";
    }
    $count > 0 or die "required log write returned zero bytes.\n";
    $offset += $count;
  }
}

sub LOCAL_monotonic {
  return clock_gettime(CLOCK_MONOTONIC);
}

sub LOCAL_utc {
  return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

sub LOCAL_number {
  my ($value) = @_;
  return sprintf('%.17g', $value);
}

sub LOCAL_tsv {
  my ($value) = @_;
  return '' if !defined($value);
  my $text = "$value";
  $text =~ s/[\t\r\n]+/ /g;
  return $text;
}
