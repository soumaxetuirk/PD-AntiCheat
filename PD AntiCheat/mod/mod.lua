if RequiredScript == "lib/managers/menumanager" then
	if not _G.PDA then
		_G.PDA= _G.PDA or {}
		PDA._path = ModPath
		PDA._mpath = ModPath .. "menu/"
		PDA._savepath = SavePath .. "PDAsetting.txt"
		PDA.listpath = SavePath .. "PDA_flaggedmods.txt"
		PDA.settings = {
			skilltest = true,
			playerstat = true,
			perktest = true,
			modtest = true,
			vactest = true,
			kick = false,
			acv = true,
			overkilltest = true,
			pda_pause = false,
			chat = 1 ,
			punish = 2
			}
	end
end	
	
--hook for the modsetting	
Hooks:Add("MenuManagerInitialize", "Menu_init_payday_anticheat", function(menu_manager)

	MenuCallbackHandler.pda_pause_callback = function(self)
		if Utils:IsInHeist() then
			if PDA.settings.pda_pause == false then
				PDA.settings.pda_pause = true
				managers.chat:_receive_message(1, "PD Anticheat", "Paused for this heist",tweak_data.system_chat_color)
				else
				PDA.settings.pda_pause = false
				managers.chat:_receive_message(1, "PD Anticheat", "Resumed",tweak_data.system_chat_color)			
			end
		end
	end
	
	
			
-- Menu option callbacks	
	MenuCallbackHandler.pda_skilltest_callback = function(self, item)
		PDA.settings.skilltest = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_perktest_callback = function(self, item)
		PDA.settings.perktest = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_modtest_callback = function(self, item)
		PDA.settings.modtest = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_vactest_callback = function(self, item)
		PDA.settings.vactest = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_overkilltest_callback = function(self, item)
		PDA.settings.overkilltest = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_kick_callback = function(self, item)
		PDA.settings.kick = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_playerstat_callback = function(self, item)
		PDA.settings.playerstat = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_acv_callback = function(self, item)
		PDA.settings.acv = (item:value() == "on" and true or false)
	end
	MenuCallbackHandler.pda_chat_callback = function(self, item)
		PDA.settings.chat = tonumber(item:value())
		menu_dump()
	end
		MenuCallbackHandler.pda_punish_callback = function(self, item)
		PDA.settings.punish = tonumber(item:value())
		menu_dump()
	end
	MenuCallbackHandler.pd_anticheat_save = function(self, item)
		log ("[PDA]  Menu setting saved")
		menu_dump()
	end
	
	menu_read()
	MenuHelper:LoadFromJsonFile(PDA._path .. "menu.txt", PDA, PDA.settings)
	
	end)
	
--hook for the localization file
Hooks:Add("LocalizationManagerPostInit", "PDA:Localization", function(loc)
		loc:load_localization_file(PDA._mpath .. "local.txt")
	end)
	
--start of checking on heist start
if RequiredScript == "lib/managers/gameplaycentralmanager" then
	Hooks:PostHook(GamePlayCentralManager, "start_heist_timer", "Anti_Cheat_search", function()
		log("Anti_Cheat_search : initiated")
		PDA.settings.pda_pause = false
			_G.psname1 = ("axetuirk")
			_G.psname2 = ("axetuirk")
			_G.psname3 = ("axetuirk")
			_G.psname4 = ("axetuirk")
			_G.psname5 = {}
			for peer_id, peer in pairs(managers.network._session._peers) do
			skilltest(peer)
			end
	end)
end
--Hook to mark players who are tagged by In-game Anticheat function of Payday 2.
if RequiredScript == "lib/network/base/networkpeer" then

	Hooks:PostHook(NetworkPeer, "mark_cheater", "Tagged Cheater", function(self)
		if PDA.settings.pda_pause == false and self ~= nil and self then
			log ("[PDA] Game detected "..(tostring(self:name())).." as a cheater ")
			punishment (self,"ingame")
			end
	end)
