# =============================================================================
# hyprland/mako.nix
# Daemon de notifications Wayland
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable  = true;
    package = pkgs.mako;

    # ---- Apparence ----
    font            = "JetBrainsMono Nerd Font 11";
    backgroundColor = "#1a1b26ee";   # Tokyo Night bg, semi-transparent
    textColor       = "#c0caf5";
    borderColor     = "#7aa2f7";
    borderRadius    = 8;
    borderSize      = 2;

    # ---- Dimensions ----
    width   = 380;
    height  = 120;
    margin  = "10";
    padding = "12,16";

    # ---- Comportement ----
    defaultTimeout = 5000;   # 5 secondes
    ignoreTimeout  = false;
    maxVisible     = 5;

    # ---- Position ----
    anchor = "top-right";

    # ---- Icônes ----
    icons  = true;
    maxIconSize = 48;

    # ---- Critère : urgence critique → pas de timeout ----
    extraConfig = ''
      [urgency=critical]
      background-color=#f7768eee
      border-color=#f7768e
      text-color=#1a1b26
      default-timeout=0
    '';
  };
}
