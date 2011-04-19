#!/usr/bin/perl

use strict;
use File::Basename;

my @tmpdir=($ENV{"TEMP"},$ENV{"TMP"},"/dev/shm","/tmp");
while(@tmpdir && ! -d $tmpdir[0]){ shift @tmpdir; }
die "No temporary directory found" if !@tmpdir;
$tmpdir[0]=~s/\\/\//g;

sub gettmp {
	my $ext=shift;
	return $tmpdir[0]."/".basename($0).".".$$.".".$ext;
}

if(!@ARGV){
	print "Usage: $0 FILE            [-dlp \"SKRIPT\"] PLOT-OPTIONS\n";
	print "Usage: $0 FILE:FIELD      [-dlp \"SKRIPT\"] PLOT-OPTIONS\n";
	print "Usage: $0 FILE:TYPE:FIELD [-dlp \"SKRIPT\"] PLOT-OPTIONS\n";
	exit 1;
}

my $fdata=shift;
my @fdata=split /:/,$fdata;
my $ftyp="data";
my $ffld="o";
if(@fdata>=2 && (my $t=pop @fdata)ne""){
	$ftyp="object";
	$ffld.=".".$t;
}
if(@fdata>=2 && (my $t=pop @fdata)ne""){
	$ftyp=$t;
}
$fdata=join ":",@fdata;

my $skript="";
if($ARGV[0]eq"-dlp"){ shift; $skript=shift; }

my $tmpxtp=&gettmp("xtp");
my $tmptxt=&gettmp("txt");

open FD,">".$tmpxtp;
print FD $ftyp." o;\n";
print FD "\"".$fdata."\" o -restore;\n";
print FD "data x;\n";
print FD $ffld." ' ' x =;\n"; # TODO remove non-numeric components
print FD $skript;
print FD "\"".$tmptxt."\" \"ascii\" x stdfile -export\n";
print FD "quit;\n";
close FD;

system "dlabpro $tmpxtp";

close STDIN;
open STDIN,"<".$tmptxt;

unlink $tmpxtp;
unlink $tmptxt;

require "plot.pl";

