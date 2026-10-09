# OpenCode v2 packaged from the official prebuilt binary.
#
# nixpkgs only ships OpenCode v1 (1.18.x), and the official flake for the 2.0
# branch (github:anomalyco/opencode/2.0) currently fails to build from source
# (its bun.lock is out of sync with its package.json). Until that is fixed
# upstream, this overlay packages the official prebuilt binary published at
# https://opencode.ai/v2/docs
#
# This overlay replaces nixpkgs' `opencode` (v1) with v2 everywhere.
#
# NOTE on the loader wrapper: the binary is a Bun single-file executable that
# locates its embedded JS payload by file offset. Running patchelf on it
# (autoPatchelfHook) breaks that payload, so the binary is left untouched and
# instead invoked through the Nix glibc dynamic loader. The musl variant is
# not an alternative: it is not fully static (it needs libc.musl).
#
# To update: bump `version` and refresh the hashes, e.g.
#   nix hash file --sri <(curl -fsSL https://opencode.ai/files/bin/<version>/opencode-linux-x64.tar.gz)

final: prev: {
  opencode = final.stdenvNoCC.mkDerivation rec {
    pname = "opencode";
    version = "2.0.6";

    src = final.fetchurl (
      {
        x86_64-linux = {
          url = "https://opencode.ai/files/bin/${version}/opencode-linux-x64.tar.gz";
          hash = "sha256-gzADIT4VUmbAc64/GeKmPQJ7nWaovJpGEOycnUs2nI0=";
        };
        aarch64-linux = {
          url = "https://opencode.ai/files/bin/${version}/opencode-linux-arm64.tar.gz";
          hash = "sha256-wHS+xv0FJWqqRFJamYZBhibgBFmUQ38w6Cs+zgkpGdg=";
        };
      }
        .${final.stdenv.hostPlatform.system} or (throw "opencode-v2: unsupported system ${final.stdenv.hostPlatform.system}")
    );

    # The tarball contains a single file (`opencode`) at its root
    sourceRoot = ".";

    # Keep the binary bit-identical to upstream: no ELF patching, no rpath
    # shrinking, nothing that could break the embedded Bun payload
    dontFixup = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 opencode $out/bin/.opencode-unwrapped

      mkdir -p $out/bin
      cat > $out/bin/opencode <<EOF
      #!${final.runtimeShell}
      # ripgrep available on PATH, same as the official Nix package
      export PATH="${final.lib.makeBinPath [ final.ripgrep ]}:\$PATH"
      exec ${final.stdenv.cc.libc}/lib64/ld-linux-x86-64.so.2 $out/bin/.opencode-unwrapped "\$@"
      EOF
      chmod +x $out/bin/opencode

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "The open source AI coding agent (v2, official prebuilt binary)";
      homepage = "https://opencode.ai";
      license = licenses.mit;
      mainProgram = "opencode";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  };
}
