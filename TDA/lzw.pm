package lzw;

use strict;
use warnings;

# Constructor (No necesita estado interno, es un algoritmo puro)
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

# ==========================================
# COMPRESIÓN
# ==========================================
# Entrada: Cadena de texto (string)
# Salida: Cadena binaria (bytes) lista para guardar en archivo .lzw
sub compress {
    my ($self, $input) = @_;
    return "" unless defined $input && length($input) > 0;

    # 1. Inicializar diccionario con caracteres ASCII básicos (0-255)
    my %dictionary;
    for my $i (0..255) {
        $dictionary{chr($i)} = $i;
    }

    my $next_code = 256;
    my @output_codes;
    my $current_string = "";

    # 2. Recorrer el texto carácter por carácter
    for my $char (split //, $input) {
        my $combined = $current_string . $char;
        
        # Si la combinación ya existe en el diccionario, la extendemos
        if (exists $dictionary{$combined}) {
            $current_string = $combined;
        } else {
            # Si NO existe:
            # a) Emitimos el código de lo que teníamos hasta ahora
            push @output_codes, $dictionary{$current_string};
            
            # b) Agregamos la nueva combinación al diccionario
            $dictionary{$combined} = $next_code++;
            
            # c) Reiniciamos la cadena actual con el carácter nuevo
            $current_string = $char;
        }
    }
    
    # Emitir el código de la última secuencia restante
    if ($current_string ne "") {
        push @output_codes, $dictionary{$current_string};
    }

    # 3. Serializar a binario
    # 'L>*' empaqueta la lista de enteros en formato Unsigned Long (4 bytes) Big Endian
    my $binary_output = pack('L>*', @output_codes);
    return $binary_output;
}

# ==========================================
# DESCOMPRESIÓN
# ==========================================
# Entrada: Cadena binaria (bytes) leída del archivo .lzw
# Salida: Texto original recuperado
sub decompress {
    my ($self, $binary_input) = @_;
    return "" unless defined $binary_input && length($binary_input) > 0;

    # 1. Leer los bytes y convertirlos de vuelta a lista de códigos
    my @codes = unpack('L>*', $binary_input);
    
    # 2. Inicializar diccionario (inverso: código -> carácter)
    my %dictionary;
    for my $i (0..255) {
        $dictionary{$i} = chr($i);
    }

    my $next_code = 256;
    my $result_string = "";
    
    # Procesar el primer código manualmente
    my $old_code = shift @codes;
    $result_string .= $dictionary{$old_code};
    my $previous_string = $dictionary{$old_code};

    # 3. Iterar sobre el resto de códigos
    foreach my $code (@codes) {
        my $current_string = "";
        
        if (exists $dictionary{$code}) {
            $current_string = $dictionary{$code};
        } 
        # CASO ESPECIAL LZW (KwKwK):
        # Ocurre cuando el código a decodificar es exactamente el siguiente que íbamos a añadir.
        # Solución: Es la cadena anterior + su primer carácter.
        elsif ($code == $next_code) {
            $current_string = $previous_string . substr($previous_string, 0, 1);
        } else {
            warn "Error: Código inválido o archivo corrupto ($code)\n";
            return "ERROR_DECOMPRESION";
        }
        
        $result_string .= $current_string;
        
        # Añadir nueva entrada al diccionario: cadena anterior + primer char de la actual
        $dictionary{$next_code++} = $previous_string . substr($current_string, 0, 1);
        
        $previous_string = $current_string;
    }
    
    return $result_string;
}

1;