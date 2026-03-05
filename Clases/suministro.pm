package suministro;
use strict;
use warnings;

#constructor 
sub new{
    my($class, %args) =@_;
    my $self = {
        tipo => $args{tipo} || '',
        codigoSuministro => $args{codigoSuministro} || '',
        nombreSuministro => $args{nombreSuministro} || '',
        fabricanteSuministro => $args{fabricanteSuministro} || '',
        precioSuministro => $args{precioSuministro} || 0,
        cantidadSuministro => $args{cantidadSuministro} || 0,
        fechaVencimientoSuministro => $args{fechaVencimientoSuministro} || '',
        nivelMinimoReorden => $args{nivelMinimoReorden} || 0,
    };
    return bless $self, $class;
}

sub tipo {
    my ($self, $val) = @_;
    $self->{tipo} = $val if defined $val;
    return $self->{tipo};
}

sub codigoSuministro {
    my ($self, $val) = @_;
    $self->{codigoSuministro} = $val if defined $val;
    return $self->{codigoSuministro};
}

sub nombreSuministro {
    my ($self, $val) = @_;
    $self->{nombreSuministro} = $val if defined $val;
    return $self->{nombreSuministro};
}

sub fabricanteSuministro {
    my ($self, $val) = @_;
    $self->{fabricanteSuministro} = $val if defined $val;
    return $self->{fabricanteSuministro};
}

sub precioSuministro {
    my ($self, $val) = @_;
    $self->{precioSuministro} = $val if defined $val;
    return $self->{precioSuministro};
}

sub cantidadSuministro {
    my ($self, $val) = @_;
    $self->{cantidadSuministro} = $val if defined $val;
    return $self->{cantidadSuministro};
}

sub fechaVencimientoSuministro {
    my ($self, $val) = @_;
    $self->{fechaVencimientoSuministro} = $val if defined $val;
    return $self->{fechaVencimientoSuministro};
}

sub nivelMinimoReorden {
    my ($self, $val) = @_;
    $self->{nivelMinimoReorden} = $val if defined $val;
    return $self->{nivelMinimoReorden};
}

1;