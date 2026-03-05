package nodoAvl;
use strict;
use warnings;

sub new {
    my ($class, $clave, $valor)= @_;
    my $self = {
        clave     => $clave,
        valor     => $valor,
        izq => undef,
        der  => undef,
        altura => 1,
    };
    return bless $self, $class;
}

1;