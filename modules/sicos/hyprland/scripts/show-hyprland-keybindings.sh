#!/usr/bin/env bash

# SicOS Keybindings Hint (Clean, Aligned & Interactive)
# ------------------------------------------------------------------
# Muestra los atajos de forma elegante y alineada, y ejecuta el seleccionado.
# ------------------------------------------------------------------

# 1. Obtener todos los binds de Hyprland
all_binds=$(hyprctl binds -j)

# 2. Generar la lista con metadatos ocultos y alineación por columnas
# Usamos \t como separador temporal para el comando 'column'
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
  "\($group)\t│  \($shortcut)\t➜  \(.description)󰇘\(.dispatcher)󰇘\(.arg)"
' | column -t -s $'\t')

# 3. Crear la lista "limpia" para mostrar en el menú (quitando los metadatos)
# sort -u para evitar duplicados si los hubiera
display_menu=$(echo "$processed_list" | sed 's/󰇘.*//' | sort -u)

# 4. Mostrar el menú al usuario
selected=$(echo "$display_menu" | walker --dmenu --placeholder "Buscar atajos de teclado...")

# 5. Si el usuario seleccionó algo, buscar el comando correspondiente y ejecutarlo
if [ -n "$selected" ]; then
    # Buscamos la línea original que empieza exactamente por lo seleccionado seguido del separador
    # Usamos grep -F para tratar el texto de forma literal (por los caracteres especiales)
    match=$(echo "$processed_list" | grep -F "${selected}󰇘" | head -n 1)
    
    if [ -n "$match" ]; then
        # Extraer el dispatcher y los argumentos usando el separador oculto
        dispatcher=$(echo "$match" | awk -F'󰇘' '{print $2}')
        arg=$(echo "$match" | awk -F'󰇘' '{print $3}')
        
        hyprctl dispatch "$dispatcher" "$arg"
    fi
fi
