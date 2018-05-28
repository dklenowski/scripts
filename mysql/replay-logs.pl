#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use POSIX 'strftime';
use File::Basename;
use File::Spec;
use File::Copy;

#
# globals
#
our $mysql = 'mysql -N -s -r ';
our $mysqlbinlog = 'mysqlbinlog';
our $mysqlbinlog_args = '--base64-output=never';
our $posfile = './replay-pos.txt';
our $binlogdir = '/var/lib/mysql/binary';
our $binlogfile = "$binlogdir/master-bin.index";
our $diffdir = '/var/lib/mysql/diff';

if (!-e($diffdir) && !mkdir($diffdir)) {
  print "cannot continue becuase the diff directory does not exist ($diffdir) and i cant create it :$!\n";
  exit 1;
}
  

sub usage {
  print <<EOF
  Usage: replay-logs.pl [--initial-pos <initial-start-pos> --initial-file <initial-file>] --local-user <user> \
     [--execute --remote-db <db> --remote-user <user> --remote-pass <pass> --final]

    --initial-pos <initial-start-pos>   Initialise $posfile with a ninitial start position of <initial-start-pos>.
    --initial-file <initial-file>       Initialise $posfile with the initial start file <initial-file>.
    --local-user <user>                 The local database user.
    --execute                           By default, this script will perform a dry run.
    --remote-db <db>                    The remote database to replay logs on.
    --remote-user <user>                The remote user for the remote database.
    --remote-pass <pass>                The remote pass for the remote database.
    --final                             Perform the final sync (decrements the endpos by 1 so the last
                                        statement is included).

EOF
;
  exit 1;
}

sub l {
  my ($error, $msg) = @_;
  print "[" . uc($error) .  "] - $msg\n";
}

sub logline {
  my ($startfile, $startpos, $endfile, $endpos, $datestr) = @_;
  if (!$datestr) {
    $datestr = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
  }
  return "\"$datestr\", $startfile, $startpos, $endfile, $endpos\n";
}

