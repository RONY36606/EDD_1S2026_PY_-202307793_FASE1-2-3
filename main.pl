#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;

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



#ESTRUCTURAS GENERALES DEL PROGRAMA
my $listaMedicamentos = listaDoblementeEnlazada->new;


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

        }
        elsif($op eq '2'){

        }
        else{
            print"Lo siento mucho!, pero esa opción no existe en este menú.\n";
        }
    }
}

#------------------------------SUB PARA REGISTRAR MEDICAMENTOS------------------------------------
sub RegistroMedicamento{
#Acá vamos a registrar medicinas para usar
            print "\n*******************Registro de medicamentos*******************\n";
            print "Código del medicamento: "; chomp(my $codigo = <STDIN>);
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

#-------------------------------SUB PARA CARGA MASIVA DE MEDICAMENTOS--------------------------------
sub cargaMasivaMedicina{
    my($ruta, $listaMedicamentos)=@_;

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 }); open my $fh, "<:encoding(utf8)", $ruta or die "Lo lamento, no se pudo abrir $ruta: $!"; 
    # Si el archivo tiene encabezados, se usan de header
    my $header = $csv->getline($fh);

    #Recorrer todas las líneas
    while(my $row = $csv->getline($fh)){
        #el row es un arrayRef con toda la data de los medicamentos
        my ($codigo, $nombre, $activo, $laboratorio, $stock, $fecha, $precio, $nivel) = @$row;
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

    }

    close $fh;
}

#-----------------------------FLUJO PRINCIPAL DEL PROGRAMA -------------------------------------------
while(1){
    my $rol  = elegir_rol();
    last if $rol eq 'salida';
    my $usuario = Login($rol);
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
