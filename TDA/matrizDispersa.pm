package matrizDispersa;
use strict;
use warnings;
 require 'nodoMatriz.pl';

 sub new{
    my($class)=@_;
    my $self ={
        filas => {},
        columnas => {},
    };
    return bless $self, $class;
 }

 sub insertar{
    my($self, $fila, $columna, $valor)=@_;
    my $nuevo = nodoMatriz->new(
    fila    => $fila,
    columna => $columna,
    valor   => $valor
);


    #insertar una fila
    if(!$self->{filas}{$fila}){
        #Si no hay una fila nueva creada
        $self->{filas}{$fila} = $nuevo;
    }else{
         #si ya hay más nodos en la fila, procedemos a recorrer todos las nodos, hacía la dercha, para colocar un nodo nuevo a la posición
        my $actual = $self->{filas}{$fila};
        while($actual->{derecha}){
            $actual = $actual-> {derecha};
        }
        $actual->{derecha} = $nuevo;

    }

    #insertar una columna
    if(!$self->{columnas}{$columna}){
        #Si no hay un nodo dentro de la columna, se crea uno
        $self->{columnas}{$columna} = $nuevo;
    }else{
        #si ya hay más nodos en la columna, procedemos a recorrer todos las nodos, hacía abajo, para colocar un nodo nuevo a la posición
        my $actual = $self->{columnas}{$columna};
        while($actual->{abajo}){
            $actual = $actual-> {abajo};
        }
        $actual->{abajo} = $nuevo;
         
    }
 }

sub imprimir { 
    my ($self) = @_; 
    foreach my $fila (keys %{$self->{filas}}) { 
        my $actual = $self->{filas}{$fila}; 
        print "Fila $fila: "; 
        while ($actual) { 
            print "[$actual->{columna}: $actual->{valor}] -> ";
            $actual = $actual->{derecha}; } print "NULL\n"; }
             }