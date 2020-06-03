local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")

local timer = C_Timer.NewTimer(1, function() end)
local function Announce(spellName)
	local found, blacklisted, tracked = BCT.GetAura(spellName)
	local blacklist = (blacklisted and BCT.session.db.announcer.enabledBl)
	local track = (tracked and BCT.session.db.announcer.enabledTrck)
	
	if found and (blacklist or track) and BCT.session.db.loading.enabled and BCT.session.db.loading.enabledAnn then
		local hex = "|cff00ff00"
		if track then hex = "|cffff0000" end

		BCT.Announcer.text:SetText(hex .. spellName:upper() .. "|r" )
		BCT.Announcer:Show()
		timer:Cancel()
		timer = C_Timer.NewTimer(3, function() BCT.Announcer:Hide() end)
	end

end
BCT.Announce = Announce

local function UpdateFontAnnouncer()
	BCT.Announcer.text:SetFont(SM:Fetch("font",BCT.session.db.announcer.font), BCT.session.db.announcer.font_size, "OUTLINE")
end
BCT.UpdateFontAnnouncer = UpdateFontAnnouncer

BCT.Announcer = CreateFrame("Frame","BCTAnnouncerFrame",UIParent)
BCT.Announcer:SetWidth(150)
BCT.Announcer:SetHeight(50)
BCT.Announcer:SetAlpha(1.)
BCT.Announcer:SetPoint("TOP",WorldFrame,0,0)
BCT.Announcer.text = BCT.Announcer:CreateFontString(nil,"ARTWORK") 
BCT.Announcer.text:SetFont(SM:Fetch("font","Expressway"), 40, "OUTLINE")
BCT.Announcer.text:SetPoint("CENTER", BCT.Announcer, 0, -100)
BCT.Announcer.text:SetText("Something is wrong")
BCT.Announcer:Hide()