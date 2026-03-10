#!/usr/bin/env bash

# SicOS Keybindings Hint (Clean, Aligned & Interactive)
# ------------------------------------------------------------------
# Display shortcuts elegantly and aligned, and execute the selected one.
# ------------------------------------------------------------------

# 1. Get all Hyprland binds
all_binds=$(hyprctl binds -j)

# 2. Generate the list with hidden metadata and column alignment
# Use \t as a temporary separator for the 'column' command
processed_list=$(echo "$all_binds" | jq -r '
  def get_mods(m):
    [
      (if (m / 64 % 2 >= 1) then "󰘳" else empty end),
      (if (m / 4 % 2 >= 1) then "Ctrl" else empty end),
      (if (m / 8 % 2 >= 1) then "Alt" else empty end),
      (if (m / 1 % 2 >= 1) then "Shift" else empty end)
    ];

  def get_group(desc; submap):
    if submap != "" then "󱗼 " + submap
    elif (desc | test("(?i)volume|brightness")) then "󰕾 Hardware"
    elif (desc | test("(?i)workspace|magic")) then "󱂬 Workspaces"
    elif (desc | test("(?i)window|focus|floating|pseudo|split")) then "󱂬 Windows"
    elif (desc | test("(?i)layout")) then "󰕰 Layouts"
    elif (desc | test("(?i)screenshot|color picker")) then "󰄄 Utils"
    elif (desc | test("(?i)terminal|file manager|editor|firefox|browser|gemini|lazyssh|launcher|sicos")) then "󰵆 Apps"
    else "󰘥 Misc" end;

  .[] | 
  select(.has_description and (.dispatcher | test("mouse") | not)) |
  get_mods(.modmask) as $mods |
  (if .key == "SUPER_L" or .key == "SUPER_R" then "󰘳" 
   elif .key == "" then "code:" + (.keycode | tostring) 
   else .key end) as $key |
  (if ($mods | contains([$key])) then $mods else $mods + [$key] end | join(" + ")) as $shortcut |
  get_group(.description; .submap) as $group |
  "\($group)\t\($shortcut)\t➜ \(.description)󰇘\(.dispatcher)󰇘\(.arg)"
' | column -t -s $'\t' -o '  │  ')

# 3. Create the "clean" list to show in the menu (removing metadata)
# sort -u to avoid duplicates if any
display_menu=$(echo "$processed_list" | sed 's/󰇘.*//' | sort -u)

# 4. Show the menu to the user
selected=$(echo "$display_menu" | walker --dmenu --placeholder "Search keyboard shortcuts..." --width 1000)

# 5. If the user selected something, find the corresponding command and execute it
if [ -n "$selected" ]; then
    # Search for the original line that starts exactly with the selection followed by the separator
    # Use grep -F to treat the text literally (due to special characters)
    match=$(echo "$processed_list" | grep -F "${selected}󰇘" | head -n 1)
    
    if [ -n "$match" ]; then
        # Extract the dispatcher and arguments using the hidden separator
        dispatcher=$(echo "$match" | awk -F'󰇘' '{print $2}')
        arg=$(echo "$match" | awk -F'󰇘' '{print $3}')
        
        hyprctl dispatch "$dispatcher" "$arg"
    fi
fi
