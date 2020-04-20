--------------------
--Nova World Buffs--
--Classic WoW world buff timers and pre warnings.
--Novaspark-Arugal OCE (classic).
--https://www.curseforge.com/members/venomisto/projects
--Note: Server restarts will cause the timers to be inaccurate because the NPC's reset.

NWB = LibStub("AceAddon-3.0"):NewAddon("NovaWorldBuffs", "AceComm-3.0");
NWB.dragonLib = LibStub("HereBeDragons-2.0");
NWB.dragonLibPins = LibStub("HereBeDragons-Pins-2.0");
NWB.commPrefix = "NWB";
NWB.hasAddon = {};
NWB.realm = GetRealmName();
NWB.faction = UnitFactionGroup("player");
NWB.loadTime = 0;
local L = LibStub("AceLocale-3.0"):GetLocale("NovaWorldBuffs");
local Serializer = LibStub:GetLibrary("AceSerializer-3.0");
local version = GetAddOnMetadata("NovaWorldBuffs", "Version") or 9999;

function NWB:OnInitialize()
	self:loadFactionSpecificOptions();
    self.db = LibStub("AceDB-3.0"):New("NWBdatabase", NWB.optionDefaults, "Default");
    LibStub("AceConfig-3.0"):RegisterOptionsTable("NovaWorldBuffs", NWB.options);
	self.NWBOptions = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NovaWorldBuffs", "NovaWorldBuffs");
	self.chatColor = "|cff" .. self:RGBToHex(self.db.global.chatColorR, self.db.global.chatColorG, self.db.global.chatColorB);
	self:RegisterComm(self.commPrefix);
	self.loadTime = GetServerTime();
	self:registerOtherAddons();
	self:buildRealmFactionData();
	self:setRegionFont();
	self:timerCleanup();
	self:ticker();
	self:yellTicker();
	self:setSongFlowers();
	self:createSongflowerMarkers();
	self:createTuberMarkers();
	self:createDragonMarkers();
	self:refreshFelwoodMarkers();
	self:createWorldbuffMarkersTable();
	self:createWorldbuffMarkers();
	self:getDmfData();
	self:createDmfMarkers();
	self:setNoOverwrite();
	self:resetSongFlowers();
	self:resetLayerData();
	NWB:removeOldLayers();
end

--Set font used in fontstrings on frames.
NWB.regionFont = "Fonts\\ARIALN.ttf";
function NWB:setRegionFont()
	if (LOCALE_koKR) then
     	NWB.regionFont = "Fonts\\2002.TTF";
    elseif (LOCALE_zhCN) then
     	NWB.regionFont = "Fonts\\ARKai_T.ttf";
    elseif (LOCALE_zhTW) then
     	NWB.regionFont = "Fonts\\blei00d.TTF";
    elseif (LOCALE_ruRU) then
    	--ARIALN seems to work in RU.
     	--NWB.regionFont = "Fonts\\FRIZQT___CYR.TTF";
    end
end

local foundPartner; --Debug testing.
function NWB:OnCommReceived(commPrefix, string, distribution, sender)
	if (UnitInBattleground("player") and distribution ~= "GUILD") then
		return;
	end
	--AceComm doesn't supply realm name if it's on the same realm as player.
	--Not sure if it provives GetRealmName() or GetNormalizedRealmName() for crossrealm.
	--For now we'll check all 3 name types just to be sure until tested.
	local me = UnitName("player") .. "-" .. GetRealmName();
	local meNormalized = UnitName("player") .. "-" .. GetNormalizedRealmName();
	if (sender == UnitName("player") or sender == me or sender == meNormalized) then
		NWB.hasAddon[meNormalized] = true;
		return;
	end
	local _, realm = strsplit("-", sender, 2);
	--If realm found then it's not my realm, but just incase acecomm changes and starts supplying realm also check if realm exists.
	if (realm ~= nil or (realm and realm ~= GetRealmName() and realm ~= GetNormalizedRealmName())) then
		--Ignore data from other realms (in bgs).
		return;
	end
	if (commPrefix == "D4C") then
		--Parse DBM.
		NWB:parseDBM(commPrefix, string, distribution, sender);
		return;
	end
	--If no realm in name it must be our realm so add it.
	if (not string.match(sender, "-")) then
		--Add normalized realm since roster checks use this.
		sender = sender .. "-" .. GetNormalizedRealmName();
	end
	--Keep a list of addon users for use in NWB:sendGuildMsg().
	NWB.hasAddon[sender] = true;
	if (distribution == "GUILD") then
		foundPartner = true;
	end
	local deserializeResult, deserialized = Serializer:Deserialize(string);
	if (not deserializeResult) then
		NWB:debug("Error deserializing:", string);
		return;
	end
	local args = NWB:explode(" ", deserialized, 2);
	local cmd = args[1]; --Cmd (first arg) so we know where to send the data.
	local remoteVersion = args[2]; --Version number.
	local data = args[3]; --Data (everything after version arg).
	if (data == nil) then
		--Temp fix for people with old version data structure sending incompatable data.
		--Only effects a few of the early testers.
		data = args[2]; --Data (everything after version arg).
		remoteVersion = 0;
	end
	--if (commPrefix == "NWB") then
		--NWB:debug("received", commPrefix, distribution, sender, cmd);
	--end
	if (not tonumber(remoteVersion)) then
		--Trying to catch a lua error and find out why.
		NWB:debug("version missing", sender, cmd, data);
		return;
	end
	--Ignore old version data with this update, trying to weed out old versions setting wrong timers.
	if (tonumber(remoteVersion) < 1.23) then
		if (cmd == "requestData" and distribution == "GUILD") then
			NWB:sendData("GUILD");
		end
		return;
	end
	if (cmd == "data" or cmd == "settings") then
		NWB:receivedData(data, sender, distribution);
	elseif (cmd == "requestData") then
		--Other addon users request data when they log on.
		NWB:receivedData(data, sender, distribution);
		NWB:sendData("GUILD");
	elseif (cmd == "requestSettings") then
		--Only used once per logon.
		NWB:receivedData(data, sender, distribution);
		NWB:sendSettings("GUILD");
	elseif (cmd == "yell" and not (NWB.db.global.receiveGuildDataOnly and distribution ~= "GUILD")) then
		NWB:debug("yell inc", sender, data);
		--Yell msg seen by someone in org.
		NWB:doFirstYell(data);
	end
	NWB:versionCheck(remoteVersion);
end

--Send to specified addon channel.
function NWB:sendComm(distribution, string, target)
	--if (NWB.isDebug and (UnitName("player") == "Exoblast" or UnitName("player") == "Novaspark")) then
	--	return;
	--end
	if (target == UnitName("player")) then
		return;
	end
	if (distribution == "GUILD" and not IsInGuild()) then
		return;
	end
	if (distribution == "CHANNEL") then
		--Get channel ID number.
		local addonChannelId = GetChannelName(target);
		--Not sure why this only accepts a string and not an int.
		--Addon channels are disabled in classic but I'll leave this here anyway.
		target = tostring(addonChannelId);
	elseif (distribution ~= "WHISPER") then
		target = nil;
	end
	--if (NWB.isDebug) then
	--	local cmd = string:match("(%w+)(.+)");
	--	NWB:debug("send", distribution, target, cmd);
	--end
	local serialized = Serializer:Serialize(string);
	NWB:SendCommMessage(NWB.commPrefix, serialized, distribution, target);
end

--Send full data.
function NWB:sendData(distribution, target, prio)
	if (not prio) then
		prio = "NORMAL";
	end
	local data;
	if (NWB.isLayered) then
		data = NWB:createDataLayered(distribution);
	else
		data = NWB:createData(distribution);
	end
	if (next(data) ~= nil) then
		if (distribution == "YELL") then
			--We only send 1 yell msg every few minutes but it can still give the error msg in chat if many people are close.
			--Not sure why it does this when we only send 1 single msg (possibly just loops through all players on blizz end?).
			C_Timer.After(15, function()
				NWB.doFilterAddonChatMsg = false;
			end)
			NWB.doFilterAddonChatMsg = true;
		end
		data = Serializer:Serialize(data);
		NWB:sendComm(distribution, "data " .. version .. " " .. data, target, prio);
	end
end

--Send settings only.
function NWB:sendSettings(distribution, target, prio)
	if (UnitInBattleground("player") and distribution ~= "GUILD") then
		return data;
	end
	if (not prio) then
		prio = "NORMAL";
	end
	local data = NWB:createSettings(distribution);
	if (next(data) ~= nil) then
		data = Serializer:Serialize(data);
		NWB:sendComm(distribution, "settings " .. version .. " " .. data, target, prio);
	end
end

--Send first yell msg.
function NWB:sendYell(distribution, type, target)
	NWB:sendComm(distribution, "yell " .. version .. " " .. type, target);
end

--Send full data and also request other users data back, used at logon time.
function NWB:requestData(distribution, target, prio)
	if (not prio) then
		prio = "NORMAL";
	end
	local data;
	if (NWB.isLayered) then
		data = NWB:createDataLayered(distribution);
	else
		data = NWB:createData(distribution);
	end
	data = Serializer:Serialize(data);
	NWB:sendComm(distribution, "requestData " .. version .. " " .. data, target, prio);
end

--Send full data and also request other users data back, used at logon time.
function NWB:requestSettings(distribution, target, prio)
	if (not prio) then
		prio = "NORMAL";
	end
	local data = NWB:createSettings(distribution);
	data = Serializer:Serialize(data);
	NWB:sendComm(distribution, "requestSettings " .. version .. " " .. data, target, prio);
end

