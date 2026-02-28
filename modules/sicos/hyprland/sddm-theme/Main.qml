import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#0f0f0f" // Back to solid black

    property int sessionIndex: sddm.lastSessionIndex

    Text {
        id: clock
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        color: "#00ff00" // Terminal green
        font.family: "Monospace"
        font.pixelSize: 48
        text: Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Rectangle {
        id: loginBox
        width: 400
        height: 220 // Even more compact
        anchors.centerIn: parent
        color: "transparent"
        border.color: "#00ff00" // Back to terminal green
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8 // Minimal spacing

            Text {
                text: "> SicOS"
                color: "#cccccc"
                font.family: "Monospace"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // User Selection
            Controls.ComboBox {
                id: userSelect
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                
                font.family: "Monospace"
                font.pixelSize: 16
                
                delegate: Controls.ItemDelegate {
                    width: userSelect.width
                    contentItem: Text {
                        text: model.name
                        color: "#00ff00"
                        font.family: "Monospace"
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#222222" : "transparent"
                    }
                }

                contentItem: Text {
                    text: userSelect.displayText
                    color: "#00ff00"
                    font.family: "Monospace"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                background: Rectangle {
                    color: "#1a1a1a"
                    border.color: "#00ff00"
                    border.width: 1
                }
            }

            // Password Input
            Controls.TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password..."
                echoMode: TextInput.Password
                focus: true
                
                color: "#00ff00"
                font.family: "Monospace"
                font.pixelSize: 16
                
                background: Rectangle {
                    color: "#1a1a1a"
                    border.color: "#00ff00"
                    border.width: 1
                }

                onAccepted: sddm.login(userSelect.currentText, passwordField.text, sessionIndex)
            }
            
            Controls.Button {
                text: "EXECUTE"
                Layout.fillWidth: true
                
                contentItem: Text {
                    text: parent.text
                    font.family: "Monospace"
                    color: parent.down ? "#0f0f0f" : "#00ff00"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.down ? "#00ff00" : "transparent"
                    border.color: "#00ff00"
                    border.width: 1
                }
                
                onClicked: sddm.login(userSelect.currentText, passwordField.text, sessionIndex)
            }
        }
    }
    
    // Status / Error message
    Text {
        anchors.top: loginBox.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        text: "STATUS: " + (sddm.loginError ? "ACCESS DENIED" : "READY")
        color: sddm.loginError ? "#ff0000" : "#555555"
        font.family: "Monospace"
        font.pixelSize: 14
    }

    // Power Buttons
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 50
        
        Controls.Button {
            text: "SHUTDOWN"
            Layout.preferredWidth: 150
            
            contentItem: Text {
                text: parent.text
                font.family: "Monospace"
                color: parent.down ? "#0f0f0f" : "#00ff00"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#00ff00" : "transparent"
                border.color: "#00ff00"
                border.width: 1
            }
            
            onClicked: sddm.powerOff()
        }

        Item { Layout.fillWidth: true } // Spacer

        Controls.Button {
            text: "REBOOT"
            Layout.preferredWidth: 150
            
            contentItem: Text {
                text: parent.text
                font.family: "Monospace"
                color: parent.down ? "#0f0f0f" : "#00ff00"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#00ff00" : "transparent"
                border.color: "#00ff00"
                border.width: 1
            }
            
            onClicked: sddm.reboot()
        }
    }
}
