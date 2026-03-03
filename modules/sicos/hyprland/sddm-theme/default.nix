{ pkgs, mode ? "dark" }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme-sicos";
  src = ./.;

  installPhase = ''
    mkdir -p $out/share/sddm/themes/sicos
    cp metadata.desktop theme.conf $out/share/sddm/themes/sicos/
    
    # Use the appropriate static Main.qml based on the theme mode
    if [ "${mode}" = "light" ]; then
      cp Main-light.qml $out/share/sddm/themes/sicos/Main.qml
    else
      cp Main-dark.qml $out/share/sddm/themes/sicos/Main.qml
    fi
  '';
}