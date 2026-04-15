{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/696dee39-8e2d-4f23-97e6-f6d2f20ece5e";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];

}
