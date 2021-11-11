{ lib
, stdenv
, glib
, gtk3
, curl
, dbus
, openssl
, gst_all_1
, pkg-config
, rustPlatform
, wrapGAppsHook
, fetchurl
, fetchFromGitHub
, makeDesktopItem
}:
let
  pname = "netease-cloud-music-gtk";
  version = "1.2.2";
  cargoSha256 = "sha256-A9wIcESdaJwLY4g/QlOxMU5PBB9wjvIzaXBSqeiRJBM=";
  src = fetchFromGitHub {
    owner = "gmg137";
    repo = "netease-cloud-music-gtk";
    rev = version;
    sha256 = "sha256-42MaylfG5LY+TiYHWQMoh9CiVLShKXSBpMrxdWhujow=";
  };
  desktopIcon = fetchurl {
    url = "https://github.com/gmg137/netease-cloud-music-gtk/raw/${src.rev}/icons/netease-cloud-music-gtk.svg";
    sha256 = "sha256-sxa+sj8KdXgvib2xzrwTuA34as1bsP3XabiyFGUHJsc=";
  };
  desktopItem = fetchurl {
    url = "https://github.com/gmg137/netease-cloud-music-gtk/raw/${src.rev}/netease-cloud-music-gtk.desktop";
    sha256 = "sha256-YtHBjETvVLH02wwQKR18do0Cc4KpToqF8NkefSBcLBE=";
  };
in
rustPlatform.buildRustPackage rec {
  inherit pname version src cargoSha256;

  cargoPatches = [ ./cargo-lock.patch ];

  nativeBuildInputs = [
    glib
    gtk3
    dbus
    pkg-config
    wrapGAppsHook
  ] ++ (with rustPlatform; [
    cargoSetupHook
    rust.cargo
    rust.rustc
  ]);

  buildInputs = [
    glib
    gtk3
    curl
    dbus
    openssl
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  postPatch = ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp ${desktopItem} $out/share/applications/netease-cloud-music-gtk.desktop
    cp ${desktopIcon} $out/share/icons/hicolor/scalable/apps/netease-cloud-music-gtk.svg
  '';

  meta = with lib; {
    description = "netease-cloud-music-gtk is a Rust + GTK based netease cloud music player";
    homepage = "https://github.com/gmg137/netease-cloud-music-gtk";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ diffumist ];
  };
}