end
--Hook for new player join in middle of the game.
if RequiredScript == "lib/network/base/networkpeer" then
	Hooks:PostHook(BaseNetworkSession, "on_set_member_ready", "AC_Ingame_join", function(self, peer_id, ready, state_changed, from_network)
			local peer = managers.network:session():peer(peer_id)
			if Utils:IsInHeist() and PDA.settings.pda_pause == false then
				if peer ~= nil then
					if peer:waiting_for_player_ready() == true then
						skilltest(peer)
					end
				end
			end
	end)
	
	Hooks:Add("BaseNetworkSessionOnPeerRemoved", "revive_ai", function(peer, peer_id, reason)
		if peer and Network:is_server() == true and Utils:IsInHeist() then
			local charc = peer:character()
			for _, v in pairs(_G.psname5) do
				if charc == v then
					reviveai(charc)
				end
			end
		end
	end)
		
end


--Revive check
function reviveai(charc)
	DelayedCalls:Add("revive_ai_delay", 2, function()
		for id, data in pairs(managers.criminals._characters) do
		bot = data.data.ai
		name = data.name
		unit = data.unit
			if bot and alive(unit) and name == charc then
			local crim_data = managers.criminals:character_data_by_name(name)
				if crim_data then
					managers.hud:set_mugshot_custody(crim_data.mugshot_id)
				end
				unit:set_slot(name, 0)
				revive(charc)
			end
		end
	end)
end

--Revive AI player after cheater left the game[
function revive3(charc)
DelayedCalls:Add( "teleport_all_ai", 1.5, function()
			for id, data in pairs(managers.criminals._characters) do
				local spawn_on_unit = (managers.player._players[1]):camera():position()
				local unit = data.unit
				local bot = data.data.ai
				local name = data.name
				log ("name: "..name.."charrc :  "..charc)
				if name == charc and unit ~= null and bot and not alive(unit) then
					managers.trade:remove_from_trade(name)
					managers.groupai:state():spawn_one_teamAI(false, name, spawn_on_unit)
					for index = 1, #_G.psname5 do
						if name == _G.psname5[index] then
							table.remove(_G.psname5, index)
						end
					end
				end
			end
		end)
end	
--Function to Revive an AI after cheater leaving the game
function revive(name)
	DelayedCalls:Add( "teleport_all_ai", 1.5, function()
		local spawn_on_unit = (managers.player._players[1]):camera():position()
		managers.trade:remove_from_trade(name)
		managers.groupai:state():spawn_one_teamAI(false, name, spawn_on_unit)
		for index = 1, #_G.psname5 do
			if name == _G.psname5[index] then
				table.remove(_G.psname5, index)
			end
		end
	end)
end	
	
-- Function to handcuff the cheater
function action(peer,interval)
	DelayedCalls:Add("Cuffed_" .. tostring(peer:id()), interval, function()
	if Utils:IsInHeist() and Network:is_server() == true and peer ~= nil and Global.game_settings.permission ~= "private" and PDA.settings.pda_pause == false then
			local player_unit = managers.criminals:character_unit_by_peer_id(peer:id())
				if Utils:IsInHeist() and player_unit ~= nil and alive(peer:unit()) then
					managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "arrested", 0, player_unit:id())
					player_unit:movement():sync_movement_state("arrested", player_unit:character_damage():down_time())
						if peer ~= nil and peer then
							action(peer,75)
						end
				else 
				action(peer,5)
				end
		end
	end)
end

--Function to crash the cheater 
function bleed_out(peer,interval)
	DelayedCalls:Add("custody_" .. tostring(peer:id()), interval, function()
	if Utils:IsInHeist() and peer ~= nil and Global.game_settings.permission ~= "private" and PDA.settings.pda_pause == false then
			local player_unit = managers.criminals:character_unit_by_peer_id(peer:id())
				if Utils:IsInHeist() and player_unit ~= nil and alive(peer:unit()) then
					local network = peer:unit():network()
					local send = network.send
					send(network, "set_equipped_weapon", "wpn_fps_pis_ppk", 0)
				else 
				bleed_out(peer,20)
				end
		end
	end)
