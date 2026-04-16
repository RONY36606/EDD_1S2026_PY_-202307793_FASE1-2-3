package tablaHash;
use strict;
use warnings;

# Tamaño de la tabla interna (número de slots por bucket de tipo)
use constant TABLA_SIZE => 13;   # primo para distribución uniforme

sub new {
    my ($class) = @_;
    # tabla: { 'TIPO-01' => [ [slot0,...], [slot1,...], ... ], ... }
    my %tabla;
    for my $t (qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04)) {
        # Cada slot es undef o una lista por chaining
        $tabla{$t} = [ map { [] } 0 .. TABLA_SIZE - 1 ];
    }
    return bless {
        tabla    => \%tabla,
        conteo   => { 'TIPO-01'=>0, 'TIPO-02'=>0, 'TIPO-03'=>0, 'TIPO-04'=>0 },
        colisiones => { 'TIPO-01'=>0, 'TIPO-02'=>0, 'TIPO-03'=>0, 'TIPO-04'=>0 },
    }, $class;
}

# ── Función hash interna (sobre el número de colegio) ───────
sub _hash {
    my ($self, $clave) = @_;
    my $suma = 0;
    $suma += ord($_) for split //, $clave;
    return $suma % TABLA_SIZE;
}

# ── Insertar usuario ─────────────────────────────────────────
sub insertar {
    my ($self, $col, $datos) = @_;
    my $tipo = $datos->{tipo} // '';
    return unless exists $self->{tabla}{$tipo};

    my $slot = $self->_hash($col);
    my $bucket = $self->{tabla}{$tipo}[$slot];

    # Verificar si ya existe (actualizar en su lugar)
    for my $entry (@$bucket) {
        if ($entry->{colegio} eq $col) {
            $entry->{datos} = $datos;
            return;
        }
    }

    # Colisión si el slot ya tenía algún elemento
    $self->{colisiones}{$tipo}++ if @$bucket > 0;

    push @$bucket, { colegio => $col, datos => $datos };
    $self->{conteo}{$tipo}++;
}

# ── Eliminar usuario ─────────────────────────────────────────
sub eliminar {
    my ($self, $col, $tipo) = @_;
    return unless $tipo && exists $self->{tabla}{$tipo};

    my $slot   = $self->_hash($col);
    my $bucket = $self->{tabla}{$tipo}[$slot];
    my @nuevo  = grep { $_->{colegio} ne $col } @$bucket;

    if (@nuevo < @$bucket) {
        $self->{tabla}{$tipo}[$slot] = \@nuevo;
        $self->{conteo}{$tipo}--;
    }
}

# ── Consultar por tipo ───────────────────────────────────────
sub por_tipo {
    my ($self, $tipo) = @_;
    return [] unless exists $self->{tabla}{$tipo};

    my @lista;
    for my $slot (@{ $self->{tabla}{$tipo} }) {
        for my $entry (@$slot) {
            push @lista, {
                numero_colegio => $entry->{colegio},
                nombre         => $entry->{datos}{nombre}  // '',
                tipo           => $entry->{datos}{tipo}    // '',
                departamento   => $entry->{datos}{depto}   // '',
                especialidad   => $entry->{datos}{espec}   // '',
            };
        }
    }
    # Ordenar por nombre
    return [ sort { $a->{nombre} cmp $b->{nombre} } @lista ];
}

# ── Estado interno de la tabla (para el reporte) ─────────────
sub estado_tabla {
    my ($self) = @_;
    my @resultado;
    for my $tipo (qw(TIPO-01 TIPO-02 TIPO-03 TIPO-04)) {
        my @slots;
        my $slot_idx = 0;
        for my $bucket (@{ $self->{tabla}{$tipo} }) {
            push @slots, {
                slot    => $slot_idx++,
                ocupado => scalar(@$bucket),
                claves  => [ map { $_->{colegio} } @$bucket ],
            };
        }
        push @resultado, {
            tipo       => $tipo,
            total      => $self->{conteo}{$tipo} // 0,
            colisiones => $self->{colisiones}{$tipo} // 0,
            slots      => \@slots,
            size       => TABLA_SIZE,
            ocupacion  => sprintf("%.1f%%",
                ($self->{conteo}{$tipo} // 0) * 100 / TABLA_SIZE),
        };
    }
    return \@resultado;
}

1;