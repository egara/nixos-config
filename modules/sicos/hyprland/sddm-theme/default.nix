{ pkgs, colors ? null, fontName ? "Monospace" }:

let
  # Fallback colors if not provided
  c = if colors != null then colors else {
    base00 = "0f0f0f";
    base01 = "1a1a1a";
    base02 = "222222";
    base03 = "333333";
    base04 = "555555";
    base05 = "cccccc";
    base06 = "dddddd";
    base07 = "eeeeee";
    base08 = "ff0000";
    base09 = "ff8800";
    base0A = "ffff00";
    base0B = "00ff00";
    base0C = "00ffff";
    base0D = "0000ff";
    base0E = "ff00ff";
    base0F = "ffffff";
  };
  
  mainQml = import ./Main.nix { colors = c; inherit fontName; };
in
pkgs.stdenv.mkDerivation {
  name = "sddm-theme-sicos";
  src = ./.;

  installPhase = ''
    mkdir -p $out/share/sddm/themes/sicos
    cp metadata.desktop theme.conf $out/share/sddm/themes/sicos/
    
    # Generate Main.qml from Nix string
    cp ${pkgs.writeText "Main.qml" mainQml} $out/share/sddm/themes/sicos/Main.qml
  '';
}
