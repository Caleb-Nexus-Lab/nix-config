# =============================================================================
# hyprland/wofi.nix
# Launcher d'applications Wayland (remplaçant de rofi)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.wofi = {
    enable  = true;
    package = pkgs.wofi;

    settings = {
      # ---- Apparence ----
      width         = "600";
      height        = "400";
      location      = "center";
      no_actions    = true;
      halign        = "fill";
      orientation   = "vertical";
      content_halign = "fill";
      insensitive   = true;   # recherche insensible à la casse
      allow_markup  = true;
      allow_images  = true;
      image_size    = 24;
      gtk_dark      = true;   # forcer thème GTK sombre

      # ---- Comportement ----
      show     = "drun";
      prompt   = " Rechercher...";
      term     = "kitty";
    };

    style = ''
      /* Wofi — Tokyo Night */
      * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
      }

      window {
          background-color: #1a1b26;
          border: 2px solid #7aa2f7;
          border-radius: 12px;
      }

      #input {
          background-color: #24283b;
          color: #c0caf5;
          border: none;
          border-radius: 8px;
          padding: 8px 12px;
          margin: 8px;
          outline: none;
      }

      #input:focus {
          border: 1px solid #7aa2f7;
      }

      #scroll {
          margin: 0 8px 8px 8px;
      }

      #inner-box {
          background: transparent;
      }

      #outer-box {
          background: transparent;
      }

      #entry {
          border-radius: 6px;
          padding: 6px 10px;
          color: #c0caf5;
      }

      #entry:selected {
          background-color: rgba(122, 162, 247, 0.2);
          color: #7aa2f7;
          border-left: 3px solid #7aa2f7;
      }

      #entry:hover {
          background-color: rgba(192, 202, 245, 0.08);
      }

      #text {
          color: #c0caf5;
      }

      #text:selected {
          color: #7aa2f7;
      }
    '';
  };
}
