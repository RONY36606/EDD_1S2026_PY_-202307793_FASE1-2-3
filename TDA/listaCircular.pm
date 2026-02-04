package listaCircular
use strict;
use warnings;
require 'nodoCircular.pl'

sub new{
    my($class) = @_;
    my $self = {
        head => undef,
        size => 0,
    }

    return bless $class, $self;
}

sub insertar{
    my($self, $valor) = @_;
    my $nodo = nodoCircular->new($valor);

    if(!$self->{head}){
        $self->{head} = $nodo;
        $nodo->set_siguiente($nodo);
    }
    else{
        $tail = $self->obtener_tail;
        $tail->set_siguiente($nodo);
        $nodo->set_siguiente($self->{head});
    }

    $self->{size}++;
    return $nodo;
}

#buscar la cola dentro de ls lista circular cawn
sub obtener_tail{
    my ($self) = @_;
    return undef unless $self->{head};
    my $cur = $self->{head}
    while($cur->siguiente ne $self->{head}){
        $cur = $cur->siguiente;
    }
    return $cur; #cur es una variable que nos sirve para iterar la lista
}

#Esto es para iterar
sub recorrer{
    my($self, $codigoReferencia)=@_;
    return unless $self->{head};
    my $cur = $self->{head};
    for(1 .. $self-{size}){
        #recorrer las posiciones de la lista
        $codigoReferencia->($cur);
        $cur = $cur->siguiente;
    }
}

#devolver el tamaño de la lista
sub size {$_[0]->{size}}

1;