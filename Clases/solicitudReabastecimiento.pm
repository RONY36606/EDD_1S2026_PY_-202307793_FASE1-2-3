package solicitudReabastecimiento;
use strict;
use warnings;

sub new{
    my($class, %args)=@_;
    my $self = {
        departamento => $args{departamento} || '',
        medicamentoRequerido => $args{medicamentoRequerido} || '',
        cantidadSolicitada => $args{cantidadSolicitada} || 0,
        fechaSolicitud => $args{fechaSolicitud} || '',
        estadoSolicitud => $args{estadoSolicitud} || '',
    };
    return bless $self, $class;
};

# Getters y setters
sub departamento { $_[0]->{departamento} } 
sub set_departamento { $_[0]->{departamento} = $_[1] } 

sub medicamentoRequerido { $_[0]->{medicamentoRequerido} } 
sub set_medicamentoRequerido { $_[0]->{medicamentoRequerido} = $_[1] } 

sub cantidadSolicitada { $_[0]->{cantidadSolicitada} } 
sub set_cantidadSolicitada { $_[0]->{cantidadSolicitada} = $_[1] } 

sub fechaSolicitud { $_[0]->{fechaSolicitud} } 
sub set_fechaSolicitud { $_[0]->{fechaSolicitud} = $_[1] } 

sub estadoSolicitud { $_[0]->{estadoSolicitud} } 
sub set_estadoSolicitud { $_[0]->{estadoSolicitud} = $_[1] } 

1;