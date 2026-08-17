{ config, lib, pkgs, c, fontName }:
''
    // Workspace Switcher
    Row {
        spacing: 6
        Repeater {
            model: Hyprland.workspaces
            Rectangle {
                property bool isActive: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === modelData.id
                width: isActive ? 32 : 24
                height: 24
                radius: 12
                color: isActive ? "#${c.base0D}" : "#${c.base02}"
                anchors.verticalCenter: parent.verticalCenter
                
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    color: isActive ? "#${c.base00}" : "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
''
