{ config, pkgs, spicetify-nix, inputs, ... }:
let
  # Orchis from upstream (nixpkgs ships an older release); pinned in flake.lock.
  # "macos" tweak = macOS-style window buttons.
  orchis = (pkgs.orchis-theme.override { tweaks = [ "macos" ]; }).overrideAttrs (_: {
    version = "git";
    src = inputs.orchis-src;
  });
  # Colour variant (Purple accent, dark). Used for GTK, the shell theme and the
  # ~/.local/share/themes link so they can never get out of sync.
  orchisTheme = "Orchis-Purple-Dark";
in
{
  imports = [
    spicetify-nix.homeManagerModules.default
    ./modules/fastfetch.nix
    ./modules/shell.nix   # fish, starship, ghostty
    ./modules/gnome.nix   # dconf settings, wallpaper, display layout, default apps
  ];

  home.username = "mc";
  home.homeDirectory = "/home/mc";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    git
    gcc
    wget
    hyfetch
    vesktop
    telegram-desktop
    prismlauncher
    heroic
    godot
    cemu
    dolphin-emu
    steam-rom-manager
    vscode
    python3
    orca-slicer
    easyeffects
    krita
    pkgs.blender-rocm
    gnome-boxes
    open-scq30
    claude-code
    bottles
    (pkgs.retroarch.withCores (cores: with cores; [ bsnes ]))
    printrun
    freecad
    eden
    gnome-tweaks
    azahar
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.spicetify =
    let
      spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        beautifulLyrics
        adblockify
        volumePercentage
        copyLyrics
      ];
    };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  # Applies the theme, icons and cursor to GTK apps and GNOME (Home Manager
  # also writes the matching org.gnome.desktop.interface dconf keys).
  gtk = {
    enable = true;
    theme = {
      name = orchisTheme;
      package = orchis;
    };
    iconTheme = {
      name = "Tela-purple-dark";
      package = pkgs.tela-icon-theme;
    };
    colorScheme = "dark";

    # Since HM 26.05, GTK4/libadwaita apps (Files, Settings, ...) are only themed
    # if this is set explicitly; it writes ~/.config/gtk-4.0/gtk.css.
    gtk4.theme = config.gtk.theme;
  };

  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2" = {
    source = ./extras/sounds/modern-minimal-ui-sounds-v1.2;
    force = true;
  };

  # Put the theme where both GTK and the GNOME Shell User Themes extension
  # look for it (~/.local/share/themes), so it never depends on XDG_DATA_DIRS.
  xdg.dataFile."themes/${orchisTheme}" = {
    source = "${orchis}/share/themes/${orchisTheme}";
    force = true;
  };

  programs.home-manager.enable = true;
}
