#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use Time::Piece;
use Time::Seconds;
use GraphViz;

# Forzar salida en UTF-8
use open ':std', ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

sub arte1{
    print <<'ART';
.:::::.........-=:.....:.....:-:-:..-=:.........::----=-:::-----::::::::::::::::------------+++****
...::..........-=:.....:.....:-..-:..==-..:....::...:---=::::.---::::::::::::::-==+++++++*****
....:..........:=-.....:::....:-...:-::==-::::::::::.....:-=::::...:--:-::-=-:::::::::-:--======+++====
::.::..........:=-::...:-:...-:.....-::=-=:::::::::.......:---:.....:--====-:::::::::::-=+=++
:::::::...::::..:==-:::.:::::::........::=-=-::::::::..:=-:...-:......:--====-:::::::::-:---------====
::::::::::::::::===:::::::.:::::..........:::-=::::::::.:--:.....:.......:===-::.....:::---::::::---------
--:::::::::::::::===:::-...::::::::::-----.....:-:::....:##*:...::::...........-::........:::---------
-:::::::::::::::::==-::::...:::::..................:::..:#:..............::::::=::...........::::::
-=-:::::::::::::::==-::.....:.......:::::...................:...:..:.:.:.:.::::--:..............:-:-:
-:--:::::::::::::::==--:.......-*######-..........:...:...:.........::...:---:.................:--
:::-=::::::::::::::-=-:.....-+#%%#+:.........:...........................:...:---:..................:
:::-=::::::::::::::=-......=#*-........:.........:--...........=###*:..:....:-:.................:
::::=-:::::::::::::::.....::::::........:....:.......-*##%%%###=.:......:::................
::::=-:::::::::::::::......::::...:.....................:*###%%%%%%%%#-..:.......................
::::-=:::::::::::::::--.....:...:...............::=*####%%%%%%%%%%##-..-=::.......................
::::-=-:::::::::...::::...:-:::...:+#####*******#############%####%#%#*:..:-===:..............::....
::::-==::::::::....--..:::.:..*#%%%%%%%%%%##%#%##**+++++++=----==:....-======:.........:-----------
::::-==-::::::....::=:.:...:..##%%%%%%%%%%%%#*+++++++=--------:......-=======-:::......:-------------
::::-===-::.:::.....:----:...:.:*###%%%%%#++=------------:.........:========:::::::::::--------------
::::-====::.:......:-==-:...::...:=####+--------:::.............-==========::::::::-----------------
::::-===::..:.......:===:....:..............................:============::::::::-----------------
::::==-::::...........:-=:.....-:..........................:=--+####*======-:::::-------------------
::::=-:.::.............:--:....:======--::..................:=----=##**+=======:::::------------------
::::=-:.:................-.....:-========-------============**********=======+=-::::------------------
:::-=-:.................:........==+===*#+-------------*##************====++++-::::------------------
:::-=-:................::......-=+*#####=+###++++***###********#***+======::::::.-----------------
:::-=-:....................===*##########*******####***************===-:::::..----------------
:::==::........................-=====##########****************========**:::::...---------------
:::==-:....................========##%%%%%%%#########*****+*+=======:.....-::-.....:------------
ART
}

