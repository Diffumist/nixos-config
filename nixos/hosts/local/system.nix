{ pkgs, ... }:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  environment.systemPackages = [ nvidia-offload ];
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
  hardware.firmware = with pkgs; [
    firmwareLinuxNonfree
    sof-firmware
    alsa-firmware
  ];
  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true;

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };
  nixpkgs.config.pulseaudio = true;
  # pipewire will not find the device after suspend
  # FIXME: https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/895
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  #   alsa = {
  #     enable = true;
  #     support32Bit = true;
  #   };
  #   jack.enable = true;
  # };
}
