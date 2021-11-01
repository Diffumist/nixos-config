{ pkgs, ... }:
{
  # User unit services
  systemd.user.services."trash-empty" = {
    Unit.Description = "Empty trash older than 30 days";
    Service.ExecStart =
      "${pkgs.trash-cli}/bin/trash-empty 30";
  };
  systemd.user.timers."trash-empty" = {
    Timer = {
      OnCalendar = "Sat";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
    # enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };
}
