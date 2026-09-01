import re

file_path = "/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/controlcenter.nix"
with open(file_path, 'r') as f:
    content = f.read()

# 1. Volume Master
content = re.sub(
    r'(RowLayout\s*{\s*Layout\.fillWidth:\s*true\s*spacing:\s*12\s*)(Text\s*{\s*text:\s*\(Pipewire\.defaultAudioSink[^}]+}\s*})',
    r'\1Item {\n                                        Layout.preferredWidth: 160\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    content
)

# 2. Mic Master
content = re.sub(
    r'(RowLayout\s*{\s*Layout\.fillWidth:\s*true\s*spacing:\s*12\s*)(Text\s*{\s*text:\s*\(Pipewire\.defaultAudioSource[^}]+}\s*})',
    r'\1Item {\n                                        Layout.preferredWidth: 160\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    content
)

# 3. Brightness Master
content = re.sub(
    r'(RowLayout\s*{\s*Layout\.fillWidth:\s*true\s*spacing:\s*12\s*)(Text\s*{\s*text:\s*"󰃠"[^}]+})',
    r'\1Item {\n                                        Layout.preferredWidth: 160\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    content
)

with open(file_path, 'w') as f:
    f.write(content)
