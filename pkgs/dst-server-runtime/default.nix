{
  dpkg,
  e2fsprogs,
  fetchurl,
  glibc,
  gnutls,
  krb5,
  lib,
  libidn2,
  libpsl,
  libssh2,
  nghttp2,
  rtmpdump,
  stdenv,
  stdenvNoCC,
  writeShellApplication,
  zlib,
  ...
}:
let
  compatLibraries = stdenvNoCC.mkDerivation {
    pname = "dst-server-compat-libraries";
    version = "2019-03-23";

    srcs = [
      (fetchurl {
        url = "https://snapshot.debian.org/archive/debian/20190323T031635Z/pool/main/c/curl/libcurl3-gnutls_7.64.0-2_amd64.deb";
        hash = "sha256-UGA5xyYBonSgxRCRQ5hGvgq4LyXaA3DJCF2riLcvu/U=";
      })
      (fetchurl {
        url = "https://snapshot.debian.org/archive/debian/20190323T031635Z/pool/main/n/nettle/libnettle6_3.4.1-1_amd64.deb";
        hash = "sha256-WjhMdzrmiwx5BezAq/XkWSV5S2eWdIZtd4PYh4b/sNI=";
      })
      (fetchurl {
        url = "https://snapshot.debian.org/archive/debian/20190323T031635Z/pool/main/o/openldap/libldap-2.4-2_2.4.47%2Bdfsg-3_amd64.deb";
        hash = "sha256-Sk0JCEtEm5WWuRufJ8CGp2VBCUjaB5/RURwBHJFanBw=";
      })
      (fetchurl {
        url = "https://snapshot.debian.org/archive/debian/20190323T031635Z/pool/main/c/cyrus-sasl2/libsasl2-2_2.1.27%2Bdfsg-1_amd64.deb";
        hash = "sha256-1YdvsZPEdqIiChs243eWLc0Cc+P4oupC6bWZ/0gOtlU=";
      })
    ];

    nativeBuildInputs = [ dpkg ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir root
      for src in $srcs; do
        dpkg-deb -x "$src" root
      done

      mkdir -p "$out/lib"
      cp -P root/usr/lib/x86_64-linux-gnu/libcurl-gnutls.so* "$out/lib/"
      cp -P root/usr/lib/x86_64-linux-gnu/libnettle.so* "$out/lib/"
      cp -P root/usr/lib/x86_64-linux-gnu/libldap*.so* "$out/lib/"
      cp -P root/usr/lib/x86_64-linux-gnu/liblber*.so* "$out/lib/"
      cp -P root/usr/lib/x86_64-linux-gnu/libsasl2.so* "$out/lib/"

      runHook postInstall
    '';
  };

  libraryPath = lib.makeLibraryPath [
    compatLibraries
    e2fsprogs
    glibc
    gnutls
    krb5
    libidn2
    libpsl
    libssh2
    nghttp2
    rtmpdump
    stdenv.cc.cc.lib
    zlib
  ];
in
writeShellApplication {
  name = "dst-server";

  text = ''
    : "''${DST_SERVER_ROOT:?DST_SERVER_ROOT must point to the SteamCMD install directory}"

    serverDir="$DST_SERVER_ROOT/bin64"
    serverBinary="$serverDir/dontstarve_dedicated_server_nullrenderer_x64"

    if [[ ! -x "$serverBinary" ]]; then
      echo "DST server binary is missing: $serverBinary" >&2
      exit 1
    fi

    cd "$serverDir"
    exec ${stdenv.cc.bintools.dynamicLinker} \
      --library-path ${libraryPath}:"$serverDir/lib64" \
      "$serverBinary" "$@"
  '';

  meta = {
    description = "Compatibility runtime for the Don't Starve Together dedicated server";
    license = lib.licenses.mit;
    mainProgram = "dst-server";
    platforms = [ "x86_64-linux" ];
  };
}
