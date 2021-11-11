{ pkgs, ... }:
{
  # User unit services
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "gnome3";
    enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };
}
