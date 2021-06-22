check:
    nix flake check
update:
    nix flake update --recreate-lock-file
install:
    sudo nixos-rebuild switch --flake .#local