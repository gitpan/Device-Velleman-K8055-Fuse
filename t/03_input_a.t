use Test::More tests => 4;
use Device::Velleman::K8055::Fuse;
use Data::Dumper;

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
my $pathToDevice = <FILE>;
close FILE;
my $dev = Device::Velleman::K8055::Fuse->new(
    'pathToDevice' => $pathToDevice,
    'debug'        => 1
) || die "Failed to get an object $!";

ok( defined($dev) && ref $dev eq 'Device::Velleman::K8055::Fuse',
    'new() works' );
ok( $dev->ReadAnalogChannel(1) >= 0, "1 Analog Channel 1" );
ok( $dev->ReadAnalogChannel(2) >= 0, "2 Analog Channel 2" );
ok( $dev->ReadAllAnalog(),           "11 All Analog" );
