{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = (pkgs.chromium.override {
      # Hardware video decoding support
      commandLineArgs = ''
        --enable-gpu-rasterization \
        --enable-zero-copy \
        --enable-features=VaapiVideoDecoder \
      '';
    });
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "ponfpcnoihfmfllpaingbgckeeldkhle" # Enhancer for YouTube
      "jklfcpboamajpiikgkbjcnnnnooefbhh" # pakku for bilibili
      "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      "niloccemoadcdkdjlinkgdfekeahmflj" # Save to Pocket
      "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "pncfbmialoiaghdehhbnbhkkgmjanfhe" # uBlacklist
    ];
  };

}
