function clans.show_clan_interface(player)
    local player_clan, is_leader = clans.get_player_clan(player)
    local members, clan_info = clans.get_clan_info(player_clan)
    local all_clans = clans.get_all_clans()
    local clan_list_text = clans.generate_clan_list_text(all_clans)
    local total_clans_count = clans.get_total_clans_count()

    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]" ..
        "box[-0.1,3.75;8,0.7;black]" ..
        "box[-0.1,7.55;8,0.7;black]" ..
        "box[-0.1,-0.1;8,9.4;#030303]" ..
        "field[6.4,0.15;2,1;clan_name;;]" ..
        "field[6,6.25;2,1;clan_kick_playername;;]" ..
        "textlist[0,4.75;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
        "button[3.95,5.95;1.75,1;kick;kick]" ..
        "button[3.545,-0.175;1.5,1;rename;Rename]" ..
        "button[4.825,-0.175;1.5,1;create;Create]" ..
        "button[0,8.35;2,1;leave_clan;Leave the clan]" ..
        "style[delete;bgcolor=#202c37]" ..
        "button[6,8.35;2,1;delete;Delete Clan]" ..
        "label[0,0;#Clan : " .. minetest.colorize("#FF0000", player_clan) .. "]" ..
        "label[0,3.9;#Members of : " .. minetest.colorize("#FF0000", player_clan) .. " (" .. #members .. " Members)]" ..
        "label[0,7.7;#Personal :" .. minetest.colorize("#FF0000", " About You") .. "]" ..
        "label[0,0.6;List of all clans (" .. total_clans_count .. " Clans)]" ..
        "textlist[0,1;3.5,2.5;all_clans;" .. clan_list_text .. "]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation, Discussion;1]"
    minetest.show_formspec(player:get_player_name(), "clan_interface", formspec)
end

function clans.show_invitation_interface(player)
    local player_clan, is_leader = clans.get_player_clan(player)
    local members, clan_info = clans.get_clan_info(player_clan)
    local all_clans = clans.get_all_clans()
    local player_name = player:get_player_name()
    local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
    local invited_clans = {}

    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
            if invited_player == player_name then
                table.insert(invited_clans, clan_name)
            end
        end
        file:close()
    end

    local clan_list_text = clans.generate_clan_list_text(all_clans)
    local invitations_count = #invited_clans

    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]" ..
        "box[-0.1,3.75;8,0.7;black]" ..
        "box[-0.1,-0.1;8,9.4;#030303]" ..
        "textarea[0.35,1;3.5,2;invit_msg;;]" ..
        "label[0,0;#Clan : " .. minetest.colorize("#FF0000", player_clan) .. "]" ..
        "label[0,0.65;Invitation Message]" ..
        "label[4,4.65;Message from the clan.]" ..
        "label[0,3.9;#Personal : " .. minetest.colorize("#FF0000", "Your Inbox") .. " (You have received " .. invitations_count .. " requests)]" ..
        "textlist[4,1;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
        "textlist[0,4.75;3.5,2.5;invited_clans;" .. table.concat(invited_clans, ",") .. "]" ..
        "field[1.8,3.05;2,1;invit_field;;]" ..
        "button[0.05,8.2;1.5,1;join_clan;Join]" ..
        "field[1.8,8.5;2.35,1;join_clanf;Confirm Clan Name;]" ..
        "button[0.05,2.75;1.5,1;invit_btn;Invite]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation, Discussion;2]"

    minetest.show_formspec(player:get_player_name(), "invitation_interface", formspec)
end

function clans.show_invitation_formspec(player, player_clan, members, invited_clans, invitations_count, selected_index, message)
    local player_name = player:get_player_name()
    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]" ..
        "box[-0.1,3.75;8,0.7;black]" ..
        "box[-0.1,-0.1;8,9.4;#030303]" ..
        "textarea[0.35,1;3.5,2;invit_msg;;]" ..
        "label[0,0;#Clan : " .. minetest.colorize("#FF0000", player_clan) .. "]" ..
        "label[0,0.65;Invitation Message]" ..
        "label[4,4.65;Message from the clan.]" ..
        "label[0,3.9;#Personal : " .. minetest.colorize("#FF0000", "Your Inbox") .. " (You have received " .. invitations_count .. " requests)]" ..
        "textlist[4,1;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
        "textlist[0,4.75;3.5,2.5;invited_clans;" .. table.concat(invited_clans, ",") .. "]" ..
        "field[1.8,3.05;2,1;invit_field;;]" ..
        "button[0.05,2.75;1.5,1;invit_btn;Invite]" ..
        "button[0.05,8.2;1.5,1;join_clan;Join]" ..
        "field[1.8,8.5;2.35,1;join_clanf;Confirm Clan Name;]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation, Discussion;2]" ..
        "hypertext[4.2,5.5;4.1,4;;" .. message .. "]"

    minetest.show_formspec(player_name, "invitation_interface", formspec)
end
