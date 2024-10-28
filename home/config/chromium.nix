{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium.override {
      # Hardware video decoding support
      commandLineArgs = ''
        --enable-gpu-rasterization \
        --enable-zero-copy \
        --enable-features=VaapiVideoDecoder \
        --ignore-gpu-blocklist \
      '';
    };
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "ponfpcnoihfmfllpaingbgckeeldkhle" # Enhancer for YouTube
      "jklfcpboamajpiikgkbjcnnnnooefbhh" # pakku for bilibili
      "ogjibjphoadhljaoicdnjnmgokohngcc" # Openai Translator
      "gcalenpjmijncebpfijmoaglllgpjagf" # Tampermonkey
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin
      "pncfbmialoiaghdehhbnbhkkgmjanfhe" # uBlacklist
      "mpkodccbngfoacfalldjimigbofkhgjn" # Aria2 for Chrome
      "onnepejgdiojhiflfoemillegpgpabdm" # V2ex Polish
      "dkndmhgdcmjdmkdonmbgjpijejdcilfh" # pixiv
      "apmmpaebfobifelkijhaljbmpcgbjbdo" # Stylus
    ];
  };

  systemd.user.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
}
