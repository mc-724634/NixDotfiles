{ pkgs, inputs, ... }:

let
  # The official Catppuccin Discord/Vencord theme hardcodes its accent ($brand)
  # to blue for every flavour. Patch the mocha variant to mauve (to match the
  # rest of this setup) and compile it with the same sass toolchain upstream
  # uses, instead of relying on their remotely-hosted, accent-fixed CSS.
  catppuccinVencordTheme =
    let
      discordSrc = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "discord";
        rev = "b9b5547f0b32296d2389716ef606de87b3c1e7c7";
        hash = "sha256-rxvHIifq5CYIBPwFA2SpOrWT+sG/z0ItXT3sx2wbEqg=";
      };
      highlightjsSrc = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "highlightjs";
        rev = "79a8accb89c5a94010ed3968cb2b04c3d679b6ba";
        hash = "sha256-zdXbktS/uiidSwX8BvFGxLb/J3dwKFZVDrxQV38l9G4=";
      };
      paletteTarball = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@catppuccin/palette/-/palette-1.8.0.tgz";
        hash = "sha256-kv0aQd8/kQohCO9WKRCgkKD3PbII6Aj22t26VTUarpk=";
      };
    in
    pkgs.runCommand "catppuccin-mocha-mauve.theme.css" {
      nativeBuildInputs = [ pkgs.dart-sass ];
    } ''
      mkdir -p node_modules/@catppuccin/palette node_modules/@catppuccin/highlightjs
      tar xzf ${paletteTarball} -C node_modules/@catppuccin/palette --strip-components=1
      cp -r ${highlightjsSrc}/sass node_modules/@catppuccin/highlightjs/sass

      cp -r ${discordSrc}/src src
      chmod -R u+w src
      sed -i 's/\$brand: \$blue;/\$brand: \$mauve;/' src/catppuccin-mocha.theme.scss

      sass -I node_modules --no-charset --no-source-map \
        src/catppuccin-mocha.theme.scss "$out"
    '';

