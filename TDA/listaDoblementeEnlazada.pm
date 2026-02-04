package listaDoblementeEnlazada;
use strict;
use warnings;

#llamar al nodo
require 'nodo.pl';

sub new{
    my($class) = @_;
    my($self) = {
        head =>  undef,
        tail => undef,
        size => 0,
    };
    return bless $self, $class;
}

#Método para ver si está vacía
sub estaVacia{ $_[0]->{size} == 0}

#método para ver el tamaño total 
sub tamanio{ $_[0]->{size}}

#método para  hacer un push para atrás
sub pushBack{
    my($self, $valor) = @_;
    my $n = nodo->new($valor);
    #si la lista estuviera vacia
    if(!$self->{tail}){
        $self ->{head} = $self->{tail} = $n;
    }
    # si no lo estuviera
    else{
        $n -> set_prev($self->{tail});
        $self->{tail}->set_next($n);    
        $self->{tail} = $n;
    }
    #aumetar el tamaño
    $self->{size}++;
    return $n;
}

#método para insertar enfrente
sub pushFront{
    my($self, $valor) = @_;
    my $n = nodo->new($valor);
    #si la lista estuviera vacia
    if(!$self->{head}){
        $self ->{head} = $self->{tail} = $n;
    }
    # si no lo estuviera
    else{
        $n -> set_next($self->{head});
        $self->{head}->set_prev($n);    
        $self->{head} = $n;
    }
    #aumetar el tamaño
    $self->{size}++;
    return $n;
}

#método para hacer un pop en el fondo
sub popBack{
    my($self) = @_;
    return unless $self->{tail};
    my $valor = $self->{tail}->{valor};
    my $prev = $self->{tail}->{anterior};
    if($prev){
        $prev->set_next(undef);
        $self->{tail} = $prev;

    }
    else{
        $self->{tail} = $self->{head} = undef;
    }
    $self->{size}--;
    return $valor;
}

#método para hacer un pop en el frente
sub popFront{
    my($self) = @_;
    return unless $self->{head};
    my $valor = $self->{head}->{valor};
    my $next = $self->{head}->{siguiente};
    if($next){
        $next->set_prev(undef);
        $self->{head} = $next;

    }
    else{
        $self->{tail} = $self->{head} = undef;
    }
    $self->{size}--;
    return $valor;
}

#Método de búsqueda
sub find{
    my ($self, $pred) = @_;
    my $cur = $self->{head};
    while($cur){
        return $cur if $pred->{$cur->valor};
        $cur  = $cur ->siguiente;
    }
    return;

}

#Método para insertar en medio de la lista, o después de un nodo
sub insert_after{
    my($self, $nodo, $valor) = @_;
    return unless $nodo;
    my $n = nodo->new($valor);
    my $next = $nodo->siguiente;
    $n -> set_prev($nodo);
    $n -> set_next($next);
    if($next){
        $next->set_prev($n);

    }
    else {
        $self->{tail} = $n;
    }
    $self->{size}++;
    return $n;
}

#método para remover un nodo de en medio
sub remove {
    my ($self, $nodo) = @_;
    return unless $nodo;
    my $prev = $nodo->anterior; 
    my $next = $nodo->siguiente; 

    if ($prev) { 
        $prev->set_next($next)
    } 
    else { 
        $self->{head} = $next 
    } 
    
    if ($next) {
         $next->set_prev($prev) 
    } else {
         $self->{tail} = $prev 
    } $self->{size}--;
     # limpiar referencias del nodo 
    $nodo->set_prev(undef);
    $nodo->set_next(undef);
     return $nodo->value; }

#método para iterar
sub iterar{
    my($self, $codigoReferencia) = @_;
    my $cur = $self->{head};
    while ($cur){
        $codigoReferencia ->($cur);
        $cur = $cur->next; #usar el nombre que usa el nodo
    }
}

1;