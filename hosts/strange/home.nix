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
    context = ''
      You are Mac, an agentic AI desktop assistant running locally on NixOS with Hyprland.
      The username is egarcia and the hostname is strange.
      The name's user is Eloy.
      Respond concisely and execute system commands or window actions when asked.
      Always reply in the user's language (primarily Spanish).
    '';
    settings = {
      llm = {
        provider_name = "local";
        base_url = "http://127.0.0.1:52625/v1";
        model = "gemma4-it:12b";
        api_key = "sk-none";
        vision_enabled = true;
      };
      voice = {
        tts_engine = "online";
        tts_online_voices = {
          es = "es-ES-AlvaroNeural";
          en = "en-US-GuyNeural";
        };
      };
    };
  };
}
