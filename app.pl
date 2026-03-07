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
use solicitudReabastecimiento;
use matrizDispersa;
use equipo; 
use suministro;
use arbolAvl;
use arbolBST;
use arbolB;
use entregaProveedorAct;

my $listaMedicamentos = listaDoblementeEnlazada->new;
my $listaProveedores  = listaCircularDoble->new;
my $listaSolicitudes  = listaCircularDoble->new;
my $matrizDispersaMed = matrizDispersa->new;

#TOCA LLAMAR A LOS ÁRBOLES
my $arbolAVL = arbolAvl->new;
my $arbolBST = arbolBST->new;
my $arbolB   = arbolB->new;



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
    my $colegio = trim($d->{numero_colegio} // '');
    my $nombre  = trim($d->{nombre}         // '');
    my $tipo    = trim($d->{tipo_usuario}   // '');
    my $depto   = trim($d->{departamento}   // '');
    my $espec   = trim($d->{especialidad}   // '');
    my $pass    = $d->{contrasena}          // '';

    # Validar campos obligatorios
    return $c->render(json => { ok=>0, mensaje=>'Complete todos los campos obligatorios' })
        unless $colegio && $nombre && $tipo && $depto && $pass;

    # Validar tipo
    return $c->render(json => { ok=>0, mensaje=>"Tipo '$tipo' no reconocido" })
        unless $tipo =~ /^TIPO-0[1-5]$/;

    # Validar departamento
    return $c->render(json => { ok=>0, mensaje=>"Departamento '$depto' no reconocido" })
        unless $depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$/;

    # Especialidad obligatoria para TIPO-01 y TIPO-02
    return $c->render(json => { ok=>0, mensaje=>'Especialidad requerida para este tipo de usuario' })
        if ($tipo eq 'TIPO-01' || $tipo eq 'TIPO-02') && !$espec;

    # Verificar duplicado en AVL
    return $c->render(json => { ok=>0, mensaje=>"$colegio ya esta registrado en el sistema" })
        if defined $arbolAVL->buscar($colegio);

    # Insertar en AVL
    $arbolAVL->insertar($colegio, {
        nombre => $nombre,
        tipo   => $tipo,
        depto  => $depto,
        espec  => $espec,
        pass   => $pass,
    });

    return $c->render(json => { ok=>1, mensaje=>"$colegio registrado exitosamente" });
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
        $listaProveedores->recorrerAdelante(sub {
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
            $listaProveedores->insertar($prov);
            $provs++;
        }

        #=========================CREAMOS LA NUEVA ENTREGA===============================0
        my $entrega = entregaProveedorAct->new(
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

# =========================================EQUIPOS (Árbol BST)  =========================================

# Este endpoint es para recorrer el árbol de diferentes formas
get '/equipos' => sub ($c) {
    my $recorrido = $c->param('recorrido') // 'inorden';
    my $lista;

    if    ($recorrido eq 'preorden')  { $lista = $arbolBST->preorden;  }
    elsif ($recorrido eq 'postorden') { $lista = $arbolBST->postorden; }
    else                              { $lista = $arbolBST->inorden;   }

    my @resultado = map {
        my $eq = $_->{valor};
        {
            codigo    => $eq->codigoEquipo,
            nombre    => $eq->nombreEquipo,
            fabricante=> $eq->fabricanteEquipo,
            precio    => $eq->precioEquipo,
            cantidad  => $eq->cantidadEquipo,
            fecha     => $eq->fechaIngresoEquipo,
            minimo    => $eq->nivelMinimoReorden,
        }
    } @$lista;

    $c->render(json => { ok=>1, equipos=>\@resultado, recorrido=>$recorrido });
};

# Este endpoint es para buscar los equipos uno a uno
get '/equipos/:codigo' => sub ($c) {
    my $codigo = uc(trim($c->param('codigo')));
    my $eq     = $arbolBST->buscar($codigo);

    unless (defined $eq) {
        return $c->render(json => { ok=>0, mensaje=>"Equipo $codigo no encontrado" });
    }

    $c->render(json => {
        ok        => 1,
        codigo    => $eq->codigoEquipo,
        nombre    => $eq->nombreEquipo,
        fabricante=> $eq->fabricanteEquipo,
        precio    => $eq->precioEquipo,
        cantidad  => $eq->cantidadEquipo,
        fecha     => $eq->fechaIngresoEquipo,
        minimo    => $eq->nivelMinimoReorden,
    });
};

# Este endpoint es para registrar un equipo de manera individual
post '/equipos' => sub ($c) {
    my $d      = decode_json($c->req->body);
    my $codigo = uc(trim($d->{codigo} // ''));
    my $nom    = trim($d->{nombre}    // '');

    return $c->render(json => { ok=>0, mensaje=>'Código y nombre son obligatorios' })
        unless $codigo && $nom;

    #Obtener el código
    my $cod_eq = $codigo =~ /^EQU/i ? uc($codigo) : "EQU$codigo";

    return $c->render(json => { ok=>0, mensaje=>"$cod_eq ya existe en el inventario" })
        if defined $arbolBST->buscar($cod_eq);

    my $eq = equipo->new(
        tipo               => 'EQUIPO',
        codigoEquipo       => $cod_eq,
        nombreEquipo       => $nom,
        fabricanteEquipo   => trim($d->{fabricante}  // ''),
        precioEquipo       => $d->{precio}            // 0,
        cantidadEquipo     => $d->{cantidad}          // 0,
        fechaIngresoEquipo => trim($d->{fecha}        // ''),
        nivelMinimoReorden => $d->{minimo}            // 0,
    );

    $arbolBST->insertar($cod_eq, $eq);
    $c->render(json => { ok=>1, mensaje=>"$cod_eq registrado exitosamente" });
};

# Esto es para poder eliminar un equipo
del '/equipos/:codigo' => sub ($c) {
    my $codigo = uc(trim($c->param('codigo')));

    unless (defined $arbolBST->buscar($codigo)) {
        return $c->render(json => { ok=>0, mensaje=>"Equipo $codigo no encontrado" });
    }

    $arbolBST->eliminar($codigo);
    $c->render(json => { ok=>1, mensaje=>"$codigo eliminado exitosamente" });
};

## =========================================SUMINISTROS (Árbol B)  =========================================

# para retornar el recorrido Inorder
get '/suministros' => sub ($c) {
    my $lista = $arbolB->inorden;

    my @resultado = map {
        my $sum = $_->{valor};
        {
            codigo     => $sum->codigoSuministro,
            nombre     => $sum->nombreSuministro,
            fabricante => $sum->fabricanteSuministro,
            precio     => $sum->precioSuministro,
            cantidad   => $sum->cantidadSuministro,
            vence      => $sum->fechaVencimientoSuministro,
            minimo     => $sum->nivelMinimoReorden,
        }
    } @$lista;

    $c->render(json => { ok=>1, suministros=>\@resultado });
};

# para buscar un código en específico 
get '/suministros/:codigo' => sub ($c) {
    my $codigo = uc(trim($c->param('codigo')));
    my $sum    = $arbolB->buscar($codigo);

    unless (defined $sum) {
        return $c->render(json => { ok=>0, mensaje=>"Suministro $codigo no encontrado" });
    }

    $c->render(json => {
        ok         => 1,
        codigo     => $sum->codigoSuministro,
        nombre     => $sum->nombreSuministro,
        fabricante => $sum->fabricanteSuministro,
        precio     => $sum->precioSuministro,
        cantidad   => $sum->cantidadSuministro,
        vence      => $sum->fechaVencimientoSuministro,
        minimo     => $sum->nivelMinimoReorden,
    });
};

# Para el registro individual
post '/suministros' => sub ($c) {
    my $d      = decode_json($c->req->body);
    my $codigo = uc(trim($d->{codigo} // ''));
    my $nom    = trim($d->{nombre}    // '');

    return $c->render(json => { ok=>0, mensaje=>'Código y nombre son obligatorios' })
        unless $codigo && $nom;

    my $cod_sum = $codigo =~ /^SUM/i ? uc($codigo) : "SUM$codigo";

    return $c->render(json => { ok=>0, mensaje=>"$cod_sum ya existe en el inventario" })
        if defined $arbolB->buscar($cod_sum);

    my $sum = suministro->new(
        tipo                       => 'SUMINISTRO',
        codigoSuministro           => $cod_sum,
        nombreSuministro           => $nom,
        fabricanteSuministro       => trim($d->{fabricante} // ''),
        precioSuministro           => $d->{precio}           // 0,
        cantidadSuministro         => $d->{cantidad}         // 0,
        fechaVencimientoSuministro => trim($d->{vence}       // ''),
        nivelMinimoReorden         => $d->{minimo}           // 0,
    );

    $arbolB->insertar($cod_sum, $sum);
    $c->render(json => { ok=>1, mensaje=>"$cod_sum registrado exitosamente" });
};

# Para eliminar un suministro del árbol
del '/suministros/:codigo' => sub ($c) {
    my $codigo = uc(trim($c->param('codigo')));

    unless (defined $arbolB->buscar($codigo)) {
        return $c->render(json => { ok=>0, mensaje=>"Suministro $codigo no encontrado" });
    }

    $arbolB->eliminar($codigo);
    $c->render(json => { ok=>1, mensaje=>"$codigo eliminado exitosamente" });
};

#================================== PARA REGISTRAR USUARIOS DENTRO DEL ÁRBOL AVL=================================
post '/carga-usuarios' => sub ($c) {
    my $upload = $c->req->upload('json');

    #siempre se comprueba que el usuario envíe un archivo json
    unless ($upload && $upload->filename =~ /\.json$/i) {
        return $c->render(json => { ok=>0, mensaje=>'El archivo debe ser .json' });
    }

    my $data;
    eval { $data = decode_json($upload->slurp); };
    if ($@) {
        return $c->render(json => { ok=>0, mensaje=>'JSON malformado: ' . $@ });
    }

    #verificamos la estructura del json, para ver si nos sirve
    unless (ref($data->{usuarios}) eq 'ARRAY') {
        return $c->render(json => { ok=>0, mensaje=>'El JSON debe tener la clave "usuarios" como array' });
    }

    #verificar si hay duplicados y llevar conteo de errores
    my ($insertados, $duplicados) = (0, 0);
    my @errores;

    for my $u (@{ $data->{usuarios} }) {
        my $col   = trim($u->{numero_colegio}  // '');
        my $nom   = trim($u->{nombre_completo} // '');
        my $tipo  = trim($u->{tipo_usuario}    // '');
        my $depto = trim($u->{departamento}    // '');
        my $espec = trim($u->{especialidad}    // '');
        my $pass  = $u->{contrasena}           // '';

        # Validar campos obligatorios
        unless ($col && $nom && $tipo && $depto && $pass) {
            push @errores, "$col: campos incompletos, omitido";
            next;
        }

        # Validar tipo de usuario
        unless ($tipo =~ /^TIPO-0[1-5]$/) {
            push @errores, "$col: tipo '$tipo' no reconocido, omitido";
            next;
        }

        # Validar departamento
        unless ($depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$/) {
            push @errores, "$col: departamento '$depto' no reconocido, omitido";
            next;
        }

        # Verificar duplicado en AVL, si es así, se omite
        if (defined $arbolAVL->buscar($col)) {
            push @errores, "$col ya registrado, omitido";
            $duplicados++;
            next;
        }

        # Insertar en árbol AVL
        $arbolAVL->insertar($col, {
            nombre => $nom,
            tipo   => $tipo,
            depto  => $depto,
            espec  => $espec,
            pass   => $pass,
        });
        $insertados++;
    }

    #Enviar respuesta al JavaScript

    return $c->render(json => {
        ok         => 1,
        insertados => $insertados,
        duplicados => $duplicados,
        errores    => \@errores,
    });
};

#============================================ESTO ES PARA LA PARTE DEL MANEJO DEL PERSONAL=====================================
#============================================================================================================================
# buscar solamente a un usuario de entre todo el árbol
get '/usuarios/:colegio' => sub ($c) {
    my $colegio = $c->param('colegio');
    my $u       = $arbolAVL->buscar($colegio);

    unless (defined $u) {
        return $c->render(json => { ok=>0, mensaje=>"Usuario $colegio no encontrado" });
    }

    $c->render(json => {
        ok             => 1,
        numero_colegio => $colegio,
        nombre         => $u->{nombre},
        tipo           => $u->{tipo},
        departamento   => $u->{depto},
        especialidad   => $u->{espec} // '',
    });
};

# tomar a los usuarios en el recorrido deseado
get '/usuarios' => sub ($c) {
    my $recorrido = $c->param('recorrido') // 'inorden';
    my $lista;

    if    ($recorrido eq 'preorden')  { $lista = $arbolAVL->preorden;  }
    elsif ($recorrido eq 'postorden') { $lista = $arbolAVL->postorden; }
    else                              { $lista = $arbolAVL->inorden;   }

    my @resultado = map {{
        numero_colegio => $_->{clave},
        nombre         => $_->{valor}{nombre},
        tipo           => $_->{valor}{tipo},
        departamento   => $_->{valor}{depto},
        especialidad   => $_->{valor}{espec} // '',
    }} @$lista;

    $c->render(json => { ok=>1, usuarios=>\@resultado });
};

# eliminar al usuario que está en el campo de bsucar
del '/usuarios/:colegio' => sub ($c) {
    my $colegio = $c->param('colegio');

    unless (defined $arbolAVL->buscar($colegio)) {
        return $c->render(json => { ok=>0, mensaje=>"Usuario $colegio no encontrado" });
    }

    $arbolAVL->eliminar($colegio);
    $c->render(json => { ok=>1, mensaje=>"$colegio eliminado exitosamente" });
};

app->start;

