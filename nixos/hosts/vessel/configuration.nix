{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ../../config/nix-config.nix
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
  };

  networking = {
    hostName = "vessel";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
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
