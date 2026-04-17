package arbolB;
use strict;
use warnings;

my $ORDEN = 4;  # Máximo 3 claves, 4 hijos por nodo (Orden 4)

require 'nodoB.pl';

# Constructor
sub new {
    my ($clase) = @_;
    return bless { raiz => nodoB->new() }, $clase;
}

# ==========================================
# BÚSQUEDA (Pública y privada)
# ==========================================
sub buscar {
    my ($self, $clave) = @_;
    my $resultado = $self->_buscar($self->{raiz}, uc($clave));
    return $resultado ? $resultado->{valor} : undef;
}

sub _buscar {
    my ($self, $nodo, $clave) = @_;
    return undef unless defined $nodo && $nodo->num_claves > 0;

    my $claves = $nodo->{claves};
    my $i = 0;
    
    # Buscar posición donde podría estar la clave
    $i++ while $i < scalar(@$claves) && $clave gt $claves->[$i]{clave};

    # Encontrada
    if ($i < scalar(@$claves) && $clave eq $claves->[$i]{clave}) {
        return $claves->[$i];  # Retorna hash {clave=>, valor=>}
    }

    # Si es hoja y no encontró, no existe
    return undef if $nodo->{es_hoja};
    
    # Recursión en hijo correspondiente
    return $self->_buscar($nodo->{hijos}[$i], $clave);
}

# ==========================================
# INSERCIÓN (Corregida y robusta)
# ==========================================
sub insertar {
    my ($self, $clave, $valor) = @_;
    $clave = uc($clave);  # Normalizar a mayúsculas
    
    # Si ya existe, actualizar valor (upsert)
    if (my $existente = $self->buscar($clave)) {
        $existente->{valor} = $valor;
        return 1;
    }
    
    my $raiz = $self->{raiz};

    # Caso especial: raíz llena → crear nueva raíz
    if ($raiz->num_claves == $ORDEN - 1) {
        my $nueva_raiz = nodoB->new();
        $nueva_raiz->{es_hoja} = 0;
        $nueva_raiz->{hijos} = [$raiz];
        $self->{raiz} = $nueva_raiz;
        $self->_split_hijo($nueva_raiz, 0);
        $self->_insertar_no_lleno($nueva_raiz, $clave, $valor);
    } else {
        $self->_insertar_no_lleno($raiz, $clave, $valor);
    }
    return 1;
}

