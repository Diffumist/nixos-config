{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      size = 2048; # MiB
    }
  ];

  networking = {
    hostName = "dos";
    domain = "diffumist.me";
    nameservers = [ "8.8.8.8" ];
    defaultGateway = "143.110.224.1";
    dhcpcd.enable = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "143.110.239.102"; prefixLength = 20; }
          { address = "10.124.0.2"; prefixLength = 16; }
        ];
        ipv4.routes = [{ address = "143.110.224.1"; prefixLength = 32; }];
      };
    };
  };
}
