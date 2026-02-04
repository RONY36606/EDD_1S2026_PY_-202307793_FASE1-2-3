package nodoCircular;
use strict;
use warnings;

sub new{
    my($class, $valor) = @_;
    my($self) = {
        valor => $valor,
        siguiente => undef,
    };
    return bless $self, $class;
}

#setters y guetters

sub valor { $_[0]->{valor} }
sub siguiente { $_[0]->{siguiente} } 
sub set_siguiente { $_[0]->{siguiente} = $_[1]; return $_[0] } 

1;