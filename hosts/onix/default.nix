{ lib, pkgs, secrets, inputs, self, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.home.nixosModules.home-manager
    inputs.nur.nixosModules.nur
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.default
  ];

  sops = {
    defaultSopsFile = ../../secrets/onix.yaml;
    secrets = { };
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  # network
  networking = {
    hostName = "onix";
    domain = "diffumist.me";
    networkmanager.dns = "none";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.1" ];
    firewall.enable = lib.mkForce false;
    # proxy.default = "socks5://127.0.0.1:7890"; for debug
  };
  time.timeZone = "Asia/Shanghai";

  # modules options
  modules = {
    gnome-env = {
      enable = true;
      waylandEnable = false;
    };
    hardware = {
      enable = true;
      nvidiaEnable = true;
      yubikeyEnable = true;
    };
  };

  users = {
    users."diffumist" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.fish;
      hashedPassword = "$6$6J91Plm9yvX7KiMs$DOUaBLnKLqpxJXlIAdIWA6KNs8boT58CuavOoMka2DFAZbLe9hRu5ubMBfYfiukHld3LC/rx/CA4B2eBetB.60";
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit secrets; };
    users.diffumist = import ../../home;
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
  };

  system.stateVersion = "21.11";
}
