#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh — Installation complète de l'environnement Caleb Nexus Lab
# ==============================================================================
# Usage : bash bootstrap.sh
# À lancer sur un Pop!_OS 24.04 fraîchement installé, en tant qu'utilisateur
# normal (pas root). Le script demande le mot de passe sudo quand nécessaire.
#
# Ce script fait dans l'ordre :
#   1. Paquets apt système (virtualisation, docker, outils système profonds)
#   2. Installation de Nix (multi-user)
#   3. Installation de Home Manager via flake
#   4. Clone du repo de config et application de home.nix
#   5. Installation de Tabby Terminal via .deb
#   6. Installation des Flatpaks résiduels (Flatseal, Chrome, Obsidian, Remmina)
# ==============================================================================

set -euo pipefail  # Arrêt immédiat sur erreur, variable non définie, pipe cassé

# --- Couleurs pour les messages ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# --- Vérification : pas root ---
[[ "$EUID" -eq 0 ]] && error "Ne pas lancer ce script en root. Lance-le en tant qu'utilisateur normal."

# --- Variables ---
REPO_URL="https://github.com/TON_USER/nix-config.git"  # ← Mettre l'URL de ton repo git
CONFIG_DIR="$HOME/nix-config"
USERNAME="$(whoami)"

# ==============================================================================
# ÉTAPE 1 — PAQUETS APT SYSTÈME
# Ces paquets ne sont PAS migrés vers Nix pour les raisons suivantes :
# - virtualisation (virt-manager, qemu, libvirt) : modules kernel, daemons
#   systemd, groupes système, sockets — une intégration Nix serait cassée
#   sur une distro non-NixOS
# - docker : même raison (dockerd daemon, socket /var/run/docker.sock, groupes)
# - dkms / modules kernel : doivent être compilés contre le kernel apt de Pop!_OS
# - tftpd-hpa : daemon système géré par systemd apt
# ==============================================================================
info "Étape 1 : Installation des paquets apt système..."

sudo apt update && sudo apt install -y \
  # --- Virtualisation (ne JAMAIS migrer vers Nix sur non-NixOS) ---
  virt-manager \
  qemu-system-x86 \
  libvirt-clients \
  libvirt-daemon-system \
  bridge-utils \
  \
  # --- Docker (daemon système) ---
  docker.io \
  docker-compose-v2 \
  \
  # --- Modules kernel / DKMS ---
  dkms \
  \
  # --- Réseau système ---
  tftpd-hpa \
  \
  # --- Dépendances build pour les modules kernel System76 ---
  # (si tu es sur matériel System76, décommenter)
  # system76-acpi-dkms system76-dkms system76-io-dkms linux-system76 \
  \
  # --- Fonts système (certaines ne sont pas dans nixpkgs) ---
  fonts-noto-core \
  fonts-noto-ui-core

# Ajouter l'utilisateur aux groupes nécessaires
info "Ajout de $USERNAME aux groupes libvirt et docker..."
sudo usermod -aG libvirt "$USERNAME"
sudo usermod -aG docker  "$USERNAME"

# Activer les daemons
sudo systemctl enable --now libvirtd
sudo systemctl enable --now docker

# ==============================================================================
# ÉTAPE 2 — INSTALLATION DE NIX (multi-user, avec flakes activés)
# ==============================================================================
info "Étape 2 : Installation de Nix..."

if command -v nix &>/dev/null; then
  warn "Nix est déjà installé, on passe."
else
  curl -L https://nixos.org/nix/install | sh -s -- --daemon

  # Charger Nix dans la session courante sans redémarrer
  # shellcheck disable=SC1091
  source /etc/profile.d/nix.sh || true
fi

# Activer les flakes et la commande 'nix' unifiée
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

# ==============================================================================
# ÉTAPE 4 — APPLICATION DE HOME MANAGER
# ==============================================================================
info "Étape 4 : Application de la config Home Manager..."

# Installation de home-manager via le flake (première fois)
if ! command -v home-manager &>/dev/null; then
  nix run home-manager/release-24.05 -- init --switch 2>/dev/null || true
fi

# Appliquer la config depuis le flake
# Le "#caleb" correspond à homeConfigurations."caleb" dans flake.nix
# Sur le PC pro, remplacer "caleb" par le bon username si différent.
nix run home-manager/release-24.05 -- switch \
  --flake "$CONFIG_DIR#$USERNAME" \
  --extra-experimental-features "nix-command flakes"

# ==============================================================================
# ÉTAPE 5 — TABBY TERMINAL (via .deb — pas dans nixpkgs)
# Tabby est une app Electron qui s'intègre profondément au système
# (raccourcis système, notifications, profils shell). Le .deb officiel
# est la méthode d'installation recommandée par le projet.
# ==============================================================================
info "Étape 5 : Installation de Tabby Terminal..."

TABBY_DEB=""

# Chercher un .deb Tabby dans les emplacements courants
for path in \
  "$HOME/Téléchargements"/tabby*.deb \
  "$HOME/Downloads"/tabby*.deb \
  "$HOME/Packages-deb"/tabby*.deb \
  /media/"$USERNAME"/*/tabby*.deb; do
  if [[ -f "$path" ]]; then
    TABBY_DEB="$path"
    break
  fi
done

if [[ -n "$TABBY_DEB" ]]; then
  info "Fichier .deb trouvé : $TABBY_DEB"
  sudo apt install -y "$TABBY_DEB"
else
  warn "Fichier .deb Tabby non trouvé. Télécharge-le depuis https://tabby.sh"
  warn "Puis lance : sudo apt install ./tabby-*.deb"
fi

# ==============================================================================
# ÉTAPE 6 — FLATPAKS RÉSIDUELS
# Obsidian   : pas de paquet nixpkgs officiel stable
# Chrome     : propriétaire Google, pas dans nixpkgs
# Flatseal   : outil de gestion des permissions Flatpak, logique en Flatpak
# Remmina    : fonctionne mieux en Flatpak (plugins RDP/VNC sandboxés)
# CosmicTweaks / Hidamari : spécifiques à l'environnement COSMIC/Pop!_OS
# ==============================================================================
info "Étape 6 : Installation des Flatpaks..."

# S'assurer que Flatpak et Flathub sont configurés
if ! command -v flatpak &>/dev/null; then
  sudo apt install -y flatpak
fi
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

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
echo "Prochaines étapes :"
echo "  1. Se déconnecter et se reconnecter (groupes libvirt/docker)"
echo "  2. Lancer Neovim une première fois : nvim"
echo "     → lazy.nvim va installer les plugins automatiquement"
echo "  3. Si le thème p10k n'est pas bon : p10k configure"
echo ""
warn "Pense à mettre à jour REPO_URL dans ce script avec l'URL de ton dépôt git !"
