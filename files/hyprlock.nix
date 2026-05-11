# =============================================================================
# hyprland/hyprlock.nix
# Écran de verrouillage Wayland natif Hyprland
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.hyprlock = {
    enable  = true;
    package = pkgs.hyprlock;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor         = true;
        grace               = 0;      # délai avant que le lock soit actif (secondes)
        no_fade_in          = false;
      };

      # ---- Fond d'écran ----
      background = [{
        monitor    = "";     # "" = tous les moniteurs
        # Utiliser une image de fond si disponible, sinon couleur unie
        # path = "/home/$USER/.config/hypr/wallpaper.jpg";
        color      = "rgba(26, 27, 38, 1.0)";    # Tokyo Night bg
        blur_size  = 7;
        blur_passes = 3;
        noise      = 0.02;
        contrast   = 1.0;
        brightness = 0.7;
        vibrancy   = 0.2;
      }];

      # ---- Champ de saisie mot de passe ----
      input-field = [{
        monitor  = "";
        size     = "280, 48";
        position = "0, -80";
        halign   = "center";
        valign   = "center";

        outline_thickness = 2;
        dots_size         = 0.26;
        dots_spacing      = 0.64;
        dots_center       = true;

        outer_color  = "rgba(122, 162, 247, 0.8)";
        inner_color  = "rgba(36, 40, 59, 0.9)";
        font_color   = "rgb(192, 202, 245)";

        fade_on_empty    = true;
        fade_timeout     = 1000;
        placeholder_text = "<i>Mot de passe...</i>";
        hide_input       = false;

        rounding    = 8;
        check_color = "rgb(158, 206, 106)";
        fail_color  = "rgb(247, 118, 142)";
        fail_text   = "<i>$FAIL ($ATTEMPTS)</i>";
        fail_timeout = 2000;
        capslock_color = "rgb(224, 175, 104)";
      }];

      # ---- Texte : heure ----
      label = [
        {
          monitor  = "";
          text     = "cmd[update:60000] date '+%H:%M'";
          color    = "rgba(192, 202, 245, 0.9)";
          font_size = 72;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 100";
          halign   = "center";
          valign   = "center";
        }
        # ---- Texte : date ----
        {
          monitor  = "";
          text     = "cmd[update:3600000] date '+%A %d %B %Y'";
          color    = "rgba(122, 162, 247, 0.8)";
          font_size = 20;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 20";
          halign   = "center";
          valign   = "center";
        }
      ];
    };
  };
}
