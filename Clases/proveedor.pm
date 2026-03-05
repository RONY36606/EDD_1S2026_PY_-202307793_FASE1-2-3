package proveedor;
use strict;
use warnings;

#llamar a la lista simple
use lib 'TDA';
use listaSimple;
use lib 'Clases';
use entregaProveedorAct;

sub new {
    my ($class, %args) = @_;
    my $self = {
        nit               => $args{nit}               || '',
        nombreEmpresa     => $args{nombreEmpresa}     || '',
        contactoPrincipal => $args{contactoPrincipal} || '',
        telefono          => $args{telefono}          || '',
        direccion         => $args{direccion}         || '',
        entregas          => listaSimple->new,
    };
    return bless $self, $class;
}

# Getters y setters
sub nit { $_[0]->{nit} } 
sub set_nit { $_[0]->{nit} = $_[1] } 

sub nombreEmpresa { $_[0]->{nombreEmpresa} } 
sub set_nombreEmpresa { $_[0]->{nombreEmpresa} = $_[1] } 

sub contactoPrincipal { $_[0]->{contactoPrincipal} } 
sub set_contactoPrincipal { $_[0]->{contactoPrincipal} = $_[1] } 

sub telefono { $_[0]->{telefono} } 
sub set_telefono { $_[0]->{telefono} = $_[1] } 

sub direccion { $_[0]->{direccion} } 
sub set_direccion { $_[0]->{direccion} = $_[1] } 

#=========================NUEVA SECCIÓN DE MANEJO DE ENTREGAS===============================

# Recibe un objeto entregaProveedorAct ya construido y lo agrega a la lista
sub agregarEntrega {
    my ($self, $entrega) = @_;
    $self->{entregas}->insertar_final($entrega);
}

# Devuelve cuántas entregas tiene este proveedor
sub totalEntregas {
    my ($self) = @_;
    my $count = 0;
    $self->{entregas}->recorrer(sub { $count++ });
    return $count;
}

# Recorre todas las entregas y ejecuta un callback por cada una
sub recorrerEntregas {
    my ($self, $callback) = @_;
    $self->{entregas}->recorrer(sub {
        my $nodo = shift;
        $callback->($nodo->valor);
    });
}

# Buscar una entrega por número de factura
sub buscarEntrega {
    my ($self, $numeroFactura) = @_;
    my $encontrada = undef;
    $self->{entregas}->recorrer(sub {
        my $nodo    = shift;
        my $entrega = $nodo->valor;
        $encontrada = $entrega if $entrega->numeroFactura eq $numeroFactura;
    });
    return $encontrada;
}

1;