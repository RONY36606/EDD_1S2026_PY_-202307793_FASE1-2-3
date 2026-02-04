package medicamento;
use strict;
use warnings;

#constructor 
sub new{
    my($class, %args) =@_;
    my $self = {
        codigoMedicina => $args{codigoMedicina} || '',
        nombreComercial => $args{nombreComercial} || '',
        principioActivo => $args{principioActivo} || '',
        laboratorioFabricante => $args{laboratorioFabricante} || '',
        cantidadStock => $args{cantidadStock} || 0,
        fechaVencimiento => $args{fechaVencimiento} || '',
        precio => $args{precio} || 0,
        nivelMinimoReorden => $args{nivelMinimoReorden} || 0,
    };
    return bless $self, $class;
}

# Getters y setters
sub codigoMedicina { $_[0]->{codigoMedicina} } 
sub set_codigoMedicina { $_[0]->{codigoMedicina} = $_[1] } 

sub nombreComercial { $_[0]->{nombreComercial} } 
sub set_nombreComercial { $_[0]->{nombreComercial} = $_[1] } 

sub principioActivo { $_[0]->{principioActivo} } 
sub set_principioActivo { $_[0]->{principioActivo} = $_[1] } 

sub laboratorioFabricante { $_[0]->{laboratorioFabricante} } 
sub set_laboratorioFabricante { $_[0]->{laboratorioFabricante} = $_[1] } 

sub cantidadStock { $_[0]->{cantidadStock} } 
sub set_cantidadStock { $_[0]->{cantidadStock} = $_[1] } 

sub fechaVencimiento { $_[0]->{fechaVencimiento} } 
sub set_fechaVencimiento { $_[0]->{fechaVencimiento} = $_[1] } 

sub precio { $_[0]->{precio} } 
sub set_precio { $_[0]->{precio} = $_[1] } 

sub nivelMinimoReorden { $_[0]->{nivelMinimoReorden} } 
sub set_nivelMinimoReorden { $_[0]->{nivelMinimoReorden} = $_[1] }

1;