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
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
    plasma-gnome-pager-src = {
      url = "github:KenanSalar/plasma-gnome-pager";
      flake = false;
    };
    split-clock-src = {
      url = "github:PlasmaDrifter/Widget-simplesplitclock";
      flake = false;
    };
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    spicetify-nix,
    helium-flake,
    lanzaboote,
    ...
  }:
    let
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          specialArgs = {
            inherit helium-flake;
          };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            ./configuration.nix
            home-manager.nixosModules.home-manager
            lanzaboote.nixosModules.lanzaboote
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
