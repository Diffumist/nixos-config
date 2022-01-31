{ pkgs, config, ... }:
{
  # User unit services
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "gnome3";
    enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };

  systemd.user.services = {
    mpris-proxy = {
      Unit.Description = "Mpris Proxy";
      Unit.After = [ "network.target" "sound.target" ];
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
      continue = true;
      enable-dht = true;
      bt-enable-lpd = true;
      enable-peer-exchange = true;
      peer-id-prefix = "-TR2770-";
      user-agent = "Transmission/2.77";
      bt-tracker = "udp://tracker.opentrackr.org:1337/announce,udp://9.rarbg.com:2810/announce,udp://open.tracker.cl:1337/announce,udp://tracker.openbittorrent.com:6969/announce,udp://exodus.desync.com:6969/announce,udp://www.torrent.eu.org:451/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.tiny-vps.com:6969/announceudp://tracker.pomf.se:80/announce,udp://retracker.netbynet.ru:2710/announce,udp://retracker.lanta-net.ru:2710/announce,udp://opentor.org:2710/announce,udp://open.stealth.si:80/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://explodie.org:6969/announce,udp://bt2.archive.org:6969/announce,udp://bt1.archive.org:6969/announce,https://tracker.tamersunion.org:443/announce,https://tracker.nanoha.org:443/announce,https://tracker.lilithraws.cf:443/announce";
    };
  };
}
