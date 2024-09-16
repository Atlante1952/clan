
if minetest.get_modpath("unified_inventory") then
    unified_inventory.register_button("open_clan_button", {
        type = "image",
        image = "5790555.png",
        tooltip = "Open Clan Interface",
        action = function(player)
            clans.show_clan_interface(player)
        end,
    })
end