sub clean {
  my ($str) = @_;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

sub result {
  my ($rc) = @_;
  my $high = $rc >> 8;
  my $low  = $rc & 255;
  return ($high, $low);
}

sub initlog {
  my ($fname, $pos) = @_;
  print "Are you sure you want to initialise $posfile with $fname:$pos (yes/no)?: ";
  my $reply = <STDIN>;
  if ($reply !~ m/yes/i) {
    print "ok..exiting\n";
    exit 1;
  }

  if ($pos !~ m/[0-9]+/) {
    l('fatal', "initial position ($pos) must only contain numbers");
    exit 1;
  }

  open(OUT, ">$posfile") || die "cant open $posfile for writing :$!";
  print OUT logline(-1, 'null', $fname, $pos);
  close(OUT);
}

sub startpos {
  open(INP, $posfile) || die "cant open $posfile for reading :$!";
  my @buf = <INP>;
  close(INP);

  my $lastline = $buf[$#buf];
  my @flds = split(/,/, $lastline);

  # the endpos of the last line becomes the startpos of the current dump
  my $startfile = clean($flds[3]);
  my $startpos = clean($flds[4]);
  l('debug', "using startfile $startfile and startpos $startpos");
  if ($startpos !~ m/[0-9]+/) {
    l('fatal', "found an invalid start position $startpos?");
    exit 1;
  }

  return ($startfile, $startpos);
}

sub endpos {
  my ($dbuser) = @_;
  my $cmd = "$mysql -u$dbuser -e \"show master status;\"";
  my $result = `$cmd`;
  if (!$result) {
   l('fatal', "failed to connect to local db using user $dbuser");
   exit 1;
  }
  my @flds = split(/[\s]+/, clean($result));
  my $endfile = $flds[0];
  my $endpos = $flds[1];
  l('debug', "using endfile $endfile and endpos $endpos");

  if ($endpos !~ m/[0-9]+/) {
    l('fatal', "found an invalid end position $endpos");
  }

  return($endfile, $endpos);
}

sub findbinfiles {
  my ($startfile, $endfile) = @_;
  
  my $start = File::Basename::basename($startfile);
  my $end = File::Basename::basename($endfile);

  if ($start eq $end) {
    l('info', "startfile ($start) is the same as endfile");
    return File::Spec->catfile($binlogdir, $start);
  }

  open(INP, $binlogfile) || die "cant open binlog file $binlogfile : $!";
  my @buf = <INP>;
  close(INP);

  l('info', "searching $binlogfile for start $start and end $end");
  my $files;
  my $include = 0;

  foreach my $line (@buf) { 
    chomp($line);
    if ($include) { 
      l('debug', "found binary file $line");
      $files .= " $line";
      last if ($line =~ m/$end$/);
    } elsif ($line =~ m/$start$/) {
      $files = $line;
      $include = 1;
    }
  }
  l('info', "using binary files:\n$files");
  return $files;
}

sub runbin {
  my ($datestr, $files, $startpos, $endpos) = @_;
  my $outputfile = File::Spec->catfile($diffdir, "diff.$datestr.sql");
  my $cmd = "$mysqlbinlog $mysqlbinlog_args --start-position $startpos --stop-position $endpos $files > $outputfile";

  l('info', "running mysqlbinlog with\n$cmd");
  my $rc = system($cmd);
  if ($rc) { 
    my ($high, $low) = result($rc);
    l('fatal', "mysqlbinlog command failed with rc $high:$low");
    exit 1;
  }

  return $outputfile;
}

sub executebin {
  my ($datestr, $dbuser, $dbpass, $dbhost, $inputfile) = @_;
  my $cmd = "$mysql -u$dbuser -p$dbpass -h$dbhost < $inputfile";

  l('info', "running mysql command with\n$cmd");
  my $rc = system($cmd);
  if ($rc) { 
    my ($high, $low) = result($rc);
    l('fatal', "mysql command failed with rc $high:$low");
    exit 1;
  }
}

#
# main
#

our ($initialpos, $initialfile);
our ($dbuser);
our ($execute, $remotedb, $remoteuser, $remotepass);
our ($final);

Getopt::Long::GetOptions(
  'initial-pos=s' => \$initialpos,
  'initial-file=s' => \$initialfile,
  'local-user=s' => \$dbuser,
  'execute' => \$execute,
  'remote-db=s' => \$remotedb,
  'remote-user=s' => \$remoteuser,
  'remote-pass=s' => \$remotepass,
  'final' => \$final);

if ($initialpos) {
  if (!$initialfile) {
    l('fatal', "you must specify both a position and a file?");
    usage();
  }

  my $fname = $initialfile;
  if ($fname !~ m/^\//) {
    $fname = $binlogdir . '/' . $initialfile;
  }
  initlog($fname, $initialpos);
  exit 1;
}

if (!$dbuser) {
  l('fatal', "you must specify a db user?");
  usage();
}

if ($execute && (!$remotedb || !$remoteuser || !$remotepass)) {
  l('fatal', "if you specify execute, you must specify remote connection parameters?");
  usage();
}

my $datestr = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
my $datestr2 = $datestr;
$datestr2 =~ s/[: ]/-/g;

my ($startfile, $startpos) = startpos();
my ($endfile, $endpos) = endpos($dbuser);

if ($final) {
 l('info', "incrementing end position ($endpos) by 1, since final sync");
 $endpos++;
}

if (File::Basename::basename($startfile) eq File::Basename::basename($endfile)) {
  if ($startpos == $endpos) {
    l('warn', "startfile is the same as endfile ($startfile) with the same start/end position ($startpos)?");
    exit 1;
  } elsif ($startpos > $endpos) {
    l('warn', "startpos > endpos ($startpos>$endpos), maybe you ran with --final, wait to see if any more transactions are applied");
    exit 1;
  }
}

my $files = findbinfiles($startfile, $endfile);
my $binfile = runbin($datestr2, $files, $startpos, $endpos);
if (!$execute) { 
  l('info', "since not executing, moving $binfile to /tmp/" . File::Basename::basename($binfile));
  if (!File::Copy::move($binfile, '/tmp')) {
    l('fatal', "failed to move $binfile to /tmp/");
  }
} else {
  executebin($datestr, $remoteuser, $remotepass, $remotedb, $binfile);
  # if we get to here we need to write the to the log file
  l('info', "saving startfile $startfile:$startpos and endfile $endfile:$endpos");
  open(OUT, ">>$posfile") || die "cant open $posfile for writing :$!";
  print OUT logline($startfile, $startpos, $endfile, $endpos, $datestr);
  close(OUT);
}

