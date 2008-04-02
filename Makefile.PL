use 5.008008;
use ExtUtils::MakeMaker;
use Config;

exit(0) if($ENV{AUTOMATED_TESTING});

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless (-t STDIN) {
  warn(
    "\n",
    "====================================================================\n",
    "\n",
    "Assuming --default because standard input is not a terminal.\n",
    "\n",
    "====================================================================\n",
    "\n",
  );
  push @ARGV, "--default";
}

# Get the mount point for k8055fs  for the user.

my $prompt = qq|
Please give the k8055fs mount path name for testing.
 Refer to the k8055 readme for more information.
If the path does not exist it will be created|;

my $ret2 = "/tmp/8055";

if (grep /^--default$/, @ARGV) {
  print $prompt, " [/tmp/8055] \n\n";
} else {
  $ret2 = prompt($prompt, "/tmp/8055");
}

my $pathFileName2 = 't/pathToDevice.txt';

unless(-d $ret2) {
    mkdir($ret2);
}

open(TOUCH,"+>$pathFileName2"); print TOUCH $ret2; close TOUCH;










print "\n";

WriteMakefile(
    NAME              => 'Device::Velleman::K8055::Fuse',
    VERSION_FROM      => 'lib/Device/Velleman/K8055/Fuse.pm', # finds $VERSION
    PREREQ_PM         => {IO::File=>1.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Device/Velleman/K8055/Fuse.pm', # retrieve abstract from module
       AUTHOR         => 'Ronan Oger<ronan@cpan.org>') : ()),
);






print "\n";

WriteMakefile(
    NAME              => 'Device::Velleman::K8055::Fuse',
    VERSION_FROM      => 'lib/Device/Velleman/K8055/Fuse.pm', # finds $VERSION
    PREREQ_PM         => {IO::File=>1.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Device/Velleman/K8055/Fuse.pm', # retrieve abstract from module
       AUTHOR         => 'Ronan Oger<ronan@cpan.org>') : ()),
);
