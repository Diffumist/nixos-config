{ config, ... }: {
  "editor.renderWhitespace" = "all";
  "editor.renderControlCharacters" = true;
  "editor.fontFamily" = "'JetBrains Mono','JetBrainsMono Nerd Font'";
  "editor.fontSize" = 16;
  "editor.fontLigatures" = true;
  "workbench.iconTheme" = "material-icon-theme";
  "git.autofetch" = true;
  "git.enableSmartCommit" = true;
  "workbench.enableExperiments" = false;
  "editor.smoothScrolling" = true;
  "editor.scrollBeyondLastLine" = false;
  "editor.links" = true;
  "editor.renderLineHighlight" = "all";
  "explorer.confirmDelete" = true;
  "typescript.updateImportsOnFileMove.enabled" = "always";
  "extensions.ignoreRecommendations" = true;
  "terminal.explorerKind" = "external";
  "git.autoStash" = true;
  "git.showPushSuccessNotification" = true;
  "editor.formatOnPaste" = true;
  "editor.formatOnType" = true;
  "debug.console.closeOnEnd" = true;
  "debug.onTaskErrors" = "showErrors";
  "task.autoDetect" = "off";
  "gitlens.advanced.messages" = {
    "suppressFileNotUnderSourceControlWarning" = true;
  };
  "git.enableCommitSigning" = true;
  "editor.suggestSelection" = "first";
  "files.autoSave" = "onFocusChange";
  "terminal.external.linuxExec" = "alacritty";
  "extensions.autoUpdate" = false;
  "files.associations" = {
    "*.md" = "markdown";
    "*.json" = "jsonc";
  };
  "[javascriptreact]" = { };
  "[typescript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[jsonc]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[diff]" = {
    "editor.renderWhitespace" = "boundary";
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = false;
    "files.trimTrailingWhitespace" = false;
  };
  "[nix]" = {
    "editor.tabSize" = 2;
  };
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nil";
  "nix.serverSettings" = {
    "nil" = {
      "formatting" = { "command" = [ "nixpkgs-fmt" ]; };
    };
  };
  "update.showReleaseNotes" = false;
  "update.mode" = "none";
  "telemetry.telemetryLevel" = "off";
  "security.workspace.trust.untrustedFiles" = "open";
  "terminal.integrated.persistentSessionReviveProcess" = "never";
  "editor.inlineSuggest.enabled" = true;
  "files.autoGuessEncoding" = false;
  "extensions.autoCheckUpdates" = false;
  "workbench.startupEditor" = "none";
  "workbench.productIconTheme" = "material-product-icons";
}
