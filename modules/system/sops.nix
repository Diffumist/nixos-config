{
  config,
  hostName,
  hostPath,
  lib,
  self,
  ...
}:
let
  recipientMatches = lib.concatMap (
    line:
    let
      match = builtins.match ("[[:space:]]*-[[:space:]]*&${hostName}[[:space:]]+(age1[0-9a-z]+)[[:space:]]*") line;
    in
    lib.optionals (match != null) match
  ) (lib.splitString "\n" (builtins.readFile "${self}/.sops.yaml"));
  hostRecipient =
    if builtins.length recipientMatches == 1 then builtins.head recipientMatches else null;
  referencedSopsFiles = lib.unique (
    map (secret: secret.sopsFile) (builtins.attrValues config.sops.secrets)
  );
  missingRecipientFiles =
    if hostRecipient == null then
      [ ]
    else
      lib.filter (
        file: !lib.hasInfix "recipient: ${hostRecipient}" (builtins.readFile file)
      ) referencedSopsFiles;
in
{
  sops.defaultSopsFile = hostPath + "/secrets.yaml";

  assertions = [
    {
      assertion = builtins.length recipientMatches == 1;
      message = ".sops.yaml must define exactly one age recipient anchor for ${hostName}";
    }
    {
      assertion = hostRecipient == null || missingRecipientFiles == [ ];
      message = ''
        ${hostName} cannot decrypt these referenced SOPS files:
        ${lib.concatMapStringsSep "\n" (file: "- ${toString file}") missingRecipientFiles}
        Run sops updatekeys after changing .sops.yaml.
      '';
    }
  ];
}
