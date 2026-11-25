{ config, lib, pkgs, ... }:

let
  # dms setup headless --compositor hyprland --terminal ghostty --no-systemd
  # generates a complete, version-matched Lua config (binds, window/layer
  # rules, animations, layout, colors, etc.) - far more correct and complete
  # than hand-authoring hyprlang/Lua ourselves (confirmed the hard way: both
  # the hyprlang comma-syntax and a hand-rolled Lua exec-once call were
  # invalid against this Hyprland version's actual config engine). Vendored
  # verbatim from a live `dms setup` run into extras/hyprland/, seeded once
  # below rather than continuously enforced - these files are meant to be
  # live-edited (binds-user.lua explicitly, colors.lua by DMS's own matugen
  # wallpaper hook, the DMS keybind editor rewrites binds-user.lua directly),
  # same lesson learned from the KDE panel config fights earlier.
  #
  # Non-bind customization (polkit autostart, QT6 theming override, monitor/
  # workspace rules, follow_mouse) lives in user-config.lua, NOT
  # binds-user.lua - confirmed the DMS keybind editor rewrites binds-user.lua
  # wholesale on every save, keeping only hl.bind/hl.unbind lines and
  # silently dropping everything else that used to live there.
  userConfig = pkgs.runCommand "hypr-user-config.lua" { } ''
    substitute ${../extras/hyprland/dms/user-config.lua} $out \
      --replace-fail '@hyprpolkitagent@' '${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent'
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Fully hands off config generation - dms setup's vendored/seeded files
    # (below) are the only thing managing ~/.config/hypr/*. Leaving
    # systemd.enable at its home-manager default would make it also try to
    # own hyprland.lua itself (shouldGenerate triggers on systemd.enable
    # alone, even with empty settings), colliding with the seed.
    systemd.enable = false;
  };

  # "Communication with the local password server failed" on smb:// (and
  # any other GVFS network-location) connections - GVFS needs a running
  # org.freedesktop.secrets provider to store/retrieve the login, and
  # nothing on this system ever provided one (no GNOME session/GDM, no
  # PAM-triggered keyring start elsewhere). Confirmed live: no
  # gnome-keyring/kwalletd process, nothing registered on the session D-Bus
  # for secrets/keyring/wallet at all. This starts gnome-keyring's daemon as
  # a systemd user service and registers it for the secrets D-Bus name.
  services.gnome-keyring.enable = true;

  # DMS's own dynamic theming writes matugen-generated colors straight into
  # ~/.config/qt5ct/colors/matugen.conf and qt6ct/colors/matugen.conf - the
  # gtk3 platform theme bridge (tried first) made Qt apps render with a
  # GTK-ish widget style, but never actually picks up DMS's colors, since
  # that pipeline specifically targets qt5ct/qt6ct, not gtk3. "qtct" is
  # home-manager's option name for this pairing - installs both qt5ct and
  # qt6ct and sets QT_QPA_PLATFORMTHEME=qt5ct accordingly.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # home-manager's qt.platformTheme only ever sets the bare
  # QT_QPA_PLATFORMTHEME to "qt5ct", with no equivalent option for the
  # Qt6-specific var at all. user-config.lua's hl.env() calls patch both
  # back to qt5ct/qt6ct, but only for processes Hyprland spawns directly -
  # DMS itself no longer qualifies since it moved to a systemd user service
  # (programs.dank-material-shell.systemd.enable), which gets its
  # environment from home-manager's session variables, not from Hyprland's
  # own env-setting. Confirmed live: DMS's own process had
  # QT_QPA_PLATFORMTHEME=qt5ct, and whatever QT6 helper it shells out to for
  # "apply icon theme" explicitly complained it needed qt6ct specifically.
  # Setting it here instead reaches both paths correctly.
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  # tela-icon-theme and bibata-cursors are just the packages - makes them
  # discoverable in DMS's icon/cursor-theme pickers, same as any other
  # package on XDG_DATA_DIRS. Nothing here sets either one as active.
  #
  # adw-gtk3 is different - it's not something DMS picks for you, it's load-
  # bearing infrastructure for DMS's own theming to work at all (see below).
  #
  # kdePackages.breeze is the same class of thing for Qt apps: without the
  # actual Breeze widget-style plugin reachable, qt5ct/qt6ct fall back to
  # Qt's generic built-in Fusion style - a real gap for the plain Qt apps
  # still around (Krita, FreeCAD, Telegram, dolphin-emu, PrismLauncher).
  home.packages = [ pkgs.tela-icon-theme pkgs.bibata-cursors pkgs.adw-gtk3 pkgs.kdePackages.breeze ];

  # Narrow patch, same reasoning as fixGtkTheme below: DMS's matugen hook
  # only ever writes color_scheme_path/custom_palette/icon_theme into
  # qt5ct.conf/qt6ct.conf - it never sets a widget style, so this key is
  # never DMS's to fight over. Without it explicitly set, qt5ct/qt6ct use
  # whatever Qt's own default happens to be (Fusion), not Breeze.
  home.activation.fixQtStyle =
    let
      patchFile = file: ''
        f="$HOME/.config/${file}"
        if [ -e "$f" ]; then
          if command grep -q "^style=" "$f"; then
            run sed -i "s/^style=.*/style=Breeze/" "$f"
          else
            run sed -i "/^\[Appearance\]/a style=Breeze" "$f"
          fi
        fi
      '';
    in
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (map patchFile [ "qt5ct/qt5ct.conf" "qt6ct/qt6ct.conf" ])
    );

  # Confirmed live (Thunar): dconf had org.gnome.desktop.interface gtk-theme
  # explicitly set to an *empty string* - once GTK3's GSettings-backed
  # settings source is active, that empty value wins over gtk-theme-name in
  # settings.ini entirely (not "ini isn't read", GSettings already owns the
  # property). Setting this is what actually makes gtk-theme-name below take
  # effect - without it, settings.ini's value is silently shadowed.
  dconf.settings."org/gnome/desktop/interface".gtk-theme = "adw-gtk3-dark";

  # Cursor and icon theme are deliberately NOT declared via
  # home.pointerCursor/gtk.enable - DMS's own settings app and
  # `dms cursor-theme install` / `dms icon-theme install` own this end to
  # end, copying theme files into the icon directory itself. Letting
  # gtk.enable manage the whole settings.ini would fight that on every
  # switch, same class of conflict already hit with the Hyprland config and
  # Qt plugin path. Pick Bibata Modern Classic and Tela through DMS's
  # settings app.
  #
  # Two confirmed gaps, patched narrowly below rather than handing the whole
  # file to gtk.enable (which would fight whatever else DMS writes there):
  #
  # 1. The cursor picker writes the Hyprland-level env vars (dms/cursor.lua)
  #    but never writes gtk-cursor-theme-name into settings.ini. Apps that
  #    resolve their cursor via GTK settings rather than XCURSOR_THEME
  #    (confirmed with Spotify and Steam, both XWayland clients) fell back
  #    to a generic cursor as a result.
  #
  # 2. gtk-theme-name was never set at all (empty), by anyone - DMS only
  #    ever injects color *overrides* (dank-colors.css, @define-color), it
  #    doesn't pick a base theme. With no theme set, GTK3 falls back to its
  #    own built-in Adwaita, which uses the *legacy* color variable names
  #    (@theme_bg_color etc.) - DMS's overrides target the *libadwaita*
  #    names (window_bg_color, headerbar_bg_color, etc.), which that
  #    fallback theme never reads. Confirmed live in Thunar: icons/cursor
  #    themed fine (separate mechanism), but no color changes took effect
  #    at all. adw-gtk3 is a GTK3 theme purpose-built to use the libadwaita
  #    variable set (confirmed by grepping its own CSS) - setting it as the
  #    active theme is what makes DMS's overrides land on anything.
  home.activation.fixGtkTheme =
    let
      settings = {
        gtk-cursor-theme-name = "Bibata-Modern-Classic";
        gtk-cursor-theme-size = "24";
        gtk-theme-name = "adw-gtk3-dark";
      };
      patchKey = key: value: ''
        if command grep -q "^${key}=" "$f"; then
          run sed -i "s/^${key}=.*/${key}=${value}/" "$f"
        else
          run sed -i "/^\[Settings\]/a ${key}=${value}" "$f"
        fi
      '';
      patchFile = file: ''
        f="$HOME/.config/${file}"
        mkdir -p "$(dirname "$f")"
        if [ ! -e "$f" ]; then
          run bash -c 'printf "[Settings]\n" > "'"$f"'"'
        fi
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList patchKey settings)}
      '';
    in
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (map patchFile [ "gtk-3.0/settings.ini" "gtk-4.0/settings.ini" ])
    );

  # Same deal for sounds - just installed to the standard XDG sound-theme
  # path (~/.local/share/sounds/), nothing here sets it as active. Pick it
  # through DMS's settings app.
  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2".source =
    ../extras/sounds/modern-minimal-ui-sounds-v1.2;


  home.activation.seedHyprlandConfig =
    let
      seeds = [
        { dest = "hypr/hyprland.lua"; src = ../extras/hyprland/hyprland.lua; }
        { dest = "hypr/dms/binds.lua"; src = ../extras/hyprland/dms/binds.lua; }
        { dest = "hypr/dms/binds-user.lua"; src = ../extras/hyprland/dms/binds-user.lua; }
        { dest = "hypr/dms/user-config.lua"; src = userConfig; }
        { dest = "hypr/dms/windowrules.lua"; src = ../extras/hyprland/dms/windowrules.lua; }
        { dest = "hypr/dms/colors.lua"; src = ../extras/hyprland/dms/colors.lua; }
        { dest = "hypr/dms/layout.lua"; src = ../extras/hyprland/dms/layout.lua; }
        { dest = "hypr/dms/outputs.lua"; src = ../extras/hyprland/dms/outputs.lua; }
        { dest = "hypr/dms/cursor.lua"; src = ../extras/hyprland/dms/cursor.lua; }
        { dest = "hypr/dms/animations.lua"; src = ../extras/hyprland/dms/animations.lua; }
        { dest = "hypr/dms/input.lua"; src = ../extras/hyprland/dms/input.lua; }
      ];
      seedOne = { dest, src }: ''
        mkdir -p "$(dirname "$HOME/.config/${dest}")"
        if [ ! -e "$HOME/.config/${dest}" ]; then
          run install -m 600 ${src} "$HOME/.config/${dest}"
        fi
      '';
    in
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (map seedOne seeds)
    );
}
