local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

local function RemoveBlacklistedBuffs()
	local openSlots = 32 - (BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal)
	
	if BCT.session.db.blacklisting.enabledOut and openSlots <= tonumber(BCT.session.db.blacklisting.buffer) and not UnitAffectingCombat("player") then
		for k, v in pairs(BCT.session.db.auras["auras_visible"]) do
			if v[6] == BCT.PLAYERBUFF or v[6] == BCT.PERSONALS then
				for i=1,40 do
					local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player",i)
					if GetSpellInfo(k) == name then
						CancelUnitBuff("player", i)
						openSlots = 32 - (BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal)
						if openSlots > tonumber(BCT.session.db.blacklisting.buffer) then break end
					end
				end
			else
				for i=1,40 do
					local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player",i)
					local found = BCT.session.db.auras["auras_visible"][tonumber(spellId)]
					if found then
						local buffType = found[6]
						local blacklisted = found[5]
						if blacklisted then
							CancelUnitBuff("player", i)
							openSlots = 32 - (BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal)
							if openSlots > tonumber(BCT.session.db.blacklisting.buffer) then break end
						end
					end
				end
			end
		end
	end
	
end
BCT.RemoveBlacklistedBuffs = RemoveBlacklistedBuffs

BCT.BlacklistButton = CreateFrame('Button', "BCT", nil, 'SecureActionButtonTemplate,SecureHandlerBaseTemplate')
BCT.BlacklistButton:SetAttribute('type', 'macro');
BCT.BlacklistButton:SetAttribute('macrotext', '/click BCT1');

BCT.BlacklistButtons = {}

local function SetInCombatBlacklistingMacro()

	BCT.session.state.macros = ""

	if not UnitAffectingCombat("player") then
		if BCT.session.db.blacklisting.enabledIn then
			local names = {}

			for k,v in pairs(BCT.session.db.auras["auras_visible"]) do
				local name = GetSpellInfo(k)
				if v[5] then table.insert(names,name) end
			end
			
			local macros = {}
			
			local j = 1
			for i=1,#names,1 do
				if string.len(macros[j] or "") + string.len("/cancelaura " .. names[i] .. "\n" or "") + 12 >= 255 then 
					macros[j] = macros[j] .. "/click BCT" .. j + 1 
					j = j + 1 
				end
					macros[j] = (macros[j] or "") .. "/cancelaura " .. names[i] .. "\n"
					BCT.session.state.macros = (BCT.session.state.macros or "") .. "/cancelaura " .. names[i] .. "\n"
			end
			macros[j] = (macros[j] or "") .. "/click BCT" .. j + 1 
			
			-- Make sure theres enough buttons available
			for i=#BCT.BlacklistButtons+1,#macros,1 do
				BCT.BlacklistButtons[i] = CreateFrame('Button', "BCT" .. i, nil, 'SecureActionButtonTemplate,SecureHandlerBaseTemplate')
				BCT.BlacklistButtons[i]:SetAttribute('type', 'macro');
			end
			
			-- Clean buttons
			for i=1,#BCT.BlacklistButtons,1 do
				BCT.BlacklistButtons[i]:SetAttribute('macrotext', "");
			end
			
			-- Set macro txt (Enable)
			for i=1,#macros,1 do
				BCT.BlacklistButtons[i]:SetAttribute('macrotext', macros[i]);
			end

		else
			-- Set macro txt (Disable)
			for i=1,#BCT.BlacklistButtons,1 do
				BCT.BlacklistButtons[i]:SetAttribute('macrotext', "");
			end
		end
	else
		print("BCT failed to change in-combat blacklisting macro due to combat, change will be applied once combat is dropped.")
		BCT.session.state.CombatCache = true
	end

end
BCT.SetInCombatBlacklistingMacro = SetInCombatBlacklistingMacro