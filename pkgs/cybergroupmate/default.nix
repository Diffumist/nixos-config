{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  autoPatchelfHook,
  nodejs_22,
  bashInteractive,
  python3,
  pkg-config,
  ffmpeg,
  zip,
  unzip,
  wget,
  curl,
  jq,
  imagemagick,
  git,
  uv,
  ruff,
  pandoc,
  poppler-utils,
  dnsutils,
  file,
  stdenv,
  ...
}:

let
  version = "0-unstable-2026-05-27";
  buildNpmPackage' = buildNpmPackage.override { nodejs = nodejs_22; };

  src = fetchFromGitHub {
    owner = "Archeb";
    repo = "CyberGroupmate";
    rev = "cd211bc13b8ad7c4c10aed3b9b136d646dab0159";
    hash = "sha256-f8ipK20wi79ee0YsufF1zr+U6wgGdHfwMfO6AYfUEr4=";
  };

  dashboard = buildNpmPackage' {
    pname = "cybergroupmate-dashboard";
    inherit version;

    src = "${src}/src/dashboard/ui";

    npmDepsHash = "sha256-996he9tV8/JTuT03lSL1qxn9eqS9vftv5gfe0/U5mCE=";

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r ../public $out/public

      runHook postInstall
    '';
  };

  runtimePackages = [
    ffmpeg
    zip
    unzip
    wget
    curl
    jq
    imagemagick
    git
    python3
    uv
    ruff
    pandoc
    poppler-utils
    dnsutils
  ];
in
buildNpmPackage' {
  pname = "cybergroupmate";
  inherit version src;

  npmDepsHash = "sha256-R2vauPncCcFhIHsXEjexgura++D5EMQFljtcvlaWPfU=";

  postPatch = ''
    substituteInPlace src/main.ts \
      --replace-fail 'const sandboxPool = new SandboxPool({' 'const sandboxPool = new SandboxPool({
        workDir: process.cwd(),'
    grep -q 'workDir: process.cwd(),' src/main.ts

    substituteInPlace src/sandbox/sandbox.ts \
      --replace-fail 'pty.spawn("/bin/bash", ["--rcfile", this.bashrcPath], {' 'pty.spawn(process.env.CYBERGROUPMATE_SHELL ?? "/bin/bash", ["--rcfile", this.bashrcPath], {'
    grep -q 'CYBERGROUPMATE_SHELL' src/sandbox/sandbox.ts
  '';

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    pkg-config
    python3
  ];

  buildInputs = [
    file
    stdenv.cc.cc.lib
  ];

  npmFlags = [ "--build-from-source" ];
  dontNpmBuild = true;
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
  ];

  installPhase = ''
    runHook preInstall

    appDir=$out/lib/cybergroupmate
    mkdir -p "$appDir" "$out/bin"

    cp -r \
      package.json \
      node_modules \
      src \
      system-prompts \
      config.example.yaml \
      "$appDir"/

    rm -rf "$appDir/src/dashboard/public"
    cp -r ${dashboard}/public "$appDir/src/dashboard/public"

    makeWrapper ${lib.getExe nodejs_22} $out/bin/cybergroupmate \
      --prefix PATH : ${lib.makeBinPath runtimePackages} \
      --set-default CYBERGROUPMATE_APPDIR "$appDir" \
      --set-default CYBERGROUPMATE_SHELL ${lib.getExe bashInteractive} \
      --run 'runtimeDir="''${CYBERGROUPMATE_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}/cybergroupmate}"' \
      --run 'mkdir -p "$runtimeDir"' \
      --run 'for path in src system-prompts node_modules package.json config.example.yaml; do if [ ! -e "$runtimeDir/$path" ]; then ln -s "$CYBERGROUPMATE_APPDIR/$path" "$runtimeDir/$path"; fi; done' \
      --run 'cd "$runtimeDir"' \
      --add-flags "$appDir/node_modules/tsx/dist/cli.mjs" \
      --add-flags "$appDir/src/main.ts"

    runHook postInstall
  '';

  meta = {
    description = "Code-driven group chat social agent";
    homepage = "https://github.com/Archeb/CyberGroupmate";
    license = lib.licenses.mit;
    mainProgram = "cybergroupmate";
    platforms = lib.platforms.linux;
  };
}
