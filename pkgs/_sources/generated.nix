# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chatbox-bin = {
    pname = "chatbox-bin";
    version = "0.4.4";
    src = fetchurl {
      url = "https://github.com/Bin-Huang/chatbox/releases/download/v0.4.4/chatbox_0.4.4_amd64.deb";
      sha256 = "sha256-IDwUIRID0tcWXwWxUgFibXWtMlv/12RFXq2ro6KryFs=";
    };
  };
  clash-meta = {
    pname = "clash-meta";
    version = "1.14.4";
    src = fetchurl {
      url = "https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.14.4/clash.meta-linux-amd64-v1.14.4.gz";
      sha256 = "sha256-Kvt6Uhgp4uXPDWapc8XWU+f1Ly8vSGM1HQd9bDdV2ng=";
    };
  };
  maxmind-geoip = {
    pname = "maxmind-geoip";
    version = "34b4cd5952e9326578746744ec8f1bd9255ba600";
    src = fetchFromGitHub ({
      owner = "Loyalsoldier";
      repo = "geoip";
      rev = "34b4cd5952e9326578746744ec8f1bd9255ba600";
      fetchSubmodules = false;
      sha256 = "sha256-Z1+StT0hRKOV24zX7miefeIK4AXnrnGvX1AhpxN4syw=";
    });
    date = "2023-05-11";
  };
}
