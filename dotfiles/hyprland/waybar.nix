# =============================================================================
# hyprland/waybar.nix
# Barre de statut Waybar — configurée via Home Manager
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    # La config et le style sont dans des fichiers séparés pour plus de lisibilité
    # Ils sont générés dans ~/.config/waybar/
    style = builtins.readFile ./waybar/style.css;

    settings = [{
      # -------------------------------------------------------------------------
      # Barre principale (en haut)
      # -------------------------------------------------------------------------
      layer    = "top";      # au-dessus des fenêtres
      position = "top";
      height   = 32;
      spacing  = 4;

      # Modules à gauche
      modules-left = [
        "hyprland/workspaces"
        "hyprland/submap"
        "hyprland/window"
      ];

      # Modules au centre
      modules-center = [
        "clock"
      ];

      # Modules à droite
      modules-right = [
        "backlight"
        "bluetooth"
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "temperature"
        "battery"
        "tray"
        "custom/power"
      ];

      # -----------------------------------------------------------------------
      # Configuration des modules
      # -----------------------------------------------------------------------

      "hyprland/workspaces" = {
        format          = "{icon}";
        on-scroll-up    = "hyprctl dispatch workspace e+1";
        on-scroll-down  = "hyprctl dispatch workspace e-1";
        format-icons = {
          "1"  = "①";
          "2"  = "②";
          "3"  = "③";
          "4"  = "④";
          "5"  = "⑤";
          "6"  = "⑥";
          "7"  = "⑦";
          "8"  = "⑧";
          "9"  = "⑨";
          "10" = "⑩";
          urgent  = "";
          active  = "";
          default = "";
        };
        persistent-workspaces = {
          "*" = 5;    # afficher 5 workspaces permanents sur tous les moniteurs
        };
      };

      "hyprland/submap" = {
        format    = "<span style='italic'>  {}</span>";
        max-length = 20;
        tooltip   = false;
      };

      "hyprland/window" = {
        max-length = 60;
        separate-outputs = true;
      };

      clock = {
        timezone  = "Europe/Paris";
        format    = " {:%H:%M}";
        format-alt = " {:%A %d %B %Y}";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>";
        interval  = 60;
      };

      cpu = {
        format   = " {usage}%";
        tooltip  = true;
        interval = 2;
        on-click = "kitty --hold -e btop";
      };

      memory = {
        format   = " {used:0.1f}G";
        tooltip-format = "RAM : {used:0.1f}G / {total:0.1f}G\nSwap : {swapUsed:0.1f}G / {swapTotal:0.1f}G";
        interval = 5;
        on-click = "kitty --hold -e btop";
      };

      temperature = {
        # Adapter le thermal-zone si nécessaire (voir /sys/class/thermal/)
        # thermal-zone = 2;
        hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
        critical-threshold = 80;
        format-critical = " {temperatureC}°C";
        format = " {temperatureC}°C";
        interval = 5;
        tooltip = false;
      };

      network = {
        format-wifi         = " {signalStrength}%";
        format-ethernet     = " {ipaddr}";
        format-disconnected = "⚠ Déconnecté";
        format-linked       = " {ifname} (pas d'IP)";
        tooltip-format-wifi = "{essid} ({signalStrength}%) \n {ipaddr}/{cidr}";
        tooltip-format-ethernet = "{ifname}\n {ipaddr}/{cidr}";
        on-click = "kitty --hold -e nmtui";
        interval = 5;
      };

      pulseaudio = {
        format            = "{icon} {volume}%";
        format-bluetooth  = "{icon} {volume}% ";
        format-muted      = "  muet";
        format-icons = {
          headphone   = "";
          headset     = "";
          phone       = "";
          portable    = "";
          car         = "";
          default     = [ "" "" "" ];
        };
        on-click = "pavucontrol";
        scroll-step = 5;
      };

      battery = {
        states = {
          good     = 95;
          warning  = 30;
          critical = 15;
        };
        format             = "{icon} {capacity}%";
        format-charging    = " {capacity}%";
        format-plugged     = " {capacity}%";
        format-icons       = [ "" "" "" "" "" ];
        tooltip-format     = "{timeTo} — {capacity}%";
      };

      tray = {
        icon-size   = 18;
        spacing     = 8;
        show-passive-items = true;
      };

      backlight = {
        format      = "{icon} {percent}%";
        format-icons = [ "" "" "" "" "" "" "" "" "" ];
        on-scroll-up   = "brightnessctl set +5%";
        on-scroll-down = "brightnessctl set 5%-";
        tooltip = false;
      };

      bluetooth = {
        format            = " {status}";
        format-connected  = " {device_alias}";
        format-disabled   = "󰂲";
        tooltip-format    = "{controller_alias} — {controller_address}";
        tooltip-format-connected = "{controller_alias}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "  {device_alias}";
        on-click          = "/usr/bin/blueman-manager";
      };

      "custom/power" = {
        format   = "⏻";
        tooltip  = false;
        on-click = "~/.config/hypr/scripts/power-menu.sh";
      };
    }];
  };
}
