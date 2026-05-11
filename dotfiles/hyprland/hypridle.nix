# =============================================================================
# modules/hyprland/idle.nix
#
# hypridle — démon de gestion de l'inactivité.
# Enchaîne : baisse luminosité → verrouillage → extinction écrans → veille.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  services.hypridle = {
    enable  = true;
    package = pkgs.hypridle;

    settings = {
      general = {
        # Commande de verrouillage : ne pas lancer deux hyprlock en parallèle
        lock_cmd    = "pidof swaylock || /usr/bin/swaylock -f --image ~/.cache/current-wallpaper --scaling fill";

        # Avant la mise en veille système : verrouiller la session
        before_sleep_cmd = "loginctl lock-session";

        # Après réveil : rallumer les écrans
        after_sleep_cmd  = "hyprctl dispatch dpms on";

        # Respecter les inhibiteurs dbus (ex : lecture vidéo plein écran)
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          # Après 4 min d'inactivité : réduire la luminosité
          timeout    = 240;
          on-timeout = "brightnessctl --save set 15%";
          on-resume  = "brightnessctl --restore";
        }
        {
          # Après 7 min : verrouiller l'écran
          timeout    = 420;
          on-timeout = "loginctl lock-session";
        }
        {
          # Après 9 min : éteindre les écrans (DPMS off)
          timeout    = 540;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume  = "hyprctl dispatch dpms on";
        }
        {
          # Après 25 min : mise en veille système
          timeout    = 1500;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
