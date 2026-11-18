{
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
    enableContext = false;  # Using my own local ~/.config/assistant/context.md
  };
}
