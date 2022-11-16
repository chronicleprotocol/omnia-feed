let
  inherit (builtins) map listToAttrs attrValues isString;

  sources = import ./sources.nix;

  nixpkgs = import sources.nixpkgs { };
  inherit (nixpkgs) pkgs;
  inherit (pkgs.lib.strings) removePrefix;

  getName = x: let parse = drv: (builtins.parseDrvName drv).name; in if isString x then parse x else x.pname or (parse x.name);
  ssb-patches = ../ssb-server;
  nixpkgs2 = import sources.nixpkgs2 { };
in rec {
  inherit pkgs;

  nodepkgs = let
    nodepkgs' = import ./nodepkgs.nix { pkgs = pkgs // { stdenv = pkgs.stdenv // { inherit (pkgs) lib; }; }; };
    shortNames = listToAttrs (map (x: {
      name = removePrefix "node_" (getName x.name);
      value = x;
    }) (attrValues nodepkgs'));
  in nodepkgs' // shortNames;

  ssb-server = nodepkgs.ssb-server.override {
    name = "patched-ssb-server";
    buildInputs = with pkgs; [ gnumake nodepkgs.node-gyp-build git ];
    postInstall = ''
      git apply ${ssb-patches}/ssb-db+19.2.0.patch
    '';
  };

  oracle-suite = pkgs.callPackage sources.oracle-suite { buildGoModule = nixpkgs2.buildGo118Module; };
  setzer = pkgs.callPackage sources.setzer { };
  ethsign = pkgs.callPackage (import "${sources.omnia}/ethsign") { };
  foundry = pkgs.callPackage ../foundry { inherit (nixpkgs2) pkgs; };

  omnia = pkgs.callPackage sources.omnia {
    inherit ssb-server oracle-suite setzer ethsign foundry;
    oracleVersion = pkgs.lib.fileContents ../version;
  };

  install-omnia = pkgs.callPackage ../systemd { inherit omnia ssb-server oracle-suite; };
}
