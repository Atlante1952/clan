minetest.register_chatcommand("clan_delete", {
    params = "<clan name>",
    description = "Delete a clan",
    privs = {server = true},
    func = function(name, param)
        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. param .. ".txt"

        if param == "" then
            minetest.chat_send_player(name, minetest.colorize(clans.message_color, "[Server] -!- Incorrect syntax. Usage: /clan_delete <clan_name>"))
            return
        end

        local success, err = os.remove(file_path)
        if success then
            minetest.chat_send_all(minetest.colorize(clans.message_color, "[Server] -!- The clan '" .. param .. "' was successfully deleted. (By Admin)"))
        else
            minetest.chat_send_player(name, minetest.colorize(clans.message_color,"[Server] -!- Error deleting clan '" .. param .. "': " .. tostring(err)))
        end
    end,
})

minetest.register_chatcommand("clan_members", {
    description = "Affiche la liste des membres d'un clan spécifique",
    params = "<clan_name>",
    func = function(player_name, param)
        local clan_name = param
        if not clan_name then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Vous devez spécifier le nom du clan."))
            return
        end

        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. clan_name .. ".txt"
        local content = clans.read_file(file_path)

        if not content then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Le clan '" .. clan_name .. "' n'existe pas."))
            return
        end

        local members = {}
        for line in content:gmatch("[^\r\n]+") do
            local rank, name = line:match("(%w+):%s*(%S+)")
            if rank and name then
                table.insert(members, rank .. ": " .. name)
            end
        end

        if #members == 0 then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Le clan '" .. clan_name .. "' n'a pas de membres."))
            return
        end

        local message = minetest.colorize(clans.message_color, "Membres du clan '" .. clan_name .. "':\n") .. table.concat(members, "\n")
        minetest.chat_send_player(player_name, message)
    end
})

minetest.register_chatcommand("clan", {
    description = "Open Clan Interface",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            clans.show_clan_interface(player)
        end
    end,
})
