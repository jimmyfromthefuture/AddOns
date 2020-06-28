local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")

SM:Register("font", "Expressway", [[Interface\AddOns\BCT\Fonts\Expressway.ttf]])
SM:Register("font", "PT Sans Narrow", [[Interface\AddOns\BCT\Fonts\PTSansNarrow.ttf]])

local function UpdateFont()
	BCT.Window.text:SetFont(SM:Fetch("font",BCT.session.db.window.body.font), BCT.session.db.window.body.font_size, BCT.session.db.window.body.font_style)
	BCT.Anchor.text:SetFont(SM:Fetch("font",BCT.session.db.window.anchor.font), BCT.session.db.window.anchor.font_size, BCT.session.db.window.anchor.font_style)
end
BCT.UpdateFont = UpdateFont

local function UpdateWindowState()
	if BCT.Anchor:GetWidth() ~= BCT.session.db.window.anchor.width or
		BCT.Anchor:GetHeight() ~= BCT.session.db.window.anchor.height then
		BCT.Anchor:SetWidth(BCT.session.db.window.anchor.width)
		BCT.Anchor:SetHeight(BCT.session.db.window.anchor.height)
		BCT.Window:SetWidth(BCT.session.db.window.body.width)
		BCT.Window:SetHeight(BCT.session.db.window.body.height)
	end
	if BCT.session.db.window.enable and BCT.session.db.loading.enabled and BCT.session.db.loading.enabledFrames then
		BCT.Anchor:Show()
		BCT.Window:Show()
	else
		BCT.Anchor:Hide()
		BCT.Window:Hide()
	end
	if BCT.session.db.window.body.mouseover then
		BCT.Window:Hide()
	end
	if BCT.session.db.window.lock then
		BCT.Anchor:SetScript("OnDragStart", nil)
		BCT.Anchor:SetScript("OnDragStop", nil)
		BCT.Anchor:SetBackdropColor(0,0,0,0)
	else
		BCT.Anchor:SetScript("OnDragStart", BCT.Anchor.StartMoving)
		BCT.Anchor:SetScript("OnDragStop", BCT.Anchor.StopMovingOrSizing)
		BCT.Anchor:SetBackdropColor(0,0,0,1)
	end
	BCT.Window.text:ClearAllPoints()
	if BCT.session.db.window.body.growup then
		BCT.Window.text:SetPoint("BOTTOMLEFT", BCT.Window, "TOPLEFT", BCT.session.db.window.body.x_offset, BCT.session.db.window.body.y_offset)
	else
		BCT.Window.text:SetPoint("TOPLEFT", BCT.Window, "BOTTOMLEFT", BCT.session.db.window.body.x_offset, BCT.session.db.window.body.y_offset)
	end
	BCT.Anchor.text:SetPoint("LEFT", BCT.Anchor, "LEFT", BCT.session.db.window.anchor.x_offset, BCT.session.db.window.anchor.y_offset)
	
	if BCT.session.db.window.anchor.clickthrough and BCT.session.db.window.lock then
		BCT.Anchor:EnableMouse(false)
	else
		BCT.Anchor:EnableMouse(true)
	end
end
BCT.UpdateWindowState = UpdateWindowState

BCT.Anchor = CreateFrame("Frame","BCTAnchor",UIParent)
BCT.Anchor:SetMovable(true)
BCT.Anchor:EnableMouse(true)
BCT.Anchor:RegisterForDrag("LeftButton")
BCT.Anchor:SetWidth(200)
BCT.Anchor:SetHeight(35)
BCT.Anchor:SetAlpha(1.)
BCT.Anchor:SetPoint("CENTER",0,0)
BCT.Anchor.text = BCT.Anchor:CreateFontString(nil,"ARTWORK") 
BCT.Anchor.text:SetFont(SM:Fetch("font","Expressway"), 13, "OUTLINE")
BCT.Anchor.text:SetPoint("LEFT", BCT.Anchor, "LEFT", 0, 0)
BCT.Anchor.text:SetJustifyH("LEFT")
BCT.Anchor.text:SetText("BUFF CAP TRACKER")
BCT.Anchor:SetUserPlaced(true)

