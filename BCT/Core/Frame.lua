local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")

SM:Register("font", "Expressway", [[Interface\AddOns\BCT\Fonts\Expressway.ttf]])
SM:Register("font", "PT Sans Narrow", [[Interface\AddOns\BCT\Fonts\PTSansNarrow.ttf]])

local function UpdateFont()
	BCT.Window.text:SetFont(SM:Fetch("font",BCT.session.db.window.font), BCT.session.db.window.font_size, "OUTLINE")
	BCT.Anchor.text:SetFont(SM:Fetch("font",BCT.session.db.window.font), BCT.session.db.window.font_size, "OUTLINE")
end
BCT.UpdateFont = UpdateFont

local function UpdateFrameState()
	local _, _, _, _, maxPlayers = GetInstanceInfo()
	local groupState = (not IsInGroup()) and "Solo" or 
		((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
		
	if BCT.session.db.window.show and
		BCT.session.db.loading.instanceState[tonumber(maxPlayers)] and
		BCT.session.db.loading.groupState[groupState] then
		BCT.Anchor:Show()
		BCT.Window:Show()
	else
		BCT.Anchor:Hide()
		BCT.Window:Hide()
	end
	if BCT.session.db.window.mouseover then
		BCT.Window:Hide()
	end
	if BCT.session.db.window.lock then
		BCT.Anchor:SetScript("OnDragStart", nil)
		BCT.Anchor:SetScript("OnDragStop", nil)
	else
		BCT.Anchor:SetScript("OnDragStart", BCT.Anchor.StartMoving)
		BCT.Anchor:SetScript("OnDragStop", BCT.Anchor.StopMovingOrSizing)
	end
end
BCT.UpdateFrameState = UpdateFrameState

BCT.Anchor = CreateFrame("Frame","BCTAnchor",UIParent)
BCT.Anchor:SetMovable(true)
BCT.Anchor:EnableMouse(true)
BCT.Anchor:RegisterForDrag("LeftButton")
BCT.Anchor:SetWidth(200)
BCT.Anchor:SetHeight(50)
BCT.Anchor:SetAlpha(1.)
BCT.Anchor:SetPoint("CENTER",0,0)
BCT.Anchor.text = BCT.Anchor:CreateFontString(nil,"ARTWORK") 
BCT.Anchor.text:SetFont(SM:Fetch("font","Expressway"), 13, "OUTLINE")
BCT.Anchor.text:SetPoint("TOPLEFT", BCT.Anchor, "TOPLEFT", 0)
BCT.Anchor.text:SetJustifyH("LEFT")
BCT.Anchor.text:SetText("BUFF CAP TRACKER")
BCT.Anchor:SetUserPlaced(true)

BCT.Anchor:SetScript("OnUpdate", function(self) 
	if GetMouseFocus() ~= nil and BCT.session.db.window.mouseover then
		if GetMouseFocus():GetName() == "BCTAnchor" then
			BCT.Window:Show()
		else
			BCT.Window:Hide()
		end
	end
	if BCT.session.db.window.mouseover then
		self.text:SetText("BUFF CAP TRACKER - " .. BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal .. "/32")
	else
		self.text:SetText("BUFF CAP TRACKER")
	end
end)

BCT.Window = CreateFrame("Frame","BCTTxtFrame",UIParent)
BCT.Window:SetWidth(200)
BCT.Window:SetHeight(50)
BCT.Window:SetAlpha(1.)
BCT.Window:SetPoint("CENTER", BCT.Anchor, "CENTER", 0, -8)
BCT.Window.text = BCT.Window:CreateFontString(nil,"ARTWORK") 
BCT.Window.text:SetFont(SM:Fetch("font","Expressway"), 13, "OUTLINE")
BCT.Window.text:SetPoint("TOPLEFT", BCT.Window, "TOPLEFT", 0)
BCT.Window.text:SetJustifyH("LEFT")
BCT.Window.text:SetText("Something is wrong")

BCT.Window:SetScript("OnUpdate", function(self) 
	BCT.BuildBuffString()
	BCT.BuildEnchantString()
	BCT.BuildTrackedString()
	BCT.BuildNextFiveString()
	
    local txt = (
		(BCT.session.db.window.enchants and 
			"\nENCHANTS: " .. BCT.enchantsStr .. "/" .. BCT.enchantsTotal or "") ..
        "\nBUFFS: " .. BCT.buffStr .. "/" .. BCT.aurasMax ..
        --"\nAUTO REMOVAL: " .. GetBuffRemovalString() ..
        "\n\nNEXT: " .. BCT.nextAura ..
		(BCT.session.db.window.nextfive and 
			"\n" .. BCT.nextFiveStr or "\n") ..
		BCT.trackedStr ..
		(BCT.session.db.window.profileTxt and "PROFILE: |cff0080ff" .. BCT.profileStr or "|r")
	)
	self.text:SetText(txt)
	
end)

