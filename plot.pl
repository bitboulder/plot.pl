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

my $tmpdat=&gettmp("dat");
my $tmpdem=&gettmp("dem");
my $outdem=0;
my $maxnum=0;

my %outtyps=("x11"=>"", "eps"=>"postscript eps", "tex"=>"epslatex", "png"=>"png", "jpg"=>"jpeg", "plot"=>"plot", "dem"=>"");
my %outopts=(           "eps"=>"color",          "tex"=>"color");
my $outtyp="x11";
my $outbase="plot";

my $gpcfg="";
my $gpcfgnf="";
my $gpcfgl="";
my $ylabel="";
my $ptyp="lines";
(my $nbg,my $blk,my $colxy,my $coln)=(0,0,0,1);
my $size="";
my $outopt="";
my $multiplot=-1;
my $infile="";

unshift @ARGV,"-in" if @ARGV==1 && $ARGV[0]=~/^.+\.plot/i;

for(my $i=@ARGV-1;$i>=0;$i--){
	my $del=0;
	if($ARGV[$i]eq"-h"){ &usage(); }
	elsif($ARGV[$i]eq"-in"){ $infile=$ARGV[$i+1]; $del=2; }
	elsif($ARGV[$i]eq"-out"){ &readout($ARGV[$i+1]); $del=2;  }
	splice @ARGV,$i,$del if $del>0;
}

if(""ne$infile){
	close STDIN;
	($infile,my @args)=split /:/,$infile if ! -f $infile;
	open STDIN,"<".$infile || die "could not open infile";
	read STDIN,my $head,4;
	seek STDIN,0,0;
	if("<?xm"eq$head || "DN\03\00"eq$head || "\37\213\10\0"eq$head){
		close STDIN;
		$infile=&indlp($infile,@args);
		open STDIN,"<".$infile || die "could not open tmp-infile";
		$infile.="[UNLINK]";
	}
}

if(""eq$outtyps{$outtyp}){
	open GP,">".$tmpdem;
	print GP "show term\n";
	close GP;
	open GP,"gnuplot ".$tmpdem." 2>&1 |";
	while(<GP>){
		chomp $_;
		$outtyps{$outtyp}=$1 if $_=~/terminal type is +([^ ]*) *$/;
	}
	close GP;
	unlink $tmpdem;
}
$outtyps{$outtyp}="x11" if ""eq$outtyps{$outtyp};

