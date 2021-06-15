{ lib, config, pkgs, modulesPath, ... }:
{
  hardware.cpu.intel.updateMicrocode = true;
  hardware.nvidia = {
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true;

  sound.enable = true;
  services.pipewire = {
      enable = true;
      pulse.enable = true;
  };
}
