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
#IMPORTS DE LA FASE 3
use grafoNoDirigido;
use tablaHash;
use lzw;

my $listaMedicamentos = listaDoblementeEnlazada->new;
my $listaProveedores  = listaCircularDoble->new;
my $listaSolicitudes  = listaCircularDoble->new;
my $matrizDispersaMed = matrizDispersa->new;

#TOCA LLAMAR A LOS ÁRBOLES
my $arbolAVL = arbolAvl->new;
my $arbolBST = arbolBST->new;
my $arbolB   = arbolB->new;

#Estructuras de la fase 3
my $grafo = grafoNoDirigido->new();
my $tablaHash = tablaHash->new();
my $compresorLZW = lzw->new();
my %chats_en_memoria; # Almacena chats activos por usuario: { 'COL-123' => { 'COL-456' => [...] } }



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
    return $c->render(json => {
        ok     => 1,
        rol    => $user eq 'AdminHospital' ? 'admin' : 'medico',
        colegio => $user,
        nombre => $u->{nombre},
        tipo   => $u->{tipo},
        depto  => $u->{depto},
        espec  => $u->{espec} // '',
    });
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

    # Insertar en Grafo
        $grafo->agregar_nodo(
            numero_colegio => $colegio,
            nombre         => $nombre,
            tipo_usuario   => $tipo,
            departamento   => $depto,
            especialidad   => $espec,
        );

        # Insertar en Tabla Hash (solo TIPO-01..04)
        $tablaHash->insertar($colegio, {
            nombre => $nombre,
            tipo   => $tipo,
            depto  => $depto,
            espec  => $espec,
        }) if $tipo =~ /^TIPO-0[1-4]$/;

    return $c->render(json => { ok=>1, mensaje=>"$colegio registrado exitosamente" });
};


#=============================================CONUSLTAR USUARIOS=======================================0
#Eliminada por errores de duplicados con otra ruta
#=============================================CONUSLTAR EQUIPOS=======================================0
#Eliminada por errores de duplicados con otra ruta
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

#===============================CONSULTA DE MEDICAMENTOS ESPECÍFICOS==========================
get '/medicamentos/:codigo' => sub ($c){
    my $codigo_buscar = uc(trim($c->param('codigo')));
    $codigo_buscar = "MED$codigo_buscar" unless $codigo_buscar =~ /^MED/i;

     my $encontrado = undef;
    
    # Recorrer la lista doblemente enlazada para buscar
    $listaMedicamentos->iterar(sub {
        my $nodo = shift;
        my $med  = $nodo->value;
        
        if ($med->codigoMedicina eq $codigo_buscar) {
            $encontrado = $med;
        }
    });

     # Si no se encontró
    unless (defined $encontrado) {
        return $c->render(json => { 
            ok => 0, 
            mensaje => "Medicamento $codigo_buscar no encontrado" 
        });
    }

    # Renderizar respuesta con los nombres de clave que espera tu JavaScript
    $c->render(json => {
        ok                => 1,
        codigo            => $encontrado->codigoMedicina,
        nombre            => $encontrado->nombreComercial,
        principio_activo  => $encontrado->principioActivo // '—',
        fabricante        => $encontrado->laboratorioFabricante // '—',
        cantidad          => $encontrado->cantidadStock // 0,
        minimo            => $encontrado->nivelMinimoReorden // 0,
        vence             => $encontrado->fechaVencimiento // '—',
        precio            => $encontrado->precio // 0,
    });
};

#=============================CARGA MASIVA============================================

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
                #metemos los equipos en la matriz
                $matrizDispersaMed->insertar($pnombre, $fab, $eq);
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
                #metemos los suministros en la matriz
                $matrizDispersaMed->insertar($pnombre, $fab, $sum);
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


