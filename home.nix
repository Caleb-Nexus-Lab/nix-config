{ config, pkgs, ... }:

{
  # ============================================================
  # IDENTITÉ UTILISATEUR
  # À adapter sur le PC pro si le nom d'utilisateur change.
  # ============================================================
  home.username = "caleb";
  home.homeDirectory = "/home/caleb";

  # Version de l'API Home Manager — ne pas modifier sans lire le changelog.
  home.stateVersion = "24.05";

  # Active la gestion de l'environnement par Home Manager.
  programs.home-manager.enable = true;

  # ============================================================
  # PAQUETS NIXPKGS
  # Tous les outils CLI/GUI migrés depuis apt et flatpak.
  # Installés dans ~/.nix-profile, sans toucher au système.
  # ============================================================
  home.packages = with pkgs; [

    # --- SHELL & TERMINAL ---
    zsh                        # Shell principal
    oh-my-zsh                  # Framework zsh (plugins git, sudo, docker…)
    zsh-autosuggestions        # Suggestions de commandes en gris
    zsh-syntax-highlighting    # Coloration syntaxique dans le prompt
    zoxide                     # Remplacement intelligent de 'cd'
    fzf                        # Fuzzy finder (Ctrl+R, Ctrl+T)
    vivid                      # Générateur de thèmes LS_COLORS
    lsd                        # 'ls' moderne avec icônes
    bat                        # 'cat' avec coloration syntaxique

    # --- ÉDITEUR ---
    neovim                     # Éditeur principal

    # --- OUTILS RÉSEAU & INFRA ---
    ansible                    # Automatisation infra
    ansible-lint               # Lint pour les playbooks Ansible
    nmap                       # Scanner réseau
    iproute2                   # ip, ss, tc…
    netcat-openbsd             # nc — couteau suisse TCP/UDP
    traceroute                 # Traceroute
    tcpdump                    # Capture de paquets
    wireshark                  # Analyse de trames (GUI + CLI)
    freerdp                    # Client RDP (freerdp3-x11)
    sshpass                    # SSH avec mot de passe en argument (scripts)
    rsync                      # Synchronisation de fichiers
    tio                        # Terminal série (remplace minicom)
    wget                       # Téléchargement HTTP/FTP
    curl                       # Requêtes HTTP CLI

    # --- MONITORING SYSTÈME ---
    btop                       # Moniteur système interactif (remplace htop)
    htop                       # Moniteur système classique (backup)

    # --- DÉVELOPPEMENT ---
    git                        # Gestionnaire de versions
    gcc                        # Compilateur C
    gnumake                    # make
    cmake                      # Build system
    cargo                      # Gestionnaire de paquets Rust
    rustc                      # Compilateur Rust
    python3                    # Python 3
    powershell                 # PowerShell (scripts cross-platform)

    # --- CONTENEURS ---
    # docker et docker-compose sont laissés en apt (daemon système, socket,
    # groupes — voir bootstrap.sh). On installe ici uniquement le CLI
    # pour que les commandes fonctionnent dans le shell Nix.
    docker-client              # CLI docker uniquement
    docker-compose             # docker compose v2

    # --- POLICES ---
    jetbrains-mono             # Police JetBrains Mono (remplace fonts-jetbrains-mono)
    noto-fonts                 # Noto fonts core (fr, en, ar, etc.)
    (nerdfonts.override {      # Nerd Fonts pour les icônes dans le terminal
      fonts = [ "JetBrainsMono" "SourceCodePro" ];
    })

    # --- UTILITAIRES SYSTÈME ---
    unzip                      # Extraction ZIP
    xterm                      # Terminal de secours
    xpad                       # Post-it bureau
    rofi                       # Lanceur d'applications
    libnotify                  # notify-send

    # --- BUREAUTIQUE ---
    # onlyoffice-bin : paquet nixpkgs disponible
    onlyoffice-bin             # Suite bureautique OnlyOffice

    # --- DIVERS ---
    openssl                    # SSL/TLS outils CLI
    gnupg                      # GPG
    xdg-user-dirs              # Gestion des dossiers utilisateur XDG
  ];

  # ============================================================
  # ZSH
  # On recrée ton .zshrc de manière déclarative.
  # oh-my-zsh est géré nativement par Home Manager.
  # powerlevel10k est chargé comme plugin oh-my-zsh.
  # ============================================================
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";  # Garde ~/.zshrc propre — le vrai fichier va dans .config/zsh

    # --- Historique ---
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;          # Partage l'historique entre toutes les sessions
    };

    # --- Oh My Zsh ---
    oh-my-zsh = {
      enable = true;
      # powerlevel10k est déclaré comme thème custom ci-dessous
      theme = "powerlevel10k/powerlevel10k";
      plugins = [
        "git"
        "sudo"
        "apt"
        "docker"
        "docker-compose"
      ];
      # Le dossier custom pointe vers la config gérée par Home Manager
      custom = "${config.home.homeDirectory}/.config/zsh/custom";
    };

    # --- Plugins supplémentaires (hors oh-my-zsh) ---
    # zsh-autosuggestions et zsh-syntax-highlighting sont gérés
    # en tant que plugins natifs HM pour éviter le double sourcing.
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./dotfiles/zsh;   # Le .p10k.zsh est dans dotfiles/zsh/
        file = ".p10k.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];

    # --- Variables d'environnement ---
    sessionVariables = {
      SUDO_EDITOR = "nvim";
      EDITOR      = "nvim";
      VISUAL      = "nvim";
      # vivid génère LS_COLORS au démarrage du shell
      LS_COLORS   = "$(${pkgs.vivid}/bin/vivid generate snazzy)";
    };

    # --- Aliases ---
    shellAliases = {
      # Navigation
      ls    = "lsd";
      ll    = "ls -alF";
      la    = "ls -A";
      ".."  = "cd ..";
      "..." = "cd ../..";

      # Outils colorés
      grep  = "grep --color=auto";
      diff  = "diff --color=auto";

      # Réseau / Infra (depuis ton .sshrc — utiles partout)
      ipbr  = "ip -c -br a";     # Interfaces et IPs en une ligne
      ports = "ss -tulanp";       # Ports ouverts et processus associés

      # Édition rapide de configs système fréquentes
      # (haproxy : laissé commenté car pas installé sur le pro)
      # haconf = "sudo nvim /etc/haproxy/haproxy.cfg";
      # hacheck = "sudo haproxy -c -f /etc/haproxy/haproxy.cfg";
      # hares  = "sudo systemctl restart haproxy";
    };

    # --- Autocompletion ---
    # Reproduit les zstyle de ton .zshrc
    initExtra = ''
      # Autocomplétion avec menu et correspondance insensible à la casse
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      autoload -Uz compinit && compinit -u

      # zoxide — remplaçant de 'cd' (z, zi)
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # fzf — keybindings et completion
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # Fonction mkcd : crée un dossier et entre dedans
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Powerlevel10k instant prompt (doit rester en haut du zshrc)
      # Chargé automatiquement via le plugin p10k-config déclaré plus haut.
    '';
  };

  # ============================================================
  # GIT
  # Reproduit ton .gitconfig minimal.
  # ============================================================
  programs.git = {
    enable    = true;
    userName  = "Caleb-Nexus-Lab";
    userEmail = "tjurgawczynski@outlook.fr";
    extraConfig = {
      init.defaultBranch = "main";
      core.editor        = "nvim";
      pull.rebase        = false;  # Merge par défaut sur git pull
    };
  };

  # ============================================================
  # NEOVIM
  # La config init.lua est gérée comme fichier externe (xdg.configFile)
  # plutôt qu'inline pour rester lisible et facilement éditable.
  # lazy.nvim se charge lui-même de télécharger les plugins au 1er lancement.
  # ============================================================
  programs.neovim = {
    enable        = true;
    defaultEditor = true;   # Positionne $EDITOR et $VISUAL automatiquement
    viAlias       = true;   # 'vi' pointe vers nvim
    vimAlias      = true;   # 'vim' pointe vers nvim
  };

  # ============================================================
  # KITTY (terminal backup)
  # ============================================================
  programs.kitty = {
    enable = true;
    font = {
      name = "Source Code Pro";
      size = 14;
    };
    settings = {
      shell                = "zsh";
      background_opacity   = "0.85";
      background_blur      = 5;
      window_padding_width = 10;
    };
    # Le thème Tokyo Night est inclus via extraConfig
    extraConfig = builtins.readFile ./dotfiles/kitty/current-theme.conf;
  };

  # ============================================================
  # FICHIERS DE CONFIG GÉRÉS DIRECTEMENT (xdg.configFile)
  # Pour les apps que Home Manager ne gère pas nativement.
  # home.file gère les fichiers à la racine ~/, xdg.configFile
  # gère ~/.config/
  # ============================================================
  xdg.configFile = {

    # btop — config complète copiée depuis dotfiles/
    "btop/btop.conf".source = ./dotfiles/btop/btop.conf;

    # Tabby — config yaml (l'app elle-même est installée via .deb dans bootstrap.sh)
    "tabby/config.yaml".source = ./dotfiles/tabby/config.yaml;

    # Neovim — init.lua géré ici plutôt qu'inline dans programs.neovim
    "nvim/init.lua".source    = ./dotfiles/nvim/init.lua;
    "nvim/lazy-lock.json".source = ./dotfiles/nvim/lazy-lock.json;
  };

  # ============================================================
  # FICHIERS À LA RACINE ~ (home.file)
  # ============================================================
  home.file = {
    # .p10k.zsh — généré par 'p10k configure', on le versionne tel quel
    ".p10k.zsh".source = ./dotfiles/zsh/.p10k.zsh;

    # .sshrc — config shell pour les sessions SSH distantes
    # (interprété par sshrc, pas par ssh natif)
    ".sshrc".source = ./dotfiles/zsh/.sshrc;
  };

  # ============================================================
  # VARIABLES D'ENVIRONNEMENT SYSTÈME (hors shell)
  # Chargées par le session manager (utile pour les apps GUI)
  # ============================================================
  home.sessionVariables = {
    EDITOR       = "nvim";
    VISUAL       = "nvim";
    SUDO_EDITOR  = "nvim";
    XCURSOR_THEME = "Sweet-cursors";  # Thème curseur de ton .zshrc
  };
}
