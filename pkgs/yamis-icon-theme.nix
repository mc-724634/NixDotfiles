{ stdenvNoCC, fetchzip, gtk3, lib }:

stdenvNoCC.mkDerivation {
  pname = "yet-another-monochrome-icon-set";
  version = "1.4.2";
  src = fetchzip {
    url = "https://github.com/googIyEYES/YAMIS/raw/main/monochrome-icon-theme.tar.gz";
    hash = "sha256-Sk7GyTnPDFBCK80a9jNdlcyetkISA+OkxfrwPjXAuVM=";
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
