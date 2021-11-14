{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../mist/boot.nix
  ];
  swapDevices = [
    {
      device = "/var/swapfile/swapfile";
      size = 1024;
    }
  ];

  networking = {
    hostName = "vessel";
    domain = "diffumist.me";
    nameservers = [ "77.88.8.8" ];
    defaultGateway = "194.147.33.1";
    dhcpcd.enable = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "194.147.33.122"; prefixLength = 20; }
        ];
        ipv4.routes = [{ address = "194.147.33.1"; prefixLength = 32; }];
      };
    };
  };
}
