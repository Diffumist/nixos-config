{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeWrapper,
  node-gyp,
  nodejs-slim_22,
  nodejs_22,
  pnpm_11,
  pnpmConfigHook,
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
  rev = "0c00f780683b686d950666c4b935eac09a0e7b84";
  version = "0.1.0-unstable-2026-06-16";
  pnpm = pnpm_11.override { nodejs-slim = nodejs-slim_22; };

  src = fetchFromGitHub {
    owner = "Archeb";
    repo = "CyberGroupmate";
    inherit rev;
    hash = "sha256-4RZ1xIzoJ5Te3ShFkkCe1t3uiwEAtZ4z8HSMlQ+dd7I=";
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

  dashboard = stdenv.mkDerivation (finalAttrs: {
    pname = "cybergroupmate-dashboard";
    inherit version src;

    pnpmRoot = "src/dashboard/ui";

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      sourceRoot = "${finalAttrs.src.name}/src/dashboard/ui";
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-SLBtfDuhSodH8G8nQ9DY2wDYlq4WytqMxDjAbqZ74K8=";
    };

    nativeBuildInputs = [
      nodejs_22
      pnpm
      pnpmConfigHook
    ];

    buildPhase = ''
      runHook preBuild

      pushd "$pnpmRoot"
      pnpm run build
      popd

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r src/dashboard/public/. $out/

      runHook postInstall
    '';
  });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "cybergroupmate";
  inherit version src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-2WgD872lsp/c6ITlSuJkWA13KYtyGlgOhGQF2U0DXi0=";
  };

  env = {
    npm_config_nodedir = nodejs_22;
    npm_config_node_gyp = "${node-gyp}/lib/node_modules/node-gyp/bin/node-gyp.js";
  };

  nativeBuildInputs = [
    nodejs_22
    node-gyp
    python3
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    export npm_config_nodedir=${nodejs_22}
    export npm_config_node_gyp=${node-gyp}/lib/node_modules/node-gyp/bin/node-gyp.js
    export pnpm_config_nodedir=${nodejs_22}

    mkdir -p "$HOME/.cache/node-gyp/${nodejs_22.version}" "$HOME/.node-gyp/${nodejs_22.version}"
    echo 11 > "$HOME/.cache/node-gyp/${nodejs_22.version}/installVersion"
    echo 11 > "$HOME/.node-gyp/${nodejs_22.version}/installVersion"
    ln -sf ${nodejs_22}/include "$HOME/.cache/node-gyp/${nodejs_22.version}/include"
    ln -sf ${nodejs_22}/include "$HOME/.node-gyp/${nodejs_22.version}/include"

    pnpm --reporter append-only rebuild esbuild better-sqlite3 protobufjs

    pushd node_modules/.pnpm/node-pty@1.1.0/node_modules/node-pty
    node scripts/prebuild.js || node-gyp rebuild --verbose
    node scripts/post-install.js
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    appRoot=$out/lib/cybergroupmate
    mkdir -p "$appRoot" "$out/bin"

    cp -r src scripts system-prompts patches "$appRoot"/
    cp package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json config.example.yaml LICENSE README.md "$appRoot"/
    cp -r node_modules "$appRoot"/

    rm -rf "$appRoot/src/dashboard/public"
    mkdir -p "$appRoot/src/dashboard/public"
    cp -r ${dashboard}/. "$appRoot/src/dashboard/public/"

    makeWrapper ${lib.getExe nodejs_22} $out/bin/cybergroupmate \
      --prefix PATH : ${lib.escapeShellArg runtimePath} \
      --run 'app_root=${lib.escapeShellArg "$out/lib/cybergroupmate"}' \
      --run 'for entry in src system-prompts node_modules package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json config.example.yaml; do if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then ln -s "$app_root/$entry" "$entry"; fi; done' \
      --run 'mkdir -p workspace' \
      --add-flags "node_modules/tsx/dist/cli.mjs" \
      --add-flags "src/main.ts"

    runHook postInstall
  '';

  meta = {
    description = "Code-driven group chat social agent";
    homepage = "https://github.com/Archeb/CyberGroupmate";
    license = lib.licenses.mit;
    mainProgram = "cybergroupmate";
    platforms = lib.platforms.linux;
  };

  passthru = {
    inherit rev src;
    dockerContext = src;
    dockerfile = "${src}/Dockerfile";
    dockerImageName = "localhost/cybergroupmate-agentic";
    dockerImageTag = lib.substring 0 12 rev;
  };
})
