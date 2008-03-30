package Device::Velleman::K8055::Fuse;

use 5.008008;

use strict;
use warnings;

use vars qw($VERSION @ISA $AUTOLOAD);
use Exporter;
use IO::File;
use Data::Dumper;

@ISA = ('');

our ( @EXPORT_OK, %EXPORT_TAGS );

our $VERSION = '0.3';

=pod

=head1 NAME

Device::Velleman::K8055::Fuse - Communication with the Velleman K8055 USB experiment board using Fuse and K8055fs

=head1 VERSION

Version 0.3

=head1 ABSTRACT

Device::Velleman::K8055::Fuse provides an object-oriented  API to the k8055fs Fuse-based interface to the Velleman K8055 USB Experimental Interface Board.

Using the module, it is possible to set two 5v analog output ports, read from two 5v analog input boards, read from a 5-bit digital input stream, write to an 8-bit digital output stream, and set two digital counters with configurable gate times.

=head1 SYNOPSIS

    use Device::Velleman::K8055::Fuse
	my $dev = new(pathToDevice=>'/path/to/device','debug'=>1);

    
    # let us flicker the Analog output leds three times each
    for (my $i = 0; $i < 3; $i++)
    {
        for (my $j = 1; $j < 3; $j++)
        {
            $dev->SetAnalogChannel($j);
            $dev->ClearAnalogChannel($j == 1 ? 2 : ($j -1));
            sleep(1);
        }
    }
    # clear the analog output
    $dev->ClearAllAnalog();

In order to work with this module, the k8055fs utility must be installed. This utility relies on Fuse, which must also be installed.

=cut

# Default attributes for constructor

my %default_attrs = (

    # processing options
    pathToDevice => '/tmp/8055',    # default path to device

#k8055 digital inputs are not synced correctly with the 8-bit number representing the signal.
#There must a mapping.

    I => {

        #decimal value vs I-number
        i2d => {
            1 => 16,
            2 => 32,
            3 => 1,
            4 => 64,
            5 => 128,
        },

        #binary value vs I-number
        i2b => {
            1 => '10000',
            2 => '100000',
            3 => '1',
            4 => '1000000',
            5 => '10000000'
        },

        #bit number (0-7) value vs I-number
        i2i => {
            1 => '4',
            2 => '5',
            3 => '0',
            4 => '6',
            5 => '7',
        },

    },

);

=head2 new(%args)

The constructor. Buils the object.

Example:

New object with k8055 card initialisation

    my $dev = Device::Velleman::K8055::Fuse->new(
        initDevice => { -U => 0, pathToDevice => '/tmp/k8055', -b => 2, test => 1 },
        debug   => 1
    ) || die "Failed to get an object $!";


New object using initialized k8055 card

    my $dev = Device::Velleman::K8055::Fuse->new(
	pathToDevice => '/tmp/8055',
        debug   => 1,
    ) || die "Failed to get an object $!";


Inputs 

(optional) initDevice: hash reference containing the inputs expected by InitialiseDevice. Refer to method documentation below for input specifications. If initDevice exists, then method InitialseDevice is called inside the constructor.

debug = 0 / 1 : Debug flag for outputing debugging information

pathToDevice : the name of the path where the k8055fs commands are mounted.

Returns the object on success


=cut

sub new ($;@) {
    my ( $proto, %attrs ) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    foreach my $key ( keys %default_attrs ) {
        $self->{$key} = $default_attrs{$key};
    }
    foreach my $key ( keys %attrs ) {
        $self->{$key} = $attrs{$key};
    }
    $self->{'decimal_out'} = "0";
    $self->{'binary_out'} = [ 0, 0, 0, 0, 0, 0, 0, 0 ];

    my $dev = bless( $self, $class );
    if (defined $dev->{initDevice}) {

	$dev->InitDevice( $dev->{initDevice} );

    } else {
	#check for the existance of the directory
	warn("Mount point [$dev->{pathToDevice}] does not exist") 
		unless -d $dev->{pathToDevice};
    	warn("Mount point [$dev->{pathToDevice}] is not readable by user")
      		unless -r $dev->{pathToDevice};
    	warn("Mount point [$dev->{pathToDevice}] is not writable by user")
      		unless -w $dev->{pathToDevice};
	}


    return $dev;
}

=head2 ReadAnalogChannel();

