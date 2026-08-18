{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: batteryPopup
        anchor.window: root
        anchor.rect.x: root.width - 240 // Adjust position for wider popup
        anchor.rect.y: root.height
        anchor.rect.width: 65
        anchor.rect.height: 0
        anchor.edges: Edges.Bottom
        visible: root.batteryVisible || popupContent.opacity > 0
        implicitWidth: 380
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

        Rectangle {
            id: popupContent
            width: parent.width
            height: parent.height
            color: "#F0${c.base01}" // Slightly transparent dark background
            radius: 16
            border.color: "#33${c.base05}"
            border.width: 1
            
            // DMS-style smooth entrance/exit transitions (fade and slide up)
            opacity: root.batteryVisible ? 1 : 0
            y: root.batteryVisible ? 0 : -20
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Top Row: Icon, Status, Close
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: ""
                        color: "#${c.base0D}" // Cyan
                        font.family: "${fontName}"
                        font.pixelSize: 22
                    }
                    
                    Text {
                        text: "<font color='#${c.base05}'><b>" + (UPower.displayDevice != null ? Math.round(UPower.displayDevice.percentage * 100) : 0) + "%</b></font> <font color='#${c.base04}'>" + batteryPopup.getBatteryStateString() + "</font>"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        textFormat: Text.RichText
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                    }
                    
                    Text {
                        text: "✕"
                        color: closeArea.containsMouse ? "#${c.base05}" : "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.batteryVisible = false
                        }
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
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryHealth()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 20
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
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryCapacity()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 20
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
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getTimeRemaining()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 20
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
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "80%"
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.bold: true
                            font.pixelSize: 16
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
                                font.pixelSize: 14
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
        color: batteryMouseArea.containsMouse ? "#${c.base03}" : "#${c.base02}"
        radius: 14 // Fully rounded pill
        Layout.preferredHeight: 28
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
                font.pixelSize: 13
                font.family: "${fontName}"
            }
            Text {
                text: UPower.displayDevice != null ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                visible: batteryWidgetContainer.showPercent
                color: "#${c.base05}"
                font.family: "${fontName}"
                font.pixelSize: 13
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