--Create data table for sending.
function NWB:createData(distribution)
	local data = {};
	if (UnitInBattleground("player") and distribution ~= "GUILD") then
		return data;
	end
	if (NWB.data.rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
		data['rendTimer'] = NWB.data.rendTimer;
		data['rendTimerWho'] = NWB.data.rendTimerWho;
		data['rendYell'] = NWB.data.rendYell or 0;
		data['rendYell2'] = NWB.data.rendYell2 or 0;
		data['rendSource'] = NWB.data.rendSource;
	end
	if (NWB.data.onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
		data['onyTimer'] = NWB.data.onyTimer;
		data['onyTimerWho'] = NWB.data.onyTimerWho;
		data['onyYell'] = NWB.data.onyYell or 0;
		data['onyYell2'] = NWB.data.onyYell2 or 0;
		data['onySource'] = NWB.data.onySource;
	end
	if (NWB.data.nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
		data['nefTimer'] = NWB.data.nefTimer;
		data['nefTimerWho'] = NWB.data.nefTimerWho;
		data['nefYell'] = NWB.data.nefYell or 0;
		data['nefYell2'] = NWB.data.nefYell2 or 0;
		data['nefSource'] = NWB.data.nefSource;
	end
	--[[if (NWB.data.zanTimer > (GetServerTime() - NWB.db.global.zanRespawnTime)) then
		data['zanTimer'] = NWB.data.zanTimer;
		data['zanTimerWho'] = NWB.data.zanTimerWho;
		data['zanYell'] = NWB.data.zanYell or 0;
		data['zanYell2'] = NWB.data.zanYell2 or 0;
		data['zanSource'] = NWB.data.zanSource;
	end]]
	if ((NWB.data.onyNpcDied > NWB.data.onyTimer) and
			(NWB.data.onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
		data['onyNpcDied'] = NWB.data.onyNpcDied;
	end
	if ((NWB.data.nefNpcDied > NWB.data.nefTimer) and
			(NWB.data.nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
		data['nefNpcDied'] = NWB.data.nefNpcDied;
	end
	for k, v in pairs(NWB.songFlowers) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.tubers) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.dragons) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.dragons) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	if (distribution == "GUILD") then
		--Include settings with timer data for guild.
		local settings = NWB:createSettings(distribution);
		local me = UnitName("player") .. "-" .. GetNormalizedRealmName();
		data[me] = settings[me];
	end
	--data['faction'] = NWB.faction;
	return data;
end

function NWB:createDataLayered(distribution)
	local data = {};
	if (UnitInBattleground("player") and distribution ~= "GUILD") then
		return data;
	end
	data.layers = {};
	for layer, v in NWB:pairsByKeys(NWB.data.layers) do
		if (not data.layers[layer]) then
			data.layers[layer] = {};
		end
		if (NWB.data.layers[layer].rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
			data.layers[layer]['rendTimer'] = NWB.data.layers[layer].rendTimer;
			data.layers[layer]['rendTimerWho'] = NWB.data.layers[layer].rendTimerWho;
			data.layers[layer]['rendYell'] = NWB.data.layers[layer].rendYell;
			data.layers[layer]['rendYell2'] = NWB.data.layers[layer].rendYell2;
			data.layers[layer]['rendSource'] = NWB.data.layers[layer].rendSource;
		end
		if (NWB.data.layers[layer].onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
			data.layers[layer]['onyTimer'] = NWB.data.layers[layer].onyTimer;
			data.layers[layer]['onyTimerWho'] = NWB.data.layers[layer].onyTimerWho;
			data.layers[layer]['onyYell'] = NWB.data.layers[layer].onyYell;
			data.layers[layer]['onyYell2'] = NWB.data.layers[layer].onyYell2;
			data.layers[layer]['onySource'] = NWB.data.layers[layer].onySource;
		end
		if (NWB.data.layers[layer].nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
			data.layers[layer]['nefTimer'] = NWB.data.layers[layer].nefTimer;
			data.layers[layer]['nefTimerWho'] = NWB.data.layers[layer].nefTimerWho;
			data.layers[layer]['nefYell'] = NWB.data.layers[layer].nefYell;
			data.layers[layer]['nefYell2'] = NWB.data.layers[layer].nefYell2;
			data.layers[layer]['nefSource'] = NWB.data.layers[layer].nefSource;
		end
		if ((NWB.data.layers[layer].onyNpcDied > NWB.data.layers[layer].onyTimer) and
				(NWB.data.layers[layer].onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
			data['onyNpcDied'] = NWB.data.layers[layer].onyNpcDied;
		end
		if ((NWB.data.layers[layer].nefNpcDied > NWB.data.layers[layer].nefTimer) and
				(NWB.data.layers[layer].nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
			data['nefNpcDied'] = NWB.data.layers[layer].nefNpcDied;
		end
	end
	for k, v in pairs(NWB.songFlowers) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.tubers) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.dragons) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	for k, v in pairs(NWB.dragons) do
		--Add currently active songflower timers.
		if (NWB.data[k] > GetServerTime() - 1500) then
			data[k] = NWB.data[k];
		end
	end
	if (distribution == "GUILD") then
		--Include settings with timer data for guild.
		local settings = NWB:createSettings(distribution);
		local me = UnitName("player") .. "-" .. GetNormalizedRealmName();
		data[me] = settings[me];
	end
	--data['faction'] = NWB.faction;
	return data;
end

--Create settings for sending.
function NWB:createSettings(distribution)
	local data = {};
	if (UnitInBattleground("player") and distribution ~= "GUILD") then
		return data;
	end
	if (distribution == "GUILD") then
		local me = UnitName("player") .. "-" .. GetNormalizedRealmName();
		data[me] = {
			["lastUpdate"] = GetServerTime(), 
			["disableAllGuildMsgs"] = NWB.db.global.disableAllGuildMsgs,
			["guildBuffDropped"] = NWB.db.global.guildBuffDropped,
			["guildNpcDialogue"] = NWB.db.global.guildNpcDialogue,
			["guildZanDialogue"] = NWB.db.global.guildNpcDialogue,
			["guildCommand"] = NWB.db.global.guildCommand,
			["guild30"] = NWB.db.global.guild30,
			["guild15"] = NWB.db.global.guild15,
			["guild10"] = NWB.db.global.guild10,
			["guild5"] = NWB.db.global.guild5,
			["guild1"] = NWB.db.global.guild1,
			["guild0"] = NWB.db.global.guild0,
		};
	end
	data['faction'] = NWB.faction;
	return data;
end

local validKeys = {
	["rendTimer"] = true,
	["rendTimerWho"] = true,
	["rendYell"] = true,
	["rendYell2"] = true,
	["rendSource"] = true,
	["onyTimer"] = true,
	["onyTimerWho"] = true,
	["onyYell"] = true,
	["onyYell2"] = true,
	["onySource"] = true,
	["onyNpcDied"] = true,
	["nefTimer"] = true,
	["nefTimerWho"] = true,
	["nefYell"] = true,
	["nefYell2"] = true,
	["nefSource"] = true,
	["nefNpcDied"] = true,
	["zanTimer"] = true,
	["zanTimerWho"] = true,
	["zanYell"] = true,
	["zanYell2"] = true,
	["zanSource"] = true,
	["flower1"] = true,
	["flower2"] = true,
	["flower3"] = true,
	["flower4"] = true,
	["flower5"] = true,
	["flower6"] = true,
	["flower7"] = true,
	["flower8"] = true,
	["flower9"] = true,
	["flower10"] = true,
	["tuber1"] = true,
	["tuber2"] = true,
	["tuber3"] = true,
	["tuber4"] = true,
	["tuber5"] = true,
	["tuber6"] = true,
	["dragon1"] = true,
	["dragon2"] = true,
	["dragon3"] = true,
	["dragon4"] = true,
	["faction"] = true,
};

--Add received data to our database.
function NWB:receivedData(data, sender, distribution)
	local deserializeResult, data = Serializer:Deserialize(data);
	if (not deserializeResult) then
		NWB:debug("Failed to deserialize data.");
		return;
	end
	--A faction check should not be needed but who knows what funky stuff can happen with the new yell channel and mind control etc.
	--if (not data['faction'] or data['faction'] ~= faction) then
	--	NWB:debug("data from opposite faction received", sender, distribution);
	--	return;
	--end
	if (not NWB:validateData(data)) then
		NWB:debug("invalid data received.");
		NWB:debug(data);
		return;
	end
	local ignoreList = {
		--["dbm"] = true,
	};
	--Ignore data from out of date version users if we've disabled another addons sync.
	--[[for k, v in pairs(ignoreList) do
		if (data["rendSource"] and data["rendSource"] == k) then
			NWB:debug("ignoring rend data from", sender, k);
			data['rendTimer'] = nil;
			data['rendTimerWho'] = nil;
			data['rendYell'] = nil;
			data['rendYell2'] = nil;
			data['rendSource'] = nil;
		end
		if (data["onySource"] and data["onySource"] == k) then
			NWB:debug("ignoring ony data from", sender, k);
			data['onyTimer'] = nil;
			data['onyTimerWho'] = nil;
			data['onyYell'] = nil;
			data['onyYell2'] = nil;
			data['onySource'] = nil;
		end
		if (data["nefSource"] and data["nefSource"] == k) then
			NWB:debug("ignoring nef data from", sender, k);
			data['nefTimer'] = nil;
			data['nefTimerWho'] = nil;
			data['nefYell'] = nil;
			data['nefYell2'] = nil;
			data['nefSource'] = nil;
		end
		if (data["zanSource"] and data["zanSource"] == k) then
			NWB:debug("ignoring zan data from", sender, k);
			data['zanTimer'] = nil;
			data['zanTimerWho'] = nil;
			data['zanYell'] = nil;
			data['zanYell2'] = nil;
			data['zanSource'] = nil;
		end
	end]]
	--NWB:debug(data);
	if (data["rendTimer"] and (data["rendTimer"] < NWB.data["rendTimer"] or 
		(data["rendYell"] < (data["rendTimer"] - 120) and data["rendYell2"] < (data["rendTimer"] - 120)))) then
		--Don't overwrite any data for this timer type if it's an old timer.
		if (data["rendYell"] < (data["rendTimer"] - 120) and data["rendYell2"] < (data["rendTimer"] - 120)) then
			NWB:debug("invalid rend timer from", sender, "npcyell:", data["rendYell"], "buffdropped:", data["rendTimer"]);
		end
		data['rendTimer'] = nil;
		data['rendTimerWho'] = nil;
		data['rendYell'] = nil;
		data['rendYell2'] = nil;
		data['rendSource'] = nil;
	end
	if (data["onyTimer"] and (data["onyTimer"] < NWB.data["onyTimer"] or
			(data["onyYell"] < (data["onyTimer"] - 120) and data["onyYell2"] < (data["onyTimer"] - 120)))) then
		if (data["onyYell"] < (data["onyTimer"] - 120) and data["onyYell2"] < (data["onyTimer"] - 120)) then
			NWB:debug("invalid ony timer from", sender, "npcyell:", data["onyYell"], "buffdropped:", data["onyTimer"]);
		end
		data['onyTimer'] = nil;
		data['onyTimerWho'] = nil;
		data['onyYell'] = nil;
		data['onyYell2'] = nil;
		data['onySource'] = nil;
	end
	if (data["nefTimer"] and (data["nefTimer"] < NWB.data["nefTimer"] or
			(data["nefYell"] < (data["nefTimer"] - 120) and data["nefYell2"] < (data["nefTimer"] - 120)))) then
		if (data["nefYell"] < (data["nefTimer"] - 120) and data["nefYell2"] < (data["nefTimer"] - 120)) then
			NWB:debug("invalid nef timer from", sender, "npcyell:", data["nefYell"], "buffdropped:", data["nefTimer"]);
		end
		data['nefTimer'] = nil;
		data['nefTimerWho'] = nil;
		data['nefYell'] = nil;
		data['nefYell2'] = nil;
		data['nefSource'] = nil;
	end
	--[[if (data["zanTimer"] and (data["zanTimer"] < NWB.data["zanTimer"] or
			(data["zanYell"] < (data["zanTimer"] - 120) and data["zanYell2"] < (data["zanTimer"] - 120)))) then
		if (data["zanYell"] < (data["zanTimer"] - 120) and data["zanYell2"] < (data["zanTimer"] - 120)) then
			NWB:debug("invalid zan timer from", sender, "npcyell:", data["zanYell"], "buffdropped:", data["zanTimer"]);
		end
		data['zanTimer'] = nil;
		data['zanTimerWho'] = nil;
		data['zanYell'] = nil;
		data['zanYell2'] = nil;
		data['zanSource'] = nil;
	end]]
	--Layering is lame.
	if (NWB.isLayered) then
		--Don't overwrite any data if this is a realm with layers.
		if (data["rendTimer"] and NWB.data.rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
			--NWB:debug("ignoring rend timer overwrite", "old:", NWB.data.rendTimer, "new:", data["rendTimer"]);
			data['rendTimer'] = nil;
			data['rendTimerWho'] = nil;
			data['rendYell'] = nil;
			data['rendYell2'] = nil;
			data['rendSource'] = nil;
		end
		if (data["onyTimer"] and NWB.data.onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
			--NWB:debug("ignoring ony timer overwrite", "old:", NWB.data.onyTimer, "new:", data["onyTimer"]);
			data['onyTimer'] = nil;
			data['onyTimerWho'] = nil;
			data['onyYell'] = nil;
			data['onyYell2'] = nil;
			data['onySource'] = nil;
		end
		if (data["nefTimer"] and NWB.data.nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
			--NWB:debug("ignoring nef timer overwrite", "old:", NWB.data.nefTimer, "new:", data["nefTimer"]);
			data['nefTimer'] = nil;
			data['nefTimerWho'] = nil;
			data['nefYell'] = nil;
			data['nefYell2'] = nil;
			data['nefSource'] = nil;
		end
		--[[if (data["zanTimer"] and NWB.data.zanTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
			data['zanTimer'] = nil;
			data['zanTimerWho'] = nil;
			data['zanYell'] = nil;
			data['zanYell2'] = nil;
			data['zanSource'] = nil;
		end]]
		for k, v in pairs(data) do
			if (string.match(k, "flower") or string.match(k, "tuber") or string.match(k, "dragon")) then
				if (tonumber(v) and NWB.data[k] > (GetServerTime() - 1500)) then
					--NWB:debug("ignoring flower timer overwrite", k, "old:", NWB.data[k], "new:", v);
					data[k] = 0;
				end
			end
		end
	end
	local hasNewData, newFlowerData;
	--Insert our layered data here.
	if (NWB.isLayered and data.layers) then
		for layer, vv in NWB:pairsByKeys(data.layers) do
			if (not NWB.data.layers[layer]) then
				NWB:createNewLayer(layer);
			end
			for k, v in pairs(vv) do
				if ((string.match(k, "flower") and NWB.db.global.syncFlowersAll)
						or (not NWB.db.global.receiveGuildDataOnly)
						or (NWB.db.global.receiveGuildDataOnly and distribution == "GUILD")) then
					if (validKeys[k] and tonumber(v)) then
						--If data is numeric (a timestamp) then check it's newer than our current timer.
						if (v ~= nil) then
							if (not NWB.data.layers[layer][k] or not tonumber(NWB.data.layers[layer][k])) then
								--Rare bug someone has corrupt data (not sure how and it's never happened to me, but been reported).
								--This will correct it by resetting thier timestamp to 0.
								NWB:debug("Local data error:", k, NWB.data[k])
								NWB.data.layers[layer][k] = 0;
							end
							--Make sure the key exists, stop a lua error in old versions if we add a new timer type.
							if (NWB.data.layers[layer][k] and v ~= 0 and v > NWB.data.layers[layer][k] and NWB:validateTimestamp(v)) then
								--NWB:debug("new data", sender, distribution, k, v, "old:", NWB.data.layers[layer][k]);
								if (string.match(k, "flower") and not (distribution == "GUILD" and (GetServerTime() - NWB.data.layers[layer][k]) > 15)) then
									newFlowerData = true;
								end
								NWB.data.layers[layer][k] = v;
								hasNewData = true;
							end
						end
					elseif (v ~= nil and k ~= "layers") then
						if (not validKeys[k] and not next(v)) then
							NWB:debug("Invalid key received:", k, v);
						else
							NWB.data.layers[layer][k] = v;
						end
					end
				end
			end
		end
	end
	for k, v in pairs(data) do
		if ((string.match(k, "flower") and NWB.db.global.syncFlowersAll)
				or (not NWB.db.global.receiveGuildDataOnly)
				or (NWB.db.global.receiveGuildDataOnly and distribution == "GUILD")) then
			if (validKeys[k] and tonumber(v)) then
				--If data is numeric (a timestamp) then check it's newer than our current timer.
				if (v ~= nil) then
					if (not NWB.data[k] or not tonumber(NWB.data[k])) then
						--Rare bug someone has corrupt data (not sure how and it's never happened to me, but been reported).
						--This will correct it by resetting thier timestamp to 0.
						NWB:debug("Local data error:", k, NWB.data[k])
						NWB.data[k] = 0;
					end
					--Make sure the key exists, stop a lua error in old versions if we add a new timer type.
					if (NWB.data[k] and v ~= 0 and v > NWB.data[k] and NWB:validateTimestamp(v)) then
						--NWB:debug("new data", sender, distribution, k, v, "old:", NWB.data[k]);
						if (string.match(k, "flower") and not (distribution == "GUILD" and (GetServerTime() - NWB.data[k]) > 15)) then
							newFlowerData = true;
						end
						NWB.data[k] = v;
						hasNewData = true;
					end
				end
			elseif (v ~= nil and k ~= "layers") then
				if (not validKeys[k] and not next(v)) then
					NWB:debug("Invalid key received:", k, v);
				else
					NWB.data[k] = v;
				end
			end
		end
	end
	NWB:timerCleanup();
	--If we get newer data from someone outside the guild then share it with the guild.
	if (hasNewData) then
		NWB.data.lastSyncBy = sender;
		--NWB:debug("new data done", sender, distribution, NWB:isPlayerInGuild(sender));
		if (distribution ~= "GUILD" and not NWB:isPlayerInGuild(sender)) then
			NWB:sendData("GUILD");
		end
	end
	--If new flower data received and not freshly picked by guild member (that sends a msg to guild chat already)
	if (newFlowerData and NWB.db.global.showNewFlower) then
		--local string = "New songflower timer received:";
		local string = L["newSongflowerReceived"] .. ":";
		local found;
		for k, v in pairs(NWB.songFlowers) do
			local time = (NWB.data[k] + 1500) - GetServerTime();
			if (time > 60) then
				local minutes = string.format("%02.f", math.floor(time / 60));
    			local seconds = string.format("%02.f", math.floor(time - minutes * 60));
				string = string .. " (" .. v.subZone .. " " .. minutes .. L["minuteShort"] .. seconds .. L["secondShort"] .. ")";
				found = true;
  			end
		end
		if (not found) then
			string = string .. " " .. L["noActiveTimers"] .. ".";
		end
		NWB:print(string);
	end
end

function NWB:validateData(data)
	--For some reason on rare occasions a timer is received without the yell msg timetsamps (not even a default 0);
	if (tonumber(data["rendTimer"])
				and (not tonumber(data["rendYell"]) or not tonumber(data["rendYell2"]))) then
		return;
	end
	if (tonumber(data["onyTimer"])
				and (not tonumber(data["onyYell"]) or not tonumber(data["onyYell2"]))) then
		return;
	end
	if (tonumber(data["nefTimer"])
				and (not tonumber(data["nefYell"]) or not tonumber(data["nefYell2"]))) then
		return;
	end
	return true;
end

function NWB:versionCheck(remoteVersion)
	local lastVersionMsg = NWB.db.global.lastVersionMsg;
	if (tonumber(remoteVersion) > tonumber(version) and (GetServerTime() - lastVersionMsg) > 43200) then
		print("|cffffff00" .. L["versionOutOfDate"]);
		NWB.db.global.lastVersionMsg = GetServerTime();
	end
end

--Print current buff timers to chat window.
function NWB:printBuffTimers(isLogon)
	local msg;
	if (NWB.faction == "Horde" or NWB.db.global.allianceEnableRend) then
		if (NWB.data.rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
			msg = L["rend"] .. ": " .. NWB:getTimeString(NWB.db.global.rendRespawnTime - (GetServerTime() - NWB.data.rendTimer), true) .. ".";
			if (NWB.db.global.showTimeStamp) then
				local timeStamp = NWB:getTimeFormat(NWB.data.rendTimer + NWB.db.global.rendRespawnTime);
				msg = msg .. " (" .. timeStamp .. ")";
			end
		else
			msg = L["rend"] .. ": " .. L["noCurrentTimer"] .. ".";
		end
		if ((not isLogon or NWB.db.global.logonRend) and not NWB.isLayered) then
			NWB:print(msg);
		end
	end
	if ((NWB.data.onyNpcDied > NWB.data.onyTimer) and
			(NWB.data.onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
		if (NWB.faction == "Horde") then
			msg = string.format(L["onyxiaNpcKilledHordeWithTimer"], NWB:getTimeString(GetServerTime() - NWB.data.onyNpcDied, true));
		else
			msg = string.format(L["onyxiaNpcKilledAllianceWithTimer"], NWB:getTimeString(GetServerTime() - NWB.data.onyNpcDied, true));
		end
	elseif (NWB.data.onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
		msg = L["onyxia"] .. ": " .. NWB:getTimeString(NWB.db.global.onyRespawnTime - (GetServerTime() - NWB.data.onyTimer), true) .. ".";
		if (NWB.db.global.showTimeStamp) then
			local timeStamp = NWB:getTimeFormat(NWB.data.onyTimer + NWB.db.global.onyRespawnTime);
			msg = msg .. " (" .. timeStamp .. ")";
		end
	else
		msg = L["onyxia"] .. ": " .. L["noCurrentTimer"] .. ".";
	end
	if ((not isLogon or NWB.db.global.logonOny) and not NWB.isLayered) then
		NWB:print(msg);
	end
	if ((NWB.data.nefNpcDied > NWB.data.nefTimer) and
			(NWB.data.nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
		if (NWB.faction == "Horde") then
			msg = string.format(L["nefarianNpcKilledHordeWithTimer"], NWB:getTimeString(GetServerTime() - NWB.data.nefNpcDied, true));
		else
			msg = string.format(L["nefarianNpcKilledAllianceWithTimer"], NWB:getTimeString(GetServerTime() - NWB.data.nefNpcDied, true));
		end
	elseif (NWB.data.nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
		msg = L["nefarian"] .. ": " .. NWB:getTimeString(NWB.db.global.nefRespawnTime - (GetServerTime() - NWB.data.nefTimer), true) .. ".";
		if (NWB.db.global.showTimeStamp) then
			local timeStamp = NWB:getTimeFormat(NWB.data.nefTimer + NWB.db.global.nefRespawnTime);
			msg = msg .. " (" .. timeStamp .. ")";
		end
	else
		msg = L["nefarian"] .. ": " .. L["noCurrentTimer"] .. ".";
	end
	if ((not isLogon or NWB.db.global.logonNef) and not NWB.isLayered) then
		NWB:print(msg);
	end
	--Disabled, is no zand timer, will remove later.
	--[[if (NWB.data.zanTimer > (GetServerTime() - NWB.db.global.zanRespawnTime)) then
		msg = L["zan"] .. ": " .. NWB:getTimeString(NWB.db.global.zanRespawnTime - (GetServerTime() - NWB.data.zanTimer), true) .. ".";
		if (NWB.db.global.showTimeStamp) then
			local timeStamp = NWB:getTimeFormat(NWB.data.zanTimer + NWB.db.global.zanRespawnTime);
			msg = msg .. " (" .. timeStamp .. ")";
		end
	else
		msg = L["zan"] .. ": " .. L["noCurrentTimer"] .. ".";
	end
	if (not isLogon or NWB.db.global.logonZan and NWB.zand) then
		--NWB:print(msg);
	end]]
	if (NWB.isLayered) then
		NWB:print("|HNWBCustomLink:timers|hYou are on a layered realm.|h");
		NWB:print("|HNWBCustomLink:timers|hClick here to view current timers.|h");
	end
	local timestamp, timeLeft, type = NWB:getDmfData();
	--if ((NWB.db.global.showDmfLogon and isLogon) or NWB.db.global.showDmfWb
	--		or (NWB.db.global.showDmfWhenClose and (timeLeft > 0 and timeLeft < 43200))) then
	if ((isLogon and NWB.db.global.logonDmfSpawn and (timeLeft > 0 and timeLeft < 21600)) or
		(not isLogon and NWB.db.global.showDmfWb)) then	
		local zone;
		if (NWB.dmfZone == "Mulgore") then
			zone = L["mulgore"];
		else
			zone = L["elwynnForest"];
		end
		msg = NWB:getDmfTimeString() .. " (" .. zone .. ")";
		NWB:print(msg, nil, "[DMF]");
	end
	if (NWB.isDmfUp and NWB.data.myChars[UnitName("player")].buffs) then
		for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
			if (v.type == "dmf" and (v.timeLeft + 7200) > 0) then
				msg = string.format(L["dmfBuffCooldownMsg"], NWB:getTimeString(v.timeLeft + 7200, true));
				if ((not isLogon and NWB.db.global.showDmfBuffWb) or NWB.db.global.logonDmfBuffCooldown) then
					NWB:print(msg, nil, "[DMF]");
				end
				break;
			end
		end
	end
end

--Single line buff timers.
function NWB:getShortBuffTimers(channel, layerID)
	local msg = "";
	local dataPrefix, layer;
	local count = 0;
	if (NWB.isLayered) then
		table.sort(NWB.data.layers);
		for k, v in NWB:pairsByKeys(NWB.data.layers) do
			count = count + 1;
			if (not layerID and count == 1) then
				--Get first layer if no layer specified.
				layer = k;
			elseif (count == tonumber(layerID)) then
				layer = k;
			end
		end
		if (layerID and not layer) then
			return "That layer wasn't found or has no valid timers.";
		end
		dataPrefix = NWB.data.layers[layer];
		if (not dataPrefix and not layeriD) then
			msg = "(" .. L["rend"] .. ": " .. L["noTimer"] .. ") ";
			msg = msg .. "(" .. L["onyxia"] .. ": " .. L["noTimer"] .. ") ";
			msg = msg .. "(" .. L["nefarian"] .. ": " .. L["noTimer"] .. ") ";
			msg = msg .. "(No layers found)";
			return msg;
		end
	else
		dataPrefix = NWB.data;
	end
	if (NWB.faction == "Horde" or NWB.db.global.allianceEnableRend) then
		if (dataPrefix.rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
			msg = "(" .. L["rend"] .. ": " .. NWB:getTimeString(NWB.db.global.rendRespawnTime - (GetServerTime() - dataPrefix.rendTimer), true) .. ") ";
		else
			msg = "(" .. L["rend"] .. ": " .. L["noTimer"] .. ") ";
		end
	end
	if ((dataPrefix.onyNpcDied > dataPrefix.onyTimer) and
			(dataPrefix.onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
		if (NWB.faction == "Horde") then
			msg = msg .. "(Onyxia: NPC (Runthak) was killed " .. NWB:getTimeString(GetServerTime() - dataPrefix.onyNpcDied, true) 
					.. " ago no buff recorded since) ";
		else
			msg = msg .. "(Onyxia: NPC (Mattingly) was killed " .. NWB:getTimeString(GetServerTime() - dataPrefix.onyNpcDied, true) 
					.. " ago no buff recorded since) ";
		end
	elseif (dataPrefix.onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
		msg = msg .. "(" .. L["onyxia"] .. ": " .. NWB:getTimeString(NWB.db.global.onyRespawnTime - (GetServerTime() - dataPrefix.onyTimer), true) .. ") ";
	else
		msg = msg .. "(" .. L["onyxia"] .. ": " .. L["noTimer"] .. ") ";
	end
	if ((dataPrefix.nefNpcDied > dataPrefix.nefTimer) and
			(dataPrefix.nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
		if (NWB.faction == "Horde") then
			msg = msg .. "(Nefarian: NPC (Saurfang) was killed " .. NWB:getTimeString(GetServerTime() - dataPrefix.nefNpcDied, true) 
					.. " ago no buff recorded since)";
		else
			msg = msg .. "(Nefarian: NPC (Afrasiabi) was killed " .. NWB:getTimeString(GetServerTime() - dataPrefix.nefNpcDied, true) 
					.. " ago no buff recorded since)";
		end
	elseif (dataPrefix.nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
		msg = msg .. "(" .. L["nefarian"] .. ": " .. NWB:getTimeString(NWB.db.global.nefRespawnTime - (GetServerTime() - dataPrefix.nefTimer), true) .. ")";
	else
		msg = msg .. "(" .. L["nefarian"] .. ": " .. L["noTimer"] .. ")";
	end
	--[[if (NWB.zand and dataPrefix.zanTimer > (GetServerTime() - NWB.db.global.zanRespawnTime)) then
		msg = msg .. " (" .. L["zan"] .. ": " .. NWB:getTimeString(NWB.db.global.zanRespawnTime - (GetServerTime() - dataPrefix.zanTimer), true) .. ")";
	elseif (NWB.zand) then
		msg = msg .. " (" .. L["zan"] .. ": " .. L["noTimer"] .. ")";
	end]]
	if (layerID) then
		return msg .. " (Layer " .. layerID .. " of " .. count .. ")";
	elseif (NWB.isLayered) then
		return msg .. " (Layer 1 of " .. count .. ")";
	end
	return msg;
end

--Prefixes are clickable in chat to open buffs frame.
function NWB.addClickLinks(self, event, msg, author, ...)
	local types;
	if (NWB.db.global.colorizePrefixLinks) then
		types = {
			["%[WorldBuffs%]"] = "|cFFFF5100|HNWBCustomLink:buffs|h[WorldBuffs]|h|r",
			["%[NovaWorldBuffs%]"] = "|cFFFF5100|HNWBCustomLink:buffs|h[NovaWorldBuffs]|h|r",
			["%[DMF%]"] = "|cFFFF5100|HNWBCustomLink:buffs|h[DMF]|h|r",
		}
	else
		types = {
			["%[WorldBuffs%]"] = "|HNWBCustomLink:buffs|h[WorldBuffs]|h",
			["%[NovaWorldBuffs%]"] = "|HNWBCustomLink:buffs|h[NovaWorldBuffs]|h",
			["%[DMF%]"] = "|HNWBCustomLink:buffs|h[DMF]|h",
		}
	end
	for k, v in pairs(types) do
		local match = string.match(msg, k);
		if (NWB.isLayered) then
			if (match) then
				--If layered make the whole msg clickable to open buffs frame.
				msg = string.gsub(msg, k .. " (.+)", v .. " |HNWBCustomLink:timers|h%1|h");
				return false, msg, author, ...;
			end
		else
			if (match) then
				msg = string.gsub(msg, k, v);
				return false, msg, author, ...;
			end
		end
	end
	return false, msg, author, ...;
	--if (NWB.isLayered and channel == "guild") then
	--	msg = "|HNWBCustomLink:timers|h" .. msg .. "|h";
	--end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", NWB.addClickLinks);
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", NWB.addClickLinks);
--Hook the chat link click func.
hooksecurefunc("ChatFrame_OnHyperlinkShow", function(...)
	local chatFrame, link, text, button = ...;
    if (link == "NWBCustomLink:buffs") then
		NWB:openBuffListFrame();
	end
	if (link == "NWBCustomLink:timers" and NWB.isLayered) then
		NWB:openLayerFrame();
	end
end)

--Insert our custom link type into blizzards SetHyperlink() func.
local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
	if (link and link:sub(0, 13) == "NWBCustomLink") then
		return;
	end
	return OriginalSetHyperlink(self, link, ...);
end

--Add prefix and colors from db then print.
local printPrefix;
function NWB:print(msg, channel, prefix)
	if (prefix) then
		printPrefix = "|cFFFF5100" .. prefix .. "|r";
	end
	if (channel) then
		channel = string.lower(channel);
	end
	if (channel == "group" or channel == "team") then
		channel = "party";
	end
	if (channel == "gchat" or channel == "gmsg") then
		channel = "guild";
	end
	local channelWhisper, name;
	if (channel) then
		channelWhisper, name = strsplit(" ", channel, 2);
	end
	if (channelWhisper == "tell" or channelWhisper == "whisper" or channelWhisper == "msg") then
		if (not prefix) then
			printPrefix = "[NovaWorldBuffs]";
		end
		if (name and name ~= "") then
			SendChatMessage(printPrefix .. " " .. msg, "WHISPER", nil, name);
		else
			print(NWB.chatColor .. "No whisper target found.");
		end
	elseif (channel == "r" or channel == "reply") then
		if (not prefix) then
			printPrefix = "[NovaWorldBuffs]";
		end
		if (NWB.lastWhisper and NWB.lastWhisper ~= "") then
			if (NWB.lastWhisperType == "bnet") then
				BNSendWhisper(NWB.lastWhisper, printPrefix .. " " .. msg);
			else
				SendChatMessage(printPrefix .. " " .. msg, "WHISPER", nil, NWB.lastWhisper);
			end
		else
			print(NWB.chatColor .. "No last whisper target found.");
		end
	elseif (channel == "say" or channel == "yell" or channel == "party" or channel == "guild" or channel == "officer" or channel == "raid") then
		--If posting to a specifed channel then advertise addon name in prefix, more people that have the addon then more accurate the data is.
		if (not prefix) then
			printPrefix = "[NovaWorldBuffs]";
			if (channel == "guild") then
				printPrefix = "[WorldBuffs]";
			end
		end
		SendChatMessage(printPrefix .. " " .. msg, channel);
	elseif (tonumber(channel)) then
		--Send to numbered channel by number.
		local id, name = GetChannelName(channel);
		if (id == 0) then
			print("|cFFFFFF00No channel with id |cFFFF5100" .. channel .. " |cFFFFFF00exists.");
			print("|cFFFFFF00Type \"/wb\" to print world buff timers to yourself.");
			print("|cFFFFFF00Type \"/wb config\" to open options.");
			print("|cFFFFFF00Type \"/wb guild\" to post buff timers to the specified chat channel (accepts channel names and numbers).");
			print("|cFFFFFF00Use \"/sf\" in the same way for songflowers.");
			print("|cFFFFFF00Type \"/dmf\" for your Darkmoon Faire buff cooldown.");
			print("|cFFFFFF00Type \"/buffs\" to view all your alts world buffs.");
			return;
		end
		if (not prefix) then
			printPrefix = "[NovaWorldBuffs]";
		end
		SendChatMessage(printPrefix .. " " .. NWB:stripColors(msg), "CHANNEL", nil, id);
	elseif (channel ~= nil) then
		--Send to numbered channel by name.
		local id, name = GetChannelName(channel);
		if (id == 0) then
			print("|cFFFFFF00No channel with name |cFFFF5100" .. channel .. " |cFFFFFF00exists.");
			print("|cFFFFFF00Type \"/wb\" to print world buff timers to yourself.");
			print("|cFFFFFF00Type \"/wb config\" to open options.");
			print("|cFFFFFF00Type \"/wb guild\" to post buff timers to the specified chat channel (accepts channel names and numbers).");
			print("|cFFFFFF00Use \"/sf\" in the same way for songflowers.");
			print("|cFFFFFF00Type \"/dmf\" for your Darkmoon Faire buff cooldown.");
			print("|cFFFFFF00Type \"/buffs\" to view all your alts world buffs.");
			return;
		end
		if (not prefix) then
			printPrefix = "[NovaWorldBuffs]";
		end
		SendChatMessage(printPrefix .. " " .. NWB:stripColors(msg), "CHANNEL", nil, id);
	else
		if (not prefix) then
			printPrefix = "|cFFFF5100|HNWBCustomLink:buffs|h[WorldBuffs]|h|r";
		end
		if (prefix == "[DMF]") then
			printPrefix = "|cFFFF5100|HNWBCustomLink:buffs|h[DMF]|h|r";
		end
		print(printPrefix .. " " .. NWB.chatColor .. msg);
	end
end

NWB.types = {
	[1] = "rend",
	[2] = "ony",
	[3] = "nef",
	--[4] = "zan"
};

--1 second looping function for timer warning msgs.
NWB.played = 0;
local lastDmfTick = 0;
function NWB:ticker()
	for k, v in pairs(NWB.types) do
		local offset = 0;
		if (v == "rend") then
			offset = NWB.db.global.rendRespawnTime;
		elseif (v == "ony") then
			offset = NWB.db.global.onyRespawnTime;
		elseif (v == "nef") then
			offset = NWB.db.global.nefRespawnTime;
		--elseif (v == "zan") then
		--	offset = NWB.db.global.zanRespawnTime;
		end
		if (NWB.isLayered) then
			for layer, value in NWB:pairsByKeys(NWB.data.layers) do
				local secondsLeft = (NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime();
				--This looks messy but when checking (secondsLeft == 0) it would sometimes skip, not sure why.
				--This gives it a 2 second window instead of 1.
				if (NWB.data.layers[layer][v .. "0"] and secondsLeft <= 0 and secondsLeft >= -1) then
					NWB.data.layers[layer][v .. "0"] = nil;
					NWB:doWarning(v, 0, secondsLeft, layer);
				elseif (NWB.data.layers[layer][v .. "1"] and secondsLeft <= 60 and secondsLeft >= 59) then
					NWB.data.layers[layer][v .. "1"] = nil;
					NWB:doWarning(v, 1, secondsLeft, layer);
				elseif (NWB.data.layers[layer][v .. "5"] and secondsLeft <= 300  and secondsLeft >= 299) then
					NWB.data.layers[layer][v .. "5"] = nil;
					NWB:doWarning(v, 5, secondsLeft, layer);
				elseif (NWB.data.layers[layer][v .. "10"] and secondsLeft <= 600  and secondsLeft >= 599) then
					NWB.data.layers[layer][v .. "10"] = nil;
					NWB:doWarning(v, 10, secondsLeft, layer);
				elseif (NWB.data.layers[layer][v .. "15"] and secondsLeft <= 900 and secondsLeft >= 899) then
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB:doWarning(v, 15, secondsLeft, layer);
				elseif (NWB.data.layers[layer][v .. "30"] and secondsLeft <= 1800 and secondsLeft >= 1799) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB:doWarning(v, 30, secondsLeft, layer);
				end
			end
		else
			local secondsLeft = (NWB.data[v .. "Timer"] + offset) - GetServerTime();
			--This looks messy but when checking (secondsLeft == 0) it would sometimes skip, not sure why.
			--This gives it a 2 second window instead of 1.
			if (NWB.data[v .. "0"] and secondsLeft <= 0 and secondsLeft >= -1) then
				NWB.data[v .. "0"] = nil;
				NWB:doWarning(v, 0, secondsLeft);
			elseif (NWB.data[v .. "1"] and secondsLeft <= 60 and secondsLeft >= 59) then
				NWB.data[v .. "1"] = nil;
				NWB:doWarning(v, 1, secondsLeft);
			elseif (NWB.data[v .. "5"] and secondsLeft <= 300  and secondsLeft >= 299) then
				NWB.data[v .. "5"] = nil;
				NWB:doWarning(v, 5, secondsLeft);
			elseif (NWB.data[v .. "10"] and secondsLeft <= 600  and secondsLeft >= 599) then
				NWB.data[v .. "10"] = nil;
				NWB:doWarning(v, 10, secondsLeft);
			elseif (NWB.data[v .. "15"] and secondsLeft <= 900 and secondsLeft >= 899) then
				NWB.data[v .. "15"] = nil;
				NWB:doWarning(v, 15, secondsLeft);
			elseif (NWB.data[v .. "30"] and secondsLeft <= 1800 and secondsLeft >= 1799) then
				NWB.data[v .. "30"] = nil;
				NWB:doWarning(v, 30, secondsLeft);
			end
		end
	end
	if (NWB.played > 0) then
		NWB.played = NWB.played + 1;
	end
	if (NWB.data.myChars[UnitName("player")].buffs) then
		for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
			v.timeLeft = v.timeLeft - 1;
			if (v.type == "dmf") then
				if ((lastDmfTick + 7200) >= 1 and (v.timeLeft + 7200) <= 0) then
					NWB:print(L["dmfBuffReset"]);
					lastDmfTick = -99999;
					NWB.data.myChars[UnitName("player")].buffs[k] = nil;
				else
					lastDmfTick = v.timeLeft;
				end
			end
		end
	end
	C_Timer.After(1, function()
		NWB:ticker();
	end)
end

function NWB:yellTicker()
	--One msg every 3 mins.
	local yellDelay = 180;
	if (NWB.isLayered) then
		--Longer yell delay on high pop servers, no need for as many.
		--One msg every 5 mins.
		yellDelay = 300;
	end
	C_Timer.After(yellDelay, function()
		--Msg inside the timer so it doesn't send first tick at logon, player entering world does that.
		local inInstance, instanceType = IsInInstance();
		if (not UnitInBattleground("player") and inInstance ~= "raid") then
			NWB:sendData("YELL");
		end
		NWB:yellTicker();
	end)
end

--Filter addon comm warnings from yell for 5 seconds after sending a yell.
--Even though we only send 1 msg every few minutes I think it can still trigger this msg if a large amount of people are in 1 spot.
--Even if it triggers this msg the data still got out there to most people, it will spread just fine over time.
--"yell" msgs possibly don't just send 1 msg to the server but instead loop through every player close and send 1 by 1?
NWB.doFilterAddonChatMsg = false;
local function filterAddonChatMsg(self, event, msg, author, ...)
	if (NWB.doFilterAddonChatMsg) then
		--The number of messages that can be sent is limited, please wait to send another message.
		if (string.find(msg, ERR_CHAT_THROTTLED) or string.find(msg, "The number of messages that can be sent is limited")) then
			return true;
    	end
    end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterAddonChatMsg);

--Send warnings to channels selected in options
local warningThroddle = {
	["rend"] = 0,
	["ony"] = 0,
	["nef"] = 0,
	["zan"] = 0,
};
function NWB:doWarning(type, num, secondsLeft, layer)
	--Temporary bug fix.
	if (warningThroddle[type] and (GetServerTime() - warningThroddle[type]) < 3) then
		return;
	end
	warningThroddle[type] = GetServerTime();
	local layerMsg = "";
	if (layer) then
		local count = 0;
		for k, v in NWB:pairsByKeys(NWB.data.layers) do
			count = count + 1;
			if (k == tonumber(layer)) then
				layerMsg = " (Layer " .. count .. ")";
			end
		end
	end
	local send = true;
	local buff;
	if (type == "rend") then
		buff = L["rend"];
		if (NWB.faction ~= "Horde" and not NWB.db.global.allianceEnableRend) then
			--We only send rend timer warnings to alliance if they have enabled it.
			send = nil;
		end
	elseif (type == "ony") then
		buff = L["onyxia"];
	elseif (type == "nef") then
		buff = L["nefarian"];
	elseif (type == "zan") then
		buff = L["zan"];
	end
	local msg;
	if (num == 0) then
		msg = string.format(L["newBuffCanBeDropped"], buff);
	else
		msg = string.format(L["buffResetsIn"], buff, NWB:getTimeString(secondsLeft, true));
	end
	if ((type == "ony" and NWB.data.onyNpcDied > NWB.data.onyTimer)
			or (type == "nef" and (NWB.data.nefNpcDied > NWB.data.nefTimer))) then
		--If npc killed timestamp is newer than last set time then don't send any warnings.
		return;	
	end
	local period = ".";
	if (LOCALE_zhCN or LOCALE_zhTW) then
		period = "。";
	end
	msg = msg .. layerMsg .. period;
	--Chat.
	if (NWB.db.global.chat30 and num == 30 and send) then
		NWB:print(msg);
	elseif (NWB.db.global.chat15 and num == 15 and send) then
		NWB:print(msg);
	elseif (NWB.db.global.chat10 and num == 10 and send) then
		NWB:print(msg);
	elseif (NWB.db.global.chat5 and num == 5 and send) then
		NWB:print(msg);
	elseif (NWB.db.global.chat1 and num == 1 and send) then
		NWB:print(msg);
	elseif (NWB.db.global.chat0 and num == 0 and send) then
		NWB:print(msg);
	end
	--Middle of the screen.
	local colorTable = {r = self.db.global.middleColorR, g = self.db.global.middleColorG, 
			b = self.db.global.middleColorB, id = 41, sticky = 0};
	if (NWB.db.global.middle30 and num == 30 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	elseif (NWB.db.global.middle15 and num == 15 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	elseif (NWB.db.global.middle10 and num == 10 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	elseif (NWB.db.global.middle5 and num == 5 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	elseif (NWB.db.global.middle1 and num == 1 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	elseif (NWB.db.global.middle0 and num == 0 and send) then
		RaidNotice_AddMessage(RaidWarningFrame, NWB:stripColors(msg), colorTable, 5);
	end
	--Guild.
	local loadWait = GetServerTime() - NWB.loadTime;
	if (loadWait > 5 and NWB.db.global.guild30 and num == 30 and send) then
		NWB:sendGuildMsg(msg, "guild30");
	elseif (loadWait > 5 and NWB.db.global.guild15 and num == 15 and send) then
		NWB:sendGuildMsg(msg, "guild15");
	elseif (loadWait > 5 and NWB.db.global.guild10 and num == 10 and send) then
		NWB:sendGuildMsg(msg, "guild10");
	elseif (loadWait > 5 and NWB.db.global.guild5 and num == 5 and send) then
		NWB:sendGuildMsg(msg, "guild5");
	elseif (loadWait > 5 and NWB.db.global.guild1 and num == 1 and send) then
		NWB:sendGuildMsg(msg, "guild1");
	elseif (loadWait > 5 and NWB.db.global.guild0 and num == 0 and send) then
		NWB:sendGuildMsg(msg, "guild0");
	end
end

--Only one person online at a time sends guild msgs so there's no spam, chosen by alphabetical order.
--Can also specify zone so only 1 person from that zone will send the msg (like orgrimmar when npc yell goes out).
function NWB:sendGuildMsg(msg, type, zoneName)
	if (NWB.db.global.disableAllGuildMsgs) then
		return;
	end
	if (not IsInGuild()) then
		return;
	end
	GuildRoster();
	local numTotalMembers = GetNumGuildMembers();
	local onlineMembers = {};
	local me = UnitName("player") .. "-" .. GetNormalizedRealmName();
	for i = 1, numTotalMembers do
		local name, _, _, _, _, zone, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i);
		if (zoneName) then
			if (name and zone == zoneName and online and NWB.hasAddon[name] and not isMobile) then
				--If guild member is in zone specified and online and has addon installed add to temp table.
				--Not currently used anywhere, was removed.
				onlineMembers[name] = true;
			end
		elseif (type) then
			--If type then check our db for other peoples settings to ignore them in online list if they have this type disabled.
			if (name and online and NWB.hasAddon[name] and not isMobile) then
				if (NWB.data[name]) then
					--If another guild member check thier settings.
					if (NWB.data[name][type] == true and NWB.data[name].disableAllGuildMsgs ~= true) then
						--Has addon and has this type of msg type option enabled.
						onlineMembers[name] = true;
					end
				elseif (name == me) then
					--If myself check my settings.
					if (NWB.db.global[type] == true and NWB.db.global.disableAllGuildMsgs ~= true) then
						onlineMembers[name] = true;
					end
				end
			end
		else
			if (name and online and NWB.hasAddon[name] and not isMobile) then
				--If guild member is online and has addon installed add to temp table.
				onlineMembers[name] = true;
			end
		end
	end
	--Check temp table to see if we're first in alphabetical order.
	for k, v in NWB:pairsByKeys(onlineMembers) do
		if (k == me) then
			SendChatMessage("[WorldBuffs] " .. NWB:stripColors(msg), "guild");
		end
		return;
	end
end

--Guild chat msg event.
local guildWbCmdCooldown, guildDmfCmdCooldown = 0, 0;
function NWB:chatMsgGuild(...)
	local msg = ...;
	msg = string.lower(msg);
	local cmd, arg = strsplit(" ", msg, 2);
	if (string.match(msg, "^!wb") and NWB.db.global.guildCommand and (GetServerTime() - guildWbCmdCooldown) > 5) then
		guildWbCmdCooldown = GetServerTime();
		NWB:sendGuildMsg(NWB:getShortBuffTimers(nil, arg), "guildCommand");
	end
	if (string.match(msg, "^!dmf") and NWB.db.global.guildCommand and (GetServerTime() - guildDmfCmdCooldown) > 5) then
		guildDmfCmdCooldown = GetServerTime();
		local output = NWB:getDmfTimeString();
		if (output) then
			NWB:sendGuildMsg(output, "guildCommand");
		end
	end
end

function NWB:monsterYell(...)
	--Skip strict string matching yell msgs for regions we haven't localized yet.
	--This could result in less accurate timers but better than no timers at all.
	local locale = GetLocale();
	local skipStringCheck;
	if (NWB.faction == "Horde") then
		if (locale == "frFR" or locale == "ptBR" or locale == "koKR" or locale == "esES" or locale == "esMX" or locale == "itIT") then
			skipStringCheck = true;
		end
	end
	if (NWB.faction == "Alliance") then
		if (locale == "frFR" or locale == "ptBR" or locale == "koKR" or locale == "esES" or locale == "esMX" or locale == "itIT"
				or locale == "ruRU" or locale == "deDE" or locale == "zhCN") then
			skipStringCheck = true;
		end
	end
	local msg, name = ...;
	if ((name == L["Thrall"] or (name == L["Herald of Thrall"] and (not NWB.isLayered or NWB.faction == "Alliance")))
			and (string.match(msg, L["Rend Blackhand, has fallen"]) or skipStringCheck)) then
		--6 seconds between first rend yell and buff applied.
		NWB.data.rendYell = GetServerTime();
		NWB:doFirstYell("rend");
		--Send first yell msg to guild so people in org see it, needed because 1 person online only will send msg.
		NWB:sendYell("GUILD", "rend");
		if  (name == L["Herald of Thrall"] and not NWB.isLayered) then
			--If it was herald we may we in the barrens but not in crossraods to receive buff, set buff timer.
			C_Timer.After(5, function()
				NWB:setRendBuff("self", UnitName("player"));
			end)
		end
	elseif ((name == L["Thrall"] or (name == L["Herald of Thrall"] and (not NWB.isLayered or NWB.faction == "Alliance")))
			and string.match(msg, "Be bathed in my power")) then
		--Second yell right before drops "Be bathed in my power! Drink in my might! Battle for the glory of the Horde!".
		NWB.data.rendYell2 = GetServerTime();
	elseif ((name == L["Overlord Runthak"] and (string.match(msg, L["Onyxia, has been slain"]) or skipStringCheck))
			or (name == L["Major Mattingly"] and (string.match(msg, L["history has been made"]) or skipStringCheck))) then
		--14 seconds between first ony yell and buff applied.
		NWB.data.onyYell = GetServerTime();
		NWB:doFirstYell("ony");
		--Send first yell msg to guild so people in org see it, needed because 1 person online only will send msg.
		NWB:sendYell("GUILD", "ony");
	elseif ((name == L["Overlord Runthak"] and string.match(msg, L["Be lifted by the rallying cry"]))
			or (name == L["Major Mattingly"] and string.match(msg, L["Onyxia, hangs from the arches"]))) then
		--Second yell right before drops "Be lifted by the rallying cry of your dragon slayers".
		NWB.data.onyYell2 = GetServerTime();
	elseif ((name == L["High Overlord Saurfang"] and (string.match(msg, L["NEFARIAN IS SLAIN"]) or skipStringCheck))
		 	or (name == L["Field Marshal Afrasiabi"] and (string.match(msg, L["the Lord of Blackrock is slain"]) or skipStringCheck))) then
		--15 seconds between first nef yell and buff applied.
		NWB.data.nefYell = GetServerTime();
		NWB:doFirstYell("nef");
		--Send first yell msg to guild so people in org see it, needed because 1 person online only will send msg.
		NWB:sendYell("GUILD", "nef");
	elseif ((name == L["High Overlord Saurfang"] and string.match(msg, L["Revel in his rallying cry"]))
			or (name == L["Field Marshal Afrasiabi"] and string.match(msg, L["Revel in the rallying cry"]))) then
		--Second yell right before drops "Be lifted by PlayerName's accomplishment! Revel in his rallying cry!".
		NWB.data.nefYell2 = GetServerTime();
	elseif ((name == L["Molthor"] or name == L["Zandalarian Emissary"])
			and (string.match(msg, L["Begin the ritual"]) or string.match(msg, L["The Blood God"]) or skipStringCheck)) then
		--27ish seconds between first zan yell and buff applied if on island.
		--45ish seconds between first zan yell and buff applied if in booty bay.
		--Booty Bay yell (Zandalarian Emissary yells: The Blood God, the Soulflayer, has been defeated!  We are imperiled no longer!)
		NWB.data.zanYell = GetServerTime();
		NWB:doFirstYell("zan");
		NWB:sendYell("GUILD", "zan");
	elseif ((name == L["Molthor"] or name == L["Zandalarian Emissary"]) and string.match(msg, L["slayer of Hakkar"])) then
		--Second yell right before drops "All Hail <name>, slayer of Hakkar, and hero of Azeroth!".
		--Booty Bay yell (Zandalarian Emissary yells: All Hail <name>, slayer of Hakkar, and hero of Azeroth!)
		NWB.data.zanYell2 = GetServerTime();
	end
end

--Post first yell warning to guild chat, shared by all different addon comms so no overlap.
local rendFirstYell, onyFirstYell, nefFirstYell, zanFirstYell = 0, 0, 0, 0;
function NWB:doFirstYell(type)
	if (type == "rend") then
		if ((GetServerTime() - rendFirstYell) > 120) then
			--6 seconds from rend first yell to buff drop.
			NWB.data.rendYell = GetServerTime();
			if (NWB.db.global.guildNpcDialogue  and (NWB.faction == "Horde" or NWB.db.global.allianceEnableRend)) then
				NWB:sendGuildMsg(L["rendFirstYellMsg"], "guildNpcDialogue");
			end
			rendFirstYell = GetServerTime();
		end
	elseif (type == "ony") then
		if ((GetServerTime() - onyFirstYell) > 120) then
			--14 seconds from ony first yell to buff drop.
			NWB.data.onyYell = GetServerTime();
			if (NWB.db.global.guildNpcDialogue) then
				NWB:sendGuildMsg(L["onyxiaFirstYellMsg"], "guildNpcDialogue");
			end
			onyFirstYell = GetServerTime();
		end
	elseif (type == "nef") then
		if ((GetServerTime() - nefFirstYell) > 120) then
			--15 seconds from nef first yell to buff drop.
			NWB.data.nefYell = GetServerTime();
			if (NWB.db.global.guildNpcDialogue) then
				NWB:sendGuildMsg(L["nefarianFirstYellMsg"], "guildNpcDialogue");
			end
			nefFirstYell = GetServerTime();
		end
	elseif (type == "zan") then
		if ((GetServerTime() - zanFirstYell) > 120) then
			--27ish seconds between first zan yell and buff applied if on island.
			--45ish seconds between first zan yell and buff applied if in booty bay.
			NWB.data.zanYell = GetServerTime();
			if (NWB.db.global.chatZan) then
				NWB:print(L["zanFirstYellMsg"]);
			end
			--Middle of the screen.
			local colorTable = {r = self.db.global.middleColorR, g = self.db.global.middleColorG, 
					b = self.db.global.middleColorB, id = 41, sticky = 0};
			if (NWB.db.global.middleZan) then
				RaidNotice_AddMessage(RaidWarningFrame, L["zanFirstYellMsg"], colorTable, 5);
			end
			if (NWB.db.global.guildZanDialogue) then
				NWB:sendGuildMsg(L["zanFirstYellMsg"], "guildZanDialogue");
			end
			NWB:debug(L["zanFirstYellMsg"]);
			zanFirstYell = GetServerTime();
		end
	end
end

local lastZanBuffGained = 0;
function NWB:combatLogEventUnfiltered(...)
	local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, 
			destName, destFlags, destRaidFlags, _, spellName = CombatLogGetCurrentEventInfo();
	if (subEvent == "UNIT_DIED") then
		local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
		if ((zone == 1454 or zone == 1411) and destName == L["Overlord Runthak"]) then
			if (NWB.faction ~= "Horde") then
				return;
			end
			NWB.data.onyNpcDied = GetServerTime();
			if (NWB.db.global.guildNpcKilled) then
				SendChatMessage("[WorldBuffs] " .. L["onyxiaNpcKilledHorde"], "guild");
			end
			NWB:print(L["onyxiaNpcKilledHorde"]);
			NWB:timerCleanup();
			NWB:sendData("GUILD");
			NWB:sendData("YELL"); --Yell is further than npc view range.
		elseif ((zone == 1454 or zone == 1411) and destName == L["High Overlord Saurfang"]) then
			if (NWB.faction ~= "Horde") then
				return;
			end
			NWB.data.nefNpcDied = GetServerTime();
			if (NWB.db.global.guildNpcKilled) then
				SendChatMessage("[WorldBuffs] " .. L["nefarianNpcKilledHorde"], "guild");
			end
			NWB:print(L["nefarianNpcKilledHorde"]);
			NWB:timerCleanup();
			NWB:sendData("GUILD");
			NWB:sendData("YELL"); --Yell is further than npc view range.
		elseif ((zone == 1453 or zone == 1429) and destName == L["Major Mattingly"]) then
			if (NWB.faction ~= "Alliance") then
				return;
			end
			NWB.data.onyNpcDied = GetServerTime();
			if (NWB.db.global.guildNpcKilled) then
				SendChatMessage("[WorldBuffs] " .. L["onyxiaNpcKilledAlliance"], "guild");
			end
			NWB:print(L["onyxiaNpcKilledAlliance"]);
			NWB:timerCleanup();
			NWB:sendData("GUILD");
			NWB:sendData("YELL"); --Yell is further than npc view range.
		elseif ((zone == 1453 or zone == 1429) and destName == L["Field Marshal Afrasiabi"]) then
			if (NWB.faction ~= "Alliance") then
				return;
			end
			NWB.data.nefNpcDied = GetServerTime();
			if (NWB.db.global.guildNpcKilled) then
				SendChatMessage("[WorldBuffs] " .. L["nefarianNpcKilledAlliance"], "guild");
			end
			NWB:print(L["nefarianNpcKilledAlliance"]);
			NWB:timerCleanup();
			NWB:sendData("GUILD");
			NWB:sendData("YELL"); --Yell is further than npc view range.
		end
	elseif (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH") then
		local _, _, _, _, zoneID, npcID = strsplit("-", sourceGUID);
		zoneID = tonumber(zoneID);
		if (destName == UnitName("player") and spellName == L["Warchief's Blessing"]) then
			local expirationTime = NWB:getBuffDuration(L["Warchief's Blessing"], 1);
			local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
			--If layered then you must be in org to set the right layer id, the barrens is disabled.
			if (expirationTime >= 3599.5 and (zone == 1454 or not NWB.isLayered)) then
				NWB:setRendBuff("self", UnitName("player"), zoneID);
				NWB:trackNewBuff(spellName, "rend");
			end
		elseif (destName == UnitName("player") and spellName == L["Spirit of Zandalar"] and (GetServerTime() - lastZanBuffGained) > 0) then
			local expirationTime = NWB:getBuffDuration(L["Spirit of Zandalar"], 1);
			if (expirationTime >= 7199.5) then
				NWB:setZanBuff("self", UnitName("player"), zoneID);
				NWB:trackNewBuff(spellName, "zan");
				--Not sure why this triggers 4 times on PTR, needs more testing once it's on live server but for now we do a 1 second cooldown.
				lastZanBuffGained = GetServerTime();
			end
		elseif ((npcID == "14720" or npcID == "14721") and destName == UnitName("player") and spellName == L["Rallying Cry of the Dragonslayer"]
				and ((GetServerTime() - NWB.data.nefYell2) < 60 or (GetServerTime() - NWB.data.nefYell) < 60)) then
			--To tell the difference between nef and ony we check if there a nef npc yell recently, if not then fall back to ony.
			--1 minute is the buff window after 2nd yell to allow for mass lag.
			--Doubt any server would drop both heads within 1min of each other.
			local expirationTime = NWB:getBuffDuration(L["Rallying Cry of the Dragonslayer"], 2);
			if (expirationTime >= 7199.5) then
				NWB:setNefBuff("self", UnitName("player"), zoneID);
			end
		elseif ((npcID == "14392" or npcID == "14394")and destName == UnitName("player") and spellName == L["Rallying Cry of the Dragonslayer"]
				and ((GetServerTime() - NWB.data.onyYell2) < 60 or (GetServerTime() - NWB.data.onyYell) < 60)
				and ((GetServerTime() - NWB.data.nefYell2) > 60)) then
			local expirationTime = NWB:getBuffDuration(L["Rallying Cry of the Dragonslayer"], 2);
			if (expirationTime >= 7199.5) then
				NWB:setOnyBuff("self", UnitName("player"), zoneID);
			end
		elseif (destName == UnitName("player") and (spellName == L["Sayge's Dark Fortune of Agility"]
				or spellName == L["Sayge's Dark Fortune of Spirit"] or spellName == L["Sayge's Dark Fortune of Stamina"]
				or spellName == L["Sayge's Dark Fortune of Strength"] or spellName == L["Sayge's Dark Fortune of Armor"]
				or spellName == L["Sayge's Dark Fortune of Resistance"] or spellName == L["Sayge's Dark Fortune of Damage"]
				 or spellName == L["Sayge's Dark Fortune of Intelligence"])) then
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "dmf");
			end
		elseif (destName == UnitName("player") and npcID == "14822") then
			--Backup checking Sayge NPC ID until all localizations are done properly.
			--Maybe this is a better way of doing it overall but I have to test when DMF is actually up first.
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "dmf");
			end
		end
		--Check new nef/ony buffs for tracking durations seperately than the buff timer checks with validation above.
		if ((npcID == "14720" or npcID == "14721") and destName == UnitName("player")
				and spellName == L["Rallying Cry of the Dragonslayer"]) then
			local expirationTime = NWB:getBuffDuration(L["Rallying Cry of the Dragonslayer"], 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "nef");
			end
		elseif ((npcID == "14392" or npcID == "14394") and destName == UnitName("player")
				and spellName == L["Rallying Cry of the Dragonslayer"]) then
			local expirationTime = NWB:getBuffDuration(L["Rallying Cry of the Dragonslayer"], 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "ony");
			end
		elseif (destName == UnitName("player") and spellName == L["Songflower Serenade"]) then
			local expirationTime = NWB:getBuffDuration(L["Songflower Serenade"], 2);
			if (expirationTime >= 3599) then
				NWB:trackNewBuff(spellName, "songflower");
			end
		elseif (npcID == "14326" and destName == UnitName("player")) then
			--Mol'dar's Moxie.
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "moxie");
			end
		elseif (npcID == "14321" and destName == UnitName("player")) then
			--Fengus' Ferocity.
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "ferocity");
			end
		elseif (npcID == "14323" and destName == UnitName("player")) then
			--Slip'kik's Savvy.
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "savvy");
			end
		elseif (NWB.isDebugg and destName == UnitName("player") and spellName == "Ice Armor") then
			local expirationTime = NWB:getBuffDuration("Ice Armor", 2);
			if (expirationTime >= 1799) then
				NWB:trackNewBuff(spellName, "ice");
			end
		elseif (destName == UnitName("player")
				and (spellName == L["Flask of Supreme Power"] or spellName == L["Supreme Power"])) then
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "flaskPower");
			end
		elseif (destName == UnitName("player") and spellName == L["Flask of the Titans"]) then
			--This is the only flask spell with "Flask" in the name it seems.
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "flaskTitans");
			end
		elseif (destName == UnitName("player")
				and (spellName == L["Flask of Distilled Wisdom"] or spellName == L["Distilled Wisdom"])) then
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "flaskWisdom");
			end
		elseif (destName == UnitName("player")
				and (spellName == L["Flask of Chromatic Resistance"] or spellName == L["Chromatic Resistance"])) then
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 7199) then
				NWB:trackNewBuff(spellName, "flaskResistance");
			end
		elseif (destName == UnitName("player") and spellName == L["Resist Fire"]) then
			local expirationTime = NWB:getBuffDuration(spellName, 2);
			if (expirationTime >= 3599) then
				NWB:trackNewBuff(spellName, "resistFire");
			end
		end
	elseif (subEvent == "SPELL_AURA_REMOVED" and destName == UnitName("player")) then
		NWB:untrackBuff(spellName);
	end	
end

local rendLastSet, onyLastSet, nefLastSet, zanLastSet = 0, 0, 0, 0;
function NWB:setRendBuff(source, sender, zoneID)
	--Check if this addon has already set a timer a few seconds before another addon's comm.
	if (source ~= "self" and (GetServerTime() - NWB.data.rendTimer) < 10) then
		return;
	end
	if (not NWB:validateNewTimer("rend", source)) then
		NWB:debug("failed rend timer validation", source);
		return;
	end
	--if (NWB.isLayered and tonumber(zoneID)) then
		if (not NWB.data.layers[zoneID]) then
			NWB:createNewLayer(zoneID);
		end
		NWB.data.layers[zoneID].rendTimer = GetServerTime();
		NWB.data.layers[zoneID].rendTimerWho = sender;
		NWB.data.layers[zoneID].rendSource = source;
		NWB.data.layers[zoneID].rendYell = NWB.data.rendYell;
		NWB.data.layers[zoneID].rendYell2 = NWB.data.rendYell2;
	--else
		--Keep recording older non layered data for now.
		NWB.data.rendTimer = GetServerTime();
		NWB.data.rendTimerWho = sender;
		NWB.data.rendSource = source;
	--end
	NWB:resetWarningTimers("rend", zoneID);
	NWB:sendData("GUILD");
	--Once per drop one guild member will say in chat it dropped.
	--Throddle the drop msg for when we get multiple sources at the same drop time.
	if ((GetServerTime() - rendLastSet) > 60) then
		local layerMsg = "";
		if (NWB.db.global.guildBuffDropped and (NWB.faction == "Horde" or NWB.db.global.allianceEnableRend)) then
			if (zoneID) then
				local count = 0;
				for k, v in NWB:pairsByKeys(NWB.data.layers) do
					count = count + 1;
					if (k == zoneID) then
						layerMsg = " (Layer " .. count .. ")";
					end
				end
			end
			NWB:sendGuildMsg(L["rendBuffDropped"] .. layerMsg, "guildBuffDropped");
		end
	end
	rendLastSet = GetServerTime();
	NWB:debug("set rend buff", source);
	NWB.data.myChars[UnitName("player")].rendCount = NWB.data.myChars[UnitName("player")].rendCount + 1;
	NWB:debug("zoneid drop", zoneID);
end

function NWB:setZanBuff(source, sender, zoneID)
	--Disabled, there is no cooldown, will remove all the zand timer code at a later point.
	--[[if (not NWB.zand) then
		return;
	end
	NWB:debug("6");
	if (source ~= "self" and (GetServerTime() - NWB.data.zanTimer) < 10) then
		return;
	end
	if (not NWB:validateNewTimer("zan", source)) then
		NWB:debug("failed zan timer validation", source);
		return;
	end
	NWB:debug("7");
	NWB.data.zanTimer = GetServerTime();
	NWB.data.zanTimerWho = sender;
	NWB.data.zanSource = source;
	NWB:resetWarningTimers("zan", zoneID);
	NWB:sendData("GUILD");
	--Once per drop one guild member will say in chat it dropped.
	--Throddle the drop msg for when we get multiple sources at the same drop time.
	if ((GetServerTime() - zanLastSet) > 120) then
		if (NWB.db.global.guildBuffDropped) then
			NWB:sendGuildMsg(L["zanBuffDropped"], "guildBuffDropped");
		end
	end
	zanLastSet = GetServerTime();
	NWB:debug("set zan buff", source);]]
	NWB.data.myChars[UnitName("player")].zanCount = NWB.data.myChars[UnitName("player")].zanCount + 1;
	NWB:debug("zoneid drop", zoneID);
end

function NWB:setOnyBuff(source, sender, zoneID)
	--Ony and nef share a last set cooldown to prevent any bugs with both being set at once.
	if ((GetServerTime() - nefLastSet) < 20) then
		return;
	end
	if (source ~= "self" and (GetServerTime() - NWB.data.onyTimer) < 10) then
		return;
	end
	if (not NWB:validateNewTimer("ony", source)) then
		NWB:debug("failed ony timer validation", source);
		return;
	end
	--if (NWB.isLayered and tonumber(zoneID)) then
		if (not NWB.data.layers[zoneID]) then
			NWB:createNewLayer(zoneID);
		end
		NWB.data.layers[zoneID].onyTimer = GetServerTime();
		NWB.data.layers[zoneID].onyTimerWho = sender;
		NWB.data.layers[zoneID].onyNpcDied = 0;
		NWB.data.layers[zoneID].onySource = source;
		NWB.data.layers[zoneID].onyYell = NWB.data.onyYell;
		NWB.data.layers[zoneID].onyYell2 = NWB.data.onyYell2;
	--else
		NWB.data.onyTimer = GetServerTime();
		NWB.data.onyTimerWho = sender;
		NWB.data.onyNpcDied = 0;
		NWB.data.onySource = source;
	--end
	NWB:resetWarningTimers("ony", zoneID);
	NWB:sendData("GUILD");
	if ((GetServerTime() - onyLastSet) > 60) then
		local layerMsg = "";
		if (NWB.db.global.guildBuffDropped) then
			if (zoneID) then
				local count = 0;
				for k, v in NWB:pairsByKeys(NWB.data.layers) do
					count = count + 1;
					if (k == zoneID) then
						layerMsg = " (Layer " .. count .. ")";
					end
				end
			end
			NWB:sendGuildMsg(L["onyxiaBuffDropped"] .. layerMsg, "guildBuffDropped");
		end
	end
	onyLastSet = GetServerTime();
	NWB:debug("set ony buff", source);
	NWB.data.myChars[UnitName("player")].onyCount = NWB.data.myChars[UnitName("player")].onyCount + 1;
	NWB:debug("zoneid drop", zoneID);
end

function NWB:setNefBuff(source, sender, zoneID)
	--Ony and nef share a last set cooldown to prevent any bugs with both being set at once.
	if ((GetServerTime() - onyLastSet) < 20) then
		return;
	end
	if (source ~= "self" and (GetServerTime() - NWB.data.nefTimer) < 10) then
		return;
	end
	if (not NWB:validateNewTimer("nef", source)) then
		NWB:debug("failed nef timer validation", source);
		return;
	end
	--if (NWB.isLayered and tonumber(zoneID)) then
		if (not NWB.data.layers[zoneID]) then
			NWB:createNewLayer(zoneID);
		end
		NWB.data.layers[zoneID].nefTimer = GetServerTime();
		NWB.data.layers[zoneID].nefTimerWho = sender;
		NWB.data.layers[zoneID].nefNpcDied = 0;
		NWB.data.layers[zoneID].nefSource = source;
		NWB.data.layers[zoneID].nefYell = NWB.data.nefYell;
		NWB.data.layers[zoneID].nefYell2 = NWB.data.nefYell2;
	--else
		NWB.data.nefTimer = GetServerTime();
		NWB.data.nefTimerWho = sender;
		NWB.data.nefNpcDied = 0;
		NWB.data.nefSource = source;
	--end
	NWB:resetWarningTimers("nef", zoneID);
	NWB:sendData("GUILD");
	if ((GetServerTime() - nefLastSet) > 60) then
		local layerMsg = "";
		if (NWB.db.global.guildBuffDropped) then
			if (zoneID) then
				local count = 0;
				for k, v in NWB:pairsByKeys(NWB.data.layers) do
					count = count + 1;
					if (k == zoneID) then
						layerMsg = " (Layer " .. count .. ")";
					end
				end
			end
			NWB:sendGuildMsg(L["nefarianBuffDropped"] .. layerMsg, "guildBuffDropped");
		end
	end
	nefLastSet = GetServerTime();
	NWB:debug("set nef buff", source);
	NWB.data.myChars[UnitName("player")].nefCount = NWB.data.myChars[UnitName("player")].nefCount + 1;
	NWB:debug("zoneid drop", zoneID);
end

--Validate new timer, mostly used for testing blanket fixes for timers.
function NWB:validateNewTimer(type, source, timestamp)
	if (type == "rend") then
		return true;
	elseif (type == "ony") then
		if (source == "dbm") then
			local timer = NWB.data.onyTimer;
			local respawnTime = NWB.db.global.onyRespawnTime;
			if ((timer - 30) > (GetServerTime() - respawnTime) and not (NWB.data.onyNpcDied > timer)) then
				--Don't set dbm timers if valid timer already exists (current bug).
				NWB:debug("trying to set timer from dbm when timer already exists");
				return;
			end
		end
		if (NWB.data.nefTimer == timestamp or NWB.data.nefTimer == GetServerTime()) then
			NWB:debug("ony trying to set exact same timer as nef", source);
			--Make sure ony never syncs with nef time stamp (current bug).
			return;
		end
	elseif (type == "nef") then
		if (NWB.data.onyTimer == timestamp or NWB.data.onyTimer == GetServerTime()) then
			NWB:debug("nef trying to set exact same timer as ony", source);
			--Make sure nef never syncs with ony time stamp (current bug).
			return;
		end
	end
	--If this is a realm with layering still (TW/CN) then don't overwrite timers ever, atleast 1 layer will be correct then.
	--Really not sure why Blizzard still have layering in these asian regions.
	--if (NWB.isLayered and NWB.data[type .. "Timer"]
		--Disabled for now for new layer tracking method.
	--		and (NWB.data[type .. "Timer"] > (GetServerTime() - NWB.db.global[type .. "RespawnTime"]))) then
	--	return;
	--end
	return true;
end

function NWB:validateTimestamp(timestamp)
	local currentTime = GetServerTime();
	if (timestamp > 2585912598) then
		return;
	end
	if (timestamp > (currentTime + 86400)) then
		return;
	end
	return true;
end

--Track our current buff durations across all chars.
function NWB:trackNewBuff(spellName, type)
	if (not NWB.data.myChars[UnitName("player")].buffs[spellName]) then
		NWB.data.myChars[UnitName("player")].buffs[spellName] = {};
	end
	if (not NWB.data.myChars[UnitName("player")].buffs[spellName].setTime) then
		NWB.data.myChars[UnitName("player")].buffs[spellName].setTime = 0;
	end
	if (not NWB.data.myChars[UnitName("player")].buffs[spellName].timeLeft) then
		NWB.data.myChars[UnitName("player")].buffs[spellName].timeLeft = 0;
	end
	NWB.data.myChars[UnitName("player")].buffs[spellName].type = type;
	--Set timestamp as a backup to calc from when dmf buff is got.
	NWB.data.myChars[UnitName("player")].buffs[spellName].setTime = GetServerTime();
	NWB.data.myChars[UnitName("player")].buffs[spellName].track = true;
	--Request played data when getting new buff drops to calc from as primary.
	--Use local cache if we have a valid number from RequestTimePlayed() at logon, otherwise request new data.
	if (NWB.played > 600) then
		NWB.data.myChars[UnitName("player")].buffs[spellName].playedCacheSetAt = NWB.played;
		NWB:syncBuffsWithCurrentDuration();
		NWB:recalcBuffTimers();
	else
		NWB.currentTrackBuff = NWB.data.myChars[UnitName("player")].buffs[spellName];
		--Hide the msg from chat.
		DEFAULT_CHAT_FRAME:UnregisterEvent("TIME_PLAYED_MSG");
		RequestTimePlayed();
	end
	if (type == "dmf") then
		NWB:print(string.format(L["dmfBuffDropped"], spellName));
	end
	NWB:debug("Tracking new buff", type, spellName);
end

function NWB:untrackBuff(spellName)
	if (NWB.data.myChars[UnitName("player")].buffs and NWB.data.myChars[UnitName("player")].buffs[spellName]) then
		--local hasBuff;
		--for i = 1, 32 do
		--	local spellName = UnitBuff("player", i);
		--	if (NWB.data.myChars[UnitName("player")].buffs and NWB.data.myChars[UnitName("player")].buffs[spellName]) then
		--		hasBuff = true;
		--	end
		--end
		--if (not hasBuff) then
			NWB.data.myChars[UnitName("player")].buffs[spellName].track = false;
		--end
	end
end

--Recalc time left on buffs we track.
--We recalc it from current total played time vs total played we recorded at time of buff drop.
local gotPlayedData;
function NWB:recalcBuffTimers()
	if (NWB.data.myChars[UnitName("player")].buffs) then
		for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
			if (not gotPlayedData) then
				NWB:debug("no played data found");
				return
			end
			if (not v.setTime) then
				v.setTime = 0;
			end
			if (not v.timeLeft) then
				v.timeLeft = 0;
			end
			if (not v.playedCacheSetAt) then
				v.playedCacheSetAt = 0;
			end
			--Calc the difference between current total played time and the played time we record when buff was gotten.
			v.timeLeft = NWB.db.global[v.type .. "BuffTime"] - (NWB.played - v.playedCacheSetAt);
			--NWB.data.myChars[UnitName("player")].buffs[k].timeLeft = NWB.db.global[v.type .. "BuffTime"] - (NWB.played - v.playedCacheSetAt);
		end
	end
end

--/played can sometimes drift a bit with buff durations, probably due to loads times and such.
--Here we resync the buff tracking with current buff durations.
function NWB:syncBuffsWithCurrentDuration()
	for i = 1, 32 do
		local spellName, _, _, _, _, expirationTime, _, _, _, spellID = UnitBuff("player", i);
		if (NWB.data.myChars[UnitName("player")].buffs and NWB.data.myChars[UnitName("player")].buffs[spellName]) then
			if (NWB.played > 600) then
				local type = NWB.data.myChars[UnitName("player")].buffs[spellName].type;
				local timeLeft = expirationTime - GetTime();
				local maxDuration = NWB.db.global[type .. "BuffTime"] or 0;
				local elapsedDuration = maxDuration - timeLeft;
				local newPlayedCache = NWB.played - elapsedDuration;
				--Change the played seconds this was buff was set at to match the current time elapsed on our current buff.
				NWB.data.myChars[UnitName("player")].buffs[spellName].playedCacheSetAt = math.floor(newPlayedCache);
				--NWB:debug("resyncing tracked buff", spellName);
			end
		elseif (spellID == 16609 or spellID == 22888 or spellID == 23768 or spellID == 23769 or spellID == 23767
				or spellID == 23766 or spellID == 23738 or spellID == 23737 or spellID == 23735 or spellID == 23736
				or spellID == 22818 or spellID == 22817 or spellID == 22820 or spellID == 17626 or spellID == 15366) then
			--Temorary adding of buffs that aren't fresh while this new feature is out, usually we record them on drop.
			local spellTypes = {			
				[16609] = "rend",
				[22888] = "ony",
				--[22888] = "nef",
				[24425] = "zan",
				[23768] = "dmf", --Sayge's Dark Fortune of Damage
				[23769] = "dmf", --Sayge's Dark Fortune of Resistance
				[23767] = "dmf", --Sayge's Dark Fortune of Armor
				[23766] = "dmf", --Sayge's Dark Fortune of Intelligence
				[23738] = "dmf", --Sayge's Dark Fortune of Spirit
				[23737] = "dmf", --Sayge's Dark Fortune of Stamina
				[23735] = "dmf", --Sayge's Dark Fortune of Strength
				[23736] = "dmf", --Sayge's Dark Fortune of Agility
				[22818] = "moxie",
				[22817] = "ferocity",
				[22820] = "savvy",
				[17628] = "flaskPower", --Supreme Power.
				[17626] = "flaskTitans", --Flask of the Titans (only flask spell with Flask in the name, dunno why).
				[17627] = "flaskWisdom", --Distilled Wisdom.
				[17629] = "flaskResistance", --Chromatic Resistance.
				[15366] = "songflower",
				[15123] = "resistFire", --LBRS fire resist buff.
			};
			if (NWB.played > 600 and spellTypes[spellID]) then
				local type = spellTypes[spellID];
				NWB.data.myChars[UnitName("player")].buffs[spellName] = {};
				NWB.data.myChars[UnitName("player")].buffs[spellName].type = type;
				local timeLeft = expirationTime - GetTime();
				local maxDuration = NWB.db.global[type .. "BuffTime"] or 0;
				local elapsedDuration = maxDuration - timeLeft;
				local newPlayedCache = NWB.played - elapsedDuration;
				NWB.data.myChars[UnitName("player")].buffs[spellName].setTime = GetServerTime();
				NWB.data.myChars[UnitName("player")].buffs[spellName].track = true;
				--Change the played seconds this was buff was set at to match the current time elapsed on our current buff.
				NWB.data.myChars[UnitName("player")].buffs[spellName].playedCacheSetAt = math.floor(newPlayedCache);
				NWB:debug("resyncing2 tracked buff", spellName);
			end
		end
	end
	NWB:recalcBuffTimers();
end

--Played time data received, update local cache.
function NWB:timePlayedMsg(...)
	local totalPlayed = ...;
	--Update played cache for ticker when /played data received.
	if (totalPlayed > 0) then
		NWB.played = totalPlayed;
	end
	--Only set the total played seconds at time of a new buff drop we track.
	if (totalPlayed > 0 and NWB.currentTrackBuff ~= nil) then
		NWB.currentTrackBuff.playedCacheSetAt = totalPlayed;
		--NWB:recalcBuffTimers();
		NWB.currentTrackBuff = nil;
	end
	--Reregister the chat frame event after we're done.
	DEFAULT_CHAT_FRAME:RegisterEvent("TIME_PLAYED_MSG");
	NWB:syncBuffsWithCurrentDuration();
	NWB:recalcBuffTimers();
end

--This only runs once at load time.
function NWB:setNoOverwrite()
	--TW realms.
	if (NWB.realm == "伊弗斯" or NWB.realm == "瑪拉頓"
			--CN realms (so many realms and all have layering apparently, wtf?).
			or NWB.realm == "匕首岭" or NWB.realm == "乌洛克" or NWB.realm == "厄运之槌"  or NWB.realm == "巴罗夫"
			or NWB.realm == "无尽风暴" or NWB.realm == "无畏" or NWB.realm == "木喉要塞" or NWB.realm == "比格沃斯"
			or NWB.realm == "比斯巨兽" or NWB.realm == "水晶之牙" or NWB.realm == "火锤" or NWB.realm == "加丁"
			or NWB.realm == "巨人追猎者" or NWB.realm == "巨龙沼泽" or NWB.realm == "巨龙追猎者" or NWB.realm == "布劳缪克丝"
			or NWB.realm == "布鲁" or NWB.realm == "弗莱拉斯" or NWB.realm == "末日之刃" or NWB.realm == "龙之召唤"
			or NWB.realm == "龙牙" or NWB.realm == "伊森迪奥斯" or NWB.realm == "伦鲁迪洛尔" or NWB.realm == "光芒"
			or NWB.realm == "吉兹洛克" or NWB.realm == "安娜丝塔丽" or NWB.realm == "灰烬使者" or NWB.realm == "艾隆纳亚"
			or NWB.realm == "克罗米" or NWB.realm == "希尔盖" or NWB.realm == "怀特迈恩" or NWB.realm == "沙尔图拉"
			or NWB.realm == "沙顶" or NWB.realm == "灵风" or NWB.realm == "狂野之刃" or NWB.realm == "辛洛斯"
			or NWB.realm == "辛迪加" or NWB.realm == "迈克斯纳" or NWB.realm == "卓越" or NWB.realm == "审判"
			or NWB.realm == "帕奇维克" or NWB.realm == "拉姆斯登" or NWB.realm == "法尔班克斯" or NWB.realm == "法拉克斯"
			or NWB.realm == "法琳娜" or NWB.realm == "觅心者" or NWB.realm == "阿什坎迪" or NWB.realm == "阿拉希盆地"
			or NWB.realm == "阿鲁高" or NWB.realm == "哈霍兰" or NWB.realm == "奎尔塞拉" or NWB.realm == "娅尔罗"
			or NWB.realm == "怒炉" or NWB.realm == "狮心" or NWB.realm == "祈福" or NWB.realm == "范克瑞斯"
			or NWB.realm == "范克瑞斯" or NWB.realm == "范沃森" or NWB.realm == "埃提耶什" or NWB.realm == "席瓦莱恩"
			or NWB.realm == "神谕林地" or NWB.realm == "秩序之源" or NWB.realm == "诺克赛恩" or NWB.realm == "诺格弗格"
			or NWB.realm == "骨火" or NWB.realm == "曼多基尔" or NWB.realm == "维克尼拉斯" or NWB.realm == "维克托"
			or NWB.realm == "维克洛尔" or NWB.realm == "维希度斯" or NWB.realm == "莫格莱尼" or NWB.realm == "奥罗"
			or NWB.realm == "奥金斧" or NWB.realm == "寒冰之王" or NWB.realm == "寒脊山小径" or NWB.realm == "湖畔镇"
			or NWB.realm == "黑曜石之锋" or NWB.realm == "塞卡尔" or NWB.realm == "塞雷布拉斯" or NWB.realm == "毁灭之刃"
			or NWB.realm == "萨弗拉斯" or NWB.realm == "萨弗隆" or NWB.realm == "雷德" or NWB.realm == "雷霆之击"
			or NWB.realm == "碧玉矿洞" or NWB.realm == "碧空之歌" or NWB.realm == "赫洛德" or NWB.realm == "德姆塞卡尔"
			or NWB.realm == "震地者" or NWB.realm == "霜语"
			--US/OCE layered realms.
			or NWB.realm == "Arugal" or NWB.realm == "Benediction" or NWB.realm == "Earthfury" or NWB.realm == "Faerlina"
			or NWB.realm == "Fairbanks" or NWB.realm == "Herod" or NWB.realm == "Pagle" or NWB.realm == "Sulfuras"
			or NWB.realm == "Whitemane"
			--EU layered realms.
			or NWB.realm == "Auberdine" or NWB.realm == "Ashbringer" or NWB.realm == "Firemaw" or NWB.realm == "Flamegor"
			or NWB.realm == "Gehennas" or NWB.realm == "Golemagg" or NWB.realm == "Mograine" or NWB.realm == "Sulfuron"
			or NWB.realm == "Venoxis") then
		NWB.isLayered = true;
	end
end

--Make sure warning msg values are correct for the current time left on each timer.
function NWB:timerCleanup()
	local types = {
		[1] = "rend",
		[2] = "ony",
		[3] = "nef",
		--[4] = "zan"
	};
	for k, v in pairs(types) do
		local offset = 0;
		if (NWB.isLayered) then
			for layer, value in NWB:pairsByKeys(NWB.data.layers) do
				if (v == "rend") then
					offset = NWB.db.global.rendRespawnTime;
					NWB:resetWarningTimers("rend", layer);
				elseif (v == "ony") then
					offset = NWB.db.global.onyRespawnTime;
					NWB:resetWarningTimers("ony", layer);
				elseif (v == "nef") then
					offset = NWB.db.global.nefRespawnTime;
					NWB:resetWarningTimers("nef", layer);
				--elseif (v == "zan") then
				--	offset = NWB.db.global.zanRespawnTime;
				--	NWB:resetWarningTimers("zan", layer);
				end
				--Clear warning timers that ended while we were offline or if NPC was killed since last buff.
				if (NWB.data.layers[layer][v .. "NpcDied"] and NWB.data.layers[layer][v .. "NpcDied"] > (GetServerTime() - NWB.db.global[v .. "RespawnTime"])) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB.data.layers[layer][v .. "10"] = nil;
					NWB.data.layers[layer][v .. "5"] = nil;
					NWB.data.layers[layer][v .. "1"] = nil;
					NWB.data.layers[layer][v .. "0"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 0) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB.data.layers[layer][v .. "10"] = nil;
					NWB.data.layers[layer][v .. "5"] = nil;
					NWB.data.layers[layer][v .. "1"] = nil;
					NWB.data.layers[layer][v .. "0"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 60) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB.data.layers[layer][v .. "10"] = nil;
					NWB.data.layers[layer][v .. "5"] = nil;
					NWB.data.layers[layer][v .. "1"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 300) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB.data.layers[layer][v .. "10"] = nil;
					NWB.data.layers[layer][v .. "5"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 600) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
					NWB.data.layers[layer][v .. "10"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 900) then
					NWB.data.layers[layer][v .. "30"] = nil;
					NWB.data.layers[layer][v .. "15"] = nil;
				elseif (((NWB.data.layers[layer][v .. "Timer"] + offset) - GetServerTime()) < 1800) then
					NWB.data.layers[layer][v .. "30"] = nil;
				end
			end
		else
			if (v == "rend") then
				offset = NWB.db.global.rendRespawnTime;
				NWB:resetWarningTimers("rend");
			elseif (v == "ony") then
				offset = NWB.db.global.onyRespawnTime;
				NWB:resetWarningTimers("ony");
			elseif (v == "nef") then
				offset = NWB.db.global.nefRespawnTime;
				NWB:resetWarningTimers("nef");
			--elseif (v == "zan") then
			--	offset = NWB.db.global.zanRespawnTime;
			--	NWB:resetWarningTimers("zan");
			end
			--Clear warning timers that ended while we were offline or if NPC was killed since last buff.
			if (NWB.data[v .. "NpcDied"] and NWB.data[v .. "NpcDied"] > (GetServerTime() - NWB.db.global[v .. "RespawnTime"])) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
				NWB.data[v .. "10"] = nil;
				NWB.data[v .. "5"] = nil;
				NWB.data[v .. "1"] = nil;
				NWB.data[v .. "0"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 0) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
				NWB.data[v .. "10"] = nil;
				NWB.data[v .. "5"] = nil;
				NWB.data[v .. "1"] = nil;
				NWB.data[v .. "0"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 60) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
				NWB.data[v .. "10"] = nil;
				NWB.data[v .. "5"] = nil;
				NWB.data[v .. "1"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 300) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
				NWB.data[v .. "10"] = nil;
				NWB.data[v .. "5"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 600) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
				NWB.data[v .. "10"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 900) then
				NWB.data[v .. "30"] = nil;
				NWB.data[v .. "15"] = nil;
			elseif (((NWB.data[v .. "Timer"] + offset) - GetServerTime()) < 1800) then
				NWB.data[v .. "30"] = nil;
			end
		end
	end
end

--Reset and enable all warning msgs for specified timer.
function NWB:resetWarningTimers(type, layer)
	if (layer) then
		NWB.data.layers[layer][type .. "30"] = true;
		NWB.data.layers[layer][type .. "15"] = true;
		NWB.data.layers[layer][type .. "10"] = true;
		NWB.data.layers[layer][type .. "5"] = true;
		NWB.data.layers[layer][type .. "1"] = true;
		NWB.data.layers[layer][type .. "0"] = true;
	else
		NWB.data[type .. "30"] = true;
		NWB.data[type .. "15"] = true;
		NWB.data[type .. "10"] = true;
		NWB.data[type .. "5"] = true;
		NWB.data[type .. "1"] = true;
		NWB.data[type .. "0"] = true;
	end
end

local f = CreateFrame("Frame");
f:RegisterEvent("PLAYER_ENTERING_WORLD");
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
f:RegisterEvent("CHAT_MSG_MONSTER_YELL");
f:RegisterEvent("GROUP_JOINED");
f:RegisterEvent("TIME_PLAYED_MSG");
f:RegisterEvent("PLAYER_LOGIN");
f:RegisterEvent("CHAT_MSG_WHISPER");
f:RegisterEvent("CHAT_MSG_BN_WHISPER");
local doLogon = true;
f:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		--Testing this here instead of PLAYER_ENTERING_WORLD, maybe it fires slightly faster enough to stop duplicate msgs.
		NWB.loadTime = GetServerTime();
		NWB:requestData("GUILD", nil, "ALERT");
		self:RegisterEvent("CHAT_MSG_GUILD");
		C_Timer.After(10, function()
			--If for some reason we get no replys to first msg, send again in 10 seconds (trying to fix a bug).
			--Could be that first msg trys to send before chat connects on rare occasions?
			if (not foundPartner) then
				NWB:requestData("GUILD", nil, "ALERT");
			end
		end)
		C_Timer.After(30, function()
			--Send a ping with settings after 30 seconds to make sure we are registered as having the addon to others.
			--There's a rare bug that makes 2 clients send a timer msg at once due to not registering each others clients.
			--Not sure of the reason yet but it could be logging on at exact same time or something? This could fix that.
			NWB:requestSettings("GUILD");
			NWB:syncBuffsWithCurrentDuration();
		end)
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (doLogon) then
			GuildRoster();
			if (NWB.db.global.logonPrint) then
				C_Timer.After(10, function()
					GuildRoster(); --Attempting to fix slow guild roster update at logon.
					NWB:printBuffTimers(true);
				end);
			end
			--If WorldBuffTimers isn't installed then send it's data request to guild.
			--if (not WorldBuffTracker_HandleSync and IsInGuild()) then
			--	C_ChatInfo.SendAddonMessage("WBT-0", 11326, "GUILD");
			--end
			--First request after logon is high prio so gets sent right away, need to register addon users asap so no duplicate guild msgs.
			--NWB:requestData("GUILD", nil, "ALERT");
			C_Timer.After(5, function()
				--Only request played data at logon if we didn't get it already for some reason.
				if (not gotPlayedData) then
					gotPlayedData = true;
					DEFAULT_CHAT_FRAME:UnregisterEvent("TIME_PLAYED_MSG");
					RequestTimePlayed();
				end
			end)
			--Temp debug.
			if (NWB.isDebug) then
				NWB:refreshWorldbuffMarkers();
			end
			doLogon = nil;
		end
		NWB:sendData("YELL");
	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		NWB:combatLogEventUnfiltered(...);
	elseif (event == "CHAT_MSG_MONSTER_YELL") then
		NWB:monsterYell(...);
	elseif (event == "GROUP_JOINED") then
		C_Timer.After(5, function()
			if (UnitInBattleground("player")) then
				return;
			end
			if (IsInRaid()) then
  				NWB:sendData("RAID");
  			elseif (IsInGroup()) then
  				NWB:sendData("PARTY");
  			end
  		end)
  	elseif (event == "CHAT_MSG_GUILD") then
  		NWB:chatMsgGuild(...);
	elseif (event == "TIME_PLAYED_MSG") then
		gotPlayedData = true;
		NWB:timePlayedMsg(...);
	elseif (event == "CHAT_MSG_WHISPER") then
		local _, name = ...;
		NWB.lastWhisper = name;
		NWB.lastWhisperType = "whisper";
	elseif (event == "CHAT_MSG_BN_WHISPER") then
		local _, name, _, _, _, _, _, _, _, _, _, _, presenceID = ...;
		NWB.lastWhisper = presenceID;
		NWB.lastWhisperType = "bnet";
	end
end)

--Flight paths.
local doCheckLeaveFlghtPath = false;
hooksecurefunc("TakeTaxiNode", function(...)
	doCheckLeaveFlghtPath = true;
    --Give it a few seconds to get on the taxi.
    C_Timer.After(5, function()
		NWB.checkLeaveFlghtPath();
		--Wipe felwood songflower detected players when leaving.
		NWB.detectedPlayers = {};
	end)
	NWB:sendData("YELL");
end)

--Loop this func till flight path is left.
function NWB.checkLeaveFlghtPath()
    local isOnFlightPath = UnitOnTaxi("player");
    if (not isOnFlightPath) then
    	doCheckLeaveFlghtPath = false;
    	--Send data to people close when dismounting a flightpath.
    	NWB:sendData("YELL");
    end
    if (doCheckLeaveFlghtPath) then
    	C_Timer.After(2, function()
			NWB.checkLeaveFlghtPath();
		end)
	end
end

--Convert seconds to a readable format.
function NWB:getTimeString(seconds, countOnly, short)
	local timecalc = 0;
	if (countOnly) then
		timecalc = seconds;
	else
		timecalc = seconds - time();
	end
	local d = math.floor((timecalc % (86400*365)) / 86400);
	local h = math.floor((timecalc % 86400) / 3600);
	local m = math.floor((timecalc % 3600) / 60);
	local s = math.floor((timecalc % 60));
	local space = "";
	if (LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW) then
		space = " ";
	end
	if (short) then
		if (d == 1 and h == 0) then
			return d .. L["dayShort"];
		elseif (d == 1) then
			return d .. L["dayShort"] .. space .. h .. L["hourShort"];
		end
		if (d > 1 and h == 0) then
			return d .. L["dayShort"];
		elseif (d > 1) then
			return d .. L["dayShort"] .. space .. h .. L["hourShort"];
		end
		if (h == 1 and m == 0) then
			return h .. L["hourShort"];
		elseif (h == 1) then
			return h .. L["hourShort"] .. space .. m .. L["minuteShort"];
		end
		if (h > 1 and m == 0) then
			return h .. L["hourShort"];
		elseif (h > 1) then
			return h .. L["hourShort"] .. space .. m .. L["minuteShort"];
		end
		if (m == 1 and s == 0) then
			return m .. L["minuteShort"];
		elseif (m == 1) then
			return m .. L["minuteShort"] .. space .. s .. L["secondShort"];
		end
		if (m > 1 and s == 0) then
			return m .. L["minuteShort"];
		elseif (m > 1) then
			return m .. L["minuteShort"] .. space .. s .. L["secondShort"];
		end
		--If no matches it must be seconds only.
		return s .. L["secondShort"];
	else
		if (d == 1 and h == 0) then
			return d .. " " .. L["day"];
		elseif (d == 1) then
			return d .. " " .. L["day"] .. " " .. h .. " " .. L["hours"];
		end
		if (d > 1 and h == 0) then
			return d .. " " .. L["days"];
		elseif (d > 1) then
			return d .. " " .. L["days"] .. " " .. h .. " " .. L["hours"];
		end
		if (h == 1 and m == 0) then
			return h .. " " .. L["hour"];
		elseif (h == 1) then
			return h .. " " .. L["hour"] .. " " .. m .. " " .. L["minutes"];
		end
		if (h > 1 and m == 0) then
			return h .. " " .. L["hours"];
		elseif (h > 1) then
			return h .. " " .. L["hours"] .. " " .. m .. " " .. L["minutes"];
		end
		if (m == 1 and s == 0) then
			return m .. " " .. L["minute"];
		elseif (m == 1) then
			return m .. " " .. L["minute"] .. " " .. s .. " " .. L["seconds"];
		end
		if (m > 1 and s == 0) then
			return m .. " " .. L["minutes"];
		elseif (m > 1) then
			return m .. " " .. L["minutes"] .. " " .. s .. " " .. L["seconds"];
		end
		--If no matches it must be seconds only.
		return s .. " " .. L["seconds"];
	end
end

--Returns am/pm and lt/st format.
function NWB:getTimeFormat(timeStamp, fullDate)
	if (NWB.db.global.timeStampZone == "server") then
		--This is ugly and shouldn't work, and probably doesn't work on some time difference.
		--Need a better solution but all I can get from the wow client in server time is hour:mins, not date or full timestamp.
		local data = date("*t", GetServerTime());
		local localHour, localMin = data.hour, data.min;
		local serverHour, serverMin = GetGameTime();
		local localSecs = (localMin*60) + ((localHour*60)*60);
		local serverSecs = (serverMin*60) + ((serverHour*60)*60);
		local diff = localSecs - serverSecs;
		--local diff = difftime(localSecs - serverSecs);
		local serverTime = 0;
		--if (localHour < serverHour) then
		--	timeStamp = timeStamp - (diff + 86400);
		--else
			timeStamp = timeStamp - diff;
		--end
	end
	if (NWB.db.global.timeStampFormat == 12) then
		--Strip leading zero and convert to lowercase am/pm.
		if (fullDate) then
			return date("%a %b %d", timeStamp) .. " " .. gsub(string.lower(date("%I:%M%p", timeStamp)), "^0", "");
		else
			return gsub(string.lower(date("%I:%M%p", timeStamp)), "^0", "");
		end
	else
		if (fullDate) then
			local dateFormat = NWB:getRegionTimeFormat();
			return date(dateFormat .. " %H:%M:%S", timeStamp);
		else
		 return date("%H:%M:%S", timeStamp);
		end
	end
end

--Date 24h string format based on region, won't be 100% accurate but better than %x returning US format for every region like it does now.
function NWB:getRegionTimeFormat()
	local dateFormat = "%x";
	local region = GetCurrentRegion();
	if (NWB.realm == "Arugal" or NWB.realm == "Felstriker" or NWB.realm == "Remulos" or NWB.realm == "Yojamba") then
		--OCE
		dateFormat = "%d/%m/%y";
	elseif (NWB.realm == "Sulthraze" or NWB.realm == "Loatheb") then
		--Brazil/Latin America.
		dateFormat = "%d/%m/%y";
	elseif (region == 1) then
		--US.
		dateFormat = "%m/%d/%y";
	elseif (region == 2 or region == 4 or region == 5) then
		--Korea, Taiwan, Chinda all same format.
		dateFormat = "%y/%m/%d";
	elseif (region == 3) then
		--EU.
		dateFormat = "%d/%m/%y";
	end
	return dateFormat;
end

--Accepts both types of RGB.
function NWB:RGBToHex(r, g, b)
	r = tonumber(r);
	g = tonumber(g);
	b = tonumber(b);
	--Check if whole numbers.
	if (r == math.floor(r) and g == math.floor(g) and b == math.floor(b)) then
		r = r <= 255 and r >= 0 and r or 0;
		g = g <= 255 and g >= 0 and g or 0;
		b = b <= 255 and b >= 0 and b or 0;
		return string.format("%02x%02x%02x", r, g, b);
	else
		return string.format("%02x%02x%02x", r*255, g*255, b*255);
	end
end

--English buff names, we check both english and locale names for buff durations just to be sure in untested locales.
local englishBuffs = {
	[1] = "Warchief's Blessing",
	[2] = "Rallying Cry of the Dragonslayer",
	[3] = "Songflower Serenade",
	[4] = "Spirit of Zandalar"
}

--Get seconds left on a buff by name.
function NWB:getBuffDuration(buff, englishID)
	for i = 1, 32 do
		local name, _, _, _, _, expirationTime = UnitBuff("player", i);
		if ((name and name == buff) or (englishID and name == englishBuffs[englishID])) then
			return expirationTime - GetTime();
		end
	end
	return 0;
end

--Check if player is in guild, accepts full realm name and normalized.
function NWB:isPlayerInGuild(who, onlineOnly)
	if (not IsInGuild()) then
		return;
	end
	GuildRoster();
	local numTotalMembers = GetNumGuildMembers();
	local normalizedWho = string.gsub(who, " ", "");
	normalizedWho = string.gsub(normalizedWho, "'", "");
	local me = UnitName("player") .. "-" .. GetRealmName();
	local normalizedMe = UnitName("player") .. "-" .. GetNormalizedRealmName();
	if (who == me or who == normalizedMe) then
		return true;
	end
	for i = 1, numTotalMembers do
		local name, _, _, _, _, _, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i);
		if (onlineOnly) then
			if (name and (name == who or name == normalizedWho) and online and not isMobile) then
				return true;
			end
		else
			if (name and (name == who or name == normalizedWho)) then
				return true;
			end
		end
	end
end

--PHP explode type function.
function NWB:explode(div, str, count)
	if (div == '') then
		return false;
	end
	local pos,arr = 0,{};
	local index = 0;
	for st, sp in function() return string.find(str, div, pos, true) end do
		index = index + 1;
 		table.insert(arr, string.sub(str, pos, st-1));
		pos = sp + 1;
		if (count and index == count) then
			table.insert(arr, string.sub(str, pos));
			return arr;
		end
	end
	table.insert(arr, string.sub(str, pos));
	return arr;
end

--Iterate table keys in alphabetical order.
function NWB:pairsByKeys(t, f)
	local a = {};
	for n in pairs(t) do
		table.insert(a, n);
	end
	table.sort(a, f);
	local i = 0;
	local iter = function()
		i = i + 1;
		if (a[i] == nil) then
			return nil;
		else
			return a[i], t[a[i]];
		end
	end
	return iter;
end

--Strip escape strings from chat msgs.
function NWB:stripColors(str)
	local escapes = {
    	["|c%x%x%x%x%x%x%x%x"] = "", --Color start.
    	["|r"] = "", --Color end.
    	--["|H.-|h(.-)|h"] = "%1", --Links.
    	["|T.-|t"] = "", --Textures.
    	["{.-}"] = "", --Raid target icons.
	};
	if (str) then
    	for k, v in pairs(escapes) do
        	str = gsub(str, k, v);
    	end
    end
    return str;
end

function NWB:debug(...)
	if (NWB.isDebug) then
		if (type(...) == "table") then
			UIParentLoadAddOn('Blizzard_DebugTools');
			--DevTools_Dump(...);
    		DisplayTableInspectorWindow(...);
    	else
			print("NWBDebug:", ...);
		end
	end
end

SLASH_NWBCMD1, SLASH_NWBCMD2, SLASH_NWBCMD3, SLASH_NWBCMD4, SLASH_NWBCMD5, SLASH_NWBCMD6 
		= '/nwb', '/novaworldbuff', '/novaworldbuffs', '/wb', '/worldbuff', '/worldbuffs';
function SlashCmdList.NWBCMD(msg, editBox)
	local cmd, arg;
	if (msg) then
		msg = string.lower(msg);
		cmd, arg = strsplit(" ", msg, 2);
		if (arg) then
			msg = cmd;
		end
	end
	if (msg == "show" or msg == "buff" or msg == "buffs") then
		NWB:openBuffListFrame();
		return;
	end
	if (msg == "group" or msg == "team") then
		msg = "party";
	end
	if (msg == "map") then
		WorldMapFrame:Show();
		if (NWB.faction == "Alliance") then
			WorldMapFrame:SetMapID(1453);
		else
			WorldMapFrame:SetMapID(1454);
		end
		return;
	end
	if (msg == "options" or msg == "option" or msg == "config" or msg == "menu") then
		--Opening the frame needs to be run twice to avoid a bug.
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
		--Hack to fix the issue of interface options not opening to menus below the current scroll range.
		--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
		local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
		if (min < max) then
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
		end
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
	elseif (msg ~= nil and msg ~= "") then
		NWB:print(NWB:getShortBuffTimers(nil, arg), msg);
	else
		NWB:printBuffTimers();
		if (NWB.isLayered) then
			NWB:openLayerFrame();
		end
	end
end

---===== Most of these are now disabled, only DBM is left =====---
---Parse other world buff addons for increased accuracy and to spread more data around.
---Thanks to all authors for their work.
---If any of these authors ask me to stop parsing their comms I'll remove it.
function NWB:registerOtherAddons()
	self:RegisterComm("D4C");
end

--DBM.
local dbmLastRend, dbmLastOny, dbmLastNef, dbmLastZan = 0, 0, 0, 0;
function NWB:parseDBM(prefix, msg, channel, sender)
	if (NWB.isLayered) then
		--We need the NPC GUIDs for buff setting on layered realms so exclude DBM from those realms.
		return;
	end
	--Strings.
	--D4C WBA	rendBlackhand	Horde	Warchief's Blessing	59 GUILD
	--D4C WBA	Onyxia	Horde	Rallying Cry of the Dragonslayer	15 GUILD
	--D4C WBA	Nefarian	Horde	Rallying Cry of the Dragonslayer	17 GUILD
	--Same exact string comes from DBM for both yell msgs so disabled timer delay for now. SendWorldSync(self, "WBA", "Zandalar\tBoth\t"..spellName.."\t12")
	if (string.match(msg, "rendBlackhand") 
			and (string.match(msg, "Warchief's Blessing") or string.match(msg, L["Warchief's Blessing"]))) then
		NWB:doFirstYell("rend");
		--6 seconds between DBM comm (first npc yell) and rend buff drop.
		if (GetServerTime() - dbmLastRend > 30) then
			C_Timer.After(7, function()
				NWB:setRendBuff("dbm", sender);
			end)
			dbmLastRend = GetServerTime();
		end
	end
	--I think maybe DBM is sending ony buff msg sometimes for nef, needs more testing.
	if (string.match(msg, "Onyxia") 
			and (string.match(msg, "Rallying Cry of the Dragonslayer") or string.match(msg, L["Rallying Cry of the Dragonslayer"]))) then
		NWB:doFirstYell("ony");
		--14 seconds between DBM comm (first npc yell) and buff drop.
		if (GetServerTime() - dbmLastOny > 30) then
			C_Timer.After(15, function()
				NWB:setOnyBuff("dbm", sender);
			end)
			dbmLastOny = GetServerTime();
		end
	end
	if (string.match(msg, "Nefarian") 
			and (string.match(msg, "Rallying Cry of the Dragonslayer") or string.match(msg, L["Rallying Cry of the Dragonslayer"]))) then
		NWB:doFirstYell("nef");
		--15 seconds between DBM comm (first npc yell) and buff drop.
		if (GetServerTime() - dbmLastNef > 30) then
			C_Timer.After(16, function()
				NWB:setNefBuff("dbm", sender);
			end)
			dbmLastNef = GetServerTime();
		end
	end
	if (string.match(msg, "Zandalar") 
			and (string.match(msg, "Spirit of Zandalar") or string.match(msg, L["Spirit of Zandalar"]))) then
		NWB:doFirstYell("zan");
		NWB:debug("dbm doing zand");
		--27ish seconds between first zan yell and buff applied if on island.
		--45ish seconds between first zan yell and buff applied if in booty bay.
		--Call it 30.
		if (GetServerTime() - dbmLastRend > 50) then
			C_Timer.After(30, function()
				NWB:setZanBuff("dbm", sender);
			end)
			dbmLastZan = GetServerTime();
		end
	end
end

---TODO
--Add some sounds.

---=======---
---Felwood---
---=======---

function NWB:setSongFlowers()
	NWB.songFlowers = {
		--Songflowers in order from north to south.						--Coords taken from NWB.dragonLib:GetPlayerZonePosition().
		["flower1"] = {x = 63.9, y = 6.1, subZone = L["North Felpaw Village"]}, --x 63.907248382611, y 6.0921582958694
		["flower2"] = {x = 55.8, y = 10.4, subZone = L["West Felpaw Village"]}, --x 55.80811845313, y 10.438248169009
		["flower3"] = {x = 50.6, y = 13.9, subZone = L["North of Irontree Woods"]}, --x 50.575074328086, y 13.918245916971
		["flower4"] = {x = 63.3, y = 22.6, subZone = L["Talonbranch Glade"]}, -- x 63.336814849559, y 22.610425663249
		["flower5"] = {x = 40.1, y = 44.4, subZone = L["Shatter Scar Vale"]}, --x 40.142029982253, y 44.353905770542
		["flower6"] = {x = 34.3, y = 52.2, subZone = L["Bloodvenom Post"]}, --x 34.345508209303, y 52.179993391643
		["flower7"] = {x = 40.1, y = 56.5, subZone = L["East of Jaedenar"]}, --x 40.142029982253, y 56.523472021355
		["flower8"] = {x = 48.3, y = 75.7, subZone = L["North of Emerald Sanctuary"]}, -- x 48.260292045699, y 75.650435262435
		["flower9"] = {x = 45.9, y = 85.2, subZone = L["West of Emerald Sanctuary"]}, --x 45.942030228517, y 85.219126632059
		["flower10"] = {x = 52.9, y = 87.8, subZone = L["South of Emerald Sanctuary"]}, --x 52.893336145267, y 87.825217631218
	}
	if (NWB.faction == "Horde") then
		NWB.songFlowers.flower6.subZone = L["Bloodvenom Post"] .. " FP";
	end
end

NWB.tubers = {
	--Whipper root in order from north to south.
	--Taken from wowhead, could be some missing.
	["tuber1"] = {x = 49.5, y = 12.2, subZone = L["North of Irontree Woods"]},
	["tuber2"] = {x = 50.6, y = 18.2, subZone = L["Irontree Woods"]},
	["tuber3"] = {x = 40.7, y = 19.2, subZone = L["West of Irontree Woods"]},
	["tuber4"] = {x = 43.0, y = 46.9, subZone = L["Bloodvenom Falls"]},
	["tuber5"] = {x = 34.1, y = 60.3, subZone = L["Jaedenar"]},
	["tuber6"] = {x = 40.2, y = 85.2, subZone = L["West of Emerald Sanctuary"]},
};

NWB.dragons = {
	--Night dragon in order from north to south.
	--Taken from wowhead, could be some missing.
	["dragon1"] = {x = 42.5, y = 13.9, subZone = L["North-West of Irontree Woods"]},
	["dragon2"] = {x = 50.6, y = 30.5, subZone = L["South of Irontree Woods"]},
	["dragon3"] = {x = 35.1, y = 59.0, subZone = L["Jaedenar"]},
	["dragon4"] = {x = 40.7, y = 78.3, subZone = L["West of Emerald Sanctuary"]},
};

--Debug.
function NWB:resetSongFlowers()
	if (NWB.db.global.resetSongflowers) then
		for k, v in pairs(NWB.songFlowers) do
			NWB.data[k] = 0;
		end
		NWB.db.global.resetSongflowers = false;
	end
end

SLASH_NWBSFCMD1, SLASH_NWBSFCMD2, SLASH_NWBSFCMD3, SLASH_NWBSFCMD4 = '/sf', '/sfs', '/songflower', '/songflowers';
function SlashCmdList.NWBSFCMD(msg, editBox)
	if (msg) then
		msg = string.lower(msg);
	end
	if (msg == "map") then
		WorldMapFrame:Show();
		WorldMapFrame:SetMapID(1448);
		return;
	end
	if (msg == "options" or msg == "option" or msg == "config" or msg == "menu") then
		--Opening the frame needs to be run twice to avoid a bug.
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
		--Hack to fix the issue of interface options not opening to menus below the current scroll range.
		--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
		local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
		if (min < max) then
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
		end
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
		return;
	end
	local string = L["Songflower"] .. ":";
	local found;
	for k, v in pairs(NWB.songFlowers) do
		local time = (NWB.data[k] + 1500) - GetServerTime();
		if (time > 0) then
			local minutes = string.format("%02.f", math.floor(time / 60));
    		local seconds = string.format("%02.f", math.floor(time - minutes * 60));
			string = string .. " (" .. v.subZone .. " " .. minutes .. "m" .. seconds .. "s)";
			found = true;
  		end
	end
	if (not found) then
		string = string .. " " .. L["noActiveTimers"] .. ".";
	end
	if (msg ~= nil and msg ~= "") then
		NWB:print(string, msg);
	else
		NWB:print(string);
	end
end

NWB.detectedPlayers = {};
local f = CreateFrame("Frame");
f:RegisterEvent("PLAYER_TARGET_CHANGED");
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
f:RegisterEvent("PLAYER_ENTERING_WORLD");
f:RegisterEvent("CHAT_MSG_LOOT");
f:SetScript('OnEvent', function(self, event, ...)
	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
		local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, 
				destName, destFlags, destRaidFlags, _, spellName = CombatLogGetCurrentEventInfo();
		if ((subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH") and spellName == L["Songflower Serenade"]) then
			if (destName == UnitName("player")) then
				--If buff is ours we'll validate it's a new buff incase we logon beside a songflower with the buff.
				local expirationTime = NWB:getBuffDuration(L["Songflower Serenade"], 3)
				if (expirationTime >= 3599) then
					local closestFlower = NWB:getClosestSongflower();
					if (NWB.data[closestFlower]) then
						NWB:songflowerPicked(closestFlower);
					end
				end
			elseif (not NWB.db.global.mySongflowerOnly) then
				--If buff is not ours then we'll hope they didn't logon beside us at a songflower and set it.
				--There's an option to make it only set if it's our buff in /wb config.
				--I'll look for a way to tell if a player just entered our view or logged on later and check if buff is new that way.
				local closestFlower = NWB:getClosestSongflower();
				if (NWB.data[closestFlower]) then
					NWB:songflowerPicked(closestFlower, destName);
				end
			end
		end
		if (zone == 1448) then
			if (sourceName) then
				NWB.detectedPlayers[sourceName] = GetServerTime();
			elseif (destName) then
				NWB.detectedPlayers[destName] = GetServerTime();
			end
		end
	elseif (event == "PLAYER_TARGET_CHANGED") then
		local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
		if (zone == 1448) then
			local name = UnitName("target");
			if (name) then
				NWB.detectedPlayers[UnitName("target")] = GetServerTime();
			end
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		--Wipe felwood songflower detected players when leaving, it costs very little to just wipe this on every zone.
		NWB.detectedPlayers = {};
	elseif (event == "CHAT_MSG_LOOT") then
		local msg = ...;
		local name, otherPlayer;
		--Self receive multiple loot "You receive loot: [Item]x2"
		local itemLink, amount = string.match(msg, string.gsub(string.gsub(LOOT_ITEM_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)"));
    	if (not itemLink) then
    		--Self receive single loot "You receive loot: [Item]"
    		itemLink = msg:match(LOOT_ITEM_SELF:gsub("%%s", "(.+)"));
    		if (not itemLink) then
    			--Self receive multiple item "You receive item: [Item]x2"
    			itemLink, amount = string.match(msg, string.gsub(string.gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)"));
    			--itemLink = msg:match(LOOT_ITEM_SELF:gsub("%%s", "(.+)"));
    			if (not itemLink) then
    	 			--Self receive single item "You receive item: [Item]"
    				itemLink = msg:match(LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.+)"));
    			end
    		end
    	end
		--If no matches for self loot then check other player loot msgs.
		if (not itemLink) then
    		--Other player receive multiple loot "Otherplayer receives loot: [Item]x2"
    		otherPlayer, itemLink, amount = string.match(msg, string.gsub(string.gsub(LOOT_ITEM_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)"));
    		if (not itemLink) then
    			--Other player receive single loot "Otherplayer receives loot: [Item]"
    			otherPlayer, itemLink = msg:match("^" .. LOOT_ITEM:gsub("%%s", "(.+)"));
    			if (not itemLink) then
    				--Other player loot multiple item "Otherplayer receives item: [Item]x2"
    				otherPlayer, itemLink, amount = string.match(msg, string.gsub(string.gsub(LOOT_ITEM_PUSHED_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)"));
    				if (not itemLink) then
    	 				--Other player receive single item "Otherplayer receives item: [Item]"
    					otherPlayer, itemLink = msg:match("^" .. LOOT_ITEM_PUSHED:gsub("%%s", "(.+)"));
    				end
    			end
    		end
    	end
    	--otherPlayer is basically a waste of time here, since it's a pushed item not a looted item the team doesn't see it be looted.
    	--But I'll keep my looted item function in tact anyway, maybe I'll track some other item here in the future.
    	if (itemLink) then
    		local item = Item:CreateFromItemLink(itemLink);
			if (item) then
				local itemID = item:GetItemID();
				if (itemID and itemID == 11951) then
					local closestTuber = NWB:getClosestTuber();
					if (NWB.data[closestTuber]) then
						NWB:tuberPicked(closestTuber, otherPlayer);
					end
				elseif (itemID and itemID == 11952) then
					local closestDragon = NWB:getClosestDragon();
					if (NWB.data[closestDragon]) then
						NWB:dragonPicked(closestDragon, otherPlayer);
					end
				end
			end
    	end
	end
end)

--Check tooltips for players while waiting at the songflower, doesn't really matter if it adds non-player stuff, it gets wiped when leaving.
--This shouldn't be done OnUpdate but it will do for now and only happens in felwood.
--Not sure how to detect tooltip changed, OnShow doesn't work when tooltip changes before fading out.
--This whole thing is pretty ugly right now.
GameTooltip:HookScript("OnUpdate", function()
	--This may need some more work to handle custom tooltip addons like elvui etc.
	local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone == 1448) then
		for i = 1, GameTooltip:NumLines() do
			local line =_G["GameTooltipTextLeft"..i];
			local text = line:GetText();
			if (text and text ~= nil and text ~= "") then
				local name;
				if (string.match(text, " ")) then
					name = NWB:stripColors(string.match(text, "%s(%S+)$"));
				else
					name = NWB:stripColors(text);
				end
				if (name) then
					NWB.detectedPlayers[name] = GetServerTime();
				end
			end
			--Iterate first line only.
			return;
		end
	end
end)

--I record some data to try and make sure if another player picked flower infront of us it's valid and not an old buff.
--Check if player has been seen before (avoid logon buff aura gained events).
--Check if there is already a valid timer for the songflower (they should never be reset except server restart?)
local pickedTime = 0;
function NWB:songflowerPicked(type, otherPlayer)
	local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		--We're not in felwood.
		return;
	end
	--If other player has not been seen before it may be someone logging in with the buff.
	if (otherPlayer and not NWB.detectedPlayers[otherPlayer]) then
		NWB:debug("Previously unseen player with buff:", otherPlayer);
		return;
	end
	if (otherPlayer and (GetServerTime() - NWB.detectedPlayers[otherPlayer] > 1500)) then
		NWB:debug("Player seen too long ago:", otherPlayer);
		return;
	end
	if ((GetServerTime() - pickedTime) > 5) then
		--Validate only if another player, we already check ours is valid by duration check.
		if (otherPlayer and NWB.data[type] > (GetServerTime() - 1500)) then
			NWB:debug("Trying to overwrite a valid songflower timer.");
			return;
		end
		local timestamp = GetServerTime();
		if (NWB:validateTimestamp(timestamp)) then
			NWB.data[type] = timestamp;
			if (IsInGuild() and NWB.db.global.guildSongflower and not NWB.db.global.disableAllGuildMsgs) then
				SendChatMessage(string.format(L["songflowerPicked"], NWB.songFlowers[type].subZone), "guild");
			end
			NWB:sendData("GUILD");
			NWB:sendData("YELL");
		end
		pickedTime = timestamp;
	end
end

local tuberPickedTime = 0;
function NWB:tuberPicked(type, otherPlayer)
	local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		--We're not in felwood.
		return;
	end
	if ((GetServerTime() - tuberPickedTime) > 5) then
		if (NWB.data[type] > (GetServerTime() - 1500)) then
			NWB:debug("Trying to overwrite a valid tuber timer.");
			return;
		end
		local timestamp = GetServerTime();
		if (NWB:validateTimestamp(timestamp)) then
			NWB.data[type] = timestamp;
			NWB:sendData("GUILD");
			NWB:sendData("YELL");
		end
		tuberPickedTime = timestamp;
	end
end

local dragonPickedTime = 0;
function NWB:dragonPicked(type, otherPlayer)
	local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		--We're not in felwood.
		return;
	end
	if ((GetServerTime() - dragonPickedTime) > 5) then
		if (NWB.data[type] > (GetServerTime() - 1500)) then
			NWB:debug("Trying to overwrite a valid dragon timer.");
			return;
		end
		local timestamp = GetServerTime();
		if (NWB:validateTimestamp(timestamp)) then
			NWB.data[type] = timestamp;
			NWB:sendData("GUILD");
			NWB:sendData("YELL");
		end
		dragonPickedTime = timestamp;
	end
end

--Gets which songflower we are closest to, if we are actually beside one.
function NWB:getClosestSongflower()
	local x, y, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		--We're not in felwood.
		return;
	end
	for k, v in pairs(NWB.songFlowers) do
		--The distance returned by this is actually much further than yards like is specifed on the addon page.
		--It returns 2 yards when I'm more like 50 yards away, it's good enough for this check anyway, songflowers aren't close together.
		--Seems it returns the distance in coords you are away not the distance in yards? 1 yard is smaller than x = 1.0 coord?
		local distance = NWB.dragonLib:GetWorldDistance(zone, x*100, y*100, v.x, v.y);
		if (distance <= 2) then
			return k;
		end
	end
end

function NWB:getClosestTuber()
	local x, y, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		return;
	end
	for k, v in pairs(NWB.tubers) do
		local distance = NWB.dragonLib:GetWorldDistance(zone, x*100, y*100, v.x, v.y);
		if (distance <= 2) then
			return k;
		end
	end
end

function NWB:getClosestDragon()
	local x, y, zone = NWB.dragonLib:GetPlayerZonePosition();
	if (zone ~= 1448) then
		return;
	end
	for k, v in pairs(NWB.dragons) do
		local distance = NWB.dragonLib:GetWorldDistance(zone, x*100, y*100, v.x, v.y);
		if (distance <= 2) then
			return k;
		end
	end
end

--Update timers for Felwood worldmap when the map is open.
function NWB:updateFelwoodWorldmapMarker(type)
	--Seconds left.
	local time = (NWB.data[type] + 1500) - GetServerTime();
	if (time > 0) then
		--If timer is less than 25 minutes old then return time left.
    	local minutes = string.format("%02.f", math.floor(time / 60));
    	local seconds = string.format("%02.f", math.floor(time - minutes * 60));
    	_G[type .. "NWB"].timerFrame:Show();
    	local tooltipText = "|CffDEDE42" .. _G[type .. "NWB"].name .. "|r\n" .. _G[type .. "NWB"].subZone .. "\n"
    			.. NWB:getTimeFormat(NWB.data[type] + 1500) .. " " .. L["spawn"];
    	_G[type .. "NWB"].tooltip.fs:SetText(tooltipText);
		_G[type .. "NWB"].tooltip:SetWidth(_G[type .. "NWB"].tooltip.fs:GetStringWidth() + 18);
		_G[type .. "NWB"].tooltip:SetHeight(_G[type .. "NWB"].tooltip.fs:GetStringHeight() + 12);
    	return minutes .. ":" .. seconds;
  	end
  	_G[type .. "NWB"].tooltip.fs:SetText("|CffDEDE42" .. _G[type .. "NWB"].name .. "|r\n" .. _G[type .. "NWB"].subZone);
	_G[type .. "NWB"].tooltip:SetWidth(_G[type .. "NWB"].tooltip.fs:GetStringWidth() + 18);
	_G[type .. "NWB"].tooltip:SetHeight(_G[type .. "NWB"].tooltip.fs:GetStringHeight() + 12);
  	_G[type .. "NWB"].timerFrame:Hide();
	return "";
end

--Update timer for minimap.
function NWB:updateFelwoodMinimapMarker(type)
	--Seconds left.
	local time = (NWB.data[type] + 1500) - GetServerTime();
	if (time > 0) then
		--If timer is less than 25 minutes old then return time left.
    	local minutes = string.format("%02.f", math.floor(time / 60));
    	local seconds = string.format("%02.f", math.floor(time - minutes * 60));
    	_G[type .. "NWBMini"].timerFrame:Show();
    	local tooltipText = "|CffDEDE42" .. _G[type .. "NWB"].name .. "|r\n" .. _G[type .. "NWB"].subZone .. "\n"
    			.. NWB:getTimeFormat(NWB.data[type] + 1500) .. " " .. L["spawn"];
    	_G[type .. "NWBMini"].tooltip.fs:SetText(tooltipText);
    	_G[type .. "NWBMini"].tooltip:SetWidth(_G[type .. "NWBMini"].tooltip.fs:GetStringWidth() + 9);
		_G[type .. "NWBMini"].tooltip:SetHeight(_G[type .. "NWBMini"].tooltip.fs:GetStringHeight() + 9);
    	return minutes .. ":" .. seconds;
  	end
	_G[type .. "NWBMini"].tooltip.fs:SetText("|CffDEDE42" .. _G[type .. "NWB"].name .. "|r\n" .. _G[type .. "NWB"].subZone);
	_G[type .. "NWBMini"].tooltip:SetWidth(_G[type .. "NWBMini"].tooltip.fs:GetStringWidth() + 9);
	_G[type .. "NWBMini"].tooltip:SetHeight(_G[type .. "NWBMini"].tooltip.fs:GetStringHeight() + 9);
	_G[type .. "NWBMini"].timerFrame:Hide();
	return L["noTimer"];
end

function NWB:createSongflowerMarkers()
	local iconLocation = "Interface\\Icons\\spell_holy_mindvision";
	for k, v in pairs(NWB.songFlowers) do
		--Worldmap marker.
		local obj = CreateFrame("Frame", k .. "NWB", WorldMapFrame);
		obj.type = k;
		obj.name = L["Songflower"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(15, 15);
		--World map tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, -36);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 12);
		obj.tooltip.fs:SetText("|CffDEDE42" .. L["Songflower"] .. "|r\n" .. v.subZone);
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		obj.tooltip:Hide();
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrame", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", obj, "CENTER", 0, 20);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 13);
		obj.timerFrame:SetWidth(42);
		obj.timerFrame:SetHeight(24);
		obj:SetScript("OnUpdate", function(self)
			--Update timer when map is open.
			obj.timerFrame.fs:SetText(NWB:updateFelwoodWorldmapMarker(obj.type));
			--obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 15);
			--obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		--Make it act like pin is the parent and not WorldMapFrame.
		obj:SetScript("OnHide", function(self)
			obj.timerFrame:Hide();
		end)
		obj:SetScript("OnShow", function(self)
			obj.timerFrame:Show();
		end)
		obj:SetScript("OnMouseDown", function(self)
			if (IsShiftKeyDown()) then
				local time = (NWB.data[obj.type] + 1500) - GetServerTime();
				if (time > 0) then
					local msg = string.format(L["singleSongflowerMsg"], NWB.songFlowers[obj.type].subZone, NWB:getTimeString(time, true));
					SendChatMessage("[WorldBuffs] " .. msg .. " (" .. NWB.songFlowers[obj.type].x .. ", " .. NWB.songFlowers[obj.type].y .. ")", "guild");
				else
					NWB:print(L["noTimer"] .. " (" .. NWB.songFlowers[obj.type].subZone .. ").");
				end
			else
				NWB:openBuffListFrame();
			end
		end)
		
		--Minimap marker.
		local obj = CreateFrame("FRAME", k .. "NWBMini");
		obj.type = k;
		obj.name = L["Songflower"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(12, 12);
		--Minimap tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", MinimMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, 18);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 8.5);
		obj.tooltip.fs:SetText("00:00");
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 9);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 9);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrameMini", obj, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", 0, 18);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0.5);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 12);
		obj.timerFrame.fs:SetText("00:00");
		obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
		obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		--obj.tooltip:SetScript("OnUpdate", function(self)
		--	--Update timer when icon is hovered over and tooltip is shown.
		--	obj.tooltip.fs:SetText(NWB:updateFelwoodMinimapMarker(obj.type));
		--	obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 16);
		--	obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 11);
		--end)
		--Changed to show minimap timer awlways instead of on hover (if timer is active).
		obj:SetScript("OnUpdate", function(self)
			--Update timer when icon is hovered over and tooltip is shown.
			--obj.tooltip.fs:SetText(NWB:updateFelwoodMinimapMarker(obj.type));
			--obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 14);
			--obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 9);
			obj.timerFrame.fs:SetText(NWB:updateFelwoodMinimapMarker(obj.type));
			obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
			obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		obj.tooltip:Hide();
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
	end
end

function NWB:createTuberMarkers()
	local iconLocation = "Interface\\Icons\\inv_misc_food_55";
	for k, v in pairs(NWB.tubers) do
		--Worldmap marker.
		local obj = CreateFrame("Frame", k .. "NWB", WorldMapFrame);
		obj.type = k;
		obj.name = L["Whipper Root Tuber"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(12, 12);
		--World map tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, -36);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 12);
		obj.tooltip.fs:SetText("|CffDEDE42" .. L["Songflower"] .. "|r\n" .. v.subZone);
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		obj.tooltip:Hide();
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrame", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", obj, "CENTER", 0, 17);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 11);
		obj.timerFrame:SetWidth(38);
		obj.timerFrame:SetHeight(20);
		obj:SetScript("OnUpdate", function(self)
			--Update timer when map is open.
			obj.timerFrame.fs:SetText(NWB:updateFelwoodWorldmapMarker(obj.type));
			--obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 15);
			--obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		--Make it act like pin is the parent and not WorldMapFrame.
		obj:SetScript("OnHide", function(self)
			obj.timerFrame:Hide();
		end)
		obj:SetScript("OnShow", function(self)
			obj.timerFrame:Show();
		end)
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
		
		--Minimap marker.
		local obj = CreateFrame("FRAME", k .. "NWBMini");
		obj.type = k;
		obj.name = L["Whipper Root Tuber"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(12, 12);
		--Minimap tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", MinimMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, 18);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 8.5);
		obj.tooltip.fs:SetText("00:00");
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 9);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 9);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrameMini", obj, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", 0, 18);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0.5);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 12);
		obj.timerFrame.fs:SetText("00:00");
		obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
		obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		--Changed to show minimap timer awlways instead of on hover (if timer is active).
		obj:SetScript("OnUpdate", function(self)
			--Update timer when icon is hovered over and tooltip is shown.
			obj.timerFrame.fs:SetText(NWB:updateFelwoodMinimapMarker(obj.type));
			obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
			obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		obj.tooltip:Hide();
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
	end
end

function NWB:createDragonMarkers()
	local iconLocation = "Interface\\Icons\\inv_misc_food_45";
	for k, v in pairs(NWB.dragons) do
		--Worldmap marker.
		local obj = CreateFrame("Frame", k .. "NWB", WorldMapFrame);
		obj.type = k;
		obj.name = L["Night Dragon's Breath"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(12, 12);
		--World map tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, -36);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 12);
		obj.tooltip.fs:SetText("|CffDEDE42" .. L["Songflower"] .. "|r\n" .. v.subZone);
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		obj.tooltip:Hide();
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrame", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", obj, "CENTER", 0, 17);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 11);
		obj.timerFrame:SetWidth(38);
		obj.timerFrame:SetHeight(20);
		obj:SetScript("OnUpdate", function(self)
			--Update timer when map is open.
			obj.timerFrame.fs:SetText(NWB:updateFelwoodWorldmapMarker(obj.type));
			--obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 15);
			--obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		--Make it act like pin is the parent and not WorldMapFrame.
		obj:SetScript("OnHide", function(self)
			obj.timerFrame:Hide();
		end)
		obj:SetScript("OnShow", function(self)
			obj.timerFrame:Show();
		end)
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
		
		--Minimap marker.
		local obj = CreateFrame("FRAME", k .. "NWBMini");
		obj.type = k;
		obj.name = L["Night Dragon's Breath"];
		obj.subZone = v.subZone;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(iconLocation);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(12, 12);
		--Minimap tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "Tooltip", MinimMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, 18);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 8.5);
		obj.tooltip.fs:SetText("00:00");
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 9);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 9);
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "TimerFrameMini", obj, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", 0, 18);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0.5);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 12);
		obj.timerFrame.fs:SetText("00:00");
		obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
		obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		--Changed to show minimap timer awlways instead of on hover (if timer is active).
		obj:SetScript("OnUpdate", function(self)
			--Update timer when icon is hovered over and tooltip is shown.
			obj.timerFrame.fs:SetText(NWB:updateFelwoodMinimapMarker(obj.type));
			obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 14);
			obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 9);
		end)
		obj.tooltip:Hide();
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
	end
end

function NWB:refreshFelwoodMarkers()
	for k, v in pairs(NWB.songFlowers) do
		NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWB", _G[k .. "NWB"]);
		NWB.dragonLibPins:RemoveMinimapIcon(k .. "NWBMini", _G[k .. "NWBMini"]);
		if (NWB.db.global.showSongflowerWorldmapMarkers) then
			NWB.dragonLibPins:AddWorldMapIconMap(k .. "NWB", _G[k .. "NWB"], 1448, v.x/100, v.y/100);
		end
		if (NWB.db.global.showSongflowerMinimapMarkers) then
			NWB.dragonLibPins:AddMinimapIconMap(k .. "NWBMini", _G[k .. "NWBMini"], 1448, v.x/100, v.y/100);
		end
	end
	for k, v in pairs(NWB.tubers) do
		NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWB", _G[k .. "NWB"]);
		NWB.dragonLibPins:RemoveMinimapIcon(k .. "NWBMini", _G[k .. "NWBMini"]);
		if (NWB.db.global.showTuberWorldmapMarkers) then
			NWB.dragonLibPins:AddWorldMapIconMap(k .. "NWB", _G[k .. "NWB"], 1448, v.x/100, v.y/100);
		end
		if (NWB.db.global.showTuberMinimapMarkers) then
			NWB.dragonLibPins:AddMinimapIconMap(k .. "NWBMini", _G[k .. "NWBMini"], 1448, v.x/100, v.y/100);
		end
	end
	for k, v in pairs(NWB.dragons) do
		NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWB", _G[k .. "NWB"]);
		NWB.dragonLibPins:RemoveMinimapIcon(k .. "NWBMini", _G[k .. "NWBMini"]);
		if (NWB.db.global.showDragonWorldmapMarkers) then
			NWB.dragonLibPins:AddWorldMapIconMap(k .. "NWB", _G[k .. "NWB"], 1448, v.x/100, v.y/100);
		end
		if (NWB.db.global.showDragonMinimapMarkers) then
			NWB.dragonLibPins:AddMinimapIconMap(k .. "NWBMini", _G[k .. "NWBMini"], 1448, v.x/100, v.y/100);
		end
	end
end

---====================---
---Worldbuff Map Frames---
---====================---

--Update timers for worldmap when the map is open.
function NWB:updateWorldbuffMarkers(type)
	--Seconds left.
	local time = 0;
	--if (type == "zanCity" or type == "zanStv") then
	--	time = (NWB.data["zanTimer"] + NWB.db.global["zanRespawnTime"]) - GetServerTime();
	--else
		if (NWB.isLayered) then
			local layerMsg = "";
			if (NWB.faction == "Horde") then
				layerMsg = L["cityMapLayerMsgHorde"];
			else
				layerMsg = L["cityMapLayerMsgAlliance"];
			end
			local layerString = "|cff00ff00[Layer " .. NWB.lastKnownLayer .. "]|cff9CD6DE";
			if (NWB.data.layers[NWB.lastKnownLayerID]) then
				--If last known layer exists use those timers.
				time = (NWB.data.layers[NWB.lastKnownLayerID][type .. "Timer"] + NWB.db.global[type .. "RespawnTime"]) - GetServerTime() or 0;
				_G["nefNWBWorldMap"].fs2:SetText("|cff9CD6DE" .. string.format(layerMsg, layerString));
			else
				--Else If first layer exists use those timers.
				local layer;
				table.sort(NWB.data.layers);
				for k, v in NWB:pairsByKeys(NWB.data.layers) do
					layer = k;
					break;
				end
				if (NWB.data.layers[layer]) then
					time = (NWB.data.layers[layer][type .. "Timer"] + NWB.db.global[type .. "RespawnTime"]) - GetServerTime() or 0;
					_G["nefNWBWorldMap"].fs2:SetText("|cff9CD6DE" .. string.format(layerMsg, layerString));
				else
					--Else If no layers recorded yet.
					_G["nefNWBWorldMap"].fs2:SetText("|cff9CD6DENo layer timers recorded yet.");
					time = 0;
				end
			end
		else
			time = (NWB.data[type .. "Timer"] + NWB.db.global[type .. "RespawnTime"]) - GetServerTime();
		end
	--end
	if (type == "ony" or type == "nef") then
		if (NWB.data[type .. "NpcDied"] > NWB.data[type .. "Timer"]) then
			local killedAgo = NWB:getTimeString(GetServerTime() - NWB.data[type .. "NpcDied"], true) 
			local tooltipString = "|CffDEDE42" .. _G[type .. "NWBWorldMap"].name .. "\n"
    				.. L["noTimer"] .. "\n"
    				.. string.format(L["anyNpcKilledAllianceWithTimer"], killedAgo);
    		_G[type .. "NWBWorldMap"].tooltip.fs:SetText(tooltipString);
    		_G[type .. "NWBWorldMap"].tooltip:SetWidth(_G[type .. "NWBWorldMap"].tooltip.fs:GetStringWidth() + 18);
			_G[type .. "NWBWorldMap"].tooltip:SetHeight(_G[type .. "NWBWorldMap"].tooltip.fs:GetStringHeight() + 12);
			return L["noTimer"];
		end
	end
	if (time > 0) then
    	local timeString = NWB:getTimeString(time, true);
    	local timeStringShort = NWB:getTimeString(time, true, true);
    	local timStamp = 0;
    	if (type == "zanCity" or type == "zanStv") then
    		timeStamp = NWB:getTimeFormat(NWB.data["zanTimer"] + NWB.db.global["zanRespawnTime"]);
    	else
    		timeStamp = NWB:getTimeFormat(NWB.data[type .. "Timer"] + NWB.db.global[type .. "RespawnTime"]);
    	end
    	local tooltipString = "|CffDEDE42" .. _G[type .. "NWBWorldMap"].name .. "\n"
    			.. timeString .. "\n"
    			.. timeStamp;
    	_G[type .. "NWBWorldMap"].tooltip.fs:SetText(tooltipString);
    	_G[type .. "NWBWorldMap"].tooltip:SetWidth(_G[type .. "NWBWorldMap"].tooltip.fs:GetStringWidth() + 18);
		_G[type .. "NWBWorldMap"].tooltip:SetHeight(_G[type .. "NWBWorldMap"].tooltip.fs:GetStringHeight() + 12);
    	return timeStringShort;
  	end
  	_G[type .. "NWBWorldMap"].tooltip.fs:SetText("|CffDEDE42" .. _G[type .. "NWBWorldMap"].name);
	return L["noTimer"];
end

function NWB:createWorldbuffMarkersTable()
	if (LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW) then
		--Adjust for icon position non-english fonts in the timer frame.
    	if (NWB.faction == "Alliance") then
			NWB.worldBuffMapMarkerTypes = {
				["rend"] = {x = 71.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\spell_arcane_teleportorgrimmar", name = L["rend"]},
				["ony"] = {x = 79.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\inv_misc_head_dragon_01", name = L["onyxia"]},
				["nef"] = {x = 87.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\inv_misc_head_dragon_black", name = L["nefarian"]},
				--["zanCity"] = {x = 95.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
				--["zanStv"] = {x = 11.0, y = 20.5, mapID = 1434, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
			};
		else
			NWB.worldBuffMapMarkerTypes = {
				["rend"] = {x = 60.0, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\spell_arcane_teleportorgrimmar", name = L["rend"]},
				["ony"] = {x = 68, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\inv_misc_head_dragon_01", name = L["onyxia"]},
				["nef"] = {x = 76.0, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\inv_misc_head_dragon_black", name = L["nefarian"]},
				--["zanCity"] = {x = 84.0, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
				--["zanStv"] = {x = 11.0, y = 20.5, mapID = 1434, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
			};
		end
	else
		if (NWB.faction == "Alliance") then
			NWB.worldBuffMapMarkerTypes = {
				["rend"] = {x = 74.0, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\spell_arcane_teleportorgrimmar", name = L["rend"]},
				["ony"] = {x = 79.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\inv_misc_head_dragon_01", name = L["onyxia"]},
				["nef"] = {x = 85.0, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\inv_misc_head_dragon_black", name = L["nefarian"]},
				--["zanCity"] = {x = 90.5, y = 73.0, mapID = 1453, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
				--["zanStv"] = {x = 11.0, y = 20.5, mapID = 1434, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
			};
		else
			NWB.worldBuffMapMarkerTypes = {
				["rend"] = {x = 59.0, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\spell_arcane_teleportorgrimmar", name = L["rend"]},
				["ony"] = {x = 64.5, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\inv_misc_head_dragon_01", name = L["onyxia"]},
				["nef"] = {x = 70.0, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\inv_misc_head_dragon_black", name = L["nefarian"]},
				--["zanCity"] = {x = 75.5, y = 79.0, mapID = 1454, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
				--["zanStv"] = {x = 11.0, y = 20.5, mapID = 1434, icon = "Interface\\Icons\\ability_creature_poison_05", name = L["Zandalar"]},
			};
		end
	end
end

function NWB:createWorldbuffMarkers()
	for k, v in pairs(NWB.worldBuffMapMarkerTypes) do
		--Worldmap marker.
		local obj = CreateFrame("Frame", k .. "NWBWorldMap", WorldMapFrame);
		obj.name = v.name;
		local bg = obj:CreateTexture(nil, "MEDIUM");
		bg:SetTexture(v.icon);
		bg:SetAllPoints(obj);
		obj.texture = bg;
		obj:SetSize(23, 23);
		--Worldmap tooltip.
		obj.tooltip = CreateFrame("Frame", k.. "WorldMapTooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, -46);
		obj.tooltip:SetFrameStrata("TOOLTIP");
		obj.tooltip:SetFrameLevel(9);
		obj.tooltip.fs = obj.tooltip:CreateFontString(k .. "NWBWorldMapTooltipFS", "ARTWORK");
		obj.tooltip.fs:SetPoint("CENTER", 0, 0);
		obj.tooltip.fs:SetFont(NWB.regionFont, 14);
		obj.tooltip.fs:SetText("|CffDEDE42" .. v.name);
		obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
		obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
		--obj.tooltip:SetParent(WorldMapFrame); --Make tooltip float on top of other pins.
		obj:SetScript("OnEnter", function(self)
			obj.tooltip:Show();
		end)
		obj:SetScript("OnLeave", function(self)
			obj.tooltip:Hide();
		end)
		obj.tooltip:Hide();
		--Timer frame that sits above the icon when an active timer is found.
		obj.timerFrame = CreateFrame("Frame", k.. "WorldMapTimerFrame", WorldMapFrame, "TooltipBorderedFrameTemplate");
		obj.timerFrame:SetPoint("CENTER", obj, "CENTER",  0, 21);
		obj.timerFrame:SetFrameStrata("FULLSCREEN");
		obj.timerFrame:SetFrameLevel(9);
		obj.timerFrame.fs = obj.timerFrame:CreateFontString(k .. "NWBWorldMapTimerFrameFS", "ARTWORK");
		obj.timerFrame.fs:SetPoint("CENTER", 0, 0);
		obj.timerFrame.fs:SetFont(NWB.regionFont, 13);
		obj.timerFrame:SetWidth(54);
		obj.timerFrame:SetHeight(24);
		obj:SetScript("OnUpdate", function(self)
			--Update timer when map is open.
			obj.timerFrame.fs:SetText(NWB:updateWorldbuffMarkers(k));
			--Adjust for non-english fonts.
			if (LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW or LOCALE_ruRU) then
				obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 18);
				obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 12);
			end
		end)
		--Make it act like pin is the parent and not WorldMapFrame.
		obj:SetScript("OnHide", function(self)
			obj.timerFrame:Hide();
		end)
		obj:SetScript("OnShow", function(self)
			obj.timerFrame:Show();
		end)
		
		if (k == "nef") then
			--/buffs text below the city map icons.
			obj.fs = obj:CreateFontString(k .. "NWBWorldMapBuffCmdFS", "ARTWORK");
			obj.fs:SetPoint("RIGHT", 40, -40);
			obj.fs:SetFont(NWB.regionFont, 14);
			obj.fs:SetText("|CffDEDE42Type /buffs to view all your\ncharacters current world buffs.");
			--Layer info text above the city map icons
			obj.fs2 = obj:CreateFontString(k .. "NWBWorldMapBuffCmdFS", "ARTWORK");
			obj.fs2:SetPoint("RIGHT", 40, 60);
			obj.fs2:SetFont(NWB.regionFont, 14);
		end
		obj:SetScript("OnMouseDown", function(self)
			NWB:openBuffListFrame();
		end)
	end
	NWB:refreshWorldbuffMarkers();
end

function NWB:refreshWorldbuffMarkers()
	for k, v in pairs(NWB.worldBuffMapMarkerTypes) do
		NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWBWorldMap", _G[k .. "NWBWorldMap"]);
		if (NWB.db.global.showWorldMapMarkers) then
			NWB.dragonLibPins:AddWorldMapIconMap(k .. "NWBWorldMap", _G[k .. "NWBWorldMap"], v.mapID, v.x/100, v.y/100, HBD_PINS_WORLDMAP_SHOW_PARENT);
			--NWB.dragonLibPins:AddWorldMapIconMap(k .. "NWBWorldMap", _G[k .. "NWBWorldMap"], v.mapID, v.x/100, v.y/100);
			if (NWB.faction == "Alliance" and k == "rend") then
				if (not NWB.db.global.allianceEnableRend) then
					NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWBWorldMap", _G[k .. "NWBWorldMap"]);
				end
			end
			if (string.match(k, "zan") and not NWB.zand) then
				--Temp debug.
				NWB.dragonLibPins:RemoveWorldMapIcon(k .. "NWBWorldMap", _G[k .. "NWBWorldMap"]);
			end
		end
	end
end

---=============---
---Darkoon Faire---
---=============---

SLASH_NWBDMFCMD1 = '/dmf';
function SlashCmdList.NWBDMFCMD(msg, editBox)
	if (msg) then
		msg = string.lower(msg);
	end
	if (msg == "map") then
		WorldMapFrame:Show();
		if (NWB.dmfZone == "Mulgore") then
			WorldMapFrame:SetMapID(1412); 
		else
			WorldMapFrame:SetMapID(1429);
		end
		return;
	end
	if (msg == "options" or msg == "option" or msg == "config" or msg == "menu") then
		--Opening the frame needs to be run twice to avoid a bug.
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
		--Hack to fix the issue of interface options not opening to menus below the current scroll range.
		--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
		local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
		if (min < max) then
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
		end
		InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
		return;
	end
	local output, zone, dmfFound;
	if (NWB.dmfZone == "Mulgore") then
		zone = L["mulgore"];
	else
		zone = L["elwynnForest"];
	end
	output = NWB:getDmfTimeString() .. " (" .. zone .. ")";
	if (output) then
		if (msg ~= nil and msg ~= "") then
			NWB:print(output, msg);
		else
			NWB:print(output);
		end
	end
	
	if (NWB.data.myChars[UnitName("player")].buffs) then
		for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
			--if (v.type == "dmf" and v.timeLeft > 0) then
			if (v.type == "dmf" and (v.timeLeft + 7200) > 0) then
				--output = string.format(L["dmfBuffCooldownMsg"],  NWB:getTimeString(v.timeLeft, true));
				output = string.format(L["dmfBuffCooldownMsg"],  NWB:getTimeString(v.timeLeft + 7200, true));
				dmfFound = true;
				break;
			end
		end
	end
	if (not dmfFound) then
		output = L["dmfBuffReady"];
	end
	if (msg == nil or msg == "") then
		NWB:print(output);
	end
end

function NWB:getDmfTimeString()
	local timestamp, timeLeft, type = NWB:getDmfData();
	local msg, dateString;
	if (timestamp) then
 		if (NWB.db.global.timeStampFormat == 12) then
			dateString = date("%a %b %d", timestamp) .. " " .. gsub(string.lower(date("%I:%M%p", timestamp)), "^0", "");
		else
			dateString = date("%x %X", timestamp);
		end
		dateString = NWB:getTimeFormat(timestamp, true);
		if (type == "start") then
			msg = string.format(L["dmfSpawns"], NWB:getTimeString(timeLeft, true), dateString);
		else
			msg = string.format(L["dmfEnds"],NWB:getTimeString(timeLeft, true), dateString);
		end
		return msg;
	end
end

--DMF spawns the following monday after first friday of the month at daily reset time.
--Whole region shares time of day for spawn (I think).
--Realms within the region possibly don't all spawn at same moment though, realms may wait for their own monday.
function NWB:getDmfStartEnd(month, nextYear)
	local startOffset, endOffset, validRegion, isDst;
	local  minOffset, hourOffset, dayOffset = 0, 0, 0;
	local region = GetCurrentRegion();
	--I may change this to realm names later instead, region may be unreliable with US client on EU region if that issue still exists.
	if (NWB.realm == "Arugal" or NWB.realm == "Felstriker" or NWB.realm == "Remulos" or NWB.realm == "Yojamba") then
		--OCE Sunday 12pm UTC reset time (4am server time).
		dayOffset = 2; --2 days after friday (sunday).
		hourOffset = 18; -- 6pm.
		validRegion = true;
	elseif (NWB.realm == "Arcanite Reaper" or NWB.realm == "Old Blanchy" or NWB.realm == "Anathema" or NWB.realm == "Azuresong"
			or NWB.realm == "Kurinnaxx" or NWB.realm == "Myzrael" or NWB.realm == "Rattlegore" or NWB.realm == "Smolderweb"
			or NWB.realm == "Thunderfury" or NWB.realm == "Atiesh" or NWB.realm == "Bigglesworth" or NWB.realm == "Blaumeux"
			or NWB.realm == "Fairbanks" or NWB.realm == "Grobbulus" or NWB.realm == "Whitemane") then
		--US west Sunday 11am UTC reset time (4am server time).
		dayOffset = 3; --3 days after friday (monday).
		hourOffset = 11; -- 11am.
		validRegion = true;
	elseif (region == 1) then
		--US east + Latin Monday 8am UTC reset time (4am server time).
		dayOffset = 3; --3 days after friday (monday).
		hourOffset = 8; -- 8am.
		validRegion = true;
	elseif (region == 2) then
		--Korea 9pm UTC sunday (4am monday local) reset time.
		dayOffset = 2;
		hourOffset = 21;
		validRegion = true;
	elseif (region == 3) then
		--EU Monday 4am UTC reset time.
		dayOffset = 3; --3 days after friday (monday).
		hourOffset = 4; -- 4am.
		validRegion = true;
	elseif (region == 4) then
		--Taiwan 8pm UTC sunday (4am monday local) reset time.
		dayOffset = 2;
		hourOffset = 20;
		validRegion = true;
	elseif (region == 5) then
		--China 8pm UTC sunday (4am monday local) reset time.
		dayOffset = 2;
		hourOffset = 20;
		validRegion = true;
	end
	--Create current UTC date table.
	local data = date("!*t", GetServerTime());
	--If month is specified then use that month instead (next dmf spawn is next month);
	if (month) then
		data.month = month;
	end
	--If nextYear is true then next dmf spawn is next year (we're in december right now).
	if (nextYear) then
		data.year = data.year + 1;
	end
	local dmfStartDay;
	for i = 1, 7 do
		--Iterate the first 7 days in the month to find first friday.
		local time = date("!*t", time({year = data.year, month = data.month, day = i}));
		if (time.wday == 6) then
			--If day of the week (wday) is 6 (friday) then set this as first friday of the month.
			dmfStartDay = i;
		end
	end
	local timeTable = {year = data.year, month = data.month, day = dmfStartDay + dayOffset, hour = hourOffset, min = minOffset, sec = 0};
	local utcdate   = date("!*t", GetServerTime());
	local localdate = date("*t", GetServerTime());
	localdate.isdst = false;
	local secondsDiff = difftime(time(utcdate), time(localdate));
	local dmfStart = time(timeTable) - secondsDiff;
	if (date("%w", dmfStart) == "0") then
		--Not sure if whole region spawns at the same moment or if each realm waits for their own monday.
		--All realms spawn same time of day, but possibly not same UTC day depending on timezone.
		--Just incase each realm waits for monday we can add a day here.
		dmfStart = dmfStart + 86400;
	end
	--Add 7 days to get end timestamp.
	local dmfEnd = dmfStart + 604800;
	--Only return if we have set daily reset offsets for this region.
	if (validRegion) then
		return dmfStart, dmfEnd;
	end
end

function NWB:getDmfData()
	local dmfStart, dmfEnd = NWB:getDmfStartEnd();
	local timestamp, timeLeft, type;
	--local locale = GetLocale();
	--OCE region only just for now.
	if (dmfStart and dmfEnd) then
		if (GetServerTime() < dmfStart) then
			--It's before the start of dmf.
			timestamp = dmfStart;
			type = "start";
			timeLeft = dmfStart - GetServerTime();
			NWB.isDmfUp = nil;
		elseif (GetServerTime() < dmfEnd) then
			--It's after dmf started and before the end.
			timestamp = dmfEnd;
			type = "end";
			timeLeft = dmfEnd - GetServerTime();
			NWB.isDmfUp = true;
		elseif (GetServerTime() > dmfEnd) then
			--It's after dmf ended so calc next months dmf instead.
			local data = date("!*t", GetServerTime());
			if (data.month == 12) then
				dmfStart, dmfEnd = NWB:getDmfStartEnd(1, true);
			else
				dmfStart, dmfEnd = NWB:getDmfStartEnd(data.month + 1);
			end
			timestamp = dmfStart;
			type = "start";
			timeLeft = dmfStart - GetServerTime();
			NWB.isDmfUp = nil;
		end
		local zone;
		if (date("%m", dmfStart) % 2 == 0) then
    		zone = "Mulgore";
		else
    		zone = "Elwynn Forest";
		end
		NWB.dmfZone = zone;
		--Timestamp of next start or end event, seconds left untill that event, and type of event.
		return timestamp, timeLeft, type;
	end
end

function NWB:updateDmfMarkers(type)
	local timestamp, timeLeft, type = NWB:getDmfData();
	local text = "";
	if (not timestamp or timestamp < 1) then
		text = text .. L["noTimer"];
	else
		if (type == "start") then
			text = text .. string.format(L["startsIn"], NWB:getTimeString(timeLeft, true, true));
		else
			text = text .. string.format(L["endsIn"], NWB:getTimeString(timeLeft, true, true));
		end
	end
	if (timeLeft > 0) then
		local tooltipText = "|Cff00ff00" .. L["Darkmoon Faire"] .. "|CffDEDE42\n";
		if (type == "start") then
			tooltipText = tooltipText .. string.format(L["startsIn"], NWB:getTimeString(timeLeft, true)) .. "\n";
		else
			tooltipText = tooltipText .. string.format(L["endsIn"], NWB:getTimeString(timeLeft, true)) .. "\n";
		end
    	tooltipText = tooltipText .. NWB:getTimeFormat(timestamp, true);
    	local dmfFound;
    	local buffText = "";
    	if (NWB.isDmfUp) then
    		if (NWB.data.myChars[UnitName("player")].buffs) then
				for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
					if (v.type == "dmf" and (v.timeLeft + 7200) > 0) then
						buffText = "\n" .. string.format(L["dmfBuffCooldownMsg"],  NWB:getTimeString((v.timeLeft + 7200), true));
						dmfFound = true;
						break;
					end
				end
			end
    		if (not dmfFound) then
    			buffText = "\n" .. L["dmfBuffReady"];
    		end
    	end
    	tooltipText = tooltipText .. buffText;
    	_G["NWBDMF"].tooltip.fs:SetText(tooltipText);
    	_G["NWBDMF"].tooltip:SetWidth(_G["NWBDMF"].tooltip.fs:GetStringWidth() + 18);
		_G["NWBDMF"].tooltip:SetHeight(_G["NWBDMF"].tooltip.fs:GetStringHeight() + 12);
		_G["NWBDMFContinent"].tooltip.fs:SetText(tooltipText);
    	_G["NWBDMFContinent"].tooltip:SetWidth(_G["NWBDMFContinent"].tooltip.fs:GetStringWidth() + 12);
		_G["NWBDMFContinent"].tooltip:SetHeight(_G["NWBDMFContinent"].tooltip.fs:GetStringHeight() + 12);
  	end
	return text;
end

function NWB:createDmfMarkers()
	--Darkmoon Faire zone map marker.
	local icon = "Interface\\AddOns\\NovaWorldBuffs\\Media\\dmf";
	local obj = CreateFrame("Frame", "NWBDMF", WorldMapFrame);
	local bg = obj:CreateTexture(nil, "MEDIUM");
	bg:SetTexture(icon);
	bg:SetAllPoints(obj);
	obj.texture = bg;
	obj:SetSize(23, 23);
	--Worldmap tooltip.
	obj.tooltip = CreateFrame("Frame", "NWBDMFTooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
	obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, 46);
	obj.tooltip:SetFrameStrata("TOOLTIP");
	obj.tooltip:SetFrameLevel(9);
	obj.tooltip.fs = obj.tooltip:CreateFontString("NWBDMFTooltipFS", "ARTWORK");
	obj.tooltip.fs:SetPoint("CENTER", 0, 0);
	obj.tooltip.fs:SetFont(NWB.regionFont, 14);
	obj.tooltip.fs:SetText("|Cff00ff00Darkmoon Faire");
	obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
	obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
	obj:SetScript("OnEnter", function(self)
		obj.tooltip:Show();
	end)
	obj:SetScript("OnLeave", function(self)
		obj.tooltip:Hide();
	end)
	obj.tooltip:Hide();
	--Timer frame that sits above the icon when an active timer is found.
	obj.timerFrame = CreateFrame("Frame", "NWBDMFTimerFrame", WorldMapFrame, "TooltipBorderedFrameTemplate");
	obj.timerFrame:SetPoint("CENTER", obj, "CENTER", 0, -21);
	obj.timerFrame:SetFrameStrata("FULLSCREEN");
	obj.timerFrame:SetFrameLevel(9);
	obj.timerFrame.fs = obj.timerFrame:CreateFontString("NWBDMFTimerFrameFS", "ARTWORK");
	obj.timerFrame.fs:SetPoint("CENTER", 0, 0);
	obj.timerFrame.fs:SetFont(NWB.regionFont, 13);
	obj.timerFrame:SetWidth(54);
	obj.timerFrame:SetHeight(24);
	obj:SetScript("OnUpdate", function(self)
		--Update timer when map is open.
		obj.timerFrame.fs:SetText(NWB:updateDmfMarkers());
		obj.timerFrame:SetWidth(obj.timerFrame.fs:GetStringWidth() + 10);
		obj.timerFrame:SetHeight(obj.timerFrame.fs:GetStringHeight() + 10);
	end)
	--Make it act like pin is the parent and not WorldMapFrame.
	obj:SetScript("OnHide", function(self)
		obj.timerFrame:Hide();
	end)
	obj:SetScript("OnShow", function(self)
		obj.timerFrame:Show();
	end)
	obj:SetScript("OnMouseDown", function(self)
		NWB:openBuffListFrame();
	end)
	
	--Darkmoon Faire continent marker.
	local obj = CreateFrame("Frame", "NWBDMFContinent", WorldMapFrame);
	local bg = obj:CreateTexture(nil, "MEDIUM");
	bg:SetTexture(icon);
	bg:SetAllPoints(obj);
	obj.texture = bg;
	obj:SetSize(14, 14);
	obj:SetFrameStrata("High");
	obj:SetFrameLevel(9);
	--Worldmap tooltip.
	obj.tooltip = CreateFrame("Frame", "NWBDMFContinentTooltip", WorldMapFrame, "TooltipBorderedFrameTemplate");
	obj.tooltip:SetPoint("CENTER", obj, "CENTER", 0, 46);
	obj.tooltip:SetFrameStrata("TOOLTIP");
	obj.tooltip:SetFrameLevel(9);
	obj.tooltip.fs = obj.tooltip:CreateFontString("NWBDMFContinentTooltipFS", "HIGH");
	obj.tooltip.fs:SetPoint("CENTER", 0, 0);
	obj.tooltip.fs:SetFont(NWB.regionFont, 14);
	obj.tooltip.fs:SetText("|Cff00ff00Darkmoon Faire");
	obj.tooltip:SetWidth(obj.tooltip.fs:GetStringWidth() + 18);
	obj.tooltip:SetHeight(obj.tooltip.fs:GetStringHeight() + 12);
	obj:SetScript("OnEnter", function(self)
		obj.tooltip:Show(); --5:34 2h4m
	end)
	obj:SetScript("OnLeave", function(self)
		obj.tooltip:Hide();
	end)
	obj.tooltip:Hide();
	obj:SetScript("OnUpdate", function(self)
		--Updatetooltip  timer when map is open.
		NWB:updateDmfMarkers();
	end)
	obj:SetScript("OnMouseDown", function(self)
		NWB:openBuffListFrame();
	end)
	NWB:refreshDmfMarkers();
end

function NWB:refreshDmfMarkers()
	local x, y, mapID, worldX, worldY, worldMapID;
	if (NWB.dmfZone == "Mulgore") then
		x, y, mapID = 36.8, 37.6, 1412;
		worldX, worldY, worldMapID = 46, 63, 1414;
	else
		x, y, mapID = 42, 70, 1429;
		worldX, worldY, worldMapID = 45.7, 71.4, 1415;
	end
	NWB.dragonLibPins:RemoveWorldMapIcon("NWBDMF", _G["NWBDMF"]);
	if (NWB.db.global.showDmfMap) then
		NWB.dragonLibPins:AddWorldMapIconMap("NWBDMF", _G["NWBDMF"], mapID, x/100, y/100, HBD_PINS_WORLDMAP_SHOW_PARENT);
		NWB.dragonLibPins:AddWorldMapIconMap("NWBDMFContinent", _G["NWBDMFContinent"], worldMapID, worldX/100, worldY/100, HBD_PINS_WORLDMAP_SHOW_WORLD, "TOOLTIP");
	end
end

WorldMapFrame:HookScript("OnShow", function()
	NWB:refreshDmfMarkers();
end)

function NWB:fixMapMarkers()
	--Fix a bug with tooltips not showing first time opening the map.
	--Running this twice taints the blizzard raid frames (wtf?)
	--WorldMapFrame:Show();
	--WorldMapFrame:SetMapID(1448);
	--WorldMapFrame:Hide();
end

---===================---
---Buff tracking frame---
---===================---

local NWBbuffListFrame = CreateFrame("ScrollFrame", "NWBbuffListFrame", UIParent, "InputScrollFrameTemplate");
NWBbuffListFrame:Hide();
NWBbuffListFrame:SetToplevel(true);
NWBbuffListFrame:SetMovable(true);
NWBbuffListFrame:EnableMouse(true);
tinsert(UISpecialFrames, "NWBbuffListFrame");
NWBbuffListFrame:SetPoint("CENTER", UIParent, 20, 120);
NWBbuffListFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",insets = {top = 0, left = 0, bottom = 0, right = 0}});
NWBbuffListFrame:SetBackdropColor(0,0,0,.5);
NWBbuffListFrame.CharCount:Hide();
--NWBbuffListFrame:SetFrameLevel(128);
NWBbuffListFrame:SetFrameStrata("MEDIUM");
NWBbuffListFrame.EditBox:SetAutoFocus(false);
NWBbuffListFrame.EditBox:SetScript("OnKeyDown", function(self, arg)
	--If control key is down keep focus for copy/paste to work.
	--Otherwise remove focus so "enter" can be used to open chat and not have a stuck cursor on this edit box.
	if (not IsControlKeyDown()) then
		NWBbuffListFrame.EditBox:ClearFocus();
	end
end)
NWBbuffListFrame.EditBox:SetScript("OnShow", function(self, arg)
	NWBbuffListFrame:SetVerticalScroll(0);
end)
local buffUpdateTime = 0;
NWBbuffListFrame:HookScript("OnUpdate", function(self, arg)
	--Only update once per second.
	if (GetServerTime() - buffUpdateTime > 0 and self:GetVerticalScrollRange() == 0) then
		NWB:recalcBuffListFrame();
		buffUpdateTime = GetServerTime();
	end
end)
NWBbuffListFrame.fs = NWBbuffListFrame:CreateFontString("NWBbuffListFrameFS", "HIGH");
NWBbuffListFrame.fs:SetPoint("TOP", 0, -0);
NWBbuffListFrame.fs:SetFont(NWB.regionFont, 14);
NWBbuffListFrame.fs:SetText("|cffffff00" .. L["Your Current World Buffs"]);

local NWBbuffListDragFrame = CreateFrame("Frame", "NWBbuffListDragFrame", NWBbuffListFrame);
--NWBbuffListDragFrame:SetToplevel(true);
NWBbuffListDragFrame:EnableMouse(true);
NWBbuffListDragFrame:SetWidth(205);
NWBbuffListDragFrame:SetHeight(38);
NWBbuffListDragFrame:SetPoint("TOP", 0, 4);
NWBbuffListDragFrame:SetFrameLevel(131);
NWBbuffListDragFrame.tooltip = CreateFrame("Frame", "NWBbuffListDragTooltip", NWBbuffListDragFrame, "TooltipBorderedFrameTemplate");
NWBbuffListDragFrame.tooltip:SetPoint("CENTER", NWBbuffListDragFrame, "TOP", 0, 12);
NWBbuffListDragFrame.tooltip:SetFrameStrata("TOOLTIP");
NWBbuffListDragFrame.tooltip:SetFrameLevel(9);
NWBbuffListDragFrame.tooltip:SetAlpha(.8);
NWBbuffListDragFrame.tooltip.fs = NWBbuffListDragFrame.tooltip:CreateFontString("NWBbuffListDragTooltipFS", "HIGH");
NWBbuffListDragFrame.tooltip.fs:SetPoint("CENTER", 0, 0.5);
NWBbuffListDragFrame.tooltip.fs:SetFont(NWB.regionFont, 12);
NWBbuffListDragFrame.tooltip.fs:SetText("Hold to drag");
NWBbuffListDragFrame.tooltip:SetWidth(NWBbuffListDragFrame.tooltip.fs:GetStringWidth() + 16);
NWBbuffListDragFrame.tooltip:SetHeight(NWBbuffListDragFrame.tooltip.fs:GetStringHeight() + 10);
NWBbuffListDragFrame:SetScript("OnEnter", function(self)
	NWBbuffListDragFrame.tooltip:Show();
end)
NWBbuffListDragFrame:SetScript("OnLeave", function(self)
	NWBbuffListDragFrame.tooltip:Hide();
end)
NWBbuffListDragFrame.tooltip:Hide();
NWBbuffListDragFrame:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent().isMoving) then
		self:GetParent().EditBox:ClearFocus();
		self:GetParent():StartMoving();
		self:GetParent().isMoving = true;
		--self:GetParent():SetUserPlaced(false);
	end
end)
NWBbuffListDragFrame:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent().isMoving) then
		self:GetParent():StopMovingOrSizing();
		self:GetParent().isMoving = false;
	end
end)
NWBbuffListDragFrame:SetScript("OnHide", function(self)
	if (self:GetParent().isMoving) then
		self:GetParent():StopMovingOrSizing();
		self:GetParent().isMoving = false;
	end
end)

--Top right X close button.
local NWBbuffListFrameClose = CreateFrame("Button", "NWBbuffListFrameClose", NWBbuffListFrame, "UIPanelCloseButton");
NWBbuffListFrameClose:SetPoint("TOPRIGHT", -5, 8.6);
NWBbuffListFrameClose:SetWidth(31);
NWBbuffListFrameClose:SetHeight(31);
NWBbuffListFrameClose:SetScript("OnClick", function(self, arg)
	NWBbuffListFrame:Hide();
end)

--Config button.
local NWBbuffListFrameConfButton = CreateFrame("Button", "NWBbuffListFrameConfButton", NWBbuffListFrameClose, "UIPanelButtonTemplate");
NWBbuffListFrameConfButton:SetPoint("CENTER", -58, 1);
NWBbuffListFrameConfButton:SetWidth(90);
NWBbuffListFrameConfButton:SetHeight(17);
--NWBbuffListFrameConfButton:SetFrameLevel(129);
--NWBbuffListFrameConfButton:SetFrameStrata("HIGH");
NWBbuffListFrameConfButton:SetText(L["Options"]);
NWBbuffListFrameConfButton:SetNormalFontObject("GameFontNormalSmall");
NWBbuffListFrameConfButton:SetScript("OnClick", function(self, arg)
	--Opening the frame needs to be run twice to avoid a bug.
	InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
	--Hack to fix the issue of interface options not opening to menus below the current scroll range.
	--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
	local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
	if (min < max) then
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
	end
	InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
end)
NWBbuffListFrameConfButton:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent().EditBox:ClearFocus();
		self:GetParent():GetParent():StartMoving();
		self:GetParent():GetParent().isMoving = true;
	end
end)
NWBbuffListFrameConfButton:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)
NWBbuffListFrameConfButton:SetScript("OnHide", function(self)
	if (self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)

--Timers button (layered realms only).
local NWBbufflistFrameTimersButton = CreateFrame("Button", "NWBbufflistFrameTimersButton", NWBbuffListFrameClose, "UIPanelButtonTemplate");
NWBbufflistFrameTimersButton:SetPoint("CENTER", -58, -13);
NWBbufflistFrameTimersButton:SetWidth(90);
NWBbufflistFrameTimersButton:SetHeight(17);
NWBbufflistFrameTimersButton:SetText("Timers");
NWBbufflistFrameTimersButton:SetNormalFontObject("GameFontNormalSmall");
NWBbufflistFrameTimersButton:SetScript("OnClick", function(self, arg)
	NWB:openLayerFrame();
end)
NWBbufflistFrameTimersButton:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent().EditBox:ClearFocus();
		self:GetParent():GetParent():StartMoving();
		self:GetParent():GetParent().isMoving = true;
	end
end)
NWBbufflistFrameTimersButton:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)
NWBbufflistFrameTimersButton:SetScript("OnHide", function(self)
	if (self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)
NWBbufflistFrameTimersButton:Hide();

function NWB:openBuffListFrame()
	NWBbuffListFrame.fs:SetFont(NWB.regionFont, 14);
	if (NWBbuffListFrame:IsShown()) then
		NWBbuffListFrame:Hide();
	else
		if (NWB.isLayered) then
			NWBbufflistFrameTimersButton:Show();
		end
		NWB:syncBuffsWithCurrentDuration();
		NWBbuffListFrame:SetHeight(300);
		NWBbuffListFrame:SetWidth(450);
		local fontSize = false
		NWBbuffListFrame.EditBox:SetFont(NWB.regionFont, 14);
		NWB:recalcBuffListFrame();
		NWBbuffListFrame.EditBox:SetWidth(NWBbuffListFrame:GetWidth() - 30);
		NWBbuffListFrame:Show();
		--Changing scroll position requires a slight delay.
		--Second delay is a backup.
		C_Timer.After(0.05, function()
			NWBbuffListFrame:SetVerticalScroll(0);
		end)
		C_Timer.After(0.3, function()
			NWBbuffListFrame:SetVerticalScroll(0);
		end)
		--So interface options and this frame will open on top of each other.
		if (InterfaceOptionsFrame:IsShown()) then
			NWBbuffListFrame:SetFrameStrata("DIALOG")
		else
			NWBbuffListFrame:SetFrameStrata("HIGH")
		end
	end
end

function NWB:recalcBuffListFrame()
	--local scroll = NWBbuffListFrame:GetVerticalScroll();
	if (NWB.isDmfUp) then
		local buffText, dmfFound;
		if (NWB.data.myChars[UnitName("player")].buffs) then
			for k, v in pairs(NWB.data.myChars[UnitName("player")].buffs) do
				if (v.type == "dmf" and (v.timeLeft + 7200) > 0) then
					buffText = string.format(L["dmfBuffCooldownMsg"],  NWB:getTimeString(v.timeLeft + 7200, true));
					dmfFound = true;
					break;
				end
			end
		end
    	if (not dmfFound) then
    		buffText = L["dmfBuffReady"];
    	end
		NWBbuffListFrame.EditBox:SetText("\n" .. buffText .. "\n");
	else
		NWBbuffListFrame.EditBox:SetText("\n\n");
	end
	local count = 0;
	local foundBuffs;
	--local msg2 = "";
	for k, v in NWB:pairsByKeys(NWB.db.global) do --Iterate realms.
		local msg = "";
		if (type(v) == "table") then --The only tables in data are realm names.
			local realm = k;
			for k, v in NWB:pairsByKeys(v) do --Iterate factions.
				local coloredFaction = "";
				if (k == "Horde") then
					coloredFaction = "|cffe50c11" .. k .. "|r";
				else
					coloredFaction = "|cff4954e8" .. k .. "|r";
				end
				msg = "|cff00ff00[" .. realm .. "]|r\n";
				--Have to check if the myChars table exists here.
				--There was a lua error when much older versions upgraded to the buff tracking version.
				--They had realmdata in thier db file without the myChars table and it won't create it until they log on that realm.
				if (v.myChars) then
					for k, v in NWB:pairsByKeys(v.myChars) do --Iterate characters.
						local _, _, _, classColor = GetClassColor(v.englishClass);
						msg = msg .. "  -|c" .. classColor .. k .. "|r\n";
						for k, v in NWB:pairsByKeys(v.buffs) do--Iterate buffs.
							if (v.track and v.timeLeft > 0) then
								local icon = "";
								if (v.type == "rend") then
									icon = "|TInterface\\Icons\\spell_arcane_teleportorgrimmar:12:12:0:0|t";
								elseif (v.type == "ony") then
									icon = "|TInterface\\Icons\\inv_misc_head_dragon_01:12:12:0:0|t";
								elseif (v.type == "nef") then
									--icon = "|TInterface\\Icons\\inv_misc_head_dragon_black:12:12:0:0|t";
									icon = "|TInterface\\Icons\\inv_misc_head_dragon_01:12:12:0:0|t";
								elseif (v.type == "dmf") then
									icon = "|TInterface\\Icons\\inv_misc_orb_02:12:12:0:0|t";
								elseif (v.type == "zan") then
									icon = "|TInterface\\Icons\\ability_creature_poison_05:12:12:0:0|t";
								elseif (v.type == "moxie") then
									icon = "|TInterface\\Icons\\spell_nature_massteleport:12:12:0:0|t";
								elseif (v.type == "ferocity") then
									icon = "|TInterface\\Icons\\spell_nature_undyingstrength:12:12:0:0|t";
								elseif (v.type == "savvy") then
									icon = "|TInterface\\Icons\\spell_holy_lesserheal02:12:12:0:0|t";
								elseif (v.type == "flaskPower") then
									icon = "|TInterface\\Icons\\inv_potion_41:12:12:0:0|t";
								elseif (v.type == "flaskTitans") then
									icon = "|TInterface\\Icons\\inv_potion_62:12:12:0:0|t";
								elseif (v.type == "flaskWisdom") then
									icon = "|TInterface\\Icons\\inv_potion_97:12:12:0:0|t";
								elseif (v.type == "flaskResistance") then
									icon = "|TInterface\\Icons\\inv_potion_48:12:12:0:0|t";
								elseif (v.type == "songflower") then
									icon = "|TInterface\\Icons\\spell_holy_mindvision:12:12:0:0|t";
								elseif (v.type == "resistFire") then
									icon = "|TInterface\\Icons\\spell_fire_firearmor:12:12:0:0|t";
								end
								msg = msg .. "        " .. icon .. " |cFFFFAE42" .. k .. "  ";
								msg = msg .. "|cFF9CD6DE" .. NWB:getTimeString(v.timeLeft, true) .. ".|r\n";
							end
						end
					end
				end
			end
		end
		--msg2 = msg2 .. msg;
		NWBbuffListFrame.EditBox:Insert(msg);
	end
	--NWBbuffListFrame.EditBox:SetText(msg2);
	--NWBbuffListFrame:SetVerticalScroll(scroll);
end

SLASH_NWBDMFBUFFSCMD1, SLASH_NWBDMFBUFFSCMD2 = '/buff', '/buffs';
function SlashCmdList.NWBDMFBUFFSCMD(msg, editBox)
	NWB:openBuffListFrame();
end

---====================---
---Layer tracking frame---
---====================---

local NWBlayerFrame = CreateFrame("ScrollFrame", "NWBlayerFrame", UIParent, "InputScrollFrameTemplate");
NWBlayerFrame:Hide();
NWBlayerFrame:SetToplevel(true);
NWBlayerFrame:SetMovable(true);
NWBlayerFrame:EnableMouse(true);
tinsert(UISpecialFrames, "NWBlayerFrame");
NWBlayerFrame:SetPoint("CENTER", UIParent, 0, 100);
NWBlayerFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8",insets = {top = 0, left = 0, bottom = 0, right = 0}});
NWBlayerFrame:SetBackdropColor(0,0,0,.5);
NWBlayerFrame.CharCount:Hide();
NWBlayerFrame:SetFrameStrata("HIGH");
NWBlayerFrame.EditBox:SetAutoFocus(false);
NWBlayerFrame.EditBox:SetScript("OnKeyDown", function(self, arg)
	--If control key is down keep focus for copy/paste to work.
	--Otherwise remove focus so "enter" can be used to open chat and not have a stuck cursor on this edit box.
	if (not IsControlKeyDown()) then
		NWBlayerFrame.EditBox:ClearFocus();
	end
end)
NWBlayerFrame.EditBox:SetScript("OnShow", function(self, arg)
	NWBlayerFrame:SetVerticalScroll(0);
end)
local buffUpdateTime = 0;
NWBlayerFrame:HookScript("OnUpdate", function(self, arg)
	--Only update once per second.
	if (GetServerTime() - buffUpdateTime > 0 and self:GetVerticalScrollRange() == 0) then
		NWB:recalclayerFrame();
		buffUpdateTime = GetServerTime();
	end
end)
NWBlayerFrame.fs = NWBlayerFrame:CreateFontString("NWBlayerFrameFS", "HIGH");
NWBlayerFrame.fs:SetPoint("TOP", 0, -0);
NWBlayerFrame.fs:SetFont(NWB.regionFont, 14);
NWBlayerFrame.fs:SetText("|cFFFF5100[NovaWorldBuffs]|r");

NWBlayerFrame.fs2 = NWBlayerFrame:CreateFontString("NWBlayerFrameFS", "HIGH");
NWBlayerFrame.fs2:SetPoint("TOPLEFT", 0, -14);
NWBlayerFrame.fs2:SetFont(NWB.regionFont, 14);
NWBlayerFrame.fs2:SetText("|cFF9CD6DETarget any NPC to see your current layer.|r");

local NWBlayerDragFrame = CreateFrame("Frame", "NWBlayerDragFrame", NWBlayerFrame);
NWBlayerDragFrame:SetToplevel(true);
NWBlayerDragFrame:EnableMouse(true);
NWBlayerDragFrame:SetWidth(205);
NWBlayerDragFrame:SetHeight(38);
NWBlayerDragFrame:SetPoint("TOP", 0, 4);
NWBlayerDragFrame:SetFrameLevel(131);
NWBlayerDragFrame.tooltip = CreateFrame("Frame", "NWBlayerDragTooltip", NWBlayerDragFrame, "TooltipBorderedFrameTemplate");
NWBlayerDragFrame.tooltip:SetPoint("CENTER", NWBlayerDragFrame, "TOP", 0, 12);
NWBlayerDragFrame.tooltip:SetFrameStrata("TOOLTIP");
NWBlayerDragFrame.tooltip:SetFrameLevel(9);
NWBlayerDragFrame.tooltip:SetAlpha(.8);
NWBlayerDragFrame.tooltip.fs = NWBlayerDragFrame.tooltip:CreateFontString("NWBlayerDragTooltipFS", "HIGH");
NWBlayerDragFrame.tooltip.fs:SetPoint("CENTER", 0, 0.5);
NWBlayerDragFrame.tooltip.fs:SetFont(NWB.regionFont, 12);
NWBlayerDragFrame.tooltip.fs:SetText("Hold to drag");
NWBlayerDragFrame.tooltip:SetWidth(NWBlayerDragFrame.tooltip.fs:GetStringWidth() + 16);
NWBlayerDragFrame.tooltip:SetHeight(NWBlayerDragFrame.tooltip.fs:GetStringHeight() + 10);
NWBlayerDragFrame:SetScript("OnEnter", function(self)
	NWBlayerDragFrame.tooltip:Show();
end)
NWBlayerDragFrame:SetScript("OnLeave", function(self)
	NWBlayerDragFrame.tooltip:Hide();
end)
NWBlayerDragFrame.tooltip:Hide();
NWBlayerDragFrame:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent().isMoving) then
		self:GetParent().EditBox:ClearFocus();
		self:GetParent():StartMoving();
		self:GetParent().isMoving = true;
		--self:GetParent():SetUserPlaced(false);
	end
end)
NWBlayerDragFrame:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent().isMoving) then
		self:GetParent():StopMovingOrSizing();
		self:GetParent().isMoving = false;
	end
end)
NWBlayerDragFrame:SetScript("OnHide", function(self)
	if (self:GetParent().isMoving) then
		self:GetParent():StopMovingOrSizing();
		self:GetParent().isMoving = false;
	end
end)

--Top right X close button.
local NWBlayerFrameClose = CreateFrame("Button", "NWBlayerFrameClose", NWBlayerFrame, "UIPanelCloseButton");
NWBlayerFrameClose:SetPoint("TOPRIGHT", -5, 8.6);
NWBlayerFrameClose:SetWidth(31);
NWBlayerFrameClose:SetHeight(31);
NWBlayerFrameClose:SetScript("OnClick", function(self, arg)
	NWBlayerFrame:Hide();
end)

--Config button.
local NWBlayerFrameConfButton = CreateFrame("Button", "NWBlayerFrameConfButton", NWBlayerFrameClose, "UIPanelButtonTemplate");
NWBlayerFrameConfButton:SetPoint("CENTER", -58, 1);
NWBlayerFrameConfButton:SetWidth(90);
NWBlayerFrameConfButton:SetHeight(17);
NWBlayerFrameConfButton:SetText(L["Options"]);
NWBlayerFrameConfButton:SetNormalFontObject("GameFontNormalSmall");
NWBlayerFrameConfButton:SetScript("OnClick", function(self, arg)
	--Opening the frame needs to be run twice to avoid a bug.
	InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
	--Hack to fix the issue of interface options not opening to menus below the current scroll range.
	--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
	local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
	if (min < max) then
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
	end
	InterfaceOptionsFrame_OpenToCategory("NovaWorldBuffs");
end)
NWBlayerFrameConfButton:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent().EditBox:ClearFocus();
		self:GetParent():GetParent():StartMoving();
		self:GetParent():GetParent().isMoving = true;
	end
end)
NWBlayerFrameConfButton:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)
NWBlayerFrameConfButton:SetScript("OnHide", function(self)
	if (self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)

--Buffs button.
local NWBlayerFrameBuffsButton = CreateFrame("Button", "NWBlayerFrameBuffsButton", NWBlayerFrameClose, "UIPanelButtonTemplate");
NWBlayerFrameBuffsButton:SetPoint("CENTER", -58, -13);
NWBlayerFrameBuffsButton:SetWidth(90);
NWBlayerFrameBuffsButton:SetHeight(17);
NWBlayerFrameBuffsButton:SetText("Buffs");
NWBlayerFrameBuffsButton:SetNormalFontObject("GameFontNormalSmall");
NWBlayerFrameBuffsButton:SetScript("OnClick", function(self, arg)
	NWB:openBuffListFrame();
end)
NWBlayerFrameBuffsButton:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton" and not self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent().EditBox:ClearFocus();
		self:GetParent():GetParent():StartMoving();
		self:GetParent():GetParent().isMoving = true;
	end
end)
NWBlayerFrameBuffsButton:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton" and self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)
NWBlayerFrameBuffsButton:SetScript("OnHide", function(self)
	if (self:GetParent():GetParent().isMoving) then
		self:GetParent():GetParent():StopMovingOrSizing();
		self:GetParent():GetParent().isMoving = false;
	end
end)

function NWB:openLayerFrame()
	NWB:removeOldLayers();
	NWBlayerFrame.fs:SetFont(NWB.regionFont, 14);
	if (NWBlayerFrame:IsShown()) then
		NWBlayerFrame:Hide();
	else
		NWB:syncBuffsWithCurrentDuration();
		NWBlayerFrame:SetHeight(300);
		NWBlayerFrame:SetWidth(450);
		local fontSize = false
		NWBlayerFrame.EditBox:SetFont(NWB.regionFont, 14);
		NWB:recalclayerFrame();
		NWBlayerFrame.EditBox:SetWidth(NWBlayerFrame:GetWidth() - 30);
		NWBlayerFrame:Show();
		--Changing scroll position requires a slight delay.
		--Second delay is a backup.
		C_Timer.After(0.05, function()
			NWBlayerFrame:SetVerticalScroll(0);
		end)
		C_Timer.After(0.3, function()
			NWBlayerFrame:SetVerticalScroll(0);
		end)
		--So interface options and this frame will open on top of each other.
		if (InterfaceOptionsFrame:IsShown()) then
			NWBlayerFrame:SetFrameStrata("DIALOG")
		else
			NWBlayerFrame:SetFrameStrata("HIGH")
		end
	end
end

NWB.testLayers = {};
NWB.testLayers[9914] = {
	rendTimer = GetServerTime() - (10800 - 600),
	rendYell = 0,
	rendYell2 = 0,
	onyTimer = 0,
	onyYell = 0,
	onyYell2 = 0,
	onyNpcDied = 0,
	nefTimer = 0,
	nefYell = 0,
	nefYell2 = 0,
	nefNpcDied = 0,
	zanTimer = 0,
	zanYell = 0,
	zanYell2 = 0,
};
NWB.testLayers[107] = {
	rendTimer = 0,
	rendYell = 0,
	rendYell2 = 0,
	onyTimer =  GetServerTime() - (21600 - 1830),
	onyYell = 0,
	onyYell2 = 0,
	onyNpcDied = 0,
	nefTimer = 0,
	nefYell = 0,
	nefYell2 = 0,
	nefNpcDied = 0,
	zanTimer = 0,
	zanYell = 0,
	zanYell2 = 0,
};
function NWB:createNewLayer(zoneID)
	NWB.data.layers[zoneID] = {
		rendTimer = 0,
		rendYell = 0,
		rendYell2 = 0,
		onyTimer = 0,
		onyYell = 0,
		onyYell2 = 0,
		onyNpcDied = 0,
		nefTimer = 0,
		nefYell = 0,
		nefYell2 = 0,
		nefNpcDied = 0,
		zanTimer = 0,
		zanYell = 0,
		zanYell2 = 0,
	};
	NWB:debug("created new layer", zoneID);
end

function NWB:removeOldLayers()
	if (next(NWB.data.layers)) then
		for k, v in NWB:pairsByKeys(NWB.data.layers) do
			--Check if this layer has any current timers old than an hour expired.
			local validTimer = nil;
			if ((v.rendTimer + 3600) > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
				validTimer = true;
			end
			if ((v.onyNpcDied > v.onyTimer) and
					(v.onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
				validTimer = true;
			elseif ((v.onyTimer + 3600) > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
				validTimer = true;
			end
			if ((v.nefNpcDied > v.nefTimer) and
					(v.nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
				validTimer = true;
			elseif ((v.nefTimer + 3600) > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
				validTimer = true;
			end
			if (not validTimer) then
				NWB.data.layers[k] = nil;
				--NWB.data.layers[k] = nil;
			end
		end
	end
end

function NWB:recalclayerFrame()
	--if (NWB.isDebug and not next(NWB.data.layers)) then
		--NWB.data.layers = NWB.testLayers;
	--end
	--local scroll = NWBlayerFrame:GetVerticalScroll();
	NWBlayerFrame.EditBox:SetText("\n\n");
	local count = 0;
	local foundTimers;
	table.sort(NWB.data.layers);
	--for k, v in NWB:pairsByKeys(NWB.data.layers) do
	for k, v in NWB:pairsByKeys(NWB.data.layers) do
		foundTimers = true;
		count = count + 1;
		--if (NWB.isDebug) then
		--	NWBlayerFrame.EditBox:Insert("\n|cff00ff00[Layer " .. count .. "]|r (zone id: " .. k .. ")\n");
		--else
			NWBlayerFrame.EditBox:Insert("\n|cff00ff00[Layer " .. count .. "]|r\n");
		--end
		local msg = "";
		if (NWB.faction == "Horde" or NWB.db.global.allianceEnableRend) then
			if (v.rendTimer > (GetServerTime() - NWB.db.global.rendRespawnTime)) then
				msg = msg .. L["rend"] .. ": " .. NWB:getTimeString(NWB.db.global.rendRespawnTime - (GetServerTime() - v.rendTimer), true) .. ".";
				if (NWB.db.global.showTimeStamp) then
					local timeStamp = NWB:getTimeFormat(v.rendTimer + NWB.db.global.rendRespawnTime);
					msg = msg .. " (" .. timeStamp .. ")";
				end
			else
				msg = msg .. L["rend"] .. ": " .. L["noCurrentTimer"] .. ".";
			end
		end
		NWBlayerFrame.EditBox:Insert(NWB.chatColor .. msg .. "\n");
		msg = "";
		if ((v.onyNpcDied > v.onyTimer) and
				(v.onyNpcDied > (GetServerTime() - NWB.db.global.onyRespawnTime))) then
			if (NWB.faction == "Horde") then
				msg = msg .. string.format(L["onyxiaNpcKilledHordeWithTimer"], NWB:getTimeString(GetServerTime() - v.onyNpcDied, true));
			else
				msg = msg .. string.format(L["onyxiaNpcKilledAllianceWithTimer"], NWB:getTimeString(GetServerTime() - v.onyNpcDied, true));
			end
		elseif (v.onyTimer > (GetServerTime() - NWB.db.global.onyRespawnTime)) then
			msg = msg .. L["onyxia"] .. ": " .. NWB:getTimeString(NWB.db.global.onyRespawnTime - (GetServerTime() - v.onyTimer), true) .. ".";
			if (NWB.db.global.showTimeStamp) then
				local timeStamp = NWB:getTimeFormat(v.onyTimer + NWB.db.global.onyRespawnTime);
				msg = msg .. " (" .. timeStamp .. ")";
			end
		else
			msg = msg .. L["onyxia"] .. ": " .. L["noCurrentTimer"] .. ".";
		end
		NWBlayerFrame.EditBox:Insert(NWB.chatColor .. msg .. "\n");
		msg = "";
		if ((v.nefNpcDied > v.nefTimer) and
				(v.nefNpcDied > (GetServerTime() - NWB.db.global.nefRespawnTime))) then
			if (NWB.faction == "Horde") then
				msg = msg .. string.format(L["nefarianNpcKilledHordeWithTimer"], NWB:getTimeString(GetServerTime() - v.nefNpcDied, true));
			else
				msg = msg .. string.format(L["nefarianNpcKilledAllianceWithTimer"], NWB:getTimeString(GetServerTime() - v.nefNpcDied, true));
			end
		elseif (v.nefTimer > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
			msg = L["nefarian"] .. ": " .. NWB:getTimeString(NWB.db.global.nefRespawnTime - (GetServerTime() - v.nefTimer), true) .. ".";
			if (NWB.db.global.showTimeStamp) then
				local timeStamp = NWB:getTimeFormat(v.nefTimer + NWB.db.global.nefRespawnTime);
				msg = msg .. " (" .. timeStamp .. ")";
			end
		else
			msg = msg .. L["nefarian"] .. ": " .. L["noCurrentTimer"] .. ".";
		end
		NWBlayerFrame.EditBox:Insert(NWB.chatColor .. msg .. "\n");
		if ((v.rendTimer + 3600) > (GetServerTime() - NWB.db.global.rendRespawnTime)
				or (v.onyTimer + 3600) > (GetServerTime() - NWB.db.global.onyRespawnTime)
				or (v.nefTimer + 3600) > (GetServerTime() - NWB.db.global.nefRespawnTime)) then
			NWB:removeOldLayers();
		end
	end
	if (not foundTimers) then
		NWBlayerFrame.EditBox:Insert(NWB.chatColor .. "\nNo current timers found.");
	end
	NWB:setCurrentLayerText();
	--NWBlayerFrame.EditBox:SetText(msg2);
	--NWBlayerFrame:SetVerticalScroll(scroll);
end

local f = CreateFrame("Frame");
f:RegisterEvent("UNIT_TARGET");
f:RegisterEvent("PLAYER_TARGET_CHANGED");
f:SetScript('OnEvent', function(self, event, ...)
	NWB:setCurrentLayerText();
end)

NWB.lastKnownLayer = 1;
NWB.lastKnownLayerID = 0;
function NWB:setCurrentLayerText()
	if (not NWB.isLayered) then
		return;
	end
	local _, _, zone = NWB.dragonLib:GetPlayerZonePosition();
	local GUID = UnitGUID("target");
	local zoneID, npcID;
	if (GUID) then
		_, _, _, _, zoneID, npcID = strsplit("-", GUID);
	end
	if (NWB.faction == "Horde" and (zone ~= 1454 or not UnitExists("target") or not npcID)) then
		NWBlayerFrame.fs2:SetText("|cFF9CD6DETarget any NPC in Orgrimmar to see your current layer.|r");
		return;
	end
	if (NWB.faction == "Alliance" and (zone ~= 1453 or not UnitExists("target") or not npcID)) then
		NWBlayerFrame.fs2:SetText("|cFF9CD6DETarget any NPC in Stormwind to see your current layer.|r");
		return;
	end
	local count = 0;
	for k, v in NWB:pairsByKeys(NWB.data.layers) do
		count = count + 1;
		if (k == tonumber(zoneID)) then
			NWBlayerFrame.fs2:SetText("|cFF9CD6DEYour are currently on |cff00ff00[Layer " .. count .. "]|cFF9CD6DE.|r");
			NWB.lastKnownLayer = count;
			NWB.lastKnownLayerID = k;
			return;
		end
	end
	NWBlayerFrame.fs2:SetText("|cFF9CD6DECan't find current layer or no timers active for this layer.|r");
end

--Reset layers one time, needed when upgrading from old version.
--Old version copys over the whole table from new version users and prevents a proper new layer being created with that id.
function NWB:resetLayerData()
	if (NWB.db.global.resetLayers) then
		NWB.data.layers = {};
		NWB.db.global.resetLayers = false;
	end
end

SLASH_NWBLAYERSCMD1, SLASH_NWBLAYERSCMD2 = '/layer', '/layers';
function SlashCmdList.NWBLAYERSCMD(msg, editBox)
	NWB:openLayerFrame();
end
