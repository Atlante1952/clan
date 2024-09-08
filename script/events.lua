minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local player_name = player:get_player_name()
        local player_clan, _ = clans.get_player_clan(player)
        local members, _ = clans.get_clan_info(player_clan)
        local member_count = #members
        local hud_text = "Your actual clan : " .. player_clan .. " \nCurrent number of members: " .. member_count
        if clans.hud_id[player_name] then
            player:hud_change(clans.hud_id[player_name], "text", hud_text)
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    clans.handle_invitation_button(player, formname, fields)
    clans.handle_join_clan_button(player, formname, fields)
    clans.handle_tabheader(player, formname, fields)
    clans.handle_create_clan_button(player, formname, fields)
    clans.handle_delete_clan_button(player, formname, fields)
    clans.handle_rename_clan_button(player, formname, fields)
    clans.handle_leave_button(player, formname, fields)
    clans.handle_clan_interface(player, formname, fields)
    clans.handle_invitation(player, formname, fields)
end)


function clans.handle_tabheader(player, formname, fields)
    if formname == "clan_interface" then
        if fields.clan_tab == "2" then
            clans.show_invitation_interface(player)
        end
    elseif formname == "invitation_interface" then
        if fields.clan_tab == "1" then
            clans.show_clan_interface(player)
        end
    end
end
