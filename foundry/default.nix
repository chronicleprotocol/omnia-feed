{ pkgs }: let
  rev = "cb925b100b400b27875ad0667c2bec7e8d55d89c";
in with pkgs; stdenv.mkDerivation rec {
  pname = "foundry";
  version = "0.0.0-${lib.substring 0 6 rev}";
#  src = fetchzip {
#    url = "https://github.com/foundry-rs/foundry/releases/download/nightly-${rev}/foundry_nightly_linux_amd64.tar.gz";
#    sha256 = "sha256-TnlcU2wt1ml5lH25jYg1ZI0BXgO9FB08Lzf5i32609c=";
#    stripRoot = false;
#  };
  src = ./.;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    autoPatchelfHook
  ];
  installPhase = let
    path = lib.makeBinPath [ git ];
  in ''
    set -e
    mkdir -p $out/bin
    cp $src/cast $out/bin/
    chmod +x $out/bin/*
    find $out/bin -type f | while read -r x; do
      wrapProgram "$x" --prefix PATH : "${path}"
    done
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/cast --version
  '';
}