This reads the value from the analog channel indicated by $channel (1 or 2).
The input voltage of the selected 8-bit Analogue to Digital converter channel is converted to a value
which lies between 0 and 255.

Returns the string containing the value.

=cut

sub ReadAnalogChannel ($$) {
    my $self = shift;
    my $cid  = shift;
    my $res  = $self->get( "analog_in" . $cid );
    return $res;
}

=head2 ReadAllAnalog();

This reads the values from the two analog ports into $data1 and $data2.

=cut

sub ReadAllAnalog ($) {
    my $self = shift;
    my $cid;
    $cid = 1;
    my $one = $self->get( "analog_in" . $cid );
    $cid = 2;
    my $two = $self->get( "analog_in" . $cid );
    return ( $one, $two );
}

=head2 OutputAnalogChannel();

This outputs $value to the analog channel indicated by $channel.
The indicated 8-bit Digital to Analogue Converter channel is altered according to the new value.
This means that the value corresponds to a specific voltage. The value 0 corresponds to a
minimum output voltage (0 Volt) and the value 255 corresponds to a maximum output voltage (+5V).
A value of $value lying in between these extremes can be translated by the following formula :
$value / 255 * 5V.

=cut

sub OutputAnalogChannel($$) {
    my $self = shift;
    my $cid  = shift;
    my $val  = shift;
    $self->set( "analog_out" . $cid, $val );
}

=head2 OutputAllAnalog();

This outputs $value1 to the first analog channel, and $value2 to the
second analog channel. See OutputAnalogChannel for more information.

=cut

sub OutputAllAnalog($@) {
    my $self = shift;
    my $val1 = shift;
    my $val2 = shift;
    my $cid;
    $cid = 1;
    $self->set( "analog_out" . $cid, $val1 );
    $cid = 2;
    $self->set( "analog_out" . $cid, $val2 );
}

=head2 ClearAnalogChannel();

This clears the analog channel indicated by $channel. The selected DA-channel is set to minimum output voltage (0 Volt).

Input: channel number

Output: value between 0 (min) and 255 (max)

 $dev->ClearAnalogChannel(1);

=cut

sub ClearAnalogChannel($$) {
    my $self = shift;
    my $cid  = shift;
    $self->SetAnalogChannel( $cid, 0 );
}

=head2 ($value1,$value1) ClearAllAnalog();

The two DA-channels are set to the minimum output voltage (0 volt).

Returns 255 on success. returns undef if either of the analog channels failed.

=cut

sub ClearAllAnalog($) {
    my $self = shift;
    my $cid;
    $cid = 1;
    my $one = $self->SetAnalogChannel( $cid, 0 );
    $cid = 2;
    my $two = $self->SetAnalogChannel( $cid, 0 );
    return undef if $one == undef || $two == undef;
    return 0;
}

=head2 SetAnalogChannel($channel);

The selected 8-bit Digital to Analogue Converter channel is set to maximum output voltage.
Returns the set value.

=cut

sub SetAnalogChannel($$$) {
    my $self = shift;
    my $cid  = shift;
    my $val  = shift;
    $self->set( "analog_out" . $cid, $val );
}

=head2 SetAllAnalog();

The two DA-channels are set to the maximum output voltage.
Returns 255 on success. returns undef if either of the analog channels failed.

=cut

sub SetAllAnalog ($) {
    my $self = shift;
    my $one  = $self->SetAnalogChannel( 1, 255 );
    my $two  = $self->SetAnalogChannel( 2, 255 );
    return undef unless ( $one && $two );
    return 255;
}

=head2 WriteAllDigital($value);

The channels of the digital output port are updated with the status of the corresponding
bits in the $value parameter. A high (1) level means that the microcontroller IC1 output
is set, and a low (0) level means that the output is cleared.
$value is a value between 0 and 255 that is sent to the output port (8 channels).

=cut

sub WriteAllDigital ($$) {
    my $self = shift;
    my $val  = shift;
    $self->set( "digital_out", $val );
}

=head2 ClearDigitalChannel($channel);

This clears the digital output channel $channel, which can have a value between 1 and 8
that corresponds to the output channel that is to be cleared.

This is the opposite of SetDigitalChannel.

=cut

sub ClearDigitalChannel ($$) {
    my $self = shift;
    my $cid  = shift;
    my $res  = $self->AssignDigitalChannel( $cid, 0 );
}

