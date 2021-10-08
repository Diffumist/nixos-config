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
}
