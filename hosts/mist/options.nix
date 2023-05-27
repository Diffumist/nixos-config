{ config, ... }: {
  modules = {
    vaultwarden.enable = false;
    nginx.enable = true;
    fail2ban.enable = true;
    acme = {
      enable = true;
      domain = config.networking.domain;
    };
    xray.enable = true;
  };
}
