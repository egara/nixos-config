--
-- Dynamic Omarchy Theme Menu for Elephant/Walker
--
Name = "sicosthemes"
NamePretty = "SicOS Themes"

-- Check if file exists using Lua (no subprocess)
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Get first matching file from directory using ls (single call for fallback)
local function first_image_in_dir(dir)
  local handle = io.popen("ls -1 '" .. dir .. "' 2>/dev/null | head -n 1")
  if handle then
    local file = handle:read("*l")
    handle:close()
    if file and file ~= "" then
      return dir .. "/" .. file
    end
  end
  return nil
end

-- The main function elephant will call
function GetEntries()
  local entries = {}
  local sicos_theme_dir = os.getenv("HOME") .. "/.config/sicos/themes"
  local omarchy_path = os.getenv("OMARCHY_PATH") or ""
  local default_theme_dir = os.getenv("HOME") .. "/.config/sicos/themes"

  local seen_themes = {}

  -- Helper function to process themes from a directory
  local function process_themes_from_dir(theme_dir)
    -- Single find call to get all theme directories
    local handle = io.popen("find -L '" .. theme_dir .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null")
    if not handle then
      return
    end

    for theme_path in handle:lines() do
      local theme_name = theme_path:match(".*/(.+)$")

      if theme_name and not seen_themes[theme_name] then
        seen_themes[theme_name] = true

        local base_name = theme_name
        local mode = "dark"
        local b, m = theme_name:match("^(.*)%-(dark)$")
        if not b then
            b, m = theme_name:match("^(.*)%-(light)$")
        end
        if b then
            base_name = b
            mode = m
        end

        -- Check for preview images directly (no subprocess)
        local preview_path = nil
        local preview_png = theme_path .. "/preview.png"
        local preview_jpg = theme_path .. "/preview.jpg"

        if file_exists(preview_png) then
          preview_path = preview_png
        elseif file_exists(preview_jpg) then
          preview_path = preview_jpg
        else
          -- Fallback: get first image from wallpapers (one ls call)
          preview_path = first_image_in_dir(theme_path .. "/wallpapers")
        end

        if preview_path and preview_path ~= "" then
          local display_name = base_name:gsub("_", " "):gsub("%-", " ")
          display_name = display_name:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
          end)
          display_name = display_name .. "  "

          table.insert(entries, {
            Text = display_name,
            Preview = preview_path,
            PreviewType = "file",
            Actions = {
              activate = "kitty --hold sh -c '~/.config/hypr/theme-switcher.sh " .. mode .. " " .. base_name .. "'",
              -- activate = "omarchy-theme-set " .. theme_name,
            },
          })
        end
      end
    end

    handle:close()
  end

  -- Process SicOS themes
  process_themes_from_dir(sicos_theme_dir)

  return entries
end
