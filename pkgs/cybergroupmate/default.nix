{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  nodejs_22,
  curl,
  dnsutils,
  ffmpeg,
  file,
  git,
  imagemagick,
  jq,
  pandoc,
  poppler-utils,
  python3,
  ruff,
  unzip,
  uv,
  wget,
  zip,
  ...
}:

let
  src = fetchFromGitHub {
    owner = "Diffumist";
    repo = "CyberGroupmate";
    rev = "bcdeecf31513a6dba12e98378ff1599dcd83a674";
    hash = "sha256-VesVuukBEGVOKl3QVXWdhzw3TxoUqCSJ+PSkS0KQYaU=";
  };

  runtimePath = lib.makeBinPath [
    nodejs_22
    curl
    dnsutils
    ffmpeg
    file
    git
    imagemagick
    jq
    pandoc
    poppler-utils
    python3
    ruff
    unzip
    uv
    wget
    zip
  ];

  dashboard = buildNpmPackage {
    pname = "cybergroupmate-dashboard";
    version = "0.1.0-unstable-2026-06-12";

    src = "${src}/src/dashboard/ui";
    npmDepsHash = "sha256-996he9tV8/JTuT03lSL1qxn9eqS9vftv5gfe0/U5mCE=";

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r ../public/. $out/

      runHook postInstall
    '';
  };
in
buildNpmPackage {
  pname = "cybergroupmate";
  version = "0.1.0-unstable-2026-06-12";

  inherit src;
  nodejs = nodejs_22;
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-9O4HqhMlLeORfGEeIIyDtTm3PNv0avPHSYP3buYCcVg=";

  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    if ! grep -q 'spoiler: (media.type === "video" || media.type === "photo") && media.spoiler' \
      node_modules/@mtcute/core/highlevel/methods/files/normalize-input-media.js; then
      patch -p1 < patches/@mtcute+core+0.29.1.patch
    fi

    appRoot=$out/lib/cybergroupmate
    mkdir -p "$appRoot" "$out/bin"

    cp -r src scripts system-prompts patches "$appRoot"/
    cp package.json package-lock.json config.example.yaml LICENSE README.md "$appRoot"/
    cp -r node_modules "$appRoot"/

    rm -rf "$appRoot/src/dashboard/public"
    mkdir -p "$appRoot/src/dashboard/public"
    cp -r ${dashboard}/. "$appRoot/src/dashboard/public/"

    makeWrapper ${lib.getExe nodejs_22} $out/bin/cybergroupmate \
      --prefix PATH : ${lib.escapeShellArg runtimePath} \
      --run 'app_root=${lib.escapeShellArg "$out/lib/cybergroupmate"}' \
      --run 'for entry in src system-prompts node_modules package.json package-lock.json config.example.yaml; do if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then ln -s "$app_root/$entry" "$entry"; fi; done' \
      --run 'mkdir -p workspace' \
      --run 'case " ''${NODE_OPTIONS-} " in *" --preserve-symlinks "*) ;; *) export NODE_OPTIONS="''${NODE_OPTIONS:+$NODE_OPTIONS }--preserve-symlinks" ;; esac' \
      --run 'case " ''${NODE_OPTIONS-} " in *" --preserve-symlinks-main "*) ;; *) export NODE_OPTIONS="''${NODE_OPTIONS:+$NODE_OPTIONS }--preserve-symlinks-main" ;; esac' \
      --add-flags "node_modules/tsx/dist/cli.mjs" \
      --add-flags "src/main.ts"

    runHook postInstall
  '';

  meta = {
    description = "Code-driven group chat social agent";
    homepage = "https://github.com/Diffumist/CyberGroupmate";
    license = lib.licenses.mit;
    mainProgram = "cybergroupmate";
    platforms = lib.platforms.linux;
  };
}
