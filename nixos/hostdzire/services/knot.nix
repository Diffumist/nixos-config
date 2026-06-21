{ pkgs, ... }:
let
  ipv4 = "172.22.64.66";
  ipv6 = "fd22:1056:95a4:2::1";
  secondaryIpv4 = "172.22.64.68";
  secondaryIpv6 = "fd22:1056:95a4:4::1";
  domain = "diffumist.dn42";
  telephonyDomain = "2.4.6.0.4.2.4.0.tel.dn42";
  ipv4ReverseDomain = "64/27.64.22.172.in-addr.arpa";
  ipv6ReverseDomain = "4.a.5.9.6.5.0.1.2.2.d.f.ip6.arpa";
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
    liteserver IN A    172.22.64.65
    liteserver IN AAAA fd22:1056:95a4:1::1
    hostdzire  IN A    ${ipv4}
    hostdzire  IN AAAA ${ipv6}
    dedirock   IN A    172.22.64.67
    dedirock   IN AAAA fd22:1056:95a4:3::1
    geelinx-jp IN A    ${secondaryIpv4}
    geelinx-jp IN AAAA ${secondaryIpv6}
    wawo       IN A    172.22.64.69
    wawo       IN AAAA fd22:1056:95a4:5::1
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
    65 IN PTR liteserver.${domain}.
    66 IN PTR hostdzire.${domain}.
    67 IN PTR dedirock.${domain}.
    68 IN PTR geelinx-jp.${domain}.
    69 IN PTR wawo.${domain}.
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
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.0.0.0 IN PTR liteserver.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0 IN PTR hostdzire.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.3.0.0.0 IN PTR dedirock.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.4.0.0.0 IN PTR geelinx-jp.${domain}.
    1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.5.0.0.0 IN PTR wawo.${domain}.
  '';
in
{
  services.knot = {
    enable = true;
    settingsFile = pkgs.writeText "knot.conf" ''
      server:
        listen: ${ipv4}@53
        listen: ${ipv6}@53

      remote:
        - id: ns2
          address: ${secondaryIpv4}@53
          address: ${secondaryIpv6}@53

      acl:
        - id: secondary_transfer
          address: ${secondaryIpv4}
          address: ${secondaryIpv6}
          action: transfer

      zone:
        - domain: ${domain}
          file: "${zoneFile}"
          acl: secondary_transfer
          notify: ns2
        - domain: ${telephonyDomain}
          file: "${telephonyZoneFile}"
          acl: secondary_transfer
          notify: ns2
        - domain: ${ipv4ReverseDomain}
          file: "${ipv4ReverseZoneFile}"
          acl: secondary_transfer
          notify: ns2
        - domain: ${ipv6ReverseDomain}
          file: "${ipv6ReverseZoneFile}"
          acl: secondary_transfer
          notify: ns2
    '';
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
