{ pkgs, config, ... }:
{
  # User unit services
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };

  services.syncthing = {
    enable = true;
    extraOptions = [
      "--config=/home/diffumist/.config/syncthing"
      "--data=/home/diffumist/.local/share/syncthing"
    ];
  };

  systemd.user.services = {
    mpris-proxy = {
      Unit.Description = "Mpris Proxy";
      Unit.After = [
        "network.target"
        "sound.target"
      ];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Install.WantedBy = [ "default.target" ];
    };
    aria2 = {
      Unit.Description = "Aria2 Service";
      Unit.After = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.aria2}/bin/aria2c --enable-rpc --conf-path=${config.xdg.configHome}/aria2/aria2.conf";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-abort";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  programs.aria2 = {
    enable = true;
    settings = {
      dir = "${config.home.homeDirectory}/Downloads";
      input-file = "${config.xdg.configHome}/aria2/aria2.session";
      save-session = "${config.xdg.configHome}/aria2/aria2.session";
      file-allocation = "falloc";
      continue = true;
      user-agent = "Transmission/2.77";
    };
  };
}
