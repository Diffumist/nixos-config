{ lib, ... }:
let
  folders = [
    "Other"
    "Pictures"
  ];
  mkSync = options: {
    path = "/persist/storage/${options}";
    devices = [ "onix" ];
    versioning = {
      type = "trashcan";
      params.cleanoutDays = "180";
    };
  };
in
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:8384";
    settings = {
      folders = lib.genAttrs folders mkSync;
      options = {
        natEnabled = false;
        globalAnnounceEnabled = false;
      };
      devices = {
        "onix" = {
          id = "SYLPCVN-O2F4TZ6-RJCHN3E-XB7UGWA-Z4RQ5CM-KD3LIXP-EGXKKK6-T6GNUQS";
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 ]; # for quic
  };
}
