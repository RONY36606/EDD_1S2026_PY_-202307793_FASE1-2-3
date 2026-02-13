package nodoMatriz;
use strict;
use warnings;

sub new{
    my($class, %args)=@_;
    my $self ={
        fila => $args{fila},
        columna => $args{columna},
        valor => $args{valor},
        derecha => undef,
        abajo => undef,
    };
    return bless $self, $class;
}

# getters / setters 
sub fila { $_[0]->{fila} } 
sub set_fila { $_[0]->{fila} = $_[1] } 
sub columna { $_[0]->{columna} } 
sub set_columna { $_[0]->{columna} = $_[1] } 
sub valor { $_[0]->{valor} } 
sub set_valor { $_[0]->{valor} = $_[1] } 
sub derecha { $_[0]->{derecha} } 
sub set_derecha { $_[0]->{derecha} = $_[1] } 
sub abajo { $_[0]->{abajo} } 
sub set_abajo { $_[0]->{abajo} = $_[1] } 
1;