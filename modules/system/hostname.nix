{ hostName, lib, ... }:
{
  networking.hostName = lib.mkDefault hostName;
}
