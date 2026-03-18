import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: container
    width: Screen.width
    height: Screen.height
    color: "#0f0f0f" // Base Background

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

    Shortcut {
        sequence: "F1"
        onActivated: sddm.powerOff()
    }

    Shortcut {
        sequence: "F2"
        onActivated: sddm.reboot()
    }

    Shortcut {
        sequence: "F3"
        onActivated: {
            userSelect.focus = true
            userSelect.popup.open()
        }
    }

    Text {
        id: clock
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 80
        color: "#00ff00" // Accent Color (Green-ish)
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 80
        text: Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Rectangle {
        id: loginBox
        width: 600
        height: 380
        anchors.centerIn: parent
        color: "transparent"
        border.color: "#00ff00" // Accent Color
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 20

            Text {
                text: "> SicOS"
                color: "#cccccc" // Main Text
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 40
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
                onActivated: passwordField.focus = true

                Component.onCompleted: {
                    if (userModel.lastIndex !== undefined) {
                        currentIndex = userModel.lastIndex
                    }
                }

                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 24

                delegate: Controls.ItemDelegate {
                    width: userSelect.width
                    contentItem: Text {
                        text: model.name
                        color: "#00ff00"
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 24
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#222222" : "transparent" // Selection
                    }
                }

                contentItem: Text {
                    text: userSelect.displayText
                    color: "#00ff00"
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 24
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                background: Rectangle {
                    color: "#1a1a1a" // Input Background
                    border.color: "#00ff00"
                    border.width: 1
                }
            }

            // Password Input
            Controls.TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password..."
                placeholderTextColor: "#00aa00" // Dimmed Accent Color
                echoMode: TextInput.Password
                focus: true

                color: "#00ff00"
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 24

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
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 24
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
        anchors.topMargin: 30
        text: "STATUS: " + (loginError ? "ACCESS DENIED" : "READY")
        color: loginError ? "#ff0000" : "#8cf58c" // Red / Accent Color
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 22
    }

    Text {
        anchors.top: loginBox.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 70
        text: "[F1] SHUTDOWN  [F2] REBOOT  [F3] USER"
        color: "#888888" // Lighter grey for hints
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 18
        visible: !loginError
    }

    // Power Buttons
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 50

        Controls.Button {
            text: "SHUTDOWN [F1]"
            Layout.preferredWidth: 250

            contentItem: Text {
                text: parent.text
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 22
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
            text: "REBOOT [F2]"
            Layout.preferredWidth: 250

            contentItem: Text {
                text: parent.text
                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 22
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
