# Autopeer frontend: other networks log in with their registry credentials,
# get a peer on a node of ours and open a pull request against this repo.
# The agents on the nodes are modules/services/dn42/autopeer.nix.
{
  config,
  inputs,
  lib,
  ...
}:
let
  domain = "autopeer.diffumist.me";
  port = 4800;
  registry = inputs.dn42-registry;
  ranet = config.my.services.ranet.nodes;
  forgejo = config.services.forgejo.settings.server;
in
{
  sops.secrets = {
    autopeer_cookie_secret = { };
    autopeer_forgejo_token = { };
    autopeer_hook_token = { };
    autopeer_agent_token.sopsFile = ../../../profiles/common/secrets/server.yaml;
  };

  services.autopeer.web = {
    enable = true;
    settings = {
      listen = "127.0.0.1:${toString port}";
      asn = 4242420642;
      link_local = "fe80::642";
      # Kioubit login signs its answer for this name.
      inherit domain;
      registry = "${registry}";
      registry_rev = registry.rev;
      registry_time = registry.lastModified;
      flapalerted = "https://flap-dn42.diffumist.me";
      forgejo = {
        url = "http://${forgejo.HTTP_ADDR}:${toString forgejo.HTTP_PORT}";
        repo = "DiftLab/nixos-config";
        dir = "profiles/common/services/peers";
      };
      nodes = lib.mapAttrsToList (name: node: {
        inherit name;
        inherit (node) location endpoint capacity;
        public_key = node.publicKey;
        agent = "http://[${ranet.${node.hostName}.ipv6}]:4801";
      }) (import ../../../profiles/common/services/dn42-nodes.nix);
    };
    secretFile = config.sops.secrets.autopeer_cookie_secret.path;
    agentTokenFile = config.sops.secrets.autopeer_agent_token.path;
    forgejoTokenFile = config.sops.secrets.autopeer_forgejo_token.path;
    hookTokenFile = config.sops.secrets.autopeer_hook_token.path;
  };

  my.systemd.harden = [ "autopeer-web" ];

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy 127.0.0.1:${toString port}
  '';

  my.networking.usedTCPPorts.autopeer = port;
}
