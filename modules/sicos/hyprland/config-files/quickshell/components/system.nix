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
                cmdRunner.start()
            }
        }
    }

    // CPU / Mem Placeholders
    Rectangle {
        color: "#${c.base01}"
        radius: 8
        Layout.preferredHeight: 28
        Layout.preferredWidth: 60
        Text {
            anchors.centerIn: parent
            text: " CPU"
            color: "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 12
        }
    }
    Rectangle {
        color: "#${c.base01}"
        radius: 8
        Layout.preferredHeight: 28
        Layout.preferredWidth: 60
        Text {
            anchors.centerIn: parent
            text: " RAM"
            color: "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 12
        }
    }
''