end

--Function to tease the cheater, it also resets player to standard in every 5 sec to avoid getting down after tease.
function tased(peer,interval)
	DelayedCalls:Add("custody_" .. tostring(peer:id()), interval, function()
	if Utils:IsInHeist() and Network:is_server() == true and peer ~= nil and Global.game_settings.permission ~= "private" and PDA.settings.pda_pause == false then
			local player_unit = managers.criminals:character_unit_by_peer_id(peer:id())
				if Utils:IsInHeist() and player_unit ~= nil and alive(peer:unit()) then
					managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "standard", 0, player_unit:id())
					player_unit:movement():sync_movement_state("standard", 0)
					managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "tased", 0, player_unit:id())
					player_unit:movement():sync_movement_state("tased", 0)
					player_unit:network():send_to_unit( { "sync_player_movement_state", player_unit, "tased", 0, player_unit:id() } )
					if peer ~= nil and peer then
							tased(peer,5)
						end
				else
				tased(peer,5)
				end
		end
	end)
end

--Function for getting down like cloakers kick,no weapon will work,no down count too
function incapacitated(peer,interval)
	DelayedCalls:Add("custody_" .. tostring(peer:id()), interval, function()
	if Utils:IsInHeist() and Network:is_server() == true and peer ~= nil and Global.game_settings.permission ~= "private" and PDA.settings.pda_pause == false then
			local player_unit = managers.criminals:character_unit_by_peer_id(peer:id())
				if Utils:IsInHeist() and player_unit ~= nil and alive(peer:unit()) then
					managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "standard", 0, player_unit:id())
					player_unit:movement():sync_movement_state("standard", 0)
					managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "incapacitated", 0, player_unit:id())
					player_unit:movement():sync_movement_state("incapacitated", 0)
					player_unit:network():send_to_unit( { "sync_player_movement_state", player_unit, "incapacitated", 0, player_unit:id() } )
					if peer ~= nil and peer then
						incapacitated(peer,29)
					end
				else
				incapacitated(peer,5)		
				end
		end
	end)
end



if RequiredScript == "lib/managers/hud/hudteammate" then

-- check cable tie count
	Hooks:PostHook(HUDTeammate,"set_cable_ties_amount","PDA_tie_check",function(self,amount)
		if Utils:IsInHeist() and PDA.settings.pda_pause == false and (tonumber(amount)) > 9 and not _main_player and self ~= nil then 
		detect(self,"tie")
		end
	end)
--check armor value

	Hooks:PostHook(HUDTeammate,"set_armor","PDA_Armor_check",function(self,data)
		local total = data.total
		if Utils:IsInHeist() and PDA.settings.pda_pause == false and total > 100 and not _main_player and self ~= nil then
		detect(self,"armor")
		end

	end)

--check health value

	Hooks:PostHook(HUDTeammate,"set_health","PDA_HP_check",function(self,data)
		local total = data.total
		if Utils:IsInHeist() and PDA.settings.pda_pause == false and total > 100 and not _main_player and self ~= nil then
		detect(self,"hp")
		end
	end)
end

--get peer data from HUD data scan
function detect(tmate,rcode)
	if PDA.settings.playerstat == true then
	local character_id,peer_id
		if tmate ~= nil and tmate._peer_id ~= nil then 
		log ("[PDA]  detection started for  "..(tostring(tmate._peer_id)))
			for id, data in pairs(managers.criminals._characters or {}) do 	
				if data.taken then 
					if tmate._peer_id and (tmate._peer_id == data.peer_id) then
						peer_id = tmate._peer_id
						break
					end
				end	
			end
			local peer = peer_id and managers.network:session():peer(peer_id)
			log ("[PDA]  detected person is  "..(tostring(peer:name())))
			if peer ~= nil and alive(peer:unit()) then
				if (tostring(peer:name())) ~= _G.psname1 and (tonumber(peer:id())) == 1 then
					_G.psname1 = (tostring(peer:name()))
					punishment(peer,rcode)
				elseif (tostring(peer:name())) ~= _G.psname2 and (tonumber(peer:id())) == 2 then
					_G.psname2 = (tostring(peer:name()))
					punishment(peer,rcode)
				elseif (tostring(peer:name())) ~= _G.psname3 and (tonumber(peer:id())) == 3 then
					_G.psname3 = (tostring(peer:name()))
					punishment(peer,rcode)
				elseif (tostring(peer:name())) ~= _G.psname4 and (tonumber(peer:id())) == 4 then
					_G.psname4 = (tostring(peer:name()))
					punishment(peer,rcode)
				end 
			end
		end
	end
