{ lib, pkgs, config, ... }:
{
  home.sessionVariables = {
    PATH = "$PATH\${PATH:+:}$HOME/.cargo/bin:$HOME/.local/bin";
  };

  programs.fish = {
    enable = true;

    shellAbbrs = {
      myip = "curl -L -s ipconfig.me";
      ls = "exa -al --icons";
      tree = "exa -T";
    };
    promptInit = ''
      # Defined interactively
      function fish_prompt
        switch "$fish_key_bindings"
          case fish_hybrid_key_bindings fish_vi_key_bindings
            set STARSHIP_KEYMAP "$fish_bind_mode"
          case '*'
            set STARSHIP_KEYMAP insert
        end
      set STARSHIP_CMD_STATUS $status
      # Account for changes in variable name between v2.7 and v3.0
      set STARSHIP_DURATION "$CMD_DURATION$cmd_duration"
      "${pkgs.starship}/bin/starship" prompt --status=$STARSHIP_CMD_STATUS --keymap=$STARSHIP_KEYMAP --cmd-duration=$STARSHIP_DURATION --jobs=(count (jobs -p))
      end
    '';
    shellInit = ''
      export LANG="en_US.UTF-8"
      set -g fish_greeting
    '';
  };
  programs.starship = {
    enable = true;
    settings = {
      battery = { disabled = true; };
      directory = { 
        read_only_style = "green";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
    };
  };
  
  home.packages = let
    nix-fish-completion = pkgs.runCommand "nix-fish-completion" {} ''
      install -Dm644 ${./completions/nix.fish} $out/share/fish/completions/nix.fish
    '';
  in [
    nix-fish-completion
  ];
}
