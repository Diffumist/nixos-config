{ modulesPath, inputs, lib, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];

  disko.devices = import ./disk-config.nix {
    lib = inputs.nixpkgs.lib;
  };

  networking = {
    hostName = "kexec";
    firewall.enable = false;
    nameservers = [ "8.8.8.8" ];
    useDHCP = lib.mkDefault true;
  };
  boot.loader.grub = {
    devices = [ "/dev/vda" ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];

  powerManagement.cpuFreqGovernor = "ondemand";


  system.stateVersion = "21.11";
}
