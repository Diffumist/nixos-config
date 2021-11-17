{ lib
, source
, dbus
, openssl
, libxcb
, python3
, pkg-config
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  inherit (source) pname version src cargoLock;

  buildInputs = [
    dbus
    libxcb
    openssl
  ];
  nativeBuildInputs = buildInputs ++ [ python3 pkg-config ];

  checkFlags = [
    "--skip formatters::tests::test_explain_html_1"
    "--skip formatters::tests::test_explain_html_2"
    "--skip ydclient::tests::test_lookup_word_0"
    "--skip ydclient::tests::test_lookup_word_1"
    "--skip ydclient::tests::test_lookup_word_2"
  ];

  meta = with lib; {
    description = "A rust version of https://github.com/felixonmars/ydcv";
    homepage = "https://github.com/farseerfc/ydcv-rs";
    license = licenses.gpl2;
    maintainers = with maintainers; [ diffumist ];
  };
}
