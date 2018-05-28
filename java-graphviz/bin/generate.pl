#!/usr/bin/perl
use strict;
use warnings;
use File::Find ();
use GraphViz2 ();
use Getopt::Std ();
#
# globals
#
our @files;
our $DEBUG = 0;

#
# subs
#
sub usage {
  print <<EOF

  Usage: generate.pl [-d] -s <srcdir> -p <package> -i <csv-list-of-ignores> -o <ps>

EOF
;
  exit 1;
}

sub msg {
  my ( $code, $msg ) = @_;
  return if ( !$DEBUG && $code =~ m/debug/i );
  print "[" . uc($code) . "]: $msg\n";
}

sub _findcallback {
  my $name = $File::Find::name;
  push(@files, $name) if ( $name =~ m/\.java/ );
}

sub asclass {
  my ( $path ) = @_;
  $path =~ s/.*java\///;
  $path =~ s/\.java$//;
  $path =~ s/\//./g;
  return $path;
}

sub parse {
  my ( $file, $package ) = @_;
  msg('info', "searching $file for deps");
  my $fh;
  if ( !open($fh, '<', $file) ) {
    msg('fatal', "failed to open $file for reading?");
    return undef;
  }

  my %deps;
  my $line;
  while ( <$fh> ) {
    $line = $_;
    if ( $line !~ m/^\/\// && $line  =~ m/import/ && $line =~ m/$package/ ) {
      $line =~ s/import\s+//;
      $line =~ s/;\s+$//;
      msg('debug', "found dep $line in $file");
      $deps{$line}++;
    }
  }

  return %deps;
}

sub contains {
  my ( $aref, $str ) = @_;
  foreach my $entry ( @{ $aref }) {
    return 1 if ( $str =~ m/$entry/ );
  }

  return 0;
}

#
# main
#
our ( $opt_d, $opt_s, $opt_p, $opt_i, $opt_o );
Getopt::Std::getopts('d:s:p:i:o:');

$DEBUG++ if ( $opt_d );

if ( !$opt_s ) {
  msg('fatal', 'you must specify a source directory?');
  usage();
} elsif ( ! -e $opt_s ) {
  msg('fatal', "source directory ($opt_s) does not exist?");
  exit 1;
} elsif ( !$opt_p ) {
  msg('fatal', 'you must specify a package?');
  usage();
} elsif ( !$opt_o ) {
  msg('fatal', 'you must specify an output png?');
  usage();
} elsif ( -e $opt_o ) {
  msg('fatal', "output png $opt_o already exists, remove to continue..");
  exit 1;
}

my @ignored;
if ( $opt_i ) {
  @ignored = split(/,/, $opt_i);
  msg('info', "using ignore [@ignored]");
}

msg('info', "scanning $opt_s for java files");
File::Find::find(\&_findcallback, $opt_s);

my $g = GraphViz2->new(
  global => {
    width => 8.3, height => 11.7,
    pagewidth => 8.3, pageheight => 11.7,
    format => 'pdf' },
  node => { shape => 'plaintext' },
  edge => { minlen => 0.75 },
  arrow => { arrowhead => 'normal'},
  graph => {
  fontname  =>'arial', fontsize  => 10,
  layout => 'neato', overlap => 'false' });

my %nodes;
my %deps;
my $baseclass;
foreach my $file ( @files ) {
  $baseclass = asclass($file);

  if ( contains(\@ignored, $baseclass) ) {
    msg('info', "skipping ignored $baseclass");
    next;
  }

  msg('info', "parsing $file ($baseclass)");

  if ( !defined($nodes{$baseclass}) ) {
    $g->add_node(name => $baseclass);
  }

  %deps = parse($file, $opt_p);
  foreach my $dep ( keys(%deps) ) {
    if ( contains(\@ignored, $dep) ){
      msg('debug', "skipping dependency $dep for $baseclass");
      next;
    }

    msg('info', "adding dependency $dep to $baseclass");
    if ( !defined($nodes{$dep}) ) {
      $g->add_node(name => $dep);
      $nodes{$dep}++;
    }

    $g->add_edge(from => $baseclass, to => $dep, dir => 'forward');
  }
}

$g->run(output_file => $opt_o);