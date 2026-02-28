{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme-sicos";
  src = ./.;
  installPhase = ''
    mkdir -p $out/share/sddm/themes/sicos
    cp -r * $out/share/sddm/themes/sicos/
  '';
}
