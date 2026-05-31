_: {
  my.services.postgresql.enable = true;
  services.postgresql = {
    authentication = ''
      local tgtldr tgtldr trust
    '';
    ensureDatabases = [ "tgtldr" ];
    ensureUsers = [
      {
        name = "tgtldr";
        ensureDBOwnership = true;
      }
    ];
  };
  virtualisation.oci-containers.containers = {
    tgtldr-app = {
      image = "fr0der1c/tgtldr-app:latest";
      environment = {
        TGTLDR_DATABASE_URL = "postgresql://tgtldr@/tgtldr?host=/run/postgresql";
        TGTLDR_MASTER_KEY_FILE = "/var/lib/tgtldr/master.key";
        TGTLDR_WEB_ORIGIN = "https://tg.503418.xyz";
        TGTLDR_HTTP_ADDR = ":8080";
      };
      volumes = [
        "/run/postgresql:/run/postgresql"
        "tgtldr-app-data:/var/lib/tgtldr"
      ];
    };
    tgtldr-web = {
      image = "fr0der1c/tgtldr-web:latest";
      dependsOn = [ "tgtldr-app" ];
      environment = {
        TGTLDR_INTERNAL_API_BASE_URL = "http://tgtldr-app:8080";
      };
      ports = [
        "127.0.0.1:13000:3000"
      ];
    };
  };
  services.caddy.virtualHosts."tg.503418.xyz".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:13000
  '';
}
