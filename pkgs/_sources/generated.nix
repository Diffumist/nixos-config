# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  v2ray-rules-dat = {
    pname = "v2ray-rules-dat";
    version = "509449cfa24fcbcb198704d36cfab73846cd3f60";
    src = fetchFromGitHub {
      owner = "Loyalsoldier";
      repo = "v2ray-rules-dat";
      rev = "509449cfa24fcbcb198704d36cfab73846cd3f60";
      fetchSubmodules = false;
      sha256 = "sha256-u4oBv2fjtqeuUIfPrPnLu5befUiPFV+UzJuvmSjTDmY=";
    };
    date = "2023-11-07";
  };
}
