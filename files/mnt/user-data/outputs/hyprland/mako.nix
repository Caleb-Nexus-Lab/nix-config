# =============================================================================
# modules/hyprland/mako.nix
#
# Daemon de notifications Wayland natif.
# Thème Tokyo Night avec urgence critique en rouge.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable  = true;
    package = pkgs.mako;

    # Apparence générale
    font            = "JetBrainsMono Nerd Font 11";
    backgroundColor = "#1a1b26ee";    # Tokyo Night, semi-transparent
    textColor       = "#c0caf5";
    borderColor     = "#7aa2f7";
    borderRadius    = 8;
    borderSize      = 2;

    # Dimensions et position
    width   = 380;
    height  = 130;
    margin  = "10";
    padding = "12,16";
    anchor  = "top-right";

    # Comportement
    defaultTimeout  = 5000;     # 5 s par défaut
    ignoreTimeout   = false;
    maxVisible      = 5;
    sort            = "-time";  # plus récent en haut

    # Icônes
    icons       = true;
    maxIconSize = 48;

    # Règles par urgence
    extraConfig = ''
      # Notifications critiques : fond rouge, pas de timeout automatique
      [urgency=critical]
      background-color=#2d1b1e
      border-color=#f7768e
      text-color=#f7768e
      default-timeout=0

      # Notifications basses : plus discrètes
      [urgency=low]
      background-color=#1a1b26cc
      border-color=#414868
      text-color=#565f89
      default-timeout=3000
    '';
  };
}
