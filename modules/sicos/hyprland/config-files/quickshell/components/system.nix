{ config, lib, pkgs, c, fontName }:
''
    // Launcher Button
    Rectangle {
        width: 36; height: 36
        radius: 18
        border.width: 1
        border.color: "white"
        color: launcherMouseArea.containsMouse ? "#${c.base03}" : "#E6${c.base0D}"
        
        Text {
            anchors.centerIn: parent
            text: "" // NixOS icon (Nerd Fonts)
            color: "#${c.base00}"
            font.family: "${fontName}"
            font.pixelSize: 21
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
