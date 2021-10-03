{ lib, pkgs, inputs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/amazon-image.nix")
    ../../config/network
    ../../config/nix-config.nix
  ];

  ec2.hvm = true;

  networking = {
    hostName = "Dmistserver";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 9090 1234 ];
    };
    nameservers = [ "127.0.0.1" ];
  };
  users = {
    groups."diffumist".gid = 1000;
    users."diffumist" = {
      isNormalUser = true;
      uid = 1000;
      group = "diffumist";
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
      hashedPassword = "$6$fcWjQgqFr8/$G37fmSElAlhYftskmdgdnvT.tVFKgnGNSBFrrPkeFAap6l2szu58b8hupAYsCE0QUZRnJ.XCGOuoNgSEVUzee1";
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    extraConfig = ''
      ClientAliveInterval 70
      ClientAliveCountMax 3
    '';
  };

  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.swappiness" = 30;
  };

  system.stateVersion = "20.09";
}
