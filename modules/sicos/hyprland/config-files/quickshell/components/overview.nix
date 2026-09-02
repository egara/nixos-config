{ config, lib, pkgs, c, fontName }:
''
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: overviewWindow
            required property var modelData
            screen: modelData
            
            // Mantenemos la ventana visible mientras la opacidad del modal sea mayor a 0 para ver la animación de salida
            visible: overviewActive || (modalCard.opacity > 0)
            
            property int draggingTargetWorkspace: -1
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "sicos:workspace-overview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            
            Rectangle {
                id: bgRect
                anchors.fill: parent
                color: "transparent" // Totalmente transparente a petición
                opacity: overviewActive ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: overviewActive = false
                }
            } // Cerramos bgRect aquí para que modalCard sea hermano
            
            // Panel flotante Premium
            Rectangle {
                id: modalCard
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Animación de entrada estilo sicos-bar (Drop-down)
                y: overviewActive ? 70 : 50
                Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                
                opacity: overviewActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                
                // Calculamos el tamaño para 5 columnas y 2 filas con márgenes
                width: flowLayout.width + 64
                height: flowLayout.height + 64
                
                radius: 28
                color: "#E6${c.base00}" // 90% opacidad del color de fondo
                border.color: "#33${c.base05}"
                border.width: 1
                    
                    // Workspaces Grid
                    Flow {
                        id: flowLayout
                        anchors.centerIn: parent
                        width: (280 * 5) + (24 * 4) // 5 columnas
                        height: (175 * 2) + (24 * 1) // 2 filas
                        spacing: 24
                        
                        Repeater {
                            model: 10 // Mostrar siempre del 1 al 10
                            
                            Rectangle {
                                id: wsRect
                                
                                property int wsId: index + 1
                                property var hyprWs: {
                                    var wss = [];
                                    if (Hyprland.workspaces !== undefined) {
                                        wss = Array.from(Hyprland.workspaces.values);
                                    }
                                    for (var i = 0; i < wss.length; i++) {
                                        if (wss[i].id === wsId) return wss[i];
                                    }
                                    return null;
                                }
                                
                                width: 280
                                height: 175
                                radius: 16
                                color: "#33${c.base01}"
                                border.color: (Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === wsId) ? "#${c.base0D}" : "#44${c.base05}"
                                border.width: (Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === wsId) ? 2 : 1
                                
                                // Workspace Label Background
                                Text {
                                    text: hyprWs ? hyprWs.name : wsId.toString()
                                    color: "#${c.base05}"
                                    font.pixelSize: 80
                                    font.family: "${fontName}"
                                    font.bold: true
                                    anchors.centerIn: parent
                                    opacity: 0.25
                                    z: 10 // Poner encima de las ventanas para que se vea
                                }
                                
                                // Drag and Drop support
                                DropArea {
                                    anchors.fill: parent
                                    onEntered: {
                                        overviewWindow.draggingTargetWorkspace = wsRect.wsId;
                                    }
                                    onExited: {
                                        if (overviewWindow.draggingTargetWorkspace === wsRect.wsId) {
                                            overviewWindow.draggingTargetWorkspace = -1;
                                        }
                                    }
                                }
                                
                                // Windows in this workspace
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    
                                    Repeater {
                                        model: {
                                            var wins = [];
                                            if (Hyprland.toplevels === undefined) return wins;
                                            var toplevels = Array.from(Hyprland.toplevels.values);
                                            for (var i = 0; i < toplevels.length; i++) {
                                                var w = toplevels[i];
                                                if (w && w.workspace && w.workspace.id === wsRect.wsId) {
                                                    wins.push(w);
                                                }
                                            }
                                            return wins;
                                        }
                                        
                                        Item {
                                            id: winItem
                                            required property var modelData
                                            
                                            property var geom: (modelData && modelData.lastIpcObject && modelData.lastIpcObject.size) ? modelData.lastIpcObject.size : [800, 600]
                                            property var pos: (modelData && modelData.lastIpcObject && modelData.lastIpcObject.at) ? modelData.lastIpcObject.at : [0, 0]
                                            property real scaleFactor: (280 - 24) / 1920 
                                        
                                        property real originalX: (pos[0] % 1920) * scaleFactor
                                        property real originalY: (pos[1] % 1080) * scaleFactor
                                        
                                        x: originalX
                                        y: originalY
                                        width: geom[0] * scaleFactor
                                        height: geom[1] * scaleFactor
                                        
                                        Drag.active: winMouse.drag.active
                                        Drag.source: winItem
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        Rectangle {
                                            id: winRect
                                            anchors.fill: parent
                                            color: "transparent"
                                            radius: 6
                                            border.color: winMouse.containsMouse ? "#${c.base0D}" : "#${c.base05}"
                                            border.width: winMouse.containsMouse ? 2 : 1
                                            clip: true
                                            
                                            // The actual window clone
                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: overviewActive ? modelData.wayland : null
                                                live: true
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: winMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.OpenHandCursor
                                            
                                            drag.target: winItem
                                            drag.axis: Drag.XAndYAxis
                                            
                                            onPressed: {
                                                cursorShape = Qt.ClosedHandCursor
                                                wsRect.z = 100
                                                winItem.z = 100
                                            }
                                            
                                            onReleased: {
                                                cursorShape = Qt.OpenHandCursor
                                                wsRect.z = 0
                                                winItem.z = 0
                                                winItem.Drag.drop()
                                                
                                                var targetWs = overviewWindow.draggingTargetWorkspace;
                                                if (targetWs !== -1 && targetWs !== wsRect.wsId) {
                                                    var addrFormatted = "0x" + modelData.address.replace("0x", "");
                                                    Hyprland.dispatch("hl.dsp.window.move({ workspace = " + targetWs + ", window = 'address:" + addrFormatted + "', follow = false })");
                                                }
                                                
                                                // Always snap back
                                                winItem.x = Qt.binding(function() { return winItem.originalX })
                                                winItem.y = Qt.binding(function() { return winItem.originalY })
                                                overviewWindow.draggingTargetWorkspace = -1;
                                            }
                                            
                                            onClicked: {
                                                var addrFormatted = "0x" + modelData.address.replace("0x", "");
                                                Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + addrFormatted + "' })");
                                                overviewActive = false
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Make clicking empty space switch to that workspace
                            MouseArea {
                                anchors.fill: parent
                                z: -1 // Behind windows
                                onClicked: {
                                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRect.wsId + " })");
                                    overviewActive = false
                                }
                            }
                        }
                    }
                }
            }
            
            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: visible
                
                Keys.onEscapePressed: event => {
                    overviewActive = false
                    event.accepted = true
                }
            }
            
            onVisibleChanged: {
                if (visible) {
                    focusScope.forceActiveFocus()
                }
            }
        }
    }
''
