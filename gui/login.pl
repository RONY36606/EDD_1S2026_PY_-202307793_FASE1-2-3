#!/usr/bin/perl
# ============================================================
#  EDD MedTrack F2 - gui/login.pl
#  Pantalla de Login — conectada con lógica de main.pl
# ============================================================
use strict;
use warnings;
use Gtk3 -init;

# ============================================================
# FUNCIÓN DE VALIDACIÓN — usa las estructuras reales de main.pl
# ============================================================
sub validar_credenciales_gui {
    my ($usuario, $password) = @_;

    # Admin especial (hardcoded según enunciado)
    if ($usuario eq "AdminHospital" && $password eq "MedTrack2025") {
        return { rol => "admin", nombre => "Administrador", tipo => "TIPO-05" };
    }

    # Usuarios departamentales — buscar en el árbol AVL
    # Por ahora usa el %usuarios de main.pl (Fase 1)
    # En Fase 2 esto se reemplaza con búsqueda en AVL
    if (exists $usuarios{$usuario}) {
        if ($usuarios{$usuario}{pass} eq $password) {
            return {
                rol    => "medico",
                nombre => $usuario,
                tipo   => "TIPO-01",   # En Fase 2 vendrá del nodo AVL
                depto  => "DEP-MED",   # En Fase 2 vendrá del nodo AVL
            };
        }
    }

    return undef;
}

# ============================================================
# APLICAR ESTILOS CSS
# ============================================================
sub aplicar_css_login {
    my $css = Gtk3::CssProvider->new();
    $css->load_from_data(<<'CSS');
        window {
            background-color: #1a2f5a;
        }
        .header-barra {
            background-color: #152548;
            padding: 10px 16px;
            border-bottom: 2px solid #c8922a;
        }
        .titulo-sistema {
            color: #ffffff;
            font-size: 15px;
            font-weight: bold;
            letter-spacing: 3px;
        }
        .subtitulo-sistema {
            color: #c8922a;
            font-size: 10px;
            letter-spacing: 2px;
        }
        .card {
            background-color: #ffffff;
            border-radius: 10px;
        }
        .label-campo {
            color: #1a2f5a;
            font-size: 10px;
            font-weight: bold;
            letter-spacing: 2px;
        }
        .entry-campo {
            border: 1px solid #d1dbe8;
            border-radius: 5px;
            padding: 6px 10px;
            font-size: 13px;
            background-color: #f8fafc;
        }
        .entry-campo:focus {
            border-color: #2563a8;
        }
        .btn-ingresar {
            background-color: #2563a8;
            color: #ffffff;
            border-radius: 5px;
            font-weight: bold;
            font-size: 12px;
            letter-spacing: 2px;
            padding: 10px;
            border: none;
        }
        .btn-ingresar:hover {
            background-color: #1a4f8a;
        }
        .btn-registrar {
            background-color: #c8922a;
            color: #ffffff;
            border-radius: 5px;
            font-weight: bold;
            font-size: 12px;
            letter-spacing: 1px;
            padding: 10px;
            border: none;
        }
        .btn-registrar:hover {
            background-color: #a87520;
        }
        .lbl-error {
            color: #e53e3e;
            font-size: 11px;
        }
        .lbl-exito {
            color: #38a169;
            font-size: 11px;
        }
        .lbl-info {
            color: #4a5568;
            font-size: 12px;
        }
CSS
    my $screen = Gtk3::Gdk::Screen::get_default();
    Gtk3::StyleContext::add_provider_for_screen(
        $screen, $css,
        Gtk3::STYLE_PROVIDER_PRIORITY_APPLICATION
    );
}

# ============================================================
# ABRIR PANEL SEGÚN ROL
# ============================================================
sub abrir_panel {
    my ($window_login, $datos) = @_;
    $window_login->hide;

    if ($datos->{rol} eq 'admin') {
        # En Fase 2: require 'gui/admin.pl'; mostrar_panel_admin($datos);
        _ventana_placeholder("Panel Administrador", $datos);
    } else {
        # En Fase 2: require 'gui/medico.pl'; mostrar_panel_medico($datos);
        _ventana_placeholder("Panel Médico", $datos);
    }
}

