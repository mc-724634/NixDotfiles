{ config, pkgs, lib, inputs, ... }:
let
  plasmaGnomePager = pkgs.stdenvNoCC.mkDerivation {
    pname = "plasma-gnome-pager";
    version = "unstable";
    src = inputs.plasma-gnome-pager-src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/plasma/plasmoids
      pkgdir=$(dirname "$(find . -name metadata.json | head -n1)")
      cp -r "$pkgdir" "$out/share/plasma/plasmoids/com.github.kenansalar.plasma-gnome-pager"
    '';
  };

  splitClock = pkgs.stdenvNoCC.mkDerivation {
    pname = "split-clock";
    version = "unstable";
    src = inputs.split-clock-src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/plasma/plasmoids
      pkgdir=$(dirname "$(find . -name metadata.json | head -n1)")
      cp -r "$pkgdir" "$out/share/plasma/plasmoids/local.widget.simplesplitclock"
    '';
  };
in
{
  home.packages = [ plasmaGnomePager splitClock ];

  home.activation.seedKdeConfig =
    config.lib.dag.entryAfter [ "writeBoundary" ] (
      let
        seeds = [
          { dest = "plasmashellrc"; src = ../extras/kde/configs/plasmashellrc; }
          { dest = "plasma-org.kde.plasma.desktop-appletsrc";
            src = ../extras/kde/configs/plasma-org.kde.plasma.desktop-appletsrc; }
          { dest = "klassy/klassyrc"; src = ../extras/kde/klassy/klassyrc; }
          { dest = "klassy/windecopresetsrc"; src = ../extras/kde/klassy/windecopresetsrc; }
          { dest = "plasma_workspace.notifyrc"; src = ../extras/kde/configs/plasma_workspace.notifyrc; }
          { dest = "appgridrc"; src = ../extras/kde/configs/appgridrc; }
        ];
        seedOne = { dest, src }: ''
          if [ ! -e "$HOME/.config/${dest}" ]; then
            mkdir -p "$(dirname "$HOME/.config/${dest}")"
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
