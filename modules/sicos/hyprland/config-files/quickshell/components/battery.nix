{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: batteryPopup
        anchor.window: root
        anchor.rect.x: root.width - 10
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        visible: root.batteryVisible || popupContent.opacity > 0
        implicitWidth: 480
        implicitHeight: 280
        color: "transparent"

        // Helper functions
        function getRealBatteryHealth() {
            let h = UPower.displayDevice != null ? UPower.displayDevice.healthPercentage : 0;
            if (h > 0) return Math.round(h) + "%";
            for (let i = 0; i < UPower.devices.values.length; i++) {
                let d = UPower.devices.values[i];
                if (d.type === 2 && d.healthPercentage > 0) return Math.round(d.healthPercentage) + "%";
            }
            return "Unknown";
        }
        
        function getRealBatteryCapacity() {
            let cap = UPower.displayDevice != null ? UPower.displayDevice.energyCapacity : 0;
            if (cap > 0) return cap.toFixed(1) + " Wh";
            for (let i = 0; i < UPower.devices.values.length; i++) {
                let d = UPower.devices.values[i];
                if (d.type === 2 && d.energyCapacity > 0) return d.energyCapacity.toFixed(1) + " Wh";
            }
            return "Unknown";
        }
        
        function getBatteryStateString() {
            if (!UPower.displayDevice) return "Unknown";
            
            // Detect hardware charge limit (usually around 80% and in 'Pending Charge' state)
            if (UPower.displayDevice.state === 5 && UPower.displayDevice.percentage >= 0.79 && UPower.displayDevice.percentage <= 0.81) {
                return "Limit Reached";
            }
            
            switch(UPower.displayDevice.state) {
                case 1: return "Charging";
                case 2: return "Discharging";
                case 3: return "Empty";
                case 4: return "Fully Charged";
                case 5: return "Pending Charge";
                case 6: return "Pending Discharge";
                default: return "Unknown";
            }
        }
        
        function getTimeRemaining() {
            if (!UPower.displayDevice) return "N/A";
            let seconds = UPower.displayDevice.state === 1 ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty;
            if (seconds <= 0) return "N/A";
            let hours = Math.floor(seconds / 3600);
            let minutes = Math.floor((seconds % 3600) / 60);
            if (hours > 0) return hours + "h " + minutes + "m";
            return minutes + "m";
        }

        HyprlandFocusGrab {
            active: root.batteryVisible
            windows: [batteryPopup, root]
            onCleared: root.batteryVisible = false
        }

        Item {
            id: popupContent
            width: parent.width
            height: parent.height
            
            opacity: root.batteryVisible ? 1 : 0
            y: root.batteryVisible ? 0 : -20
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            // The background color providing the pixels
            Rectangle {
                id: bgSourceBattery
                anchors.fill: parent
                color: "#F0${c.base01}"
                visible: false
            }

            // The mask shape (Body + Beak)
            Item {
                id: bgMaskBattery
                anchors.fill: parent
                visible: false

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    radius: 16
                    color: "black"
                }

                Rectangle {
                    width: 20
                    height: 20
                    color: "black"
                    rotation: 45
                    y: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 150 // Aligned with battery widget
                }
            }

            // The final masked background
            OpacityMask {
                anchors.fill: parent
                source: bgSourceBattery
                maskSource: bgMaskBattery
            }


            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 32
                spacing: 16

                // Top Row: Icon, Status, Close
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: ""
                        color: "#${c.base0D}" // Cyan
                        font.family: "${fontName}"
                        font.pixelSize: 25
                    }
                    
                    Text {
                        text: "<font color='#${c.base05}'><b>" + (UPower.displayDevice != null ? Math.round(UPower.displayDevice.percentage * 100) : 0) + "%</b></font> <font color='#${c.base04}'>" + batteryPopup.getBatteryStateString() + "</font>"
                        font.family: "${fontName}"
                        font.pixelSize: 21
                        textFormat: Text.RichText
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                    }
                    
                }

                // Middle Row: Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Health"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryHealth()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 23
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Capacity"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryCapacity()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 23
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    // Time Remaining Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Time"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getTimeRemaining()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 23
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // Charge Limit Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 12
                    color: "#${c.base02}"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        Text {
                            text: "Hardware Charge Limit"
                            color: "#${c.base0D}"
                            font.family: "${fontName}"
                            font.pixelSize: 16
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "80%"
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.bold: true
                            font.pixelSize: 19
                        }
                    }
                }

                // Bottom Row: Power Profiles
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 8
                    
                    Repeater {
                        model: [
                            { name: "Power Saver", cmd: "power-saver-mode", enumVal: 0 },
                            { name: "Balanced", cmd: "balanced-mode", enumVal: 1 },
                            { name: "Performance", cmd: "powerprofilesctl set performance", enumVal: 2 }
                        ]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 20
                            color: PowerProfiles.profile === modelData.enumVal ? "#${c.base0D}" : 
                                   (profileArea.containsMouse ? "#${c.base03}" : "#${c.base02}")
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: PowerProfiles.profile === modelData.enumVal ? "#${c.base00}" : "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 17
                                font.bold: PowerProfiles.profile === modelData.enumVal
                            }
                            
                            MouseArea {
                                id: profileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    profileProc.exec(["sh", "-c", modelData.cmd])
                                }
                            }
                            Process {
                                id: profileProc
                            }
                        }
                    }
                }
            }
        }
    }
  '';

  widget = ''
    // Battery Widget (DMS Pill Style)
    Rectangle {
        id: batteryWidgetContainer
        property bool showPercent: UPower.displayDevice != null && UPower.displayDevice.state !== 4 && UPower.displayDevice.state !== 5
        color: batteryMouseArea.containsMouse ? "#${c.base03}" : (root.batteryVisible ? "#E6${c.base02}" : "#CC${c.base01}")
        radius: 14 // Fully rounded pill
        Layout.preferredHeight: 36
        Layout.preferredWidth: showPercent ? 70 : 42
        visible: UPower.displayDevice != null && UPower.displayDevice.isPresent
        
        // Smooth transition for width changes
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: (UPower.displayDevice != null && UPower.displayDevice.state === 1) ? "⚡" : 
                      (UPower.displayDevice != null && (UPower.displayDevice.state === 4 || UPower.displayDevice.state === 5)) ? "󰚥" : "🔋"
                color: {
                    if (!UPower.displayDevice) return "#${c.base05}";
                    let s = UPower.displayDevice.state;
                    if (s === 1) return "#${c.base0A}"; // Yellow when actively charging
                    if (s === 4 || s === 5) return "#${c.base05}"; // Standard button color when plugged in
                    if (UPower.displayDevice.percentage < 0.2) return "#${c.base08}"; // Red when low
                    return "#${c.base0B}"; // Green when discharging
                }
                font.pixelSize: 18
                font.family: "${fontName}"
            }
            Text {
                text: UPower.displayDevice != null ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                visible: batteryWidgetContainer.showPercent
                color: "#${c.base05}"
                font.family: "${fontName}"
                font.pixelSize: 16
                font.bold: true
            }
        }

        MouseArea {
            id: batteryMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.batteryVisible = !root.batteryVisible
            }
        }
    }
  '';
}
