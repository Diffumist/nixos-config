{ pkgs, ... }:
let
  ipv4 = "172.22.64.68";
  ipv6 = "fd22:1056:95a4:4::1";
  primaryIpv4 = "172.22.64.66";
  primaryIpv6 = "fd22:1056:95a4:2::1";
  domain = "diffumist.dn42";
  telephonyDomain = "2.4.6.0.4.2.4.0.tel.dn42";
  ipv4ReverseDomain = "64/27.64.22.172.in-addr.arpa";
  ipv6ReverseDomain = "4.a.5.9.6.5.0.1.2.2.d.f.ip6.arpa";
in
{
  services.knot = {
    enable = true;
    settingsFile = pkgs.writeText "knot.conf" ''
      server:
        listen: ${ipv4}@53
        listen: ${ipv6}@53

      remote:
        - id: ns1
          address: ${primaryIpv4}@53
          address: ${primaryIpv6}@53

      acl:
        - id: primary_notify
          address: ${primaryIpv4}
          address: ${primaryIpv6}
          action: notify

      zone:
        - domain: ${domain}
          file: "/var/lib/knot/${domain}.zone"
          master: ns1
          acl: primary_notify
        - domain: ${telephonyDomain}
          file: "/var/lib/knot/${telephonyDomain}.zone"
          master: ns1
          acl: primary_notify
        - domain: ${ipv4ReverseDomain}
          file: "/var/lib/knot/ipv4-reverse.zone"
          master: ns1
          acl: primary_notify
        - domain: ${ipv6ReverseDomain}
          file: "/var/lib/knot/ipv6-reverse.zone"
          master: ns1
          acl: primary_notify
    '';
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
