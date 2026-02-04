package listaCircularDoble;
use strict;
use warnings;

require 'nodoCircularDoble.pl';

sub new{
    my($class) = @_;
    my $self = {
        head => undef,
        size=>0,
    };
    return bless $self, $class;
}

sub insertar{
    my($self, $valor) = @_;
    my $nodo = nodoCircularDoble->new($valor);

    if(!$self->{head}){
        $self->{head}=$nodo;
        $nodo->set_anterior($nodo);
        $nodo->set_siguiente($nodo);
    }
    else{
        my $tail = $self->obtener_tail;
        $tail->set_siguiente($nodo);
        $nodo->set_anterior($tail);
        $nodo->set_siguiente($self->{head});
        $self->{head}->set_anterior($nodo);
    }
    $self->{size}++;
    return $nodo;
}

sub obtener_tail{
    my ($self) = @_;
    return undef unless $self->{head};
    my $cur = $self->{head};
    while($cur->siguiente ne $self->{head}){
        $cur = $cur->siguiente;
    }
    return $cur;
}

sub recorrerAdelante{
    my($self, $codigoReferencia)=@_;
    return undef unless $self->{head};
    my $cur = $self->{head};
    for(1 .. $self->{size}){
        $codigoReferencia->($cur);
        $cur = $cur->siguiente;
    }
}

sub recorrerAtras{
    my($self, $codigoReferencia)=@_;
    return undef unless $self->{head};
    my $cur = $self->obtener_tail;
    for(1 .. $self->{size}){
        $codigoReferencia->($cur);
        $cur = $cur->anteriorS;
    }
}

sub size { $_[0]->{size} } 

1;