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
    vscode
    python3
    orca-slicer
    klassy
    easyeffects
    krita
    inputs.appgrid.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.papirus-icon-theme
    gnome-boxes
    kdePackages.kamoso
    nur.repos.quriosity.BedrockNix
    open-scq30
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

    programs.plasma = {
    enable = true;

    workspace = {
      iconTheme = "Papirus-Dark";
      cursor.theme = "Bibata-Catppuccin-Macchiato";
      wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/cat-vibin.png";
    };

    shortcuts = {
      ActivityManager.switch-to-activity-c95fdc30-60c7-4ef1-a4c9-8a41482f67f1 = [ ];
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
      kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
      kmix.decrease_microphone_volume = "Microphone Volume Down";
      kmix.decrease_volume = "Volume Down";
      kmix.decrease_volume_small = "Shift+Volume Down";
      kmix.increase_microphone_volume = "Microphone Volume Up";
      kmix.increase_volume = "Volume Up";
      kmix.increase_volume_small = "Shift+Volume Up";
      kmix.mic_mute = ["Microphone Mute" "Meta+Volume Mute"];
      kmix.mute = "Volume Mute";
      ksmserver."Halt Without Confirmation" = [ ];
      ksmserver."Lock Session" = ["Meta+L" "Screensaver"];
      ksmserver."Log Out" = "Ctrl+Alt+Del";
      ksmserver."Log Out Without Confirmation" = [ ];
      ksmserver.LogOut = [ ];
      ksmserver.Reboot = [ ];
      ksmserver."Reboot Without Confirmation" = [ ];
      ksmserver."Shut Down" = [ ];
      kwin."Activate Window Demanding Attention" = "Meta+Ctrl+A";
      kwin."Cycle Overview" = [ ];
      kwin."Cycle Overview Opposite" = [ ];
      kwin."Decrease Opacity" = [ ];
      kwin."Edit Tiles" = [ ];
      kwin.Expose = ["Meta+F9" "Ctrl+F9"];
      kwin.ExposeAll = ["Meta+F10" "Launch (C)" "Ctrl+F10"];
      kwin.ExposeClass = ["Meta+F7" "Ctrl+F7"];
      kwin.ExposeClassCurrentDesktop = [ ];
      kwin."Grid View" = "Meta+G";
      kwin."Increase Opacity" = [ ];
      kwin."Kill Window" = "Meta+Ctrl+Esc";
      kwin."Move Tablet to Next LogicalOutput" = [ ];
      kwin.MoveMouseToCenter = "Meta+F6";
      kwin.MoveMouseToFocus = "Meta+F5";
      kwin.MoveZoomDown = [ ];
      kwin.MoveZoomLeft = [ ];
      kwin.MoveZoomRight = [ ];
      kwin.MoveZoomUp = [ ];
      kwin.Overview = [ ];
      kwin."Setup Window Shortcut" = [ ];
      kwin."Show Desktop" = "Meta+D";
      kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
      kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
      kwin."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
      kwin."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
      kwin."Switch Window Down" = "Meta+Alt+Down";
      kwin."Switch Window Left" = "Meta+Alt+Left";
      kwin."Switch Window Right" = "Meta+Alt+Right";
      kwin."Switch Window Up" = "Meta+Alt+Up";
      kwin."Switch to Desktop 1" = "Meta+1";
      kwin."Switch to Desktop 10" = "Meta+0";
      kwin."Switch to Desktop 11" = [ ];
      kwin."Switch to Desktop 12" = [ ];
      kwin."Switch to Desktop 13" = [ ];
      kwin."Switch to Desktop 14" = [ ];
      kwin."Switch to Desktop 15" = [ ];
      kwin."Switch to Desktop 16" = [ ];
      kwin."Switch to Desktop 17" = [ ];
      kwin."Switch to Desktop 18" = [ ];
      kwin."Switch to Desktop 19" = [ ];
      kwin."Switch to Desktop 2" = "Meta+2";
      kwin."Switch to Desktop 20" = [ ];
      kwin."Switch to Desktop 21" = [ ];
      kwin."Switch to Desktop 22" = [ ];
      kwin."Switch to Desktop 23" = [ ];
      kwin."Switch to Desktop 24" = [ ];
      kwin."Switch to Desktop 25" = [ ];
      kwin."Switch to Desktop 3" = "Meta+3";
      kwin."Switch to Desktop 4" = "Meta+4";
      kwin."Switch to Desktop 5" = "Meta+5";
      kwin."Switch to Desktop 6" = "Meta+6";
      kwin."Switch to Desktop 7" = "Meta+7";
      kwin."Switch to Desktop 8" = "Meta+8";
      kwin."Switch to Desktop 9" = "Meta+9";
      kwin."Switch to Next Desktop" = [ ];
      kwin."Switch to Next Screen" = [ ];
      kwin."Switch to Previous Desktop" = [ ];
      kwin."Switch to Previous Screen" = [ ];
      kwin."Switch to Screen 0" = [ ];
      kwin."Switch to Screen 1" = [ ];
      kwin."Switch to Screen 2" = [ ];
      kwin."Switch to Screen 3" = [ ];
      kwin."Switch to Screen 4" = [ ];
      kwin."Switch to Screen 5" = [ ];
      kwin."Switch to Screen 6" = [ ];
      kwin."Switch to Screen 7" = [ ];
      kwin."Switch to Screen Above" = [ ];
      kwin."Switch to Screen Below" = [ ];
      kwin."Switch to Screen to the Left" = [ ];
      kwin."Switch to Screen to the Right" = [ ];
      kwin."Toggle Night Color" = [ ];
      kwin."Toggle Window Raise/Lower" = [ ];
      kwin."Walk Through Windows" = ["Meta+Tab" "Alt+Tab"];
      kwin."Walk Through Windows (Reverse)" = ["Meta+Shift+Tab" "Alt+Shift+Tab"];
      kwin."Walk Through Windows Alternative" = [ ];
      kwin."Walk Through Windows Alternative (Reverse)" = [ ];
      kwin."Walk Through Windows of Current Application" = ["Meta+`" "Alt+`"];
      kwin."Walk Through Windows of Current Application (Reverse)" = ["Meta+~" "Alt+~"];
      kwin."Walk Through Windows of Current Application Alternative" = [ ];
      kwin."Walk Through Windows of Current Application Alternative (Reverse)" = [ ];
      kwin."Window Above Other Windows" = [ ];
      kwin."Window Below Other Windows" = [ ];
      kwin."Window Close" = "Meta+Q";
      kwin."Window Custom Quick Tile Bottom" = [ ];
      kwin."Window Custom Quick Tile Left" = [ ];
      kwin."Window Custom Quick Tile Right" = [ ];
      kwin."Window Custom Quick Tile Top" = [ ];
      kwin."Window Fullscreen" = [ ];
      kwin."Window Grow Horizontal" = [ ];
      kwin."Window Grow Vertical" = [ ];
      kwin."Window Lower" = [ ];
      kwin."Window Maximize" = "Meta+PgUp";
      kwin."Window Maximize Horizontal" = [ ];
      kwin."Window Maximize Vertical" = [ ];
      kwin."Window Minimize" = "Meta+PgDown";
      kwin."Window Move" = [ ];
      kwin."Window Move Center" = [ ];
      kwin."Window No Border" = [ ];
      kwin."Window On All Desktops" = [ ];
      kwin."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
      kwin."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
      kwin."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
      kwin."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
      kwin."Window One Screen Down" = [ ];
      kwin."Window One Screen Up" = [ ];
      kwin."Window One Screen to the Left" = [ ];
      kwin."Window One Screen to the Right" = [ ];
      kwin."Window Operations Menu" = "Alt+F3";
      kwin."Window Pack Down" = [ ];
      kwin."Window Pack Left" = [ ];
      kwin."Window Pack Right" = [ ];
      kwin."Window Pack Up" = [ ];
      kwin."Window Quick Tile Bottom" = "Meta+Down";
      kwin."Window Quick Tile Bottom Left" = [ ];
      kwin."Window Quick Tile Bottom Right" = [ ];
      kwin."Window Quick Tile Left" = "Meta+Left";
      kwin."Window Quick Tile Right" = "Meta+Right";
      kwin."Window Quick Tile Top" = "Meta+Up";
      kwin."Window Quick Tile Top Left" = [ ];
      kwin."Window Quick Tile Top Right" = [ ];
      kwin."Window Raise" = [ ];
      kwin."Window Resize" = [ ];
      kwin."Window Shrink Horizontal" = [ ];
      kwin."Window Shrink Vertical" = [ ];
      kwin."Window to Desktop 1" = "Meta+Ctrl+1";
      kwin."Window to Desktop 10" = "Meta+Ctrl+0";
      kwin."Window to Desktop 11" = [ ];
      kwin."Window to Desktop 12" = [ ];
      kwin."Window to Desktop 13" = [ ];
      kwin."Window to Desktop 14" = [ ];
      kwin."Window to Desktop 15" = [ ];
      kwin."Window to Desktop 16" = [ ];
      kwin."Window to Desktop 17" = [ ];
      kwin."Window to Desktop 18" = [ ];
      kwin."Window to Desktop 19" = [ ];
      kwin."Window to Desktop 2" = "Meta+Ctrl+2";
      kwin."Window to Desktop 20" = [ ];
      kwin."Window to Desktop 21" = [ ];
      kwin."Window to Desktop 22" = [ ];
      kwin."Window to Desktop 23" = [ ];
      kwin."Window to Desktop 24" = [ ];
      kwin."Window to Desktop 25" = [ ];
      kwin."Window to Desktop 3" = "Meta+Ctrl+3";
      kwin."Window to Desktop 4" = "Meta+Ctrl+4";
      kwin."Window to Desktop 5" = "Meta+Ctrl+5";
      kwin."Window to Desktop 6" = "Meta+Ctrl+6";
      kwin."Window to Desktop 7" = "Meta+Ctrl+7";
      kwin."Window to Desktop 8" = "Meta+Ctrl+8";
      kwin."Window to Desktop 9" = "Meta+Ctrl+9";
      kwin."Window to Next Desktop" = [ ];
      kwin."Window to Next Screen" = "Meta+Shift+Right";
      kwin."Window to Previous Desktop" = [ ];
      kwin."Window to Previous Screen" = "Meta+Shift+Left";
      kwin."Window to Screen 0" = [ ];
      kwin."Window to Screen 1" = [ ];
      kwin."Window to Screen 2" = [ ];
      kwin."Window to Screen 3" = [ ];
      kwin."Window to Screen 4" = [ ];
      kwin."Window to Screen 5" = [ ];
      kwin."Window to Screen 6" = [ ];
      kwin."Window to Screen 7" = [ ];
      kwin.disableInputCapture = "Meta+Shift+Esc";
      kwin.view_actual_size = [ ];
      kwin.view_zoom_in = ["Meta++" "Meta+="];
      kwin.view_zoom_out = "Meta+-";
      mediacontrol.mediavolumedown = [ ];
      mediacontrol.mediavolumeup = [ ];
      mediacontrol.nextmedia = "Media Next";
      mediacontrol.pausemedia = "Media Pause";
      mediacontrol.playmedia = [ ];
      mediacontrol.playpausemedia = "Media Play";
      mediacontrol.previousmedia = "Media Previous";
      mediacontrol.seekbackwardmedia = "Media Rewind";
      mediacontrol.seekbackwardmedialong = [ ];
      mediacontrol.seekforwardmedia = "Media Fast Forward";
      mediacontrol.seekforwardmedialong = [ ];
      mediacontrol.stopmedia = "Media Stop";
      org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      org_kde_powerdevil.Hibernate = "Hibernate";
      org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      org_kde_powerdevil.PowerDown = "Power Down";
      org_kde_powerdevil.PowerOff = "Power Off";
      org_kde_powerdevil.Sleep = "Sleep";
      org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      org_kde_powerdevil."Turn Off Screen" = [ ];
      org_kde_powerdevil.powerProfile = ["Battery" "Meta+B"];
      plasmashell."Slideshow Wallpaper Next Image" = [ ];
      plasmashell."activate application launcher" = ["Meta" "Alt+F1"];
      plasmashell."activate task manager entry 1" = [ ];
      plasmashell."activate task manager entry 10" = [ ];
      plasmashell."activate task manager entry 2" = [ ];
      plasmashell."activate task manager entry 3" = [ ];
      plasmashell."activate task manager entry 4" = [ ];
      plasmashell."activate task manager entry 5" = [ ];
      plasmashell."activate task manager entry 6" = [ ];
      plasmashell."activate task manager entry 7" = [ ];
      plasmashell."activate task manager entry 8" = [ ];
      plasmashell."activate task manager entry 9" = [ ];
      plasmashell.clear-history = [ ];
      plasmashell.clipboard_action = "Meta+Ctrl+X";
      plasmashell.cycle-panels = "Meta+Alt+P";
      plasmashell.cycleNextAction = [ ];
      plasmashell.cyclePrevAction = [ ];
      plasmashell.edit_clipboard = [ ];
      plasmashell."manage activities" = [ ];
      plasmashell."next activity" = "Meta+A";
      plasmashell."previous activity" = "Meta+Shift+A";
      plasmashell.repeat_action = [ ];
      plasmashell."show dashboard" = "Ctrl+F12";
      plasmashell.show-barcode = [ ];
      plasmashell.show-on-mouse-pos = "Meta+V";
      plasmashell."switch to next activity" = [ ];
      plasmashell."switch to previous activity" = [ ];
      plasmashell."toggle do not disturb" = [ ];
      "services/helium.desktop".new-private-window = "Meta+Ctrl+W";
      "services/helium.desktop".new-window = "Meta+W";
      "services/kitty.desktop"._launch = "Meta+T";
      "services/org.kde.spectacle.desktop".CurrentMonitorScreenShot = [ ];
      "services/org.kde.spectacle.desktop".OpenWithoutScreenshot = [ ];
    };

    configFile = {
      kcminputrc.Keyboard.NumLock = 0;

      kdeglobals.General.ColorScheme = "CatppuccinMacchiatoFlamingo";
      kdeglobals.General.AccentColor = "138,173,244";
      kdeglobals.General.LastUsedCustomAccentColor = "138,173,244";
      kdeglobals.Sounds.Theme = "modern-minimal-ui-sounds-v1.2";

      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".Image = "file://${config.home.homeDirectory}/.local/share/wallpapers/cat-vibin.png";
      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".PreviewImage = "file://${config.home.homeDirectory}/.local/share/wallpapers/cat-vibin.png";

      kwinrc."org.kde.kdecoration2".theme = "Klassy";
      kwinrc."org.kde.kdecoration2".library = "org.kde.klassy";
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
      plasmanotifyrc.DoNotDisturb.WhenFullscreen = false;

      ksplashrc.KSplash.Engine = "none";
      ksplashrc.KSplash.Theme = "None";
      ksmserverrc.General.loginMode = "emptySession";
      kiorc.Confirmations.ConfirmDelete = true;

      spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";
      spectaclerc.VideoSave.translatedScreencastsFolder = "Screencasts";
    };
  };

  xdg.configFile."net.imput.helium/NativeMessagingHosts/org.kde.plasma.browser_integration.json".source =
  "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  programs.home-manager.enable = true;
}
