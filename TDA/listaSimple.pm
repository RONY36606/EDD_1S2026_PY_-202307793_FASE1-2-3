package listaSimple;
use strict;
use warnings;

require 'nodoSimple.pl';

sub new{
    my($class) = @_;
    my $self = {
        head => undef,
        size => 0,
    };

    return bless $self, $class;
}

sub insertar_final{
    my($self, $valor) = @_;
    my $nodo = nodoSimple->new($valor);

    if(!$self->{head}){
        $self->{head} = $nodo;
    }
    else{
        my $cur = $self->{head};
        while($cur->siguiente){
            $cur = $cur->siguiente;
        }
        $cur->set_siguiente($nodo);
    }
    $self->{size}++;
    return $nodo;
}

sub insertar_inicio{
    my($self, $valor) = @_;
    my $nodo = nodoSimple->new($valor);
    $nodo->set_siguiente($self->{head});
    $self->{head} = $nodo;
    $self->{size}++;
    return $nodo;
    
}

sub recorrer{
    my($self, $codigoReferencia)=@_;
    my $cur = $self->{head};
    for(1 .. $self->{size}){
        $codigoReferencia->($cur);
        $cur = $cur->siguiente;
    }

}

sub size { $_[0]->{size} } 

1;