_: {
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "::1/128"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      factor = "4";
      overalljails = true;
    };
    jails = {
      vaultwarden = {
        settings = {
          enabled = true;
          filter = "vaultwarden";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
          maxretry = 3;
          bantime = "1h";
        };
      };

      forgejo = {
        settings = {
          enabled = true;
          filter = "forgejo";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=forgejo.service";
          maxretry = 5;
          bantime = "1h";
        };
      };

      immich-caddy = {
        settings = {
          enabled = true;
          filter = "immich-caddy";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=caddy.service";
          maxretry = 5;
          bantime = "1h";
        };
      };

      memos-caddy = {
        settings = {
          enabled = true;
          filter = "memos-caddy";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=caddy.service";
          maxretry = 5;
          bantime = "1h";
        };
      };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/vaultwarden.local".text = ''
      [Definition]
      failregex = ^.*\[WARN\] Invalid password for '.*' from <HOST>\.$
                  ^.*\[WARN\] Two-factor authentication failed .* from <HOST>\.$
    '';

    "fail2ban/filter.d/forgejo.local".text = ''
      [Definition]
      failregex = ^.*Failed authentication attempt for .* from <HOST>.*$
                  ^.*invalid credentials from <HOST>.*$
    '';

    "fail2ban/filter.d/immich-caddy.local".text = ''
      [Definition]
      failregex = ^.*"client_ip":"<HOST>".*"method":"POST".*"uri":"/api/auth/login".*"status":(401|403).*$
      ignoreregex =
    '';

    "fail2ban/filter.d/memos-caddy.local".text = ''
      [Definition]
      failregex = ^.*"client_ip":"<HOST>".*"method":"POST".*"uri":"(?:/api/v1/auth/signin|/api/v1/auth/login)".*"status":(401|403).*$
      ignoreregex =
    '';
  };
}
