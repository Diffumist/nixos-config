{ lib, config, ... }:
let
  folders = [
    "Other"
    "Pictures"
    "Documents"
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
    devices = {
      "onix" = {
        id = "SYLPCVN-O2F4TZ6-RJCHN3E-XB7UGWA-Z4RQ5CM-KD3LIXP-EGXKKK6-T6GNUQS";
      };
    };
    guiAddress = "0.0.0.0:8384";
    folders = lib.genAttrs folders mkSync;
    extraOptions = {
      options = {
        natEnabled = false;
        globalAnnounceEnabled = false;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 ]; # for quic
  };
}
