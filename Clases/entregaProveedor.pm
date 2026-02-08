package entregaProveedor;
use strict;
use warnings;

sub new{
    my($class, %args) = @_;
    my $self = {
        nit => $args{nit} || '',
        fechaEntrega => $args{fechaEntrega} || '',
        numeroFactura => $args{numeroFactura} || '',
        codigoMedicamento => $args{codigoMedicamento} || '',
        cantidadEntregada => $args{cantidadEntregada} || 0,
    };

    return bless $self, $class;
};

# Getters y setters

sub nit { $_[0]->{nit} } 
sub set_nit { $_[0]->{nit} = $_[1] } 

sub fechaEntrega { $_[0]->{fechaEntrega} } 
sub set_fechaEntrega { $_[0]->{fechaEntrega} = $_[1] } 

sub numeroFactura { $_[0]->{numeroFactura} } 
sub set_numeroFactura { $_[0]->{numeroFactura} = $_[1] } 

sub codigoMedicamento { $_[0]->{codigoMedicamento} } 
sub set_codigoMedicamento { $_[0]->{codigoMedicamento} = $_[1] } 

sub cantidadEntregada { $_[0]->{cantidadEntregada} } 
sub set_cantidadEntregada { $_[0]->{cantidadEntregada} = $_[1] } 

1;