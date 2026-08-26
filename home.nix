{ config, pkgs, spicetify-nix, inputs, ... }:
let
  shellAliases = {
    clear = "printf '\\033[2J\\033[3J\\033[H'";
  };
in
{
  imports = [
    spicetify-nix.homeManagerModules.default
    inputs.plasma-manager.homeModules.plasma-manager
    ./modules/kde.nix
    ./modules/fastfetch.nix
  ];

  home.username = "mc";
  home.homeDirectory = "/home/mc";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    git
    wget
    hyfetch
    kdePackages.kcalc
    haruna
    vesktop
    telegram-desktop
    blender
    prismlauncher
    heroic
    godot
    cemu
    dolphin-emu
    retroarch
    steam-rom-manager
    vscodium
    orca-slicer
    klassy
    easyeffects
    krita
    inputs.appgrid.packages.${pkgs.stdenv.hostPlatform.system}.default
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

      os.disabled = false;
      os.symbols = {
        nix = "";
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

  programs.plasma = {
    enable = true;

    workspace = {
      iconTheme = "Papirus-Dark";
      cursor.theme = "Bibata-Catppuccin-Macchiato";
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/cat-vibin.png";
    };

    shortcuts = {
      ksmserver."Lock Session" = [ "Meta+L" "Screensaver" ];
      "services/helium.desktop".new-window = "Meta+W";
      "services/helium.desktop".new-private-window = "Meta+Ctrl+W";
      "services/kitty.desktop"._launch = "Meta+T";
    };

    configFile = {
      kdeglobals.General.ColorScheme = "CatppuccinMacchiatoFlamingo";
      kdeglobals.General.AccentColor = "138,173,244";
      kdeglobals.General.LastUsedCustomAccentColor = "138,173,244";

      kdeglobals.Sounds.Theme = "modern-minimal-ui-sounds-v1.2";

      kwinrc."org.kde.kdecoration2".theme = "Klassy";
      kwinrc."org.kde.kdecoration2".BorderSize = "None";
      kwinrc."org.kde.kdecoration2".BorderSizeAuto = false;
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "MFS";
      kwinrc."org.kde.kdecoration2".ButtonsOnRight = "HIAX";

      kwinrc.Windows.FocusPolicy = "FocusFollowsMouse";
      kwinrc.Windows.NextFocusPrefersMouse = true;
      kwinrc.Windows.DelayFocusInterval = 50;

      kwinrc.Xwayland.Scale = 1;
      kwinrc.Plugins.fadedesktopEnabled = true;
      kwinrc.Plugins.slideEnabled = false;
      kwinrc.Effect-fadedesktop.AnimationDuration = 100;
      kwinrc.Effect-overview.BorderActivate = 9;
      kwinrc.Desktops.Number = 2;
      kwinrc.Desktops.Rows = 1;

      plasma-localerc.Formats.LANG = "en_US.UTF-8";
      plasmanotifyrc.Notifications.PopupPosition = "TopCenter";

      ksplashrc.KSplash.Engine = "none";
      ksplashrc.KSplash.Theme = "None";
      ksmserverrc.General.loginMode = "emptySession";
      kiorc.Confirmations.ConfirmDelete = true;

      spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";
      spectaclerc.VideoSave.translatedScreencastsFolder = "Screencasts";
    };
  };

  programs.home-manager.enable = true;
}
