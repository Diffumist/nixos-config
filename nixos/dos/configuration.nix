{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
  ];

  networking = {
    hostName = "dos";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
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

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    passwordAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGF706zFsxehLg28ah0NKHNyJtiw2IAM1ch5xDDUDaDt"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC530VLkFEFeQbmy22mSkcO5zRAZE9KTXwEciQU97y+FDawcqilS4RJ+LR4kCsxLgt8K/SGCBXc5h3eSuPxsCUvV9X5VP+R3xuK/c/KffYLivSGauVGRKJ4hQR99JrMAZyT2HXDlP84XAwXKj76jz8XkOolDq/cUp57ZmF1YJ7PJnAjOqQsdmOlGacgXww1s2XP98AN/9LXCiaJsiCOYfBKMdDdkQICpNTbx6tCsFxgNWKJcKkASl1fqywwR2D6DFE1nwGnORYr9L+B+F35pgjS8EZFMCvRMJBqlr8FvGcSlaiJfO2QSNRuB+WCieJIMeOWwimcHO1CgmkqNUY/nSOKu+wE0+TnEp88XvxalfM3LiI0hExYaUiqtooTIOHHXoTM1jt198WgAcZHjIfZL3jFlIuSlxcPT2YZQBa+2rkDpMba2Hl8N2dsygR2Uo0fI9AL1wZsyOHtl34mST1pP1BISEXkPhKdjYCS2SZfohw5rebfL+pur1ceMsKflIlT/lc="
  ];

  system.stateVersion = "20.09";
}
