import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: container
    width: Screen.width
    height: Screen.height
    color: "#f5f5f5" // Base Background

    property int sessionIndex: 0
    property bool loginError: false

    Connections {
        target: sddm
        function onLoginFailed() {
            loginError = true
            passwordField.text = ""
            passwordField.focus = true
        }
        function onLoginSucceeded() {
            loginError = false
        }
    }

    Component.onCompleted: {
        if (sessionModel.lastIndex !== undefined) {
            sessionIndex = sessionModel.lastIndex
        }
    }

    Text {
        id: clock
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        color: "#0055ff" // Accent Color (Blue)
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
        height: 220
        anchors.centerIn: parent
        color: "transparent"
        border.color: "#0055ff" // Accent Color
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            Text {
                text: "> SicOS"
                color: "#333333" // Main Text
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
                currentIndex: 0
                
                Component.onCompleted: {
                    if (userModel.lastIndex !== undefined) {
                        currentIndex = userModel.lastIndex
                    }
                }
                
                font.family: "Monospace"
                font.pixelSize: 16
                
                delegate: Controls.ItemDelegate {
                    width: userSelect.width
                    contentItem: Text {
                        text: model.name
                        color: "#0055ff"
                        font.family: "Monospace"
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#d0d0d0" : "transparent" // Selection
                    }
                }

                contentItem: Text {
                    text: userSelect.displayText
                    color: "#0055ff"
                    font.family: "Monospace"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                background: Rectangle {
                    color: "#e0e0e0" // Input Background
                    border.color: "#0055ff"
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
                
                color: "#0055ff"
                font.family: "Monospace"
                font.pixelSize: 16
                
                background: Rectangle {
                    color: "#e0e0e0"
                    border.color: "#0055ff"
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
                    color: parent.down ? "#f5f5f5" : "#0055ff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.down ? "#0055ff" : "transparent"
                    border.color: "#0055ff"
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
        text: "STATUS: " + (loginError ? "ACCESS DENIED" : "READY")
        color: loginError ? "#d00000" : "#777777" // Red / Grey
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
                color: parent.down ? "#f5f5f5" : "#0055ff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#0055ff" : "transparent"
                border.color: "#0055ff"
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
                color: parent.down ? "#f5f5f5" : "#0055ff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#0055ff" : "transparent"
                border.color: "#0055ff"
                border.width: 1
            }
            
            onClicked: sddm.reboot()
        }
    }
}
