{ lib, buildGoModule }:
buildGoModule rec {
  name = "ethsign-${version}";
  version = "0.18.0";
  src = ./.;
  vendorSha256 = "ViEzwV4XcoxLzzJrwYxtV5YBm5Q1CLGO7iUd/l1GXDE=";
  meta = {
    homepage = http://github.com/dapphub/dapptools;
    description = "Make raw signed Ethereum transactions";
    license = [lib.licenses.agpl3];
  };
}
