local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

function BCT:DoesProfileExist(name)
	for k,v in pairs(BCT.db:GetProfiles()) do
		if name == v then return true end
	end
	return false
end

function BCT:ChangeProfile(name)
	if BCT:DoesProfileExist(name) then
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
		for i=1,4 do
			for k, v in pairs(BCT.session.db.auras[i]) do
				if v[6] == nil then print(k) end
			end
		end
		return
	end
	if cmd == "profile" then
		BCT:ChangeProfile(args)
		return
	end
	
	InterfaceOptionsFrame_OpenToCategory(BCT.optionsFrames.BCT)
	InterfaceOptionsFrame_OpenToCategory(BCT.optionsFrames.Setup)
end