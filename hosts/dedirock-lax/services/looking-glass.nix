{ config, lib, ... }:
let
  domain = "lg-dn42.diffumist.me";
  frontendPort = 5000;
  mesh = config.my.services.dn42.mesh;
  nodes = map (
    node:
    let
      shortName = builtins.head (lib.splitString "." node.endpoint);
    in
    {
      inherit shortName;
      inherit (node) ipv4;
    }
  ) (lib.sort (a: b: a.ipv4 < b.ipv4) (builtins.attrValues mesh.nodes));
in
{
  services.bird-lg.frontend = {
    enable = true;
    listenAddresses = "127.0.0.1:${toString frontendPort}";
    proxyPort = mesh.lookingGlassProxyPort;
    servers = map (node: "${lib.toUpper node.shortName}<${node.shortName}.lg>") nodes;
    domain = "";
    netSpecificMode = "dn42";
    protocolFilter = [ "BGP" ];
    titleBrand = "Diffumist's DN42 Looking Glass";
    navbar.brand = "Diffumist's DN42 LG";
  };

  networking.hosts = lib.listToAttrs (
    map (node: lib.nameValuePair node.ipv4 [ "${node.shortName}.lg" ]) nodes
  );

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = { };
  };
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString frontendPort}
    '';
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };

  my.networking.usedTCPPorts.bird-lg-frontend = frontendPort;
}