#============================================ESTO ES PARA LA PARTE DEL MANEJO DEL PERSONAL=====================================
#============================================================================================================================
# tomar a los usuarios en el recorrido deseado
get '/usuarios' => sub ($c) {
    my $recorrido = $c->param('recorrido') // 'inorden';

    print "$recorrido";

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



get '/debug/avl' => sub ($c) {
    my $raiz = $arbolAVL->raiz;
    return $c->render(json => { raiz => 'vacio' }) unless defined $raiz;
    $c->render(json => {
        raiz    => $raiz->{clave},
        altura  => $raiz->{altura},
        izq     => defined $raiz->{izq} ? $raiz->{izq}{clave} : 'null',
        der     => defined $raiz->{der} ? $raiz->{der}{clave} : 'null',
    });
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

#=========================================FUNCIÓN 7 PARA OBTENER LA MATRIZ DISPERZA=============================
#===============================================================================================================
get '/matriz' => sub ($c) {
    my $data = $matrizDispersaMed->obtenerMatriz();
    $c->render(json => { ok=>1, %$data });
};



#==========================================EDITAR EL PERFIL DEL USUARIO==================================
#==================================================================================================================
# PUT /perfil — editar nombre y contraseña
put '/perfil' => sub ($c) {
    my $d          = decode_json($c->req->body);
    my $colegio    = trim($d->{colegio}      // '');
    my $pass_actual = $d->{pass_actual}      // '';
    my $nuevo_nom  = trim($d->{nuevo_nombre} // '');
    my $nueva_pass = $d->{nueva_pass}        // '';

    my $u = $arbolAVL->buscar($colegio);
    return $c->render(json => { ok=>0, mensaje=>'Usuario no encontrado' })
        unless defined $u;

    return $c->render(json => { ok=>0, mensaje=>'Contraseña actual incorrecta' })
        unless $u->{pass} eq $pass_actual;

    $u->{nombre} = $nuevo_nom  if $nuevo_nom;
    $u->{pass}   = $nueva_pass if $nueva_pass;

    $c->render(json => { ok=>1, mensaje=>'Perfil actualizado exitosamente' });
};

#=========================================REPORTE DEL ARBOL AVL==================================
#================================================================================================
get '/reporte/avl' => sub ($c) {
    # Verificar que graphviz esté instalado
   
    my $raiz = $arbolAVL->raiz;
    unless (defined $raiz) {
        return $c->render(json => { ok=>0, mensaje=>'El árbol AVL está vacío' });
    }

    # Generar contenido .dot
    my @lineas;
    push @lineas, 'digraph AVL {';
    push @lineas, '    rankdir=TB;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=record, fontname="Courier", fontsize=11,';
    push @lineas, '          style=filled, fillcolor="#071520", fontcolor="#00ffe7",';
    push @lineas, '          color="#00ffe7", margin="0.2"];';
    push @lineas, '    edge [color="#00ffe7", fontcolor="#00ffe7", fontname="Courier", fontsize=9];';

    # Recorrer árbol recursivamente
    _dot_nodo_avl($raiz, \@lineas, undef, '');

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);

    # Escribir archivo .dot temporal
    my $dot_file = 'reportes/avl.dot';
    my $png_file = 'reportes/avl.png';

    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    # Generar PNG con graphviz
    system("dot -Tpng $dot_file -o $png_file");


    #========================================================================
    #===================BLOQUE PARA EVITAR ERRORES DE GENERACIÓN DEL ARCHIVO
    my $dot_exe = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $ret    = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
    return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    unless (-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    # Leer PNG y devolver como base64
    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');

    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# Función auxiliar recursiva — genera líneas .dot para cada nodo
sub _dot_nodo_avl {
    my ($nodo, $lineas, $padre, $lado) = @_;
    return unless defined $nodo;

    my $id    = $nodo->{clave};
    my $nom   = $nodo->{valor}{nombre} // '?';
    my $tipo  = $nodo->{valor}{tipo}   // '?';
    my $depto = $nodo->{valor}{depto}  // '?';
    my $alt   = $nodo->{altura}        // 1;
    my $es_hoja = !defined($nodo->{izq}) && !defined($nodo->{der});
    my $es_raiz = !defined($padre);

    # Escapar caracteres especiales para .dot
    $nom   =~ s/"/\\"/g;
    $depto =~ s/"/\\"/g;

    # Estilo según tipo de nodo
    my $estilo;
    if ($es_raiz) {
        # Raíz — borde dorado
        $estilo = 'style=filled, fillcolor="#1a1200", color="#f5e642", penwidth=2';
    } elsif ($es_hoja) {
        # Hoja — borde rosa
        $estilo = 'style=filled, fillcolor="#071520", color="#ff2d78"';
    } else {
        # Normal — borde cian
        $estilo = 'style=filled, fillcolor="#071520", color="#00ffe7"';
    }

    # Definir nodo
    push @$lineas,
        "    \"$id\" [label=\"{$id | $nom | $tipo | $depto | h=$alt}\", $estilo];";

    # Arista desde padre
    if (defined $padre) {
        my $color = $lado eq 'izq' ? '"#ff2d78"' : '"#00ffe7"';
        my $label = $lado eq 'izq' ? 'L'         : 'R';
        push @$lineas, "    \"$padre\" -> \"$id\" [label=\"$label\", color=$color];";
    }

    # Recursión
    _dot_nodo_avl($nodo->{izq}, $lineas, $id, 'izq');
    _dot_nodo_avl($nodo->{der}, $lineas, $id, 'der');
}


#=========================================REPORTE DEL ARBOL BST==================================
#================================================================================================

#posee la misma lógica que el recorrido que hicimos al árbol AVL, solo que este no anda balanceado
get '/reporte/bst' => sub ($c) {
    my $raiz = $arbolBST->raiz;
    unless (defined $raiz) {
        return $c->render(json => { ok=>0, mensaje=>'El árbol BST está vacío' });
    }

    my @lineas;
    push @lineas, 'digraph BST {';
    push @lineas, '    rankdir=TB;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=record, fontname="Courier", fontsize=11,';
    push @lineas, '          style=filled, fillcolor="#071520", fontcolor="#00ffe7",';
    push @lineas, '          color="#00ffe7", margin="0.3"];';
    push @lineas, '    edge [color="#00ffe7", fontcolor="#00ffe7", fontname="Courier", fontsize=9];';

    _dot_nodo_bst($raiz, \@lineas, undef, '');

    push @lineas, '}';

    my $dot_txt  = join("\n", @lineas);
    my $dot_file = 'reportes/bst.dot';
    my $png_file = 'reportes/bst.png';
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';

    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);


    #==================================PROCESO PARA QUE EL ARCHIVO NO MUERA====================
    #=========================================================================================
    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

sub _dot_nodo_bst {
    my ($nodo, $lineas, $padre, $lado) = @_;
    return unless defined $nodo;

    my $id    = $nodo->{clave};
    my $eq    = $nodo->{valor};
    my $nom   = $eq->nombreEquipo        // '?';
    my $fab   = $eq->fabricanteEquipo    // '?';
    my $cant  = $eq->cantidadEquipo      // 0;
    my $nivel = $eq->nivelMinimoReorden  // 0;
    my $alerta = $cant < $nivel ? ' [!]' : '';

    my $es_hoja = !defined($nodo->{izq}) && !defined($nodo->{der});
    my $es_raiz = !defined($padre);

    $nom =~ s/"/\\"/g;
    $fab =~ s/"/\\"/g;

    my $estilo;
    if ($es_raiz) {
        $estilo = 'style=filled, fillcolor="#1a1200", color="#f5e642", penwidth=2';
    } elsif ($es_hoja) {
        $estilo = 'style=filled, fillcolor="#0d0714", color="#ff2d78"';
    } else {
        $estilo = 'style=filled, fillcolor="#071520", color="#00ffe7"';
    }

    push @$lineas,
        "    \"$id\" [label=\"{$id | $nom | $fab | cant: $cant$alerta}\", $estilo];";

    if (defined $padre) {
        my $color = $lado eq 'izq' ? '"#ff2d78"' : '"#00ffe7"';
        my $label = $lado eq 'izq' ? 'IZQ' : 'DER';
        push @$lineas,
            "    \"$padre\" -> \"$id\" [label=\"$label\", color=$color, fontcolor=$color];";
    }

    _dot_nodo_bst($nodo->{izq}, $lineas, $id, 'izq');
    _dot_nodo_bst($nodo->{der}, $lineas, $id, 'der');
}

#===================================================REPORTE ÁRBOL B ===================================================
get '/reporte/arbolb' => sub ($c) {
    

    my $raiz = $arbolB->raiz;
    unless (defined $raiz && $raiz->num_claves > 0) {
        return $c->render(json => { ok=>0, mensaje=>'El Árbol B está vacío' });
    }

    my @lineas;
    push @lineas, 'digraph ArbolB {';
    push @lineas, '    rankdir=TB;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=record, fontname="Courier", fontsize=10,';
    push @lineas, '          style=filled, fontcolor="#00ffe7", margin="0.3"];';
    push @lineas, '    edge [color="#00ffe7", fontname="Courier", fontsize=9];';

    my $contador = 0;
    _dot_nodo_arbolb($raiz, \@lineas, \$contador, undef, undef);

    push @lineas, '}';

    my $dot_txt  = join("\n", @lineas);
    my $dot_file = 'reportes/b.dot';
    my $png_file = 'reportes/b.png';
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';

    open(my $fh, '>', $dot_file) or die "No se pudo crear: $!";
    print $fh $dot_txt;
    close($fh);

    #========================================================================
    my $ret    = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
    return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    unless (-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

sub _dot_nodo_arbolb {
    my ($nodo, $lineas, $cont, $padre_id, $puerto) = @_;
    return unless defined $nodo;

    my $id      = 'n' . $$cont++;
    my $num     = $nodo->num_claves;
    my $max     = 3;  # orden 4 - 1
    my $lleno   = $num == $max;

    # Color según capacidad
    my ($fill, $border);
    if ($lleno) {
        $fill   = '"#1a1500"';   # amarillo oscuro — lleno
        $border = '"#f5e642"';
    } else {
        $fill   = '"#001a0d"';   # verde oscuro — con espacio
        $border = '"#00ff88"';
    }

    # Construir label con puertos
    # Formato: <h0> | clave0 | <h1> | clave1 | <h2> | clave2 | <h3>
    my $label = '';
    for my $i (0 .. $num - 1) {
        my $clave = $nodo->{claves}[$i]{clave};
        $clave =~ s/"/\\"/g;
        $label .= "<h$i> |$clave| ";
    }
    $label .= "<h$num>";

    # Indicador de capacidad
    my $cap = "$num/$max claves";
    $label = "{$label | $cap}";

    push @$lineas,
        "    $id [label=\"$label\", fillcolor=$fill, color=$border, penwidth=2];";

    # Arista desde padre
    if (defined $padre_id) {
        push @$lineas,
            "    ${padre_id}:${puerto} -> ${id} [color=$border];";
    }

    # Recursión para cada hijo
    unless ($nodo->{es_hoja}) {
        for my $i (0 .. $num) {
            _dot_nodo_arbolb(
                $nodo->{hijos}[$i],
                $lineas, $cont,
                $id, "h$i"
            );
        }
    }
}


#===================================================REPORTE DE LA MATRIZ DISPERSA ===================================================
get '/reporte/matriz' => sub ($c) {
    my $data     = $matrizDispersaMed->obtenerMatriz();
    my @filas    = @{ $data->{filas}   };
    my @columnas = @{ $data->{columnas} };
    my @celdas   = @{ $data->{celdas}  };

    unless (@filas && @columnas) {
        return $c->render(json => { ok=>0, mensaje=>'La matriz está vacía' });
    }

    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/matriz.dot';
    my $png_file = 'reportes/matriz.png';

    # Construir mapa rápido celda[fila][columna] = cantidad
    my %mapa;
    for my $celda (@celdas) {
        $mapa{ $celda->{fila} }{ $celda->{columna} } += $celda->{cantidad};
    }

    my @lineas;
    push @lineas, 'digraph Matriz {';
    push @lineas, '    rankdir=LR;';   # izquierda a derecha
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [fontname="Courier", fontsize=11, style=filled, margin="0.2"];';
    push @lineas, '    edge [fontname="Courier", fontsize=9];';
    push @lineas, '    splines=false;';  # líneas rectas

    # ── Cabeceras de columna (fabricantes) — arriba, color amarillo
    push @lineas, '    // Fabricantes';
    push @lineas, '    { rank=min;';
    for my $col (@columnas) {
        my $id  = _id_seguro($col);
        my $esc = $col; $esc =~ s/"/\\"/g;
        push @lineas,
            "        fab_$id [label=\"$esc\", shape=rectangle,".
            ' fillcolor="#1a1500", color="#f5e642", fontcolor="#f5e642"];';
    }
    push @lineas, '    }';

    # ── Cabeceras de fila (proveedores) — izquierda, color cyan
    push @lineas, '    // Proveedores';
    for my $fila (@filas) {
        my $id  = _id_seguro($fila);
        my $esc = $fila; $esc =~ s/"/\\"/g;
        push @lineas,
            "    prov_$id [label=\"$esc\", shape=rectangle,".
            ' fillcolor="#071520", color="#00ffe7", fontcolor="#00ffe7"];';
    }

    # ── Nodos de valor (celdas) — círculos, color verde
    push @lineas, '    // Celdas';
    for my $fila (@filas) {
        for my $col (@columnas) {
            next unless exists $mapa{$fila}{$col};
            my $cant   = $mapa{$fila}{$col};
            my $id_f   = _id_seguro($fila);
            my $id_c   = _id_seguro($col);
            push @lineas,
                "    val_${id_f}_${id_c} [label=\"$cant\", shape=circle,".
                ' fillcolor="#001a0d", color="#00ff88", fontcolor="#00ff88", width=0.8];';
        }
    }

    # ── Conexiones horizontales: proveedor → sus celdas
    push @lineas, '    // Conexiones horizontales (proveedor -> cantidad)';
    for my $fila (@filas) {
        my $id_f = _id_seguro($fila);
        for my $col (@columnas) {
            next unless exists $mapa{$fila}{$col};
            my $id_c = _id_seguro($col);
            push @lineas,
                "    prov_$id_f -> val_${id_f}_${id_c}".
                ' [color="#00ffe7", style=solid];';
        }
    }

    # ── Conexiones verticales: fabricante → sus celdas
    push @lineas, '    // Conexiones verticales (fabricante -> cantidad)';
    for my $col (@columnas) {
        my $id_c = _id_seguro($col);
        for my $fila (@filas) {
            next unless exists $mapa{$fila}{$col};
            my $id_f = _id_seguro($fila);
            push @lineas,
                "    fab_$id_c -> val_${id_f}_${id_c}".
                ' [color="#f5e642", style=dashed];';
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);

    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# Convierte un string a identificador seguro para .dot
sub _id_seguro {
    my $s = shift;
    $s =~ s/[^a-zA-Z0-9]/_/g;
    return $s;
}


# ================================================= REPORTE LISTA DOBLEMENTE ENLAZADA (Medicamentos) =================================================
get '/reporte/medicamentos' => sub ($c) {
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/medicamentos.dot';
    my $png_file = 'reportes/medicamentos.png';

    my @lineas;
    push @lineas, 'digraph ListaMedicamentos {';
    push @lineas, '    rankdir=LR;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=box, fontname="Courier", fontsize=10,';
    push @lineas, '          style=filled, fontcolor="#000000", margin="0.3"];';
    push @lineas, '    edge [fontname="Courier", fontsize=9];';

    my @nodos;  # guardar códigos para hacer las aristas después

    $listaMedicamentos->iterar(sub {
        my $nodo = shift;
        my $med  = $nodo->value;

        my $codigo = $med->codigoMedicina;
        my $nombre = $med->nombreComercial    // '?';
        my $vence  = $med->fechaVencimiento   // '?';
        my $cant   = $med->cantidadStock      // 0;
        my $nivel  = $med->nivelMinimoReorden // 0;

        $nombre =~ s/"/\\"/g;

        # Color según estado
        my $color = '#00ff88';  # verde — ok
        if ($cant < $nivel) {
            $color = '#ff2d78';  # rosa — stock bajo
        }

        # Verificar vencimiento
        eval {
            use Time::Piece;
            my $fv  = Time::Piece->strptime($vence, "%Y-%m-%d");
            my $hoy = localtime;
            if ($fv < $hoy) {
                $color = '#f5e642';  # amarillo — vencido
            } elsif ($fv <= $hoy + 86400*7) {
                $color = '#f5e642';  # amarillo — próximo a vencer
            }
        };

        push @lineas,
            "    \"$codigo\" [label=\"$codigo\\n$nombre\\nStock: $cant\\nVence: $vence\",".
            " fillcolor=\"$color\"];";

        push @nodos, { nodo => $nodo, codigo => $codigo, med => $med };
    });

    # Aristas
    for my $entry (@nodos) {
        my $nodo   = $entry->{nodo};
        my $codigo = $entry->{codigo};

        # Siguiente — cian
        if ($nodo->next) {
            my $sig = $nodo->next->value->codigoMedicina;
            push @lineas, "    \"$codigo\" -> \"$sig\" [color=\"#00ffe7\", label=\"sig\"];";
        }
        # Anterior — rosa
        if ($nodo->prev) {
            my $ant = $nodo->prev->value->codigoMedicina;
            push @lineas, "    \"$codigo\" -> \"$ant\" [color=\"#ff2d78\", label=\"ant\", style=dashed];";
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);

    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# ================================================= REPORTE LISTA CIRCULAR DOBLE (Proveedores) =================================================
get '/reporte/proveedores' => sub ($c) {


    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/proveedores.dot';
    my $png_file = 'reportes/proveedores.png';

    my @lineas;
    push @lineas, 'digraph ListaProveedores {';
    push @lineas, '    rankdir=LR;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=box, fontname="Courier", fontsize=10,';
    push @lineas, '          style=filled, fontcolor="#000000", margin="0.3"];';
    push @lineas, '    edge [fontname="Courier", fontsize=9];';

    my @nodos;
    my $orden = 0;
    

    $listaProveedores->recorrerAdelante(sub {
        my $nodo = shift;
        my $prov = $nodo->valor;
        $orden++;

        my $nit    = $prov->nit           // '?';
        my $nombre = $prov->nombreEmpresa // '?';
        my $tel    = $prov->telefono      // '?';
        my $total  = $prov->totalEntregas // 0;

        $nombre =~ s/"/\\"/g;

        # Primer nodo en amarillo — cabeza de la lista
        my $color = $orden == 1 ? '#f5e642' : '#00ffe7';

        push @lineas,
            "    \"$nit\" [label=\"$nit\\n$nombre\\nTel: $tel\\nEntregas: $total\",".
            " fillcolor=\"$color\"];";

        push @nodos, { nodo => $nodo, nit => $nit };
    });

    # Aristas
    for my $entry (@nodos) {
        my $nodo = $entry->{nodo};
        my $nit  = $entry->{nit};

        # Siguiente — cian
        if ($nodo->siguiente) {
            my $sig = $nodo->siguiente->valor->nit;
            push @lineas, "    \"$nit\" -> \"$sig\" [color=\"#00ffe7\", label=\"sig\"];";
        }
        # Anterior — rosa
        if ($nodo->anterior) {
            my $ant = $nodo->anterior->valor->nit;
            push @lineas, "    \"$nit\" -> \"$ant\" [color=\"#ff2d78\", label=\"ant\", style=dashed];";
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);

    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");

    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# ═══════════════════════════════════════════════════════════════════
# FASE 3 — RUTAS NUEVAS
# Grafo No Dirigido, Tabla Hash, LZW Mensajería
# ═══════════════════════════════════════════════════════════════════


post '/carga-usuarios' => sub ($c) {
    my $upload = $c->req->upload('json');

    unless ($upload && $upload->filename =~ /\.json$/i) {
        return $c->render(json => { ok=>0, mensaje=>'El archivo debe ser .json' });
    }

    my $data;
    eval { $data = decode_json($upload->slurp); };
    if ($@) {
        return $c->render(json => { ok=>0, mensaje=>'JSON malformado: ' . $@ });
    }

    unless (ref($data->{usuarios}) eq 'ARRAY') {
        return $c->render(json => { ok=>0, mensaje=>'El JSON debe tener la clave "usuarios" como array' });
    }

    my ($insertados, $duplicados, $pendientes) = (0, 0, 0);
    my @errores;

    for my $u (@{ $data->{usuarios} }) {
        my $col   = trim($u->{numero_colegio}  // '');
        my $nom   = trim($u->{nombre_completo} // '');
        my $tipo  = trim($u->{tipo_usuario}    // '');
        my $depto = trim($u->{departamento}    // '');
        my $espec = trim($u->{especialidad}    // '');
        my $pass  = $u->{contrasena}           // '';

        unless ($col && $nom && $tipo && $pass) {
            push @errores, "$col: campos incompletos, omitido";
            next;
        }
        unless ($tipo =~ /^TIPO-0[1-4]$/) {
            push @errores, "$col: tipo '$tipo' no reconocido, omitido";
            next;
        }
        if (defined $arbolAVL->buscar($col)) {
            push @errores, "$col ya registrado, omitido";
            $duplicados++;
            next;
        }

        # Departamento puede ser null/vacío → SIN-DEP
        my $depto_real = ($depto && $depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$/)
                         ? $depto : 'SIN-DEP';

        $arbolAVL->insertar($col, {
            nombre => $nom,
            tipo   => $tipo,
            depto  => $depto_real,
            espec  => $espec,
            pass   => $pass,
        });

        # Insertar en Grafo
        $grafo->agregar_nodo(
            numero_colegio => $col,
            nombre         => $nom,
            tipo_usuario   => $tipo,
            departamento   => $depto_real,
            especialidad   => $espec,
        );

        # Insertar en Tabla Hash (solo TIPO-01..04)
        $tablaHash->insertar($col, {
            nombre => $nom,
            tipo   => $tipo,
            depto  => $depto_real,
            espec  => $espec,
        }) if $tipo =~ /^TIPO-0[1-4]$/;

        $pendientes++ if $depto_real eq 'SIN-DEP';
        $insertados++;
    }

    return $c->render(json => {
        ok         => 1,
        insertados => $insertados,
        duplicados => $duplicados,
        pendientes => $pendientes,
        errores    => \@errores,
    });
};

# ══════════════════════════════════════════════════════
# CARGA MASIVA DE RELACIONES (Grafo)
# ══════════════════════════════════════════════════════
post '/carga-relaciones' => sub ($c) {
    my $upload = $c->req->upload('json');
    unless ($upload && $upload->filename =~ /\.json$/i) {
        return $c->render(json => { ok=>0, mensaje=>'El archivo debe ser .json' });
    }

    my $data;
    eval { $data = decode_json($upload->slurp); };
    if ($@) {
        return $c->render(json => { ok=>0, mensaje=>'JSON malformado: ' . $@ });
    }

    unless (ref($data) eq 'ARRAY') {
        return $c->render(json => { ok=>0, mensaje=>'El JSON debe ser un array de relaciones' });
    }

    my ($activas, $pendientes_rel, $rechazadas) = (0, 0, 0);
    my @errores;

    for my $rel (@$data) {
        my $sol    = trim($rel->{solicitante} // '');
        my $rec    = trim($rel->{receptor}    // '');
        my $estado = uc(trim($rel->{estado}   // ''));

        unless ($sol && $rec) {
            push @errores, "Relación sin solicitante o receptor, omitida";
            next;
        }

        if ($estado eq 'ACTIVA') {
            $grafo->agregar_arista($sol, $rec);
            $activas++;
        } elsif ($estado eq 'PENDIENTE') {
            $grafo->agregar_solicitud($sol, $rec);
            $pendientes_rel++;
        } elsif ($estado eq 'RECHAZADA') {
            $rechazadas++;
        } else {
            push @errores, "Estado '$estado' no reconocido para $sol→$rec";
        }
    }

    return $c->render(json => {
        ok               => 1,
        aristas_agregadas => $activas,
        pendientes       => $pendientes_rel,
        rechazadas       => $rechazadas,
        errores          => \@errores,
    });
};

# ══════════════════════════════════════════════════════
# GRAFO — Endpoints
# ══════════════════════════════════════════════════════

# Lista de todos los nodos del grafo
get '/grafo/nodos' => sub ($c) {
    $c->render(json => { ok=>1, nodos => $grafo->todos_nodos() });
};

# Colaboradores directos de un usuario
get '/grafo/colaboradores/:colegio' => sub ($c) {
    my $col = $c->param('colegio');
    $c->render(json => { ok=>1, colaboradores => $grafo->colaboradores($col) });
};

# Sugerencias BFS 2 saltos
get '/grafo/sugerencias/:colegio' => sub ($c) {
    my $col = $c->param('colegio');
    $c->render(json => { ok=>1, sugerencias => $grafo->sugerencias($col) });
};

# Lista de adyacencia completa
get '/grafo/adyacencia' => sub ($c) {
    $c->render(json => { ok=>1, adyacencia => $grafo->lista_adyacencia() });
};

# Solicitudes recibidas de un usuario
get '/grafo/solicitudes/:colegio' => sub ($c) {
    my $col = $c->param('colegio');
    $c->render(json => { ok=>1, solicitudes => $grafo->solicitudes_recibidas($col) });
};

# Enviar solicitud de colaboración
post '/grafo/solicitud' => sub ($c) {
    my $d    = decode_json($c->req->body);
    my $sol  = trim($d->{solicitante} // '');
    my $rec  = trim($d->{receptor}    // '');

    return $c->render(json => { ok=>0, mensaje=>'Datos incompletos' })
        unless $sol && $rec;
    return $c->render(json => { ok=>0, mensaje=>'No puedes enviarte una solicitud a ti mismo' })
        if $sol eq $rec;
    return $c->render(json => { ok=>0, mensaje=>'Ya son colaboradores' })
        if $grafo->existe_arista($sol, $rec);

    $grafo->agregar_solicitud($sol, $rec);
    $c->render(json => { ok=>1, mensaje=>"Solicitud enviada a $rec" });
};

# Aceptar solicitud
post '/grafo/aceptar' => sub ($c) {
    my $d   = decode_json($c->req->body);
    my $sol = trim($d->{solicitante} // '');
    my $rec = trim($d->{receptor}    // '');

    my $r = $grafo->aceptar_solicitud($sol, $rec);
    $c->render(json => { ok=>$r, mensaje=> $r ? "Colaboración aceptada" : "Solicitud no encontrada" });
};

# Rechazar solicitud
post '/grafo/rechazar' => sub ($c) {
    my $d   = decode_json($c->req->body);
    my $sol = trim($d->{solicitante} // '');
    my $rec = trim($d->{receptor}    // '');

    my $r = $grafo->rechazar_solicitud($sol, $rec);
    $c->render(json => { ok=>$r, mensaje=> $r ? "Solicitud rechazada" : "Solicitud no encontrada" });
};



# Asignar departamento a un usuario (activa acceso)
put '/usuarios/:colegio/asignar-depto' => sub ($c) {
    my $col   = $c->param('colegio');
    my $d     = decode_json($c->req->body);
    my $depto = trim($d->{departamento} // '');

    return $c->render(json => { ok=>0, mensaje=>'Departamento inválido' })
        unless $depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$/;

    my $u = $arbolAVL->buscar($col);
    return $c->render(json => { ok=>0, mensaje=>"Usuario $col no encontrado" })
        unless defined $u;

    $u->{depto} = $depto;
    $grafo->actualizar_depto($col, $depto);

    $c->render(json => { ok=>1, mensaje=>"Departamento asignado: $depto a $col" });
};

# ══════════════════════════════════════════════════════
# TABLA HASH — Directorio por Tipo
# ══════════════════════════════════════════════════════
get '/directorio/:tipo' => sub ($c) {
    my $tipo = uc($c->param('tipo'));
    return $c->render(json => { ok=>0, mensaje=>'Tipo inválido (TIPO-01 a TIPO-04)' })
        unless $tipo =~ /^TIPO-0[1-4]$/;

    my $lista = $tablaHash->por_tipo($tipo);
    $c->render(json => { ok=>1, tipo=>$tipo, usuarios=>$lista, total=>scalar(@$lista) });
};

# Estado completo de la tabla hash (para reporte)
get '/directorio/estado' => sub ($c) {
    $c->render(json => { ok=>1, estado => $tablaHash->estado_tabla() });
};

# ══════════════════════════════════════════════════════
# MENSAJERÍA — Chats con LZW
# ══════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════

# Enviar mensaje entre colaboradores
post '/chat/mensaje' => sub ($c) {
    my $d    = decode_json($c->req->body);
    my $de   = trim($d->{de}      // '');
    my $para = trim($d->{para}    // '');
    my $msg  = $d->{mensaje}      // '';

    return $c->render(json => { ok=>0, mensaje=>'Datos incompletos' })
        unless $de && $para && $msg;

    unless ($grafo->existe_arista($de, $para)) {
        return $c->render(json => { ok=>0, mensaje=>'Solo puedes enviar mensajes a colaboradores directos' });
    }

    my @t  = localtime;
    my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);

    my $entrada = { de=>$de, ts=>$ts, msg=>$msg };

    # Solo guardamos en la entrada del REMITENTE.
    # El receptor cargará el historial desde el archivo del remitente
    # cuando lo necesite (ver /chat/historial).
    $chats_en_memoria{$de}{$para} //= [];
    push @{ $chats_en_memoria{$de}{$para} }, $entrada;

    $c->render(json => { ok=>1, ts=>$ts });
};

# Obtener historial de una conversación entre $de y $para.
# Combina los mensajes propios de $de + los mensajes que $para
# tiene guardados hacia $de, los ordena por timestamp, y devuelve
# la lista unificada (sin duplicados).
get '/chat/historial/:de/:para' => sub ($c) {
    my $de   = $c->param('de');
    my $para = $c->param('para');

    # Asegurar que los chats del usuario activo estén en memoria
    _asegurar_en_memoria($de);

    # Mensajes donde $de es remitente
    my @propios = @{ $chats_en_memoria{$de}{$para} // [] };

    # Mensajes donde $para es remitente (leídos desde su archivo si no están en memoria)
    _asegurar_en_memoria($para);
    my @del_otro = @{ $chats_en_memoria{$para}{$de} // [] };

    # Unir y ordenar por timestamp (sin duplicar: cada mensaje tiene un dueño único)
    my @todos = sort { $a->{ts} cmp $b->{ts} } (@propios, @del_otro);

    $c->render(json => { ok=>1, mensajes=>\@todos });
};

# Función auxiliar: carga el archivo .lzw de un usuario en memoria
# SOLO si todavía no ha sido cargado en esta sesión del servidor.
# Usa REEMPLAZO (no push) para evitar duplicados.
sub _asegurar_en_memoria {
    my ($colegio) = @_;
    # Si ya está marcado como cargado, no hacer nada
    return if exists $chats_en_memoria{"__cargado_$colegio"};

    my $chats_cargados = $compresorLZW->cargar_chats($colegio, 'chats');

    # REEMPLAZAR (no acumular) para evitar duplicados entre sesiones
    for my $interlocutor (keys %$chats_cargados) {
        $chats_en_memoria{$colegio}{$interlocutor} = $chats_cargados->{$interlocutor};
    }

    # Marcar como cargado para esta sesión del servidor
    $chats_en_memoria{"__cargado_$colegio"} = 1;
}

# Cerrar sesión: serializar y comprimir los chats del usuario con LZW.
# Guarda solo los mensajes PROPIOS del usuario (de los que es remitente).
post '/chat/cerrar-sesion' => sub ($c) {
    my $d   = decode_json($c->req->body);
    my $col = trim($d->{colegio} // '');

    return $c->render(json => { ok=>0, mensaje=>'Usuario no válido' }) unless $col;

    # Construir el hash de chats propios (solo donde $col es remitente)
    my %chats_propios;
    for my $interlocutor (keys %{ $chats_en_memoria{$col} // {} }) {
        next if $interlocutor =~ /^__cargado_/; # ignorar marcas internas
        $chats_propios{$interlocutor} = $chats_en_memoria{$col}{$interlocutor};
    }

    eval {
        $compresorLZW->guardar_chats($col, \%chats_propios, 'chats');
    };

    if ($@) {
        warn "Error al guardar chats de $col: $@";
        return $c->render(json => { ok=>0, mensaje=>"Error al guardar chats: $@" });
    }

    # Limpiar de memoria (incluida la marca de cargado)
    delete $chats_en_memoria{$col};
    delete $chats_en_memoria{"__cargado_$col"};

    $c->render(json => { ok=>1, mensaje=>'Chats guardados y sesión cerrada' });
};

# Iniciar sesión: cargar chats del usuario desde su archivo .lzw.
post '/chat/iniciar-sesion' => sub ($c) {
    my $d   = decode_json($c->req->body);
    my $col = trim($d->{colegio} // '');

    return $c->render(json => { ok=>0, mensaje=>'Usuario no válido' }) unless $col;

    # Forzar recarga limpia: borrar marca de cargado si existía
    delete $chats_en_memoria{"__cargado_$col"};
    delete $chats_en_memoria{$col};

    _asegurar_en_memoria($col);

    my $total = scalar grep { !/^__/ } keys %{ $chats_en_memoria{$col} // {} };
    $c->render(json => { ok=>1, cargados=>$total });
};

get '/reporte/lzw' => sub ($c) {
    my $archivos = $compresorLZW->listar_archivos('chats');
    $c->render(json => { ok=>1, archivos=>$archivos, total=>scalar(@$archivos) });
};

# ══════════════════════════════════════════════════════
# SOLICITUDES DE REABASTECIMIENTO (Lista Circular Doble)
# ══════════════════════════════════════════════════════

# POST: Crear nueva solicitud (Usuario)
post '/solicitudes' => sub ($c) {
    my $d    = decode_json($c->req->body);
    my $dep  = trim($d->{departamento}  // '');
    my $tipo = trim($d->{tipo_insumo}   // '');
    my $cod  = trim($d->{codigo}        // '');
    my $cant = $d->{cantidad}           // 0;
    my $mot  = trim($d->{motivo}        // '');
    my $sol  = trim($d->{solicitante}   // '');

    # Validaciones estrictas
    return $c->render(json => { ok=>0, mensaje=>'Campos obligatorios: departamento, tipo, código y cantidad > 0' })
        unless $dep && $tipo && $cod && $cant > 0;

    # Generar timestamp
    my @t = localtime;
    my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);

    # Crear objeto solicitud
    my $sol_obj = solicitudReabastecimiento->new(
        departamento => $dep,
        tipoInsumo   => $tipo,
        codigo       => $cod,
        cantidad     => $cant,
        motivo       => $mot,
        solicitante  => $sol,
        fecha        => $ts,
        estado       => 'PENDIENTE',
    );

    # Insertar en lista circular (cola FIFO)
    $listaSolicitudes->insertar($sol_obj);
    
    $c->render(json => { 
        ok => 1, 
        mensaje => 'Solicitud registrada exitosamente', 
        fecha => $ts,
        id_solicitud => $sol_obj->get_codigo() . '_' . $ts  # ID único temporal
    });
};

# GET: Obtener todas las solicitudes pendientes (Admin)
get '/solicitudes' => sub ($c) {
    return $c->render(json => { ok=>0, mensaje=>'No hay solicitudes' })
        if $listaSolicitudes->esta_vacia();
        
    my @lista;
    $listaSolicitudes->recorrerAdelante(sub {
        my $nodo = shift;
        my $s    = $nodo->valor;  # Objeto solicitudReabastecimiento
        
        push @lista, {
            departamento => $s->get_departamento() // '',
            tipo_insumo  => $s->get_tipoInsumo()   // '',
            codigo       => $s->get_codigo()       // '',
            cantidad     => $s->get_cantidad()     // 0,
            motivo       => $s->get_motivo()       // '',
            solicitante  => $s->get_solicitante()  // '',
            fecha        => $s->get_fecha()        // '',
            estado       => $s->get_estado()       // 'PENDIENTE',
        };
    });
    
    $c->render(json => { 
        ok => 1, 
        total => scalar(@lista),  # ✅ Sin referencia innecesaria
        solicitudes => \@lista 
    });
};

# POST: Aprobar primera solicitud de la cola (Admin)
post '/solicitudes/aprobar' => sub ($c) {
    return $c->render(json => { ok=>0, mensaje=>'No hay solicitudes pendientes' })
        if $listaSolicitudes->esta_vacia();

    # Obtener primera solicitud (FIFO)
    my $primera = $listaSolicitudes->{head}->valor;
    
    # Extraer datos con getters
    my $tipo = uc($primera->get_tipoInsumo() // '');
    my $cod  = $primera->get_codigo() // '';
    my $cant = $primera->get_cantidad() // 0;
    my $depto_sol = $primera->get_departamento() // '';

    # Verificar stock según tipo de insumo
    my $stock_ok = 0;
    
    if ($tipo eq 'MEDICAMENTO') {
        $listaMedicamentos->iterar(sub {
            my $nodo = shift;
            my $med  = $nodo->value;
            if ($med->codigoMedicina eq $cod && $med->cantidadStock >= $cant) {
                $med->{cantidadStock} -= $cant;  # Descontar stock
                $stock_ok = 1;
            }
        });
        return $c->render(json => { ok=>0, mensaje=>"Medicamento $cod no encontrado o stock insuficiente" })
            unless $stock_ok;

    } elsif ($tipo eq 'EQUIPO') {
        my $eq = $arbolBST->buscar($cod);
        return $c->render(json => { ok=>0, mensaje=>"Equipo $cod no encontrado" }) unless $eq;
        return $c->render(json => { ok=>0, mensaje=>"Stock insuficiente para $cod" })
            if $eq->cantidadEquipo < $cant;
        $eq->{cantidadEquipo} -= $cant;
        $stock_ok = 1;

    } elsif ($tipo eq 'SUMINISTRO') {
        my $sum = $arbolB->buscar($cod);
        return $c->render(json => { ok=>0, mensaje=>"Suministro $cod no encontrado" }) unless $sum;
        return $c->render(json => { ok=>0, mensaje=>"Stock insuficiente para $cod" })
            if $sum->cantidadSuministro < $cant;
        $sum->{cantidadSuministro} -= $cant;
        $stock_ok = 1;
    } else {
        return $c->render(json => { ok=>0, mensaje=>"Tipo de insumo '$tipo' no reconocido" });
    }

    # Actualizar estado de la solicitud a APROBADA (buena práctica)
    $primera->set_estado('APROBADA') if $primera->can('set_estado');
    
    # Eliminar de la cola
    $listaSolicitudes->eliminarPrimero();

    $c->render(json => { 
        ok => 1, 
        mensaje => "Solicitud aprobada: $cant unidades de $cod descontadas del inventario",
        departamento => $depto_sol
    });
};

# POST: Rechazar primera solicitud de la cola (Admin)
post '/solicitudes/rechazar' => sub ($c) {
    return $c->render(json => { ok=>0, mensaje=>'No hay solicitudes pendientes' })
        if $listaSolicitudes->esta_vacia();

    # Obtener referencia para logging (opcional)
    my $rechazada = $listaSolicitudes->{head}->valor;
    my $cod = $rechazada->get_codigo();
    
    # Actualizar estado antes de eliminar (auditoría)
    $rechazada->set_estado('RECHAZADA') if $rechazada->can('set_estado');
    
    # Eliminar de la cola
    $listaSolicitudes->eliminarPrimero();
    
    $c->render(json => { 
        ok => 1, 
        mensaje => "Solicitud de $cod rechazada y eliminada de la cola",
        codigo => $cod
    });
};

# ══════════════════════════════════════════════════════
# REGISTRO INDIVIDUAL CON GRAFO + HASH (override)
# ══════════════════════════════════════════════════════
post '/registro-f3' => sub ($c) {
    my $d       = decode_json($c->req->body);
    my $colegio = trim($d->{numero_colegio} // '');
    my $nombre  = trim($d->{nombre}         // '');
    my $tipo    = trim($d->{tipo_usuario}   // '');
    my $depto   = trim($d->{departamento}   // '');
    my $espec   = trim($d->{especialidad}   // '');
    my $pass    = $d->{contrasena}          // '';

    return $c->render(json => { ok=>0, mensaje=>'Complete todos los campos obligatorios' })
        unless $colegio && $nombre && $tipo && $pass;

    return $c->render(json => { ok=>0, mensaje=>"Tipo '$tipo' no reconocido" })
        unless $tipo =~ /^TIPO-0[1-4]$/;

    return $c->render(json => { ok=>0, mensaje=>"$colegio ya está registrado" })
        if defined $arbolAVL->buscar($colegio);

    my $depto_real = ($depto && $depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$/)
                     ? $depto : 'SIN-DEP';

    $arbolAVL->insertar($colegio, {
        nombre => $nombre, tipo => $tipo,
        depto  => $depto_real, espec => $espec, pass => $pass,
    });

    $grafo->agregar_nodo(
        numero_colegio => $colegio, nombre => $nombre,
        tipo_usuario   => $tipo,   departamento => $depto_real,
        especialidad   => $espec,
    );

    $tablaHash->insertar($colegio, {
        nombre => $nombre, tipo => $tipo,
        depto  => $depto_real, espec => $espec,
    });

    $c->render(json => { ok=>1, mensaje=>"$colegio registrado exitosamente" });
};

# ══════════════════════════════════════════════════════
# REPORTES FASE 3
# ══════════════════════════════════════════════════════

# ── Reporte Grafo No Dirigido ─────────────────────────
get '/reporte/grafo' => sub ($c) {
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/grafo.dot';
    my $png_file = 'reportes/grafo.png';

    my @nodos = @{ $grafo->todos_nodos() };
    unless (@nodos) {
        return $c->render(json => { ok=>0, mensaje=>'El grafo está vacío' });
    }

    # Colores por departamento
    my %color_depto = (
        'DEP-ADM' => '#f5e642',
        'DEP-MED' => '#00ffe7',
        'DEP-CIR' => '#ff2d78',
        'DEP-LAB' => '#00ff88',
        'DEP-FAR' => '#c77dff',
        'SIN-DEP' => '#888888',
    );

    my @lineas;
    push @lineas, 'graph RedColaboracion {';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [shape=ellipse, fontname="Courier", fontsize=9,';
    push @lineas, '          style=filled, fontcolor="#000000", margin="0.15"];';
    push @lineas, '    edge [color="#00ffe7", fontname="Courier", fontsize=8];';
    push @lineas, '    overlap=false; splines=true;';

    # Nodos
    for my $n (@nodos) {
        my $col   = $n->{numero_colegio} // '';
        my $nom   = $n->{nombre}         // '';
        my $depto = $n->{depto}          // 'SIN-DEP';
        my $tipo  = $n->{tipo}           // '';

        my $color = $color_depto{$depto} // '#888888';
        (my $id = $col) =~ s/[^a-zA-Z0-9]/_/g;
        $nom =~ s/"/\\"/g;

        push @lineas,
            "    $id [label=\"$col\\n$nom\\n$depto\\n$tipo\",".
            " fillcolor=\"$color\"];";
    }

    # Aristas (solo una vez por par)
    my %vistas;
    my $adyacencia = $grafo->lista_adyacencia();
    for my $nodo (@$adyacencia) {
        my $col_a = $nodo->{nodo};
        (my $id_a = $col_a) =~ s/[^a-zA-Z0-9]/_/g;
        for my $col_b (@{ $nodo->{vecinos} }) {
            my $par = join('--', sort($col_a, $col_b));
            next if $vistas{$par}++;
            (my $id_b = $col_b) =~ s/[^a-zA-Z0-9]/_/g;
            push @lineas, "    $id_a -- $id_b;";
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);
    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");
    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# ── Reporte Lista de Adyacencia ───────────────────────
get '/reporte/adyacencia' => sub ($c) {
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/adyacencia.dot';
    my $png_file = 'reportes/adyacencia.png';

    my $adyacencia = $grafo->lista_adyacencia();
    unless (@$adyacencia) {
        return $c->render(json => { ok=>0, mensaje=>'El grafo está vacío' });
    }

    my @lineas;
    push @lineas, 'digraph ListaAdyacencia {';
    push @lineas, '    rankdir=LR;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [fontname="Courier", fontsize=9, style=filled, margin="0.1"];';
    push @lineas, '    edge [color="#00ffe7", fontname="Courier", fontsize=8];';

    for my $nodo (@$adyacencia) {
        my $col  = $nodo->{nodo};
        my $nom  = $nodo->{nombre} // '';
        my $dep  = $nodo->{depto}  // '';
        $nom =~ s/"/\\"/g;
        (my $id = $col) =~ s/[^a-zA-Z0-9]/_/g;

        push @lineas,
            "    head_$id [label=\"$col\\n$nom\",".
            ' shape=record, fillcolor="#071520", color="#00ffe7", fontcolor="#00ffe7"];';

        my @vecinos = @{ $nodo->{vecinos} };
        for my $i (0 .. $#vecinos) {
            my $vec = $vecinos[$i];
            (my $id_v = $vec) =~ s/[^a-zA-Z0-9]/_/g;
            my $es_ultimo = $i == $#vecinos;

            push @lineas,
                "    slot_${id}_${id_v} [label=\"$vec\",".
                " shape=box, fillcolor=\"#0a1f30\", color=\"#00ff88\", fontcolor=\"#00ff88\"];";
            if ($i == 0) {
                push @lineas, "    head_$id -> slot_${id}_${id_v};";
            } else {
                my $prev = $vecinos[$i-1];
                (my $id_prev = $prev) =~ s/[^a-zA-Z0-9]/_/g;
                push @lineas, "    slot_${id}_${id_prev} -> slot_${id}_${id_v};";
            }
        }
        unless (@vecinos) {
            push @lineas,
                "    null_$id [label=\"NULL\", shape=plaintext, fontcolor=\"#444444\"];";
            push @lineas, "    head_$id -> null_$id;";
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);
    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");
    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};

# ── Reporte Tabla Hash ────────────────────────────────
get '/reporte/tablahash' => sub ($c) {
    my $dot_exe  = 'C:/Program Files/Graphviz/bin/dot.exe';
    my $dot_file = 'reportes/tablahash.dot';
    my $png_file = 'reportes/tablahash.png';

    my $estado = $tablaHash->estado_tabla();

    my @lineas;
    push @lineas, 'digraph TablaHash {';
    push @lineas, '    rankdir=LR;';
    push @lineas, '    bgcolor="#040d14";';
    push @lineas, '    node [fontname="Courier", fontsize=9, style=filled, margin="0.1"];';
    push @lineas, '    edge [color="#f5e642"];';

    for my $bucket (@$estado) {
        my $tipo  = $bucket->{tipo};
        my $total = $bucket->{total};
        my $col   = $bucket->{colisiones};
        (my $id   = $tipo) =~ s/-/_/g;

        push @lineas,
            "    tipo_$id [label=\"$tipo\\ntotal=$total\\ncol=$col\",".
            ' shape=record, fillcolor="#1a1200", color="#f5e642", fontcolor="#f5e642"];';

        for my $slot (@{ $bucket->{slots} }) {
            my $si     = $slot->{slot};
            my $claves = join(', ', @{ $slot->{claves} });
            my $fill   = @{ $slot->{claves} } ? '"#001a0d"' : '"#071520"';
            my $bcolor = @{ $slot->{claves} } ? '"#00ff88"' : '"#3a6070"';
            my $fcolor = @{ $slot->{claves} } ? '"#00ff88"' : '"#3a6070"';
            my $label  = $claves ? "[$si]\\n$claves" : "[$si] vacío";

            push @lineas,
                "    slot_${id}_$si [label=\"$label\", shape=box,".
                " fillcolor=$fill, color=$bcolor, fontcolor=$fcolor];";
            push @lineas, "    tipo_$id -> slot_${id}_$si;";
        }
    }

    push @lineas, '}';

    my $dot_txt = join("\n", @lineas);
    open(my $fh, '>', $dot_file) or die "No se pudo crear $dot_file: $!";
    print $fh $dot_txt;
    close($fh);

    my $ret = system("\"$dot_exe\" -Tpng $dot_file -o $png_file");
    if ($ret != 0 || !-f $png_file) {
        return $c->render(json => { ok=>0, mensaje=>'Error al generar imagen con Graphviz' });
    }

    open(my $img, '<:raw', $png_file) or die "No se pudo leer $png_file: $!";
    my $img_data = do { local $/; <$img> };
    close($img);

    use MIME::Base64;
    my $b64 = encode_base64($img_data, '');
    $c->render(json => { ok=>1, imagen=>"data:image/png;base64,$b64" });
};



# ══════════════════════════════════════════════════════
# REASIGNAR DEPARTAMENTO (Admin -> AVL)
# ══════════════════════════════════════════════════════
put '/usuarios/:colegio/depto' => sub ($c) {
    my $colegio    = uc(trim($c->param('colegio')));
    my $body       = decode_json($c->req->body);
    my $nuevo_depto = uc(trim($body->{departamento} // ''));

    # Validar formato de departamento
    unless ($nuevo_depto =~ /^DEP-(ADM|MED|CIR|LAB|FAR)$|^SIN-DEP$/) {
        return $c->render(json => { ok=>0, mensaje=>'Departamento no válido' });
    }

    # Buscar en AVL
    my $u = $arbolAVL->buscar($colegio);
    unless (defined $u) {
        return $c->render(json => { ok=>0, mensaje=>"Usuario $colegio no encontrado" });
    }

    # Actualizar departamento en el nodo del AVL
    $u->{depto} = $nuevo_depto;

    $c->render(json => {
        ok      => 1,
        mensaje => "Departamento de $colegio actualizado a $nuevo_depto",
        depto   => $nuevo_depto,
        activo  => $nuevo_depto ne 'SIN-DEP' ? 1 : 0  # Activa/desactiva acceso
    });
};

# ══════════════════════════════════════════════════════
# USUARIOS SIN DEPARTAMENTO (Solo lectura - Lista simple)
# ══════════════════════════════════════════════════════
get '/usuariosD/sin-departamento' => sub ($c) {
    my $lista = $arbolAVL->inorden;
    
    # Filtrar SOLO usuarios con SIN-DEP, null o vacío
    my @pendientes = grep {
        my $v = $_->{valor};           # El hash con los datos
        my $d = $v->{depto} // '';     # Acceder a la clave 'depto'
        
        # Debug en consola
        warn "DEBUG Usuario: " . ($_->{clave}) . " Depto: '$d'\n";
        
        $d eq '' || $d eq 'null' || $d eq 'SIN-DEP'
    } @$lista;
    
    warn "DEBUG Total pendientes: " . scalar(@pendientes) . "\n";
    
    # Formatear respuesta
    my @resultado = map {{
        numero_colegio => $_->{clave},
        nombre         => $_->{valor}{nombre},
        tipo           => $_->{valor}{tipo},
        especialidad   => $_->{valor}{espec} // 'N/A',
    }} @pendientes;
    
    $c->render(json => {
        ok       => 1,
        total    => scalar(@resultado),
        usuarios => \@resultado,
    });
};

app->start;