{ lib, config, ... }:
let
  user = "diffumist";
  folders = [
    "Other"
  ];
  mkSync = options: {
    path = "/home/${user}/${options}";
    devices = [ "nixlab" "onix" ];
    versioning = {
      type = "trashcan";
      params.cleanoutDays = "180";
    };
  };
in
{
  # sops.secrets = {
  #   "syncthing/nixlab" = {
  #     owner = "diffumist";
  #     restartUnits = [ "syncthing.service" "syncthing-init.service" ];
  #   };
  #   "syncthing/onix" = {
  #     owner = "diffumist";
  #     restartUnits = [ "syncthing.service" "syncthing-init.service" ];
  #   };
  # };
  # services.syncthing = {
  #   enable = true;
  #   openDefaultPorts = true;
  #   user = "${user}";
  #   devices = {
  #     "nixlab" = {
  #       id = config.sops.secrets."syncthing/nixlab".path;
  #     };
  #     "onix" = {
  #       id = config.sops.secrets."syncthing/onix".path;
  #     };
  #   };
  #   dataDir = "/home/${user}/.local/share/syncthing";
  #   configDir = "/home/${user}/.config/syncthing";
  #   guiAddress = "0.0.0.0:8384";
  #   folders = lib.genAttrs folders mkSync;
  #   extraOptions = {
  #     options = {
  #       natEnabled = false;
  #       globalAnnounceEnabled = false;
  #     };
  #   };
  # };
  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 ]; # for quic
  };
}
