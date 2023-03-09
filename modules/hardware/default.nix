{ lib, config, pkgs, secrets, ... }:

with lib;
let
  cfg = config.modules.hardware;
in
{
  options = {
    modules.hardware = {
      enable = mkEnableOption "base hardware for laptop";
      nvidiaEnable = mkEnableOption "hardware for nvidia";
      yubikeyEnable = mkEnableOption "hardware for Yubikey";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
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
      # SSD trim
      services.fstrim = {
        enable = true;
        interval = "Sun";
      };

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

    (mkIf cfg.nvidiaEnable {
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
        nvidiaPersistenced = true;
      };
      services.xserver.videoDrivers = [ "nvidia" ];
    })
    (mkIf cfg.yubikeyEnable {
      # Yubikey
      hardware.gpgSmartcards.enable = true;
      services.pcscd = {
        enable = true;
        plugins = [ pkgs.ccid ];
      };

      security.pam.u2f = {
        enable = true;
        authFile = secrets.u2f.authFile;
        control = "sufficient";
        cue = true;
      };
      security.pam.services.login.u2fAuth = true;
      security.pam.services.gdm.u2fAuth = true;

      services.udev.packages = [ pkgs.yubikey-personalization pkgs.libu2f-host ];
    })
  ]);
}
