package nodoGrafo;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    
    my $self = {
        numero_colegio => $args{numero_colegio} || '',  
        nombre         => $args{nombre} || '',           
        tipo_usuario   => $args{tipo_usuario} || '',     
        departamento   => $args{departamento} || 'SIN-DEP', 
        especialidad   => $args{especialidad} || '',     
        vecinos        => [],                           
    };
    
    bless $self, $class;
    return $self;
}

# Agregar un vecino (colaborador) a la lista de adyacencia
sub agregar_vecino {
    my ($self, $colegio_vecino) = @_;
    
    # Verificar que no esté ya agregado (evitar duplicados)
    unless ($self->tiene_vecino($colegio_vecino)) {
        push @{$self->{vecinos}}, $colegio_vecino;
    }
}

# Eliminar un vecino de la lista de adyacencia
sub eliminar_vecino {
    my ($self, $colegio_vecino) = @_;
    
    @{$self->{vecinos}} = grep { $_ ne $colegio_vecino } @{$self->{vecinos}};
}

# Verificar si un colegio está en la lista de vecinos
sub tiene_vecino {
    my ($self, $colegio_vecino) = @_;
    
    foreach my $vecino (@{$self->{vecinos}}) {
        return 1 if $vecino eq $colegio_vecino;
    }
    return 0;
}

# Obtener la lista completa de vecinos
sub obtener_vecinos {
    my ($self) = @_;
    return @{$self->{vecinos}};
}

# Contar cuántos vecinos tiene (grado del nodo)
sub grado {
    my ($self) = @_;
    return scalar @{$self->{vecinos}};
}

# Getters
sub get_numero_colegio { return $_[0]->{numero_colegio}; }
sub get_nombre         { return $_[0]->{nombre}; }
sub get_tipo_usuario   { return $_[0]->{tipo_usuario}; }
sub get_departamento   { return $_[0]->{departamento}; }
sub get_especialidad   { return $_[0]->{especialidad}; }

# Setters (para actualizar departamento, por ejemplo)
sub set_departamento {
    my ($self, $nuevo_depto) = @_;
    $self->{departamento} = $nuevo_depto;
}

# Color para Graphviz según departamento
sub get_color_graphviz {
    my ($self) = @_;
    
    my %colores = (
        'DEP-MED'  => 'lightblue',   # Medicina General - Azul claro
        'DEP-CIR'  => 'lightgreen',  # Cirugía - Verde claro
        'DEP-LAB'  => 'yellow',      # Laboratorio - Amarillo
        'DEP-FAR'  => 'orange',      # Farmacia - Naranja
        'DEP-ADM'  => 'purple',      # Administración - Púrpura
        'SIN-DEP'  => 'gray',        # Sin departamento - Gris
    );
    
    return $colores{$self->{departamento}} || 'gray';
}

1;  # Los módulos en Perl deben retornar verdadero