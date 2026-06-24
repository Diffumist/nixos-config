{ config, pkgs, ... }:
let
  ipv4 = "172.22.64.66";
  ipv6 = "fd22:1056:95a4:2::1";
  secondaryIpv4 = "172.22.64.68";
  secondaryIpv6 = "fd22:1056:95a4:4::1";
  domain = "diffumist.dn42";
  telephonyDomain = "2.4.6.0.4.2.4.0.tel.dn42";
  ipv4ReverseDomain = "64/27.64.22.172.in-addr.arpa";
  ipv6ReverseDomain = "4.a.5.9.6.5.0.1.2.2.d.f.ip6.arpa";
  dbName = "pdns";
  apiPort = 8081;
  tsigKeyAlgorithm = "hmac-sha256";
  postgresqlUnits = [
    "postgresql.service"
    "postgresql-setup.service"
  ];
  psql = "${config.services.postgresql.package}/bin/psql";
  schemaFile = "${pkgs.pdns}/share/doc/pdns/schema.pgsql.sql";
  powerdnsBaseConfig = ''
    launch=gpgsql
    gpgsql-host=/run/postgresql
    gpgsql-user=${dbName}
    gpgsql-dbname=${dbName}
    local-address=${ipv4},${ipv6}
    primary=yes
    also-notify=${secondaryIpv4},${secondaryIpv6}
  '';
  powerdnsConfig = ''
    ${powerdnsBaseConfig}
    api=yes
    api-key=$PDNS_API_KEY
    webserver=yes
    webserver-address=127.0.0.1
    webserver-port=${toString apiPort}
    webserver-allow-from=127.0.0.1,::1
  '';
  pdnsConfigDir = pkgs.writeTextDir "pdns.conf" powerdnsBaseConfig;
  pdnsutil = "${pkgs.pdns}/bin/pdnsutil --config-dir=${pdnsConfigDir}";
  zoneFile = pkgs.writeText "${domain}.zone" ''
    $TTL 300
    @ IN SOA ns1.${domain}. hostmaster.${domain}. (
      2026062201 ; serial
      300        ; refresh
      120        ; retry
      1209600    ; expire
      300        ; minimum
    )

    @   IN NS   ns1.${domain}.
    @   IN NS   ns2.${domain}.
    ns1 IN A    ${ipv4}
    ns1 IN AAAA ${ipv6}
    ns2 IN A    ${secondaryIpv4}
    ns2 IN AAAA ${secondaryIpv6}

    @          IN A    ${ipv4}
    @          IN AAAA ${ipv6}
    ams-0 IN A    172.22.64.65
    ams-0 IN AAAA fd22:1056:95a4:1::1
    sjc-0 IN A    ${ipv4}
    sjc-0 IN AAAA ${ipv6}
    lax-0 IN A    172.22.64.67
    lax-0 IN AAAA fd22:1056:95a4:3::1
    tyo-0 IN A    ${secondaryIpv4}
    tyo-0 IN AAAA ${secondaryIpv6}
    hkg-0 IN A    172.22.64.69
    hkg-0 IN AAAA fd22:1056:95a4:5::1
  '';
  telephonyZoneFile = pkgs.writeText "${telephonyDomain}.zone" ''
    $TTL 300
    @ IN SOA ns1.${domain}. hostmaster.${domain}. (
      2026062201 ; serial
      300        ; refresh
      120        ; retry
      1209600    ; expire
      300        ; minimum
    )

    @ IN NS ns1.${domain}.
    @ IN NS ns2.${domain}.
  '';
  ipv4ReverseZoneFile = pkgs.writeText "ipv4-reverse.zone" ''
    $TTL 300
    @ IN SOA ns1.${domain}. hostmaster.${domain}. (
      2026062201 ; serial
      300        ; refresh
      120        ; retry
      1209600    ; expire
      300        ; minimum
    )

    @  IN NS  ns1.${domain}.
    @  IN NS  ns2.${domain}.
    65 IN PTR ams-0.${domain}.
    66 IN PTR sjc-0.${domain}.
    67 IN PTR lax-0.${domain}.
    68 IN PTR tyo-0.${domain}.
    69 IN PTR hkg-0.${domain}.
  '';
  ipv6ReverseZoneFile = pkgs.writeText "ipv6-reverse.zone" ''
    $TTL 300
    @ IN SOA ns1.${domain}. hostmaster.${domain}. (
      2026062201 ; serial
      300        ; refresh
      120        ; retry
      1209600    ; expire
      300        ; minimum
    )

    @ IN NS  ns1.${domain}.
    @ IN NS  ns2.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.0.0.0 IN PTR ams-0.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0 IN PTR sjc-0.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.3.0.0.0 IN PTR lax-0.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.4.0.0.0 IN PTR tyo-0.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.5.0.0.0 IN PTR hkg-0.${domain}.
  '';
  mkZoneBootstrap = zone: file: ''
    if ! ${psql} -d ${dbName} -Atqc "select 1 from domains where name = '${zone}' limit 1" | grep -qx 1; then
      ${pdnsutil} zone create '${zone}' 'ns1.${domain}'
      ${pdnsutil} load-zone '${zone}' '${file}'
    fi
  '';
  activateZoneTsig = zone: ''
    ${pdnsutil} tsigkey activate '${zone}' "$PDNS_TSIG_KEY_NAME" primary
  '';
