{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
  ];

  networking = {
    hostName = "mist";
    domain = "diffumist.me";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
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
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    passwordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd/6aBTs/HVmH0g1xHZ+ECETUjEOEHVI7PJuxELqYCg noname"
  ];

  system.stateVersion = "20.09";
}
