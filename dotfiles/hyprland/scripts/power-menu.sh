#!/bin/sh
LOCK=" Verrouiller"
SUSPEND="󰒲 Suspendre"
LOGOUT=" Déconnecter"
REBOOT=" Redémarrer"
SHUTDOWN=" Éteindre"

CHOICE=$(printf '%s\n' "$LOCK" "$SUSPEND" "$LOGOUT" "$REBOOT" "$SHUTDOWN" \
    | wofi --dmenu --prompt "  Système" --lines 5 --width 220)

case "$CHOICE" in
    "$LOCK")     hyprlock ;;
    "$SUSPEND")  systemctl suspend ;;
    "$LOGOUT")   hyprctl dispatch exit ;;
    "$REBOOT")   systemctl reboot ;;
    "$SHUTDOWN") systemctl poweroff ;;
esac
