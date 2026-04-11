package tablaHash;

use strict;
use warnings;
use nodoHash;

sub new {
    my ($class) = @_;
    
    my $self = {
        buckets => {}, # Hash perl que actuará como nuestros buckets: 'TIPO-01' => nodoHash
        total_usuarios => 0,
    };
    
    # Inicializamos los 4 buckets requeridos
    $self->{buckets}{'TIPO-01'} = undef;
    $self->{buckets}{'TIPO-02'} = undef;
    $self->{buckets}{'TIPO-03'} = undef;
    $self->{buckets}{'TIPO-04'} = undef;
    
    bless $self, $class;
    return $self;
}

# Función Hash simple: Extrae el número del tipo para validar
# En este caso, como las claves son explícitas (TIPO-XX), la "función hash"
# es simplemente validar que el bucket exista.
sub _hash_func {
    my ($self, $tipo) = @_;
    return exists $self->{buckets}{$tipo} ? $tipo : undef;
}

# Agregar usuario a la tabla
sub agregar {
    my ($self, $usuario_obj) = @_;
    
    my $tipo = $usuario_obj->get_tipo_usuario(); # Asumo que tu clase Usuario tiene este método
    my $bucket_key = $self->_hash_func($tipo);
    
    unless ($bucket_key) {
        warn "Tipo de usuario no válido para Hash: $tipo\n";
        return 0;
    }
    
    # Crear nuevo nodo
    my $nuevo_nodo = nodoHash->new($usuario_obj);
    
    # Encadenamiento: Insertar al inicio de la lista del bucket
    $nuevo_nodo->set_siguiente($self->{buckets}{$bucket_key});
    $self->{buckets}{$bucket_key} = $nuevo_nodo;
    
    $self->{total_usuarios}++;
    return 1;
}

# Buscar y devolver lista de usuarios de un tipo específico
sub buscar_por_tipo {
    my ($self, $tipo) = @_;
    
    my $inicio = $self->{buckets}{$tipo};
    my @lista_usuarios = ();
    
    my $actual = $inicio;
    while (defined $actual) {
        push @lista_usuarios, $actual->get_usuario();
        $actual = $actual->get_siguiente();
    }
    
    return @lista_usuarios;
}

# Eliminar un usuario (por número de colegio)
# Útil si se borra del AVL, debe borrarse aquí también
sub eliminar {
    my ($self, $num_colegio) = @_;
    
    # Iterar sobre todos los buckets porque no sabemos de qué tipo es el usuario solo con el colegio
    foreach my $tipo (keys %{$self->{buckets}}) {
        my $actual = $self->{buckets}{$tipo};
        my $anterior = undef;
        
        while (defined $actual) {
            if ($actual->get_usuario()->get_numero_colegio() eq $num_colegio) {
                # Encontrado, eliminar
                if ($anterior) {
                    $anterior->set_siguiente($actual->get_siguiente());
                } else {
                    $self->{buckets}{$tipo} = $actual->get_siguiente();
                }
                $self->{total_usuarios}--;
                return 1;
            }
            $anterior = $actual;
            $actual = $actual->get_siguiente();
        }
    }
    return 0;
}

# Contar usuarios en un bucket específico
sub obtener_tamano_bucket {
    my ($self, $tipo) = @_;
    return scalar $self->buscar_por_tipo($tipo);
}

# ==========================================
# REPORTE GRAPHVIZ 
# ==========================================
sub generar_reporte {
    my ($self, $archivo_salida) = @_;
    
    open(my $fh, '>', $archivo_salida) or die "Error creando reporte hash: $!";
    
    print $fh "digraph TablaHashReporte {\n";
    print $fh "    rankdir=TB;\n";
    print $fh "    node [shape=box, style=filled, fillcolor=\"#f0f0f0\"];\n";
    
    # Nodo central "Tabla Hash"
    print $fh "    Tabla [label=\"Tabla Hash\\n(Total Usuarios: $self->{total_usuarios})\", shape=ellipse, fillcolor=\"#333333\", fontcolor=white];\n\n";
    
    # Iterar buckets
    foreach my $tipo (sort keys %{$self->{buckets}}) {
        my $inicio = $self->{buckets}{$tipo};
        my $contador = 0;
        
        # Nodo del Bucket
        print $fh "    Bucket_$tipo [label=\"$tipo\", shape=component, fillcolor=\"#4a90e2\", fontcolor=white];\n";
        print $fh "    Tabla -> Bucket_$tipo;\n";
        
        my $actual = $inicio;
        my $nodo_anterior_id = "Bucket_$tipo";
        
        # Iterar lista enlazada
        while (defined $actual) {
            $contador++;
            my $usuario = $actual->get_usuario();
            my $id_nodo = "Nodo_${tipo}_${contador}";
            my $label = $usuario->get_nombre() . "\\n" . $usuario->get_numero_colegio();
            
            print $fh "    $id_nodo [label=\"$label\"];\n";
            print $fh "    $nodo_anterior_id -> $id_nodo;\n";
            
            $nodo_anterior_id = $id_nodo;
            $actual = $actual->get_siguiente();
        }
        
        # Si el bucket está vacío
        if ($contador == 0) {
            print $fh "    Empty_$tipo [label=\"VACÍO\", shape=plaintext, fontcolor=\"gray\"];\n";
            print $fh "    Bucket_$tipo -> Empty_$tipo [style=dashed];\n";
        }
    }
    
    print $fh "}\n";
    close($fh);
    
    # Comando para generar PNG
    system("dot -Tpng $archivo_salida -o ${archivo_salida}.png");
}

1;