my @dat=();
my $i=0;
while(<STDIN>){
	if($_=~/^([^#]*)#(.*)$/){
		$_=$1;
		my $arg=$2;
		$arg=~s/##.*//;
		if("!"ne substr $arg,0,1){
			foreach(split / +/,$arg){
				$_=~s/__/ /g;
				push @ARGV,$_;
			}
		}
	}
	$_=~s/^ +//g;
	$_=~s/ +$//g;
	next if ""eq$_;
	push @dat,$_;
	my $num=split / +/,$_;
	$maxnum=$num if $maxnum<$num;
}
close STDIN if ""ne$infile;
unlink $1 if $infile=~/^(.*)\[UNLINK\]$/;

if($outtyps{$outtyp}eq"plot"){
	foreach(@ARGV){ $_=~s/ /__/g; }
	for(my $i=@ARGV-1;$i>0;$i--){
		next if $ARGV[$i-1]!~/^-/ || $ARGV[$i]=~/^-/;
		$ARGV[$i-1].=" ".$ARGV[$i];
		splice @ARGV,$i,1;
	}
	open PL,">".$outbase.".".$outtyp;
	print PL "#!/usr/bin/env plot.pl\n";
	foreach(@ARGV){ print PL "#$_\n"; }
	foreach(@dat){ print PL $_; }
	close PL;
	chmod 0755,$outbase.".".$outtyp;
	exit 0;
}

&usage() if $maxnum<1;
unshift @ARGV,"-nox" if $maxnum==1;

while(1){
	if   ($ARGV[0]eq"-nbg"      ){ shift; $nbg    =1;       }
	elsif($ARGV[0]eq"-blk"      ){ shift; $blk    =1;       }
	elsif($ARGV[0]eq"-blke"     ){ shift; $blk    =2;       }
	elsif($ARGV[0]eq"-blkw"     ){ shift; $blk=$blk?$blk:1; $gpcfg.="set boxwidth ".(shift)." absolute\n"; }
	elsif($ARGV[0]eq"-typ"      ){ shift; $ptyp=shift;   &ptypinit(); }
	elsif($ARGV[0]eq"-xy"       ){ shift; $colxy  =1;       }
	elsif($ARGV[0]eq"-nox"      ){ shift; $colxy  =-1;      }
	elsif($ARGV[0]eq"-col"      ){ shift; $coln   =shift;   }
	elsif($ARGV[0]eq"-multiplot"){ shift; $multiplot=shift; }
	elsif($ARGV[0]eq"-xrange"   ){ shift; $gpcfg .="set xrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-yrange"   ){ shift; $gpcfg .="set yrange [".(shift)."]\n"; }
	elsif($ARGV[0]eq"-xgrid"    ){ shift; $gpcfg .="set grid xtics\n"; }
	elsif($ARGV[0]eq"-ygrid"    ){ shift; $gpcfg .="set grid ytics\n"; }
	elsif($ARGV[0]eq"-xtics"    ){ shift; $gpcfg .=&readtics("xtics",shift); }
	elsif($ARGV[0]eq"-x2tics"   ){ shift; $gpcfg .=&readtics("x2tics",shift); }
	elsif($ARGV[0]eq"-ytics"    ){ shift; $gpcfg .=&readtics("ytics",shift); }
	elsif($ARGV[0]eq"-y2tics"   ){ shift; $gpcfg .=&readtics("y2tics",shift); }
	elsif($ARGV[0]eq"-xlabel"   ){ shift; $gpcfgl.="set xlabel \"".(shift)."\"\n"; }
	elsif($ARGV[0]eq"-ylabel"   ){ shift; $ylabel =shift;   }
	elsif($ARGV[0]eq"-title"    ){ shift; $gpcfg .="set title \"".(shift)."\"\n"; $gpcfgnf.="unset title\n"; }
	elsif($ARGV[0]eq"-size"     ){ shift; $size   =shift;   }
	elsif($ARGV[0]eq"-xsize"    ){ shift; $outopt.=" size ".(shift);   }
	elsif($ARGV[0]eq"-color"    ){ shift; $gpcfg .=&readlinestyles(shift,"lt 1 lc rgb \"#%s\""); }
	elsif($ARGV[0]eq"-style"    ){ shift; $gpcfg .=&readlinestyles(shift); }
	elsif($ARGV[0]eq"-log"      ){ shift; $gpcfg .="set logscale ".(shift)."\n"; }
	elsif($ARGV[0]eq"-key"      ){ shift; $gpcfg .="set key ".(shift)."\n"; }
	elsif($ARGV[0]eq"-outopt"   ){ shift; $outopt.=" ".(shift); }
	elsif($ARGV[0]eq"-C"        ){ shift; $gpcfg .=(shift)."\n"; }
	elsif($ARGV[0]eq"-c"        ){ shift; $gpcfg .=&readfile(shift); }
	# deprecated
	elsif($ARGV[0]eq"-2"        ){ shift; $colxy  =1;       }
	elsif($ARGV[0]eq"-3"        ){ shift; $coln   =2;       }
	elsif($ARGV[0]eq"-eps"      ){ shift; $outtyp ="eps";   }
	elsif($ARGV[0]eq"-png"      ){ shift; $outtyp ="png"; $outtyp.=" size ".(shift); }
	else{ last; }
}

open TMP,">".$tmpdat;
foreach(@dat){
	print TMP ($i++)." " if $colxy<0;
	print TMP $_;
}
close TMP;

sub ptypinit {
	if("image"eq$ptyp){
		$coln=0;
	}
}

$outopt=" ".$outopts{$outtyp} if ""eq$outopt;
$maxnum++ if $colxy<0;
$coln=$maxnum if !$coln;
$nbg=1 if "x11"ne$outtyp;
$multiplot=$maxnum if $multiplot<0;
my $nplot=$multiplot<$maxnum ? int(($maxnum-($colxy<0?1:0))/$multiplot) : 1;
$colxy=0 if $colxy<0;

sub usage {
	print "Usage: $0 {Options} {COLNAME}\n";
	print "  -typ TYP        plotting type:\n";
	print "       lines (def.) use lines\n";
	print "       boxes        use boxes (for histogram,recognition result,...)\n";
	print "       image        use image (for sonagram,confusion matrix,...)\n";
	print "       any other gnuplot plotting style (points,dots,linespoints,...)\n";
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
	print "  -x2tics [P:]L,...\n";
	print "  -y2tics [P:]L,...\n";
	print "  -xtics [P:]L,...\n";
	print "  -ytics [P:]L,...places labels L at position P (\"0.5:hallo,0.8:welt\" or \"hallo,welt\")\n";
	print "  -xlabel TXT     label for x-axis\n";
	print "  -ylabel TXT     label for y-axis (multiple labels for multiplot: seperated by ,)\n";
	print "  -title TXT      plot title\n";
	print "  -xgrid          x-axis grid\n";
	print "  -ygrid          y-axis grid\n";
	print "  -size W,H       set drawing size for gnuplot\n";
	print "  -xsize W,H      set output size of drawing in pixels (for eps use: Wcm,Hcm)\n";
	print "  -color C,C,...  define colors (exa: ff0000,00ff000)\n";
	print "  -style T:V,V,...define line styles (exa: pt:1,2,3 / lw:2,2,1) - see gnuplot: set style line\n";
	print "  -log AXIS       enable logscale (AXIS: x|y|xy)\n";
	print "  -key ARG        modifiy the key (example: -key off)\n";
	print "  -in INPUTFILE   read data form file instead of stdin\n";
	print "                  If the file is a dn3- or xml-file data file be converted by dlabpro.\n";
	print "                  You can specify the file as:\n";
	print "                   INPUTFILE              file should be of typ data\n";
	print "                   INPUTFILE::FIELD       file should be of typ object and contain a data instance named FIELD\n";
	print "                   INPUTFILE:TYP:FIELD    file should be of typ TYP and contain a data instance named FIELD\n";
	print "                   INPUTFILE:::CODE       execute CODE on restored data instance (is named 'x')\n";
	print "  -out OUTFILE    define name of generated output file (extension specifies output type - eps|png|jpg|plot / only type is also possible)\n";
	print "                  dem is a special output type which uses the previous configured one but outputs a dem- and a dat-file for gnuplot\n";
	print "  -outopt OPT     output options (example for eps/tex: color, monochrome - see gnuplot terminal typ if supported\n";
	print "  -c GPCFG        include file GPCFG in gnuplot script\n";
	print "  -C GPCMD        include command GPCMD in gnuplot script\n";
	print "  COLNAME         sorted list of column titles\n";
	print "All options can also be included in the input file.\n";
	print "The options sections start with '#' and will be splitted at spaces into single options.\n";
	print "To use spaces within the options or arguments you need to use '__'\n";
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
$dem.="set term ".$outtyps{$outtyp}.$outopt."\n";
$dem.="set encoding utf8\n";
$dem.="set output \"".$outbase.".".$outtyp."\n" if "x11"ne$outtyp;
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

exit 0 if $outdem;

exit if !$nbg && fork()!=0;

system "gnuplot ".$tmpdem;

unlink $tmpdat;
unlink $tmpdem;

sub readout {
	my $arg=shift;
	my $ooutbase=$outbase;
	my $oouttyp=$outtyp;
	if($arg=~/^(.*)\.([a-z]{3,4})$/){
		$outbase=$1;
		$outtyp=$2;
		die "unknown outtyp: $outtyp" if !exists $outtyps{$outtyp};
	}elsif(exists $outtyps{$arg}){
		$outtyp=$arg;
	}else{
		$outbase=$arg;
	}
	system "mkdir -p \"".dirname($outbase)."\"";
	if("dem"eq$outtyp){
		$outdem=1;
		$tmpdat=$outbase.".dat";
		$tmpdem=$outbase.".dem";
		$outbase=$ooutbase;
		$outtyp=$oouttyp;
	}
}

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

sub readlinestyles {
	my $args=shift;
	my $style="lt";
	if(@_){ $style=shift; }
	elsif($args=~/^([^:]*):(.*)$/){
		$style=$1." %s";
		$args=$2;
	}
	my $gp="";
	my @args=split /,/,$args;
	my $num=@args;
	$num=$maxnum+1 if @args==1;
	for(my $i=0;$i<$num;$i++){
		my $arg = @args==1 ? $args[0] : $args[$i];
		$gp.=sprintf "set style line ".($i+1)." ".$style."\n",$arg if ""ne$arg;
	}
	return $gp;
}

sub indlp {
	my $tmpxtp=&gettmp("xtp");
	my $tmptxt=&gettmp("txt");

	my @fdata=@_;
	my $ftyp="data";
	my $ffld="o";
	my $fcode="";
	if(@fdata>=2 && (my $t=splice @fdata,1,1)ne""){ $ftyp=$t; }
	if(@fdata>=2 && (my $t=splice @fdata,1,1)ne""){ $ftyp="object"; $ffld.=".".$t; }
	if(@fdata>=2 && (my $t=splice @fdata,1,1)ne""){ $fcode=$t; }
	my $fdata=join ":",@fdata;

	open FD,">".$tmpxtp;
	print FD $ftyp." o;\n";
	print FD "\"".$fdata."\" o -restore;\n";
	print FD "data x;\n";
	print FD $ffld." ' ' x =;\n"; # TODO remove non-numeric components
	print FD $fcode."\n";
	print FD "\"".$tmptxt."\" \"ascii\" x stdfile -export\n";
	print FD "quit;\n";
	close FD;

	system "dlabpro $tmpxtp";
	unlink $tmpxtp;
	return $tmptxt;
}

1;
