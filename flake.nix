{
  description = "Home Manager config — Caleb Nexus Lab";

  inputs = {
    # Canal nixpkgs stable — change "nixos-24.05" en "nixos-24.11" pour
    # mettre à jour vers la prochaine release stable.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      # Utilise le même nixpkgs que ci-dessus pour éviter les conflits.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in {
      # Point d'entrée : home-manager switch --flake .#caleb
      # Remplacer "caleb" par le nom d'utilisateur sur le nouveau PC si besoin.
      homeConfigurations."caleb" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
