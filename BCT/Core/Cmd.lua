local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

local function DoesProfileExist(name)
	for k,v in pairs(BCT.db:GetProfiles()) do
		if name == v then return true end
	end
	return false
end

local function ChangeProfile(name)
	if DoesProfileExist(name) then
		BCT.db:SetProfile(name)
		print("BCT: Profile changed to: " .. name)
	else
		print("BCT: Requested profile does not exist.")
	end
end

SLASH_BCTSC1 = "/BCT"
function SlashCmdList.BCTSC(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	
	if cmd == "test" then
		return
	end
	if cmd == "profile" then
		ChangeProfile(args)
		return
	end
	
	InterfaceOptionsFrame_OpenToCategory(BCT.optionsFrames.BCT)
	InterfaceOptionsFrame_OpenToCategory(BCT.optionsFrames.BCT)
end