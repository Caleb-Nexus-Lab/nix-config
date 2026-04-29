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
#   5. Icônes et curseur (candy-icons, Sweet-cursors)
#   6. Configuration COSMIC desktop (thème, raccourcis, wallpaper)
#   7. Installation de Tabby Terminal via .deb
#   8. Installation des Flatpaks (Flatseal, Chrome, Obsidian, Remmina)
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
# home.nix, flake.nix et la config COSMIC avant d'appliquer.
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
  zsh \
  git \
  tio \
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
  # Nettoyer les éventuelles traces d'une install avortée
  sudo rm -f /etc/bash.bashrc.backup-before-nix
  sudo rm -f /etc/zsh/zshrc.backup-before-nix

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

# Ajouter zsh Nix à /etc/shells et le définir comme shell par défaut.
# On utilise usermod qui est plus fiable que chsh sur Pop!_OS.
if ! grep -qF "$NIX_ZSH" /etc/shells 2>/dev/null; then
  echo "$NIX_ZSH" | sudo tee -a /etc/shells
fi
sudo usermod -s "$NIX_ZSH" "$USERNAME"
info "Shell par défaut : zsh ($NIX_ZSH)"

# ==============================================================================
# ÉTAPE 5 — ICÔNES ET CURSEUR
# candy-icons et Sweet-cursors sont versionnés dans assets/icons/ du repo.
# Ils sont copiés dans /usr/share/icons/ (système) pour être disponibles
# pour tous les utilisateurs et pour COSMIC qui lit depuis cet emplacement.
# ==============================================================================
info "Étape 5 : Installation des icônes et du curseur..."

ICONS_SRC="$CONFIG_DIR/assets/icons"

if [[ -d "$ICONS_SRC/candy-icons" ]]; then
  sudo cp -r "$ICONS_SRC/candy-icons" /usr/share/icons/
  info "candy-icons installé."
else
  warn "candy-icons non trouvé dans le repo."
fi

if [[ -d "$ICONS_SRC/Sweet-cursors" ]]; then
  sudo cp -r "$ICONS_SRC/Sweet-cursors" /usr/share/icons/
  # Mettre à jour le cache des icônes système
  sudo gtk-update-icon-cache /usr/share/icons/Sweet-cursors 2>/dev/null || true
  info "Sweet-cursors installé."
else
  warn "Sweet-cursors non trouvé dans le repo."
fi

# ==============================================================================
# ÉTAPE 6 — CONFIG COSMIC DESKTOP
# Les fichiers RON sont copiés dans ~/.config/cosmic/.
# Les chemins absolus /home/caleb sont corrigés si le username a changé.
# Le wallpaper est appliqué via la commande cosmic-settings après le démarrage
# de la session — un script de démarrage automatique s'en charge.
# ==============================================================================
info "Étape 6 : Application de la config COSMIC..."

COSMIC_SRC="$CONFIG_DIR/dotfiles/cosmic"
COSMIC_DST="$HOME/.config/cosmic"

if [[ -d "$COSMIC_SRC" ]]; then
  mkdir -p "$COSMIC_DST"
  cp -r "$COSMIC_SRC"/. "$COSMIC_DST/"

  # Corriger les chemins absolus si le username a changé
  if [[ "$USERNAME" != "$ORIGINAL_USERNAME" ]]; then
    info "Correction des chemins /home/$ORIGINAL_USERNAME -> /home/$USERNAME..."
    find "$COSMIC_DST" -type f -exec \
      sed -i "s|/home/$ORIGINAL_USERNAME|/home/$USERNAME|g" {} +
      # Corriger aussi la config Tabby
    sed -i "s|/home/$ORIGINAL_USERNAME|/home/$USERNAME|g" \
      "$HOME/.config/tabby/config.yaml"
  fi

  info "Config COSMIC appliquée."
else
  warn "Dossier dotfiles/cosmic introuvable dans le repo."
fi

# Forcer le terminal COSMIC à utiliser zsh
# COSMIC lit la variable d'environnement SHELL pour son terminal intégré.
# On l'écrit dans ~/.config/environment.d/ qui est chargé par systemd user.
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/shell.conf" <<EOF
SHELL=$NIX_ZSH
EOF
info "Terminal COSMIC configuré pour utiliser zsh."

# ==============================================================================
# ÉTAPE 7 — TABBY TERMINAL (via .deb)
# Pas dans nixpkgs. Le script cherche le .deb dans les emplacements courants.
# ==============================================================================
info "Étape 7 : Installation de Tabby Terminal..."

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
# ÉTAPE 8 — FLATPAKS
# Installation en mode --user pour éviter la question système/utilisateur
# et ne pas nécessiter de droits root pour les mises à jour futures.
# - Flatseal  : gestionnaire de permissions Flatpak
# - Chrome    : propriétaire, absent de nixpkgs
# - Obsidian  : pas de paquet nixpkgs officiel stable
# - Remmina   : plugins RDP/VNC mieux gérés en Flatpak
# ==============================================================================
info "Étape 8 : Installation des Flatpaks..."

if ! command -v flatpak &>/dev/null; then
  sudo apt install -y flatpak
fi

# Ajouter Flathub en mode user (pas besoin de sudo)
flatpak remote-add --user --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y --user flathub \
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
echo "  - Appliquer le fond d'écran manuellement dans Paramètres COSMIC"
echo "    si il ne s'applique pas automatiquement"
echo "  - Appliquer le thème d'icônes candy-icons dans Paramètres COSMIC"
echo "  - Appliquer le curseur Sweet-cursors dans Paramètres COSMIC"
echo "  - Si le thème powerlevel10k ne s'affiche pas bien : p10k configure"
echo ""
if [[ "$USERNAME" != "$ORIGINAL_USERNAME" ]]; then
  warn "Username adapté : $ORIGINAL_USERNAME -> $USERNAME"
  warn "Les fichiers home.nix et flake.nix ont été modifiés localement."
  warn "Si ce PC devient une référence, commite ces changements dans le repo."
fi
