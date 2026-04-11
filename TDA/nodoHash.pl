package nodoHash;

use strict;
use warnings;

sub new {
    my ($class, $usuario_obj) = @_;
    
    my $self = {
        usuario => $usuario_obj, # Referencia al objeto usuario (del AVL)
        siguiente => undef,      # Para manejo de colisiones (encadenamiento)
    };
    
    bless $self, $class;
    return $self;
}

# Getters y Setters
sub get_usuario   { return $_[0]->{usuario}; }
sub get_siguiente { return $_[0]->{siguiente}; }
sub set_siguiente { $_[0]->{siguiente} = $_[1]; }

1;