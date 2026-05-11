# =============================================================================
# hyprland/default.nix
# Module Home Manager pour Hyprland
# Importer depuis home.nix avec : imports = [ ./hyprland/default.nix ];
# =============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    ./waybar.nix
    ./wofi.nix
    ./mako.nix
    ./hypridle.nix
    ./hyprlock.nix
  ];

  # ---------------------------------------------------------------------------
  # Paquets spécifiques à l'environnement Wayland/Hyprland
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Wayland essentiels
    hyprpaper            # fond d'écran Hyprland
    hyprpicker           # color picker
    wl-clipboard         # copier/coller Wayland (wl-copy / wl-paste)
    cliphist             # historique clipboard Wayland
    wlr-randr            # gestion moniteurs wlroots (alternative à xrandr)
    xorg.xrandr          # compatibilité XWayland

    # Screenshots
    grim                 # capture d'écran Wayland
    slurp                # sélection de zone pour grim

    # Utilitaires bureau
    swww                 # fond d'écran animé (alternative à hyprpaper)
    dunst                # fallback notification (mako est préféré)
    brightnessctl        # contrôle de la luminosité
    pamixer              # contrôle du volume PulseAudio/PipeWire
    playerctl            # contrôle media (play/pause/next)

    # Polkit (authentification graphique)
    polkit_gnome         # agent polkit GTK

    # Divers
    libnotify            # commande notify-send
    xdg-utils            # xdg-open etc.
    qt5.qtwayland        # support Qt5 Wayland
    qt6.qtwayland        # support Qt6 Wayland
  ];

  # ---------------------------------------------------------------------------
  # Hyprland via Home Manager
  # Note : on utilise le paquet nixpkgs standard.
  # Pour le paquet officiel hyprland avec les dernières features, tu peux
  # ajouter l'input hyprland flake dans flake.nix et remplacer par :
  # wayland.windowManager.hyprland.package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;

    # Activer XWayland pour les apps X11 (Wireshark, certains outils réseau, etc.)
    xwayland.enable = true;

    # Configuration principale — générée depuis hyprland.conf (extraConfig)
    # On utilise extraConfig pour garder la syntaxe native Hyprland lisible
    extraConfig = builtins.readFile ./hyprland.conf;

    # Variables d'environnement spécifiques à la session Hyprland
    systemd.enable = true;  # intégration systemd (permet notify-sd, portals, etc.)
  };

  xdg.configFile."hypr/scripts/wallpaper.sh" = {
    source = ./scripts/wallpaper.sh;
    executable = true;
  };

  xdg.configFile."hypr/scripts/power-menu.sh" = {
    source = ./scripts/power-menu.sh;
    executable = true;
  };

  xdg.configFile."hypr/scripts/workspace-next.sh" = {
    source = ./scripts/workspace-next.sh;
    executable = true;
  };

  xdg.configFile."hypr/scripts/workspace-prev.sh" = {
    source = ./scripts/workspace-prev.sh;
    executable = true;
  };

  # ---------------------------------------------------------------------------
  # XDG Desktop Portals — requis pour screen sharing, file picker, etc.
  # ---------------------------------------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland   # portail natif Hyprland (screen share)
      xdg-desktop-portal-gtk        # portail GTK (file picker, etc.)
    ];
    config.common.default = "*";
  };

  # ---------------------------------------------------------------------------
  # Variables d'environnement session (écrites dans ~/.config/environment.d/)
  # ---------------------------------------------------------------------------
  home.sessionVariables = {
    # Forcer Wayland pour les apps qui le supportent
    NIXOS_OZONE_WL     = "1";    # Electron (VSCode, etc.) — pas utilisé mais bon à avoir
    MOZ_ENABLE_WAYLAND = "1";    # Firefox
    QT_QPA_PLATFORM    = "wayland;xcb";  # Qt : Wayland avec fallback XCB
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND        = "wayland,x11";  # GTK
    SDL_VIDEODRIVER    = "wayland";
    CLUTTER_BACKEND    = "wayland";

    # Curseur (cohérent avec Sweet-cursors configuré ailleurs)
    XCURSOR_THEME = "Sweet-cursors";
    XCURSOR_SIZE  = "24";

    # XDG
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE    = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # ---------------------------------------------------------------------------
  # Autostart via systemd user services
  # polkit agent — nécessaire pour sudo graphique (virt-manager, etc.)
  # ---------------------------------------------------------------------------
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description     = "Polkit GNOME Authentication Agent";
      After           = [ "graphical-session.target" ];
      PartOf          = [ "graphical-session.target" ];
      WantedBy        = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
