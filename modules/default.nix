{ ... }:
{
  imports = [
    (import ./nix)
    (import ./desktop)
    (import ./program)
    (import ./hardware)
    (import ./baseline)
    (import ./virtualisation)
  ];
}
