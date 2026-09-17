{ config, lib, pkgs, c, fontName, ... }:
{
  # Shared per-screen feedback OSD (volume-style pill). Rendered once per
  # monitor inside the Variants block; shows up only on the output(s) that
  # are currently targeted by a multi-monitor setting (wallpaper output,
  # monitor scale, ...) so the user knows which screen will be affected.
  widget = ''
    PanelWindow {
        id: targetOsdWindow
        screen: root.screen
        visible: mainScope.targetOsdOutputs.indexOf(root.screen.name) !== -1

        anchors {
            top: true
            left: false
            right: false
            bottom: false
        }

        margins { top: 60 }

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        implicitWidth: 280
        implicitHeight: 56

        Item {
            id: targetOsdContent
            anchors.fill: parent

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            opacity: mainScope.targetOsdOutputs.indexOf(root.screen.name) !== -1 ? 1 : 0

            Rectangle {
                anchors.fill: parent
                color: "#E6${c.base01}"
                radius: 28
                border.color: "#33${c.base05}"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "󰍹"
                        color: "#${c.base0D}"
                        font.family: "${fontName}"
                        font.pixelSize: 22
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: mainScope.targetOsdLabel
                        color: "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 15
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 18
                        radius: 1
                        color: "#33${c.base05}"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        // Empty value falls back to the name of the screen the
                        // OSD is rendered on (used to identify each monitor)
                        text: mainScope.targetOsdValue !== "" ? mainScope.targetOsdValue : root.screen.name
                        color: "#${c.base0D}"
                        font.family: "${fontName}"
                        font.pixelSize: 15
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
  '';
}
