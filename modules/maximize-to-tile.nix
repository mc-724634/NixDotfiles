{ pkgs, ... }:
let
  uuid = "maximize-to-tile@local";

  # Custom extension (source in extras/gnome-extensions/maximize-to-tile, see
  # README): GNOME gives extensions no hook on the titlebar maximize button
  # itself, so this reacts to the resulting Meta.Window maximized state
  # instead and turns it into a gapped resize, matching Tiling Shell's
  # edge-drag tiling. Built here (schema compiled) rather than shipped
  # pre-built so it stays reproducible from source.
  extensionPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-maximize-to-tile";
    version = "1.0";
    src = ../extras/gnome-extensions/maximize-to-tile;
    nativeBuildInputs = [ pkgs.glib ];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      dir=$out/share/gnome-shell/extensions/${uuid}
      mkdir -p "$dir"
      cp metadata.json extension.js "$dir"/
      cp -r schemas "$dir"/
      glib-compile-schemas "$dir/schemas"
      runHook postInstall
    '';
  };
in
{
  xdg.dataFile."gnome-shell/extensions/${uuid}".source =
    "${extensionPkg}/share/gnome-shell/extensions/${uuid}";
}
