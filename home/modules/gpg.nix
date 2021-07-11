{ config, ... }: {
  programs.gpg = {
    enable = true;
    settings = {
      default-key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
      personal-digest-preferences = "SHA256";
      cert-digest-algo = "SHA256";
      homedir = "${config.home.homeDirectory}/storage/personal/gnupg";
    };
  };

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
    # enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };

}
