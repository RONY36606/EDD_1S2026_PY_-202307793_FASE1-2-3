package solicitudReabastecimiento;
use strict;
use warnings;

sub new{
    my($class, %args)=@_;
    my $self = {
        departamento => $args{departamento} || '',
        tipoInsumo => $args{tipoInsumo} || '',
        codigo => $args{codigo} || '',
        cantidad => $args{cantidad} || 0,
        motivo => $args{motivo} || '',
        solicitante => $args{solicitante} || '',
        fecha => $args{fecha} || '',
        estado => $args{estado} || '',
    };
    return bless $self, $class;
};

# ==========================================
# GETTERS
# ==========================================
sub get_departamento { return $_[0]->{departamento}; }
sub get_tipoInsumo   { return $_[0]->{tipoInsumo}; }
sub get_codigo       { return $_[0]->{codigo}; }
sub get_cantidad     { return $_[0]->{cantidad}; }
sub get_motivo       { return $_[0]->{motivo}; }
sub get_solicitante  { return $_[0]->{solicitante}; }
sub get_fecha        { return $_[0]->{fecha}; }
sub get_estado       { return $_[0]->{estado}; }

# ==========================================
# SETTERS
# ==========================================
sub set_departamento { $_[0]->{departamento} = $_[1]; return $_[0]; }
sub set_tipoInsumo   { $_[0]->{tipoInsumo} = $_[1]; return $_[0]; }
sub set_codigo       { $_[0]->{codigo} = $_[1]; return $_[0]; }
sub set_cantidad     { $_[0]->{cantidad} = $_[1]; return $_[0]; }
sub set_motivo       { $_[0]->{motivo} = $_[1]; return $_[0]; }
sub set_solicitante  { $_[0]->{solicitante} = $_[1]; return $_[0]; }
sub set_fecha        { $_[0]->{fecha} = $_[1]; return $_[0]; }
sub set_estado       { $_[0]->{estado} = $_[1]; return $_[0]; }

1;