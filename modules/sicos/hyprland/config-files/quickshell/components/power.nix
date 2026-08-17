{ config, lib, pkgs, c, fontName }:
''
    // Power Profile Indicator
    Rectangle {
        color: "#${c.base02}"
        radius: 8
        Layout.preferredHeight: 28
        Layout.preferredWidth: 28
        
        Text {
            anchors.centerIn: parent
            text: PowerProfiles.profile === 0 ? "" : (PowerProfiles.profile === 1 ? "" : "")
            color: PowerProfiles.profile === 0 ? "#${c.base0B}" : (PowerProfiles.profile === 1 ? "#${c.base0D}" : "#${c.base08}") // Green for saver, Cyan for balanced, Red for performance
            font.family: "${fontName}"
            font.pixelSize: 14
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                // Cycle profiles on click
                let nextCmd = "balanced-mode";
                if (PowerProfiles.profile === 0) { // from saver to balanced
                    nextCmd = "balanced-mode";
                } else if (PowerProfiles.profile === 1) { // from balanced to performance
                    nextCmd = "powerprofilesctl set performance";
                } else { // from performance to saver
                    nextCmd = "power-saver-mode";
                }
                indicatorProc.exec(["sh", "-c", nextCmd])
            }
        }
        Process {
            id: indicatorProc
        }
    }

    // Power Menu Button
    Rectangle {
        width: 28; height: 28
        radius: 14
        color: powerMouseArea.containsMouse ? "#${c.base08}" : "#${c.base02}" // Red on hover
        
        Text {
            anchors.centerIn: parent
            text: "" // Power icon
            color: powerMouseArea.containsMouse ? "#${c.base00}" : "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 14
        }
        
        MouseArea {
            id: powerMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                cmdRunner.exec(["uwsm", "app", "--", "wlogout"])
            }
        }
    }
''
