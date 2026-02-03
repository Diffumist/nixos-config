inputs: let
  system = "x86_64-linux";
  sopsModule = inputs.sops-nix.nixosModules.sops;
  hmModule = inputs.home-manager.nixosModules.home-manager;
  impModule = inputs.impermanence.nixosModules.impermanence;
  diskoModule = inputs.disko.nixosModules.disko;
  inherit (inputs.nixpkgs.lib) nixosSystem;
in {
  liteserver = nixosSystem {
    inherit system;
    specialArgs = {inherit inputs;};
    modules = [
      ./common
      ./liteserver
      sopsModule
      hmModule
      impModule
    ];
  };
  nixiso = nixosSystem {
    inherit system;
    specialArgs = {inherit inputs;};
    modules = [
      ./common
      ./nixiso
      sopsModule
      diskoModule
    ];
  };
}