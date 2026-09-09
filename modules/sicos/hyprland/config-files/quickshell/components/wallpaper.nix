{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: wallpaperPopup
        anchor.window: root
        anchor.rect.x: root.width - 10
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        visible: root.wallpaperVisible || popupContentWallpaper.opacity > 0
        implicitWidth: 640
        implicitHeight: 700
        color: "transparent"

        HyprlandFocusGrab {
            active: root.wallpaperVisible
            windows: [wallpaperPopup, root]
            onCleared: root.wallpaperVisible = false
        }

        Item {
            id: popupContentWallpaper
            width: parent.width
            height: parent.height

            opacity: root.wallpaperVisible ? 1 : 0
            y: root.wallpaperVisible ? 0 : -20

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            // State & Data properties
            property var allItems: []
            property var filteredItems: []
            property var folderList: ["All"]
            property string activeFolder: "All"
            property string currentWallpaperPath: ""
            property string wallpapersDirPath: "~/.config/sicos/wallpapers"
            property string searchText: ""
            property bool isScanning: false

            function filterItems() {
                var res = [];
                var q = searchText.trim().toLowerCase();
                for (var i = 0; i < allItems.length; i++) {
                    var it = allItems[i];
                    if (activeFolder !== "All" && it.folder !== activeFolder) continue;
                    if (q !== "" && it.name.toLowerCase().indexOf(q) === -1) continue;
                    res.push(it);
                }
                filteredItems = res;
            }

            function setWallpaper(filePath) {
                currentWallpaperPath = filePath;
                wallpaperSetProc.command = ["python3", "/home/egarcia/.config/sicos/scripts/sicos-wallpapers.py", "--set", filePath];
                wallpaperSetProc.running = true;
            }

            function setRandom() {
                wallpaperRandomProc.running = true;
            }

            function refreshList() {
                isScanning = true;
                wallpaperListProc.running = true;
            }

            // Commands and Processes
            Process {
                id: wallpaperSetProc
                running: false
                onExited: {
                    // Update current wallpaper state
                }
            }

            Process {
                id: wallpaperRandomProc
                command: ["python3", "/home/egarcia/.config/sicos/scripts/sicos-wallpapers.py", "--random"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() !== "") {
                            popupContentWallpaper.currentWallpaperPath = text.trim();
                        }
                    }
                }
            }

            // Thumbnail Generator (background helper for missing thumbnails)
            Process {
                id: thumbGenProc
                running: false
            }

            // Batch Thumbnail Generator Process
            Process {
                id: batchThumbGenProc
                command: ["python3", "/home/egarcia/.config/sicos/scripts/sicos-wallpapers.py", "--gen-thumbs"]
                running: false
                onExited: {
                    // Refresh wallpaper list to pick up generated thumbnails
                    wallpaperListProc.running = true;
                }
            }

            Timer {
                id: batchThumbsTimer
                interval: 1500
                repeat: false
                onTriggered: {
                    if (!batchThumbGenProc.running) {
                        batchThumbGenProc.running = true;
                    }
                }
            }

            Process {
                id: wallpaperListProc
                command: ["python3", "/home/egarcia/.config/sicos/scripts/sicos-wallpapers.py", "--list"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                var data = JSON.parse(text);
                                popupContentWallpaper.wallpapersDirPath = data.wallpapersDir || "~/.config/sicos/wallpapers";
                                popupContentWallpaper.currentWallpaperPath = data.current || "";
                                popupContentWallpaper.folderList = data.folders || ["All"];
                                popupContentWallpaper.allItems = data.items || [];
                                popupContentWallpaper.filterItems();
                                batchThumbsTimer.restart();
                            } catch (e) {
                                console.log("Error parsing wallpaper list JSON:", e);
                            }
                            popupContentWallpaper.isScanning = false;
                        }
                    }
                }
            }

            // Background source
            Rectangle {
                id: bgSourceWallpaper
                anchors.fill: parent
                color: "#F0${c.base01}"
                visible: false
            }

            // Ambient Background Mask (Body + Beak)
            Item {
                id: bgMaskWallpaper
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
                    y: 12 - 10
                    x: {
                        if (root.wallpaperButtonX > 0) {
                            let popupLeftEdge = (root.width - 10) - wallpaperPopup.implicitWidth;
                            let calculatedX = root.wallpaperButtonX - popupLeftEdge - (width / 2);
                            return Math.max(20, Math.min(wallpaperPopup.implicitWidth - 40, calculatedX));
                        }
                        return parent.width - 160;
                    }
                }
            }

            // The final masked background
            OpacityMask {
                anchors.fill: parent
                source: bgSourceWallpaper
                maskSource: bgMaskWallpaper
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                anchors.topMargin: 26
                spacing: 12

                // Header Row: Title vertically centered, action buttons at right
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Wallpaper Gallery"
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 18
                        }
                        Text {
                            text: popupContentWallpaper.filteredItems.length + " wallpapers available"
                            color: "#${c.base04}"
                            font.family: "${fontName}"
                            font.pixelSize: 13
                        }
                    }

                    // Spacer to push action buttons to the right
                    Item {
                        Layout.fillWidth: true
                    }

                    // Random Wallpaper Button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: randArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 17
                        }
                        MouseArea {
                            id: randArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupContentWallpaper.setRandom()
                        }
                    }

                    // Rescan / Refresh Button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: rescanArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: popupContentWallpaper.isScanning ? "#${c.base0A}" : "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 17
                        }
                        MouseArea {
                            id: rescanArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupContentWallpaper.refreshList()
                        }
                    }
                }

                // Info Banner: Directory Path
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: "#${c.base02}"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: ""
                            color: "#${c.base0D}"
                            font.family: "${fontName}"
                            font.pixelSize: 16
                        }

                        Text {
                            text: popupContentWallpaper.wallpapersDirPath
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }

                        // Open folder in Nautilus button
                        Rectangle {
                            width: 30; height: 30; radius: 6
                            color: openFolderArea.containsMouse ? "#33${c.base0D}" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: openFolderArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cmdRunner.exec(["nautilus", popupContentWallpaper.wallpapersDirPath]);
                                    root.wallpaperVisible = false;
                                }
                            }
                        }
                    }
                }

                // Search & Filter Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Search input
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: "#${c.base02}"
                        border.color: searchInput.activeFocus ? "#${c.base0D}" : "#${c.base03}"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: ""
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 15
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                clip: true
                                selectByMouse: true
                                focus: true
                                onTextChanged: {
                                    popupContentWallpaper.searchText = text;
                                    popupContentWallpaper.filterItems();
                                }

                                Text {
                                    text: "Search wallpaper..."
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 14
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }
                            }

                            // Clear button
                            Text {
                                text: "✕"
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                visible: searchInput.text !== ""
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = "";
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                // Folder category chips (horizontal scroll)
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    contentWidth: folderRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: folderRow
                        spacing: 6

                        Repeater {
                            model: popupContentWallpaper.folderList
                            delegate: Rectangle {
                                height: 28
                                width: chipText.implicitWidth + 18
                                radius: 14
                                color: popupContentWallpaper.activeFolder === modelData ? "#${c.base0D}" : (chipArea.containsMouse ? "#${c.base03}" : "#${c.base02}")

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: popupContentWallpaper.activeFolder === modelData ? "#${c.base00}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 13
                                    font.bold: popupContentWallpaper.activeFolder === modelData
                                }

                                MouseArea {
                                    id: chipArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        popupContentWallpaper.activeFolder = modelData;
                                        popupContentWallpaper.filterItems();
                                    }
                                }
                            }
                        }
                    }
                }

                // Wallpaper Grid View
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: wallpaperGrid
                        anchors.fill: parent
                        clip: true
                        cellWidth: Math.floor((width - 16) / 3)
                        cellHeight: Math.round(((width - 16) / 3) * 0.65)
                        boundsBehavior: Flickable.StopAtBounds
                        model: popupContentWallpaper.filteredItems

                        ScrollBar.vertical: ScrollBar {
                            id: scrollBar
                            policy: ScrollBar.AlwaysOn
                            interactive: true
                            width: 14
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right

                            background: Rectangle {
                                implicitWidth: 14
                                radius: 7
                                color: "#33${c.base02}"
                            }

                            contentItem: Rectangle {
                                implicitWidth: 10
                                radius: 5
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: scrollBar.pressed ? "#${c.base0D}" : (scrollBar.hovered ? "#CC${c.base0D}" : "#80${c.base04}")
                            }
                        }

                        delegate: Item {
                            id: cardDelegate
                            width: wallpaperGrid.cellWidth
                            height: wallpaperGrid.cellHeight
                            z: isHoveredZoomed ? 100 : 1

                            property bool isHoveredZoomed: false

                            Timer {
                                id: hoverZoomTimer
                                interval: 250
                                repeat: false
                                onTriggered: {
                                    if (cellMouse.containsMouse) {
                                        cardDelegate.isHoveredZoomed = true;
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 8
                                color: "#${c.base02}"
                                border.color: modelData.isCurrent || modelData.path === popupContentWallpaper.currentWallpaperPath ? "#${c.base0B}" : (cellMouse.containsMouse ? "#${c.base0D}" : "#33${c.base03}")
                                border.width: modelData.isCurrent || modelData.path === popupContentWallpaper.currentWallpaperPath ? 2 : (cellMouse.containsMouse ? 2 : 1)
                                clip: true
                                scale: cardDelegate.isHoveredZoomed ? 1.14 : 1.0

                                Behavior on scale {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + (modelData.thumb || modelData.path)
                                    sourceSize.width: 320
                                    sourceSize.height: 180
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                // Dark gradient at bottom for text
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 24
                                    color: cellMouse.containsMouse ? "#E6${c.base00}" : "#B3${c.base00}"

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        text: modelData.name
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                // Active Checkmark Badge
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "#${c.base0B}"
                                    visible: modelData.isCurrent || modelData.path === popupContentWallpaper.currentWallpaperPath

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#${c.base00}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        hoverZoomTimer.start();
                                    }
                                    onExited: {
                                        hoverZoomTimer.stop();
                                        cardDelegate.isHoveredZoomed = false;
                                    }
                                    onClicked: {
                                        popupContentWallpaper.setWallpaper(modelData.path);
                                    }
                                }
                            }
                        }
                    }

                    // Empty state indicator
                    Text {
                        anchors.centerIn: parent
                        visible: popupContentWallpaper.filteredItems.length === 0 && !popupContentWallpaper.isScanning
                        text: "No wallpapers found"
                        color: "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 14
                    }
                }
            }

            // Hover tracker using HoverHandler (Qt 6)
            HoverHandler {
                id: popupHoverWallpaper
                onHoveredChanged: {
                    if (hovered) {
                        root.wallpaperHovering = true;
                        wallpaperCloseTimer.stop();
                    } else {
                        root.wallpaperHovering = false;
                        wallpaperCloseTimer.start();
                    }
                }
            }

            Timer {
                id: wallpaperCloseTimer
                interval: 400
                repeat: false
                onTriggered: if (!root.wallpaperHovering && !searchInput.activeFocus) root.wallpaperVisible = false
            }
        }
    }
  '';

  widget = ''
    Rectangle {
        id: wallpaperButton
        Layout.preferredWidth: 36
        Layout.preferredHeight: 32
        radius: 12
        color: hoverWallpaper.hovered ? "#${c.base03}" : (root.wallpaperVisible ? "#E6${c.base02}" : "#CC${c.base01}")

        Text {
            anchors.centerIn: parent
            text: "󰋩"
            color: root.wallpaperVisible ? "#${c.base0D}" : "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 18
        }

        // Hover tracker using HoverHandler (Qt 6)
        HoverHandler {
            id: hoverWallpaper
            onHoveredChanged: {
                if (hovered) {
                    root.wallpaperHovering = true;
                    wallpaperCloseTimerWidget.stop();
                    wallpaperOpenTimer.start();
                } else {
                    root.wallpaperHovering = false;
                    wallpaperOpenTimer.stop();
                    wallpaperCloseTimerWidget.start();
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    // Set random wallpaper on middle click
                    cmdRunner.exec(["python3", "/home/egarcia/.config/sicos/scripts/sicos-wallpapers.py", "--random"]);
                } else {
                    root.wallpaperButtonX = wallpaperButton.mapToItem(null, wallpaperButton.width / 2, 0).x;
                    root.wallpaperVisible = !root.wallpaperVisible;
                    if (root.wallpaperVisible) {
                        popupContentWallpaper.refreshList();
                    }
                }
            }
        }

        Timer {
            id: wallpaperOpenTimer
            interval: 200
            repeat: false
            onTriggered: {
                root.wallpaperButtonX = wallpaperButton.mapToItem(null, wallpaperButton.width / 2, 0).x;
                root.wallpaperVisible = true;
                popupContentWallpaper.refreshList();
            }
        }

        Timer {
            id: wallpaperCloseTimerWidget
            interval: 400
            repeat: false
            onTriggered: if (!root.wallpaperHovering && !searchInput.activeFocus) root.wallpaperVisible = false
        }
    }
  '';
}
