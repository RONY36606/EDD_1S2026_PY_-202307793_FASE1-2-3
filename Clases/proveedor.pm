package proveedor;
use strict;
use warnings;

#llamar a la lista simple
use lib 'TDA';
use listaSimple;
use lib 'Clases';
use entregaProveedor;

sub new{
    my($class, %args) = @_;
    my $self = {
        nit => $args{nit} || '',
        nombreEmpresa => $args{nombreEmpresa} || '',
        contactoPrincipal => $args{contactoPrincipal} || '',
        telefono => $args{telefono} || '',
        direccion => $args{direccion} || '',
        entregas => listaSimple->new,
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

#Método para insertar el la entrega realizada
sub registroEntrega{
    my($self, %args) = @_;
    my $entrega = entregaProveedor->new(%args);
    $self->{entregas}->insertar_final($entrega);
}

#Método para listar todas las entregas realizadas

sub listarEntregas{
    my($self) = @_;
    $self->{entregas}->recorrer(sub {
        my $nodo = shift;
        my $entrega = $nodo->valor;
        print $entrega->nit, " - ", $entrega->codigoMedicamento, "\n";
    });
}

1;