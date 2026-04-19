package lzw;
use strict;
use warnings;


sub new {
    my ($class) = @_;
    return bless {}, $class;
}

# ── Comprimir un string a una lista de códigos ─────────────────────
sub comprimir {
    my ($self, $texto) = @_;
    return [] unless defined $texto && length $texto;

    # Diccionario inicial: todos los bytes 0-255
    my %dict;
    $dict{chr($_)} = $_ for 0 .. 255;
    my $siguiente = 256;

    my @codigos;
    my $w = '';

    for my $c (split //, $texto) {
        my $wc = $w . $c;
        if (exists $dict{$wc}) {
            $w = $wc;
        } else {
            push @codigos, $dict{$w} if length $w;
            $dict{$wc}  = $siguiente++;
            $w = $c;
        }
    }
    push @codigos, $dict{$w} if length $w;

    return \@codigos;
}

# ── Descomprimir lista de códigos a un  string ───────────────────
sub descomprimir {
    my ($self, $codigos) = @_;
    return '' unless ref($codigos) eq 'ARRAY' && @$codigos;

    # Diccionario inverso inicial
    my %dict;
    $dict{$_} = chr($_) for 0 .. 255;
    my $siguiente = 256;

    my $w      = $dict{ $codigos->[0] } // '';
    my $result = $w;

    for my $i (1 .. $#$codigos) {
        my $k = $codigos->[$i];
        my $entry;
        if (exists $dict{$k}) {
            $entry = $dict{$k};
        } elsif ($k == $siguiente) {
            $entry = $w . substr($w, 0, 1);
        } else {
            die "LZW descomprimir: código inválido $k\n";
        }
        $result .= $entry;
        $dict{$siguiente++} = $w . substr($entry, 0, 1);
        $w = $entry;
    }
    return $result;
}

# ── Guardar historial de chats de un usuario ─────────────────
# chats_usuario: { 'COL-XXX' => [ { de, para, msg, ts }, ... ] }
sub guardar_chats {
    my ($self, $numero_colegio, $chats_usuario, $dir) = @_;
    $dir //= 'chats';
    mkdir $dir unless -d $dir;

    # Serializar a texto estructurado
    my $texto = _serializar($numero_colegio, $chats_usuario);

    # Comprimir
    my $codigos = $self->comprimir($texto);

    # Escribir archivo .lzw (códigos separados por comas)
    # Sanitizar SOLO el nombre del colegio, no el directorio
    (my $nombre_seguro = $numero_colegio) =~ s/[<>:"\/\\|?*]/_/g;
    my $archivo = "$dir/$nombre_seguro.lzw";

    open(my $fh, '>', $archivo) or die "No se pudo crear $archivo: $!";
    print $fh join(',', @$codigos);
    close($fh);

    return $archivo;
}

# ── Cargar historial de chats de un usuario ──────────────────
sub cargar_chats {
    my ($self, $numero_colegio, $dir) = @_;
    $dir //= 'chats';

    # Sanitizar SOLO el nombre del colegio, no el directorio
    (my $nombre_seguro = $numero_colegio) =~ s/[<>:"\/\\|?*]/_/g;
    my $archivo = "$dir/$nombre_seguro.lzw";

    return {} unless -f $archivo;

    # Leer y descomprimir
    open(my $fh, '<', $archivo) or return {};
    my $contenido = do { local $/; <$fh> };
    close($fh);

    return {} unless $contenido && $contenido =~ /\d/;

    my @codigos = split /,/, $contenido;
    my $texto = eval { $self->descomprimir(\@codigos) };
    return {} if $@;

    return _deserializar($texto);
}

# ── Listar archivos .lzw existentes ──────────────────────────
sub listar_archivos {
    my ($self, $dir) = @_;
    $dir //= 'chats';
    return [] unless -d $dir;

    opendir(my $dh, $dir) or return [];
    my @archivos = grep { /\.lzw$/ } readdir($dh);
    closedir($dh);

    my @resultado;
    for my $arch (sort @archivos) {
        my $ruta = "$dir/$arch";
        my @stat = stat($ruta);
        push @resultado, {
            archivo => $arch,
            ruta    => $ruta,
            tam_kb  => sprintf("%.2f", ($stat[7] // 0) / 1024),
        };
    }
    return \@resultado;
}

# ── Serializar estructura de chats a texto ───────────────────
sub _serializar {
    my ($usuario, $chats) = @_;
    my @lineas;
    push @lineas, "USUARIO:$usuario";

    for my $interlocutor (sort keys %{ $chats // {} }) {
        push @lineas, "CONV:$interlocutor";
        for my $msg (@{ $chats->{$interlocutor} // [] }) {
            my $de  = $msg->{de}   // '';
            my $ts  = $msg->{ts}   // '';
            my $txt = $msg->{msg}  // '';
            # Escapar saltos de línea dentro del mensaje
            $txt =~ s/\n/\\n/g;
            $txt =~ s/\|/\\pipe/g;
            push @lineas, "MSG:$de|$ts|$txt";
        }
    }
    return join("\n", @lineas);
}

# ── Deserializar texto a estructura de chats ─────────────────
sub _deserializar {
    my ($texto) = @_;
    my %chats;
    my $conv_actual = '';

    for my $linea (split /\n/, $texto) {
        if ($linea =~ /^CONV:(.+)$/) {
            $conv_actual = $1;
            $chats{$conv_actual} //= [];
        } elsif ($linea =~ /^MSG:(.+)\|(.+)\|(.*)$/ && $conv_actual) {
            my ($de, $ts, $txt) = ($1, $2, $3);
            $txt =~ s/\\n/\n/g;
            $txt =~ s/\\pipe/|/g;
            push @{ $chats{$conv_actual} }, {
                de  => $de,
                ts  => $ts,
                msg => $txt,
            };
        }
    }
    return \%chats;
}

1;