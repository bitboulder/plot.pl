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

my $tmpdat=&hlp::gettmp("dat");
my $tmpdem=&hlp::gettmp("dem");
my $maxnum=0;

my $infile="";

for(my $i=0;$i<@ARGV;$i++){
	if($ARGV[$i]eq"-h"){ &usage(); }
	elsif($ARGV[$i]eq"-in"){
		$infile=$ARGV[$i+1];
		splice @ARGV,$i,2;
		$i--;
	}
}

if(""ne$infile){
	close STDIN;
	open STDIN,"<".$infile || die "could not open infile";
}

my @dat=();
my $i=0;
while(<STDIN>){
	push @dat,$_;
	if($_=~/^(.*)#(.*)$/){
		$_=$1;
		foreach(split / +/,$2){
			$_=~s/__/ /g;
			push @ARGV,$_;
		}
	}
	$_=~s/^ +//g;
	$_=~s/ +$//g;
	next if ""eq$_;
	my $num=split / +/,$_;
	$maxnum=$num if $maxnum<$num;
}
&usage() if $maxnum<1;
push @ARGV,"-nox" if $maxnum==1;

my $gpcfg="";
my $gpcfgnf="";
my $gpcfgl="";
my $ylabel="";
my $ptyp="lines";
(my $nbg,my $blk,my $colxy,my $coln,my $eps)=(0,0,0,1,0);
(my $size,my $png)=("","","");
my $multiplot=-1;
my $outbase="plot";
while(1){
	if   ($ARGV[0]eq"-nbg"      ){ shift; $nbg    =1;       }
	elsif($ARGV[0]eq"-blk"      ){ shift; $blk    =1;       }
	elsif($ARGV[0]eq"-blke"     ){ shift; $blk    =2;       }
	elsif($ARGV[0]eq"-blkw"     ){ shift; $blk=$blk?$blk:1; $gpcfg.="set boxwidth ".(shift)." absolute\n"; }
	elsif($ARGV[0]eq"-typ"      ){ shift; $ptyp=shift;   &ptypinit(); }
	elsif($ARGV[0]eq"-xy"       ){ shift; $colxy  =1;       }
	elsif($ARGV[0]eq"-nox"      ){ shift; $colxy  =-1;      }
	elsif($ARGV[0]eq"-2"        ){ shift; $colxy  =1;       } # depr
	elsif($ARGV[0]eq"-col"      ){ shift; $coln   =shift;   }
	elsif($ARGV[0]eq"-3"        ){ shift; $coln   =2;       } # depr
	elsif($ARGV[0]eq"-multiplot"){ shift; $multiplot=shift; }
	elsif($ARGV[0]eq"-xrange"   ){ shift; $gpcfg .="set xrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-yrange"   ){ shift; $gpcfg .="set yrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-xgrid"    ){ shift; $gpcfg .="set grid xtics\n"; }
	elsif($ARGV[0]eq"-ygrid"    ){ shift; $gpcfg .="set grid ytics\n"; }
	elsif($ARGV[0]eq"-xtics"    ){ shift; $gpcfg .=&readtics("xtics",shift); }
	elsif($ARGV[0]eq"-ytics"    ){ shift; $gpcfg .=&readtics("ytics",shift); }
	elsif($ARGV[0]eq"-xlabel"   ){ shift; $gpcfgl.="set xlabel \"".(shift)."\"\n"; }
	elsif($ARGV[0]eq"-ylabel"   ){ shift; $ylabel =shift; }
	elsif($ARGV[0]eq"-title"    ){ shift; $gpcfg .="set title \"".(shift)."\"\n"; $gpcfgnf.="unset title\n"; }
	elsif($ARGV[0]eq"-size"     ){ shift; $size  .="set size ".(shift)."\n"; }
	elsif($ARGV[0]eq"-xsize"    ){ shift; $gpcfg .="set terminal x11 size ".(shift)."\n"; }
	elsif($ARGV[0]eq"-color"    ){ shift; $gpcfg .=&readcolors(shift); }
	elsif($ARGV[0]eq"-log"      ){ shift; $gpcfg .="set logscale ".(shift)."\n"; }
	elsif($ARGV[0]eq"-eps"      ){ shift; $eps    =1;       }
	elsif($ARGV[0]eq"-png"      ){ shift; $png    =shift;   }
	elsif($ARGV[0]eq"-out"      ){ shift; $outbase=shift;  system "mkdir -p \"".dirname($outbase)."\""; }
	elsif($ARGV[0]eq"-C"        ){ shift; $gpcfg .=(shift)."\n"; }
	elsif($ARGV[0]eq"-c"        ){ shift; $gpcfg .=&readfile(shift); }
	else{ last; }
}


