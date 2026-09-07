{ stdenvNoCC, fetchzip, gtk3, lib }:

stdenvNoCC.mkDerivation {
  pname = "yet-another-monochrome-icon-set";
  version = "1.4.2";
  src = fetchzip {
    url = "https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set/get/master.tar.gz";
    hash = ""; # nix will tell you the correct hash on first build failure
  };
  nativeBuildInputs = [ gtk3 ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/yet-another-monochrome-icon-set
    cp -a actions apps categories devices emblems index.theme mimetypes places preferences status $out/share/icons/yet-another-monochrome-icon-set/
    runHook postInstall
  '';
  meta = with lib; {
    description = "Yet Another Monochrome Icon Set For KDE Plasma";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
