# =============================================================================
# modules/hyprland/waybar.nix
#
# Barre de statut Waybar configurée via Home Manager.
# Thème Tokyo Night — cohérent avec kitty et le reste de ta config.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable  = true;
    package = pkgs.waybar;

    # -------------------------------------------------------------------------
    # Style CSS — Tokyo Night
    # -------------------------------------------------------------------------
    style = ''
      /* Police : JetBrainsMono Nerd Font (installée via Nix) */
      * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 13px;
          min-height: 0;
          border: none;
          border-radius: 0;
          box-sizing: border-box;
      }

      /* Fenêtre principale */
      window#waybar {
          background-color: rgba(26, 27, 38, 0.93);  /* Tokyo Night #1a1b26 */
          color: #c0caf5;
          border-bottom: 2px solid rgba(122, 162, 247, 0.25);
      }

      /* Conteneurs gauche / centre / droite */
      .modules-left,
      .modules-center,
      .modules-right {
          padding: 0 6px;
      }

      /* Hover générique */
      button:hover {
          background: rgba(122, 162, 247, 0.12);
          border-bottom: 2px solid #7aa2f7;
      }

      /* ------------------------------------------------------------------ */
      /* Workspaces                                                           */
      /* ------------------------------------------------------------------ */
      #workspaces button {
          padding: 0 8px;
          color: #414868;
          background: transparent;
          transition: all 0.15s ease;
          border-bottom: 2px solid transparent;
      }
      #workspaces button.active {
          color: #7aa2f7;
          border-bottom: 2px solid #7aa2f7;
          background: rgba(122, 162, 247, 0.10);
      }
      #workspaces button.urgent {
          color: #f7768e;
          border-bottom: 2px solid #f7768e;
          background: rgba(247, 118, 142, 0.10);
      }
      #workspaces button:hover {
          color: #c0caf5;
          border-bottom: 2px solid #565f89;
      }

      /* ------------------------------------------------------------------ */
      /* Fenêtre active                                                       */
      /* ------------------------------------------------------------------ */
      #window {
          color: #9ece6a;
          padding: 0 14px;
          font-style: italic;
      }

      /* ------------------------------------------------------------------ */
      /* Horloge                                                              */
      /* ------------------------------------------------------------------ */
      #clock {
          color: #e0af68;
          font-weight: bold;
          padding: 0 16px;
      }

      /* ------------------------------------------------------------------ */
      /* Modules droite                                                       */
      /* ------------------------------------------------------------------ */
      #cpu        { color: #7dcfff; padding: 0 10px; }
      #memory     { color: #9ece6a; padding: 0 10px; }
      #temperature { color: #ff9e64; padding: 0 10px; }
      #network    { color: #2ac3de; padding: 0 10px; }
      #pulseaudio { color: #bb9af7; padding: 0 10px; }
      #battery    { padding: 0 10px; }
      #tray       { padding: 0 8px; }

      #temperature.critical {
          color: #f7768e;
          animation: blink 1s step-end infinite;
      }
      #battery.warning  { color: #e0af68; }
      #battery.critical { color: #f7768e; animation: blink 1s step-end infinite; }
      #battery.charging { color: #9ece6a; }
      #network.disconnected { color: #f7768e; }

      /* Submap (mode spécial actif) */
      #submap {
          color: #f7768e;
          background: rgba(247, 118, 142, 0.15);
          padding: 0 10px;
          border-radius: 4px;
          font-style: italic;
      }

      tooltip {
          background: rgba(26, 27, 38, 0.97);
          border: 1px solid rgba(122, 162, 247, 0.35);
          border-radius: 6px;
          color: #c0caf5;
      }

      @keyframes blink {
          to { opacity: 0.4; }
      }
    '';

    # -------------------------------------------------------------------------
    # Configuration des modules
    # -------------------------------------------------------------------------
    settings = [{
      layer    = "top";
      position = "top";
      height   = 32;
      spacing  = 4;

      modules-left   = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right  = [ "cpu" "memory" "temperature" "network" "pulseaudio" "battery" "tray" ];

      # -- Workspaces --
      "hyprland/workspaces" = {
        format       = "{icon}";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        # Icônes numériques nerdfont pour les workspaces
        format-icons = {
          "1" = "󰲡"; "2" = "󰲣"; "3" = "󰲥"; "4" = "󰲧"; "5" = "󰲩";
          "6" = "󰲫"; "7" = "󰲭"; "8" = "󰲯"; "9" = "󰲱"; "10" = "󰿬";
          urgent  = "󰀧";
          active  = "";
          default = "";
        };
        # Afficher 5 workspaces permanents même s'ils sont vides
        persistent-workspaces = { "*" = 5; };
      };

      "hyprland/submap" = {
        format     = "  {}";
        max-length = 25;
        tooltip    = false;
      };

      "hyprland/window" = {
        max-length       = 55;
        separate-outputs = true;
      };

      # -- Horloge --
      clock = {
        timezone      = "Europe/Paris";
        format        = "  {:%H:%M}";
        format-alt    = "  {:%a %d %B %Y}";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        interval      = 60;
      };

      # -- CPU --
      cpu = {
        format   = "  {usage}%";
        interval = 2;
        tooltip  = true;
        on-click = "kitty --hold -e btop";   # ouvrir btop au clic
      };

      # -- Mémoire --
      memory = {
        format         = "  {used:0.1f}G";
        tooltip-format = "RAM : {used:0.1f}G/{total:0.1f}G  Swap : {swapUsed:0.1f}G/{swapTotal:0.1f}G";
        interval       = 5;
        on-click       = "kitty --hold -e btop";
      };

      # -- Température CPU --
      # Adapter hwmon-path selon ton matériel : `ls /sys/class/hwmon/*/temp1_input`
      temperature = {
        hwmon-path        = "/sys/class/hwmon/hwmon1/temp1_input";
        critical-threshold = 80;
        format-critical   = "  {temperatureC}°C";
        format            = "  {temperatureC}°C";
        interval          = 5;
        tooltip           = false;
      };

      # -- Réseau --
      network = {
        format-ethernet     = "  {ipaddr}";
        format-wifi         = "  {signalStrength}%";
        format-disconnected = "󰤭  Déconnecté";
        format-linked       = "  {ifname} (sans IP)";
        tooltip-format-wifi     = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}";
        tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}";
        on-click = "kitty --hold -e nmtui";
        interval = 5;
      };

      # -- Volume --
      pulseaudio = {
        format         = "{icon}  {volume}%";
        format-muted   = "󰝟  muet";
        format-icons   = { default = [ "" "" "󰕾" ]; headphone = ""; };
        on-click       = "pavucontrol";
        scroll-step    = 5;
        tooltip-format = "{desc} — {volume}%";
      };

      # -- Batterie (si laptop) --
      battery = {
        states         = { good = 95; warning = 30; critical = 15; };
        format         = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-plugged  = "󰚥  {capacity}%";
        format-icons    = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        tooltip-format  = "{timeTo}  —  {capacity}%";
      };

      # -- Systray --
      tray = {
        icon-size          = 18;
        spacing            = 8;
        show-passive-items = true;
      };
    }];
  };
}
