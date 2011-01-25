package hlp;

use File::Basename;

my @tmpdir=($ENV{"TEMP"},$ENV{"TMP"},"/dev/shm","/tmp");
while(@tmpdir && ! -d $tmpdir[0]){ shift @tmpdir; }
die "No temporaty directory found" if !@tmpdir;

sub gettmp {
	my $ext=shift;
	return $tmpdir[0]."/".basename($0).".".$$.".".$ext;
}

1;
