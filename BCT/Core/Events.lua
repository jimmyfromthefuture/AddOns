local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")


local function Refresh()
	BCT.SetItems()
	BCT.SetBuffs()
	BCT.SetHidden()
	BCT.SetAurasSorted()
	BCT.RemoveBlacklistedBuffs()
end
BCT.Refresh = Refresh

BCT.Events:RegisterUnitEvent("UNIT_AURA", "player")
BCT.Events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
BCT.Events:RegisterEvent("PLAYER_LOGIN")
BCT.Events:RegisterEvent("PLAYER_ENTERING_WORLD")
BCT.Events:RegisterEvent("PLAYER_REGEN_ENABLED")

BCT.Events:SetScript("OnEvent", function(self, event, ...)
	local _, _, classIndex = UnitClass(UnitName("player"))
	if event == "COMBAT_LOG_EVENT_UNFILTERED" and classIndex == 1 then
		local _, subEvent, _, _, sourceName, _, _, _, destName, _, _, spellId, spellName, _, missType = CombatLogGetCurrentEventInfo()
		BCT.SetDefensiveState(subEvent, spellId, spellName, sourceName, destName, missType)
		return
	end
	BCT.Refresh()
	if event == "PLAYER_LOGIN" then
		BCT.UpdateFont()
		BCT.UpdateFontAnnouncer()
		BCT.UpdateFrameState()
		BCT.SetInCombatBlacklistingMacro()
		BCT.profileStr = BCT.db:GetCurrentProfile()
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		BCT.UpdateFrameState()
		return
	end
	if event == "PLAYER_REGEN_ENABLED" and BCT.session.state.CombatCache then
		BCT.SetInCombatBlacklistingMacro()
		BCT.session.state.CombatCache = false
		return
	end
end)