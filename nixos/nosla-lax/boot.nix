{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e6fc1503-b395-4ce8-b377-541ae6793c52";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];

}
