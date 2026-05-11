# Hyprland — intégration nix-config

Stack cible : Pop!_OS 24.04 · Nix + Home Manager standalone · COSMIC desktop existant

---

## Arborescence

```
modules/hyprland/
├── default.nix        # module principal : paquets, wayland.windowManager, portals, polkit
├── hyprland.conf      # config native Hyprland (moniteurs, keybinds, windowrules)
├── waybar.nix         # barre de statut — thème Tokyo Night
├── wofi.nix           # launcher Super+Space
├── mako.nix           # notifications Wayland
├── idle.nix           # hypridle : veille progressive
├── lock.nix           # hyprlock : écran de verrouillage
└── HOME_NIX_DIFF.txt  # diff minimal à appliquer dans home.nix
```

---

## Installation

### 1. Copier le module dans ton repo

```bash
cp -r modules/hyprland/ ~/nix-config/modules/
```

### 2. Modifier home.nix (une ligne)

```nix
imports = [
  ./modules/hyprland/default.nix   # ← ajouter
];
```

### 3. Appliquer

```bash
home-manager switch
```

---

## Coexistence COSMIC ↔ Hyprland

Pop!_OS 24.04 utilise **COSMIC Greeter**. Hyprland installe son fichier de session dans :

```
~/.nix-profile/share/wayland-sessions/hyprland.desktop
```

**Si Hyprland n'apparaît pas dans le greeter**, créer un lien symbolique :

```bash
sudo ln -sf \
  ~/.nix-profile/share/wayland-sessions/hyprland.desktop \
  /usr/share/wayland-sessions/hyprland.desktop
```

Ce lien survit aux `home-manager switch` tant que le chemin du profil ne change pas.
Pour l'automatiser proprement, l'ajouter dans un script d'activation ou un `home.activation` :

```nix
# Dans home.nix, en dehors du module Hyprland
home.activation.hyprlandSession = lib.hm.dag.entryAfter ["writeBoundary"] ''
  ln -sf $HOME/.nix-profile/share/wayland-sessions/hyprland.desktop \
    /usr/share/wayland-sessions/hyprland.desktop 2>/dev/null || true
'';
```

---

## Ajustements post-installation

### Moniteurs

```bash
# Lister les sorties disponibles
hyprctl monitors

# Exemple dans hyprland.conf pour deux écrans :
# monitor = DP-1,   2560x1440@144, 0x0,    1
# monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1
```

### Température CPU (waybar.nix)

```bash
# Trouver le bon capteur
ls /sys/class/hwmon/*/temp1_input
# Adapter hwmon-path dans waybar.nix en conséquence
```

### Fond d'écran

Déposer une image dans `~/Images/wallpaper.jpg` (chemin dans `default.nix` → `hyprpaper.conf`).

### virt-manager (apt)

Aucune action. Le polkit GNOME est autostarté via systemd user. Les windowrules dans
`hyprland.conf` ouvrent virt-manager en flottant centré (1200×820).

### Wireshark (Nix)

Règle flottante 1400×900 centrée définie dans `hyprland.conf`.

### Neovim

`caps:escape` dans `kb_options` transforme CapsLock → Escape pour toute la session.

---

## Commandes de debug courantes

```bash
hyprctl reload              # recharger la config sans relancer Hyprland
hyprctl clients             # lister les fenêtres (class, title) — utile pour windowrules
hyprctl monitors            # lister les moniteurs et leurs noms
hyprctl activewindow        # infos sur la fenêtre en focus
hyprctl dispatch ...        # exécuter une action Hyprland (test keybind)
journalctl --user -u hyprland --since "5 min ago"   # logs session
```

---

## Keybindings résumé

| Raccourci | Action |
|---|---|
| `Super+Return` | Kitty (terminal backup) |
| `Super+Shift+Return` | Tabby (terminal principal) |
| `Super+Space` | Wofi launcher |
| `Super+Q` | Fermer fenêtre |
| `Super+F` | Plein écran |
| `Super+T` | Bascule flottant/tiling |
| `Super+L` | Verrouiller l'écran |
| `Super+H/J/K/L` | Focus Vim-style |
| `Super+Shift+H/J/K/L` | Déplacer fenêtre |
| `Super+Ctrl+H/J/K/L` | Redimensionner |
| `Super+1…0` | Workspace 1–10 |
| `Super+Shift+1…0` | Envoyer vers workspace |
| `Super+S` | Scratchpad (toggle) |
| `Super+V` | Historique clipboard (wofi) |
| `Print` | Capture zone → clipboard |
| `Shift+Print` | Capture plein écran → fichier |
