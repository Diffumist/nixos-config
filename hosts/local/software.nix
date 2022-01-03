{ pkgs, secrets, ... }: {
  # HiDPI display
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";

  environment.sessionVariables = {
    WINIT_X11_SCALE_FACTOR = "1.5"; # Ref: https://github.com/alacritty/alacritty/issues/3792
  };

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  # SSD trim
  services.fstrim = {
    enable = true;
    interval = "Sun";
  };

  # Canokey
  services.pcscd.enable = true;
  security.pam.u2f = {
    enable = true;
    authFile = secrets.u2f.authFile;
    control = "sufficient";
    cue = true;
  };

  services.udev = {
    packages = [ pkgs.libu2f-host ];
    extraRules = ''
      SUBSYSTEM!="usb", GOTO="canokeys_rules_end"
      ACTION!="add|change", GOTO="canokeys_rules_end"
      ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42d4", ENV{ID_SMARTCARD_READER}="1"
      LABEL="canokeys_rules_end"

      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42d4", TAG+="uaccess", GROUP="plugdev", MODE="0660"

      SUBSYSTEMS=="usb", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42d4", MODE="0666"
    '';
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        verbatimConfig = ''
          seccomp_sandbox = 0
        '';
      };
    };
    kvmgt = {
      enable = true;
      vgpus.i915-GVTg_V5_4.uuid = [ "9dfe21be-dd2f-411e-b21c-6eef9c8b3703" ];
    };
    # waydroid.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.backend = "podman";
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.wireshark = {
    enable = true;
  };
  users.groups."wireshark".members = [ "diffumist" ];

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
