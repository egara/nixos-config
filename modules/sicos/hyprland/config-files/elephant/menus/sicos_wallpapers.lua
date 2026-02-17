--
-- Dynamic SicOS Wallpaper Menu for Elephant/Walker
--
Name = "sicoswallpapers"
NamePretty = "SicOS Wallpapers"

-- The main function elephant will call
function GetEntries()
  local entries = {}
  local sicos_wallpaper_dir = os.getenv("HOME") .. "/.config/sicos/wallpapers"

  -- Helper function to process wallpapers from a directory
  local function process_wallpapers_from_dir(dir)
    -- Find all image files recursively
    -- -L follows symlinks
    local cmd = "find -L '" .. dir .. "' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null"
    local handle = io.popen(cmd)

    if not handle then
      return
    end

    for file_path in handle:lines() do
      local file_name = file_path:match(".*/(.+)$")

      if file_name then
        table.insert(entries, {
          Text = file_name,
          Preview = file_path,
          PreviewType = "file",
          Actions = {
            activate = "swww img --transition-type grow --transition-pos 0,0 --transition-step 90 " .. file_path,
          },
        })
      end
    end

    handle:close()
  end

  process_wallpapers_from_dir(sicos_wallpaper_dir)

  return entries
end
