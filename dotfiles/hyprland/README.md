# Hyprland — Installation sur un nouveau système

Config testée sur **Pop!_OS 24.04** avec **cosmic-greeter**.  
La config Nix est entièrement déclarative sauf les étapes ci-dessous qui nécessitent des droits système.

---

## 1. Prérequis système (apt)

```bash
sudo apt install swaylock
```

---

## 2. Fichiers système (sudo requis)

### Session Wayland pour cosmic-greeter
Crée le fichier qui fait apparaître Hyprland dans la roue de connexion :

```bash
sudo tee /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=/home/caleb/.local/bin/hyprland-launch
Type=Application
EOF
```

### PAM — authentification swaylock
```bash
echo "auth include common-auth" | sudo tee /etc/pam.d/swaylock
```

---

## 3. Wrapper EGL (obligatoire sur systèmes non-NixOS)

Hyprland a besoin des drivers Mesa de Nix pour initialiser OpenGL/EGL.

### Trouver le chemin mesa.drivers
```bash
nix build nixpkgs/nixos-24.11#mesa.drivers --no-link --print-out-paths 2>/dev/null
# ou depuis le profil courant après home-manager switch :
ls /nix/store/*-mesa-*-drivers/ 2>/dev/null | head -1
```

### Créer le wrapper
```bash
mkdir -p ~/.local/bin

MESA_PATH=$(ls -d /nix/store/*-mesa-*-drivers 2>/dev/null | head -1)

cat > ~/.local/bin/hyprland-launch << EOF
#!/bin/sh
MESA=${MESA_PATH}
export __EGL_VENDOR_LIBRARY_FILENAMES=\${MESA}/share/glvnd/egl_vendor.d/50_mesa.json
export LIBGL_DRIVERS_PATH=\${MESA}/lib/dri
export LD_LIBRARY_PATH=\${MESA}/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
exec /home/caleb/.nix-profile/bin/Hyprland "\$@"
EOF

chmod +x ~/.local/bin/hyprland-launch
```

---

## 4. Appliquer la config Home Manager

```bash
cd ~/nix-config
home-manager switch --flake .#caleb -b backup
```

---

## 5. Adaptations spécifiques à la machine

### Moniteur — `dotfiles/hyprland/hyprland.conf`
```
monitor = eDP-1, 3000x1876@120, 0x0, 1.333333
```
- Vérifier le nom du connecteur : `hyprctl monitors` ou `wlr-randr`
- Vérifier les modes disponibles : `hyprctl monitors | grep availableModes`
- Adapter résolution, fréquence et scale (seuls les scales dont la résolution est divisible entièrement fonctionnent)

> **Rappel scale valide pour 3000x1876 :** GCD = 4 → scale=2 ou scale=1.333333 uniquement

### Capteur température Waybar — `dotfiles/hyprland/waybar.nix`
```nix
hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
```
- Lister les capteurs disponibles : `ls /sys/class/hwmon/*/temp*_input`
- Vérifier les valeurs : `cat /sys/class/hwmon/hwmon*/temp*_input`

---

## 6. Vérification post-installation

```bash
# Vérifier que le wrapper EGL fonctionne
~/.local/bin/hyprland-launch --version

# Vérifier le scale et la résolution actifs (depuis une session Hyprland)
hyprctl monitors

# Vérifier les services systemd utilisateur
systemctl --user status waybar hypridle
```

---

## Résumé des fichiers hors Nix

| Fichier | Méthode | Raison |
|---|---|---|
| `/usr/share/wayland-sessions/hyprland.desktop` | sudo | Fichier système, cosmic-greeter |
| `/etc/pam.d/swaylock` | sudo | Authentification écran de verrouillage |
| `~/.local/bin/hyprland-launch` | script | Wrapper EGL, chemin Nix store dynamique |
| `swaylock` (binaire) | apt | Le binaire Nix ne peut pas lire /etc/shadow |
