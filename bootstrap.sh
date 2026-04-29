#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh — Installation complète de l'environnement Nexus Lab
# ==============================================================================
# Usage : bash bootstrap.sh
# À lancer sur un Pop!_OS 24.04 fraîchement installé, en tant qu'utilisateur
# normal (pas root). Le script demande le mot de passe sudo quand nécessaire.
#
# Ce script fait dans l'ordre :
#   1. Paquets apt système (virtualisation, docker, outils système profonds)
#   2. Installation de Nix (multi-user)
#   3. Clone du repo de config
#   4. Application de Home Manager (home.nix)
#   5. Configuration COSMIC desktop
#   6. Installation de Tabby Terminal via .deb
#   7. Installation des Flatpaks résiduels (Flatseal, Chrome, Obsidian, Remmina)
#
# IMPORTANT — avant de lancer ce script :
#   - Copier le dossier wallpapers dans ~/Images/wallpaper/
#   - Avoir le .deb Tabby disponible (clé USB ou ~/Téléchargements/)
#   - Avoir une connexion internet active
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[[ "$EUID" -eq 0 ]] && error "Ne pas lancer ce script en root."

REPO_URL="https://github.com/Caleb-Nexus-Lab/nix-config.git"
CONFIG_DIR="$HOME/nix-config"
USERNAME="$(whoami)"
ORIGINAL_USERNAME="caleb"

# ==============================================================================
# GESTION DU USERNAME
# Si le username sur ce PC est différent de "caleb", on adapte automatiquement
# home.nix et flake.nix avant d'appliquer la config.
# ==============================================================================
adapt_username() {
  if [[ "$USERNAME" == "$ORIGINAL_USERNAME" ]]; then
    info "Username identique ($USERNAME), pas d'adaptation nécessaire."
    return
  fi

  info "Username différent ($ORIGINAL_USERNAME -> $USERNAME), adaptation des fichiers..."

  sed -i \
    -e "s|home.username = \"$ORIGINAL_USERNAME\"|home.username = \"$USERNAME\"|g" \
    -e "s|home.homeDirectory = \"/home/$ORIGINAL_USERNAME\"|home.homeDirectory = \"/home/$USERNAME\"|g" \
    "$CONFIG_DIR/home.nix"

  sed -i \
    "s|homeConfigurations.\"$ORIGINAL_USERNAME\"|homeConfigurations.\"$USERNAME\"|g" \
    "$CONFIG_DIR/flake.nix"

  info "Adaptation terminée."
}

# ==============================================================================
# ÉTAPE 1 — PAQUETS APT SYSTÈME
# Ces paquets restent sous apt car ils s'intègrent profondément au système :
# - virtualisation : modules kernel, daemons systemd, groupes, sockets
# - docker         : daemon système, socket /var/run/docker.sock, groupes
# - dkms           : compilation contre le kernel Pop!_OS
# - tftpd-hpa      : daemon réseau géré par systemd
# ==============================================================================
info "Étape 1 : Installation des paquets apt système..."

sudo apt update && sudo apt install -y \
  virt-manager \
  qemu-system-x86 \
  libvirt-clients \
  libvirt-daemon-system \
  bridge-utils \
  docker.io \
  docker-compose-v2 \
  dkms \
  tftpd-hpa \
  fonts-noto-core \
  fonts-noto-ui-core \
  git \
  curl

info "Ajout de $USERNAME aux groupes libvirt et docker..."
sudo usermod -aG libvirt "$USERNAME"
sudo usermod -aG docker  "$USERNAME"

sudo systemctl enable --now libvirtd
sudo systemctl enable --now docker

# ==============================================================================
# ÉTAPE 2 — INSTALLATION DE NIX (multi-user)
# --daemon installe un daemon root qui gère /nix/store/
# Nécessaire sur une distro non-NixOS pour une installation propre.
# ==============================================================================
info "Étape 2 : Installation de Nix..."

if command -v nix &>/dev/null; then
  warn "Nix est déjà installé ($(nix --version)), on passe."
else
  curl -L https://nixos.org/nix/install | sh -s -- --daemon
  # shellcheck disable=SC1091
  source /etc/profile.d/nix.sh || true
fi

mkdir -p "$HOME/.config/nix"
cat > "$HOME/.config/nix/nix.conf" <<'EOF'
experimental-features = nix-command flakes
EOF

info "Nix version : $(nix --version)"

# ==============================================================================
# ÉTAPE 3 — CLONE DU REPO DE CONFIG
# ==============================================================================
info "Étape 3 : Clonage du repo de config..."

if [[ -d "$CONFIG_DIR" ]]; then
  warn "Le dossier $CONFIG_DIR existe déjà. On fait un git pull."
  git -C "$CONFIG_DIR" pull
else
  git clone "$REPO_URL" "$CONFIG_DIR"
