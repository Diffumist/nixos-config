{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.garage;
  rpcPort = 3901;
  s3Port = 3900;
in
{
  options.my.services.garage = {
    enable = lib.mkEnableOption "the Garage storage node";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "s3.418.cat";
      description = "Public S3 API domain";
    };

    exposeS3 = lib.mkEnableOption "the public S3 API through Caddy";

    bootstrapPeers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "0123456789abcdef@storage-1.example.com:3901" ];
      description = "Garage peers contacted during node startup";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.garage_rpc_secret = {
      sopsFile = ../../profiles/common/secrets/garage.yaml;
      restartUnits = [ "garage.service" ];
    };
    sops.templates."garage.env" = {
      mode = "0400";
      content = ''
        GARAGE_RPC_SECRET=${config.sops.placeholder.garage_rpc_secret}
      '';
    };

    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = config.sops.templates."garage.env".path;
      settings = {
        metadata_dir = "/var/lib/garage/meta";
        data_dir = "/var/lib/garage/data";
        db_engine = "lmdb";
        metadata_auto_snapshot_interval = "6h";
        replication_factor = 2;
        consistency_mode = "consistent";
        compression_level = 1;

        rpc_bind_addr = "[::]:${toString rpcPort}";
        rpc_public_addr_subnet = "2000::/3";
        bootstrap_peers = cfg.bootstrapPeers;

        s3_api = {
          api_bind_addr = "127.0.0.1:${toString s3Port}";
          s3_region = "garage";
        };

        admin.api_bind_addr = "127.0.0.1:3903";
      };
    };

    environment.systemPackages = [ config.services.garage.package ];

    my.services.caddy = lib.mkIf cfg.exposeS3 {
      enable = true;
      virtualHosts.${cfg.domain}.useCloudflareACME = true;
    };
    services.caddy.virtualHosts = lib.mkIf cfg.exposeS3 {
      ${cfg.domain}.extraConfig = ''
        reverse_proxy 127.0.0.1:${toString s3Port}
      '';
    };

    # Garage authenticates Internet-facing RPC with the shared 256-bit secret.
    networking.firewall.allowedTCPPorts = [ rpcPort ];
  };
}
