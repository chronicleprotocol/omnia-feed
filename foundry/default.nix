#{ pkgs }: with pkgs; rustPlatform.buildRustPackage {
#  pname = "foundry";
#  version = "0.2.0-f523139";
#  src = fetchFromGitHub {
#    owner = "foundry-rs";
#    repo = "foundry";
#    rev = "f523139a01458a7c0a02b5e8b2f37bc856cf9055";
#    sha256 = "sha256-64lTZlzufjWE3uGGeKF4UXPz7t4xuVWyR6RiMcM+ycs=";
#  };
#  cargoSha256 = "sha256-9GnsVhLhMEtJJbfE9gHjdSwdbOaZuJkjyMvjL3Xarnk=";
#  preInstall = ''
#    pwd
#    ls -la
#    set -ex
#  '';
#}

{ pkgs }: with pkgs; stdenv.mkDerivation {
  name = "foundry-0.2.0-f523139";
  src = fetchzip {
    url = "https://github.com/foundry-rs/foundry/releases/download/nightly-f523139a01458a7c0a02b5e8b2f37bc856cf9055/foundry_nightly_linux_amd64.tar.gz";
    sha256 = "sha256-/WudY6Zi6LEAfEet3E9f9zGLI5nSCpS/lvUl8u54qak=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/bin
    cp $src/cast $out/bin/
  '';

#  installCheckPhase = ''
#    $out/bin/cast --version
#  '';
#  doInstallCheck = true;
}
