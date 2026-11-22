{ config, lib, ... }:
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

  my.systemd.harden = lib.mkIf config.services.fail2ban.enable [ "fail2ban" ];
  systemd.services = lib.mkIf config.services.fail2ban.enable {
    fail2ban.serviceConfig = {
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      SystemCallFilter = [
        "@system-service"
        "~@clock @cpu-emulation @debug @module @mount @obsolete @raw-io @reboot @swap"
      ];
    };
  };
}
