{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  libxcb,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  wayland,
  git,
  xdg-utils,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "wu";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/dstrml/wu/releases/download/v${finalAttrs.version}/wu-linux-${stdenv.hostPlatform.parsed.cpu.name}.tar.gz";
    hash =
      {
        x86_64-linux = "sha256-bPWQ8yNOQIh9oQh9Sv6xCwTPLCqfCTyOnGiZomSjWtw=";
        aarch64-linux = "sha256-Rf7zLB0tDswKTT4DvUHR7ONwgIGcJZaqp5Ss9WjQvG8=";
      }
      .${stdenv.hostPlatform.system};
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  # The renderer loads these libraries at runtime rather than linking them.
  runtimeDependencies = map lib.getLib [
    libglvnd
    vulkan-loader
    wayland
  ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    # Use Nix libraries instead of the distribution-specific bundled copies.
    cp -r bin libexec share "$out/"
    install -Dm644 licenses.md "$out/share/doc/wu/licenses.md"
    substituteInPlace "$out/share/applications/me.farshed.Wu.desktop" \
      --replace-fail "Exec=wu" "Exec=$out/bin/wu"

    runHook postInstall
  '';

  postFixup = ''
    # The immutable package must be updated through Nix.
    wrapProgram "$out/libexec/wu-editor" \
      --set ZED_UPDATE_EXPLANATION "Updates are managed by Nix." \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          xdg-utils
        ]
      }
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/wu" --version | grep -F "${finalAttrs.version}"
    "$out/libexec/wu-editor" --help | grep -F "Usage:"

    runHook postInstallCheck
  '';

  meta = {
    description = "Native code editor and agent workspace based on Zed";
    homepage = "https://github.com/dstrml/wu";
    changelog = "https://github.com/dstrml/wu/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      gpl3Plus
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "wu";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
