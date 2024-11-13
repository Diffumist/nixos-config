{ ... }:
{
  time.timeZone = "Asia/Shanghai";
  services.timesyncd.enable = false;
  services.ntpd-rs.enable = true;

  services.earlyoom.enable = true;

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  # FHS fix for nixos
  services.envfs.enable = true;
  programs.nix-ld.enable = true;

  # impermanence
  systemd.suppressedSystemUnits = [
    "systemd-machine-id-commit.service"
  ];
}