in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    ./modules/fastfetch.nix
    ./modules/shell.nix   # fish, starship, ghostty
    ./modules/hyprland.nix
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
    # Official Discord client with Vencord injected at build time by nixpkgs
    # (what Vencord's own installer does, just reproducible). Not Vesktop:
    # Vesktop's own screen-share implementation captures system audio via
    # xdg-desktop-portal, which stock Discord's Linux build still lacks -
    # traded away here since it isn't used.
    (discord.override { withVencord = true; })
    telegram-desktop

    # Phone integration - runs alongside kdeconnect-kde (configuration.nix's
    # programs.kdeconnect), reusing the same firewall ports (TCP+UDP
    # 1714-1764) that option already opens, no extra networking changes
    # needed. Both implement the same KDE Connect protocol though, so if
    # they're both advertising/listening at once, only one is likely to
    # actually hold the discovery port at a time - not a conflict Nix can
    # resolve, just something to be aware of if pairing acts up.
    valent

    # Desktop utilities - no DE-provided file manager/camera app now that
    # KDE Plasma's gone; DMS doesn't ship one itself.
    #
    # Nautilus (GNOME), not Dolphin/Ark/Thunar - after Thunar's archive
    # extraction turned out unreliable here, Dolphin fixed that (KIO handles
    # file associations/archives independently of GTK/GIO) but needed a
    # dedicated QT_QPA_PLATFORMTHEME=kde wrapper plus kded/plasma-integration/
    # a kdeglobals patch just to render its own icon-view labels correctly,
    # since it was the only KDE Frameworks app in an otherwise GTK-first
    # setup. Nautilus is GTK4/libadwaita, so it follows the dark-mode/
    # accent-color portal signal this setup already had working correctly
    # for every other GTK4 app, and its archive extraction (gnome-autoar) is
    # built directly into the file manager itself - no separate backend
    # package or MIME-default resolution to go wrong at all.
    nautilus

    # snapshot, not kamoso/webcamoid - GNOME's actively-maintained camera
    # app (Cheese's replacement), GTK4, same reasoning as Nautilus: stays in
    # the one consistent toolkit this setup is actually built around.
    snapshot

    # Image viewer, text editor, PDF reader, video player, music player -
    # swapped from the XFCE/X-apps picks (ristretto/mousepad/xreader/
    # celluloid) to GNOME's own GTK4/libadwaita apps, matching the Nautilus
    # switch instead of just being "any GTK3 app that themes fine":
    #
    # - loupe replaces ristretto (GNOME's current image viewer, Eye of
    #   GNOME's GTK4 successor).
    # - gnome-text-editor replaces mousepad (GNOME's current default editor).
    # - papers replaces xreader (GNOME's current document viewer, the
    #   libadwaita fork that's replacing Evince).
    # - showtime replaces celluloid for video. One real trade-off: Showtime
    #   is GStreamer-backed (same as old Totem), not mpv - mpv/celluloid has
    #   broader out-of-the-box codec/subtitle support. If a video format
    #   misbehaves, that's why; swap back to celluloid if it's a problem.
    # - amberol is new (nothing handled single-file audio playback before) -
    #   GNOME's minimal single-track player, not a library manager like
    #   gnome-music, matching the "double-click a file" role the others play.
    loupe
    gnome-text-editor
    papers
    showtime
    amberol

    # Games & emulation
    #
    # gamescope - needed for HDR in Steam/Proton games specifically. Hyprland
    # itself already supports HDR (wp_color_manager_v1 protocol,
    # render:cm_auto_hdr enabled by default - confirmed live via
    # `hyprctl getoption`), which is why native apps like RetroArch already
    # get it with no extra config. DXVK/VKD3D-Proton don't speak that
    # protocol at all though, so a Proton game launched directly has no way
    # to request HDR regardless of what the compositor supports. gamescope
    # exposes a Vulkan WSI layer Proton *can* target
    # (`--hdr-enabled`'s own --help text: "needs Gamescope WSI layer enabled
    # for support from clients"), then renegotiates real Wayland HDR with
    # Hyprland on the game's behalf - the same mechanism the Steam Deck uses.
    # Per-game, not a gamescopeSession: set a Steam launch option of
    # `gamescope --hdr-enabled -- %command%` on whichever game needs it.
    gamescope
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
       sameboy
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

    # System & fun
    hyfetch
  ];

  # Reverted back to spicetify-nix's declarative build-time patching - the
  # imperative CLI + matugen flow (writable Spotify copy, spicetify watch -s)
  # didn't actually get live color updates reaching Spotify, and wasn't
  # worth the extra moving parts without that working. Static Catppuccin
  # Mauve again, same as before.
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      # The bundled catppuccin theme only ships flavours, not accents - every
      # accent-bearing key in its [mocha] section is a neutral grey. Reuse the
      # rest of that section verbatim and override just those keys to mauve.
      customColorScheme = {
        text               = "cdd6f4";
        subtext            = "cdd6f4";
        main               = "1e1e2e";
        main-elevated      = "313244";
        highlight          = "313344";
        highlight-elevated = "45475a";
        sidebar            = "181825";
        player             = "11111b";
        card               = "313244";
        shadow             = "181825";
        selected-row       = "cba6f7";
        button             = "7f849c";
        button-active      = "cba6f7";
        button-disabled    = "6c7086";
        tab-active         = "313244";
        notification       = "cba6f7";
        notification-error = "f38ba8";
        equalizer          = "cba6f7";
        misc               = "45475a";

        crust              = "11111b";
        mantle             = "181825";
        base               = "1e1e2e";
        surface0           = "313244";
        surface1           = "45475a";
        surface2           = "585b70";
        overlay0           = "6c7086";
        overlay1           = "7f849c";
        overlay2           = "9399b2";
        rosewater          = "f5e0dc";
        flamingo           = "f2cdcd";
        pink               = "f5c2e7";
        maroon             = "eba0ac";
        red                = "f38ba8";
        peach              = "fab387";
        yellow             = "f9e2af";
        green              = "a6e3a1";
        teal               = "94e2d5";
        sapphire           = "74c7ec";
        blue               = "89b4fa";
        sky                = "89dceb";
        mauve              = "cba6f7";
        lavender           = "b4befe";
      };
      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        beautifulLyrics
        adblockify
        volumePercentage
        copyLyrics
      ];
    };

  xdg.configFile."Vencord/themes/catppuccin-mocha-mauve.theme.css".source =
    catppuccinVencordTheme;

  # ── default applications (Settings → Apps → Default Apps) ──────────────
  # Web browser/mail and archive-manager used to be pinned here too, but DMS's
  # own Settings → Applications → Default apps page has pickers for both
  # (confirmed: it writes straight to ~/.config/mimeapps.list, the same file
  # this option manages as a read-only symlink - home-manager's own module
  # docs say so explicitly). Declaring them here meant every
  # `nixos-rebuild switch` would silently revert whatever was picked in DMS's
  # UI back to these values. Left in Nix only for scheme handlers DMS has no
  # picker for at all - nothing here fights that settings page anymore.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/discord" = "discord.desktop";
      "x-scheme-handler/heroic" = [ "com.heroicgameslauncher.hgl.desktop" "heroic.desktop" ];
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
