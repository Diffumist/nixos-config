# Peering with Diffumist (AS4242420642)

| | |
|---|---|
| ASN | `AS4242420642` (`AS-DIFFUMIST-DN42`) |
| Maintainer | `DIFFUMIST-MNT` |
| IPv4 | `172.22.64.64/27` |
| IPv6 | `fd22:1056:95a4::/48` |
| Domain | `diffumist.dn42` |
| Contact | dn42@diffumist.me |
| Looking Glass | https://lg-dn42.diffumist.me |
| Route Flaps | https://flap-dn42.diffumist.me |
| AutoPeer(experimental) | https://autopeer.diffumist.me |

## Node

Pick the node closest to yours. Endpoints are IPv4 and IPv6; put `v4.` or
`v6.` in front of a name to pin one of them (`v6.ams-0.diffumist.me`).

| Node | ID | Location | Region / Country | Endpoint | WireGuard public key | DN42 IPv4 | DN42 IPv6 |
|---|---|---|---|---|---|---|---|
| ams-0 | `1` | Amsterdam, NL | `41` / `1528` | `ams-0.diffumist.me` | `25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=` | `172.22.64.65` | `fd22:1056:95a4:1::1` |
| sjc-0 | `2` | San Jose, US | `44` / `1840` | `sjc-0.diffumist.me` | `byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=` | `172.22.64.66` | `fd22:1056:95a4:2::1` |
| lax-0 | `3` | Los Angeles, US | `44` / `1840` | `lax-0.diffumist.me` | `viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=` | `172.22.64.67` | `fd22:1056:95a4:3::1` |
| tyo-0 | `4` | Tokyo, JP | `52` / `1392` | `tyo-0.diffumist.me` | `KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=` | `172.22.64.68` | `fd22:1056:95a4:4::1` |
| hkg-0 | `5` | Hong Kong, HK | `52` / `1344` | `hkg-0.diffumist.me` | `3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=` | `172.22.64.69` | `fd22:1056:95a4:5::1` |
| nue-0 | `6` | Nuremberg, DE | `41` / `1276` | `nue-0.diffumist.me` | `Ti77y04KRfP/GRLPp87cw/8tcIB4Z6+phjOTQhoqHBQ=` | `172.22.64.70` | `fd22:1056:95a4:6::1` |

## Peering

One WireGuard tunnel per peer, MP-BGP over IPv6 link-local. No addresses are
assigned inside the tunnel besides the link-locals.

| | |
|---|---|
| Our port | `2xxxx`, the last four digits of your ASN (AS424242**1234** dials `21234`) |
| Your port | any; `20642` by convention. Leave it out if only you can dial out |
| Our link-local | `fe80::642` |
| Your link-local | any address in `fe80::/10` other than ours |
| MTU | `1420` |
| BGP | one session for both families, `extended next hop` for IPv4, extended messages |

To ask for a peering, send to the contact above: your ASN, the node, your
WireGuard public key, your endpoint and port, and your link-local address.

What a session gets:

- Import: routes are checked against ROA and dropped unless valid; our own
  prefixes are not accepted back.
- Flapping prefixes (FlapAlerted) are kept with local preference 0, tagged
  `(64511, 65282)` and not passed on.
- Export: our prefixes and every other DN42 route we hold, so we give transit.

## BGP Communities

### Well-Known & DN42 Standard Communities

| Community | Meaning |
|---|---|
| `(65535, 0)` | `GRACEFUL_SHUTDOWN` (RFC 8326): received routes get `local_pref = 0` |
| `(65535, 65281)` | `NO_EXPORT` (RFC 1997) |
| `(65535, 65282)` | `NO_ADVERTISE` (RFC 1997) |
| `(64511, 34)` | Link encryption: WireGuard with PFS (propagated as path minimum) |
| `(64511, 83)` | Link topology: Tunnel (propagated as path maximum) |
| `(64511, 41..70)` | Origin region on our originated prefixes (`41` EU, `44` NA-W, `52` Asia-E) |
| `(64511, 1000+ISO)` | Origin country on our originated prefixes (`1276` DE, `1344` HK, `1392` JP, `1528` NL, `1840` US) |
| `(64511, 65282)` | Internal FlapAlerted flapping marker (scrubbed on import, never re-exported) |

### Informational Large Communities

Attached to routes entering or originating from `AS4242420642` (scrubbed on import):

| Large Community | Meaning |
|---|---|
| `(4242420642, 10, <node_id>)` | Ingress/origin node ID (`1`..`6`, see Node table above) |
| `(4242420642, 11, <region>)` | Ingress/origin DN42 region (`41`, `44`, `52`) |
| `(4242420642, 12, <country>)` | Ingress/origin DN42 country (`1276`, `1344`, `1392`, `1528`, `1840`) |

### Action Large Communities (Traffic Engineering)

Peers may attach these Large Communities to control export and routing policy inside `AS4242420642` (stripped on eBGP export):

| Large Community | Action |
|---|---|
| `(4242420642, 0, 0)` | Do not export to any eBGP peer |
| `(4242420642, 0, <peer_asn>)` | Do not export to `<peer_asn>` |
| `(4242420642, 1000, <region>)` | Do not export from nodes in DN42 region `<region>` |
| `(4242420642, 1001, <node_id>)` | Do not export from node `<node_id>` |
| `(4242420642, 101..103, <peer_asn>)` | Prepend `AS4242420642` 1x / 2x / 3x to `<peer_asn>` (`0` = all eBGP peers) |
| `(4242420642, 1101..1103, <region>)` | Prepend `AS4242420642` 1x / 2x / 3x when exporting from region `<region>` |
| `(4242420642, 200, 50\|80\|90)` | Set `local_pref` to `50` / `80` / `90` (default `100`) |

Prepend precedence: peer-specific `(101..103, <peer_asn>)` > region-specific `(1101..1103, <region>)` > global `(101..103, 0)` (capped at 3x).
