package nodoSimple;
use strict;
use warnings;

sub new{
    my($class, $valor) = @_;
    my $self = {
        valor => $valor,
        siguiente => undef,
    }
    return bless $class, $self;
}

#colocar los guetters y setters

sub valor { $_[0]->{valor} }
sub siguiente { $_[0]->{siguiente} } 
sub set_siguiente { $_[0]->{siguiente} = $_[1]; return $_[0] } 

1;