{ pkgs, lib, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    enableTCPIP = true;

    ensureDatabases = [ "tgtldr" ];
    ensureUsers = [
      {
        name = "tgtldr";
        ensureDBOwnership = true;
      }
    ];

    authentication = ''
      host tgtldr tgtldr 10.88.0.0/16 scram-sha-256
      host tgtldr tgtldr 127.0.0.1/32 scram-sha-256
    '';
  };

  virtualisation.oci-containers.containers = {
    tgtldr-app = {
      image = "fr0der1c/tgtldr-app:latest";
      environmentFiles = [
        "/var/lib/tgtldr/app.env"
      ];
      volumes = [
        "tgtldr-app-data:/var/lib/tgtldr"
      ];
      extraOptions = [
        "--add-host=host.containers.internal:host-gateway"
      ];
    };
    # tee /var/lib/tgtldr/app.env >/dev/null <<'EOF'
    # TGTLDR_DATABASE_URL=postgres://tgtldr:CHANGE_ME@host.containers.internal:5432/tgtldr?sslmode=disable
    # TGTLDR_MASTER_KEY_FILE=/var/lib/tgtldr/master.key
    # TGTLDR_WEB_ORIGIN=https://tg.503418.xyz
    # TGTLDR_HTTP_ADDR=:8080
    # EOF
    tgtldr-web = {
      image = "fr0der1c/tgtldr-web:latest";
      dependsOn = [ "tgtldr-app" ];
      environment = {
        TGTLDR_INTERNAL_API_BASE_URL = "http://host.containers.internal:8080";
      };
      ports = [
        "127.0.0.1:13000:3000"
      ];
      extraOptions = [
        "--add-host=host.containers.internal:host-gateway"
      ];
    };
  };
}
