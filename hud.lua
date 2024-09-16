minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    clans.hud_id[player_name] = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.8, y = 0.05},
        text = "",
        number = 0xaac729,
        alignment = {x = 1, y = 1},
        offset = {x = -10, y = -10},
        size = {x = 1},
    })
end)
