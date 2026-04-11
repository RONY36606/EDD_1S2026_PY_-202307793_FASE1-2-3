package grafoNoDirigido;

use strict;
use warnings;
use nodoGrafo;

# Constructor del grafo
sub new {
    my ($class) = @_;
    
    my $self = {
        nodos => {},  # Hash: clave = numero_colegio, valor = objeto nodoGrafo
    };
    
    bless $self, $class;
    return $self;
}

# Agregar un nodo al grafo
sub agregar_nodo {
    my ($self, %args) = @_;
    
    my $colegio = $args{numero_colegio};
    
    # Si ya existe, no hacer nada (o actualizar)
    if (exists $self->{nodos}{$colegio}) {
        warn "El nodo $colegio ya existe en el grafo\n";
        return 0;
    }
    
    # Crear nuevo nodo
    my $nodo = nodoGrafo->new(%args);
    $self->{nodos}{$colegio} = $nodo;
    
    return 1;
}

# Eliminar un nodo del grafo
sub eliminar_nodo {
    my ($self, $colegio) = @_;
    
    return 0 unless exists $self->{nodos}{$colegio};
    
    # Primero eliminar todas las aristas que conectan a este nodo
    foreach my $vecino ($self->{nodos}{$colegio}->obtener_vecinos()) {
        $self->eliminar_arista($colegio, $vecino);
    }
    
    # Luego eliminar el nodo
    delete $self->{nodos}{$colegio};
    
    return 1;
}

# Agregar una arista (relación de colaboración) - NO DIRIGIDA
sub agregar_arista {
    my ($self, $colegio_a, $colegio_b) = @_;
    
    # Verificar que ambos nodos existan
    unless (exists $self->{nodos}{$colegio_a} && exists $self->{nodos}{$colegio_b}) {
        warn "Uno o ambos nodos no existen en el grafo\n";
        return 0;
    }
    
    # En grafo NO DIRIGIDO: A es vecino de B y B es vecino de A
    $self->{nodos}{$colegio_a}->agregar_vecino($colegio_b);
    $self->{nodos}{$colegio_b}->agregar_vecino($colegio_a);
    
    return 1;
}

# Eliminar una arista
sub eliminar_arista {
    my ($self, $colegio_a, $colegio_b) = @_;
    
    # En grafo NO DIRIGIDO: eliminar en ambas direcciones
    $self->{nodos}{$colegio_a}->eliminar_vecino($colegio_b) if exists $self->{nodos}{$colegio_a};
    $self->{nodos}{$colegio_b}->eliminar_vecino($colegio_a) if exists $self->{nodos}{$colegio_b};
    
    return 1;
}

# Verificar si existe una arista entre dos nodos
sub existe_arista {
    my ($self, $colegio_a, $colegio_b) = @_;
    
    return 0 unless exists $self->{nodos}{$colegio_a};
    
    return $self->{nodos}{$colegio_a}->tiene_vecino($colegio_b);
}

# Obtener un nodo específico
sub obtener_nodo {
    my ($self, $colegio) = @_;
    return $self->{nodos}{$colegio};
}

# Obtener todos los nodos del grafo
sub obtener_todos_nodos {
    my ($self) = @_;
    return values %{$self->{nodos}};
}

# Contar total de nodos
sub total_nodos {
    my ($self) = @_;
    return scalar keys %{$self->{nodos}};
}

# Contar total de aristas (cada arista se cuenta 2 veces en lista de adyacencia)
sub total_aristas {
    my ($self) = @_;
    my $total = 0;
    
    foreach my $nodo (values %{$self->{nodos}}) {
        $total += $nodo->grado();
    }
    
    return $total / 2;  # Dividir entre 2 porque es no dirigido
}

