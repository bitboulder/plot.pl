#!/usr/bin/perl

use strict;

my $tmpdat="/tmp/plot.pl.$$.dat";
my $tmpdem="/tmp/plot.pl.$$.dem";
my $maxnum=0;

open TMP,">".$tmpdat;
while(<STDIN>){
	print TMP $_;
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
close TMP;

my $gpcfg="";
(my $nbg,my $blk,my $hist,my $colxy,my $coln,my $eps)=(0,0,0,0,1,0);
(my $size,my $png)=("","","");
my $multiplot=$maxnum;
my $outbase="plot";
while(1){
	if   ($ARGV[0]eq"-h"        ){ shift; &usage();         }
	elsif($ARGV[0]eq"-nbg"      ){ shift; $nbg    =1;       }
	elsif($ARGV[0]eq"-blk"      ){ shift; $blk    =1;       }
	elsif($ARGV[0]eq"-blke"     ){ shift; $blk    =2;       }
	elsif($ARGV[0]eq"-blkw"     ){ shift; $blk=$blk?$blk:1; $gpcfg.="set boxwidth ".(shift)." absolute\n"; }
	elsif($ARGV[0]eq"-hist"     ){ shift; $hist   =1;       }
	elsif($ARGV[0]eq"-xy"       ){ shift; $colxy  =1;       }
	elsif($ARGV[0]eq"-2"        ){ shift; $colxy  =1;       }
	elsif($ARGV[0]eq"-col"      ){ shift; $coln   =shift;   }
	elsif($ARGV[0]eq"-3"        ){ shift; $coln   =2;       }
	elsif($ARGV[0]eq"-multiplot"){ shift; $multiplot=shift; }
	elsif($ARGV[0]eq"-xrange"   ){ shift; $gpcfg .="set xrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-yrange"   ){ shift; $gpcfg .="set yrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-xgrid"    ){ shift; $gpcfg .="set grid xtics\n"; }
	elsif($ARGV[0]eq"-ygrid"    ){ shift; $gpcfg .="set grid ytics\n"; }
	elsif($ARGV[0]eq"-xtics"    ){ shift; $gpcfg .=&readxtics(shift); }
	elsif($ARGV[0]eq"-size"     ){ shift; $size  .="set size ".(shift)."\n"; }
	elsif($ARGV[0]eq"-xsize"    ){ shift; $gpcfg .="set terminal x11 size ".(shift)."\n"; }
	elsif($ARGV[0]eq"-color"    ){ shift; $gpcfg .=&readcolors(shift); }
	elsif($ARGV[0]eq"-eps"      ){ shift; $eps    =1;       }
	elsif($ARGV[0]eq"-png"      ){ shift; $png    =shift;   }
	elsif($ARGV[0]eq"-out"      ){ shift; $outbase=shift;   }
	elsif($ARGV[0]eq"-C"        ){ shift; $gpcfg .=(shift)."\n"; }
	elsif($ARGV[0]eq"-c"        ){ shift; $gpcfg .=&readfile(shift); }
	else{ last; }
}
$gpcfg.=$size if ""ne$size && ($png || $eps);

sub usage {
	print "Usage: $0 {Options} {COLNAME}\n";
	print "  -nbg            no background mode (donot detach from terminal)\n";
	print "  -blk            use blocks instead of lines\n";
	print "  -blke           use blocks with error bars\n";
	print "  -blkw NUM       set absolute block width (implies -blk)\n";
	print "  -xy             use two colums of data (x,y-values) - normaly x-values are read from the first column\n";
	print "  -col N          use N data columns (for block width in -blk mode, or err-bar in -blke)\n";
	print "  -multiplot N    use every N columns for a new subplot\n";
	print "  -xrange MIN:MAX define x-axis range\n";
	print "  -yrange MIN:MAX define y-axis range\n";
	print "  -xtics          places labels L at position P (exa: 0.5:hallo,0.8:welt)\n";
	print "  -xgrid          x-axis grid\n";
	print "  -ygrid          y-axis grid\n";
	print "  -size W,H       set size of drawing (for png/eps)\n";
	print "  -xsize W,H      set size of x11-window drawing\n";
	print "  -color C,C,...  define colors (exa: ff0000,00ff000)\n";
	print "  -eps            output eps-file\n";
	print "  -png W,H        output png-file with WxH pixels\n";
	print "  -out OUTBASE    define basename of generated output files (will be extended by \".png\" or \".eps\")\n";
	print "  -c GPCFG        include file GPCFG in gnuplot script\n";
	print "  -C GPCMD        include command GPCMD in gnuplot script\n";
	print "  COLNAME         sorted list of column titles\n";
	exit 0;
}

my $dem="";
my $with="";
if($blk){
	$with=$blk==1 ? "boxes" : "boxerrorbars";
	$dem.="set boxwidth 1.0 relative\n";
	$dem.="set style fill solid border -1\n";
  $dem.="set style fill solid 0.2\n" if $blk==2;
#}elsif($hist){
#	$with="histograms";
#	$dem.="set style histogram rowstacked\n";
#	$dem.="set style fill solid border -1\n";
#	$dem.="set boxwidth 0.8 relative\n";
}else{
	$with="lines";
}
$dem.=$gpcfg;
if($eps){
	$dem.="set term postscript eps color\n";
	$dem.="set output \"".$outbase.".eps\"\n";
}
if($png){
	$dem.="set term png size ".$png."\n";
	$dem.="set output \"".$outbase.".png\"\n";
}
my $nplot=1;
my $iplot=0;
if($multiplot<$maxnum){
  $nplot=int($maxnum/$multiplot);
  $dem.="set multiplot\n";
  $dem.="set format x \"\"\n";
  $dem.="set bmargin 0\n";
  $dem.="set lmargin 10\n";
  $dem.=sprintf "set size 1,%.5f\n",0.9/$nplot;
}
my $ncol = $colxy+$coln; # number of colums per line
my $col  = $colxy ? 0 : 1; # first column
while($col<$maxnum){
  if($multiplot<$maxnum){
    $dem.="set tmargin 0\n";
    if(++$iplot==$nplot){
      $dem.="set format x\n";
      $dem.="set bmargin\n";
      $dem.=sprintf "set size 1,%.5f\n",0.9/$nplot+0.02;
      $dem.=sprintf "set origin 0,%.5f\n",0.95-0.9*$iplot/$nplot-0.02;
    }else{
      $dem.=sprintf "set origin 0,%.5f\n",0.95-0.9*$iplot/$nplot;
    }
  }
  $dem.="plot";
  my $ls   = 1;
  my $scol = 0;
  while($col<$maxnum && $scol<$multiplot){
  	my $title = $ARGV[$scol];
  	my $using = ($colxy ? ++$col : 1);
  	#$with="points" if $col>3;
    for(my $i=0;$i<$coln;$i++){ $using.=":".(++$col); }
  	$dem.=" \"".$tmpdat."\" using ".$using;
  	$dem.=" title \"".$title."\"" if $title ne "";
  	$dem.=" with ".$with if $with ne "";
  	$dem.=" ls ".($ls++);
  	$dem.=",";
    $scol++;
  }
  $dem=~s/,$//; $dem.="\n";
}
if($multiplot<$maxnum){
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

sub readxtics {
	my $xtics=shift;
	my $gp="set xtics (";
	foreach my $xtic (split /,/,$xtics){
		(my $pos,my $lab)=split /:/,$xtic,2;
		$gp.="'".$lab."' ".$pos.",";
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
