{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./console.nix
    ../../config/nix-config.nix
  ];

  networking = {
    hostName = "dos";
    domain = "diffumist.me";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 53232 ];
      allowedUDPPorts = [ 52540 ];
    };
    nameservers = [ "8.8.8.8" ];
    defaultGateway = "165.232.128.1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "165.232.133.247"; prefixLength = 20; }
          { address = "10.48.0.5"; prefixLength = 16; }
        ];
        ipv4.routes = [{ address = "165.232.128.1"; prefixLength = 32; }];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="56:06:06:d1:f5:1e", NAME="eth0"
    ATTR{address}=="8e:f6:b4:3d:8b:d9", NAME="eth1"
  '';

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    passwordAuthentication = false;
    extraConfig = ''
      ClientAliveInterval 70
      ClientAliveCountMax 3
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDibG8MqrPcT/FyeLDGyXG03lU4nOrzAbPTDWdCwUTGOjhLy2fDevJ8D+uWfQp11Y/MOpsOpfJMohMM+VcunFhgi5sHSmPfmjat5lKXCXRwMwHjEQhTnx1KIFpjikIPs5NpOjhXc5/7IrSdFG9crpog24ThThjuYNKFyHAbSysuniL1n6YAnW9AZpJVixD8Cvm3TenfnsRaFCfEQ2Sde7bXqlWqE3wbi0hNcaXSGdh5MDB6IJp5jwu1D4qR2TfCrMR5GOrlaXP+5E8QpZfaMj1E+Mz8ohRH9YcYMAVvGXooV9FALbgxYfo7hqrNbUO7pY3uV0ap0yUeQnSs6QRXHwV+UefeyrixZP6PFi7yNu4SKJ/OolCstxT3Q24C7JgNtq8EJ+0qJ3pwD/sjxq1usEl74mhjUBpr/c8RIhEqCInRmPhvNvKy5d4pdcHX3YQkQW8qgNfhMH8qY8u41UMdHYC1yLajW1/jtcVlus1nnkAU94Rf9JPg/V/Zynpt4K+ZPLM= root@Host.diffumist.me"
  ];

  system.stateVersion = "20.09";
}
