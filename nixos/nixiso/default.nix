{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
    ./boot.nix
  ];

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    volumeID = "NIXOS_ISO";
  };

  networking = {
    hostName = "nixos-installer";
    nftables.enable = true;
    firewall.enable = false;
    networkmanager.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.PasswordAuthentication = false;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
    ];
  };

  environment.systemPackages = with pkgs; [
    fd
    bat
    eza
    duf
    age
    sops
    ncdu
    btop
    disko
    helix
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # nix-config
  nixpkgs.config.allowUnfree = true;

  nix = {
    channel.enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      auto-allocate-uids = true;
      warn-dirty = false;
      auto-optimise-store = true;
    };
  };

  documentation.doc.enable = false;

  system.stateVersion = "25.11";
}
