{ pkgs, ... }:
let
  uuid = "disable-overview-search@local";

  # Custom extension (source in extras/gnome-extensions/disable-overview-search):
  # overrides SearchController._shouldTriggerSearch so typing in the overview does
  # nothing, instead of just hiding the (still-functional) search entry. Built here
  # rather than shipped pre-built so it stays reproducible from source.
  extensionPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-disable-overview-search";
    version = "1.0";
    src = ../extras/gnome-extensions/disable-overview-search;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      dir=$out/share/gnome-shell/extensions/${uuid}
      mkdir -p "$dir"
      cp metadata.json extension.js "$dir"/
      runHook postInstall
    '';
  };
in
{
  xdg.dataFile."gnome-shell/extensions/${uuid}".source =
    "${extensionPkg}/share/gnome-shell/extensions/${uuid}";
}