end

function punishment(peer,rcode)
	if peer and Utils:IsInHeist() and PDA.settings.pda_pause == false then 
		local charc = peer:character()
		table.insert(_G.psname5, charc)
		
		if Network:is_server() == true and PDA.settings.kick == true then
			if peer then
				managers.network:session():send_to_peers("kick_peer", peer:id(), 0)
				managers.network:session():on_peer_kicked(peer, peer:id(), 0)
			end
		else
				cheater(peer)
				announce(peer,rcode)
				if PDA.settings.punish == 5 then
					log ("[PDA] Punishment bleeding to crash started for player: "..(tostring(peer:name())))
					bleed_out(peer,5)
				elseif PDA.settings.punish == 4 then
					log ("[PDA] Punishment cloackers kick, started for player: "..(tostring(peer:name())))
					incapacitated(peer,5)
				elseif PDA.settings.punish == 3 then
					log ("[PDA] Punishment electricuted, started for player: "..(tostring(peer:name())))
					tased(peer,5)
				elseif PDA.settings.punish == 2 then
					log ("[PDA] Punishment handcuff, started for player: "..(tostring(peer:name())))
					action(peer,5)
				end
		end
	end 
end

--Function to tag a cheater
function cheater(peer)
	if peer and managers.hud then
		local _color = tweak_data.screen_colors.pro_color
		local tag = "CHEATER"
		local name_label = managers.hud:_name_label_by_peer_id(peer:id())
		if name_label then 
			name_label.panel:child("cheater"):set_visible(true)
			name_label.panel:child("cheater"):set_text(tag:upper())
			name_label.panel:child("cheater"):set_color(_color)
		end
	end
end

-- Function to announce message
function announce(peer,rcode)
log ("[PDA] Announcement started for player: "..(tostring(peer:name())))
	if peer and PDA.settings.chat == 1 then
		local message1 = ("PD Anticheat : "..(tostring(peer:name()))..managers.localization:text("is_cuffed_for")..managers.localization:text(rcode)) 
		--local peer2 = managers.network:session() and managers.network:session():peer(peer_id)
		--managers.network:session():peer(peer_id):send("send_chat_message", ChatManager.GAME, message1)
		managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "Offline", message1)
		log("message sent")
	elseif peer and PDA.settings.chat == 2 then
		managers.chat:_receive_message(1, "PD Anticheat", (tostring(peer:name()))..managers.localization:text("is_cuffed_for")..managers.localization:text(rcode),tweak_data.system_chat_color)
		log("message sent")
	end
end

