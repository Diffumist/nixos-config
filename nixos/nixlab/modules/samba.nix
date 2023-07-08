{ lib, ... }:
let
  folders = [
    "Music"
    "Videos"
    "Pictures"
    "Documents"
    "Other"
  ];
  mkSmb = options: {
    path = "/persist/storage/${options}";
    browseable = "yes";
    "read only" = "no";
    "guest ok" = "no";
    comment = "${options} samba share.";
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
    shares = lib.genAttrs folders mkSmb;
  };
}
