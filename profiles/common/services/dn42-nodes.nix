# The DN42 mesh nodes, keyed by short node name. Plain data, so that hosts
# outside the mesh (the autopeer frontend) can read it too.
let
  baseurl = "diffumist.me";
in
{
  ams0 = {
    hostName = "liteserver-ams";
    endpoint = "ams-0.${baseurl}";
    ipv4 = "172.22.64.65";
    ipv6 = "fd22:1056:95a4:1::1";
    publicKey = "25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=";
    location = "Amsterdam, NL";
    capacity = 30;
  };
  sjc0 = {
    hostName = "hostdzire-sfo";
    endpoint = "sjc-0.${baseurl}";
    ipv4 = "172.22.64.66";
    ipv6 = "fd22:1056:95a4:2::1";
    publicKey = "byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=";
    location = "San Jose, US";
    capacity = 50;
  };
  lax0 = {
    hostName = "dedirock-lax";
    endpoint = "lax-0.${baseurl}";
    ipv4 = "172.22.64.67";
    ipv6 = "fd22:1056:95a4:3::1";
    publicKey = "viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=";
    location = "Los Angeles, US";
    capacity = 30;
  };
  tyo0 = {
    hostName = "noboard-tyo";
    endpoint = "tyo-0.${baseurl}";
    ipv4 = "172.22.64.68";
    ipv6 = "fd22:1056:95a4:4::1";
    publicKey = "KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=";
    location = "Tokyo, JP";
    capacity = 40;
  };
  hkg0 = {
    hostName = "wawo-hkg";
    endpoint = "hkg-0.${baseurl}";
    ipv4 = "172.22.64.69";
    ipv6 = "fd22:1056:95a4:5::1";
    publicKey = "3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=";
    location = "Hong Kong, HK";
    capacity = 15;
  };
  nue0 = {
    hostName = "netcup-nue";
    endpoint = "nue-0.${baseurl}";
    ipv4 = "172.22.64.70";
    ipv6 = "fd22:1056:95a4:6::1";
    publicKey = "Ti77y04KRfP/GRLPp87cw/8tcIB4Z6+phjOTQhoqHBQ=";
    location = "Nuremberg, DE";
    capacity = 25;
  };
}
