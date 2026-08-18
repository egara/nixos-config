import re

with open('/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/clock.nix', 'r') as f:
    content = f.read()

# I will replace all instances of parent.parent.parent... with calendarRoot
# First, give the ColumnLayout an id

new_content = content.replace('// Right side: Calendar (Omarchy style)\n                ColumnLayout {', '// Right side: Calendar (Omarchy style)\n                ColumnLayout {\n                    id: calendarRoot')

# Now replace all parent.parent.parent... stuff in the calendar block
new_content = re.sub(r'parent(\.parent)+\.today', 'calendarRoot.today', new_content)
new_content = re.sub(r'parent(\.parent)+\.view', 'calendarRoot.view', new_content)
new_content = re.sub(r'parent(\.parent)+\.year', 'calendarRoot.year', new_content)
new_content = re.sub(r'parent(\.parent)+\.life', 'calendarRoot.life', new_content)
new_content = re.sub(r'parent(\.parent)+\.birth', 'calendarRoot.birth', new_content)
new_content = re.sub(r'parent(\.parent)+\.week', 'calendarRoot.week', new_content)
new_content = re.sub(r'parent(\.parent)+\.editingLife', 'calendarRoot.editingLife', new_content)
new_content = re.sub(r'parent(\.parent)+\.goToToday', 'calendarRoot.goToToday', new_content)
new_content = re.sub(r'parent(\.parent)+\.moveMonth', 'calendarRoot.moveMonth', new_content)
new_content = re.sub(r'parent(\.parent)+\.todayKey', 'calendarRoot.todayKey', new_content)
new_content = re.sub(r'parent\.todayKey', 'calendarRoot.todayKey', new_content)
new_content = re.sub(r'parent\.today', 'calendarRoot.today', new_content)
new_content = re.sub(r'parent\.viewingCurrentMonth', 'calendarRoot.viewingCurrentMonth', new_content)
new_content = re.sub(r'parent\.goToToday', 'calendarRoot.goToToday', new_content)
new_content = re.sub(r'parent\.viewDate', 'calendarRoot.viewDate', new_content)

# Fix some specifics:
# The SystemClock onDateChanged uses parent.todayKey etc. I already replaced parent.todayKey.
# Wait, parent.viewDate -> calendarRoot.viewDate

with open('/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/clock.nix', 'w') as f:
    f.write(new_content)

print("Done")
