{ lib, pkgs, ...}:
{
  services.syncthing = {
    enable = true;
    user = "diffumist";
    openDefaultPorts = true;
    declarative = {
      android = {
        devices = {
          address = ["dynamic"];
          id = "P4HRTS6-CPFCLPU-QYTPFJV-F3NTFQW-3BY42Q6-L5GSIMM-HQO3LPV-UHMGGA3";
        };
      };
      folders = {
        "/home/diffumist/Pictures/ShaftImages/" = {
          id = "d7zsp-fqqmz";
          devices = ["android"];
        };
        "/home/diffumist/Music/Sync" = {
          id = "vghwu-tsmep";
          devices = ["android"];
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 22067 ];
}