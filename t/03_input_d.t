use Test::More tests => 6;
use Device::Velleman::K8055::Fuse;
use Data::Dumper;

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
my $pathToDevice = <FILE>;
close FILE;
my $dev = Device::Velleman::K8055::Fuse->new(
    'pathToDevice' => $pathToDevice,
    'debug'        => 1
) || die "Failed to get an object $!";

ok( $dev->ReadDigitalChannel(1) >= 0, "3 Digital Channel 1" );
ok( $dev->ReadDigitalChannel(2) >= 0, "4 Digital Channel 2" );
ok( $dev->ReadDigitalChannel(3) >= 0, "5 Digital Channel 3" );
ok( $dev->ReadDigitalChannel(4) >= 0, "6 Digital Channel 4" );
ok( $dev->ReadDigitalChannel(5) >= 0, "7 Digital Channel 5" );
ok( $dev->ReadAllDigital(),           "8 All Digital" );