# BFS de DOS SALTOS (para sugerencias de colaboración)
# Retorna hash: { colegio => cantidad_de_colaboradores_en_comun }
sub bfs_dos_saltos {
    my ($self, $colegio_origen) = @_;
    
    my %sugerencias;
    my %visitados;
    my @cola;
    
    # Marcar origen como visitado
    $visitados{$colegio_origen} = 1;
    
    # Obtener nodo origen
    my $nodo_origen = $self->{nodos}{$colegio_origen};
    return \%sugerencias unless $nodo_origen;
    
    # PRIMER SALTO: Obtener colaboradores directos (ya son mis vecinos, no sugerirlos)
    my @colaboradores_directos = $nodo_origen->obtener_vecinos();
    
    # Marcar colaboradores directos como visitados (no los sugerimos)
    foreach my $colab (@colaboradores_directos) {
        $visitados{$colab} = 1;
    }
    
    # SEGUNDO SALTO: Explorar vecinos de mis colaboradores
    foreach my $colegio_colab (@colaboradores_directos) {
        my $nodo_colab = $self->{nodos}{$colegio_colab};
        next unless $nodo_colab;
        
        foreach my $vecino_de_colab ($nodo_colab->obtener_vecinos()) {
            next if $visitados{$vecino_de_colab};  # Ya visitado o es colaborador directo
            
            # Contar cuántos colaboradores en común tienen
            $sugerencias{$vecino_de_colab}++;
        }
    }
    
    return \%sugerencias;
}

# Generar archivo DOT para Graphviz
sub generar_dot {
    my ($self, $archivo_salida) = @_;
    
    open(my $fh, '>', $archivo_salida) or die "No se puede crear $archivo_salida: $!";
    
    print $fh "graph RedColaboracion {\n";
    print $fh "    rankdir=LR;\n";           # Left to Right
    print $fh "    node [shape=circle];\n";  # Nodos circulares
    
    # Imprimir nodos con sus atributos
    foreach my $nodo (values %{$self->{nodos}}) {
        my $colegio = $nodo->get_numero_colegio();
        my $nombre = $nodo->get_nombre();
        my $color = $nodo->get_color_graphviz();
        my $depto = $nodo->get_departamento();
        
        # Etiqueta: nombre + departamento
        print $fh "    \"$colegio\" [label=\"$nombre\\n$depto\", fillcolor=\"$color\", style=filled];\n";
    }
    
    # Imprimir aristas (solo una dirección para evitar duplicados en DOT)
    my %aristas_impresas;
    foreach my $nodo (values %{$self->{nodos}}) {
        my $colegio_a = $nodo->get_numero_colegio();
        
        foreach my $colegio_b ($nodo->obtener_vecinos()) {
            # Evitar imprimir la misma arista dos veces
            my $clave = join('-', sort ($colegio_a, $colegio_b));
            next if $aristas_impresas{$clave};
            
            print $fh "    \"$colegio_a\" -- \"$colegio_b\";\n";
            $aristas_impresas{$clave} = 1;
        }
    }
    
    print $fh "}\n";
    close($fh);
    
    # Generar PNG con Graphviz
    my $archivo_png = $archivo_salida;
    $archivo_png =~ s/\.dot$/.png/;
    
    system("dot -Tpng $archivo_salida -o $archivo_png");
    
    return $archivo_png;
}

# Generar reporte de lista de adyacencia (texto)
sub reporte_lista_adyacencia {
    my ($self, $archivo_salida) = @_;
    
    open(my $fh, '>', $archivo_salida) or die "No se puede crear $archivo_salida: $!";
    
    print $fh "=== LISTA DE ADYACENCIA - RED DE COLABORACIÓN ===\n\n";
    
    foreach my $nodo (sort { $a->get_numero_colegio() cmp $b->get_numero_colegio() } 
                      values %{$self->{nodos}}) {
        my $colegio = $nodo->get_numero_colegio();
        my $nombre = $nodo->get_nombre();
        my @vecinos = $nodo->obtener_vecinos();
        
        print $fh "$colegio ($nombre): ";
        
        if (@vecinos) {
            print $fh join(', ', sort @vecinos);
        } else {
            print $fh "SIN COLABORADORES";
        }
        print $fh "\n";
    }
    
    close($fh);
}

1;