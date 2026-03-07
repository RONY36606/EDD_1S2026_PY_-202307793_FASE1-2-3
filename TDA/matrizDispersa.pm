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

# Obtener todas las filas (proveedores, en caso de la fase 2) disponibles
sub obtenerFilas {
    my ($self) = @_;
    return keys %{ $self->{filas} };
}

# Obtener todas las columnas (fabricantes, en la fase 2) disponibles
sub obtenerColumnas {
    my ($self) = @_;
    return keys %{ $self->{columnas} };
}

# Obtener cantidad total de una celda proveedor-fabricante
sub obtenerCantidad {
    my ($self, $fila, $columna) = @_;
    my $actual = $self->{filas}{$fila};
    #con esto vamos a recorrer a los proveedores que tenemos en memoria
    while ($actual) {
        if ($actual->{columna} eq $columna) {
            # El valor es un objeto medicamento, equipo o suministro
            # sumamos según el tipo de objeto
            my $cant = 0;
            my $v = $actual->{valor};
            if ($v->can('cantidadStock'))     { $cant = $v->cantidadStock;     }
            elsif ($v->can('cantidadEquipo')) { $cant = $v->cantidadEquipo;    }
            elsif ($v->can('cantidadSuministro')) { $cant = $v->cantidadSuministro; }
            return $cant;
        }
        $actual = $actual->{derecha};
    }
    return 0;
}


#Esto devuelve la matriz disperza como un JSON
#{ filas=>[], columnas=>[], celdas=>[ {fila, columna, cantidad} ] }
sub obtenerMatriz {
    my ($self) = @_;
    my @filas    = sort keys %{ $self->{filas} };
    my @columnas = sort keys %{ $self->{columnas} };
    my @celdas;

    for my $fila (@filas) {
        my $actual = $self->{filas}{$fila};
        while ($actual) {
            my $v    = $actual->{valor};
            my $cant = 0;
            if    ($v->can('cantidadStock'))       { $cant = $v->cantidadStock;       }
            elsif ($v->can('cantidadEquipo'))      { $cant = $v->cantidadEquipo;      }
            elsif ($v->can('cantidadSuministro'))  { $cant = $v->cantidadSuministro;  }

            # Verificar si ya existe una celda para este proveedor-fabricante
            my $existente = undef;
            for my $celda (@celdas) {
                if ($celda->{fila} eq $fila && $celda->{columna} eq $actual->{columna}) {
                    $existente = $celda;
                    last;
                }
            }

            if ($existente) {
                # Sumar a la celda existente
                $existente->{cantidad} += $cant;
            } else {
                # Crear nueva celda
                push @celdas, {
                    fila     => $fila,
                    columna  => $actual->{columna},
                    cantidad => $cant,
                };
            }

            $actual = $actual->{derecha};
        }
    }

    return {
        filas    => \@filas,
        columnas => \@columnas,
        celdas   => \@celdas,
    };
}