import sys

file_path = "/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/controlcenter.nix"
with open(file_path, 'r') as f:
    content = f.read()

def replace_block(content, start_str, end_str, wrap_start, wrap_end):
    idx = content.find(start_str)
    if idx == -1:
        print(f"Could not find start_str: {start_str[:30]}...")
        return content
    idx_end = content.find(end_str, idx)
    if idx_end == -1:
        print("Could not find end_str")
        return content
    
    idx_end += len(end_str)
    
    # We want to replace the whole block from start_str to end_str
    # with wrap_start + block + wrap_end
    
    block = content[idx:idx_end]
    new_block = wrap_start + block + wrap_end
    return content[:idx] + new_block + content[idx_end:]

# 1. Volume Master Text Block
vol_start = '                                    Text {\n                                        text: (Pipewire.defaultAudioSink'
vol_end = '                                        }\n                                    }'
content = replace_block(content, vol_start, vol_end, '                                    Item {\n                                        Layout.preferredWidth: 140\n                                        Layout.preferredHeight: 24\n', '\n                                    }')

# 2. Mic Master Text Block
mic_start = '                                    Text {\n                                        text: (Pipewire.defaultAudioSource'
mic_end = '                                        }\n                                    }'
content = replace_block(content, mic_start, mic_end, '                                    Item {\n                                        Layout.preferredWidth: 140\n                                        Layout.preferredHeight: 24\n', '\n                                    }')

# 3. Brightness Master Text Block
bri_start = '                                    Text {\n                                        text: "󰃠"'
bri_end = '                                        }\n                                    }'
content = replace_block(content, bri_start, bri_end, '                                    Item {\n                                        Layout.preferredWidth: 140\n                                        Layout.preferredHeight: 24\n', '\n                                    }')

# Accordion Sliders:
# 4. Volume App (Image + Text)
vol_app_start = '                                            Image {\n                                                width: 14'
vol_app_end = '                                                elide: Text.ElideRight\n                                            }'
content = replace_block(content, vol_app_start, vol_app_end, '                                            Item {\n                                                Layout.preferredWidth: 140\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    Item { width: 12 }\n', '\n                                                }\n                                            }')

# 5. Mic App (Rectangle + Text)
mic_app_start = '                                            Rectangle {\n                                                width: 24'
mic_app_end = '                                                elide: Text.ElideRight\n                                            }'
content = replace_block(content, mic_app_start, mic_app_end, '                                            Item {\n                                                Layout.preferredWidth: 140\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    Item { width: 12 }\n', '\n                                                }\n                                            }')

# 6. Brightness App (Text only)
bri_app_start = '                                            Text {\n                                                text: modelData.subtitle'
bri_app_end = '                                                elide: Text.ElideRight\n                                            }'
content = replace_block(content, bri_app_start, bri_app_end, '                                            Item {\n                                                Layout.preferredWidth: 140\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    Item { width: 12 }\n', '\n                                                }\n                                            }')

with open(file_path, 'w') as f:
    f.write(content)
