# =============================================================================
# hyprland/hypridle.nix
# Gestion de la mise en veille / économie d'énergie
# hypridle surveille l'inactivité et déclenche des actions
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.hypridle = {
    enable  = true;
    package = pkgs.hypridle;

    settings = {
      general = {
        # Éviter de se locker si un media est en cours de lecture
        lock_cmd         = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd  = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          # Après 5 min : baisser la luminosité
          timeout  = 300;
          on-timeout = "brightnessctl -s set 10%";
          on-resume  = "brightnessctl -r";   # restaurer la luminosité précédente
        }
        {
          # Après 8 min : verrouiller l'écran
          timeout    = 480;
          on-timeout = "loginctl lock-session";
        }
        {
          # Après 10 min : éteindre les écrans
          timeout    = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume  = "hyprctl dispatch dpms on";
        }
        {
          # Après 30 min : mise en veille système
          timeout    = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
