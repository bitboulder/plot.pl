#!/usr/bin/perl

use strict;
use File::Basename;
my $pname=$0;
$pname=$ENV{"_"} if ! $pname;
if(-l $pname){
	my $l=readlink $pname;
	$l=dirname($pname)."/".$l if $l!~/^[\/\\]/;
	$pname=$l;
}
unshift @INC,dirname($pname);
require hlp;

if(!@ARGV){
	print "Usage: $0 FILE            PLOT-OPTIONS\n";
	print "Usage: $0 FILE:FIELD      PLOT-OPTIONS\n";
	print "Usage: $0 FILE:TYPE:FIELD PLOT-OPTIONS\n";
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

my $tmpxtp=&hlp::gettmp("xtp");
my $tmptxt=&hlp::gettmp("txt");

open FD,">".$tmpxtp;
print FD $ftyp." o;\n";
print FD "\"".$fdata."\" o -restore;\n";
print FD $ffld." ' ' ".$ffld." =;\n"; # TODO remove non-numeric components
print FD "\"".$tmptxt."\" \"ascii\" ".$ffld." stdfile -export\n";
print FD "quit;\n";
close FD;

system "dlabpro $tmpxtp";

close STDIN;
open STDIN,"<".$tmptxt;

unlink $tmpxtp;
unlink $tmptxt;

require "plot.pl";

