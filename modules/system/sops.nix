{ hostPath, ... }:
{
  sops.defaultSopsFile = hostPath + "/secrets.yaml";
}