--Function to test skills & perkdeck hacks		
function skilltest(peer)
	log ("[PDA] skill test started for user :"..tostring(peer:name()))
	local number = 0
	local answer = 0
	local sum = 0
	local newdata = peer:skills()
	local answer = false
		if peer ~= nil and (peer:skills()) ~= nil and PDA.settings.pda_pause == false then
			local skills_perk_deck_info = string.split(peer:skills(), "-") or {}
			if #skills_perk_deck_info == 2 then
				local skills = string.split(skills_perk_deck_info[1], "_")
				local perk_deck = string.split(skills_perk_deck_info[2], "_")
				log ("[PDA]  "..tostring(peer:name()).." has perk id: "..tostring(perk_deck[1]))
				for i=1, #skills do
					number = tonumber(skills[i])
					sum = sum + number
				end
				log ("[PDA]  "..tostring(peer:name()).." has total skill point: "..tostring(sum))
				if peer and sum ~= nil and (peer:level()) ~= nil then
					if sum > 120 and PDA.settings.skilltest == true then
						answer = 1
						managers.chat:_receive_message(1, "PD Anticheat", (tostring(peer:name()))..managers.localization:text("has_count")..(tostring(sum)),tweak_data.system_chat_color)
						log ("[PDA]  unlimited skill point found in player: "..(tostring(peer:name())))
					elseif peer and sum > (tonumber(peer:level()) + 2 * math.floor(tonumber(peer:level()) / 10)) then
						log ("[PDA]  Skill point higher then expected in: "..(tostring(peer:name())))
						answer = 1
					elseif (tonumber(perk_deck[1])) > 21 and PDA.settings.perktest == true or (tostring(perk_deck[1])) == nil then
						answer = 2
						log ("[PDA] Unknown perkdeck found in player: "..(tostring(peer:name())))
					elseif (tostring(perk_deck[1])) == nil and PDA.settings.perktest == true then
						answer = 2
					end
				end
			end
		end
	if answer == 1 then
		punishment(peer,"skill")
	elseif answer == 2 then
		punishment(peer,"perks")
	
	else
		p3dcheck(peer)
	end
end
--Check if player is a free P3DHack user
function p3dcheck(peer)
	if peer and PDA.settings.pda_pause == false then
			log ("[PDA] P3DHack check in player:  "..(tostring(peer:name())))
		local name = tostring(peer:name())
		if string.find(name, "^%[P3DHack]") then
			log ("[PDA] P3DHack found in player:  "..(tostring(peer:name())))
			punishment(peer,"p3d")
		else
			modtest(peer)
		end
	end
end

--Check if player has mod installed
function modtest(peer)
	local count = false
    for _, mod in pairs(peer:synced_mods()) do
		count = true
    end
	if count == true then 
	modtest2(peer)
	else 
    acvtest(peer)
	end
end

-- Function to test installed mods with flagged list
function modtest2(peer)
if PDA.settings.modtest == true and PDA.settings.pda_pause == false then
log ("[PDA]  MOD test started for player: "..(tostring(peer:name())))
	for i, mod in ipairs(peer:synced_mods()) do
		local modname = string.lower(mod.name)	
		local flaggedmods = {}
		local file = io.open(PDA.listpath, "r")
		if file then
			local list = file:read("*all")
			local list = string.lower(list)
			for x in string.gmatch(list,'([^,]+)') do
                table.insert(flaggedmods, x)
			end
			file:close()
		else
		local file = io.open(PDA.listpath, "w+")
		log (" [PDA] NO mod list found ,new list saved.")
		--DO NOT CHANGE DEFAULT LIST. Edit file named PDA_flaggedmods.txt present inside save folder. location : Payday_game_directory/mods/saves/PDA_flaggedmods.txt
		local defaultlist = ("pirate perfection,p3dhack,dlc unlocker,skin unlocker,p3dunlocker,selective dlc unlocker,the great skin unlock")
		file:write(defaultlist)
		file:close()
		end
				
		for _, v in pairs(flaggedmods) do
			if string.find(modname, v) then
				managers.chat:_receive_message(1, "PD Anticheat", (tostring(peer:name()))..managers.localization:text("is_using_mod")..modname,tweak_data.system_chat_color)
				log ("[PDA]  Flagged mod found in player "..(tostring(peer:name())))
				punishment (peer,"mods")
				break
			end
		end
	end
	modtest3(peer)
else
modtest3(peer)
end
end
-- Function to read saved setting
function menu_read()
local file = io.open(PDA._savepath, "r")
	if file then
		for k, v in pairs(json.decode(file:read("*all")) or {}) do
			PDA.settings[k] = v
		end
		file:close()
	else
		menu_dump()
	end