# Dividir hijo lleno durante inserción
sub _split_hijo {
    my ($self, $padre, $idx_hijo) = @_;
    
    my $t = int($ORDEN / 2);  # Punto medio (2 para orden 4)
    my $hijo = $padre->{hijos}[$idx_hijo];
    
    # Crear nuevo nodo para la mitad derecha
    my $nuevo = nodoB->new();
    $nuevo->{es_hoja} = $hijo->{es_hoja};

    # Mover claves: [0..t-2] se quedan en hijo, [t..end] van a nuevo
    # La clave [t-1] sube al padre
    my @claves_hijo = @{ $hijo->{claves} };
    
    $nuevo->{claves} = [ @claves_hijo[$t .. $#claves_hijo] ];
    $hijo->{claves}  = [ @claves_hijo[0 .. $t-2] ];  # t-2 porque t-1 sube

    # Mover hijos si no es hoja
    if (!$hijo->{es_hoja}) {
        my @hijos_hijo = @{ $hijo->{hijos} };
        $nuevo->{hijos}  = [ @hijos_hijo[$t .. $#hijos_hijo] ];
        $hijo->{hijos}   = [ @hijos_hijo[0 .. $t-1] ];  # t hijos se quedan
    }

    # Insertar clave media en el padre (con su valor original)
    splice(@{ $padre->{claves} }, $idx_hijo, 0, $claves_hijo[$t-1]);
    splice(@{ $padre->{hijos} }, $idx_hijo+1, 0, $nuevo);
}

# Insertar en nodo que tiene espacio
sub _insertar_no_lleno {
    my ($self, $nodo, $clave, $valor) = @_;
    
    if ($nodo->{es_hoja}) {
        # Insertar en hoja manteniendo orden
        my $i = $nodo->num_claves - 1;
        while ($i >= 0 && $clave lt $nodo->{claves}[$i]{clave}) {
            $nodo->{claves}[$i+1] = $nodo->{claves}[$i];
            $i--;
        }
        $nodo->{claves}[$i+1] = { clave => $clave, valor => $valor };
    } else {
        # Encontrar hijo apropiado
        my $i = $nodo->num_claves - 1;
        $i-- while $i >= 0 && $clave lt $nodo->{claves}[$i]{clave};
        $i++;
        
        # Si hijo está lleno, dividirlo
        if ($nodo->{hijos}[$i]->num_claves == $ORDEN - 1) {
            $self->_split_hijo($nodo, $i);
            # Re-evaluar hacia qué hijo ir después del split
            $i++ if $clave gt $nodo->{claves}[$i]{clave};
        }
        $self->_insertar_no_lleno($nodo->{hijos}[$i], $clave, $valor);
    }
}

# ==========================================
# ELIMINACIÓN (NUEVO - Crítico para inventario)
# ==========================================
sub eliminar {
    my ($self, $clave) = @_;
    $clave = uc($clave);
    
    return 0 unless defined $self->{raiz} && $self->{raiz}->num_claves > 0;
    
    $self->_eliminar($self->{raiz}, $clave);
    
    # Si raíz quedó vacía y tiene hijos, promover hijo a raíz
    if ($self->{raiz}->num_claves == 0 && !$self->{raiz}->{es_hoja}) {
        $self->{raiz} = $self->{raiz}->{hijos}[0];
    }
    return 1;
}

sub _eliminar {
    my ($self, $nodo, $clave) = @_;
    
    my $idx = 0;
    my $claves = $nodo->{claves};
    
    # Encontrar posición de la clave
    $idx++ while $idx < scalar(@$claves) && $clave gt $claves->[$idx]{clave};
    
    # CASO 1: Clave encontrada en este nodo
    if ($idx < scalar(@$claves) && $clave eq $claves->[$idx]{clave}) {
        if ($nodo->{es_hoja}) {
            # Hoja: eliminar directamente
            splice(@$claves, $idx, 1);
        } else {
            # Nodo interno: reemplazar con predecesor o sucesor
            $self->_eliminar_interno($nodo, $idx);
        }
        return;
    }
    
    # CASO 2: Clave no está en este nodo → ir al hijo
    return if $nodo->{es_hoja};  # No encontrada
    
    my $hijo = $nodo->{hijos}[$idx];
    
    # Asegurar que el hijo tenga al menos t claves antes de recursar
    if ($hijo->num_claves < int($ORDEN/2)) {
        $self->_asegurar_hijo($nodo, $idx);
        # Re-obtener hijo después de posibles fusiones
        $hijo = $nodo->{hijos}[$idx];
    }
    
    $self->_eliminar($hijo, $clave);
}

# Eliminar clave de nodo interno (reemplazo con predecesor)
sub _eliminar_interno {
    my ($self, $nodo, $idx) = @_;
    my $clave_a_eliminar = $nodo->{claves}[$idx]{clave};
    
    # Intentar tomar predecesor del subárbol izquierdo
    my $hijo_izq = $nodo->{hijos}[$idx];
    if ($hijo_izq->num_claves >= int($ORDEN/2)) {
        my $predecesor = $self->_obtener_maximo($hijo_izq);
        $nodo->{claves}[$idx] = { 
            clave => $predecesor->{clave}, 
            valor => $predecesor->{valor} 
        };
        $self->_eliminar($hijo_izq, $predecesor->{clave});
        return;
    }
    
    # Si no, tomar sucesor del subárbol derecho
    my $hijo_der = $nodo->{hijos}[$idx+1];
    if ($hijo_der->num_claves >= int($ORDEN/2)) {
        my $sucesor = $self->_obtener_minimo($hijo_der);
        $nodo->{claves}[$idx] = { 
            clave => $sucesor->{clave}, 
            valor => $sucesor->{valor} 
        };
        $self->_eliminar($hijo_der, $sucesor->{clave});
        return;
    }
    
    # Si ambos hijos tienen mínimo, fusionarlos
    $self->_fusionar_nodos($nodo, $idx);
    $self->_eliminar($hijo_izq, $clave_a_eliminar);
}

# Obtener clave máxima de un subárbol (predecesor)
sub _obtener_maximo {
    my ($self, $nodo) = @_;
    while (!$nodo->{es_hoja}) {
        $nodo = $nodo->{hijos}[$nodo->num_claves];
    }
    return $nodo->{claves}[$nodo->num_claves - 1];
}

# Obtener clave mínima de un subárbol (sucesor)
sub _obtener_minimo {
    my ($self, $nodo) = @_;
    while (!$nodo->{es_hoja}) {
        $nodo = $nodo->{hijos}[0];
    }
    return $nodo->{claves}[0];
}

# Asegurar que un hijo tenga al menos t claves (borrow o merge)
sub _asegurar_hijo {
    my ($self, $padre, $idx) = @_;
    my $hijo = $padre->{hijos}[$idx];
    my $t = int($ORDEN/2);
    
    return if $hijo->num_claves >= $t;  # Ya tiene suficientes
    
    # Intentar tomar prestado del hermano izquierdo
    if ($idx > 0 && $padre->{hijos}[$idx-1]->num_claves >= $t) {
        $self->_prestar_izquierda($padre, $idx);
        return;
    }
    
    # Intentar tomar prestado del hermano derecho
    if ($idx < $padre->num_claves && 
        $padre->{hijos}[$idx+1]->num_claves >= $t) {
        $self->_prestar_derecha($padre, $idx);
        return;
    }
    
    # Si no se puede prestar, fusionar con hermano
    if ($idx > 0) {
        $self->_fusionar_nodos($padre, $idx-1);  # Fusionar con izquierdo
    } else {
        $self->_fusionar_nodos($padre, $idx);    # Fusionar con derecho
    }
}

# Tomar prestado del hermano izquierdo
sub _prestar_izquierda {
    my ($self, $padre, $idx) = @_;
    my $hijo = $padre->{hijos}[$idx];
    my $hermano = $padre->{hijos}[$idx-1];
    
    # Bajar clave del padre al hijo
    unshift @{ $hijo->{claves} }, { 
        clave => $padre->{claves}[$idx-1]{clave},
        valor => $padre->{claves}[$idx-1]{valor}
    };
    
    # Si no es hoja, mover hijo del hermano
    if (!$hijo->{es_hoja}) {
        unshift @{ $hijo->{hijos} }, pop @{ $hermano->{hijos} };
    }
    
    # Subir clave del hermano al padre
    $padre->{claves}[$idx-1] = pop @{ $hermano->{claves} };
}

# Tomar prestado del hermano derecho
sub _prestar_derecha {
    my ($self, $padre, $idx) = @_;
    my $hijo = $padre->{hijos}[$idx];
    my $hermano = $padre->{hijos}[$idx+1];
    
    # Bajar clave del padre al hijo
    push @{ $hijo->{claves} }, { 
        clave => $padre->{claves}[$idx]{clave},
        valor => $padre->{claves}[$idx]{valor}
    };
    
    # Si no es hoja, mover hijo del hermano
    if (!$hijo->{es_hoja}) {
        push @{ $hijo->{hijos} }, shift @{ $hermano->{hijos} };
    }
    
    # Subir clave del hermano al padre
    $padre->{claves}[$idx] = shift @{ $hermano->{claves} };
}

# Fusionar dos nodos hijos con una clave del padre
sub _fusionar_nodos {
    my ($self, $padre, $idx) = @_;
    my $hijo_izq = $padre->{hijos}[$idx];
    my $hijo_der = $padre->{hijos}[$idx+1];
    
    # Mover clave del padre al hijo izquierdo
    push @{ $hijo_izq->{claves} }, $padre->{claves}[$idx];
    
    # Mover todas las claves del derecho al izquierdo
    push @{ $hijo_izq->{claves} }, @{ $hijo_der->{claves} };
    
    # Mover hijos si no son hojas
    if (!$hijo_izq->{es_hoja}) {
        push @{ $hijo_izq->{hijos} }, @{ $hijo_der->{hijos} };
    }
    
    # Eliminar clave del padre y nodo derecho
    splice(@{ $padre->{claves} }, $idx, 1);
    splice(@{ $padre->{hijos} }, $idx+1, 1);
}

# ==========================================
# RECORRIDOS (NUEVOS)
# ==========================================
sub inorden {
    my ($self) = @_;
    my @resultado;
    $self->_inorden($self->{raiz}, \@resultado);
    return \@resultado;
}

sub _inorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo && $nodo->num_claves > 0;
    
    my $num = $nodo->num_claves;
    for my $i (0 .. $num - 1) {
        $self->_inorden($nodo->{hijos}[$i], $r) unless $nodo->{es_hoja};
        push @$r, { 
            clave => $nodo->{claves}[$i]{clave}, 
            valor => $nodo->{claves}[$i]{valor} 
        };
    }
    $self->_inorden($nodo->{hijos}[$num], $r) unless $nodo->{es_hoja};
}

sub preorden {
    my ($self) = @_;
    my @resultado;
    $self->_preorden($self->{raiz}, \@resultado);
    return \@resultado;
}

sub _preorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo && $nodo->num_claves > 0;
    
    # Procesar claves del nodo actual
    for my $entry (@{ $nodo->{claves} }) {
        push @$r, { clave => $entry->{clave}, valor => $entry->{valor} };
    }
    
    # Recursión en hijos
    unless ($nodo->{es_hoja}) {
        for my $hijo (@{ $nodo->{hijos} }) {
            $self->_preorden($hijo, $r);
        }
    }
}

# ==========================================
# ESTADÍSTICAS Y UTILIDADES (NUEVAS)
# ==========================================
sub total_claves {
    my ($self) = @_;
    return $self->_contar_claves($self->{raiz});
}

sub _contar_claves {
    my ($self, $nodo) = @_;
    return 0 unless defined $nodo;
    
    my $total = $nodo->num_claves;
    unless ($nodo->{es_hoja}) {
        for my $hijo (@{ $nodo->{hijos} }) {
            $total += $self->_contar_claves($hijo);
        }
    }
    return $total;
}

sub altura {
    my ($self) = @_;
    return $self->_calcular_altura($self->{raiz});
}

sub _calcular_altura {
    my ($self, $nodo) = @_;
    return 0 unless defined $nodo;
    return 1 if $nodo->{es_hoja};
    
    my $max_h = 0;
    for my $hijo (@{ $nodo->{hijos} }) {
        my $h = $self->_calcular_altura($hijo);
        $max_h = $h if $h > $max_h;
    }
    return 1 + $max_h;
}

sub minimo {
    my ($self) = @_;
    my $nodo = $self->{raiz};
    return undef unless defined $nodo && $nodo->num_claves > 0;
    
    while (!$nodo->{es_hoja}) {
        $nodo = $nodo->{hijos}[0];
    }
    return $nodo->{claves}[0]{valor};
}

sub maximo {
    my ($self) = @_;
    my $nodo = $self->{raiz};
    return undef unless defined $nodo && $nodo->num_claves > 0;
    
    while (!$nodo->{es_hoja}) {
        $nodo = $nodo->{hijos}[$nodo->num_claves];
    }
    return $nodo->{claves}[$nodo->num_claves - 1]{valor};
}

# Getter para la raíz (necesario para Graphviz)
sub raiz { return $_[0]->{raiz}; }

# ==========================================
# DEBUG: Imprimir árbol en consola (opcional)
# ==========================================
sub imprimir {
    my ($self) = @_;
    $self->_imprimir_nivel($self->{raiz}, 0);
}

sub _imprimir_nivel {
    my ($self, $nodo, $nivel) = @_;
    return unless defined $nodo;
    
    my $indent = "  " x $nivel;
    my @claves = map { $_->{clave} } @{ $nodo->{claves} };
    
    print "${indent}Nivel $nivel: [" . join(", ", @claves) . "]";
    print " (HOJA)" if $nodo->{es_hoja};
    print "\n";
    
    unless ($nodo->{es_hoja}) {
        for my $hijo (@{ $nodo->{hijos} }) {
            $self->_imprimir_nivel($hijo, $nivel + 1);
        }
    }
}

1;  # Los módulos Perl deben retornar verdadero