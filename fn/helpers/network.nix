{ lib }:
let
  formatHostPort =
    host: port:
    let
      hostString = toString host;
      portString = toString port;
      isBracketed = lib.hasPrefix "[" hostString && lib.hasSuffix "]" hostString;
    in
    if isBracketed || !(lib.hasInfix ":" hostString) then
      "${hostString}:${portString}"
    else
      "[${hostString}]:${portString}";

  renderStaticNetwork =
    {
      placeholder,
      settings,
    }:
    let
      ipv4AddressSecrets = [ settings.ipv4.addressSecret ];
      ipv6AddressSecrets = lib.optionals settings.ipv6.enable (
        [ settings.ipv6.addressSecret ] ++ settings.ipv6.extraAddressSecrets
      );
      addressLines =
        map (
          secret: "Address=${placeholder secret}/${toString settings.ipv4.prefixLength}"
        ) ipv4AddressSecrets
        ++ map (
          secret: "Address=${placeholder secret}/${toString settings.ipv6.prefixLength}"
        ) ipv6AddressSecrets;
      gatewayLines =
        lib.optionals (!settings.ipv4.gatewayOnLink) [
          "Gateway=${placeholder settings.ipv4.gatewaySecret}"
        ]
        ++ lib.optional (
          settings.ipv6.enable && !settings.ipv6.gatewayOnLink
        ) "Gateway=${placeholder settings.ipv6.gatewaySecret}";
      networkLines = [
        "[Match]"
        "MACAddress=${settings.macAddress}"
        ""
        "[Network]"
      ]
      ++ addressLines
      ++
        lib.optional (settings.ipv6.acceptRA != null)
          "IPv6AcceptRA=${if settings.ipv6.acceptRA then "yes" else "no"}"
      ++ gatewayLines
      ++ map (server: "DNS=${server}") settings.dns
      ++ lib.optionals settings.ipv4.gatewayOnLink [
        ""
        "[Route]"
        "Destination=0.0.0.0/0"
        "Gateway=${placeholder settings.ipv4.gatewaySecret}"
        "GatewayOnLink=yes"
      ]
      ++ lib.optionals settings.ipv6.gatewayOnLink [
        ""
        "[Route]"
        "Destination=::/0"
        "Gateway=${placeholder settings.ipv6.gatewaySecret}"
        "GatewayOnLink=yes"
      ];
      secretNames =
        ipv4AddressSecrets
        ++ [ settings.ipv4.gatewaySecret ]
        ++ ipv6AddressSecrets
        ++ lib.optional settings.ipv6.enable settings.ipv6.gatewaySecret;
    in
    {
      inherit secretNames;
      text = lib.concatStringsSep "\n" networkLines + "\n";
    };
in
{
  inherit formatHostPort renderStaticNetwork;
}
