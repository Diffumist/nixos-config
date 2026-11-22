{
  autoPatchelfHook,
  copyDesktopItems,
  desktop-file-utils,
  fetchurl,
  fontconfig,
  gdk-pixbuf,
  glib,
  glib-networking,
  gst_all_1,
  gtk3,
  lib,
  libX11,
  libsoup_3,
  makeDesktopItem,
  stdenvNoCC,
  wayland,
  webkitgtk_4_1,
  wrapGAppsHook3,
  xdg-utils,
  ...
}:

let
  assetRevision = "14f0046e7d13ee199ad7f7b479bea74728e2f792";
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/yetone/magpie/${assetRevision}/internal/gui/icon-256.png";
    hash = "sha256-V0N8ZZbgWo/PxC1CiMAwqgDthraf411GTWnXAmFQxwQ=";
  };
  license = fetchurl {
    url = "https://raw.githubusercontent.com/yetone/magpie/${assetRevision}/LICENSE";
    hash = "sha256-edLIREcV1LxFPsT4oKryBRpMHuWsCPW9LlhIrvh8dXI=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "magpie";
  version = "0.1.4667";

  src = fetchurl {
    url = "https://github.com/yetone/magpie-releases/releases/download/v${finalAttrs.version}/magpie-linux-${
      {
        x86_64-linux = "amd64";
        aarch64-linux = "arm64";
      }
      .${stdenvNoCC.hostPlatform.system}
    }";
    hash =
      {
        x86_64-linux = "sha256-LYGv9uDdpxmN3kF5asSxWnABWi7YovSnBZIL/jxJ/B4=";
        aarch64-linux = "sha256-F0RYbDk4hsZ8JhW1uvXNukZj6F1YP9F1nZY0XEpTZPk=";
      }
      .${stdenvNoCC.hostPlatform.system};
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    wrapGAppsHook3
  ];

  buildInputs = [
    fontconfig
    gdk-pixbuf
    glib
    glib-networking
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gtk3
    libX11
    libsoup_3
    wayland
    webkitgtk_4_1
  ];

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  desktopItems = [
    (makeDesktopItem {
      name = "magpie";
      desktopName = "magpie";
      comment = "One place to pick every agent's model";
      exec = "magpie %u";
      icon = "magpie";
      categories = [ "Development" ];
      mimeTypes = [ "x-scheme-handler/magpie" ];
      startupWMClass = "magpie";
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/magpie"
    install -Dm644 ${icon} "$out/share/icons/hicolor/256x256/apps/magpie.png"
    install -Dm644 ${license} "$out/share/licenses/magpie/LICENSE"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${
      lib.makeBinPath [
        desktop-file-utils
        xdg-utils
      ]
    })
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  nativeInstallCheckInputs = [ desktop-file-utils ];
  installCheckPhase = ''
    runHook preInstallCheck

    # Without HOME these commands return before account discovery or config migration.
    env -u HOME "$out/bin/magpie" --version | grep -F "${finalAttrs.version}"
    env -u HOME "$out/bin/magpie" --help | grep -F "magpie tray"
    desktop-file-validate "$out/share/applications/magpie.desktop"

    runHook postInstallCheck
  '';

  meta = {
    description = "Desktop model gateway and configuration manager for AI agents";
    homepage = "https://github.com/yetone/magpie";
    changelog = "https://github.com/yetone/magpie/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "magpie";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
