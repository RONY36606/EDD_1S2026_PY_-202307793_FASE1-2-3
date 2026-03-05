package arbolAvl;
use strict;
use warnings;

require 'nodoAvl.pl';

sub new {
    my ($class) = @_;
    return bless { raiz => undef }, $class;
}

sub _altura {
    my ($self, $nodo) = @_;
    return 0 unless defined $nodo;
    return $nodo->{altura};
}

sub _actualizar_altura {
    my ($self, $nodo) = @_;
    my $hi = $self->_altura($nodo->{izq});
    my $hd = $self->_altura($nodo->{der});
    $nodo->{altura} = 1 + ($hi > $hd ? $hi : $hd);
}

sub _balance {
    my ($self, $nodo) = @_;
    return 0 unless defined $nodo;
    return $self->_altura($nodo->{izq}) - $self->_altura($nodo->{der});
}

#eEsto es para mover los valores de una rama a otra, de la izquierda a la derecha 
sub _rotar_derecha {
    my ($self, $y) = @_;
    my $x = $y->{izq};
    my $B = $x->{der};
    $x->{der} = $y;
    $y->{izq} = $B;
    $self->_actualizar_altura($y);
    $self->_actualizar_altura($x);
    return $x;}
#eEsto es para mover los valores de una rama a otra, de la derecha a la izquierda 
sub _rotar_izquierda {
    my ($self, $x) = @_;
    my $y = $x->{der};
    my $B = $y->{izq};
    $y->{izq} = $x;
    $x->{der} = $B;
    $self->_actualizar_altura($x);
    $self->_actualizar_altura($y);
    return $y;
}


#ESTE ARBOL NECESITA BALANCEO, para eso sirve este Sub
sub _balancear {
    my ($self, $nodo, $clave) = @_;
    my $fb = $self->_balance($nodo);

    # Izquierda-Izquierda
    if ($fb > 1 && $clave lt $nodo->{izq}{clave}) {
        return $self->_rotar_derecha($nodo);
    }
    # Derecha-Derecha
    if ($fb < -1 && $clave gt $nodo->{der}{clave}) {
        return $self->_rotar_izquierda($nodo);
    }
    # Izquierda-Derecha
    if ($fb > 1 && $clave gt $nodo->{izq}{clave}) {
        $nodo->{izq} = $self->_rotar_izquierda($nodo->{izq});
        return $self->_rotar_derecha($nodo);
    }
    # Derecha-Izquierda
    if ($fb < -1 && $clave lt $nodo->{der}{clave}) {
        $nodo->{der} = $self->_rotar_derecha($nodo->{der});
        return $self->_rotar_izquierda($nodo);
    }

    return $nodo;
}

sub _insertar {
    my ($self, $nodo, $clave, $valor) = @_;

    unless (defined $nodo) {
        return nodoAvl->new($clave, $valor);
    }

    if    ($clave lt $nodo->{clave}) { $nodo->{izq} = $self->_insertar($nodo->{izq}, $clave, $valor); }
    elsif ($clave gt $nodo->{clave}) { $nodo->{der} = $self->_insertar($nodo->{der}, $clave, $valor); }
    else  { return $nodo; } # duplicado

    $self->_actualizar_altura($nodo);
    return $self->_balancear($nodo, $clave);
}

#Este es el método main para llamar a insertar, que se trata de un método recursivo para ir recorriendo el árbol
sub insertar {
    my ($self, $clave, $valor) = @_;
    $self->{raiz} = $self->_insertar($self->{raiz}, $clave, $valor);
}


#Esto es para buscar entre todos los valores, usando las claves de cada nodo para guiarnos
sub buscar {
    my ($self, $clave) = @_;
    my $nodo = $self->{raiz};
    while (defined $nodo) {
        if    ($clave lt $nodo->{clave}) { $nodo = $nodo->{izq}; }
        elsif ($clave gt $nodo->{clave}) { $nodo = $nodo->{der}; }
        else  { return $nodo->{valor};  } # devuelve el objeto
    }
    return undef;
}

sub _minimo {
    my ($self, $nodo) = @_;
    $nodo = $nodo->{izq} while defined $nodo->{izq};
    return $nodo;
}

#Después de una eliminación, podemos volver a balancear a nuestro árbol
sub _balancear_post_elim {
    my ($self, $nodo) = @_;
    my $fb = $self->_balance($nodo);

    if ($fb > 1) {
        if ($self->_balance($nodo->{izq}) < 0) {
            $nodo->{izq} = $self->_rotar_izquierda($nodo->{izq});
        }
        return $self->_rotar_derecha($nodo);
    }
    if ($fb < -1) {
        if ($self->_balance($nodo->{der}) > 0) {
            $nodo->{der} = $self->_rotar_derecha($nodo->{der});
        }
        return $self->_rotar_izquierda($nodo);
    }
    return $nodo;
}

#Con este sum podemos eliminar un nodo, utilizando este método recursivo, es parecido a insertar
sub _eliminar {
    my ($self, $nodo, $clave) = @_;
    return undef unless defined $nodo;

    if    ($clave lt $nodo->{clave}) { $nodo->{izq} = $self->_eliminar($nodo->{izq}, $clave); }
    elsif ($clave gt $nodo->{clave}) { $nodo->{der} = $self->_eliminar($nodo->{der}, $clave); }
    else {
        return $nodo->{der} unless defined $nodo->{izq};
        return $nodo->{izq} unless defined $nodo->{der};
        my $sucesor    = $self->_minimo($nodo->{der});
        $nodo->{clave} = $sucesor->{clave};
        $nodo->{valor} = $sucesor->{valor};  # copiar el objeto completo
        $nodo->{der}   = $self->_eliminar($nodo->{der}, $sucesor->{clave});
    }

    $self->_actualizar_altura($nodo);
    return $self->_balancear_post_elim($nodo);
}
#Esto llama al método de eliminar, para que actúe de forma recursiva
sub eliminar {
    my ($self, $clave) = @_;
    $self->{raiz} = $self->_eliminar($self->{raiz}, $clave);
}

# <================================================== RECORRIDOS — devuelven array de objetos (los valores) ==================================================>
sub _inorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo;
    $self->_inorden($nodo->{izq}, $r);
    push @$r, { clave => $nodo->{clave}, valor => $nodo->{valor} };
    $self->_inorden($nodo->{der}, $r);
}

sub _preorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo;
    push @$r, { clave => $nodo->{clave}, valor => $nodo->{valor} };
    $self->_preorden($nodo->{izq}, $r);
    $self->_preorden($nodo->{der}, $r);
}

sub _postorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo;
    $self->_postorden($nodo->{izq}, $r);
    $self->_postorden($nodo->{der}, $r);
    push @$r, { clave => $nodo->{clave}, valor => $nodo->{valor} };
}

sub inorden   { my ($self) = @_; my @r; $self->_inorden($self->{raiz},   \@r); return \@r; }
sub preorden  { my ($self) = @_; my @r; $self->_preorden($self->{raiz},  \@r); return \@r; }
sub postorden { my ($self) = @_; my @r; $self->_postorden($self->{raiz}, \@r); return \@r; }

# Para Graphviz
sub raiz { return $_[0]->{raiz}; }

1;