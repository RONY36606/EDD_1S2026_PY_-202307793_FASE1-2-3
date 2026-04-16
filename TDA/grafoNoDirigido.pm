package grafoNoDirigido;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        nodos    => {},   # colegio => { nombre, tipo, depto, ... }
        adyacencia => {}, # colegio => { colegio_vecino => 1 }
        pendientes => {}, # colegio_receptor => [ { solicitante, estado } ]
    }, $class;
}

# ── Agregar nodo (profesional) ──────────────────────────────
sub agregar_nodo {
    my ($self, %datos) = @_;
    my $col = $datos{numero_colegio} // return;
    $self->{nodos}{$col} = {
        nombre => $datos{nombre}       // '',
        tipo   => $datos{tipo_usuario} // '',
        depto  => $datos{departamento} // 'SIN-DEP',
        espec  => $datos{especialidad} // '',
    };
    # Inicializar lista de adyacencia si no existe
    $self->{adyacencia}{$col} //= {};
    $self->{pendientes}{$col}  //= [];
}

# ── Actualizar departamento de un nodo ──────────────────────
sub actualizar_depto {
    my ($self, $col, $depto) = @_;
    return unless exists $self->{nodos}{$col};
    $self->{nodos}{$col}{depto} = $depto;
}

# ── Agregar arista (colaboración ACTIVA) ────────────────────
sub agregar_arista {
    my ($self, $col_a, $col_b) = @_;
    return unless exists $self->{nodos}{$col_a} && exists $self->{nodos}{$col_b};
    return if $col_a eq $col_b;
    $self->{adyacencia}{$col_a}{$col_b} = 1;
    $self->{adyacencia}{$col_b}{$col_a} = 1;
}

# ── Eliminar arista ─────────────────────────────────────────
sub eliminar_arista {
    my ($self, $col_a, $col_b) = @_;
    delete $self->{adyacencia}{$col_a}{$col_b};
    delete $self->{adyacencia}{$col_b}{$col_a};
}

# ── Verificar si existe arista ──────────────────────────────
sub existe_arista {
    my ($self, $col_a, $col_b) = @_;
    return exists $self->{adyacencia}{$col_a}{$col_b} ? 1 : 0;
}

# ── Obtener colaboradores directos de un nodo ───────────────
sub colaboradores {
    my ($self, $col) = @_;
    return [] unless exists $self->{adyacencia}{$col};
    my @lista;
    for my $vecino (keys %{ $self->{adyacencia}{$col} }) {
        my $info = $self->{nodos}{$vecino} // {};
        push @lista, {
            numero_colegio => $vecino,
            nombre         => $info->{nombre} // '',
            tipo           => $info->{tipo}   // '',
            depto          => $info->{depto}  // '',
            espec          => $info->{espec}  // '',
        };
    }
    return \@lista;
}

# ── Sugerencias BFS 2 saltos (amigos de amigos) ─────────────
sub sugerencias {
    my ($self, $col) = @_;
    return [] unless exists $self->{adyacencia}{$col};

    my %directos    = %{ $self->{adyacencia}{$col} };
    my %conteo;   # posible_col => cuántos colaboradores en común

    for my $d (keys %directos) {
        for my $dd (keys %{ $self->{adyacencia}{$d} }) {
            next if $dd eq $col;
            next if exists $directos{$dd};
            $conteo{$dd}++;
        }
    }

    my @sugs;
    for my $posible (sort { $conteo{$b} <=> $conteo{$a} } keys %conteo) {
        my $info = $self->{nodos}{$posible} // {};
        push @sugs, {
            numero_colegio  => $posible,
            nombre          => $info->{nombre} // '',
            tipo            => $info->{tipo}   // '',
            depto           => $info->{depto}  // '',
            comunes         => $conteo{$posible},
        };
    }
    return \@sugs;
}

# ── Agregar solicitud pendiente ──────────────────────────────
sub agregar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    # Evitar duplicados
    for my $s (@{ $self->{pendientes}{$receptor} }) {
        return if $s->{solicitante} eq $solicitante;
    }
    push @{ $self->{pendientes}{$receptor} }, {
        solicitante => $solicitante,
        estado      => 'PENDIENTE',
    };
}

# ── Obtener solicitudes recibidas por un usuario ─────────────
sub solicitudes_recibidas {
    my ($self, $receptor) = @_;
    my @lista;
    for my $s (@{ $self->{pendientes}{$receptor} // [] }) {
        next unless $s->{estado} eq 'PENDIENTE';
        my $info = $self->{nodos}{ $s->{solicitante} } // {};
        push @lista, {
            solicitante => $s->{solicitante},
            nombre      => $info->{nombre} // '',
            tipo        => $info->{tipo}   // '',
            depto       => $info->{depto}  // '',
        };
    }
    return \@lista;
}

# ── Aceptar solicitud ────────────────────────────────────────
sub aceptar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    for my $s (@{ $self->{pendientes}{$receptor} // [] }) {
        if ($s->{solicitante} eq $solicitante && $s->{estado} eq 'PENDIENTE') {
            $s->{estado} = 'ACTIVA';
            $self->agregar_arista($solicitante, $receptor);
            return 1;
        }
    }
    return 0;
}

# ── Rechazar solicitud ───────────────────────────────────────
sub rechazar_solicitud {
    my ($self, $solicitante, $receptor) = @_;
    for my $s (@{ $self->{pendientes}{$receptor} // [] }) {
        if ($s->{solicitante} eq $solicitante && $s->{estado} eq 'PENDIENTE') {
            $s->{estado} = 'RECHAZADA';
            return 1;
        }
    }
    return 0;
}

# ── Lista de adyacencia completa ─────────────────────────────
sub lista_adyacencia {
    my ($self) = @_;
    my @result;
    for my $col (sort keys %{ $self->{nodos} }) {
        my @vecinos = sort keys %{ $self->{adyacencia}{$col} // {} };
        push @result, {
            nodo    => $col,
            nombre  => $self->{nodos}{$col}{nombre} // '',
            depto   => $self->{nodos}{$col}{depto}  // '',
            vecinos => \@vecinos,
        };
    }
    return \@result;
}

# ── Todos los nodos ──────────────────────────────────────────
sub todos_nodos {
    my ($self) = @_;
    my @lista;
    for my $col (sort keys %{ $self->{nodos} }) {
        push @lista, {
            numero_colegio => $col,
            %{ $self->{nodos}{$col} },
        };
    }
    return \@lista;
}

# ── Usuarios sin departamento (SIN-DEP) ──────────────────────
sub nodos_sin_depto {
    my ($self) = @_;
    my @lista;
    for my $col (sort keys %{ $self->{nodos} }) {
        if (($self->{nodos}{$col}{depto} // 'SIN-DEP') eq 'SIN-DEP') {
            push @lista, {
                numero_colegio => $col,
                %{ $self->{nodos}{$col} },
            };
        }
    }
    return \@lista;
}

1;