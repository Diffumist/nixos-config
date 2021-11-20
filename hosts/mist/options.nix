_: {
  dmist = {
    cloud.enable = true;
  };
  modules = {
    services = {
      vaultwarden.enable = true;
      nginx.enable = true;
      fail2ban.enable = true;
      acme.enable = true;
      v2ray = {
        enable = true;
        name = "mist";
      };
    };
  };
}
