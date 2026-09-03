import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    anchors {
        top: true
        left: true
        right: true
    }
    height: 40
    color: "#1e1e2e" // Catppuccin Mocha base

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        // Center text
        Text {
            anchors.centerIn: parent
            text: "SicOS Custom Bar (QuickShell POC)"
            color: "#cdd6f4" // Catppuccin Mocha text
            font.pixelSize: 16
            font.bold: true
        }

        // Left side workspaces placeholder
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: 5
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: index === 0 ? "#89b4fa" : "#313244" // Active vs inactive
                }
            }
        }

        // Right side clock placeholder
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            color: "#cdd6f4"
            font.pixelSize: 16
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }
}