sub _ventana_placeholder {
    my ($titulo, $datos) = @_;

    my $win = Gtk3::Window->new('toplevel');
    $win->set_title("EDD MedTrack — $titulo");
    $win->set_default_size(700, 450);
    $win->set_position('center');
    $win->signal_connect(destroy => sub { Gtk3->main_quit });

    my $vbox = Gtk3::Box->new('vertical', 0);

    # Header
    my $header = Gtk3::Box->new('horizontal', 10);
    $header->get_style_context->add_class('header-barra');
    $header->set_size_request(-1, 50);

    my $lbl_h = Gtk3::Label->new("EDD MEDTRACK");
    $lbl_h->get_style_context->add_class('titulo-sistema');
    $header->pack_start($lbl_h, 0, 0, 5);

    my $lbl_bienvenido = Gtk3::Label->new("");
    $lbl_bienvenido->set_markup(
        '<span color="#c8922a" weight="bold" size="small">Bienvenido, ' .
        $datos->{tipo} . ' — ' . $datos->{nombre} . '</span>'
    );
    $header->pack_end($lbl_bienvenido, 0, 0, 15);
    $vbox->pack_start($header, 0, 0, 0);

    # Contenido
    my $lbl = Gtk3::Label->new("");
    my $contenido = $datos->{rol} eq 'admin'
        ? "Panel de Administrador\n\n" .
          "Próximamente:\n" .
          "  • Carga Masiva JSON\n" .
          "  • Gestionar Equipos (Árbol BST)\n" .
          "  • Gestionar Suministros (Árbol B)\n" .
          "  • Panel Personal Médico (Árbol AVL)\n" .
          "  • Reportes Graphviz"
        : "Panel de Usuario Médico\n\n" .
          "Departamento: " . ($datos->{depto} // "N/A") . "\n" .
          "Tipo: " . $datos->{tipo} . "\n\n" .
          "Próximamente:\n" .
          "  • Consultar Medicamentos\n" .
          "  • Consultar Equipos\n" .
          "  • Consultar Suministros\n" .
          "  • Mi Perfil";

    $lbl->set_markup('<span font="13" color="#1a2f5a">' . $contenido . '</span>');
    $lbl->set_margin_top(30);
    $lbl->set_margin_start(30);
    $lbl->set_halign('start');
    $vbox->pack_start($lbl, 1, 1, 0);

    $win->add($vbox);
    $win->show_all;
}

# ============================================================
# CONSTRUIR VENTANA DE LOGIN
# ============================================================
sub construir_login {

    aplicar_css_login();

    my $window = Gtk3::Window->new('toplevel');
    $window->set_title("EDD MedTrack — Hospital General San Carlos");
    $window->set_default_size(460, 560);
    $window->set_position('center');
    $window->set_resizable(0);
    $window->signal_connect(destroy => sub { Gtk3->main_quit });

    my $vbox_main = Gtk3::Box->new('vertical', 0);

    # ---- HEADER ----
    my $header = Gtk3::Box->new('vertical', 2);
    $header->get_style_context->add_class('header-barra');
    $header->set_size_request(-1, 55);

    my $lbl_titulo = Gtk3::Label->new("EDD MEDTRACK");
    $lbl_titulo->get_style_context->add_class('titulo-sistema');
    $header->pack_start($lbl_titulo, 0, 0, 2);

    my $lbl_sub = Gtk3::Label->new("HOSPITAL GENERAL SAINT CHARLES");
    $lbl_sub->get_style_context->add_class('subtitulo-sistema');
    $header->pack_start($lbl_sub, 0, 0, 0);

    $vbox_main->pack_start($header, 0, 0, 0);

    # ---- NOTEBOOK ----
    my $nb = Gtk3::Notebook->new;
    $nb->set_margin_start(25);
    $nb->set_margin_end(25);
    $nb->set_margin_top(15);
    $nb->set_margin_bottom(15);

    # ====================
    # PESTAÑA 1 — LOGIN
    # ====================
    my $vbox_login = Gtk3::Box->new('vertical', 10);
    $vbox_login->set_margin_start(15);
    $vbox_login->set_margin_end(15);
    $vbox_login->set_margin_top(20);

    my $lbl_login_t = Gtk3::Label->new("");
    $lbl_login_t->set_markup('<span font="18" weight="bold" color="#1a2f5a">INICIAR SESIÓN</span>');
    $vbox_login->pack_start($lbl_login_t, 0, 0, 5);

    my $sep1 = Gtk3::Separator->new('horizontal');
    $vbox_login->pack_start($sep1, 0, 0, 5);

    # Usuario
    my $lbl_u = Gtk3::Label->new("USUARIO / N° DE COLEGIO");
    $lbl_u->set_halign('start');
    $lbl_u->get_style_context->add_class('label-campo');
    $vbox_login->pack_start($lbl_u, 0, 0, 0);

    my $entry_u = Gtk3::Entry->new;
    $entry_u->set_placeholder_text("AdminHospital  ó  COL-XXXXX");
    $entry_u->get_style_context->add_class('entry-campo');
    $vbox_login->pack_start($entry_u, 0, 0, 0);

    # Contraseña
    my $lbl_p = Gtk3::Label->new("CONTRASEÑA");
    $lbl_p->set_halign('start');
    $lbl_p->get_style_context->add_class('label-campo');
    $vbox_login->pack_start($lbl_p, 0, 0, 0);

    my $entry_p = Gtk3::Entry->new;
    $entry_p->set_visibility(0);
    $entry_p->set_placeholder_text("Contraseña institucional");
    $entry_p->get_style_context->add_class('entry-campo');
    $vbox_login->pack_start($entry_p, 0, 0, 0);

    # Error
    my $lbl_err = Gtk3::Label->new("");
    $lbl_err->get_style_context->add_class('lbl-error');
    $vbox_login->pack_start($lbl_err, 0, 0, 0);

    # Botón
    my $btn_login = Gtk3::Button->new_with_label("INGRESAR");
    $btn_login->get_style_context->add_class('btn-ingresar');
    $vbox_login->pack_start($btn_login, 0, 0, 5);

    my $lbl_hint = Gtk3::Label->new("");
    $lbl_hint->set_markup('<span color="#8898aa" size="small">¿Sin cuenta? Regístrate en la pestaña Registro</span>');
    $vbox_login->pack_start($lbl_hint, 0, 0, 0);

    # Lógica login
    my $do_login = sub {
        my $u = $entry_u->get_text;
        my $p = $entry_p->get_text;

        if (!$u || !$p) {
            $lbl_err->set_markup('<span color="#e53e3e">⚠ Complete todos los campos</span>');
            return;
        }

        my $resultado = validar_credenciales_gui($u, $p);
        if ($resultado) {
            $lbl_err->set_text("");
            abrir_panel($window, $resultado);
        } else {
            $lbl_err->set_markup('<span color="#e53e3e">⚠ Credenciales incorrectas</span>');
            $entry_p->set_text("");
        }
    };

    $btn_login->signal_connect(clicked => $do_login);
    $entry_p->signal_connect(activate => $do_login);

    $nb->append_page($vbox_login, Gtk3::Label->new("  Login  "));

    # ====================
    # PESTAÑA 2 — REGISTRO
    # ====================
    my $vbox_reg = Gtk3::Box->new('vertical', 8);
    $vbox_reg->set_margin_start(15);
    $vbox_reg->set_margin_end(15);
    $vbox_reg->set_margin_top(15);

    my $lbl_reg_t = Gtk3::Label->new("");
    $lbl_reg_t->set_markup('<span font="16" weight="bold" color="#1a2f5a">REGISTRO DE USUARIO</span>');
    $vbox_reg->pack_start($lbl_reg_t, 0, 0, 5);

    my $grid = Gtk3::Grid->new;
    $grid->set_row_spacing(8);
    $grid->set_column_spacing(10);

    my @def = (
        ["N° COLEGIO",   "COL-XXXXX",           0],
        ["NOMBRE",       "Nombre completo",      0],
        ["TIPO",         "TIPO-01 ... TIPO-04",  0],
        ["DEPARTAMENTO", "DEP-MED, DEP-CIR...",  0],
        ["ESPECIALIDAD", "Opcional",              0],
        ["CONTRASEÑA",   "Contraseña",           1],
    );

    my @ereg;
    for my $i (0..$#def) {
        my $l = Gtk3::Label->new($def[$i][0]);
        $l->set_halign('end');
        $l->get_style_context->add_class('label-campo');
        $grid->attach($l, 0, $i, 1, 1);

        my $e = Gtk3::Entry->new;
        $e->set_placeholder_text($def[$i][1]);
        $e->set_hexpand(1);
        $e->set_visibility(!$def[$i][2]);
        $e->get_style_context->add_class('entry-campo');
        $grid->attach($e, 1, $i, 1, 1);
        push @ereg, $e;
    }
    $vbox_reg->pack_start($grid, 0, 0, 0);

    my $lbl_msg_reg = Gtk3::Label->new("");
    $vbox_reg->pack_start($lbl_msg_reg, 0, 0, 0);

    my $btn_reg = Gtk3::Button->new_with_label("REGISTRARSE");
    $btn_reg->get_style_context->add_class('btn-registrar');
    $btn_reg->signal_connect(clicked => sub {
        my ($col, $nom, $tipo, $dep, $esp, $pass) = map { $_->get_text } @ereg;

        if (!$col || !$nom || !$tipo || !$dep || !$pass) {
            $lbl_msg_reg->set_markup('<span color="#e53e3e">⚠ Complete los campos obligatorios</span>');
            return;
        }

        # Verificar si ya existe en AVL
        # En Fase 2: if (buscar_avl($col)) { ... }
        if (exists $usuarios{$col}) {
            $lbl_msg_reg->set_markup('<span color="#e53e3e">⚠ N° de colegio ya registrado</span>');
            return;
        }

        # Insertar en AVL
        # En Fase 2: insertar_avl({ numero_colegio=>$col, nombre=>$nom, ... })
        # Por ahora insertamos en %usuarios como placeholder
        $usuarios{$col} = { pass => $pass, role => 'usuario_departamental' };

        $lbl_msg_reg->set_markup('<span color="#38a169">✓ Registrado exitosamente. Ya puede iniciar sesión.</span>');
        $_->set_text("") for @ereg;
    });
    $vbox_reg->pack_start($btn_reg, 0, 0, 5);

    $nb->append_page($vbox_reg, Gtk3::Label->new("  Registro  "));

    # ====================
    # PESTAÑA 3 — INFO
    # ====================
    my $vbox_info = Gtk3::Box->new('vertical', 10);
    $vbox_info->set_margin_start(20);
    $vbox_info->set_margin_end(20);
    $vbox_info->set_margin_top(20);

    my $lbl_info_t = Gtk3::Label->new("");
    $lbl_info_t->set_markup('<span font="13" weight="bold" color="#1a2f5a">INFORMACIÓN DEL SISTEMA</span>');
    $vbox_info->pack_start($lbl_info_t, 0, 0, 10);

    my $lbl_info = Gtk3::Label->new("");
    $lbl_info->set_markup(
        "<b>Sistema:</b> EDD MedTrack F2 EST\n" .
        "<b>Curso:</b> Estructuras de Datos\n" .
        "<b>Universidad:</b> San Carlos de Guatemala\n" .
        "<b>Facultad:</b> Ingeniería en Ciencias y Sistemas\n\n" .
        "<b>Estudiante:</b> ESCRIBE TU NOMBRE\n" .
        "<b>Carnet:</b> 202XXXXXX\n" .
        "<b>Sección:</b> X\n\n" .
        "<b>Estructuras Fase 1:</b>\n" .
        "  • Lista doblemente enlazada — Medicamentos\n" .
        "  • Lista circular simple — Proveedores\n" .
        "  • Lista circular doble — Solicitudes\n" .
        "  • Matriz dispersa — Lab/Medicina\n\n" .
        "<b>Estructuras Fase 2 (nuevas):</b>\n" .
        "  • Árbol AVL — Personal médico\n" .
        "  • Árbol BST — Equipos médicos\n" .
        "  • Árbol B Orden 4 — Suministros"
    );
    $lbl_info->set_halign('start');
    $lbl_info->set_line_wrap(1);
    $vbox_info->pack_start($lbl_info, 0, 0, 0);

    $nb->append_page($vbox_info, Gtk3::Label->new("  Información  "));

    # ---- Ensamblar ----
    $vbox_main->pack_start($nb, 1, 1, 0);
    $window->add($vbox_main);
    $window->show_all;
}

1;