=head2 ClearAllDigital();

This clears (sets to 0) all digital output channels.

=cut

sub ClearAllDigital ($) {
    my $self = shift;
    for my $i ( 1 .. 8 ) { $self->ClearDigitalChannel($i); }

    #$self->set('digital_out',0);
    return 0;
}

=head2 SetDigitalChannel($channel);


This sets the digital output channel $channel, which can have a value between 1 and 8
that corresponds to the output channel that is to be cleared.

This is the opposite of ClearDigitalChannel.

=cut

sub SetDigitalChannel ($$) {
    my $self = shift;
    my $cid  = shift;
    return $self->AssignDigitalChannel( $cid, 1 );
}

=head2 AssignDigitalChannel($channel,$value,[$digitalFlag]);

This sets digital channel $channel to the assigned value.

=cut 

sub AssignDigitalChannel ($$$) {

    my $self = shift;
    my $cid  = shift;
    my $val  = shift;

    unless ( $val == 1 || $val == 0 ) {
        die
"AssignDigitalChannel: Type error: string [$val] for chanel ID [$cid] is not a binary";
    }
    print "cid:$cid val:$val\n" if $self->{'debug'};
    my $decVal = $self->{'decimal_out'} || '0';
    print "Current digital value: $decVal\n" if $self->{'debug'};

    #convert it to binary string
    my @curBinVal = @{ $self->{'binary_out'} };
    ##dec2bin($decVal);

    if ( $self->{'debug'} ) {
        print "Old Binary array: ", Dumper $self->{'binary_out'};
    }

    #set the register
    $self->{'binary_out'}->[ 8 - $cid ] = $val;

 #If the array was null and we gave a N-length array, we can end up with undefs.

    if ( $self->{'debug'} ) {
        print "New Binary Array:";
        print Dumper $self->{'binary_out'};
    }

    #turn binary array back into a string
    my $newBinVal = join( '', @{ $self->{'binary_out'} } );

    print "Binary new digital value: $newBinVal\n"
      if $self->{'debug'};

    #convert back to decimal
    my $newDecVal = $self->{'decimal_out'} = $self->bin2dec($newBinVal);

    print "Decimal new digital value: $newDecVal\n"
      if $self->{'debug'};

    #send to the device
    return $self->set( 'digital_out', $newDecVal );

}

=head2 SetAllDigital();

This sets all digital output channels to 1 (true).

$obj->SetAllDigital();

sets all digital output channels to 1, giving '1111111'.

=cut

sub SetAllDigital ($) {
    my $self   = shift;
    my $errors = 0;
    for my $i ( 1 .. 8 ) {
        my $r = $self->SetDigitalCh;
        annel($i);
        $errors++ unless $r;
    }
    return undef if $errors;
    $self->{binary_out} = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    return 1;
}

=head2 ReadAllDigital('bin') or ReadAllDigital();

This reads all 5 digital ports at once. The 5 least significant bits correspond to the
status of the input channels. A high (1) means that the channel is set, a low (0) means that the channel is cleared.
Returns the decimal value of the the 8-channel interface card (0-255) unless flag 'bin' is set.

If flag 'bin' is set, then returns an array of binary characters (0/1).

Returns undef on error.

=cut

sub ReadAllDigital ($;$) {
    my $self = shift;
    my $flag = shift || 'dec';

    #get decimal value from the device
    my $decVal = $self->get('digital_in');

    #convert it to binary string
    if ( $flag eq 'bin' ) {
        my $curBinVal = $self->dec2bin($decVal);

 #stick the string into an array. Reverse it to get the right order for an array

        my @index = split( '', $curBinVal );

        print "ReadAllDigital:[$flag]", Dumper \@index if $self->{debug};

        return @index;
    }
    return $decVal;

}

=head2 ReadDigitalChannel($channel);

The status of the selected input $channel is read.

$channel can have a value between 1 and 8 which corresponds to the input channel whose
status is to be read.

The return value will be true (1) if the channel has been set, false (0) otherwise

returns undef on error.
 
=cut

sub ReadDigitalChannel ($$) {
    my $self = shift;
    my $cid  = shift;
    die "Digital Input channel $cid not defined for this board"
      unless exists $self->{I}->{i2i}->{$cid};
    $cid = $self->{I}->{i2i}->{$cid};

    my @array = $self->ReadAllDigital('bin');

    #fetch the value for $cid
    my $val = $array[$cid] || 0;

    return $val;
}

