#!/bin/sh
WALLPAPER_DIR="$HOME/Images/wallpaper"
INTERVAL=300

swww-daemon &
sleep 1

while true; do
    img=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)
    if [ -n "$img" ]; then
        swww img "$img" --transition-type wipe --transition-duration 1.5
        ln -sf "$img" "$HOME/.cache/current-wallpaper"
    fi
    sleep "$INTERVAL"
done
