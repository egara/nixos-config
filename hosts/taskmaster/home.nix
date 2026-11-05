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
      The username is egarcia and the hostname is taskmaster.
      The name's user is Eloy and he lives in León (Spain).
      Respond concisely and execute system commands or window actions when asked.
      Always reply in the user's language (primarily Spanish).
    '';
    settings = {
      llm = {
        provider_name = "local";
        # Taskmaster has no FastFlowLM (unlike strange), so the assistant talks
        # to the local Open WebUI instance which proxies GLM-5.3-Flash
        base_url = "http://127.0.0.1:8010/v1";
        model = "GLM-5.3-Flash";
        api_key = "sk-none";
        vision_enabled = true;
        # Same Open WebUI server: if GLM fails, retry with another hosted model
        fallback = {
          provider_name = "local";
          base_url = "http://127.0.0.1:8010/v1";
          model = "qwen3";
          api_key = "sk-none";
          vision_enabled = false;
        };
      };
      voice = {
        tts_engine = "none";
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
      # MCP containers running in Docker on this host. The published ports are
      # different from strange's ones (32770/32771 there)
      mcp_servers = {
        time = {
          url = "http://127.0.0.1:32770/sse";
          transport = "sse";
        };
        searxng = {
          url = "http://127.0.0.1:32771/mcp";
          transport = "streamable_http";
        };
      };
    };
  };
}
