{ pkgs }: let
  rev = "b65d58d8f634137c61d8334ecfa81711e77496c6";
in with pkgs; stdenv.mkDerivation rec {
  pname = "foundry";
  version = "0.0.0-${lib.substring 0 7 rev}-0";
  src = fetchzip {
    url = "https://github.com/foundry-rs/foundry/releases/download/nightly-${rev}/foundry_nightly_linux_amd64.tar.gz";
    sha256 = "sha256-2isjF7yINVrhD+aW80c37ldD0q/Obf6YhqS/JB/kRJk=";
    stripRoot = false;
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
    autoPatchelfHook
  ];
  installPhase = let
    path = lib.makeBinPath [ git ];
  in ''
    mkdir -p $out/bin
    mv cast $out/bin/
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
