{ system, nixpkgs, inputs, self, ... }:
let this = import ./../../pkgs; in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.clash
    self.nixosModules.nix-config
    self.nixosModules.sops-nix
    self.nixosModules.plasma-env
    {
      nixpkgs.overlays = [
        (import "${inputs.nickpkgs}/pkgs").overlay
        inputs.rust-overlay.overlay
        inputs.berberman.overlay
        this.overlay
      ];
    }
  ];
}

