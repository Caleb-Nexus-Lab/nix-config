# =============================================================================
# modules/hyprland/wofi.nix
#
# Launcher d'applications Wayland natif.
# Déclenché par Super+Space (défini dans hyprland.conf).
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.wofi = {
    enable  = true;
    package = pkgs.wofi;

    settings = {
      # Dimensions et position
      width    = "600";
      height   = "420";
      location = "center";

      # Comportement
      insensitive   = true;    # recherche insensible à la casse
      allow_markup  = true;
      allow_images  = true;
      image_size    = 22;
      no_actions    = true;
      gtk_dark      = true;

      # Affichage
      show        = "drun";
      prompt      = "  Rechercher…";
      term        = "kitty";
      halign      = "fill";
      orientation = "vertical";
    };

    style = ''
      /* ========================================================
         Wofi — Tokyo Night
         ======================================================== */
      * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 14px;
      }

      window {
          background-color: #1a1b26;
          border: 2px solid rgba(122, 162, 247, 0.60);
          border-radius: 12px;
      }

      #input {
          background-color: #24283b;
          color: #c0caf5;
          border: none;
          border-radius: 8px;
          padding: 8px 14px;
          margin: 10px 10px 4px 10px;
          outline: none;
          caret-color: #7aa2f7;
      }
      #input:focus {
          border: 1px solid rgba(122, 162, 247, 0.50);
      }

      #scroll   { margin: 4px 8px 8px 8px; }
      #inner-box,
      #outer-box { background: transparent; }

      #entry {
          border-radius: 6px;
          padding: 7px 12px;
          color: #a9b1d6;
          transition: background 0.1s ease;
      }
      #entry:selected {
          background-color: rgba(122, 162, 247, 0.18);
          border-left: 3px solid #7aa2f7;
          color: #c0caf5;
      }
      #entry:hover:not(:selected) {
          background-color: rgba(192, 202, 245, 0.06);
      }

      #text         { color: #a9b1d6; }
      #text:selected { color: #7aa2f7; font-weight: bold; }
    '';
  };
}
