# Hyprland — Intégration dans nix-config

## Structure

```
hyprland/
├── default.nix           # Module principal : paquets, wayland.windowManager, portals
├── hyprland.conf         # Config native Hyprland (moniteurs, keybinds, règles fenêtres)
├── waybar.nix            # Barre de statut
├── waybar/
│   └── style.css         # Thème Tokyo Night
├── wofi.nix              # Launcher (Super+Space)
├── mako.nix              # Notifications
├── hypridle.nix          # Veille / économie énergie
├── hyprlock.nix          # Écran de verrouillage
├── PATCH_home.nix.txt    # Instructions pour modifier home.nix
└── README.md             # Ce fichier
```

---

## Installation

### 1. Copier ce répertoire dans ton repo

```bash
cp -r hyprland/ ~/nix-config/
```

### 2. Modifier home.nix

Ajouter l'import en haut du fichier :

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hyprland/default.nix    # <-- ajouter
    # ... tes autres imports
  ];
  # ...
}
```

### 3. Appliquer

```bash
home-manager switch
```

---

## Coexistence COSMIC / Hyprland

Pop!_OS 24.04 utilise **COSMIC Greeter** (`cosmic-greeter`).  
Hyprland installe son fichier `.desktop` de session dans :
```
~/.nix-profile/share/wayland-sessions/hyprland.desktop
```

Pour que le greeter COSMIC le détecte, vérifier qu'il scanne `~/.nix-profile/share/wayland-sessions/`.  
Si ce n'est pas le cas (greeter ne liste que `/usr/share/wayland-sessions/`), créer un lien :

```bash
sudo ln -s ~/.nix-profile/share/wayland-sessions/hyprland.desktop \
           /usr/share/wayland-sessions/hyprland.desktop
```

> Ce lien symbolique sera à recréer si `home-manager switch` change le profil Nix.  
> Alternative propre : utiliser un module NixOS system-level, mais Pop!_OS n'est pas NixOS.

---

## Points d'attention spécifiques à ta config

### virt-manager / QEMU
Reste entièrement géré par apt — aucun conflit.  
Le polkit GNOME est autostarté via systemd user pour que virt-manager puisse demander les permissions root.  
Les windowrules dans `hyprland.conf` l'ouvrent en flottant centré.

### Wireshark
Windowrule flottante 1400×900 centrée — pratique pour l'analyse de captures.

### Neovim
`caps:escape` dans `kb_options` transforme CapsLock en Escape — confort optimal sous Neovim.

### Kitty vs Tabby
- `Super+Return` → Kitty (terminal Nix, disponible immédiatement)  
- `Super+Shift+Return` → Tabby (géré par .deb, à adapter si le binaire n'est pas dans le PATH)

### Polices
JetBrainsMono Nerd Font est déjà dans ta config Nix — Waybar et hyprlock l'utilisent directement.

---

## Commandes utiles

```bash
# Recharger la config Hyprland sans relancer
hyprctl reload

# Lister les fenêtres ouvertes (pour windowrules)
hyprctl clients

# Lister les moniteurs
hyprctl monitors

# Lister les workspaces
hyprctl workspaces

# Informations de debug
hyprctl version
hyprctl systeminfo
```

---

## Personalisation recommandée

### Fond d'écran
Déposer une image dans `~/.config/hypr/wallpaper.jpg` et ajouter dans `hyprland.conf` :
```ini
exec-once = hyprpaper
```
Créer `~/.config/hypr/hyprpaper.conf` :
```ini
preload = ~/.config/hypr/wallpaper.jpg
wallpaper = ,~/.config/hypr/wallpaper.jpg
```
Ou gérer hyprpaper.conf via Home Manager dans `default.nix` avec `xdg.configFile`.

### Moniteurs multi-écrans
Éditer la section `MONITEURS` dans `hyprland.conf` :
```ini
monitor=DP-1,2560x1440@144,0x0,1
monitor=HDMI-A-1,1920x1080@60,2560x0,1
```
Utiliser `hyprctl monitors` pour connaître les noms exacts.

### Température CPU
Adapter le chemin `hwmon-path` dans `waybar.nix` selon ton système :
```bash
ls /sys/class/hwmon/*/temp1_input
```