fi

adapt_username

# ==============================================================================
# ÉTAPE 4 — APPLICATION DE HOME MANAGER
# 'nix run' télécharge et exécute home-manager sans l'installer globalement.
# Le #$USERNAME pointe vers homeConfigurations."username" dans flake.nix.
# ==============================================================================
info "Étape 4 : Application de la config Home Manager..."

NIX_ZSH="$HOME/.nix-profile/bin/zsh"

nix run home-manager/release-24.05 -- switch \
  --flake "$CONFIG_DIR#$USERNAME" \
  --extra-experimental-features "nix-command flakes"

# Ajouter zsh Nix à /etc/shells et le définir comme shell par défaut
if ! grep -qF "$NIX_ZSH" /etc/shells 2>/dev/null; then
  echo "$NIX_ZSH" | sudo tee -a /etc/shells
fi
chsh -s "$NIX_ZSH"
info "Shell par défaut : zsh ($NIX_ZSH)"

# ==============================================================================
# ÉTAPE 5 — CONFIG COSMIC DESKTOP
# Les fichiers RON sont copiés directement dans ~/.config/cosmic/.
# Les chemins absolus /home/caleb sont corrigés si le username a changé.
# ==============================================================================
info "Étape 5 : Application de la config COSMIC..."

COSMIC_SRC="$CONFIG_DIR/dotfiles/cosmic"
COSMIC_DST="$HOME/.config/cosmic"

if [[ -d "$COSMIC_SRC" ]]; then
  mkdir -p "$COSMIC_DST"
  cp -r "$COSMIC_SRC"/. "$COSMIC_DST/"

  if [[ "$USERNAME" != "$ORIGINAL_USERNAME" ]]; then
    info "Correction des chemins /home/$ORIGINAL_USERNAME -> /home/$USERNAME..."
    find "$COSMIC_DST" -type f -exec \
      sed -i "s|/home/$ORIGINAL_USERNAME|/home/$USERNAME|g" {} +
  fi

  info "Config COSMIC appliquée."
else
  warn "Dossier dotfiles/cosmic introuvable dans le repo."
fi

# ==============================================================================
# ÉTAPE 6 — TABBY TERMINAL (via .deb)
# Pas dans nixpkgs. Le script cherche le .deb dans les emplacements courants.
# ==============================================================================
info "Étape 6 : Installation de Tabby Terminal..."

TABBY_DEB=""

for path in \
  "$HOME/Téléchargements"/tabby*.deb \
  "$HOME/Downloads"/tabby*.deb \
  "$HOME/Packages-deb"/tabby*.deb \
  /media/"$USERNAME"/*/tabby*.deb \
  /run/media/"$USERNAME"/*/tabby*.deb; do
  if [[ -f "$path" ]]; then
    TABBY_DEB="$path"
    break
  fi
done

if [[ -n "$TABBY_DEB" ]]; then
  info "Fichier .deb trouvé : $TABBY_DEB"
  sudo apt install -y "$TABBY_DEB"
else
  warn "Fichier .deb Tabby non trouvé."
  warn "Télécharge-le sur https://tabby.sh puis lance : sudo apt install ./tabby-*.deb"
fi

# ==============================================================================
# ÉTAPE 7 — FLATPAKS
# - Flatseal  : gestionnaire de permissions Flatpak
# - Chrome    : propriétaire, absent de nixpkgs
# - Obsidian  : pas de paquet nixpkgs officiel stable
# - Remmina   : plugins RDP/VNC mieux gérés en Flatpak
# ==============================================================================
info "Étape 7 : Installation des Flatpaks..."

if ! command -v flatpak &>/dev/null; then
  sudo apt install -y flatpak
fi

flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub \
  com.github.tchx84.Flatseal \
  com.google.Chrome \
  md.obsidian.Obsidian \
  org.remmina.Remmina

# ==============================================================================
# FIN
# ==============================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Bootstrap terminé !${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Prochaines étapes OBLIGATOIRES :"
echo "  1. Redémarrer la session complète"
echo "     -> groupes docker/libvirt actifs + shell zsh chargé"
echo "  2. Après reconnexion, lancer nvim une première fois"
echo "     -> lazy.nvim installe les plugins automatiquement"
echo ""
echo "Optionnel :"
echo "  - Si le thème powerlevel10k ne s'affiche pas bien : p10k configure"
echo "  - Copier les wallpapers dans ~/Images/wallpaper/ si pas déjà fait"
echo ""
if [[ "$USERNAME" != "$ORIGINAL_USERNAME" ]]; then
  warn "Username adapté : $ORIGINAL_USERNAME -> $USERNAME"
  warn "Les fichiers home.nix et flake.nix ont été modifiés localement."
  warn "Si ce PC devient une référence, commite ces changements dans le repo."
fi