open TMP,">".$tmpdat;
foreach(@dat){
	print TMP ($i++)." " if $colxy<0;
	print TMP $_;
}
close TMP;
close STDIN if ""ne$infile;

sub ptypinit {
	if("image"eq$ptyp){
		$coln=0;
	}
}

$maxnum++ if $colxy<0;
$coln=$maxnum if !$coln;
$gpcfg.=$size if ""ne$size && ($png || $eps);
$nbg=1 if $png || $eps;
$multiplot=$maxnum if $multiplot<0;
my $nplot=$multiplot<$maxnum ? int(($maxnum-($colxy<0?1:0))/$multiplot) : 1;
$colxy=0 if $colxy<0;

sub usage {
	print "Usage: $0 {Options} {COLNAME}\n";
	print "  -typ TYP        plotting type:\n";
	print "       lines (def.) use lines\n";
	print "       boxes        use boxes (for histogram,recognition result,...)\n";
	print "       image        use image (for sonagram,confusion matrix,...)\n";
	print "       any other gnuplot plotting style (points,dots,...)\n";
	print "  -nbg            no background mode (donot detach from terminal)\n";
	print "  -blk            use blocks instead of lines\n";
	print "  -blke           use blocks with error bars\n";
	print "  -blkw NUM       set absolute block width (implies -blk)\n";
	print "  -xy             use two colums of data (x,y-values) - normaly x-values are read from the first column\n";
	print "  -nox            there is no x-column in data - use line number\n";
	print "  -col N          use N data columns (for block width in -blk mode, or err-bar in -blke)\n";
	print "  -multiplot N    use every N columns for a new subplot\n";
	print "  -xrange MIN:MAX define x-axis range\n";
	print "  -yrange MIN:MAX define y-axis range\n";
	print "  -xtics [P:]L,...\n";
	print "  -ytics [P:]L,...places labels L at position P (\"0.5:hallo,0.8:welt\" or \"hallo,welt\")\n";
	print "  -xlabel TXT     label for x-axis\n";
	print "  -ylabel TXT     label for y-axis\n";
	print "  -title TXT      plot title\n";
	print "  -xgrid          x-axis grid\n";
	print "  -ygrid          y-axis grid\n";
	print "  -size W,H       set size of drawing (for png/eps)\n";
	print "  -xsize W,H      set size of x11-window drawing\n";
	print "  -color C,C,...  define colors (exa: ff0000,00ff000)\n";
	print "  -log AXIS       enable logscale (AXIS: x|y|xy)\n";
	print "  -eps            output eps-file\n";
	print "  -png W,H        output png-file with WxH pixels\n";
	print "  -in INPUTFILE   read data form file instead of stdin\n";
	print "  -out OUTBASE    define basename of generated output files (will be extended by \".png\" or \".eps\")\n";
	print "  -c GPCFG        include file GPCFG in gnuplot script\n";
	print "  -C GPCMD        include command GPCMD in gnuplot script\n";
	print "  COLNAME         sorted list of column titles\n";
	exit 0;
}

