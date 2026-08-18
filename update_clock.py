import re

with open('/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/clock.nix', 'r') as f:
    content = f.read()

replacement = """                // Right side: Calendar (Omarchy style)
                ColumnLayout {
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
                            if (Model.keyForDate(date) === parent.todayKey) return;
                            var followToday = parent.viewingCurrentMonth;
                            parent.today = date;
                            if (followToday) parent.goToToday();
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
                            MouseArea { id: prevHover; anchors.fill: parent; hoverEnabled: true; onClicked: parent.parent.parent.moveMonth(-1) }
                        }

                        Text {
                            text: Qt.formatDate(parent.viewDate, "MMMM yyyy").toUpperCase()
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 15
                            font.bold: true
                            font.letterSpacing: 1
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: nextHover.containsMouse ? "#${c.base03}" : "transparent"
                            Text { anchors.centerIn: parent; text: "󰅂"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            MouseArea { id: nextHover; anchors.fill: parent; hoverEnabled: true; onClicked: parent.parent.parent.moveMonth(1) }
                        }
                    }

                    // Year progress
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        MouseArea {
                            Layout.fillWidth: true
                            height: 20
                            onDoubleClicked: parent.parent.editingLife = true
                            
                            RowLayout {
                                anchors.fill: parent
                                Text { text: parent.parent.parent.today.getFullYear(); color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11; font.letterSpacing: 1 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                                    height: 4; radius: 2; color: "#22${c.base05}"
                                    Rectangle { width: parent.width * parent.parent.parent.parent.yearDone; height: parent.height; radius: parent.radius; color: "#${c.base0D}" }
                                }
                                Text { text: parent.parent.parent.yearDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 11 }
                            }
                        }
                        
                        // Life progress
                        MouseArea {
                            Layout.fillWidth: true
                            height: parent.parent.editingLife || parent.parent.birthYear > 0 ? 20 : 0
                            visible: height > 0
                            clip: true
                            
                            RowLayout {
                                anchors.fill: parent
                                visible: !parent.parent.parent.editingLife
                                Text { text: "LIFE"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11; font.letterSpacing: 1 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                                    height: 4; radius: 2; color: "#22${c.base05}"
                                    Rectangle { width: parent.width * parent.parent.parent.parent.lifeDone; height: parent.height; radius: parent.radius; color: "#${c.base08}" }
                                }
                                Text { text: parent.parent.parent.lifeDonePercent + "%"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 11 }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                visible: parent.parent.parent.editingLife
                                Text { text: "BORN"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 11 }
                                TextInput { 
                                    id: birthInput
                                    text: parent.parent.parent.birthYear > 0 ? parent.parent.parent.birthYear.toString() : ""
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 40
                                    onAccepted: { parent.parent.parent.birthYear = parseInt(text); parent.parent.parent.editingLife = false; }
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
                            model: parent.parent.weekdays
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
                            model: parent.parent.weeks
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
                                                if (dayData.today) parent.parent.parent.parent.goToToday();
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
                }"""

# Use regex to replace everything between "// Right side: Calendar (Omarchy style)" and the end of that ColumnLayout
# Since QML is nested, finding the end of the ColumnLayout requires counting braces, or just replacing a known chunk.
# Let's replace from "// Right side: Calendar (Omarchy style)" to the line right before `            }` matching the RowLayout end.
pattern = re.compile(r'// Right side: Calendar \(Omarchy style\).*?Item \{ Layout\.fillHeight: true \}\s+\}\s+\}', re.DOTALL)
# Wait, the original code had:
#                 // Right side: Calendar (Omarchy style)
#                 ColumnLayout {
#                     ...
#                     // Calendar Grid Placeholder
#                     GridLayout { ... }
#                 }

start_idx = content.find('// Right side: Calendar (Omarchy style)')
if start_idx != -1:
    # Find the end of the ColumnLayout
    # Count braces
    open_braces = 0
    in_block = False
    end_idx = -1
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            open_braces += 1
            in_block = True
        elif content[i] == '}':
            open_braces -= 1
            if in_block and open_braces == 0:
                end_idx = i + 1
                break
    if end_idx != -1:
        new_content = content[:start_idx] + replacement + content[end_idx:]
        with open('/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/clock.nix', 'w') as f:
            f.write(new_content)
        print("Replaced successfully")
    else:
        print("Failed to find end of block")
else:
    print("Failed to find start string")
