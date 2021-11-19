{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.dmist.hardware;
in
{
  options = {
    dmist.hardware = {
      enable = mkEnableOption "base hardware for laptop";
      nvidiaEnable = mkEnableOption "hardware for nvidia";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      hardware.cpu.intel.updateMicrocode = true;
      hardware.opengl = {
        enable = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [ intel-media-driver ];
      };
      hardware.firmware = with pkgs; [
        firmwareLinuxNonfree
        sof-firmware
        alsa-firmware
      ];
      hardware.enableRedistributableFirmware = lib.mkDefault true;

      hardware.bluetooth.enable = true;
      hardware.logitech.wireless.enable = true;

      sound.enable = true;
      hardware.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        jack.enable = true;
      };
    })

    (mkIf (cfg.nvidiaEnable) {
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
        modesetting.enable = true;
        nvidiaSettings = false;
      };
      services.xserver.videoDrivers = [ "nvidia" ];
    })
  ];
}
