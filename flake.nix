{
  description = "Nixos flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    home-manager.url =
      "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url =
      "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    helium-flake.url =
      "github:oxcl/nix-flake-helium-browser";
    helium-flake.inputs.nixpkgs.follows = "nixpkgs";

    appgrid.url =
      "github:xarbit/plasma6-applet-appgrid";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    spicetify-nix,
    helium-flake,
    ...
  }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          helium-flake.overlays.default
        ];
      };
    in {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit helium-flake;
          };

          modules = [
            ./configuration.nix

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit spicetify-nix;
              };

              home-manager.users.mc = ./home.nix;
            }
          ];
        };
      };
    };
}
