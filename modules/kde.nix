{ config, pkgs, ... }:

{
  # KDE configuration
  xdg.configFile = {
    "kdeglobals".source =
      ../extras/kde/configs/kdeglobals;

    "kwinrc".source =
      ../extras/kde/configs/kwinrc;

    "plasma-localerc".source =
      ../extras/kde/configs/plasma-localerc;

    "plasmanotifyrc".source =
      ../extras/kde/configs/plasmanotifyrc;

    "plasmarc".source =
      ../extras/kde/configs/plasmarc;

    "plasmashellrc".source =
      ../extras/kde/configs/plasmashellrc;
  };

  # Seed Plasma's desktop/panel layout on first setup.
  # After that, Plasma owns this file and can modify it normally.
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
  xdg.dataFile."color-schemes/CatppuccinMacchiatoFlamingo.colors".source =
    ../extras/kde/themes/CatppuccinMacchiatoFlamingo.colors;

  # KDE icons
  xdg.dataFile."icons/Papirus-Light".source =
    ../extras/kde/icons/Papirus-Light;

  # KDE cursor
  xdg.dataFile."icons/Bibata-Catppuccin-Macchiato".source =
    ../extras/kde/icons/Bibata-Catppuccin-Macchiato;

  # KDE sound theme
  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2".source =
    ../extras/kde/sounds/modern-minimal-ui-sounds-v1.2;

  # KDE wallpaper
  xdg.dataFile."wallpapers/cat-vibin.png".source =
    ../extras/kde/wallpapers/cat-vibin.png;
}