sub arte2{
    print <<'ART2';
    __________  ____              __  ___         ____                  __               __  _______ ___   ______
   / ____/ __ \/ __ \            /  |/  /__  ____/ / /__________ ______/ /__            / / / / ___//   | / ____/
  / __/ / / / / / / /  ______   / /|_/ / _ \/ __  / __/ ___/ __ `/ ___/ //_/  ______   / / / /\__ \/ /| |/ /     
 / /___/ /_/ / /_/ /  /_____/  / /  / /  __/ /_/ / /_/ /  / /_/ / /__/ ,<    /_____/  / /_/ /___/ / ___ / /___   
/_____/_____/_____/           /_/  /_/\___/\__,_/\__/_/   \__,_/\___/_/|_|            \____//____/_/  |_\____/   
     
ART2
}

sub arte3{
    print <<'ART3';
..............::::::::::::::::::::::::::::::::::............
............:::::::::::::---====---:::::::::::::::..........
...........::::::::::::--------------::::::::::::::.........
.........::::::::::::--::----:-:::-----:::::::::::::........
.........:::::::::::----=------:--------:::::::::::::.......
........::::::::::::--==*========+==-==-::::::::::::::......
........:::::::::::-+++++++**++++**+*++=-:::::::::::::......
.......::::::::::::=++*#+=++#**++-+++#*+-::::::::::::::.....
.......:::::::::::::*#%#+=+--+=:=+=+#**=::::::::::::::::....
.......:::::::::::::=*=:-:::::::::--=+#-:::::::::::::::.....
.......:::::::::::::-=-::=::::::::--:-=-:::::::::::::::.....
.......:::::::::::::====-+=:::::-=:--==:::::::::::::::::....
.......:::::::::::::::=#++=:-:---=+**::::::::::::::::::.....
.......:::::::::::::::-*-+++-+==++==+::::::::::::::::::.....
........:::::::::::::=:+-++=-==-+++==--:::::::::::::::......
........:::::::::::::==+*++---=:+++**+:::::::::::::::.......
.........::::::::::::+***+=:+++:-++##+:::::::::::::::.......
..........:::::::::::+***+-:***::=+**+::::::::::::::........ 
ART3
}

#REQUIRES NECESARIOS

use lib 'Clases';
use lib 'TDA';

use medicamento;
use listaDoblementeEnlazada;
use listaCircular;
use proveedor;
use entregaProveedor;
use solicitudReabastecimiento;
use listaCircularDoble;
use solicitudReabastecimiento;



#ESTRUCTURAS GENERALES DEL PROGRAMA
my $listaMedicamentos = listaDoblementeEnlazada->new;
my $listaProveedores = listaCircular->new;
my $listaSolicitudesReabaste = listaCircularDoble->new;
my $rolGeneral;

# Simulación de usuarios y roles
my %usuarios = (
  'admin' => { pass => 'admin123', role => 'admin' },
  'enfermeria'  => { pass => 'user123',  role => 'usuario_departamental' },
);

sub elegir_rol {
  arte2();
  print "Hola, bienvenido!,por favor, elige tu rol: ";
  print "
         1) Administrador 
         2) Usuario departamental
         3) Salir
          ";
  chomp(my $rol = <STDIN>);
  return 'admin' if $rol eq '1';
  return 'usuario_departamental' if $rol eq '2';
  return 'salida' if $rol eq '3';
  print "Oye!, esa opcion no es valida. Pruebas de nuevo?, por favor :3";
  return elegir_rol();
}


#*******-----------------------------*Login de todo usuario----------------------
sub Login{
    my($expected_rol) = @_; # el @_ es un operador que extrae el primer argumento que le han pasado a la subrutina, osea el rol
    print "\n Coloca aqui tu nombre de usuario, por favor :3: ";
    chomp(my $user = <STDIN>);

    print "\n Coloca aqui tu contraseña, por favor :3: ";
    chomp(my $password = <STDIN>);

    unless (exists $usuarios{$user}){
        print "Lo siento mucho!, tu usuario no esta en nuestra base datos :(\n";
        return;
    }
    if ($usuarios{$user}{pass} ne $password){
        print "Lo siento mucho!, Escribiste mal tu contraseña\n";
        return;

    }
    if($usuarios{$user}{role} ne $expected_rol){
        print "Qué haces aqui?, no eres de este rol\n";
        return;
    }

    return $user;
}

#-----------------------------------MENÚ DE LOS USUARIO ADMINISTRADOR--------------------------------------
sub menu_admin{
    my($user) = @_;
    while(1){
        print "\n Hola $user!, Que deseas hacer hoy?!\n";
        print "1.) Registrar nuevo medicamento \n";
        print "2.) Registrar nuevo medicamento - Carga Masiva\n";
        print "3.) Gestionar Proveedores\n";
        print "4.) Registrar nueva entrega de proveedores\n";
        print "5.) Procesar solicitudes de reabastecimiento\n";
        print "6.) Visualizar inventario completo\n";
        print "7.) Consultar inventario por laboratorio/medicina\n";
        print "8.) REPORTES \n";
        print "9.) Cerrar sesión :3\n";
        chomp(my $op = <STDIN>);
        last if $op eq '9';        
        if ($op eq '1'){
            RegistroMedicamento();
        }
        elsif($op eq '2'){
            print "Hola!, ingresa la ruta del archivo csv para cargar los datos :D: ";
            chomp(my $ruta = <STDIN>);
            cargaMasivaMedicina($ruta, $listaMedicamentos);
            print "\n--- Lista de medicamentos ---\n";
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
             print $med->codigoMedicina, " - ", $med->nombreComercial, "\n";});
        }
        elsif($op eq '3'){
            RegistroProveedor();
        }
        elsif($op eq '4'){
            registrarEntregaProveedor();
        }
        elsif($op eq '5'){
            aprobarSolicitudReabaste();
        }
        elsif($op eq '6'){
            visualizarInventario();
        }
        elsif($op eq '8'){
            print "\n*******************Creación de reportes gráficos*******************\n";
             print "Que reporte deseas generar? \n";
            print "1.) Reporte de medicinas\n";
            print "2.) Reporte de solicitudes\n";
            print "3.) Reporte de proveedores\n";
            print "4.) Reporte comparación\n";
            print "5.) salir :(\n";
            print "Que reporte deseas generar?: "; chomp(my $opcion = <STDIN>);
            last if $opcion eq '5';  
            if($opcion eq '1'){
                graficarListaMedicina($listaMedicamentos);
            }
            elsif($opcion eq '2'){
                graficarListaSolicitudes($listaSolicitudesReabaste);
            }
            else{
                print "!!!!!!!!!!!!!!!!!!!OYE, esa opción no existe!!!!!!!!!!!!!!!!!!!!";
            } 
            
        }
        else{
            print"Lo siento mucho!, pero esa opción no existe en este menú.";
        }
    }
}

#-----------------------------------MENÚ DE LOS USUARIO DEPARTAMENTALES--------------------------------------
sub menu_departamental{
    my($user) = @_;
    while(1){
        print "\n Hola $user!, Qué deseas hacer hoy?!\n";
        print "1.) Consultar disponibilidad de medicinas\n";
        print "2.) Solicitar reabastecimineto\n";
        print "3.) Ver historial de Solicitudes\n";
        print "4.) Cerrar sesión :3\n";
        chomp(my $op = <STDIN>);
        last if $op eq '4';        
        if ($op eq '1'){
            visualizarInventarioDepartamental();
        }
        elsif($op eq '2'){
            realizarSolicitudReabaste();
        }
        elsif($op eq '3'){
            mostrarSolicitudes();
        }
        else{
            print"Lo siento mucho!, pero esa opción no existe en este menú.\n";
        }
    }
}
#------------------------------SUB PARA CREAR CÓDIGO MED--------------------------
sub generar_codigo_medicamento { 
    my ($listaMedicamentos) = @_; 
    my $num = $listaMedicamentos->size + 1; #para contar desde uno cawn
    my $codigo = sprintf("MED%03d", $num);
     return $codigo; }
#------------------------------SUB PARA CREAR CÓDIGO MED--------------------------
sub generar_codigo_solicitud { 
    my ($listaSolicitudesReabaste) = @_; 
    my $num = $listaSolicitudesReabaste->size + 1; #para contar desde uno cawn
    my $codigo = sprintf("SOL%03d", $num);
     return $codigo; }

#------------------------------ 1. SUB PARA REGISTRAR MEDICAMENTOS------------------------------------
sub RegistroMedicamento{
    #Ver la estructura del código MED00X
#Acá vamos a registrar medicinas para usar
            print "\n*******************Registro de medicamentos*******************\n";
            my $codigo = generar_codigo_medicamento($listaMedicamentos);
            print "Nombre comercial del medicamento: "; chomp(my $nombre = <STDIN>);
            print "Principio activo del medicamento: "; chomp(my $activo = <STDIN>);
            print "Laboratorio fabricante del medicamento: "; chomp(my $laboratorio = <STDIN>);
            print "Cantidad de stock del medicamento: "; chomp(my $stock = <STDIN>);
            print "Fecha de vencimiento del medicamento: "; chomp(my $fecha = <STDIN>);
            print "precio del medicamento: "; chomp(my $precio = <STDIN>);
            print "Nivel mínimo de reorden del medicamento: "; chomp(my $nivel = <STDIN>);
            print "\n*******************Muchas gracias por tus respuestas :D!*******************\n";

            my $medicina = medicamento->new(
                codigoMedicina => $codigo,
                nombreComercial => $nombre,
                principioActivo => $activo,
                laboratorioFabricante => $laboratorio,
                cantidadStock => $stock,
                fechaVencimiento => $fecha,
                precio => $precio,
                nivelMinimoReorden => $nivel,
            );

            #Meter el objeto a la lista doblemente enlazada, al fondo
            $listaMedicamentos->pushBack($medicina);
            print "\n*******************Medicamento registrado :D!*******************\n";

            print "\n--- Lista de medicamentos ---\n";
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
             print $med->codigoMedicina, " - ", $med->nombreComercial, "\n";});
}

#-------------------------------2. SUB PARA CARGA MASIVA DE MEDICAMENTOS--------------------------------
sub cargaMasivaMedicina{
    my($ruta, $listaMedicamentos)=@_;

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 }); open my $fh, "<:encoding(utf8)", $ruta or die "Lo lamento, no se pudo abrir $ruta: $!"; 
    # Si el archivo tiene encabezados, se usan de header
    my $header = $csv->getline($fh);

    #Recorrer todas las líneas
    while(my $row = $csv->getline($fh)){
        #el row es un arrayRef con toda la data de los medicamentos
        my ($codigo, $nombre, $activo, $laboratorio, $stock, $fecha, $precio, $nivel) = @$row;
        
            my $existe =0;
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
                #verificar si el código está en la lista
                if($med->codigoMedicina eq $codigo){
                    $existe = 1;
                }
             });
             #si es que hay un código repetido, creamos otro
             if ($existe) { 
                $codigo =~ /MED(\d+)/; 
                my $num = $1; 
                $num++; 
                $codigo = sprintf("MED%03d", $num); }
            # Crear objeto medicamento 
            my $medicina = medicamento->new( 
                codigoMedicina => $codigo, 
                nombreComercial => $nombre, 
                principioActivo => $activo, 
                laboratorioFabricante => $laboratorio, 
                cantidadStock => $stock, 
                fechaVencimiento => $fecha, 
                precio => $precio, 
                nivelMinimoReorden => $nivel, ); 
                # Insertar al final de la lista 
                $listaMedicamentos->pushBack($medicina);
    }

    close $fh;
}
#-----------------------------3. SUB PARA CREAR PROVEEDORES EN EL SISTEMA--------------------------------
sub RegistroProveedor{
#Acá vamos a registrar medicinas para usar
            print "\n*******************Registro de proveedores*******************\n";
            print "NIT del proveedor: "; chomp(my $nit = <STDIN>);
            print "Nombre de la empresa: "; chomp(my $nombre = <STDIN>);
            print "Contacto principal: "; chomp(my $contacto = <STDIN>);
            print "Teléfono: "; chomp(my $telefono = <STDIN>);
            print "Dirección: "; chomp(my $direccion = <STDIN>);
            print "\n*******************Muchas gracias por tus respuestas :D!*******************\n";

            my $proveedor = proveedor->new(
                nit => $nit,
                nombreEmpresa => $nombre,
                contactoPrincipal => $contacto,
                telefono => $telefono,
                direccion => $direccion,
            );

            #Meter el objeto a la lista doblemente enlazada, al fondo
            $listaProveedores->insertar($proveedor);
            print "\n*******************Medicamento registrado :D!*******************\n";

            print "\n--- Lista de proveedores ---\n";
            $listaProveedores->recorrer(sub { 
                my $nodo = shift;
                my $prov = $nodo->valor; # método del setter para obtener el contenido
             print $prov->nit, " - ", $prov->nombreEmpresa, "\n";});
}

#----------------------------- 4. SUB PARA INSERTAR NUEVA ENTREGA A PROVEEDOR-----------------------------
sub registrarEntregaProveedor{
    my $encontrado = 0;
    print "\n*******************Registro de nueva entrega a proveedor*******************\n";
            print "Por favor, ingresa el nit del proveedor: "; chomp(my $nit = <STDIN>);
            print "++++Buscando+++++++++\n";
            print "++++Buscando+++++++++\n";
            print "++++Buscando+++++++++\n";
            print "++++Buscando+++++++++\n";
    #recorremos y buscamos el númerode nit del proveedor
    $listaProveedores->recorrer(sub { 
                my $nodo = shift;
                my $prov = $nodo->valor; # método del setter para obtener el contenido

                if($prov->nit eq $nit){
                    #ver si encontraron un proveedor
                    $encontrado = 1;
                    #si encuentra el nit, pediremos los demás datos
                    print "\n*******************Registro de nueva entrega a proveedor*******************\n";
                    print "Por favor, ingresa el número de la factura: "; chomp(my $factura = <STDIN>);
                    print "Por favor, ingresa la fecha de entrega del medicamento: "; chomp(my $fecha = <STDIN>);
                    print "Por favor, ingresa el código del medicamento: "; chomp(my $codigo = <STDIN>);
                    print "Por favor, ingresa la cantidad entregada del medicamento: "; chomp(my $cantidad = <STDIN>);
                    my $existe =0;
                    $listaMedicamentos->iterar(sub { 
                        my $nodo = shift;
                        my $med = $nodo->value; # método del setter para obtener el contenido
                        #verificar si el código está en la lista
                        if($med->codigoMedicina eq $codigo){
                            $existe = 1;
                            #actualizaremos de una vez la cantidad del medicamento
                            $med->set_cantidadStock($med->cantidadStock +$cantidad);
                        }
                    });
                    if($existe){
                        
                        #GUARDAR EL MEDICAMENTO EN EL PROVEEDOR
                        $prov->registroEntrega(
                            nit => $nit,
                            fechaEntrega => $factura,
                            numeroFactura => $fecha,
                            codigoMedicamento => $codigo,
                            cantidadEntregada => $cantidad
                        );
                        print "\n*******************:D Entrega registrada!*******************\n";
                    }else{
                        print "\n*******************Oye, ese medicamento no está registrado!, la entrega no es válida*******************\n";
                    }
                }else{
                    print "\n*******************Lo sentimos, ese proveedor no está registrado*******************\n";
                }
             print "\n--- Lista de entregas del proveedor ---\n";   
             print $prov->listarEntregas;});

             print "***************************OYE!, Ese proveedor no existe en mis registros!*****************************\n" unless $encontrado;
}

#------------------------------- 5. SUB PARA SOLICITUD DE REABASTECIMIENTO--------------------------------
sub realizarSolicitudReabaste{
    print "\n*******************Nueva solicitud de reabastecimiento*******************\n";
    print "Por favor, ingresa el código del medicamento requerido: "; chomp(my $medicamento = <STDIN>);
    print "Por favor, ingresa la cantidad del medicamento requerido: "; chomp(my $cantidad = <STDIN>);
    print "\n*******************Muchas gracias por tus respuestas :D!*******************\n";
    my $t = localtime;
    my $fecha = $t->ymd;
    my $encontrado = 0;

    $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
             #verificar que la medicina exista para poder crear la solicitud
             if($med->codigoMedicina eq $medicamento){
                $encontrado = 1;
             }
             });

    if($encontrado == 1){
        my $codigo = generar_codigo_solicitud($listaSolicitudesReabaste);
        #si lo encuentra, se guarda la solicitud
        my $solicitud = solicitudReabastecimiento->new(
                codigoSolicitud => $codigo,
                departamento => $rolGeneral,
                medicamentoRequerido => $medicamento,
                cantidadSolicitada => $cantidad,
                fechaSolicitud => $fecha, 
                estadoSolicitud => 'sin confirmar'
            );

        #insertar la solicitud en la lista doblemente enlazada
        $listaSolicitudesReabaste->insertar($solicitud);
        print "\n*******************Solicitud registrada :D!*******************\n";
        print "\n*******************Recibirás una respuesta, muy pronto :D!*******************\n";
    }
    else{
        print "\n*******************El medicamento que mencionas, no está registrado:(!*******************\n";
    }

    
    
}

#------------------------------- 5. SUB PARA CONFIRMAR SOLICITUD DE REABASTECIMIENTO----------------------
sub aprobarSolicitudReabaste{
    $listaSolicitudesReabaste->recorrerAdelante(
        sub { 
            #Acá vamos a mostrar la información de la solicitud
            my $nodo = shift; 
            my $solicitud = $nodo->valor;
            #mostrar las solicitudes que no han sido confirmadas
            if($solicitud->{estadoSolicitud} eq 'sin confirmar'){
                print "\n--- Solicitudes disponibles: ", $listaSolicitudesReabaste->{size},"---\n";
                print $solicitud->departamento, " - ", $solicitud->fechaSolicitud, " - ", "\n", $solicitud->medicamentoRequerido, " - ", $solicitud->cantidadSolicitada,"\n"; 
                print "Aprobaremos esta solicitud? :D  (s/n): "; chomp(my $respuesta = <STDIN>);
                #si se aprueba la solicitud, se busca el código del medicamento en la lista de medicinas
                #se establece el estado en aceptado
                if(lc($respuesta) eq 's'){
                    #recorrer los medicamentos disponibles
                    print "\n--- Buscando unidades disponibles ---\n";
                    $listaMedicamentos->iterar(sub { 
                        
                        my $nodo = shift;
                        my $med = $nodo->value; # método del setter para obtener el contenido
                        #si los códigos de los medicamentos son iguales, verificar si hay unidades suficientes
                        if($med->{codigoMedicina} eq $solicitud->{medicamentoRequerido}){
                            #verificar que en la solicitud hayan pedido menos unidades que las disponibles
                           
                            if($med->{cantidadStock} < $solicitud->{cantidadSolicitada}){
                                #si hay menos unidades disponibles que las requeridas, rechazamos la solicitud
                                $solicitud->{estadoSolicitud} = 'rechazado';
                                print "\n*******************Solicitud rechazada :D!*******************\n";
                            }
                            else{
                                #si hay suficientes medicamentos, restarle al stock lo solicitado
                                $med->{cantidadStock} = $med->{cantidadStock} - $solicitud->{cantidadSolicitada};
                                #marcamos la solicitud como aprobada
                                $solicitud->{estadoSolicitud} = 'aprobada';
                                print "\n*******************Solicitud aprobada :D!*******************\n";
                            }
                        }
                    });
                }else{
                    #si no se aprueba, se establece el estado en rechazado
                    $solicitud->{estadoSolicitud} = 'rechazado';
                    print "\n*******************Solicitud rechazada :D!*******************\n";
                }
            }
            else{
                
            }
            
        });
}

#----------------------------- 5. SUB PARA MOSTRAR EL HISTORIAL DE SOLICITUDES-------------------------
sub mostrarSolicitudes{
    $listaSolicitudesReabaste->recorrerAdelante(
        sub { 
            my $nodo = shift;
            my $solicitud = $nodo->valor; 
            print "\n--- Solicitud ---\n";
            print $solicitud->departamento, " - ", $solicitud->fechaSolicitud, " - ", "\n", $solicitud->medicamentoRequerido, " - ", $solicitud->cantidadSolicitada,"\n", $solicitud->estadoSolicitud;
            });
}

#----------------------------- 6. SUB PARA VISUALIZAR EL INVENTARIO COMPLETO-------------------------
sub visualizarInventario{
    print "\n--- Lista de medicamentos en nuestro inventario---\n";
    print "\n--- Esto es todo lo que tenemos dentro del hospital (.-.)---\n";
    
    my $fecha = localtime;
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
                print $med->codigoMedicina, " - ", $med->nombreComercial, " - ", $med->principioActivo, " - ", $med->laboratorioFabricante, " - ",$med->cantidadStock, " - ",$med->fechaVencimiento, " - ",$med->precio, " - ",$med->nivelMinimoReorden ,"\n";
             #verificar si se necesita comprar más
                if($med->cantidadStock < $med->nivelMinimoReorden){
                    print "-------->>>>> ALERTA : Se necesita solicitar más unidades de ", $med->nombreComercial,"\n";
                }
             #verificar si está próximo a vencer
             my $fecha_vencimiento_str = $med->fechaVencimiento;
             my $fecha_vencimiento = Time::Piece->strptime($fecha_vencimiento_str, "%Y-%m-%d");
             if ($fecha_vencimiento < $fecha){ 
                print "-------->>>>Lo siento, pero, el medicamento ya venció.\n";
             } elsif ($fecha_vencimiento <= $fecha + ONE_DAY*7){ 
                print "-------->>>>>>>>Ten mucho cuidado!, el medicamento vence en menos de una semana.\n";
             } else { 
                print "-------->>>(0u0!), Yay!, el medicamento aun esta vigente. :)\n"; }
                print "\n-----------------------------------------------------------------------------\n";
             });
}

#-----------------------------SUB PARA VISUALIZAR INVENTARIO - DEPARTAMENTAL------------------------
sub visualizarInventarioDepartamental{
    my $encontrado = 0;
    print "\n--- Lista de medicamentos en nuestro inventario---\n";
    print "\n*******************Acá podrás buscar el medicamento de tu interes!*******************\n";
    print "Cuentame!, Quieres buscar el medicamento por nombre o identificador? :D, n para nombre e i para identificador  (n/i): "; chomp(my $respuesta = <STDIN>);
    if(lc($respuesta) eq 'i'){
        print "\n--- Lista de medicamentos ---\n";
            print "Ingresa el código del medicamento del que necesitas información!: "; chomp(my $codigo = <STDIN>);
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
                if($med->codigoMedicina eq uc($codigo)){
                    print $med->nombreComercial, " - ", $med->cantidadStock, "\n";
                    $encontrado = 1;
                }
             });
             print "\n*******************Oye!, ese medicamento no existe*******************\n" unless $encontrado;
    }
    elsif(lc($respuesta) eq 'n'){
        print "\n--- Lista de medicamentos ---\n";
            print "Ingresa el nombre del medicamento del que necesitas información!: "; chomp(my $nombre = <STDIN>);
            $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido
                if(uc($med->nombreComercial) eq uc($nombre)){
                    print $med->nombreComercial, " - ", $med->cantidadStock, "\n";
                    $encontrado = 1;
                }
             });
             print "\n*******************Oye!, ese medicamento no existe*******************\n" unless $encontrado;
    }
    else{
        print "\n*******************Oye!, esa opción no existe*******************\n";
    }

}

#*********************************************************************************************************************************
#*********************************************************************************************************************************
#*********************************************************************************************************************************
#*********************************************************************************************************************************

#------------------------------------REPORTE PARA LA LISTA DOBLEMENTE ENLAZADA--------------
sub graficarListaMedicina{
    my($listaMedicamentos)=@_;
    my $g = GraphViz->new(directed =>1);
    my $fecha = localtime;
    my $color = 'green';

    #hay que recorrer la lista de medicinas
    $listaMedicamentos->iterar(sub { 
                my $nodo = shift;
                my $med = $nodo->value; # método del setter para obtener el contenido

                #verificar si se necesita comprar más
                if($med->cantidadStock < $med->nivelMinimoReorden){
                    $color = 'red';
                }
             #verificar si está próximo a vencer
             my $fecha_vencimiento_str = $med->fechaVencimiento;
             my $fecha_vencimiento = Time::Piece->strptime($fecha_vencimiento_str, "%Y-%m-%d");
             if ($fecha_vencimiento < $fecha){ 
                $color = 'yellow';
             } elsif ($fecha_vencimiento <= $fecha + ONE_DAY*7){ 
                $color = 'yellow';
             } 

             
             #cada nodo será un rectángulo con color
             $g->add_node(
                $med->{codigoMedicina},
                label => "$med->{codigoMedicina}\n$med->{nombreComercial}\n$med->{fechaVencimiento}\n$med->{cantidadStock}",
                shape => 'box',
                style => 'filled',
                color => $color,
                fontcolor => 'black'
             );
             # Conexión hacia el siguiente
            if ($nodo->next) { 
                $g->add_edge($med->{codigoMedicina} => $nodo->next->value->{codigoMedicina});
                 } # Conexión hacia el anterior (en rojo) 
            if ($nodo->prev) { 
                $g->add_edge($med->{codigoMedicina} => $nodo->prev->value->{codigoMedicina}, color => 'red'); }
             
             });
             # Exportar a archivo DOT
            mkdir "graficos" unless -d "graficos"; #se crea la carpeta

            open my $fh, '>', 'graficos/lista.dot' or die $!;
            print $fh $g->as_text;
            close $fh;



             #Guardar el PNG en una carpeta
             system("dot -Tpng graficos/lista.dot -o graficos/lista.png");
}
#------------------------------------REPORTE PARA LA LISTA CIRCULAR DOBLEMENTE ENLAZADA--------------
sub graficarListaSolicitudes{
    my($listaSolicitudesReabaste)=@_;
    my $g = GraphViz->new(directed =>1);
    my $fecha = localtime;
    my $ordenSolicitud = 0;

    #hay que recorrer la lista de medicinas
    $listaSolicitudesReabaste->recorrerAdelante(sub { 
                my $nodo = shift;
                my $solicitud = $nodo->valor; # método del setter para obtener el contenido
                $ordenSolicitud++;
                my $color = ($ordenSolicitud == 1) ? 'red' : 'white';
             
             if($solicitud->estadoSolicitud eq 'sin confirmar'){
                #cada nodo será un rectángulo con color
             $g->add_node(
                $solicitud->{codigoSolicitud},
                label => "$ordenSolicitud\n$solicitud->{departamento}\n$solicitud->{medicamentoRequerido}\n$solicitud->{cantidadSolicitada}",
                shape => 'circle',
                style => 'filled',
                fillcolor => $color,
                color => 'black',
                fontcolor => 'black'
             );
            # Conexión hacia el siguiente
            if ($nodo->siguiente) { 
                $g->add_edge($solicitud->{codigoSolicitud} => $nodo->siguiente->valor->{codigoSolicitud});
                 } # Conexión hacia el anterior (en rojo) 
            if ($nodo->anterior) { 
                $g->add_edge($solicitud->{codigoSolicitud} => $nodo->anterior->valor->{codigoSolicitud}, color => 'red'); }
             }
             
             });
             # Exportar a archivo DOT
            mkdir "graficos" unless -d "graficos"; #se crea la carpeta

            open my $fh, '>', 'graficos/listaCircularDoble.dot' or die $!;
            print $fh $g->as_text;
            close $fh;



             #Guardar el PNG en una carpeta
             system("dot -Tpng graficos/listaCircularDoble.dot -o graficos/listaCircularDoble.png");
}
#-----------------------------FLUJO PRINCIPAL DEL PROGRAMA -------------------------------------------
while(1){
    my $rol  = elegir_rol();
    last if $rol eq 'salida';
    my $usuario = Login($rol);
    $rolGeneral = $usuario;
    if ($usuario){
        # si el usuario existe, según el rol, desviaremos a uno u otro lugar
        if($rol eq 'admin'){
            menu_admin($usuario);
        }
        else{
            menu_departamental($usuario);
        }

        arte2();
        print "Cerrando sesión :3\n";
    } 
    else {
        print " Lo siento!,no ha sido posible que inicies sesion. Lo volvemos a intentar? (s/n)\n";
        chomp(my $respuesta = <STDIN>);
        last if lc($respuesta) ne 's';
    }


}
print "Nos veremos en otra ocasion!, espero que sea muy pronto :)\n";
arte3();
