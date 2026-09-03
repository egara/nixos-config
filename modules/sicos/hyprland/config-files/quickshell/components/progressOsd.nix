{ config, pkgs, c, fontName, ... }:
{
  widget = ''
    PanelWindow {
        id: progressOsdWindow
        visible: root.progressOsdVisible && (root.progressOsdType === "Volume" || root.progressOsdType === "Brightness")
        
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
        
        implicitWidth: 420
        implicitHeight: 64
        
        Item {
            anchors.fill: parent
            
            // Animations
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            opacity: progressOsdWindow.visible ? 1 : 0
            
            Rectangle {
                anchors.fill: parent
                color: "#E6${c.base01}"
                radius: 32
                border.color: "#33${c.base05}"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    Text {
                        text: root.progressOsdType === "Volume" ? (root.progressOsdValue === 0 ? "󰝟" : (root.progressOsdValue < 50 ? "󰖀" : "󰕾")) : "󰃠"
                        color: "#${c.base0D}"
                        font.family: "${fontName}"
                        font.pixelSize: 27
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        Layout.alignment: Qt.AlignVCenter
                        radius: 6
                        color: "#33${c.base05}"
                        clip: true
                        
                        Rectangle {
                            height: parent.height
                            width: parent.width * (root.progressOsdValue / 100.0)
                            radius: 6
                            color: "#${c.base0D}"
                            
                            Behavior on width {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                    
                    Text {
                        text: root.progressOsdValue + "%"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 17
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
    
    PanelWindow {
        id: lockOsdWindow
        visible: root.progressOsdVisible && (root.progressOsdType === "Caps Lock" || root.progressOsdType === "Num Lock")
        
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
        
        implicitWidth: 120
        implicitHeight: 64
        
        Item {
            anchors.fill: parent
            
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            opacity: lockOsdWindow.visible ? 1 : 0
            
            Rectangle {
                anchors.fill: parent
                color: "#E6${c.base01}"
                radius: 32
                border.color: "#33${c.base05}"
                border.width: 1
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: root.progressOsdType === "Caps Lock" ? "󰘲" : "󰎦"
                        color: "#${c.base0D}"
                        font.family: "${fontName}"
                        font.pixelSize: 25
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 20
                        radius: 1
                        color: "#33${c.base05}"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Text {
                        text: root.progressOsdValue === 1 ? "ON" : "OFF"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 17
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
  '';
}
