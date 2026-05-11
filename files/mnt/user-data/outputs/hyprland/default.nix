# =============================================================================
# modules/hyprland/default.nix
#
# Module Home Manager pour Hyprland — Pop!_OS 24.04 (standalone, non-NixOS)
#
# USAGE : dans home.nix, ajouter :
#   imports = [ ./modules/hyprland/default.nix ];
#
# COEXISTENCE COSMIC : Hyprland et COSMIC restent deux sessions indépendantes
# sélectionnables au greeter. Rien ici ne touche à COSMIC.
#
# HORS NIX (inchangé) : virt-manager, QEMU/libvirt, docker, dkms, tftpd-hpa
# =============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    ./waybar.nix    # barre de statut
    ./wofi.nix      # launcher (Super+Space)
    ./mako.nix      # notifications
    ./idle.nix      # hypridle — veille / économie d'énergie
    ./lock.nix      # hyprlock — écran de verrouillage
  ];

  # ---------------------------------------------------------------------------
  # Paquets Wayland/Hyprland installés dans le profil Home Manager
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # -- Fond d'écran ----------------------------------------------------------
    hyprpaper           # fond d'écran statique natif Hyprland

    # -- Capture d'écran -------------------------------------------------------
    grim                # capture Wayland (plein écran ou zone)
    slurp               # sélection de zone interactive pour grim

    # -- Presse-papiers --------------------------------------------------------
    wl-clipboard        # wl-copy / wl-paste — clipboard Wayland
    cliphist            # historique du clipboard (wofi comme frontend)

    # -- Contrôles système -----------------------------------------------------
    brightnessctl       # luminosité écran (rétroéclairage)
    pamixer             # volume PulseAudio/PipeWire en ligne de commande
    playerctl           # contrôle lecture média (play/pause/next/prev)

    # -- Portails XDG ----------------------------------------------------------
    # Nécessaires pour : screen share, sélecteur de fichiers, xdg-open, etc.
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # -- Compatibilité Qt/GTK sous Wayland -------------------------------------
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct    # thème Qt5
    adwaita-qt          # thème Qt → apparence GTK/Adwaita

    # -- Utilitaires divers ----------------------------------------------------
    wlr-randr           # gestion moniteurs wlroots (équivalent xrandr)
    xorg.xrandr         # compatibilité XWayland
    libnotify           # commande notify-send (scripts)
    xdg-utils           # xdg-open, xdg-mime, etc.

    # -- Agent d'authentification graphique ------------------------------------
    # Requis pour que virt-manager (apt) puisse demander le mot de passe root
    polkit_gnome
  ];

  # ---------------------------------------------------------------------------
  # Hyprland — déclaration Home Manager
  # Utilise le paquet nixpkgs-unstable standard.
  #
  # Pour suivre le flake officiel Hyprland (HEAD, features en avance) :
  #   1. Ajouter dans flake.nix :
  #      inputs.hyprland.url = "github:hyprwm/Hyprland";
  #   2. Passer inputs en extraSpecialArgs du homeManagerConfiguration
  #   3. Remplacer `package` ci-dessous par :
  #      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable  = true;
    package = pkgs.hyprland;

    # XWayland : nécessaire pour Wireshark, freerdp, certaines apps réseau
    xwayland.enable = true;

    # Intégration systemd : expose la session comme target systemd user.
    # Permet aux portails XDG et services (waybar, mako…) de démarrer proprement.
    systemd = {
      enable = true;
      # Variables d'environnement transmises au bus systemd user
      variables = [ "--all" ];
    };

    # La configuration native Hyprland est dans un fichier dédié.
    # `builtins.readFile` lit le fichier au moment du build Nix — il sera
    # intégré verbatim dans ~/.config/hypr/hyprland.conf généré.
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  # ---------------------------------------------------------------------------
  # Portails XDG
  # xdg-desktop-portal-hyprland  → screen share, pipewire camera
  # xdg-desktop-portal-gtk       → sélecteur de fichiers, mime
  # ---------------------------------------------------------------------------
  xdg.portal = {
    enable         = true;
    xdgOpenUsePortal = true;
    extraPortals   = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    # Associer chaque interface au portail correct
    config = {
      hyprland = {
        default               = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Screenshot"  = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast"  = [ "hyprland" ];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Variables d'environnement de session
  # Écrites dans ~/.nix-profile/etc/profile.d/ et sourcées au login
  # ---------------------------------------------------------------------------
  home.sessionVariables = {
    # Activer le backend Wayland pour les apps qui le supportent
    MOZ_ENABLE_WAYLAND          = "1";        # Firefox
    NIXOS_OZONE_WL              = "1";        # Electron (signal, etc.)
    QT_QPA_PLATFORM             = "wayland;xcb";  # Qt5/Qt6 : Wayland avec fallback X11
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";    # Qt : pas de décorations côté client
    GDK_BACKEND                 = "wayland,x11";  # GTK3/4
    SDL_VIDEODRIVER             = "wayland";
    CLUTTER_BACKEND             = "wayland";

    # Curseur — cohérent avec ta config Sweet-cursors existante
    XCURSOR_THEME = "Sweet-cursors";
    XCURSOR_SIZE  = "24";

    # Identité de la session (utile pour certains portails et apps)
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE    = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # ---------------------------------------------------------------------------
  # Service systemd user : agent Polkit GNOME
  # Lance l'agent d'authentification graphique dès que la session graphique
  # est active — requis pour virt-manager, sudo graphique, montage disques, etc.
  # ---------------------------------------------------------------------------
  systemd.user.services.polkit-gnome-agent = {
    Unit = {
      Description = "GNOME Polkit authentication agent";
      After       = [ "graphical-session-pre.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart   = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ---------------------------------------------------------------------------
  # Fichier de config hyprpaper (fond d'écran)
  # Édite `wallpaper` selon ton image. Le chemin est absolu.
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    # Précharger l'image (obligatoire avant de l'affecter)
    preload = ~/Images/wallpaper.jpg

    # Affecter à tous les moniteurs (laisser vide = tous)
    wallpaper = ,~/Images/wallpaper.jpg

    # Splash screen hyprpaper désactivé
    splash = false
  '';
}
