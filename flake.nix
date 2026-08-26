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
    appgrid.inputs.nixpkgs.follows = "nixpkgs";
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
    in {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          # No `system = ...` here anymore — passing `system` straight into
          # nixosSystem is the deprecated antipattern that produced the
          # evaluation warning. Setting nixpkgs.hostPlatform as a module
          # value below is the current, non-deprecated way to declare it.
          specialArgs = {
            inherit helium-flake;
          };

          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }

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
