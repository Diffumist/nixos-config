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

| Node | Location | Endpoint | WireGuard public key | DN42 IPv4 | DN42 IPv6 |
|---|---|---|---|---|---|
| ams-0 | Amsterdam, NL | `ams-0.diffumist.me` | `25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=` | `172.22.64.65` | `fd22:1056:95a4:1::1` |
| sjc-0 | San Jose, US | `sjc-0.diffumist.me` | `byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=` | `172.22.64.66` | `fd22:1056:95a4:2::1` |
| lax-0 | Los Angeles, US | `lax-0.diffumist.me` | `viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=` | `172.22.64.67` | `fd22:1056:95a4:3::1` |
| tyo-0 | Tokyo, JP | `tyo-0.diffumist.me` | `KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=` | `172.22.64.68` | `fd22:1056:95a4:4::1` |
| hkg-0 | Hong Kong, HK | `hkg-0.diffumist.me` | `3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=` | `172.22.64.69` | `fd22:1056:95a4:5::1` |
| nue-0 | Nuremberg, DE | `nue-0.diffumist.me` | `Ti77y04KRfP/GRLPp87cw/8tcIB4Z6+phjOTQhoqHBQ=` | `172.22.64.70` | `fd22:1056:95a4:6::1` |

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
