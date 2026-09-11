{ config, pkgs, c, fontName, ... }:
{
  widget = ''
    PanelWindow {
        id: progressOsdWindow
        visible: mainScope.progressOsdVisible && (mainScope.progressOsdType === "Volume" || mainScope.progressOsdType === "Brightness")
        
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
        
        implicitWidth: 380
        implicitHeight: 56
        
        Item {
            id: progressOsdContent
            anchors.fill: parent
            
            // Animations
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            opacity: (mainScope.progressOsdVisible && (mainScope.progressOsdType === "Volume" || mainScope.progressOsdType === "Brightness")) ? 1 : 0
            
            Rectangle {
                anchors.fill: parent
                color: "#E6${c.base01}"
                radius: 28
                border.color: "#33${c.base05}"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14
                    
                    Text {
                        text: {
                            if (mainScope.progressOsdType === "Volume") {
                                if (mainScope.progressOsdValue === 0) return "󰝟";
                                if (mainScope.progressOsdValue < 50) return "󰖀";
                                return "󰕾";
                            }
                            // Brightness icon (Sun)
                            return "󰃠";
                        }
                        color: "#${c.base0D}"
                        font.family: "${fontName}"
                        font.pixelSize: 24
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                        Layout.alignment: Qt.AlignVCenter
                        radius: 5
                        color: "#33${c.base05}"
                        clip: true
                        
                        Rectangle {
                            height: parent.height
                            width: parent.width * (mainScope.progressOsdValue / 100.0)
                            radius: 6
                            color: "#${c.base0D}"
                            
                            Behavior on width {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                    
                    Text {
                        text: mainScope.progressOsdValue + "%"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 15
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
    
    PanelWindow {
        id: lockOsdWindow
        visible: mainScope.progressOsdVisible && (mainScope.progressOsdType === "Caps Lock" || mainScope.progressOsdType === "Num Lock" || mainScope.progressOsdType === "Caffeine" || mainScope.progressOsdType === "Night Mode")
        
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
        
        implicitWidth: (mainScope.progressOsdType === "Caffeine" || mainScope.progressOsdType === "Night Mode") ? 190 : 100
        implicitHeight: 56
        
        Item {
            id: lockOsdContent
            anchors.fill: parent
            
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            opacity: (mainScope.progressOsdVisible && (mainScope.progressOsdType === "Caps Lock" || mainScope.progressOsdType === "Num Lock" || mainScope.progressOsdType === "Caffeine" || mainScope.progressOsdType === "Night Mode")) ? 1 : 0
            
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
                        text: {
                            if (mainScope.progressOsdType === "Caps Lock") return "󰘲";
                            if (mainScope.progressOsdType === "Num Lock") return "󰎦";
                            if (mainScope.progressOsdType === "Caffeine") return "";
                            if (mainScope.progressOsdType === "Night Mode") return "";
                            return "󰂚";
                        }
                        color: (mainScope.progressOsdValue === 1) ? "#${c.base0D}" : "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 22
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Text {
                        visible: (mainScope.progressOsdType === "Caffeine" || mainScope.progressOsdType === "Night Mode")
                        text: mainScope.progressOsdType
                        color: "#${c.base05}"
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
                        text: mainScope.progressOsdValue === 1 ? "ON" : "OFF"
                        color: (mainScope.progressOsdValue === 1) ? "#${c.base0B}" : "#${c.base08}"
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
