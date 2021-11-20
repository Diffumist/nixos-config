{ config, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.services.fail2ban;
in
{
  options.modules.services.fail2ban = {
    enable = mkEnableOption "fail2ban";
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      ignoreIP = [ "127.0.0.1/16" "192.168.1.0/24" ];
      banaction-allports = "iptables-allports";
      bantime-increment = {
        enable = true;
        maxtime = "168h";
        factor = "4";
      };
      jails = {
        DEFAULT = ''
          blocktype = DROP
          bantime = 1h
          findtime = 1h
        '';
        # See https://github.com/dani-garcia/bitwarden_rs/wiki/Fail2Ban-Setup
        vaultwarden = ''
          enabled = true
          filter = vaultwarden
          port = 80,443,8443
          maxretry = 5
        '';
      };
    };

    # Extra filters
    environment.etc = {
      "fail2ban/filter.d/vaultwarden.conf".text = ''
        [INCLUDES]
        before = common.conf
        [Definition]
        failregex = ^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
        ignoreregex =
        journalmatch = _SYSTEMD_UNIT=vaultwarden.service
      '';
      "fail2ban/filter.d/gitea.conf".text = ''
        [Definition]
        failregex =  .*(Failed authentication attempt|invalid credentials|Attempted access of unknown user).* from <HOST>
        ignoreregex =
        journalmatch = _SYSTEMD_UNIT=gitea.service
      '';
    };
  };
}
