{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:

with lib;
let
  cfg = config.modules.hardware;
in
{
  options = {
    modules.hardware = {
      enable = mkEnableOption "hardware config";
    };
  };

  config = mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = true;
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };
    hardware.firmware = with pkgs; [
      firmwareLinuxNonfree
      sof-firmware
      alsa-firmware
    ];
    hardware.enableRedistributableFirmware = lib.mkDefault true;
    # AMDVLK
    hardware.amdgpu.initrd.enable = true;
    hardware.amdgpu.opencl.enable = true;
    hardware.amdgpu.amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };

    hardware.bluetooth.enable = true;
    # SSD trim
    services.fstrim = {
      enable = true;
      interval = "Sun";
    };

    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack.enable = true;
    };
    # Yubikey
    hardware.gpgSmartcards.enable = true;
    services.pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };

    security.pam.u2f = {
      enable = true;
      settings = {
        authFile = secrets.u2f.authFile;
        cue = true;
      };
      control = "sufficient";
    };
    security.pam.services.login.u2fAuth = true;
    security.pam.services.gdm.u2fAuth = true;

    services.udev.packages = [
      pkgs.yubikey-personalization
      pkgs.libu2f-host
    ];
  };
}
