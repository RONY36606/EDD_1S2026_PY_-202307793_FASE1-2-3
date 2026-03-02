#!/usr/bin/perl
use strict;
use warnings;
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json decode_json);

use lib 'Clases';
use lib 'TDA';

use medicamento;
use listaDoblementeEnlazada;
use listaCircular;
use listaCircularDoble;
use proveedor;
use entregaProveedor;
use solicitudReabastecimiento;
use matrizDispersa;

my $listaMedicamentos = listaDoblementeEnlazada->new;
my $listaProveedores  = listaCircular->new;
my $listaSolicitudes  = listaCircularDoble->new;
my $matrizDispersaMed = matrizDispersa->new;

my %usuarios_avl = (
    'COL-10245' => { nombre => 'Ana Ramírez',     tipo => 'TIPO-01', depto => 'DEP-MED', pass => 'medgen2026'  },
    'COL-10389' => { nombre => 'Roberto Aguilar', tipo => 'TIPO-02', depto => 'DEP-CIR', pass => 'cirugia2026' },
    'COL-20134' => { nombre => 'María Paz',        tipo => 'TIPO-03', depto => 'DEP-FAR', pass => 'enf2026far'  },
);

sub generar_codigo_med {
    my $num = $listaMedicamentos->size + 1;
    return sprintf("MED%03d", $num);
}

get '/' => sub ($c) { $c->reply->static('index.html') };

post '/login' => sub ($c) {
    my $data = decode_json($c->req->body);
    my $user = $data->{usuario}  // '';
    my $pass = $data->{password} // '';

    if ($user eq 'AdminHospital' && $pass eq 'MedTrack2025') {
        return $c->render(json => { ok=>1, rol=>'admin', nombre=>'Administrador', tipo=>'TIPO-05' });
    }

    if (exists $usuarios_avl{$user} && $usuarios_avl{$user}{pass} eq $pass) {
        my $u = $usuarios_avl{$user};
        return $c->render(json => { ok=>1, rol=>'medico', nombre=>$u->{nombre}, tipo=>$u->{tipo}, depto=>$u->{depto} });
    }

    return $c->render(json => { ok=>0, mensaje=>'Credenciales incorrectas' });
};

post '/registro' => sub ($c) {
    my $d       = decode_json($c->req->body);
    my $colegio = $d->{numero_colegio} // '';
    my $nombre  = $d->{nombre}         // '';
    my $tipo    = $d->{tipo_usuario}   // '';
    my $depto   = $d->{departamento}   // '';
    my $espec   = $d->{especialidad}   // '';
    my $pass    = $d->{contrasena}     // '';

    return $c->render(json => { ok=>0, mensaje=>'Complete todos los campos' })
        unless $colegio && $nombre && $tipo && $depto && $pass;

    return $c->render(json => { ok=>0, mensaje=>'N de colegio ya registrado' })
        if exists $usuarios_avl{$colegio};

    $usuarios_avl{$colegio} = { nombre=>$nombre, tipo=>$tipo, depto=>$depto, especialidad=>$espec, pass=>$pass };
    return $c->render(json => { ok=>1, mensaje=>'Usuario registrado exitosamente' });
};

