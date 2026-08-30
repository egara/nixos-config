{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: clockPopup
        anchor.window: root
        anchor.item: clockWidgetContainer
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        visible: root.clockVisible || popupContentClock.opacity > 0
        implicitWidth: 700
        implicitHeight: 480
        color: "transparent"

        HyprlandFocusGrab {
            active: root.clockVisible
            windows: [clockPopup, root]
            onCleared: root.clockVisible = false
        }

        Rectangle {
            id: popupContentClock
            width: parent.width
            height: parent.height
            color: "#F0${c.base01}" // Transparent dark background
            radius: 16
            border.color: "#33${c.base05}"
            border.width: 1
            
            opacity: root.clockVisible ? 1 : 0
            y: root.clockVisible ? 0 : -20
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Left side: Notifications (DankMaterialShell style placeholder)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 350
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Notificaciones"
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 18
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        // DND Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: dndHover.hovered ? "#${c.base03}" : (root.dndMode ? "#20${c.base0D}" : "transparent")
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰂛"
                                color: root.dndMode ? "#${c.base0D}" : "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            HoverHandler {
                                id: dndHover
                            }
                            TapHandler {
                                onTapped: root.dndMode = !root.dndMode
                            }
                        }

                        // Clear all button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: clearHover.hovered ? "#${c.base03}" : "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰎟" // Trash icon or clear all
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            HoverHandler {
                                id: clearHover
                            }
                            TapHandler {
                                onTapped: root.clearNotifications()
                            }
                        }
                    }

                    // Empty State
                    Rectangle {
                        visible: notificationModel.count === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰂚"
                                color: "#40${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 48
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "No hay notificaciones nuevas"
                                color: "#80${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // List of notifications
                    ListView {
                        id: notifList
                        visible: notificationModel.count > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: notificationModel
                        spacing: 8
                        clip: true
                        section.property: "appName"
                        section.criteria: ViewSection.FullString

                        populate: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        remove: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "x"; to: notifList.width; duration: 300; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "opacity"; to: 0; duration: 250; easing.type: Easing.OutCubic }
                            }
                        }
                        
                        addDisplaced: Transition {
                            NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        removeDisplaced: Transition {
                            NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
                        }

                        delegate: ColumnLayout {
                            id: delegateRoot
                            width: notifList.width
                            
                            readonly property bool isFirstInGroup: delegateRoot.ListView.previousSection !== delegateRoot.ListView.section
                            readonly property bool hasMultiple: delegateRoot.ListView.nextSection === delegateRoot.ListView.section || !isFirstInGroup
                            readonly property bool isExpanded: root.expandedGroups[model.appName] === true
                            readonly property bool shouldShow: isFirstInGroup || isExpanded
                            
                            visible: opacity > 0
                            opacity: shouldShow ? 1 : 0
                            height: shouldShow ? implicitHeight : 0
                            spacing: shouldShow ? 6 : 0
                            clip: true
                            
                            Behavior on height {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                            }
                            Behavior on spacing {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
                            }

                            // Group Header (visible only for the first item of a group)
                            RowLayout {
                                visible: delegateRoot.isFirstInGroup
                                Layout.fillWidth: true
                                Layout.topMargin: index === 0 ? 0 : 8
                                spacing: 8

                                Image {
                                    source: {
                                        var appImg = model.desktopEntry;
                                        if (!appImg || appImg === "") appImg = model.appIcon;
                                        
                                        if (appImg && appImg !== "") {
                                            if (appImg.startsWith("/")) return "file://" + appImg;
                                            return "image://icon/" + appImg;
                                        }
                                        
                                        var img = model.iconName.toString();
                                        if (img && img !== "") {
                                            if (img.startsWith("image://") || img.startsWith("file://")) return img;
                                            if (img.startsWith("/")) return "file://" + img;
                                            return "image://icon/" + img;
                                        }
                                        return "image://icon/dialog-information";
                                    }
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    fillMode: Image.PreserveAspectCrop
                                    
                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            var img = model.iconName.toString();
                                            var fallbackSource = "image://icon/dialog-information";
                                            
                                            if (img && img !== "") {
                                                if (img.startsWith("image://") || img.startsWith("file://")) fallbackSource = img;
                                                else if (img.startsWith("/")) fallbackSource = "file://" + img;
                                                else fallbackSource = "image://icon/" + img;
                                            }
                                            
                                            if (source.toString() !== fallbackSource) {
                                                source = fallbackSource;
                                            } else if (source.toString() !== "image://icon/dialog-information") {
                                                source = "image://icon/dialog-information";
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: model.appName
                                    color: "#${c.base0D}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Group expand button
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: groupExpandHover.hovered ? "#33${c.base05}" : "transparent"
                                    visible: delegateRoot.hasMultiple
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅂"
                                        rotation: delegateRoot.isExpanded ? 180 : 0
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 14
                                        
                                        Behavior on rotation {
                                            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                                        }
                                    }
                                    
                                    HoverHandler {
                                        id: groupExpandHover
                                    }
                                    
                                    TapHandler {
                                        onTapped: {
                                            root.toggleGroup(model.appName)
                                        }
                                    }
                                }

                                // Group close button
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: groupCloseHover.hovered ? "#${c.base08}" : "transparent"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: groupCloseHover.hovered ? "#${c.base00}" : "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 14
                                    }
                                    
                                    HoverHandler {
                                        id: groupCloseHover
                                    }
                                    
                                    TapHandler {
                                        onTapped: {
                                            root.dismissNotificationGroup(model.appName)
                                        }
                                    }
                                }
                            }

                            // Notification Card
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: cardContent.implicitHeight + 20

                                Rectangle {
                                    anchors.fill: parent
                                    color: notifHover.hovered ? "#${c.base03}" : "#40${c.base02}"
                                    radius: 10
                                    border.color: "#33${c.base05}"
                                    border.width: 1
                                }

                                HoverHandler {
                                    id: notifHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        root.invokeDefaultAction(model.notifId)
                                    }
                                }

                                RowLayout {
                                    id: cardContent
                                    anchors.centerIn: parent
                                    width: delegateRoot.width - 20
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 48
                                        Layout.preferredHeight: 48
                                        Layout.alignment: Qt.AlignTop
                                        radius: 8
                                        color: "transparent"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: {
                                                var img = model.iconName.toString();
                                                if (img.startsWith("image://") || img.startsWith("file://")) return img;
                                                if (img.startsWith("/")) return "file://" + img;
                                                return "image://icon/" + img;
                                            }
                                            sourceSize.width: 128
                                            sourceSize.height: 128
                                            fillMode: Image.PreserveAspectCrop
                                            
                                            onStatusChanged: {
                                                if (status === Image.Error) {
                                                    if (model.desktopEntry && source.toString() !== "image://icon/" + model.desktopEntry) {
                                                        source = "image://icon/" + model.desktopEntry;
                                                    } else if (model.appIcon && source.toString() !== "image://icon/" + model.appIcon) {
                                                        source = "image://icon/" + model.appIcon;
                                                    } else {
                                                        var generic = "image://icon/dialog-information";
                                                        if (source.toString() !== generic) source = generic;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            
                                            Text {
                                                text: model.summary
                                                color: "#${c.base05}"
                                                font.family: "${fontName}"
                                                font.pixelSize: 14
                                                font.bold: true
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                            }
                                            
                                            Text {
                                                text: model.timeStr
                                                color: "#${c.base04}"
                                                font.family: "${fontName}"
                                                font.pixelSize: 11
                                                Layout.alignment: Qt.AlignTop
                                            }

                                            // Close button
                                            Rectangle {
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 20
                                                Layout.alignment: Qt.AlignTop
                                                radius: 10
                                                color: closeHover.hovered ? "#${c.base08}" : "transparent"
                                                visible: notifHover.hovered
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰅖"
                                                    color: closeHover.hovered ? "#${c.base00}" : "#${c.base05}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 14
                                                }
                                                
                                                HoverHandler {
                                                    id: closeHover
                                                }
                                                
                                                TapHandler {
                                                    onTapped: {
                                                        root.forceDismissNotification(model.notifId, false)
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            text: model.body
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                        }
                                    }
                                }
                            }
                        }
                    }

                // Divider
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: "#33${c.base05}"
                }

                // Right side: Calendar (Omarchy style)
                ColumnLayout {
                    id: calendarRoot
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 330
                    spacing: 8
                    
                    // State and logic
                    property date today: new Date()
                    property string todayKey: Model.keyForDate(today)
                    property int viewYear: today.getFullYear()
                    property int viewMonth: today.getMonth()
                    property date viewDate: new Date(viewYear, viewMonth, 1)
                    property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()

                    property real yearDone: Model.yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
                    property int yearDonePercent: Model.yearProgressPercent(today.getFullYear(), today.getMonth(), today.getDate())

                    // Memento mori
                    property int birthYear: 0
                    property int lifeExpectancy: 90
                    property int age: Model.ageFromBirthYear(birthYear, today.getFullYear())
                    property real lifeDone: Model.lifeProgress(age, lifeExpectancy)
                    property int lifeDonePercent: Model.lifeProgressPercent(age, lifeExpectancy)
                    property bool editingLife: false
                    property int weekStart: 1 // Monday
                    property var weekdays: Model.weekdayOrder(weekStart)
                    property var weeks: Model.monthGrid(viewYear, viewMonth, weekStart, todayKey)

                    function goToToday() { viewYear = today.getFullYear(); viewMonth = today.getMonth(); }
                    function moveMonth(delta) { var next = Model.stepMonth(viewYear, viewMonth, delta); viewYear = next.year; viewMonth = next.month; }

                    SystemClock {
                        precision: SystemClock.Minutes
                        onDateChanged: {
                            if (Model.keyForDate(date) === calendarRoot.todayKey) return;
                            var followToday = calendarRoot.viewingCurrentMonth;
                            calendarRoot.today = date;
                            if (followToday) calendarRoot.goToToday();
                        }
                    }

                    // Month Nav
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 8
                        
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: prevHover.containsMouse ? "#${c.base03}" : "transparent"
                            Text { anchors.centerIn: parent; text: "󰅁"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            MouseArea { id: prevHover; anchors.fill: parent; hoverEnabled: true; onClicked: calendarRoot.moveMonth(-1) }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Text {
                                anchors.centerIn: parent
                                text: titleHover.containsMouse && !calendarRoot.viewingCurrentMonth ? "BACK TO TODAY" : Qt.formatDate(calendarRoot.viewDate, "MMMM yyyy").toUpperCase()
                                color: titleHover.containsMouse && !calendarRoot.viewingCurrentMonth ? "#${c.base0D}" : "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 15
                                font.bold: true
                                font.letterSpacing: 1
                            }
                            
                            MouseArea {
                                id: titleHover
                                anchors.fill: parent
                                hoverEnabled: !calendarRoot.viewingCurrentMonth
                                onClicked: calendarRoot.goToToday()
                            }
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: nextHover.containsMouse ? "#${c.base03}" : "transparent"
                            Text { anchors.centerIn: parent; text: "󰅂"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            MouseArea { id: nextHover; anchors.fill: parent; hoverEnabled: true; onClicked: calendarRoot.moveMonth(1) }
                        }
                    }

                    // Year progress
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        MouseArea {
                            Layout.fillWidth: true
                            height: 20
                            onDoubleClicked: calendarRoot.editingLife = true
                            
                            RowLayout {
                                anchors.fill: parent
                                Text { text: calendarRoot.today.getFullYear(); color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11; font.letterSpacing: 1 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                                    height: 4; radius: 2; color: "#22${c.base05}"
                                    Rectangle { width: parent.width * calendarRoot.yearDone; height: parent.height; radius: parent.radius; color: "#${c.base0D}" }
                                }
                                Text { text: calendarRoot.yearDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 11 }
                            }
                        }
                        
                        // Life progress
                        Item {
                            Layout.fillWidth: true
                            height: calendarRoot.editingLife || calendarRoot.birthYear > 0 ? 20 : 0
                            visible: height > 0
                            clip: true
                            
                            RowLayout {
                                anchors.fill: parent
                                visible: !calendarRoot.editingLife
                                Text { text: "LIFE"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11; font.letterSpacing: 1 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                                    height: 4; radius: 2; color: "#22${c.base05}"
                                    Rectangle { width: parent.width * calendarRoot.lifeDone; height: parent.height; radius: parent.radius; color: "#${c.base08}" }
                                }
                                Text { text: calendarRoot.lifeDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 11 }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                visible: calendarRoot.editingLife
                                Text { text: "BORN"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11 }
                                
                                Rectangle {
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 18
                                    color: "#22${c.base05}"
                                    radius: 4
                                    
                                    TextInput { 
                                        id: birthInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: calendarRoot.birthYear > 0 ? calendarRoot.birthYear.toString() : ""
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        onAccepted: { calendarRoot.birthYear = parseInt(text); calendarRoot.editingLife = false; }
                                        onVisibleChanged: {
                                            if (visible) {
                                                forceActiveFocus();
                                                selectAll();
                                            }
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                    
                    Item { Layout.preferredHeight: 4 } // Spacer

                    // Weekdays Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Item { Layout.preferredWidth: 24; Layout.preferredHeight: 24 } // W gutter
                        
                        Repeater {
                            model: calendarRoot.weekdays
                            Text {
                                text: { var days = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]; return days[modelData]; }
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                    
                    // Calendar Grid
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Repeater {
                            model: calendarRoot.weeks
                            RowLayout {
                                property var weekData: modelData
                                spacing: 2
                                
                                Text {
                                    text: weekData.week
                                    color: "#${c.base03}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                Repeater {
                                    model: weekData.days
                                    Rectangle {
                                        property var dayData: modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 6
                                        color: "transparent"
                                        border.width: dayData.today ? 1 : 0
                                        border.color: "#${c.base0D}"
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: dayData.day
                                            color: dayData.inMonth ? (dayData.weekend ? "#${c.base04}" : "#${c.base05}") : "#${c.base03}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            font.bold: dayData.today
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (dayData.today) calendarRoot.goToToday();
                                            }
                                        }
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            color: parent.children[1].containsMouse ? "#1A${c.base0D}" : "transparent"
                                            radius: 6
                                            z: -1
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true } // Push everything up
                }
            }
        }
    }
  '';

  widget = ''
    Rectangle {
        id: clockWidgetContainer
        color: clockMouseArea.containsMouse ? "#${c.base03}" : (root.clockVisible ? "#${c.base02}" : "#${c.base01}")
        radius: 14 // Pill style
        Layout.preferredHeight: 28
        Layout.preferredWidth: clockLayout.implicitWidth + 24
        
        RowLayout {
            id: clockLayout
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                text: root.dndMode ? "󰂛" : (notificationModel.count > 0 ? "󰂚" : "󰂜")
                color: root.dndMode ? "#80${c.base05}" : (notificationModel.count > 0 ? "#${c.base0D}" : "#${c.base05}")
                font.family: "${fontName}"
                font.pixelSize: 14
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dndMode = !root.dndMode
                }
            }

            Text {
                id: clockText
                text: Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                color: "#${c.base05}"
                font.family: "${fontName}"
                font.pixelSize: 13
                font.bold: true
                
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                }
            }
        }

        MouseArea {
            id: clockMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clockVisible = !root.clockVisible
        }
    }
  '';
}
