{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.assistant.homeManagerModules.default
  ];

  programs.assistant = {
    enable = true;
    enableConfig = false;   # Using my own local ~/.config/assistant/config.json
    enableDefaultRole = false;  # Using my own default role within ~/.config/assistant/roles/default.md
  };
}
