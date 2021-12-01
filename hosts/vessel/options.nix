_: {
  modules = {
    cloud.enable = true;
    nginx.enable = true;
    fail2ban.enable = true;
    acme.enable = true;
    transmission.enable = true;
    v2ray = {
      enable = true;
      name = "vessel";
    };
  };
}