=head2 ReadCounter($counternumber);

The function returns the status of the selected 16 bit pulse counter.
The counter number 1 counts the pulses fed to the input I1 and the counter number 2 counts the
pulses fed to the input I2.

returns an 16 bit count on success. 

returns undef on error.

=cut

sub ReadCounter ($$) {
    my $self = shift;
    my $cid  = shift;
    $self->get( "counter" . $cid );
}

=head2 ResetCounter($counternumber);

This resets the selected pulse counter.

returns undef on error.

=cut

sub ResetCounter ($$) {
    my $self = shift;
    my $cid  = shift;
    $self->set( "counter" . $cid, 0 );
}

=head2 SetCounterDebounceTime($counternumber, $debouncetime);

The counter inputs are debounced in the software to prevent false triggering when mechanical
switches or relay inputs are used. The debounce time is equal for both falling and rising edges. The
default debounce time is 2ms. This means the counter input must be stable for at least 2ms before it is
recognised, giving the maximum count rate of about 200 counts per second.
If the debounce time is set to 0, then the maximum counting rate is about 2000 counts per second.

The $deboucetime value corresponds to the debounce time in milliseconds (ms) to be set for the
pulse counter. Debounce time value may vary between 0 and 5000.

returns the set time in milliseconds on success.

returns undef on error.

=cut

sub SetCounterDebounceTime($$$) {
    my $self = shift;
    my $cid  = shift;
    my $time = shift;

    unless ( $time >= 0 && $time <= 5000 ) {
        warn
          "SetCounterDebounceTime Range Error: Shound be between 0 and 5000.";
    }

    $self->set( "debounce" . $cid, $time );
}

=head2 get($file,$value)

uses IO::File to retrieve data from the FUSE files. Refer to the k8055fs readme for details.

  $dev->set('/tmp/8055/digital_out',255);

This is a low-level call that is not particualrly intended for direct access from the API.

Returns $value on success and undef on error.

=cut

sub get ($$) {
    my $self  = shift;
    my $mfile = shift;
    my $fh    = new IO::File;
    my $res   = undef;
    my $file  = $self->{pathToDevice} . "/$mfile";

    if ( $fh->open("< $file") ) {
        my @io = <$fh>;
        $fh->close;
        if ( scalar(@io) != 1 ) {
            warn "01 get: $file: failed. $!\n";
        }
        $res = shift @io;
        print "get: $file: $res\n" if $self->{'debug'};
        chomp $res;
        $self->{io}->{$mfile} = $res;
        return $res;
    }

    die "02 get: $file: failed. $!\n";
    $self->{io}->{$mfile} = undef;
    return $self->{io}->{$mfile};
}

=head2 set($file,$value)

uses IO::File to send io to the FUSE files. Refer to the k8055fs readme for details.

  $dev->set('/tmp/8055/digital_out',255);

This is a low-level call that is not particualrly intended for direct access from the API.
Using the set function could desynchronize the internal representation for the binary array
held in array 
  
  $dev->{binary_out}

Returns $value on success and undef on error.

=cut

sub set ($$$) {
    my $self  = shift;
    my $mfile = shift;
    my $val   = shift;
    $val = "0" unless defined $val;

    my $fh = new IO::File;

    my $file = $self->{pathToDevice} . "/$mfile";

    if ( $fh->open("> $file") ) {
        print "set: $file: $val\n" if $self->{'debug'};
        print $fh $val;
        $fh->close;
        chomp $val;
        $self->{io}->{$mfile} = $val;
        return $self->{io}->{$mfile};
    }

    die "01 set: $file: failed. Unable to open file handle: $!\n";
    $self->{io}->{$mfile} = undef;
    return $self->{io}->{$mfile};
}

#from Perl Cookbook (Oreilly)

=head2 dec2bin($dec) 

convert a decimal to a string representing a bin

The binary string is represented as a big-endiani. In big-endian encoding, digits increase as the string progresses to the left:

   0 (dec) =        0 (bin).
   1 (dec) =        1 (bin).
   2 (dec) =       10 (bin).
   3 (dec) =       11 (bin).
   4 (dec) =      100 (bin).
 255 (dec) = 11111111 (bin).

