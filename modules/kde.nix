{ config, pkgs, lib, ... }:
{
  home.activation.seedKdeConfig =
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      let
        seeds = [
          { dest = "kwinrc"; src = ../extras/kde/configs/kwinrc; }
          { dest = "plasmashellrc"; src = ../extras/kde/configs/plasmashellrc; }
          { dest = "plasma-org.kde.plasma.desktop-appletsrc";
            src = ../extras/kde/configs/plasma-org.kde.plasma.desktop-appletsrc; }
        ];
        seedOne = { dest, src }: ''
          if [ ! -e "$HOME/.config/${dest}" ]; then
            mkdir -p "$HOME/.config"
            cp ${src} "$HOME/.config/${dest}"
            chmod 600 "$HOME/.config/${dest}"
          fi
        '';
      in
        lib.concatStringsSep "\n" (map seedOne seeds)
    );

  xdg.dataFile."color-schemes/CatppuccinMacchiatoFlamingo.colors" = {
    source = ../extras/kde/themes/CatppuccinMacchiatoFlamingo.colors;
    force = true;
  };

  xdg.dataFile."icons/Papirus-Dark" = {
    source = ../extras/kde/icons/Papirus-Dark;
    force = true;
  };

  xdg.dataFile."icons/Bibata-Catppuccin-Macchiato" = {
    source = ../extras/kde/icons/Bibata-Catppuccin-Macchiato;
    force = true;
  };

  xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2" = {
    source = ../extras/kde/sounds/modern-minimal-ui-sounds-v1.2;
    force = true;
  };

  xdg.dataFile."wallpapers/cat-vibin.png" = {
    source = ../extras/kde/wallpapers/cat-vibin.png;
    force = true;
  };
}