get '/usuarios' => sub ($c) {
    my @lista;
    for my $col (sort keys %usuarios_avl) {
        my $u = $usuarios_avl{$col};
        push @lista, { numero_colegio=>$col, nombre=>$u->{nombre}, tipo=>$u->{tipo}, departamento=>$u->{depto}, especialidad=>$u->{especialidad}//'' };
    }
    $c->render(json => { ok=>1, usuarios=>\@lista });
};

get '/medicamentos' => sub ($c) {
    my @lista;
    $listaMedicamentos->iterar(sub {
        my $nodo = shift; my $med = $nodo->value;
        push @lista, { codigo=>$med->codigoMedicina, nombre=>$med->nombreComercial, activo=>$med->principioActivo, lab=>$med->laboratorioFabricante, stock=>$med->cantidadStock, vence=>$med->fechaVencimiento, precio=>$med->precio, minimo=>$med->nivelMinimoReorden };
    });
    $c->render(json => { ok=>1, medicamentos=>\@lista });
};

# POST /carga-masiva → Procesa CSV de medicamentos
# POST /carga-masiva — Funcion 1 del enunciado
# JSON con clave "proveedor": array de proveedores, cada uno con "entrega": []
post '/carga-masiva' => sub ($c) {
    my $upload = $c->req->upload('json');

    unless ($upload && $upload->filename =~ /\.json$/i) {
        return $c->render(json => { ok=>0, mensaje=>'El archivo debe ser .json' });
    }

    my $data;
    eval { $data = decode_json($upload->slurp); };
    if ($@) {
        return $c->render(json => { ok=>0, mensaje=>'JSON malformado: ' . $@ });
    }

    unless (ref($data->{proveedor}) eq 'ARRAY') {
        return $c->render(json => { ok=>0, mensaje=>'El JSON debe tener la clave "proveedor" como array' });
    }

    my ($meds, $equipos, $suministros, $provs) = (0, 0, 0, 0);
    #lista de errores que pueden venirs
    my @errores;

    for my $prov_data (@{ $data->{proveedor} }) {
        my $nit     = trim($prov_data->{nit}            // '');
        my $pnombre = trim($prov_data->{nombre}         // '');
        my $tel     = trim($prov_data->{telefono}       // '');
        my $dir     = trim($prov_data->{direccion}      // '');
        my $fent    = trim($prov_data->{fecha_entrega}  // '');
        my $fact    = trim($prov_data->{numero_factura} // '');

        unless ($nit && $pnombre) {
            push @errores, "Proveedor sin NIT o nombre, omitido";
            next;
        }

        # Fase 2: $listaProveedores->insertar({ nit=>$nit, nombre=>$pnombre, ... })
        $provs++;

        for my $item (@{ $prov_data->{entrega} // [] }) {
            my $tipo   = uc(trim($item->{tipo}    // ''));
            my $codigo = trim($item->{codigo}     // '');
            my $nom    = trim($item->{nombre}     // '');
            my $fab    = trim($item->{fabricante} // '');
            my $precio = $item->{precio_unitario} // 0;
            my $cant   = $item->{cantidad}        // 0;
            my $nivel  = $item->{nivel_minimo}    // 0;

            unless ($tipo && $codigo && $nom) {
                push @errores, "Item sin tipo/codigo/nombre en '$pnombre', omitido";
                next;
            }
            unless ($cant > 0) {
                push @errores, "Codigo $codigo: cantidad invalida, omitido";
                next;
            }
            unless ($tipo eq 'MEDICAMENTO' || $tipo eq 'EQUIPO' || $tipo eq 'SUMINISTRO') {
                push @errores, "Tipo '$tipo' no reconocido en codigo $codigo, omitido";
                next;
            }

            if ($tipo eq 'MEDICAMENTO') {
                my $activo  = trim($item->{principio_activo}  // '');
                my $vence   = trim($item->{fecha_vencimiento} // '');
                my $cod_med = "MED$codigo";

                my $existe = 0;
                $listaMedicamentos->iterar(sub {
                    $existe = 1 if $_[0]->value->codigoMedicina eq $cod_med;
                });

                if ($existe) {
                    push @errores, "$cod_med ya existe, omitido";
                    next;
                }

                my $med = medicamento->new(
                    codigoMedicina        => $cod_med,
                    nombreComercial       => $nom,
                    principioActivo       => $activo,
                    laboratorioFabricante => $fab,
                    cantidadStock         => $cant,
                    fechaVencimiento      => $vence,
                    precio                => $precio,
                    nivelMinimoReorden    => $nivel,
                );
                $matrizDispersaMed->insertar($pnombre, $fab, $med);
                $listaMedicamentos->pushBack($med);
                $meds++;

            } elsif ($tipo eq 'EQUIPO') {
                my $fing   = trim($item->{fecha_ingreso} // '');
                my $cod_eq = "EQU$codigo";
                # Fase 2: $arbolBST->insertar({ codigo=>$cod_eq, nombre=>$nom,
                #   fabricante=>$fab, precio=>$precio, cantidad=>$cant,
                #   fecha_ingreso=>$fing, nivel_minimo=>$nivel })
                $equipos++;

            } elsif ($tipo eq 'SUMINISTRO') {
                my $vence   = trim($item->{fecha_vencimiento} // '');
                my $cod_sum = "SUM$codigo";
                # Fase 2: $arbolB->insertar({ codigo=>$cod_sum, nombre=>$nom,
                #   fabricante=>$fab, precio=>$precio, cantidad=>$cant,
                #   fecha_vencimiento=>$vence, nivel_minimo=>$nivel })
                $suministros++;
            }
        }
    }

    return $c->render(json => {
        ok           => 1,
        medicamentos => $meds,
        equipos      => $equipos,
        suministros  => $suministros,
        proveedores  => $provs,
        errores      => \@errores,
    });
};

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s; }

post '/medicamentos' => sub ($c) {
    my $d = decode_json($c->req->body);
    my $codigo = generar_codigo_med();
    my $med = medicamento->new(
        codigoMedicina=>$codigo, nombreComercial=>$d->{nombre}//'',
        principioActivo=>$d->{activo}//'', laboratorioFabricante=>$d->{lab}//'',
        cantidadStock=>$d->{stock}//0, fechaVencimiento=>$d->{vence}//'',
        precio=>$d->{precio}//0, nivelMinimoReorden=>$d->{minimo}//0,
    );
    $matrizDispersaMed->insertar($d->{lab}//'', $d->{nombre}//'', $med);
    $listaMedicamentos->pushBack($med);
    $c->render(json => { ok=>1, codigo=>$codigo });
};

app->start;

