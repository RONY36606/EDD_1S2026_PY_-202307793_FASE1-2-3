package nodoCircularDoble;
use strict;
use warnings;

sub new {
    my ($class, $valor) = @_;
    my $self = {
        valor     => $valor,
        siguiente => undef,
        anterior  => undef,
    };
    return bless $self, $class;
}

#GUETTERS Y SETTER USADOS 

sub valor     { $_[0]->{valor} }
sub siguiente { $_[0]->{siguiente} }
sub anterior  { $_[0]->{anterior} }

sub set_siguiente { $_[0]->{siguiente} = $_[1]; return $_[0] }
sub set_anterior  { $_[0]->{anterior}  = $_[1]; return $_[0] }

1;
