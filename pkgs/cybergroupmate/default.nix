{
  coreutils,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  gnugrep,
  gnused,
  makeWrapper,
  nix-update,
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
  writeShellApplication,
  zip,
  ...
}:

let
  rev = "08d218d8bb5f2aee875fb75b7492d3b0e6d759ff";
  version = "0.1.0-unstable-2026-08-06";
  pnpm = pnpm_11.override { nodejs-slim = nodejs-slim_22; };

  src = fetchFromGitHub {
    owner = "Archeb";
    repo = "CyberGroupmate";
    inherit rev;
    hash = "sha256-Xo/7/jbiet6jzJNncJW3VpG1YszAy6X6SmFAy1W9Hbs=";
  };

  updateScript = writeShellApplication {
    name = "update-cybergroupmate";
    runtimeInputs = [
      coreutils
      git
      gnugrep
      gnused
      nix-update
    ];
    text = ''
      repo_root="$(git rev-parse --show-toplevel)"
      tmpdir="$(mktemp -d)"
      package_file="$repo_root/pkgs/cybergroupmate/default.nix"
      completed=false

      cleanup() {
        status=$?
        if [ "$completed" != true ] && [ -e "$tmpdir/default.nix" ]; then
          cp "$tmpdir/default.nix" "$package_file"
        fi
        rm -rf "$tmpdir"
        exit "$status"
      }
      trap cleanup EXIT

      git -C "$tmpdir" init --quiet
      git -C "$tmpdir" fetch --depth=1 --quiet \
        https://github.com/Archeb/CyberGroupmate.git \
        refs/heads/agentic

      new_rev="$(git -C "$tmpdir" rev-parse FETCH_HEAD)"
      new_date="$(git -C "$tmpdir" show --no-patch --format=%cs FETCH_HEAD)"

      if [ "$new_rev" = ${lib.escapeShellArg rev} ]; then
        echo "CyberGroupmate is already at agentic commit $new_rev"
        completed=true
        exit 0
      fi

      if [ "$(grep -Ec '^  rev = "[0-9a-f]{40}";$' "$package_file")" -ne 1 ]; then
        echo "expected exactly one CyberGroupmate rev assignment" >&2
        exit 1
      fi
      if [ "$(grep -Ec '^  version = "[^"]+";$' "$package_file")" -ne 1 ]; then
        echo "expected exactly one CyberGroupmate version assignment" >&2
        exit 1
      fi

      cp "$package_file" "$tmpdir/default.nix"
      sed -i \
        -e "s|^  rev = \"[0-9a-f]\\{40\\}\";|  rev = \"$new_rev\";|" \
        -e "s|^  version = \"[^\"]*\";|  version = \"0.1.0-unstable-$new_date\";|" \
        "$package_file"

      cd "$repo_root"
      nix-update --flake --version=skip cybergroupmate
      nix-update --flake --version=skip --subpackage=dashboard cybergroupmate
      completed=true
    '';
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
    inherit dashboard rev src;
    nixUpdateUseUpdateScript = true;
    updateScript = lib.getExe updateScript;
    dockerContext = src;
    dockerfile = "${src}/Dockerfile";
    dockerImageName = "localhost/cybergroupmate-agentic";
    dockerImageTag = lib.substring 0 12 rev;
  };
})
