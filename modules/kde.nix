{ config, pkgs, ... }:

{
  # KDE configuration
  xdg.configFile = {
    "kdeglobals" = {
      source = ../extras/kde/configs/kdeglobals;
      force = true;
    };

    "kwinrc" = {
      source = ../extras/kde/configs/kwinrc;
      force = true;
    };

    "plasma-localerc" = {
      source = ../extras/kde/configs/plasma-localerc;
      force = true;
    };

    "plasmanotifyrc" = {
      source = ../extras/kde/configs/plasmanotifyrc;
      force = true;
    };

    "plasmarc" = {
      source = ../extras/kde/configs/plasmarc;
      force = true;
    };

    "plasmashellrc" = {
      source = ../extras/kde/configs/plasmashellrc;
      force = true;
    };
  };

  # Plasma desktop/panel layout
  #
  # This is intentionally NOT managed as a permanent symlink because
  # Plasma needs to modify this file while you use the desktop.
  # We only seed it on a fresh installation.
  home.activation.seedPlasmaLayout =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        mkdir -p "$HOME/.config"

        cp ${../extras/kde/configs/plasma-org.kde.plasma.desktop-appletsrc} \
          "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

        chmod 600 "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
      fi
    '';

  # KDE color scheme
  xdg.dataFile."color-schemes/CatppuccinMacchiatoFlamingo.colors" = {
    source = ../extras/kde/themes/CatppuccinMacchiatoFlamingo.colors;
    force = true;
  };

  # KDE icons
  xdg.dataFile."icons/Papirus-Light" = {
    source = ../extras/kde/icons/Papirus-Light;
    force = true;
  };

  # KDE cursor
  xdg.dataFile."icons/Bibata-Catppuccin-Macchiato" = {
    source = ../extras/kde/icons/Bibata-Catppuccin-Macchiato;
    force = true;
  };

  # KDE sound theme
  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2" = {
    source = ../extras/kde/sounds/modern-minimal-ui-sounds-v1.2;
    force = true;
  };

  # KDE wallpaper
  xdg.dataFile."wallpapers/cat-vibin.png" = {
    source = ../extras/kde/wallpapers/cat-vibin.png;
    force = true;
  };
}
