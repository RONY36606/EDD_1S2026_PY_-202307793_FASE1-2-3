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
use equipo; 
use suministro;
use ArbolAVL;
use ArbolBST;
use ArbolB;
use entregaProveedorAct;

my $listaMedicamentos = listaDoblementeEnlazada->new;
my $listaProveedores  = listaCircular->new;
my $listaSolicitudes  = listaCircularDoble->new;
my $matrizDispersaMed = matrizDispersa->new;

#TOCA LLAMAR A LOS ÁRBOLES
my $arbolAVL = ArbolAVL->new;
my $arbolBST = ArbolBST->new;
my $arbolB   = ArbolB->new;

$arbolAVL->insertar('COL-10245', { nombre=>'Ana Ramirez',     tipo=>'TIPO-01', depto=>'DEP-MED', espec=>'Medicina General',       pass=>'medgen2026'  });
$arbolAVL->insertar('COL-10389', { nombre=>'Roberto Aguilar', tipo=>'TIPO-02', depto=>'DEP-CIR', espec=>'Cirugia Cardiovascular', pass=>'cirugia2026' });
$arbolAVL->insertar('COL-20134', { nombre=>'Maria Paz',        tipo=>'TIPO-03', depto=>'DEP-FAR', espec=>'',                       pass=>'enf2026far'  });


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


#Ahora ya buscamos dentro de un árbol AVL
     my $u = $arbolAVL->buscar($user);
    if (defined $u && $u->{pass} eq $pass) {
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

    return $c->render(json => { ok=>0, mensaje=>"$colegio ya esta registrado" })
        if defined $arbolAVL->buscar($colegio);

     $arbolAVL->insertar($colegio, { nombre=>$nombre, tipo=>$tipo, depto=>$depto, espec=>$espec, pass=>$pass });
    return $c->render(json => { ok=>1, mensaje=>'Usuario registrado exitosamente' });
};


#=============================================CONUSLTAR USUARIOS=======================================0
get '/usuarios' => sub ($c) {
    my @lista;
    for my $entry (@{ $arbolAVL->inorden() }) {
        my $u = $entry->{valor};
        push @lista, {
            numero_colegio => $entry->{clave},
            nombre         => $u->{nombre},
            tipo           => $u->{tipo},
            departamento   => $u->{depto},
            especialidad   => $u->{espec} // '',
        };
    }
    $c->render(json => { ok=>1, usuarios=>\@lista });
};
#=============================================CONUSLTAR EQUIPOS=======================================0
get '/equipos' => sub ($c) {
    my @lista;
    for my $entry (@{ $arbolBST->inorden() }) {
        my $eq = $entry->{valor};
        push @lista, {
            codigo    => $eq->codigoEquipo,
            nombre    => $eq->nombreEquipo,
            fabricante=> $eq->fabricanteEquipo,
            precio    => $eq->precioEquipo,
            cantidad  => $eq->cantidadEquipo,
            fecha     => $eq->fechaIngresoEquipo,
            minimo    => $eq->nivelMinimoReorden,
        };
    }
    $c->render(json => { ok=>1, equipos=>\@lista });
};
#=============================================CONUSLTAR SUMINISTROS=======================================0
get '/suministros' => sub ($c) {
    my @lista;
    for my $entry (@{ $arbolB->inorden() }) {
        my $sum = $entry->{valor};
        push @lista, {
            codigo    => $sum->codigoSuministro,
            nombre    => $sum->nombreSuministro,
            fabricante=> $sum->fabricanteSuministro,
            precio    => $sum->precioSuministro,
            cantidad  => $sum->cantidadSuministro,
            vence     => $sum->fechaVencimientoSuministro,
            minimo    => $sum->nivelMinimoReorden,
        };
    }
    $c->render(json => { ok=>1, suministros=>\@lista });
};

#======================CONSULTA DE MEDICAMENTOS===============================================
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

        #====================CREAMOS AL PROVEEDOR==================
        # Antes de crear $prov, verificar si ya existe por NIT
        my $prov_existente = undef;
        #recorremos la lista en búsqueda del mismo proveedor
        $listaProveedores->recorrer(sub {
            my $nodo = shift;
            $prov_existente = $nodo->valor if $nodo->valor->nit eq $nit;
        });
        my $prov;
        #verificar la existencia del proveedor
        if (defined $prov_existente) {
            # Ya existe, solo agregar la nueva entrega al mismo proveedor
            $prov = $prov_existente;
        } else {
            # Es nuevo, crearlo e insertarlo al final
            $prov = proveedor->new(
                nit           => $nit,
                nombreEmpresa => $pnombre,
                telefono      => $tel,
                direccion     => $dir,
            );
            $listaProveedores->pushBack($prov);
            $provs++;
        }

        #=========================CREAMOS LA NUEVA ENTREGA===============================0
        my $entrega = entregaProveedor->new(
            fechaEntrega  => $fent,
            numeroFactura => $fact,
        );

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
                #metemos el artículo en la entrega
                $entrega->agregarItem($med);
                #metemos los medicamentos en la lista de medicamentos y en la matriz
                $matrizDispersaMed->insertar($pnombre, $fab, $med);
                $listaMedicamentos->pushBack($med);
                $meds++;

            } elsif ($tipo eq 'EQUIPO') {
                my $fing   = trim($item->{fecha_ingreso} // '');
                my $cod_eq = "EQU$codigo";

                # Verificar que no haya duplicados dentro del árbol
                if (defined $arbolBST->buscar($cod_eq)) {
                    push @errores, "$cod_eq ya existe, omitido";
                    next;
                }

                #construimos el equipo
                my $eq = equipo->new(
                    tipo               => 'EQUIPO',
                    codigoEquipo       => $cod_eq,
                    nombreEquipo       => $nom,
                    fabricanteEquipo   => $fab,
                    precioEquipo       => $precio,
                    cantidadEquipo     => $cant,
                    fechaIngresoEquipo => $fing,
                    nivelMinimoReorden => $nivel,
                );
                #metemos el artículo en la entrega
                $entrega->agregarItem($eq);
                #insertamos los equipos y aumentamos el contador de equipo
                $arbolBST->insertar($cod_eq, $eq);
                $equipos++;

            } elsif ($tipo eq 'SUMINISTRO') {
                my $vence   = trim($item->{fecha_vencimiento} // '');
                my $cod_sum = "SUM$codigo";
                # Verificar que no hya duplicado en Árbol B
                if (defined $arbolB->buscar($cod_sum)) {
                    push @errores, "$cod_sum ya existe, omitido";
                    next;
                }
                #creamos el suministro
                my $sum = suministro->new(
                    tipo                       => 'SUMINISTRO',
                    codigoSuministro           => $cod_sum,
                    nombreSuministro           => $nom,
                    fabricanteSuministro       => $fab,
                    precioSuministro           => $precio,
                    cantidadSuministro         => $cant,
                    fechaVencimientoSuministro => $vence,
                    nivelMinimoReorden         => $nivel,
                );
                #metemos el artículo en la entrega
                $entrega->agregarItem($sum);
                #insertamos dentro del árbol y aumentamos el contador
                $arbolB->insertar($cod_sum, $sum);
                $suministros++;
            }
        }
        #metemos la entrega en la lista del proveedor vigente
         $prov->agregarEntrega($entrega);
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