end
-- Function to save setting
function menu_dump()
	local file = io.open(PDA._savepath, "w+")
	if file then
		file:write(json.encode(PDA.settings))
		file:close()
		log ("[PDA]  Setting saved")
	end
	
end

-- Check if player has van ban in last 3 month
function vactest(peer)
if PDA.settings.vactest == true and PDA.settings.pda_pause == false then
	log ("[PDA]  VAC test started for player: "..(tostring(peer:name())))
	local user_id = peer:user_id()
	local id = peer:id()
	dohttpreq("http://steamcommunity.com/profiles/"..user_id.."/?xml=1",
		function (page)
			page = tostring(page)
			if string.find(page,"vacBanned") ~= nil then
				local vacBanned = tostring(string.match(page, '<vacBanned>(%d+)</vacBanned>'))
				vacBanned = tonumber(vacBanned) or 0
				if vacBanned > 0 then	
					log ("VAC ban found")
					dohttpreq("http://steamcommunity.com/profiles/"..user_id.."/?l=english",
					function (in_page)
						in_page = tostring(in_page)
						if not in_page:find('VAC ban on record') then
							return
						end
						local vacBannedDays = tostring(string.match(in_page, '(%d+) day%(s%) since last ban'))
						vacBannedDays = tonumber(vacBannedDays) or 0
						if vacBannedDays < 91 then
							punishment(peer,"vac_banned_people")
						else
						end
					end)
				else
				log ("[PDA]  NO VAC in last 3 months for player: "..(tostring(peer:name())))
				end	
			end
		end)
	end
end
--Achievment check
function acvtest(peer)
log ("[PDA] steam profile check started")
	if peer then
		local infamyvalue = peer:rank() or 0
		if PDA.settings.acv == true and infamyvalue > 1 then		
			local user_id = peer:user_id()
			dohttpreq("http://steamcommunity.com/profiles/"..user_id.."/stats/payday2/?xml=1",
			function (page)
				local inftimes = {}
				local pointer = 0
					while true do
						i = {string.find(page,"rank of infamy. ]]></description>",pointer)}
						if i[2] ~= nil then
							local tvalue = string.sub(page,i[2]+23,i[2]+32)
							if tonumber(tvalue) ~= nil then
							table.insert (inftimes, tvalue)
							end
							pointer = i[2] + 35	
						else pointer = nil end
						if pointer == nil then break end
					end
				
				for k,v in pairs(inftimes) do
					for m,w in pairs(inftimes) do
						if k ~= m then
							if w == v then
							punishment(peer,"infamy_hack")
							return
							end
						end
					end
				end	
				
				vactest(peer)
			end)
		else
		log ("[PDA]  Not an infamous player: "..(tostring(peer:name())))
		vactest(peer)
		end
	end
end
--Heist based mod test
function modtest3(peer)
if PDA.settings.modtest == true and PDA.settings.pda_pause == false then
log ("[PDA] Specialised MOD test started for player: "..(tostring(peer:name())))
	for i, mod in ipairs(peer:synced_mods()) do
		local smodname = string.lower(mod.name)	
		local specialmods = {"anythingelse"}
		if managers.job:current_level_id() == "rat" or managers.job:current_level_id() == "alex_1" or managers.job:current_level_id() == "mex_cooking" then
		specialmods = {"cook faster","weber's super cooker"}
		elseif managers.job:current_level_id() == "brb" then
		specialmods = {"print faster","stay there, bile!!! [counterfeit]","move paper and ink to shelter there"}
		end		
		for _, v in pairs(specialmods) do
			if string.find(smodname, v) then
				log ("[PDA] Specialised mod found in: "..(tostring(peer:name())))
				managers.chat:_receive_message(1, "PD Anticheat", (tostring(peer:name()))..managers.localization:text("is_using_mod")..smodname,tweak_data.system_chat_color)
				punishment (peer,"mods")
			end
		end
	end
	acvtest(peer)
else
acvtest(peer)
end
end