=cut

sub dec2bin ($$) {
    my $self = shift;
    my $dec  = shift || 0;
    my $str  = unpack( "B32", pack( "N", $dec ) );
    $str =~ s/^0+(?=\d)//;    # otherwise you'll get leading zeros
    return $str;
}

=head2 bin2dec($bin) 

convert a string representing a binary number  to a  decimal number.

Refer to dec2bin for information on the binary format in use.

=cut

sub bin2dec ($$) {
    my $self = shift;
    my $bin  = shift;
    return unpack( "N", pack( "B32", substr( "0" x 32 . $bin, -32 ) ) );
}

=head2 InitDevice (\%args)

Initialises the k8055 USB device by mounting the k8055 file system.

usage: 
	$dev->InitialseDevice({-U=>1, -b=>2, pathToDevice=>'/tmp/8055'})

Input arguments

-b board number. (2-4) If skipped, default board (1) number is taken.

-U 1 0r 0 turn on USB debugging if true.

pathToDevice: Desired mount point of the k8055fs application.  This directory needs to be accessible by the user.

fuseOptions: additional options to pass to FUSE.


test: do not run the k8055fs initialiaation. Print the command to STDOUT and return success. This is for debugging support.

See also new().

=cut

sub InitDevice ($$) {
    my $self = shift;

    my $p = shift;
    #initialise command line attributes
    my $b          = '';
    my $U          = '';
    my $fuseArgs   = '';

    $self->{initParams} = $p;
    $b = "-b ".$p->{'-b'} if $p->{'-b'};
    $U = "-U" if $p->{'-U'};
    $fuseArgs = '-o '.$p->{fuseArgs} if $p->{fuseArgs};
	#pass the device path to the object
    $self->{pathToDevice} = $p->{pathToDevice};


	#check for the existance of the directory
    warn("Mount point [$self->{pathToDevice}] does not exist") 
	unless -d $self->{pathToDevice};
    warn("Mount point [$self->{pathToDevice}] is not readable by user")
      unless -r $self->{pathToDevice};
    warn("Mount point [$self->{pathToDevice}] is not writable by user")
      unless -w $self->{pathToDevice};


    #see k8055fs README
    my $commands =
      [ [ 'modprobe', 'fuse' ],
        [ 'k8055fs', $b, $U, $p->{pathToDevice}, $fuseArgs ] ];

    my $failed = 0;
    foreach my $action (@$commands) {
        my @args = @$action;

        my $cmd = join( " ", @args );

        push (@{$self->{init}->{cmd}}, $cmd);

        if ( $p->{test} ) {
	        print "InitialiseDevice Test: $cmd\n";
            next;
        }
        system($cmd) == 0 or warn "system $cmd failed: $?";

        #You can check all the failure possibilities by inspecting $? like this:
        if ( $? == -1 ) {
            push (@{$self->{init}->{errors}}, "Failed: [$cmd]". $failed++ . ":$!");
        }
        elsif ( $? & 127 ) {
            push (@{$self->{initParams}->{errors}}, printf "child died with signal %d, %s coredump\n",
              ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without');
            $failed++;
            push (@{$self->{init}->{errors}}, "Failed: [$cmd]". $failed++ . ":$!");
        }
        else {
            push (@{$self->{init}->{errors}}, printf "child exited with value %d\n", $? >> 8);
        }
    }

    if ($failed) {
	print STDERR join ("\n" , @{$self->{init}->{errors}}) if $failed;
	return undef;
    }
    return;
}

=head1 AUTHOR

Ronan Oger, C<< <ronan@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Special thanks to Jouke Visser, author of Device::Velleman::K8055 for writing the original win32-based module. I extensively copied his documentation and derived the method names from the names used by Jouke.

=head1 BUGS

Likely to be many, please use http://rt.cpan.org/ for reporting bugs. The counter functionality is poorly tested and I suspect it has bugs.

=head1 SEE ALSO

For more information on this board, visit http://www.velleman.be.

For more information on the K0855fs fuse implementation of K0855, visit  https://launchpad.net/k8055fs

For more information on the Fuse driver, visit the FUSE project on sourceforge: http://fuse.sourceforge.net

For Win32 applications, see Jouke Visser's Device::Velleman::K8055 implementation.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ronan Oger, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1
