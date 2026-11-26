{
  autoPatchelfHook,
  fetchurl,
  fontconfig,
  git,
  lib,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  stdenv,
  stdenvNoCC,
  wayland,
  xdg-utils,
  zstd,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "winc";
  version = "0.1.970";

  src = fetchurl {
    url = "https://github.com/DEEIX-AI/Winc/releases/download/v${finalAttrs.version}/winc-${finalAttrs.version}-1-x86_64.pkg.tar.zst";
    hash = "sha256-TIl7VsWXK/zvGWSeF/eX5H/K5Q7cJPxeVvy3dKbTCWo=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    zstd
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  # Wayland/X11 backends and keyboard handling are loaded via dlopen at runtime.
  runtimeDependencies = map lib.getLib [
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    wayland
  ];

  dontBuild = true;
  dontStrip = true;
  # Keep the static musl remote server binaries in lib/winc untouched for SSH upload.
  dontAutoPatchelf = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r usr/bin usr/lib usr/share "$out/"

    for f in \
      "$out/share/applications/winc.desktop" \
      "$out/share/applications/winc-url-handler.desktop" \
      "$out/share/kio/servicemenus/winc-open-file.desktop" \
      "$out/share/kio/servicemenus/winc-open-folder.desktop" \
      "$out/share/nemo/actions/winc-open-current-folder.nemo_action" \
      "$out/share/nemo/actions/winc-open-file.nemo_action" \
      "$out/share/nemo/actions/winc-open-folder.nemo_action"; do
      substituteInPlace "$f" --replace-fail "Exec=winc" "Exec=$out/bin/winc"
    done

    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf -- "$out/bin"

    wrapProgram "$out/bin/winc" \
      --prefix PATH : ${
        lib.makeBinPath [
          fontconfig
          git
          xdg-utils
        ]
      }
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/winc" --version | grep -F "winc ${finalAttrs.version}"
    test -x "$out/bin/winc-pty"
    test -f "$out/lib/winc/winc-server-Linux-x86_64"
    test -f "$out/lib/winc/winc-server-Linux-aarch64"

    runHook postInstallCheck
  '';

  meta = {
    description = "Lighter, faster desktop code editor built with Rust";
    homepage = "https://winc.si";
    changelog = "https://github.com/DEEIX-AI/Winc/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "winc";
    platforms = [ "x86_64-linux" ];
  };
})
