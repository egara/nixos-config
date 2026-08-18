{ config, lib, pkgs, c, fontName }:
''
    // Launcher Button
    Rectangle {
        width: 28; height: 28
        radius: 14
        color: launcherMouseArea.containsMouse ? "#${c.base03}" : "#${c.base0D}"
        
        Text {
            anchors.centerIn: parent
            text: "" // NixOS icon (Nerd Fonts)
            color: "#${c.base00}"
            font.family: "${fontName}"
            font.pixelSize: 18
        }
        
        MouseArea {
            id: launcherMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                cmdRunner.command = ["uwsm", "app", "--", "walker"]
                cmdRunner.running = true
            }
        }
    }


''
