{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ../common/kernel.nix
    ../common/nixconfig.nix
    ../common/services/fail2ban.nix
    ../common/services/sshd.nix
    "${self}/modules/system/sops.nix"
  ];
  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    secrets.user_passwd_hash = {
      sopsFile = ../common/secrets/server.yaml;
      neededForUsers = true;
    };
  };

  environment.systemPackages = with pkgs; [
    xsz
    duf
    btop
    binutils
    dnsutils
    man-pages
    microfetch
    wireguard-tools
  ];

  time.timeZone = lib.mkDefault "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;

  programs = {
    nexttrace.enable = true;
    command-not-found.enable = false;
    bash = {
      enable = true;
      shellInit = ''
        if [[ $- == *i* ]]; then
          enable -f ${pkgs.flyline}/lib/bash/libflyline.so flyline
        fi
      '';
    };
  };
}
