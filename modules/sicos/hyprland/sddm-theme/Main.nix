{ colors, fontName }:
''
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

Rectangle {
    id: container
    width: Screen.width
    height: Screen.height
    color: "#${colors.base00}" // Base Background

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
        color: "#${colors.base0B}" // Accent Color (Green-ish)
        font.family: "${fontName}"
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
        border.color: "#${colors.base0B}" // Accent Color
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            Text {
                text: "> SicOS"
                color: "#${colors.base05}" // Main Text
                font.family: "${fontName}"
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
                
                font.family: "${fontName}"
                font.pixelSize: 16
                
                delegate: Controls.ItemDelegate {
                    width: userSelect.width
                    contentItem: Text {
                        text: model.name
                        color: "#${colors.base0B}"
                        font.family: "${fontName}"
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#${colors.base02}" : "transparent" // Selection
                    }
                }

                contentItem: Text {
                    text: userSelect.displayText
                    color: "#${colors.base0B}"
                    font.family: "${fontName}"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                }

                background: Rectangle {
                    color: "#${colors.base01}" // Input Background
                    border.color: "#${colors.base0B}"
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
                
                color: "#${colors.base0B}"
                font.family: "${fontName}"
                font.pixelSize: 16
                
                background: Rectangle {
                    color: "#${colors.base01}"
                    border.color: "#${colors.base0B}"
                    border.width: 1
                }

                onAccepted: sddm.login(userSelect.currentText, passwordField.text, sessionIndex)
            }
            
            Controls.Button {
                text: "EXECUTE"
                Layout.fillWidth: true
                
                contentItem: Text {
                    text: parent.text
                    font.family: "${fontName}"
                    color: parent.down ? "#${colors.base00}" : "#${colors.base0B}"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.down ? "#${colors.base0B}" : "transparent"
                    border.color: "#${colors.base0B}"
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
        color: loginError ? "#${colors.base08}" : "#${colors.base04}" // Red / Grey
        font.family: "${fontName}"
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
                font.family: "${fontName}"
                color: parent.down ? "#${colors.base00}" : "#${colors.base0B}"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#${colors.base0B}" : "transparent"
                border.color: "#${colors.base0B}"
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
                font.family: "${fontName}"
                color: parent.down ? "#${colors.base00}" : "#${colors.base0B}"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.down ? "#${colors.base0B}" : "transparent"
                border.color: "#${colors.base0B}"
                border.width: 1
            }
            
            onClicked: sddm.reboot()
        }
    }
}
''