in
{
  sops.secrets.powerdns_env = {
    sopsFile = ../secrets.yaml;
    owner = "pdns";
    group = "pdns";
    mode = "0440";
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [ "pdns" ];
    ensureUsers = [
      {
        name = "pdns";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.pdns-init-db = {
    description = "Bootstrap PowerDNS PostgreSQL schema and initial zones";
    wants = postgresqlUnits;
    after = postgresqlUnits;
    before = [ "pdns.service" ];
    requiredBy = [ "pdns.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "pdns";
      Group = "pdns";
    };
    script = ''
      set -euo pipefail
      set -a
      . ${config.sops.secrets.powerdns_env.path}
      set +a

      : "''${PDNS_TSIG_KEY_NAME:?missing PDNS_TSIG_KEY_NAME}"
      : "''${PDNS_TSIG_KEY_SECRET:?missing PDNS_TSIG_KEY_SECRET}"

      if ! ${psql} -d ${dbName} -Atqc "select 1 from pg_tables where schemaname = 'public' and tablename = 'domains'" | grep -qx 1; then
        ${psql} -d ${dbName} -f ${schemaFile}
      fi

      # Keep bootstrap one-shot so DNSControl-managed data is not overwritten on every switch.
      ${mkZoneBootstrap domain zoneFile}
      ${mkZoneBootstrap telephonyDomain telephonyZoneFile}
      ${mkZoneBootstrap ipv4ReverseDomain ipv4ReverseZoneFile}
      ${mkZoneBootstrap ipv6ReverseDomain ipv6ReverseZoneFile}

      # Keep TSIG bootstrap idempotent so key rotation follows Nix state.
      ${pdnsutil} tsigkey import "$PDNS_TSIG_KEY_NAME" ${tsigKeyAlgorithm} "$PDNS_TSIG_KEY_SECRET"
      ${activateZoneTsig domain}
      ${activateZoneTsig telephonyDomain}
      ${activateZoneTsig ipv4ReverseDomain}
      ${activateZoneTsig ipv6ReverseDomain}
    '';
  };

  systemd.services.pdns = {
    requires = postgresqlUnits ++ [ "pdns-init-db.service" ];
    after = postgresqlUnits ++ [ "pdns-init-db.service" ];
  };

  services.powerdns = {
    enable = true;
    secretFile = config.sops.secrets.powerdns_env.path;
    extraConfig = powerdnsConfig;
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."zones.diffumist.me" = {
    useACMEHost = "zones.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString apiPort}
    '';
  };

  security.acme.certs."zones.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
