{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./options.nix
  ];

  networking = {
    hostName = "mist";
    domain = "diffumist.me";
    nameservers = [ "205.185.112.68" ];
    defaultGateway = "209.141.44.1";
    dhcpcd.enable = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "209.141.44.76"; prefixLength = 24; }
        ];
        ipv4.routes = [
          { address = "209.141.44.1"; prefixLength = 32; }
        ];
      };
    };
    firewall = {
      allowedTCPPorts = [ 12345 12346 ];
    };
  };

  virtualisation.oci-containers.containers = {
    subconverter = {
      image = "docker.io/tindy2013/subconverter:latest";
      ports = [ "0.0.0.0:12345:80" ];
    };
    clash-web = {
      image = "docker.io/careywong/subweb:latest";
      ports = [ "0.0.0.0:12346:80" ];
    };
  };
}
