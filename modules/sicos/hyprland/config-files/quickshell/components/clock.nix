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
        implicitWidth: 720
        implicitHeight: 440
        color: "transparent"

        HyprlandFocusGrab {
            active: root.clockVisible
            windows: [clockPopup, root]
            onCleared: root.clockVisible = false
        }

        Item {
            id: popupContentClock
            width: parent.width
            height: parent.height

            opacity: root.clockVisible ? 1 : 0
            y: root.clockVisible ? 0 : -20

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            // The background color providing the pixels
            Rectangle {
                id: bgSourceClock
                anchors.fill: parent
                color: "#F0${c.base01}"
                visible: false
            }

            // The mask shape (Body + Beak)
            Item {
                id: bgMaskClock
                anchors.fill: parent
                visible: false

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 18 // 12 + 6px to match root.height anchor of others
                    radius: 16
                    color: "black"
                }

                Rectangle {
                    width: 20
                    height: 20
                    color: "black"
                    rotation: 45
                    y: 8 // 2 + 6px
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // The final masked background
            OpacityMask {
                anchors.fill: parent
                source: bgSourceClock
                maskSource: bgMaskClock
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 32 // 26 + 6px
                spacing: 16

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

                        // Clear all button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
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
                                onTapped: mainScope.clearNotifications()
                            }
                        }

                        // DND (Do Not Disturb) Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: dndHover.hovered ? "#${c.base03}" : (mainScope.dndMode ? "#20${c.base0D}" : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "󰂛"
                                color: mainScope.dndMode ? "#${c.base0D}" : "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            HoverHandler {
                                id: dndHover
                            }
                            TapHandler {
                                onTapped: mainScope.dndMode = !mainScope.dndMode
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
                                font.pixelSize: 44
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "You don't have notifications"
                                color: "#80${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 15
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
                            readonly property bool isExpanded: mainScope.expandedGroups[model.appName] === true
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

                                        var appNameLower = model.appName ? model.appName.toLowerCase().replace(/\s+/g, '-') : "";
                                        if (appNameLower && appNameLower !== "sistema") {
                                            return "image://icon/" + appNameLower;
                                        }

                                        var img = model.iconName.toString();
                                        if (img && img !== "") {
                                            if (img.startsWith("image://") || img.startsWith("file://")) return img;
                                            if (img.startsWith("/")) return "file://" + img;
                                            return "image://icon/" + img;
                                        }
                                        return "image://icon/dialog-information";
                                    }
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
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
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Group expand button
                                Rectangle {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 22
                                    radius: 9
                                    color: groupExpandHover.hovered ? "#33${c.base05}" : "transparent"
                                    visible: delegateRoot.hasMultiple

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅂"
                                        rotation: delegateRoot.isExpanded ? 180 : 0
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 15

                                        Behavior on rotation {
                                            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                                        }
                                    }

                                    HoverHandler {
                                        id: groupExpandHover
                                    }

                                    TapHandler {
                                        onTapped: {
                                            mainScope.toggleGroup(model.appName)
                                        }
                                    }
                                }

                                // Group close button
                                Rectangle {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 22
                                    radius: 9
                                    color: groupCloseHover.hovered ? "#${c.base08}" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: groupCloseHover.hovered ? "#${c.base00}" : "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 15
                                    }

                                    HoverHandler {
                                        id: groupCloseHover
                                    }

                                    TapHandler {
                                        onTapped: {
                                            mainScope.dismissNotificationGroup(model.appName)
                                        }
                                    }
                                }
                            }

                            // Notification Card
                            Item {
                                id: cardItem
                                property bool expanded: false
                                Layout.fillWidth: true
                                implicitHeight: cardContent.implicitHeight + 16

                                Rectangle {
                                    anchors.fill: parent
                                    color: notifMouseArea.containsMouse || expandMouseArea.containsMouse || closeMouseArea.containsMouse ? "#${c.base03}" : "#40${c.base02}"
                                    radius: 8
                                    border.color: "#33${c.base05}"
                                    border.width: 1
                                }

                                MouseArea {
                                    id: notifMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        mainScope.invokeDefaultAction(model.notifId);
                                    }
                                }

                                RowLayout {
                                    id: cardContent
                                    anchors.centerIn: parent
                                    width: delegateRoot.width - 20
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
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
                                                font.pixelSize: 15
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
                                                font.pixelSize: 12
                                                Layout.alignment: Qt.AlignTop
                                            }

                                            // Expand button
                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignTop
                                                radius: 6
                                                color: expandMouseArea.containsMouse ? "#33${c.base0D}" : "#1A${c.base0D}"
                                                border.color: expandMouseArea.containsMouse ? "#66${c.base0D}" : "#33${c.base0D}"
                                                border.width: 1
                                                visible: cardBodyText.truncated || cardItem.expanded

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cardItem.expanded ? "󰅃" : "󰅀"
                                                    color: "#${c.base0D}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 15
                                                }

                                                MouseArea {
                                                    id: expandMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: (mouse) => {
                                                        mouse.accepted = true;
                                                        cardItem.expanded = !cardItem.expanded;
                                                    }
                                                }
                                            }

                                            // Close button
                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignTop
                                                radius: 6
                                                color: closeMouseArea.containsMouse ? "#33${c.base08}" : "#1A${c.base08}"
                                                border.color: closeMouseArea.containsMouse ? "#66${c.base08}" : "#33${c.base08}"
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰅖"
                                                    color: "#${c.base08}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 15
                                                }

                                                MouseArea {
                                                    id: closeMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: (mouse) => {
                                                        mouse.accepted = true;
                                                        mainScope.forceDismissNotification(model.notifId, false);
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            id: cardBodyText
                                            text: model.body
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 14
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            maximumLineCount: cardItem.expanded ? 100 : 3
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
                            width: 24; height: 24; radius: 12
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
                                font.pixelSize: 16
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
                            width: 24; height: 24; radius: 12
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
                                Text { text: calendarRoot.today.getFullYear(); color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12; font.letterSpacing: 1 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6
                                    height: 4; radius: 2; color: "#22${c.base05}"
                                    Rectangle { width: parent.width * calendarRoot.yearDone; height: parent.height; radius: parent.radius; color: "#${c.base0D}" }
                                }
                                Text { text: calendarRoot.yearDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12 }
                            }
                        }

                        // Life progress
                        Item {
                            Layout.fillWidth: true
                            height: calendarRoot.editingLife || calendarRoot.birthYear > 0 ? 20 : 0
                            visible: height > 0
                            clip: true

                            MouseArea {
                                anchors.fill: parent
                                visible: !calendarRoot.editingLife
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarRoot.editingLife = true
                                onDoubleClicked: calendarRoot.editingLife = true

                                RowLayout {
                                    anchors.fill: parent
                                    Text { text: "LIFE"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12; font.letterSpacing: 1 }
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6
                                        height: 4; radius: 2; color: "#22${c.base05}"
                                        Rectangle { width: parent.width * calendarRoot.lifeDone; height: parent.height; radius: parent.radius; color: "#${c.base08}" }
                                    }
                                    Text { text: calendarRoot.lifeDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                visible: calendarRoot.editingLife
                                Text { text: "BORN"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 18
                                    color: "#22${c.base05}"
                                    radius: 4

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: birthInput.forceActiveFocus()
                                    }

                                    TextInput {
                                        id: birthInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: calendarRoot.birthYear > 0 ? calendarRoot.birthYear.toString() : ""
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                        selectByMouse: true
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

                        Item { Layout.preferredWidth: 22; Layout.preferredHeight: 22 } // W gutter

                        Repeater {
                            model: calendarRoot.weekdays
                            Text {
                                text: { var days = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]; return days[modelData]; }
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 12
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
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 22
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Repeater {
                                    model: weekData.days
                                    Rectangle {
                                        property var dayData: modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 6
                                        color: "transparent"
                                        border.width: dayData.today ? 1 : 0
                                        border.color: "#${c.base0D}"

                                        Text {
                                            anchors.centerIn: parent
                                            text: dayData.day
                                            color: dayData.inMonth ? (dayData.weekend ? "#${c.base04}" : "#${c.base05}") : "#${c.base03}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 14
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

            // Hover tracker using HoverHandler (Qt 6)
            HoverHandler {
                id: popupHoverClock
                onHoveredChanged: {
                    if (hovered) {
                        root.clockHovering = true;
                        clockCloseTimer.stop();
                    } else {
                        root.clockHovering = false;
                        clockCloseTimer.start();
                    }
                }
            }

            Timer {
                id: clockCloseTimer
                interval: 400
                repeat: false
                onTriggered: if (!root.clockHovering) root.clockVisible = false
            }
        }
    }
  '';

  widget = ''
    Rectangle {
        id: clockWidgetContainer
        color: hoverClock.hovered ? "#${c.base03}" : (root.clockVisible ? "#E6${c.base02}" : "#CC${c.base01}")
        radius: 12 // Pill style
        Layout.preferredHeight: 32
        Layout.preferredWidth: clockLayout.implicitWidth + 20

        RowLayout {
            id: clockLayout
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: bellMouseArea.containsMouse ? "#44${c.base05}" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: mainScope.dndMode ? "󰂛" : (notificationModel.count > 0 ? "󰂚" : "󰂜")
                    color: mainScope.dndMode ? "#80${c.base05}" : (notificationModel.count > 0 ? "#${c.base0D}" : "#${c.base05}")
                    font.family: "${fontName}"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: bellMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        mainScope.dndMode = !mainScope.dndMode
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 16
                radius: 1
                color: "#33${c.base05}"
                Layout.leftMargin: 0
                Layout.rightMargin: 4
            }

            Text {
                id: clockText
                text: Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                color: "#${c.base05}"
                font.family: "${fontName}"
                font.pixelSize: 14
                font.bold: true

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm")
                }
            }
        }

        // Hover tracker using HoverHandler (Qt 6)
        HoverHandler {
            id: hoverClock
            onHoveredChanged: {
                if (hovered) {
                    root.clockHovering = true;
                    clockCloseTimerWidget.stop();
                    clockOpenTimer.start();
                } else {
                    root.clockHovering = false;
                    clockOpenTimer.stop();
                    clockCloseTimerWidget.start();
                }
            }
        }

        Timer {
            id: clockOpenTimer
            interval: 200
            repeat: false
            onTriggered: root.clockVisible = true
        }

        Timer {
            id: clockCloseTimerWidget
            interval: 400
            repeat: false
            onTriggered: if (!root.clockHovering) root.clockVisible = false
        }
    }
  '';
}
