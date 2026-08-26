{ config, pkgs, lib, ... }:
{
  # KDE configuration
  #
  # These rc files are all things KDE actively reads AND rewrites during
  # normal use (theme application, window-manager state, per-output/per-screen
  # geometry, notification history, etc). Force-symlinking them into the Nix
  # store worked fine as long as every machine had identical hardware, but it
  # breaks on a VM: KWin/Plasma detect a different display (different EDID,
  # output name, screen count) than whatever was baked into these files on
  # the original machine, and because the files are locked read-only symlinks,
  # KWin can't self-correct like it normally would. Result: panels missing,
  # theme not applying, output/scaling settings wrong.
  #
  # Fix: seed each file once on first login (so a fresh VM/install still gets
  # your intended defaults), then leave it alone so KDE can freely rewrite it
  # to match whatever hardware it's actually running on. This is the same
  # pattern already used below for the Plasma applets layout.
  home.activation.seedKdeConfig =
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      let
        seeds = [
          { dest = "kdeglobals";       src = ../extras/kde/configs/kdeglobals; }
          { dest = "kwinrc";           src = ../extras/kde/configs/kwinrc; }
          { dest = "plasma-localerc";  src = ../extras/kde/configs/plasma-localerc; }
          { dest = "plasmanotifyrc";   src = ../extras/kde/configs/plasmanotifyrc; }
          { dest = "plasmarc";         src = ../extras/kde/configs/plasmarc; }
          { dest = "plasmashellrc";    src = ../extras/kde/configs/plasmashellrc; }
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
