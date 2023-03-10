{ stdenv, makeWrapper, symlinkJoin, lib, glibcLocales, coreutils, bash, parallel, bc, jq, gnused,
datamash, gnugrep, curl,
ethsign, foundry, setzer,
ssb-server, oracle-suite }:
stdenv.mkDerivation rec {
  name = "omnia-${version}";
  version = lib.fileContents ../version;
  src = ./.;

  buildInputs =
    [ coreutils bash parallel bc jq gnused datamash gnugrep ssb-server ethsign foundry setzer oracle-suite curl ];
  nativeBuildInputs = [ makeWrapper ];
  passthru.runtimeDeps = buildInputs;

  buildPhase = ''
    find ./bin -type f | while read -r x; do patchShebangs "$x"; done
    find ./exec -type f | while read -r x; do patchShebangs "$x"; done
  '';

  doCheck = true;
  checkPhase = ''
    find ./test -path "*/test/*.sh" -executable | while read -r x; do
      patchShebangs "$x"
      PATH="./exec:$PATH" $x
    done
  '';

  installPhase = let
    path = lib.makeBinPath passthru.runtimeDeps;
    locales = lib.optionalString (glibcLocales != null) ''--set LOCALE_ARCHIVE "${glibcLocales}"/lib/locale/locale-archive'';
  in ''
    mkdir -p $out

    cp -r ./lib $out/lib
    cp -r ./config $out/config

    cp -r ./bin $out/bin
    chmod +x $out/bin/*
    find $out/bin -type f | while read -r x; do
      wrapProgram "$x" \
        --prefix PATH : "$out/exec:${path}" \
        --set OMNIA_VERSION "${version}" \
        ${locales}
    done

    cp -r ./exec $out/exec
    chmod +x $out/exec/*
    find $out/exec -type f | while read -r x; do
      wrapProgram "$x" \
        --prefix PATH : "$out/exec:${path}" \
        ${locales}
    done
  '';

  meta = {
    description = "Omnia is a Feed and Relay Oracle client";
    homepage = "https://github.com/chronicleprotocol/omnia";
    license = lib.licenses.gpl3;
    inherit version;
  };
}
