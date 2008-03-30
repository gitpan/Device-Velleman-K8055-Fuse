use Test::More tests => 14;
use Data::Dumper;

use_ok( Device::Velleman::K8055::Fuse,
    "Device::Velleman::K8055::Fuse availability" );

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";

ok( my $pathToDevice = <FILE>, "Setting device path for test" );

close FILE;

my $feedback = '';
my $newArgs   = {
    pathToDevice => $pathToDevice,
    debug        => 1,
    initDevice   => { pathToDevice => $pathToDevice, fuseArgs => 'nonempty' },
};


opendir(DIR,$pathToDevice) || die "Cant opendir $pathToDevice: $!";
my @commandList = readdir(DIR);
closedir(DIR);

if ( scalar @commandList > 5 ) {
    $feedback = ' in test mode. Device already activated';
    $newArgs->{initDevice}->{test} = 1;
} else {
    $feedback = '... Device activation succesful.';
}

$dev = Device::Velleman::K8055::Fuse->new(%$newArgs)
  || die "Failed to get an object $!";

ok( defined($dev) && ref $dev eq 'Device::Velleman::K8055::Fuse',
    'new() works' . $feedback );

ok( $myPathToDevice = $dev->{'pathToDevice'}, "path to device succesfully set" );

ok( -e "$myPathToDevice/analog_in1",  "analog_in1" );
ok( -e "$myPathToDevice/analog_in2",  "analog_in2" );
ok( -e "$myPathToDevice/analog_out1", "analog_out1" );
ok( -e "$myPathToDevice/analog_out2", "analog_out2" );
ok( -e "$myPathToDevice/counter1",    "counter1" );
ok( -e "$myPathToDevice/counter2",    "counter2" );
ok( -e "$pathToDevice/debounce1",   "debounce1" );
ok( -e "$pathToDevice/debounce2",   "debounce2" );
ok( -e "$pathToDevice/digital_in",  "digital_in" );
ok( -e "$pathToDevice/digital_out", "digital_out" );


