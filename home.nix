{ config, pkgs, inputs, ... }:
let
  # Orchis from upstream (nixpkgs ships an older release); pinned in flake.lock.
  # "macos" tweak = macOS-style window buttons.
  orchis = (pkgs.orchis-theme.override { tweaks = [ "macos" ]; }).overrideAttrs (old: {
    version = "git";
    src = inputs.orchis-src;

    # Orchis deliberately renders the QuickToggleMenu popup (Suspend/Restart/Power
    # Off/Log Out, Night Light, etc.) as a white Material card with dark text
    # (.quick-toggle-menu rules around "gnome-shell.css:1913") - confirmed by diffing
    # against GNOME's own stock dark theme, which leaves that selector's background
    # unset (inherits dark) entirely. That clashes with everything else in this setup
    # being dark, so flip it back to match.
    #
    # ".quick-toggle-menu-container" (the outer wrapper) is never styled by Orchis at
    # all and is left that way here too: it's only a BinLayout animation wrapper, and
    # giving it its own opaque background made the real card's rounded corners
    # (border-radius on ".quick-toggle-menu" below, untouched) invisible - same solid
    # colour behind and in front leaves nothing for the rounding to contrast against.
    #
    # Every override selector below is prefixed with the ".quick-toggle-menu-container"
    # ancestor class so it has strictly higher specificity than Orchis's own same-class
    # rules: appending a same-specificity "!important" rule later in the file (tried
    # first) did NOT win, confirmed live via Looking Glass (Main.panel.statusArea
    # .quickSettings._system._systemItem.menu...get_theme_node()) - GNOME's St CSS
    # engine doesn't reliably prefer later declarations on a specificity tie the way
    # the CSS cascade does, so winning on specificity is the only reliable lever.
    postInstall = (old.postInstall or "") + ''
      cat >> $out/share/themes/${orchisTheme}/gnome-shell/gnome-shell.css <<'EOF'

      .quick-toggle-menu-container .quick-toggle-menu,
      .quick-toggle-menu-container .quick-toggle-menu:insensitive {
        background-color: rgba(33, 33, 33, 0.97) !important;
        color: #ffffff !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item,
      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item StLabel {
        color: #ffffff !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item:focus,
      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item:hover,
      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item.selected {
        background-color: rgba(255, 255, 255, 0.08) !important;
        color: #ffffff !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item:active {
        background-color: rgba(255, 255, 255, 0.3) !important;
        color: #ffffff !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item:insensitive {
        color: rgba(255, 255, 255, 0.5) !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .popup-menu-item .popup-separator-menu-item-separator {
        background-color: rgba(255, 255, 255, 0.1) !important;
      }

      .quick-toggle-menu-container .quick-toggle-menu .header .icon {
        background-color: rgba(255, 255, 255, 0.08) !important;
      }
      EOF
    '';
  });
  # Colour variant (Purple accent, dark). Used for GTK, the shell theme and the
  # ~/.local/share/themes link so they can never get out of sync.
  orchisTheme = "Orchis-Purple-Dark";
in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    ./modules/fastfetch.nix
    ./modules/shell.nix   # fish, starship, ghostty
    ./modules/gnome.nix   # dconf settings, wallpaper, display layout, default apps
    ./modules/maximize-to-tile.nix   # custom extension: maximize button -> Tiling Shell-style tile
  ];

  home.username = "mc";
  home.homeDirectory = "/home/mc";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Development
    git
    gcc
    wget
    python3
    vscode
    claude-code

    # Chat
    vesktop
    telegram-desktop

    # Games & emulation
    prismlauncher
    heroic
    bottles
    cemu
    dolphin-emu
    eden
    azahar
    steam-rom-manager
    inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
    (retroarch.withCores (cores: with cores; [
       bsnes
       mesen
     ]))

    # Creative, 3D & printing
    krita
    blender-rocm
    godot
    freecad
    orca-slicer
    printrun

    # Audio
    easyeffects
    open-scq30

    # Networking
    cisco-packet-tracer_9

    # System & fun
    gnome-boxes
    gnome-tweaks
    hyfetch
  ];

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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

  # Same reasoning, for the icon theme: Tela otherwise only lives in the
  # per-user Nix profile, a path Flatpak's "xdg-data/icons" filesystem
  # override (configuration.nix) can't see. Put it at ~/.local/share/icons
  # too so sandboxed apps can read it.
  xdg.dataFile."icons/Tela-purple-dark" = {
    source = "${pkgs.tela-icon-theme}/share/icons/Tela-purple-dark";
    force = true;
  };
}
