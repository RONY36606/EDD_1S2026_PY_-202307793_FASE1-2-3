package nodoB;
use strict;
use warnings;

sub new {
    my ($clase) = @_;
    return bless {
        claves  => [],   # cada elemento: { clave => '...', valor => $objeto }
        hijos   => [],
        es_hoja => 1,
    }, $clase;
}

sub num_claves { return scalar @{ $_[0]->{claves} }; }

1;