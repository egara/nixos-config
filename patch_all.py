import re

path = "/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/controlcenter.nix"
with open(path, 'r') as f:
    text = f.read()

# 1. Volume Master
text = re.sub(
    r'(PwObjectTracker {\s*objects: Pipewire\.defaultAudioSink \? \[Pipewire\.defaultAudioSink\] : \[\]\s*}\s*RowLayout {\s*Layout\.fillWidth: true\s*spacing: 12\s*)(Text {\s*text: \(Pipewire\.defaultAudioSink && Pipewire\.defaultAudioSink\.audio\.muted\) \? "" : "".*?MouseArea {\s*anchors\.fill: parent\s*onClicked: [^\n]+\n\s*}\s*})',
    r'\1Item {\n                                        Layout.preferredWidth: 150\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    text,
    flags=re.DOTALL
)

# 2. Volume App
text = re.sub(
    r'(delegate: RowLayout {\s*Layout\.fillWidth: true\s*Layout\.leftMargin: 24\s*spacing: 12\s*)(Image {\s*width: 14.*?opacity: modelData\.audio\.muted \? 0\.5 : 1\.0.*?MouseArea {.*?}\s*}\s*Text {\s*text: {.*?color: "#\$\{c\.base05\}".*?elide: Text\.ElideRight\s*})',
    r'\1Item {\n                                                Layout.preferredWidth: 126\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    spacing: 12\n                                                    \2\n                                                }\n                                            }',
    text,
    flags=re.DOTALL
)

# 3. Mic Master
text = re.sub(
    r'(PwObjectTracker {\s*objects: Pipewire\.defaultAudioSource \? \[Pipewire\.defaultAudioSource\] : \[\]\s*}\s*RowLayout {\s*Layout\.fillWidth: true\s*spacing: 12\s*)(Text {\s*text: \(Pipewire\.defaultAudioSource && Pipewire\.defaultAudioSource\.audio\.muted\) \? "" : "".*?MouseArea {\s*anchors\.fill: parent\s*onClicked: [^\n]+\n\s*}\s*})',
    r'\1Item {\n                                        Layout.preferredWidth: 150\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    text,
    flags=re.DOTALL
)

# 4. Mic App
text = re.sub(
    r'(delegate: RowLayout {\s*Layout\.fillWidth: true\s*Layout\.leftMargin: 24\s*spacing: 12\s*)(Rectangle {\s*width: 24\s*height: 24.*?MouseArea {.*?}\s*}\s*Text {\s*text: modelData\.properties\["node\.description"\] \|\| modelData\.name.*?elide: Text\.ElideRight\s*})',
    r'\1Item {\n                                                Layout.preferredWidth: 126\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    spacing: 12\n                                                    \2\n                                                }\n                                            }',
    text,
    flags=re.DOTALL
)

# 5. Brightness Master
text = re.sub(
    r'(RowLayout {\s*Layout\.fillWidth: true\s*spacing: 12\s*)(Text {\s*text: "󰃠".*?font\.pixelSize: 18\s*})',
    r'\1Item {\n                                        Layout.preferredWidth: 150\n                                        Layout.preferredHeight: 24\n                                        \2\n                                    }',
    text,
    flags=re.DOTALL
)

# 6. Brightness App
text = re.sub(
    r'(delegate: RowLayout {\s*Layout\.fillWidth: true\s*Layout\.leftMargin: 24\s*spacing: 12\s*)(Text {\s*text: modelData\.subtitle.*?elide: Text\.ElideRight\s*})',
    r'\1Item {\n                                                Layout.preferredWidth: 126\n                                                Layout.preferredHeight: 24\n                                                RowLayout {\n                                                    anchors.fill: parent\n                                                    \2\n                                                }\n                                            }',
    text,
    flags=re.DOTALL
)

# Fix double widths on text elements inside wrappers
text = text.replace('Layout.preferredWidth: 80', 'Layout.fillWidth: true')
text = text.replace('Layout.minimumWidth: 80', '')
text = text.replace('Layout.maximumWidth: 80', '')

# Remove Layout.leftMargin: 24 from the RowLayout since we handled it by using width: 126 vs 150 (150 - 24 = 126)
text = text.replace('Layout.leftMargin: 24', 'Item { width: 12 }')

with open(path, 'w') as f:
    f.write(text)
