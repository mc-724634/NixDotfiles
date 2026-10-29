{ config, pkgs, spicetify-nix, inputs, ... }:
let
  shellAliases = {
    clear = "printf '\\033[2J\\033[3J\\033[H'";
  };
  # Orchis from upstream (nixpkgs ships an older release); pinned in flake.lock.
  orchis = pkgs.orchis-theme.overrideAttrs (_: {
    version = "git";
    src = inputs.orchis-src;
  });
in
{
  imports = [
    spicetify-nix.homeManagerModules.default
    ./modules/fastfetch.nix
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
  ];

  home.file = {
    ".config/vesktop/themes/macchiato.theme.css".source = ./extras/vesktop/macchiato.theme.css;
    ".config/blender/5.1/scripts/presets/interface_theme/catppuccin-blender-dark.xml".source = ./extras/blender/catppuccin-blender-dark.xml;
    "Games/Heroic/themes/catppuccin-macchiato-blue.css".source = ./extras/heroic/catppuccin-macchiato-blue.css;
    ".local/share/krita/color-schemes/MacchiatoBlue.colors".source = ./extras/krita/MacchiatoBlue.colors;
    ".config/godot/text_editor_themes/Catppuccin Macchiato.tet".source = "${./extras/godot}/Catppuccin Macchiato.tet";
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.spicetify =
    let
      spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "macchiato";
      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        beautifulLyrics
        adblockify
        volumePercentage
        copyLyrics
      ];
    };

  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    presets = [ "catppuccin-powerline" ];

    settings = {
      line_break.disabled = false;

      os = {
        disabled = false;
        symbols = {
          NixOS = "";
        };
      };
    };
  };

  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Macchiato";
    font = {
      name = "Hack";
      size = 12;
    };
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
      name = "Orchis-Dark";
      package = orchis;
    };
    iconTheme = {
      name = "Tela";
      package = pkgs.tela-icon-theme;
    };
    colorScheme = "dark";
  };

  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2" = {
    source = ./extras/sounds/modern-minimal-ui-sounds-v1.2;
    force = true;
  };

  # Put the theme where both GTK and the GNOME Shell User Themes extension
  # look for it (~/.local/share/themes), so it never depends on XDG_DATA_DIRS.
  xdg.dataFile."themes/Orchis-Dark" = {
    source = "${orchis}/share/themes/Orchis-Dark";
    force = true;
  };

  # GNOME settings, translated from the old Plasma shortcuts/behaviour.
  # Anything not listed here is left at GNOME defaults.
  dconf.settings = {
    "org/gnome/desktop/sound" = {
      theme-name = "modern-minimal-ui-sounds-v1.2";
      event-sounds = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy";            # focus follows mouse
      num-workspaces = 2;
      button-layout = ":minimize,maximize,close";
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
      remember-numlock-state = false;   # always on at login
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "gsconnect@andyholmes.github.io"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
    };

    # Orchis shell theme (needs the User Themes extension above).
    "org/gnome/shell/extensions/user-theme" = {
      name = "Orchis-Dark";
    };

    # Free up Super+1..9 (GNOME uses them to launch dock apps by default).
    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
      switch-to-application-6 = [ ];
      switch-to-application-7 = [ ];
      switch-to-application-8 = [ ];
      switch-to-application-9 = [ ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      maximize = [ "<Super>Page_Up" ];
      minimize = [ "<Super>Page_Down" ];
      show-desktop = [ "<Super>d" ];

      # Window-level (not app-grouped) switcher, like Plasma's.
      switch-windows = [ "<Alt>Tab" "<Super>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" "<Shift><Super>Tab" ];
      switch-applications = [ ];
      switch-applications-backward = [ ];

      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-left = [ "<Super><Control>Left" ];
      switch-to-workspace-right = [ "<Super><Control>Right" ];

      move-to-workspace-1 = [ "<Super><Control>1" ];
      move-to-workspace-2 = [ "<Super><Control>2" ];
      move-to-workspace-3 = [ "<Super><Control>3" ];
      move-to-workspace-4 = [ "<Super><Control>4" ];
      move-to-workspace-5 = [ "<Super><Control>5" ];
      move-to-workspace-6 = [ "<Super><Control>6" ];
      move-to-workspace-7 = [ "<Super><Control>7" ];
      move-to-workspace-8 = [ "<Super><Control>8" ];
      move-to-workspace-9 = [ "<Super><Control>9" ];
      move-to-workspace-10 = [ "<Super><Control>0" ];
      move-to-workspace-left = [ "<Super><Control><Shift>Left" ];
      move-to-workspace-right = [ "<Super><Control><Shift>Right" ];
    };

    # App launchers (Super+T kitty, Super+W browser, Super+Ctrl+W private window)
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/helium/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/helium-private/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty" = {
      name = "Terminal";
      command = "kitty";
      binding = "<Super>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files" = {
      name = "Files";
      command = "nautilus";
      binding = "<Super>e";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/helium" = {
      name = "Browser";
      command = "helium";
      binding = "<Super>w";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/helium-private" = {
      name = "Browser (private)";
      command = "helium --incognito";
      binding = "<Super><Control>w";
    };
  };

  programs.home-manager.enable = true;
}
