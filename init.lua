clans = {}
clans.modpath = minetest.get_modpath("clan")
clans.max_number_characters = 10
clans.min_number_characters = 2
clans.message_color = "#aac729"
clans.hud_id = {}


function clans.load_file(path)
    local status, err = pcall(dofile, path)
    if not status then
        minetest.log("error", "-!- Failed to load file: " .. path .. " - Error: " .. err)
    else
        minetest.log("action", "-!- Successfully loaded file: " .. path)
    end
end

if clans.modpath then
    local files_to_load = {
        "script/api.lua",
        "script/events.lua",
        "script/commands.lua",
        "script/hud.lua",
        "script/interface.lua",
        "script/unified_inventory.lua",
    }
    for _, file in ipairs(files_to_load) do
        clans.load_file(clans.modpath .. "/" .. file)
    end
else
    minetest.log("error", "-!- Files in clan mod are not set or valid.")
end
