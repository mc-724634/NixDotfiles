{ config, lib, ... }:

let
  inherit (lib.hm.gvariant) mkUint32 mkTuple;
  wallpaper = "${config.home.homeDirectory}/.local/share/backgrounds/wallpaper.png";
in
{
  # ── wallpaper ──────────────────────────────────────────────────────────
  xdg.dataFile."backgrounds/wallpaper.png".source = ../extras/wallpapers/wallpaper.png;

  # ── display layout ─────────────────────────────────────────────────────
  # Installed as a normal (writable) file so GNOME Settings can still save
  # display changes; it is reset to this layout on every `switch`.
  home.activation.monitorsXml = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -Dm644 ${../extras/monitors.xml} "$HOME/.config/monitors.xml"
  '';

  # ── default applications (Settings → Apps → Default Apps) ──────────────
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
      "x-scheme-handler/mailto" = "helium.desktop";
      "text/html" = "helium.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/heroic" = [ "com.heroicgameslauncher.hgl.desktop" "heroic.desktop" ];
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  # ── GNOME settings (everything from Settings + extensions) ─────────────
  # Generated from `dconf dump /`; window sizes, history, timestamps, pairing
  # data and saved locations were left out on purpose.
  dconf.settings = {
    "org/gnome/GWeather4" = {
      temperature-unit = "fahrenheit";
    };

    "org/gnome/desktop/a11y/applications" = {
      screen-reader-enabled = false;
    };

    "org/gnome/desktop/a11y/magnifier" = {
      cross-hairs-length = 58;
    };

    # Wallpaper (the image is installed from extras/wallpapers, see above).
    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file://${wallpaper}";
      picture-uri-dark = "file://${wallpaper}";
      primary-color = "#ff7800";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/break-reminders" = {
      selected-breaks = [ ];
    };

    "org/gnome/desktop/break-reminders/eyesight" = {
      play-sound = true;
    };

    "org/gnome/desktop/break-reminders/movement" = {
      duration-seconds = (mkUint32 300);
      interval-seconds = (mkUint32 1800);
      play-sound = true;
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = false;
    };

    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };

    "org/gnome/desktop/input-sources" = {
      show-all-sources = false;
      sources = [ (mkTuple [ "xkb" "us" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    # Theme, icons and cursor come from the `gtk` block in home.nix; the rest is from Settings.
    "org/gnome/desktop/interface" = {
      accent-color = "green";
      clock-format = "12h";
      clock-show-weekday = true;
      cursor-blink = true;
      cursor-blink-time = 1000;
      document-font-name = "Noto Sans  10";
      enable-animations = true;
      enable-hot-corners = false;
      font-name = "Noto Sans  10";
      monospace-font-name = "Hack  10";
      scaling-factor = (mkUint32 1);
      text-scaling-factor = 1.0;
      toolbar-style = "text";
      toolkit-accessibility = false;
    };

    # Lock-screen notifications are what make GNOME switch the display back on,
    # so they are turned off. (Per-app control: Settings -> Notifications.)
    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
      remember-numlock-state = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed = 0.191358;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/amber-l.jxl";
      primary-color = "#ff7800";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [ "org.gnome.Settings.desktop" "org.gnome.Contacts.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/desktop/sound" = {
      event-sounds = true;
      theme-name = "modern-minimal-ui-sounds-v1.2";
    };

    # Window / workspace shortcuts.
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      minimize = [ "<Super>Page_Down" ];
      move-to-workspace-1 = [ "<Super><Control>1" ];
      move-to-workspace-10 = [ "<Super><Control>0" ];
      move-to-workspace-2 = [ "<Super><Control>2" ];
      move-to-workspace-3 = [ "<Super><Control>3" ];
      move-to-workspace-4 = [ "<Super><Control>4" ];
      move-to-workspace-5 = [ "<Super><Control>5" ];
      move-to-workspace-6 = [ "<Super><Control>6" ];
      move-to-workspace-7 = [ "<Super><Control>7" ];
      move-to-workspace-8 = [ "<Super><Control>8" ];
      move-to-workspace-9 = [ "<Super><Control>9" ];
      move-to-workspace-left = [ "<Super><Control><Shift>Left" ];
      move-to-workspace-right = [ "<Super><Control><Shift>Right" ];
      show-desktop = [ "<Super>d" ];
      switch-applications = [ ];
      switch-applications-backward = [ ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-10 = [ "<Super>0" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-left = [ "<Super><Control>Left" ];
      switch-to-workspace-right = [ "<Super><Control>Right" ];
      switch-windows = [ "<Alt>Tab" "<Super>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" "<Shift><Super>Tab" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      action-double-click-titlebar = "toggle-maximize";
      button-layout = ":minimize,maximize,close";
      focus-mode = "sloppy";
      num-workspaces = 2;
      resize-with-right-button = true;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      overlay-key = "Super_L";
      workspaces-only-on-primary = true;
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small-plus";
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = false;
      night-light-schedule-automatic = false;
    };

    # Shell: favourites and which extensions are switched on (all installed via Nix, see configuration.nix).
    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [ ];
      enabled-extensions = [
        "gsconnect@andyholmes.github.io"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "blur-my-shell@aunetx"
        "dash-to-dock@micxgx.gmail.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "tilingshell@ferrarodomenico.com"
        "Rounded_Corners@lennart-k"
      ];
      favorite-apps = [
        "helium.desktop"
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
        "steam.desktop"
        "vesktop.desktop"
        "spotify.desktop"
        "code.desktop"
      ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "50.5";
    };

    # AppIndicator (system tray): icon-saturation 0.0 = greyscale, 1.0 = colour.
    "org/gnome/shell/extensions/appindicator" = {
      icon-brightness = 0.0;
      icon-contrast = 0.0;
      icon-opacity = 240;
      icon-saturation = 0.0;
      icon-size = 0;
      tray-pos = "right";
    };

    # Blur my Shell (internal pipeline definitions are left to the extension).
    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = false;
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      override-background = true;
      pipeline = "pipeline_default_rounded";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
      unblur-in-overview = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/hidetopbar" = {
      compatibility = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      pipeline = "pipeline_default";
      style-components = 1;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      brightness = 0.6;
      corner-radius = 0;
      force-light-text = false;
      pipeline = "pipeline_default_rounded";
      sigma = 30;
      static-blur = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma = 30;
    };

    # Dash to Dock.
    "org/gnome/shell/extensions/dash-to-dock" = {
      always-center-icons = false;
      animation-time = 0.2;
      apply-custom-theme = false;
      apply-glossy-effect = false;
      autohide = true;
      autohide-in-fullscreen = false;
      background-opacity = 0.8;
      custom-theme-customize-running-dots = false;
      custom-theme-running-dots-border-color = "rgb(255,255,255)";
      custom-theme-running-dots-color = "rgb(255,255,255)";
      custom-theme-shrink = true;
      dash-max-icon-size = 42;
      disable-overview-on-startup = true;
      dock-fixed = false;
      dock-position = "LEFT";
      extend-height = false;
      height-fraction = 0.9;
      hide-delay = 0.2;
      hide-tooltip = false;
      hot-keys = false;
      icon-size-fixed = false;
      intellihide = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      isolate-workspaces = false;
      multi-monitor = false;
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-1";
      pressure-threshold = 100.0;
      require-pressure-to-show = true;
      running-indicator-dominant-color = false;
      running-indicator-style = "DOTS";
      scroll-action = "cycle-windows";
      show-apps-at-top = true;
      show-delay = 0.25;
      show-dock-urgent-notify = true;
      show-favorites = true;
      show-mounts = true;
      show-mounts-network = false;
      show-show-apps-button = false;
      show-trash = false;
      unity-backlit-items = false;
    };

    # GSConnect (device pairing is deliberately NOT stored here).
    "org/gnome/shell/extensions/gsconnect" = {
      name = "nixos";
      show-indicators = false;
    };

    # Tiling Shell (window snapping zones).
    # Rounded screen corners on every monitor.
    "org/gnome/shell/extensions/lennart-k/rounded_corners" = {
      corner-radius = 18;
    };

    "org/gnome/shell/extensions/tilingshell" = {
      edge-tiling-mode = "default";
      enable-autotiling = false;
      enable-blur-selected-tilepreview = true;
      enable-blur-snap-assistant = true;
      enable-directional-focus-tiled-only = false;
      enable-screen-edges-windows-suggestions = false;
      enable-snap-assist = false;
      enable-snap-assistant-windows-suggestions = false;
      enable-tiling-system = true;
      enable-tiling-system-windows-suggestions = false;
      enable-window-border = false;
      layouts-json = ''
        [
          {"id":"Layout 1","tiles":[
            {"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},
            {"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},
            {"x":0.22,"y":0,"width":0.56,"height":1,"groups":[2,3]},
            {"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},
            {"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}
          ]},
          {"id":"Layout 2","tiles":[
            {"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},
            {"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},
            {"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}
          ]},
          {"id":"Layout 3","tiles":[
            {"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},
            {"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}
          ]},
          {"id":"Layout 4","tiles":[
            {"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},
            {"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}
          ]},
          {"id":"322203","tiles":[
            {"x":0.5,"y":0,"width":0.49999999999999856,"height":0.5,"groups":[2,1]},
            {"x":0.5,"y":0.5,"width":0.49999999999999856,"height":0.5,"groups":[2,1]},
            {"x":0,"y":0,"width":0.5,"height":0.5,"groups":[1,3]},
            {"x":0,"y":0.5,"width":0.5,"height":0.49999999999999983,"groups":[3,1]}
          ]}
        ]
      '';
      quarter-tiling-threshold = (mkUint32 1);
      selected-layouts = [ [ "322203" "322203" ] [ "322203" "322203" ] ];
      show-indicator = false;
      span-multiple-tiles-activation-key = [ "1" ];
      span-window-all-tiles = [ "<Super>Page_Up" ]; # "maximize" that keeps the gaps
      top-edge-maximize = false;
      window-use-custom-border-color = false;
    };

    # Orchis shell theme (needs the User Themes extension).
    "org/gnome/shell/extensions/user-theme" = {
      name = config.gtk.theme.name;
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

    "org/gnome/shell/weather" = {
      automatic-location = true;
    };

    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
    };

    # Custom shortcuts (Super+T terminal, Super+W browser, Super+E files, Super+I settings, Ctrl+Shift+Esc system monitor).
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser-private/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/settings/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/system-monitor/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser" = {
      name = "Browser";
      command = "helium";
      binding = "<Super>w";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/browser-private" = {
      name = "Browser (private)";
      command = "helium --incognito";
      binding = "<Super><Control>w";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/files" = {
      name = "Files";
      command = "nautilus";
      binding = "<Super>e";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/settings" = {
      name = "Settings";
      command = "gnome-control-center";
      binding = "<Super>i";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/system-monitor" = {
      name = "System Monitor";
      command = "gnome-system-monitor";
      binding = "<Control><Shift>Escape";
    };
  };
}
