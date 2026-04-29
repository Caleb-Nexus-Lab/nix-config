# nix-config — Environnement Caleb Nexus Lab

Config Home Manager reproductible en une commande sur n'importe quel Pop!_OS 24.04.

## Structure

```
nix-config/
├── flake.nix              # Point d'entrée Nix — dépendances nixpkgs + home-manager
├── home.nix               # Config principale : paquets, shell, git, neovim, kitty…
├── bootstrap.sh           # Script clé USB : installe Nix + applique tout
├── dotfiles/
│   ├── nvim/
│   │   ├── init.lua       # Config Neovim (lazy.nvim + plugins)
│   │   └── lazy-lock.json # Versions verrouillées des plugins nvim
│   ├── kitty/
│   │   ├── kitty.conf     # Config kitty (terminal backup)
│   │   └── current-theme.conf  # Thème Tokyo Night
│   ├── btop/
│   │   └── btop.conf      # Config btop
│   ├── tabby/
│   │   └── config.yaml    # Config Tabby terminal (hotkeys, profils…)
│   └── zsh/
│       ├── .p10k.zsh      # Thème Powerlevel10k (généré par p10k configure)
│       └── .sshrc         # Config shell pour sessions SSH distantes
└── README.md
```

## Premier déploiement (nouveau PC)

```bash
# 1. Copier bootstrap.sh sur le nouveau PC (clé USB, scp, etc.)
# 2. Rendre exécutable et lancer
chmod +x bootstrap.sh
bash bootstrap.sh
```

## Mise à jour de la config

```bash
# Modifier home.nix ou les dotfiles, puis :
home-manager switch --flake ~/nix-config#caleb
```

## Changer de username

Dans `flake.nix` et `home.nix`, remplacer `caleb` par le nouveau username.
Puis dans bootstrap.sh, la variable `USERNAME` est détectée automatiquement via `whoami`.

## Mettre à jour nixpkgs

Dans `flake.nix`, changer `nixos-24.05` en `nixos-24.11` puis :
```bash
nix flake update ~/nix-config
home-manager switch --flake ~/nix-config#caleb
```

## Ce qui reste géré en dehors de Nix

| Outil | Méthode | Raison |
|---|---|---|
| virt-manager / QEMU / libvirt | apt | Modules kernel, daemons systemd, groupes système |
| docker / docker-compose | apt | Daemon système, socket, groupes |
| dkms | apt | Compilation contre le kernel Pop!_OS |
| tftpd-hpa | apt | Daemon système |
| Tabby Terminal | .deb officiel | Pas dans nixpkgs, app Electron avec intégration système |
| Obsidian | Flatpak | Pas de paquet nixpkgs officiel stable |
| Google Chrome | Flatpak | Propriétaire, pas dans nixpkgs |
| Flatseal | Flatpak | Outil de gestion Flatpak — logique en Flatpak |
| Remmina | Flatpak | Plugins RDP/VNC mieux gérés en Flatpak |

## Paquets apt sans équivalent nixpkgs

Ces paquets de ta liste apt n'ont pas d'équivalent nixpkgs utilisable
sur une distro non-NixOS et sont donc ignorés (gérés par Pop!_OS) :

- `kernelstub`, `system76-*`, `linux-system76` — spécifiques System76/Pop!_OS
- `language-pack-*`, `hunspell-*`, `hyphen-*`, `mythes-*` — packs de langues système
- `fonts-arphic-*`, `fonts-noto-cjk*`, `ibus-*` — support CJK non nécessaire
- Toutes les `lib*` — dépendances système gérées par apt automatiquement
- `pop-desktop`, `cosmic-*` — environnement de bureau Pop!_OS