my $dem="";
if($blk){
	$ptyp=$blk==1 ? "boxes" : "boxerrorbars";
	$dem.="set boxwidth 1.0 relative\n";
	$dem.="set style fill solid border -1\n";
	$dem.="set style fill solid 0.2\n" if $blk==2;
}
my $matrix = $ptyp=~/^(image)$/;
$dem.=$gpcfg;
if($eps){
	$dem.="set term postscript eps color\n";
	$dem.="set output \"".$outbase.".eps\"\n";
}
if($png){
	$dem.="set term png size ".$png."\n";
	$dem.="set output \"".$outbase.".png\"\n";
}
my $iplot=0;
my @gpcfgi=();
if($nplot>1){
  $dem.="set multiplot\n";
  $dem.="set format x \"\"\n";
  $dem.="set bmargin 0\n";
  $dem.="set lmargin 10\n";
  $dem.=sprintf "set size 1,%.5f\n",0.9/$nplot;
  $dem.="set tmargin 0\n";
  $gpcfgl.="set format x\n";
  $gpcfgl.="set bmargin\n";
  $gpcfgl.=sprintf "set size 1,%.5f\n",0.9/$nplot+0.02;
  my @ylabel=split /,/,$ylabel;
  for(my $i=0;$i<$nplot;$i++){
	  my $lab="";
	  $lab=$ylabel[$i] if $i<@ylabel;
	  $lab=$ylabel if @ylabel<2;
	  $gpcfgi[$i] = ""ne$lab ? "set ylabel \"".$lab."\"\n" : "unset ylabel\n";
  }
}else{
  $dem.="set ylabel \"$ylabel\"\n" if ""ne$ylabel;
}
my $ncol = $colxy+$coln; # number of colums per line
my $col  = $colxy ? 0 : 1; # first column
while($col<$maxnum){
  $dem.= $gpcfgi[$iplot];
  $dem.= $gpcfgnf if $iplot==1;
  $dem.= $gpcfgl if ++$iplot==$nplot;
  $dem.= sprintf "set origin 0,%.5f\n",0.95-0.9*$iplot/$nplot-($iplot==$nplot?0.02:0) if $nplot>1;
  $dem.="plot";
  my $ls   = 1;
  my $scol = 0;
  while($col<$maxnum && $scol<$multiplot){
  	my $title = $ARGV[$scol];
  	my $using = ($colxy ? ++$col : 1);
    for(my $i=0;$i<$coln;$i++){ $using.=":".(++$col); }
  	$dem.=" \"".$tmpdat."\"";
	$dem.=" matrix" if $matrix;
	$dem.=" using ".$using if !$matrix;
  	$dem.=" title \"".$title."\"" if $title ne "";
  	$dem.=" with ".$ptyp;
  	$dem.=" ls ".($ls++) if !$matrix;
  	$dem.=",";
    $scol++;
  }
  $dem=~s/,$//; $dem.="\n";
}
if($nplot>1){
  $dem.="unset multiplot\n";
}
$dem.="pause mouse\n";
open GP,">".$tmpdem;
print GP $dem;
close GP;
#print $dem;

exit if !$nbg && fork()!=0;

system "gnuplot ".$tmpdem;

unlink $tmpdat;
unlink $tmpdem;


sub readfile {
	my $file=shift;
	my $dat="";
	open FD,"<".$file;
	while(<FD>){ $dat.=$_; }
	close FD;
	return $dat;
}

sub readtics {
	(my $name,my $tics)=@_;
	my $gp="set ".$name." (";
	my $i=0;
	foreach my $xtic (split /,/,$tics){
		(my $pos,my $lab)=split /:/,$xtic,2;
		if($xtic!~/:/){ $lab=$pos; $pos=$i; }
		$gp.="'".$lab."' ".$pos.",";
		$i++;
	}
	$gp=~s/,$//;
	$gp.=")\n";
	return $gp;
}

sub readcolors {
	my $colors=shift;
	my $gp="";
	my $c=1;
	foreach my $color (split /,/,$colors){
		$gp.="set style line ".($c++)." lt 1 lc rgb \"#".$color."\"\n";
	}
	return $gp;
}

1;
