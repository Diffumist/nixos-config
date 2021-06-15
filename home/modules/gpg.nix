{ pkgs, config, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      default-key = "C753CC5B08CA116C83E9253FAFBF30648956131E";
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
