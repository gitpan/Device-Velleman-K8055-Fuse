use Test::More tests => 15;
use Device::Velleman::K8055::Fuse;
use Data::Dumper;

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
my $pathToDevice = <FILE>;
close FILE;
my $dev = Device::Velleman::K8055::Fuse->new(
    'pathToDevice' => $pathToDevice,
    'debug'        => 1
) || die "Failed to get an object $!";

ok( $dev->SetAnalogChannel( 1, 0 ) == 0, "1 Analog Channel 1 to  0" );
ok( $dev->SetAnalogChannel( 2, 0 ) == 0, "1 Analog Channel 2 to  0" );

ok( $dev->{io}->{analog_out1} == 0, "1 Check output 1" );
ok( $dev->{io}->{analog_out2} == 0, "1 Check output 2" );

ok( $dev->SetAnalogChannel( 1, 2 ) == 2, "3 Analog Channel 1 to  2" );
ok( $dev->SetAnalogChannel( 2, 2 ) == 2, "3 Analog Channel 2 to  2" );

ok( $dev->{io}->{analog_out1} == 2, "3 Check output 1" );
ok( $dev->{io}->{analog_out2} == 2, "3 Check output 2" );

ok( $dev->SetAnalogChannel( 1, 1 ) == 1, "2 Analog Channel 1 to  1" );
ok( $dev->SetAnalogChannel( 2, 1 ) == 1, "2 Analog Channel 2 to  1" );

ok( $dev->{io}->{analog_out1} == 1, "2 Check output 1" );
ok( $dev->{io}->{analog_out2} == 1, "2 Check output 2" );

ok( $dev->SetAllAnalog() == 255, "4 Analog Channels  to  255" );

ok( $dev->{io}->{analog_out1} == 255, "4 Check output 1" );
ok( $dev->{io}->{analog_out2} == 255, "4 Check output 2" );

#print Dumper $dev;
