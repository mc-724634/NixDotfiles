{
  description = "NixOS flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    helium-flake.url = "github:oxcl/nix-flake-helium-browser";
    helium-flake.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative flatpak installs/removals (services.flatpak.* in configuration.nix).
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.8.0";

    # Minecraft Bedrock launcher (downloads the game with your own Microsoft account).
    # Deliberately NOT following our nixpkgs: it is written for nixos-unstable
    # (it calls steam-run.override, which does not exist on 26.05).
    bedrock-on-linux.url = "git+https://github.com/Wyze3306/BedrockOnLinux";

    # Orchis GTK/shell theme, built from upstream (the nixpkgs release is older).
    orchis-src = {
      url = "github:vinceliuice/Orchis-theme";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, helium-flake, lanzaboote, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit helium-flake; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.overwriteBackup = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.mc = ./home.nix;
        }
      ];
    };
  };
}
