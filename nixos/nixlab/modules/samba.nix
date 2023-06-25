{ lib, config, ... }:
let
  user = "diffumist";
  folders = [
    "Music"
    "Videos"
    "Pictures"
    "Downloads"
    "Other"
  ];
  mkSmb = options: {
    path = "/home/${user}/${options}";
    browseable = "yes";
    "read only" = "no";
    "guest ok" = "no";
  };
in
{
  services.samba = {
    enable = true;
    openFirewall = true;
    nsswins = true;
    extraConfig = ''
      guest account = nobody
      map to guest = bad user
    '';
    shares = lib.genAttrs folders mkSmb // {
      Transmission = {
        path = "/var/lib/transmission/Downloads";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0775";
      };
    };
  };
}
