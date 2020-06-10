local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

local function Refresh()
	BCT.SetItems()
	BCT.SetBuffs()
	BCT.SetHidden()
	BCT.SetAurasSorted()
	BCT.RemoveBlacklistedBuffs()
end
BCT.Refresh = Refresh

local function ZoneChange()
	if BCT.session.state.zone ~= GetInstanceInfo() then
		local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
		local groupState = (not IsInGroup()) and "Solo" or 
			((IsInGroup() and not IsInRaid()) and "Group" or "Raid")

		if BCT.session.db.loading.instanceStateFrames[tonumber(maxPlayers)] and
			BCT.session.db.loading.groupStateFrames[(instanceType == "pvp" and "Battleground" or groupState)] then
			BCT.session.db.loading.enabledFrames = true
		else
			BCT.session.db.loading.enabledFrames = false
		end
		
		if BCT.session.db.loading.instanceStateAnn[tonumber(maxPlayers)] and
			BCT.session.db.loading.groupStateAnn[(instanceType == "pvp" and "Battleground" or groupState)] then
			BCT.session.db.loading.enabledAnn = true
		else
			BCT.session.db.loading.enabledAnn = false
		end
		
		if BCT.session.db.loading.instanceStateBL[tonumber(maxPlayers)] and
			BCT.session.db.loading.groupStateBL[(instanceType == "pvp" and "Battleground" or groupState)] then
			BCT.session.db.loading.enabledBL = true
		else
			BCT.session.db.loading.enabledBL = false
		end
		
		if BCT.session.db.loading.instanceState[tonumber(maxPlayers)] and
			BCT.session.db.loading.groupState[(instanceType == "pvp" and "Battleground" or groupState)] then
			BCT.session.db.loading.enabled = true
		else
			BCT.session.db.loading.enabled = false
		end
		
		if BCT.session.db.loading.instanceStateHl[tonumber(maxPlayers)] and
			BCT.session.db.loading.groupStateHl[(instanceType == "pvp" and "Battleground" or groupState)] then
			BCT.session.db.loading.enabledHl = true
		else
			BCT.session.db.loading.enabledHl = false
		end
		
		BCT.UpdateRaid()
		BCT.SetInCombatBlacklistingMacro(true)
		BCT.UpdateWindowState()
		BCT.session.state.zone = GetInstanceInfo()
	end
end
BCT.ZoneChange = ZoneChange

local FrameStateTicker = C_Timer.NewTicker(0.1, function() BCT.ZoneChange() end)

BCT.Events:RegisterUnitEvent("UNIT_AURA", "player")
BCT.Events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
BCT.Events:RegisterEvent("PLAYER_LOGIN")
BCT.Events:RegisterEvent("PLAYER_REGEN_ENABLED")

BCT.Events:SetScript("OnEvent", function(self, event, ...)
	local _, _, classIndex = UnitClass("player")
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		
		local _, subEvent, _, _, sourceName, _, _, _, destName, _, _, spellId, spellName, _, missType = CombatLogGetCurrentEventInfo()
		if classIndex == 1 then BCT.SetDefensiveState(subEvent, spellId, spellName, sourceName, destName, missType) end
		if subEvent == "SPELL_AURA_REMOVED" and destName == UnitName("player") then BCT.Announce(spellName) end
		if (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED") then 
			if UnitInParty(destName) then
				BCT.UpdateRaid(destName)
			end
		end
		return
	end
	if event == "UNIT_AURA" then
		BCT.UpdateRaid(UnitName("player"))
		BCT.Refresh()
		return
	end
	if event == "PLAYER_LOGIN" then
		BCT.SetRangeTicker()
		BCT.SetReservedBuffs()
		BCT.UpdateRaid()
		BCT.UpdateRaid(UnitName("player"))
		BCT.UpdateFont()
		BCT.UpdateFontAnnouncer()
		BCT.UpdateWindowState()
		BCT.SetInCombatBlacklistingMacro()
		BCT.profileStr = BCT.db:GetCurrentProfile()
		BCT.Refresh()
		return
	end
	if event == "PLAYER_REGEN_ENABLED" and BCT.session.state.CombatCache then
		BCT.SetInCombatBlacklistingMacro()
		BCT.session.state.CombatCache = false
		return
	end
end)