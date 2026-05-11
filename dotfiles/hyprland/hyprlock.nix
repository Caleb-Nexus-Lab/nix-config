# =============================================================================
# modules/hyprland/lock.nix
#
# hyprlock — écran de verrouillage natif Wayland pour Hyprland.
# Heure en grand, date en dessous, champ mot de passe centré.
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
        grace               = 0;       # délai de grâce en secondes (0 = immédiat)
        no_fade_in          = false;
        no_fade_out         = false;
      };

      # -- Fond d'écran -------------------------------------------------------
      # Utilise la même image que hyprpaper. Avec flou+assombrissement.
      # Remplacer le path si besoin ; `color` est le fallback si l'image est absente.
      background = [{
        monitor = "";                            # "" = tous les moniteurs
        path    = "screenshot";                  # capture l'écran au moment du lock
        # path  = "~/Images/wallpaper.jpg";      # ou une image fixe
        blur_size   = 6;
        blur_passes = 3;
        noise       = 0.015;
        contrast    = 1.0;
        brightness  = 0.65;
        vibrancy    = 0.15;
        color       = "rgba(26, 27, 38, 1.0)";  # fallback si screenshot échoue
      }];

      # -- Heure --------------------------------------------------------------
      label = [
        {
          monitor     = "";
          text        = "cmd[update:60000] date '+%H:%M'";
          color       = "rgba(192, 202, 245, 0.92)";
          font_size   = 80;
          font_family = "JetBrainsMono Nerd Font";
          position    = "0, 130";
          halign      = "center";
          valign      = "center";
        }
        # -- Date ------------------------------------------------------------
        {
          monitor     = "";
          # fr_FR.UTF-8 doit être généré ; si absent, utiliser date '+%A %d %B %Y'
          text        = "cmd[update:3600000] date '+%A %d %B %Y'";
          color       = "rgba(122, 162, 247, 0.75)";
          font_size   = 20;
          font_family = "JetBrainsMono Nerd Font";
          position    = "0, 55";
          halign      = "center";
          valign      = "center";
        }
        # -- Indicateur capslock ----------------------------------------------
        {
          monitor     = "";
          text        = "  CAPS LOCK";
          color       = "rgba(224, 175, 104, 0.90)";
          font_size   = 14;
          font_family = "JetBrainsMono Nerd Font";
          position    = "0, -150";
          halign      = "center";
          valign      = "center";
          # Visible uniquement si CapsLock est actif
          # (hyprlock n'a pas encore de condition native — commenté en attendant)
          # if_conditions = "capslock"
        }
      ];

      # -- Champ mot de passe ------------------------------------------------
      input-field = [{
        monitor  = "";
        size     = "300, 50";
        position = "0, -60";
        halign   = "center";
        valign   = "center";

        # Apparence
        outline_thickness = 2;
        outer_color  = "rgba(122, 162, 247, 0.80)";
        inner_color  = "rgba(36, 40, 59, 0.92)";
        font_color   = "rgb(192, 202, 245)";
        rounding     = 8;

        # Points de saisie
        dots_size    = 0.28;
        dots_spacing = 0.60;
        dots_center  = true;

        # Comportement
        fade_on_empty    = true;
        fade_timeout     = 1200;
        placeholder_text = "<i>Mot de passe…</i>";
        hide_input       = false;

        # Retour visuel
        check_color  = "rgb(158, 206, 106)";    # vert si correct
        fail_color   = "rgb(247, 118, 142)";     # rouge si incorrect
        fail_text    = "<i>Incorrect ($ATTEMPTS)</i>";
        fail_timeout = 2000;

        capslock_color = "rgb(224, 175, 104)";   # orange si CapsLock actif
      }];
    };
  };
}
