# Two-node VM check for profiles/common/services/ranet.nix:
#   nix-build tests/ranet.nix
let
  flake = builtins.getFlake (toString ./..);
  pkgs = flake.legacyPackages.x86_64-linux;

  # Import-from-derivation: throwaway keys are generated at build time so no
  # private key is committed.
  keys = pkgs.runCommand "ranet-test-keys" { nativeBuildInputs = [ pkgs.openssl ]; } ''
    mkdir $out
    for n in a b; do
      openssl genpkey -algorithm ed25519 -out $out/$n.key
      openssl pkey -in $out/$n.key -pubout -outform DER | base64 -w0 > $out/$n.pub
    done
  '';

  mkNode = name: {
    imports = [
      ../modules/system/used-ports.nix
      # Run under the server kernel baseline: it blocks modules, and once blocked ESP.
      ../profiles/common/kernel.nix
      ../profiles/common/services/ranet.nix
      flake.inputs.sops-nix.nixosModules.sops
    ];
    _module.args.hostName = name;

    networking.nftables.enable = true;
    networking.useNetworkd = true;

    my.services.ranet = {
      privateKeyFile = "${keys}/${name}.key";
      nodes = {
        a = {
          endpoint = "a";
          ipv4 = "10.203.0.1";
          ipv6 = "fd42:203::1";
          publicKey = builtins.readFile "${keys}/a.pub";
        };
        b = {
          endpoint = "b";
          ipv4 = "10.203.0.2";
          ipv6 = "fd42:203::2";
          publicKey = builtins.readFile "${keys}/b.pub";
        };
        # Reserved address without a key must stay out of the registry.
        c = {
          endpoint = "c";
          ipv4 = "10.203.0.3";
          ipv6 = "fd42:203::3";
        };
      };
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "ranet";
  nodes = {
    a = mkNode "a";
    b = mkNode "b";
  };
  testScript = ''
    start_all()
    a.wait_for_unit("ranet.service")
    b.wait_for_unit("ranet.service")

    # The management addresses are only routed through the XFRM links.
    a.wait_until_succeeds("ping -c1 -W1 10.203.0.2", timeout=60)
    b.succeed("ping -c1 -W1 fd42:203::1")
    a.succeed("swanctl --list-sas | grep INSTALLED")
    # Plugins that act on the underlay LAN must stay unloaded.
    a.succeed("swanctl --stats | grep -w updown")
    a.fail("swanctl --stats | grep -wE 'farp|dhcp|forecast|stroke'")
    a.succeed("nft list table inet ranet | grep 'ranet-\\*'")
    a.fail("ip route get 10.203.0.3 | grep ranet-")

    # A daemon restart replaces the SA; the kept link must carry the new one.
    b.systemctl("restart strongswan-swanctl.service")
    b.wait_for_unit("ranet.service")
    a.wait_until_succeeds("ping -c1 -W1 10.203.0.2", timeout=90)
    b.succeed("ping -c1 -W1 fd42:203::1")
    assert a.succeed("ip -o link show type xfrm | wc -l").strip() == "1"
  '';
}
