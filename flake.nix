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

    # Hyprland desktop shell (modules/hyprland.nix) - formerly
    # "DankMaterialShell", repo moved to duxlabs-dev/dux-shell and rebranded
    # "Dux Shell". Using its own flake outputs (module + package versioned
    # together) rather than nixpkgs' bundled programs.dms-shell module: that
    # one pins the package at 1.4.6, upstream's current tag is v2.1.2, and
    # grafting a newer package onto an older module's assumptions is a
    # needless risk when the upstream flake already ships both in sync.
    dux-shell.url = "github:duxlabs-dev/dux-shell";
    dux-shell.inputs.nixpkgs.follows = "nixpkgs";

    # DMS's own greetd-backed login screen (split out of dux-shell into its
    # own repo). Replaces SDDM in configuration.nix so the login screen
    # matches the Dux Shell look (wallpaper/colors) instead of a generic
    # greeter theme.
    dux-greeter.url = "github:duxlabs-dev/dux-greeter";
    dux-greeter.inputs.nixpkgs.follows = "nixpkgs";

    # nixpkgs' kdePackages.qt6ct is built from upstream qt6ct directly, not
    # the qt6ct-kde fork - it's missing KDE theming support entirely (no
    # KColorScheme/KIconThemes linking), a known, open, unresolved nixpkgs
    # issue (NixOS/nixpkgs#489021). This is the actual root cause behind
    # Dolphin's icon-view labels staying a hardcoded dark color regardless
    # of theme, and DMS's own "apply icon theme" action failing with a
    # QT_QPA_PLATFORMTHEME warning - not anything fixable via env vars,
    # activation patches, or service restarts, since the package itself
    # structurally can't read KDE color schemes the normal way. NUR's
    # ilya-fedin/nur-repository ships the patched qt6ct-kde build (confirmed:
    # built successfully, pulls in kcolorscheme/kiconthemes as real deps,
    # drop-in replacement - same binary, same plugin layout as plain qt6ct).
    # Used via an overlay (configuration.nix) rather than NUR's own home-
    # manager module, to keep using home-manager's existing qt.platformTheme
    # option/everything else in this config unchanged.
    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, helium-flake, lanzaboote, nur, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit helium-flake nur; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.dux-shell.nixosModules.dank-material-shell
        inputs.dux-greeter.nixosModules.default
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
