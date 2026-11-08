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
      The name's user is Eloy and he lives in León (Spain).
      Respond concisely and execute system commands or window actions when asked.
      Always reply in the user's language (primarily Spanish).
    '';
    settings = {
      llm = {
        default = "gemma";
        models = {
          gemma = {
            provider_name = "local";
            base_url = "http://127.0.0.1:52625/v1";
            model = "gemma4-it:12b";
            api_key = "sk-none";
            vision_enabled = true;
            timeout = 180.0;
          };
          glm = {
            provider_name = "local";
            base_url = "http://127.0.0.1:8010/v1";
            model = "GLM-5.3-Flash";
            api_key = "sk-none";
            vision_enabled = true;
            timeout = 180.0;
          };
        };
      };
      decision_router = {
        enabled = true;
        endpoint = "http://127.0.0.1:52625/v1/systemone";
        model = "d3:edge";
        timeout = 1.5;
        confidence_threshold = 0.60;
      };
      voice = {
        tts_engine = "none";
        silence_duration = "0.7";
        silence_threshold = "1%";
        asr = {
          enabled = true;
          endpoint = "http://127.0.0.1:52625/v1/audio/transcriptions";
          model = "whisper";
          language = "es";
          timeout = 10.0;
        };
        # To enable TTS output, switch tts_engine and configure voices:
        # tts_engine = "online"; # Options: "none", "online", "local"
        # tts_online_voices = {
        #   es = "es-ES-AlvaroNeural";
        #   en = "en-US-GuyNeural";
        # };
        # For local offline Piper models:
        # tts_engine = "local";
        # tts_offline_voices = [ "en" "es" ];
      };
      mcp_servers = {
        searxng = {
          url = "http://127.0.0.1:32771/mcp";
          transport = "streamable_http";
        };
      };
    };
  };
}
