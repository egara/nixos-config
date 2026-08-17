{ config, lib, pkgs, c, fontName }:
''
    Text {
        id: clockText
        color: "#${c.base05}"
        font.family: "${fontName}"
        font.pixelSize: 14
        font.bold: true
        text: Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
        
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
        }
    }
''
