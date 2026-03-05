package arbolB;
use strict;
use warnings;
use constant ORDEN => 4;  # max 3 claves, max 4 hijos por nodo

require 'nodoB.pl';

sub new {
    my ($clase) = @_;
    return bless { raiz => nodoB->new() }, $clase;
}


#ESTO INVOCA A BUSCAR DE MANERA RECURSIVA
sub buscar {
    my ($self, $clave) = @_;
    return $self->_buscar($self->{raiz}, $clave);
}

sub _buscar {
    my ($self, $nodo, $clave) = @_;
    return undef unless defined $nodo;

    my $claves = $nodo->{claves};
    my $i = 0;
    $i++ while $i < scalar(@$claves) && $clave gt $claves->[$i]{clave};

    # Encontrada
    if ($i < scalar(@$claves) && $clave eq $claves->[$i]{clave}) {
        return $claves->[$i]{valor};  # devuelve el objeto
    }

    return undef if $nodo->{es_hoja};
    return $self->_buscar($nodo->{hijos}[$i], $clave);
}

#==================================ESTO ES PARA INSERTAR UN NUEVO CONTENIDO===============================
sub insertar {
    my ($self, $clave, $valor) = @_;
    my $raiz = $self->{raiz};

    if ($raiz->num_claves == ArbolB::ORDEN - 1) {
        my $nueva_raiz = nodoB->new();
        $nueva_raiz->{es_hoja} = 0;
        push @{ $nueva_raiz->{hijos} }, $raiz;
        $self->_split_hijo($nueva_raiz, 0);
        $self->{raiz} = $nueva_raiz;
        $self->_insertar_no_lleno($nueva_raiz, $clave, $valor);
    } else {
        $self->_insertar_no_lleno($raiz, $clave, $valor);
    }
}

#============================================================================
sub _split_hijo {
    my ($self, $padre, $i) = @_;
    my $t    = int(ArbolB::ORDEN / 2);
    my $hijo = $padre->{hijos}[$i];
    my $nuevo = nodoB->new();
    $nuevo->{es_hoja} = $hijo->{es_hoja};

    my @claves_hijo = @{ $hijo->{claves} };
    $nuevo->{claves} = [ @claves_hijo[$t .. $#claves_hijo] ];
    $hijo->{claves}  = [ @claves_hijo[0 .. $t-2] ];

    if (!$hijo->{es_hoja}) {
        my @hijos_hijo   = @{ $hijo->{hijos} };
        $nuevo->{hijos}  = [ @hijos_hijo[$t .. $#hijos_hijo] ];
        $hijo->{hijos}   = [ @hijos_hijo[0 .. $t-1] ];
    }

    # La clave del medio sube al padre — con su objeto completo
    splice(@{ $padre->{claves} }, $i, 0, $claves_hijo[$t-1]);
    splice(@{ $padre->{hijos} }, $i+1, 0, $nuevo);
}

#=====================================================0

sub _insertar_no_lleno {
    my ($self, $nodo, $clave, $valor) = @_;
    my $i = $nodo->num_claves - 1;

    if ($nodo->{es_hoja}) {
        my @claves = @{ $nodo->{claves} };
        my $pos = scalar @claves;
        $pos-- while $pos > 0 && $clave lt $claves[$pos-1]{clave};
        splice(@{ $nodo->{claves} }, $pos, 0, { clave => $clave, valor => $valor });
    } else {
        $i-- while $i >= 0 && $clave lt $nodo->{claves}[$i]{clave};
        $i++;

        if ($nodo->{hijos}[$i]->num_claves == ArbolB::ORDEN - 1) {
            $self->_split_hijo($nodo, $i);
            $i++ if $clave gt $nodo->{claves}[$i]{clave};
        }
        $self->_insertar_no_lleno($nodo->{hijos}[$i], $clave, $valor);
    }
}

# =====================================SOLO TENEMOS EL RECORRIDO DE INORDER====================================
sub _inorden {
    my ($self, $nodo, $r) = @_;
    return unless defined $nodo;

    my $num = $nodo->num_claves;
    for my $i (0 .. $num - 1) {
        $self->_inorden($nodo->{hijos}[$i], $r) unless $nodo->{es_hoja};
        push @$r, { clave => $nodo->{claves}[$i]{clave}, valor => $nodo->{claves}[$i]{valor} };
    }
    $self->_inorden($nodo->{hijos}[$num], $r) unless $nodo->{es_hoja};
}

sub inorden {
    my ($self) = @_;
    my @r;
    $self->_inorden($self->{raiz}, \@r);
    return \@r;
}

# Para Graphviz
sub raiz { return $_[0]->{raiz}; }

1;