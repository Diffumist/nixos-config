{ lib, config, ... }:
with lib;
let
  cfg = config.modules.nas-sync;
  user = cfg.username;
  dir = cfg.folder;
in
{
  options.modules.nas-sync = {
    enable = mkEnableOption "nas-sync";
    username = mkOption {
      type = types.str;
      default = "diffumist";
    };
    folder = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
  config = mkIf cfg.enable {
    services.samba =
      let
        smb = options: {
          path = "/home/${user}/${options}";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
        };

      in
      {
        enable = true;
        openFirewall = true;
        nsswins = true;
        extraConfig = ''
          guest account = nobody
          map to guest = bad user
        '';
        shares = lib.genAttrs dir smb;
      };
    services.samba-wsdd.enable = true;

    services.syncthing =
      let
        sync = options: {
          path = "/home/${user}/${options}";
          devices = [ "nixlab" "onix" ];
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "180";
          };
        };
      in
      {
        enable = true;
        openDefaultPorts = true;
        user = "${user}";
        devices = {
          "nixlab" = {
            id = "YWDZUCK-STLKVTN-XMJTVTH-GF4XN7E-V4ZORWA-5P3LBOD-3W5Z6HD-U2SSJQ5";
          };
          "onix" = {
            id = "SYLPCVN-O2F4TZ6-RJCHN3E-XB7UGWA-Z4RQ5CM-KD3LIXP-EGXKKK6-T6GNUQS";
          };
        };
        dataDir = "/home/${user}/.local/share/syncthing";
        configDir = "/home/${user}/.config/syncthing";
        guiAddress = "0.0.0.0:8384";
        folders = lib.genAttrs dir sync;
      };
    networking.firewall.allowedTCPPorts = [ 8384 ];
  };
}
