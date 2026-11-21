{ lib, ... }:
{
  services.fail2ban = {
    enable = lib.mkDefault true;
    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "fc00::/7"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "1w";
      factor = "4";
      overalljails = true;
    };
    jails.sshd.settings.enabled = false;
  };
}
