package equipo;
use strict;
use warnings;


#constructor 
sub new{
    my($class, %args) =@_;
    my $self = {
        tipo => $args{tipo} || '',
        codigoEquipo => $args{codigoEquipo} || '',
        nombreEquipo => $args{nombreEquipo} || '',
        fabricanteEquipo => $args{fabricanteEquipo} || '',
        precioEquipo => $args{precioEquipo} || 0,
        cantidadEquipo => $args{cantidadEquipo} || 0,
        fechaIngresoEquipo => $args{fechaIngresoEquipo} || '',
        nivelMinimoReorden => $args{nivelMinimoReorden} || 0,
    };
    return bless $self, $class;
}

sub tipo {
    my ($self, $val) = @_;
    $self->{tipo} = $val if defined $val;
    return $self->{tipo};
}

sub codigoEquipo {
    my ($self, $val) = @_;
    $self->{codigoEquipo} = $val if defined $val;
    return $self->{codigoEquipo};
}

sub nombreEquipo {
    my ($self, $val) = @_;
    $self->{nombreEquipo} = $val if defined $val;
    return $self->{nombreEquipo};
}

sub fabricanteEquipo {
    my ($self, $val) = @_;
    $self->{fabricanteEquipo} = $val if defined $val;
    return $self->{fabricanteEquipo};
}

sub precioEquipo {
    my ($self, $val) = @_;
    $self->{precioEquipo} = $val if defined $val;
    return $self->{precioEquipo};
}

sub cantidadEquipo {
    my ($self, $val) = @_;
    $self->{cantidadEquipo} = $val if defined $val;
    return $self->{cantidadEquipo};
}

sub fechaIngresoEquipo {
    my ($self, $val) = @_;
    $self->{fechaIngresoEquipo} = $val if defined $val;
    return $self->{fechaIngresoEquipo};
}

sub nivelMinimoReorden {
    my ($self, $val) = @_;
    $self->{nivelMinimoReorden} = $val if defined $val;
    return $self->{nivelMinimoReorden};
}

1;