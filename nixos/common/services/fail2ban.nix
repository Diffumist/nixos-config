_: {
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.1/16"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      factor = "4";
      overalljails = true;
    };
    jails = {
      easytier = ''
        enabled = true
        filter  = easytier
        maxretry = 5
        findtime = 5m
      '';
    };
  };

  environment.etc = {
    "fail2ban/filter.d/easytier.conf".text = ''
      [Definition]
      failregex = remote: \S+://<HOST>:\d+, err: wait resp error:.+
      journalmatch = _SYSTEMD_UNIT=easytier.service
    '';
  };
}
