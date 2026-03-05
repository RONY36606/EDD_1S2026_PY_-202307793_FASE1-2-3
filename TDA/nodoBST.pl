package nodoBST;
use strict;
use warnings;

#Este es parecido a los otros nodos, menos por la altura

    sub new {
    my ($class, $clave, $valor)= @_;
    my $self = {
        clave     => $clave,
        valor     => $valor,
        izq => undef,
        der  => undef,
    };
    return bless $self, $class;
}

1;