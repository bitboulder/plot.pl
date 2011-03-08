package hlp;

use File::Basename;

my @tmpdir=($ENV{"TEMP"},$ENV{"TMP"},"/dev/shm","/tmp");
while(@tmpdir && ! -d $tmpdir[0]){ shift @tmpdir; }
die "No temporary directory found" if !@tmpdir;
$tmpdir[0]=~s/\\/\//g;

sub gettmp {
	my $ext=shift;
	return $tmpdir[0]."/".basename($0).".".$$.".".$ext;
}

1;
