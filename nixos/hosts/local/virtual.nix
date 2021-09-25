{ pkgs, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuPackage = pkgs.qemu_kvm;
    };
    kvmgt = {
      enable = true;
      # Random generated UUIDs.
      # vgpus."i915-GVTg_V5_4".uuid = "7a0eb5a3-9927-4613-a01e-24886e15c4a4"; # 1920x1200
      # vgpus."i915-GVTg_V5_8".uuid = [ "83d2cd0c-89aa-4045-8e8e-5796ac8d6d4f" ]; # 1024x768
    };
    podman.enable = true;
  };

  users.groups."libvirtd".members = [ "diffumist" ];

  # Local samba for VM
  services.samba = {
    enable = true;
    extraConfig = ''
      bind interfaces only = yes
      interfaces = lo virbr0
      guest account = nobody
    '';
    shares."vm_share" = {
      path = "/home/diffumist/.local/share/vm/share";
      writable = "yes";
    };
  };
}