BCT.Anchor:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	--edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }})
BCT.Anchor:SetBackdropColor(0,0,0,1)

BCT.Anchor:SetScript("OnUpdate", function(self) 

	if not TradeFrame:IsVisible() then
		if GetMouseFocus() ~= nil and BCT.session.db.window.body.mouseover then
			if GetMouseFocus():GetName() == "BCTAnchor" then
				BCT.Window:Show()
			else
				BCT.Window:Hide()
			end
		end
	end
	
	local title = BCT.session.db.window.anchor.value
	local counter = BCT.session.db.window.anchor.counter
	local buffs = BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal
	
	if string.len(title) > 0 and counter ~= "None" then
		title = title .. " - "
	end
	
	if counter == "3/32" then
		title = title .. buffs .. "/32"
	elseif counter == "3" then
		title = title .. buffs
	end
	
	self.text:SetText(title)
end)

BCT.Window = CreateFrame("Frame","BCTTxtFrame",UIParent)
BCT.Window:SetWidth(200)
BCT.Window:SetHeight(35)
BCT.Window:SetAlpha(1.)
BCT.Window:SetPoint("CENTER", BCT.Anchor, "CENTER", 0, 0)
BCT.Window.text = BCT.Window:CreateFontString(nil,"ARTWORK") 
BCT.Window.text:SetFont(SM:Fetch("font","Expressway"), 13, "OUTLINE")
BCT.Window.text:SetPoint("TOPLEFT", BCT.Window, "BOTTOMLEFT", 0, 0)
BCT.Window.text:SetJustifyH("LEFT")
BCT.Window.text:SetText("Something is wrong")

local StringBuildTicker = C_Timer.NewTicker(0.1, function() 
	BCT.BuildBuffString()
	BCT.BuildEnchantString()
	BCT.BuildTrackedString()
	BCT.BuildNextFiveString()
end)

BCT.Window:SetScript("OnUpdate", function(self) 

	local enchantsLine = (BCT.session.db.window.text["enchants"] and "ENCHANTS: " .. BCT.enchantsStr .. "/" .. BCT.enchantsTotal .. "\n" or "")
	local buffsLine = (BCT.session.db.window.text["buffs"] and "BUFFS: " .. BCT.buffStr .. "/" .. BCT.aurasMax .. "\n" or "")
	local nextLine = (BCT.session.db.window.text["nextone"] and "NEXT: " ..  BCT.nextAura .. "\n" or "")
	local trackedLine = (BCT.session.db.window.text["tracking"] and BCT.trackedStr .. "\n" or "")
	local profileLine = (BCT.session.db.window.text["profile"] and "PROFILE: |cff0080ff" .. BCT.profileStr .. "\n" ..  "|r" or "")

    local txt = (
		enchantsLine ..
        buffsLine ..
        nextLine ..
		trackedLine ..
		profileLine
	)
	
	self.text:SetText(txt)
end)

--[[
BCT.Tester = CreateFrame("Frame","BCTTester",UIParent)
BCT.Tester:SetMovable(true)
BCT.Tester:EnableMouse(true)
BCT.Tester:RegisterForDrag("LeftButton")
BCT.Tester:SetWidth(200)
BCT.Tester:SetHeight(35)
BCT.Tester:SetAlpha(1.)
BCT.Tester:SetPoint("CENTER",0,0)
BCT.Tester.text = BCT.Tester:CreateFontString(nil,"ARTWORK") 
BCT.Tester.text:SetFont(SM:Fetch("font","Expressway"), 13, "OUTLINE")
BCT.Tester.text:SetPoint("LEFT", BCT.Tester, "LEFT", -800, 0)
BCT.Tester.text:SetJustifyH("LEFT")
BCT.Tester.text:SetText("BUFF CAP TRACKER")
BCT.Tester:SetUserPlaced(true)

BCT.Tester:SetScript("OnUpdate", function(self) 
	local txt = ""
	for k,v in pairs(BCT.session.state.raid) do
		if v[1] then
			txt = txt .. k .. ": " .. v[1] .. "\n"
		end
	end
	self.text:SetText(txt)
end)
--]]