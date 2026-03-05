package entregaProveedorAct;
use strict;
use warnings;

# Una entrega representa una factura completa de un proveedor.
# Contiene los datos de la transacción y un array de items entregados,
# donde cada item puede ser un objeto medicamento, equipo o suministro.
#
# Ejemplo de uso:
#   my $entrega = entregaProveedor->new(
#       fechaEntrega  => '2026-03-15',
#       numeroFactura => 'FAC-2026-00145',
#   );
#   $entrega->agregarItem($objMedicamento);
#   $entrega->agregarItem($objEquipo);

sub new {
    my ($class, %args) = @_;
    my $self = {
        fechaEntrega  => $args{fechaEntrega}  || '',
        numeroFactura => $args{numeroFactura} || '',
        items         => [],   # array de objetos (medicamento, equipo, suministro)
    };
    return bless $self, $class;
}

# ── GETTERS & SETTERS ─────────────────────────────────────────────────────────

sub fechaEntrega {
    my ($self, $val) = @_;
    $self->{fechaEntrega} = $val if defined $val;
    return $self->{fechaEntrega};
}

sub numeroFactura {
    my ($self, $val) = @_;
    $self->{numeroFactura} = $val if defined $val;
    return $self->{numeroFactura};
}

#=========================MANEJO DEL CONTENIDO =============================================
# Agregar cualquier objeto al array de items
sub agregarItem {
    my ($self, $objeto) = @_;
    push @{ $self->{items} }, $objeto;
}

# Devuelve el array completo de items
sub items {
    my ($self) = @_;
    return $self->{items};
}

# Cuántos items tiene esta entrega
sub totalItems {
    my ($self) = @_;
    return scalar @{ $self->{items} };
}

# Filtrar items por tipo (devuelve solo medicamentos, o solo equipos, y cosas así)
sub itemsPorTipo {
    my ($self, $tipo) = @_;
    return [ grep { ref($_) eq $tipo } @{ $self->{items} } ];
}

1;