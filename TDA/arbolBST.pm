package arbolBST;
use strict;
use warnings;
require 'nodoBST.pl';
sub new{
    my($class)=@_;
    return bless {
        raiz => undef
    }, $class;
}

#Este sub es para insertar valores dentro del árbol BST
sub insertar {
    my ($self, $clave, $valor) = @_;
    my $nuevo = nodoBST->new($clave, $valor);

    unless (defined $self->{raiz}) {
        $self->{raiz} = $nuevo;
        return;
    }

    my $actual = $self->{raiz};
    while (1) {
        if    ($clave lt $actual->{clave}) {
            if (!defined $actual->{izq}) { $actual->{izq} = $nuevo; last; }
            $actual = $actual->{izq};
        }
        elsif ($clave gt $actual->{clave}) {
            if (!defined $actual->{der}) { $actual->{der} = $nuevo; last; }
            $actual = $actual->{der};
        }
        else { last; } # duplicado
    }
}

#=================================este sub es para buscar dentro del árbol==============================
sub buscar {
    my ($self, $clave) = @_;
    my $actual = $self->{raiz};
    while (defined $actual) {
        if    ($clave lt $actual->{clave}) { $actual = $actual->{izq}; }
        elsif ($clave gt $actual->{clave}) { $actual = $actual->{der}; }
        else  { return $actual->{valor}; } # devuelve el objeto
    }
    return undef;
}

#============================este sub es para buscar el mínimo dentro del árbol=============================

sub _minimo {
    my ($self, $nodo) = @_;
    $nodo = $nodo->{izq} while defined $nodo->{izq};
    return $nodo;
}

#===========Este sub es para eliminar un árbol, es un método recursivo, parecido a insert========================
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
    return $nodo;
}

#Acá se llama al método recursivo de eliminación
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