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
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "netease-cloud-music-gtk";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "gmg137";
    repo = "netease-cloud-music-gtk";
    rev = version;
    sha256 = "sha256-42MaylfG5LY+TiYHWQMoh9CiVLShKXSBpMrxdWhujow=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  nativeBuildInputs = [
    glib
    gtk3
    curl
    dbus
    openssl
    pkg-config
    wrapGAppsHook
  ] ++ (with rustPlatform; [
    cargoSetupHook
    rust.cargo
    rust.rustc
  ]) ++ (with gst_all_1;[
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  buildInputs = [
    glib
    gtk3
    curl
    dbus
    openssl
  ]++ (with gst_all_1;[
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  meta = with lib; {
    description = "netease-cloud-music-gtk is a Rust + GTK based netease cloud music player";
    homepage = "https://github.com/gmg137/netease-cloud-music-gtk";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ diffumist ];
  };
}