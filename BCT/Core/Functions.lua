local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

local function CleanUp()

	BCT.session.state.cleanedup = true
	
	-- duplicates
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		for t, b in pairs(BCT.session.db.auras[BCT.BUFF]) do
			if k ~= t and (v[6] == BCT.PLAYERBUFF or v[6] == BCT.PERSONALS) 
				and (b[6] == BCT.PLAYERBUFF or b[6] == BCT.PERSONALS) 
				and GetSpellInfo(k) == GetSpellInfo(t)
				and	v[9] == b[9] then
				BCT.session.db.auras[BCT.BUFF][k] = nil
				BCT.session.db.auras[BCT.BUFF][t] = nil
				print("BCT: " .. GetSpellInfo(k) .. " was removed from the aura list because of duplicates, please reload UI and confirm availability and setup of the removed buff.")
			end
		end
	end
	
	-- incompatibility issues
	for i=1,4 do
		for k, v in pairs(BCT.session.db.auras[i]) do
			if v[6] == nil then 
				BCT.session.db.auras[i][k] = nil
				print("BCT: " .. GetSpellInfo(k) .. " was removed from the aura list because of incompatibility issues with new data structure, please reload UI and confirm availability and setup of the removed buff.")
			end
		end
	end
	
	return false, false, false
end
BCT.CleanUp = CleanUp

local function GetAura(name)

	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if name == GetSpellInfo(k) then
			return true, v[5], v[3], v[8]
		end
	end
	
	return false, false, false, false
end
BCT.GetAura = GetAura

CreateFrame("GameTooltip", "BCTTooltip", nil, "GameTooltipTemplate")

----------------------------
-- Weapons Metadata (Credit sigg (RDX))
-----------------------------
-- INTERNAL: Get information about weapons buff.
-- "MainHandSlot"
-- "SecondaryHandSlot"
local function scanHand(hand)
	BCTTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	BCTTooltip:ClearLines();
	local idslot = GetInventorySlotInfo(hand);
	BCTTooltip:SetInventoryItem("player", idslot);
	local mytext, strfound = nil, nil;
	local buffname, buffrank, bufftex;
	for i = 1, BCTTooltip:NumLines() do
		mytext = _G["BCTTooltipTextLeft" .. i];
		strfound = strmatch(mytext:GetText(), "^(.*) %(%d+ [^%)]+%)$");
		if strfound then break; end
	end
	if strfound then
		strfound = gsub(strfound, " %(%d+ [^%)]+%)", "");
		buffname, buffrank = strmatch(strfound, "(.*) (%d*)$");
		if not buffname then
			buffname, buffrank = strmatch(strfound, "(.*) ([IVXLMCD]*)$");
		end
		if not buffname then
			buffname, buffrank = strmatch(strfound, "(.*)(%d)");
			-- specific fucking french language langue de feu
			if buffname then
				local a = string.len(buffname);
				buffname = string.sub(buffname, 1, a - 2);
			else 
				buffname = strfound;
			end
		end
		if not buffname then
			buffname = "unknown parse";
		end
		bufftex = GetInventoryItemTexture("player", idslot);
	end
	BCTTooltip:Hide();
	return buffname, buffrank, bufftex, idslot;
end
BCT.scanHand = scanHand

local function SetItems()
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()
	
	for i=1,17,1 do
		local itemLink = GetInventoryItemLink("player", i)
		if itemLink ~= nil then
			local itemChanged = false
			local _, _, _, _, itemId, enchantId = string.find(itemLink,
				"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

			if BCT.items[i] ~= nil then
				itemChanged = (BCT.items[i][1] ~= tonumber(itemId) or BCT.items[i][2] ~= tonumber(enchantId)) and true or false
			end

			BCT.items[i] = {
				tonumber(itemId),
				tonumber(enchantId or (i == INVSLOT_MAINHAND and tonumber(mainHandEnchantID) or tonumber(offHandEnchantId))),
				BCT.items[i] == nil and i or (itemChanged and GetTime() + i or BCT.items[i][3]), -- Position
			}
			
		end
	end

	-- Elemental Sharpening Stone
	local itemLink = GetInventoryItemLink("player", 16)
	if itemLink ~= nil then
		local buffname, buffrank, bufftex, idslot = BCT.scanHand("MainHandSlot")
		local itemChanged = false
		local _, _, _, _, itemId, enchantId = string.find(itemLink,
				"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
		local position = 18

		if BCT.items[position] ~= nil then
			itemChanged = (BCT.items[position][1] ~= tonumber(itemId) or BCT.items[position][2] ~= 2506) and true or false
		end

		BCT.items[position] = {
			tonumber(itemId),
			(buffname == "Critical" and tonumber(buffrank) == 2) and 2506 or -1,
			BCT.items[position] == nil and position or (itemChanged and GetTime() + position or BCT.items[position][3]), -- Position
		}
	end

	local itemLink = GetInventoryItemLink("player", 17)
	if itemLink ~= nil then
		local buffname, buffrank, bufftex, idslot = BCT.scanHand("SecondaryHandSlot")
		local itemChanged = false
		local _, _, _, _, itemId, enchantId = string.find(itemLink,
				"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
		local position = 19

		if BCT.items[position] ~= nil then
			itemChanged = (BCT.items[position][1] ~= tonumber(itemId) or BCT.items[position][2] ~= 2506) and true or false
		end

		BCT.items[position] = {
			tonumber(itemId),
			(buffname == "Critical" and tonumber(buffrank) == 2) and 2506 or -1,
			BCT.items[position] == nil and position or (itemChanged and GetTime() + position or BCT.items[position][3]), -- Position
		}
	end

end
BCT.SetItems = SetItems

local function SetBuffs()
	BCT.buffs = {}
		
	for i=1,40 do
        local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player",i)
        if name and duration > 0 then
            BCT.buffs[(expirationTime - duration)] = tonumber(spellId)
        end
        if name and duration == 0 then
            BCT.buffs[GetTime()+spellId] = tonumber(spellId)
        end
    end
end
BCT.SetBuffs = SetBuffs

local timer = C_Timer.NewTimer(1, function() end)
local function SetDefensiveState(subEvent, spellId, spellName, sourceName, destName, missType)

	local function DefensiveState(b)
		if b then
			BCT.session.state.DefensiveState = true
			timer:Cancel()
			timer = C_Timer.NewTimer(5, function() 
					BCT.session.state.DefensiveState = false
					BCT.Refresh()
				end
			)
		else
			BCT.session.state.DefensiveState = false
		end
		BCT.Refresh()
	end

	if (subEvent == "SWING_MISSED") and destName == UnitName("player") and
		(spellId == "BLOCK" or spellId == "DODGE" or spellId == "PARRY") then -- Melee attacks
		DefensiveState(true)
	elseif (subEvent == "SPELL_MISSED" or subEvent == "RANGE_MISSED") and destName == UnitName("player") and
		(missType == "BLOCK" or missType == "DODGE" or missType == "PARRY") then -- Abilities + Arrows
		DefensiveState(true)
	elseif (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_CAST_MISSED") and sourceName == UnitName("player") and
		(spellName == GetSpellInfo(6572) or spellName == GetSpellInfo(7384)) then
		DefensiveState(false)
	end
	
end
BCT.SetDefensiveState = SetDefensiveState

local function SetHidden()
	local i = GetTime() + 1 -- (BCT.aurasSorted[#BCT.aurasSorted] or GetTime()) + 1
	local _, _, classIndex = UnitClass("player")
	
	local function addHidden(j, tree, talent, DefState)
		if tree ~= nil then	_, _, _, _, currentRank = GetTalentInfo(tree, talent) end
		local arr = BCT.session.db.auras[BCT.OTHER]
		local isCounted = arr[j][4]
		local talentChk = tree == nil and true or tonumber(currentRank or 0) > 0
		local dsChk = DefState == nil and true or BCT.session.state.DefensiveState

		if talentChk and dsChk and isCounted then 
			BCT.hidden[i] = arr[j][1]
			i = i + 1
		end
	end
	
	local classFuncs = {
		[1] = function() 					---- Warrior
			addHidden(1, nil, nil, true)	-- Defensive State
			addHidden(2)					-- Stance
		end,
		[7] = function() 					---- Shaman
			addHidden(7, 1, 11)				-- Elemental Devastation
		end,
		[11] = function() 					---- Druid
			addHidden(4, 2, 10)				-- Predatory Strikes
			addHidden(5, 3, 2)				-- Furor
			addHidden(6, 2, 15)				-- Heart of the Wild
		end,
	}
	
	local classFunc = classFuncs[tonumber(classIndex)]

	-- reset state
	BCT.hidden = {}
	
	-- add hidden class auras
	if classFunc ~= nil then classFunc() end

	-- add tracking
	if GetTrackingTexture() ~= nil then addHidden(3) end

end
BCT.SetHidden = SetHidden

local function SetAurasSorted()
	BCT.buffsTotal, BCT.enchantsTotal, BCT.hiddenTotal, BCT.aurasTotal, BCT.aurasSorted = 0, 0, 0, 0, {}

	-- add consumables + worldbuffs + playerbuffs
    for k,v in pairs(BCT.buffs) do 
		table.insert(BCT.aurasSorted, k)
		BCT.buffsTotal = BCT.buffsTotal + 1 
    end

	-- add enchants
	for i=1,19,1 do
		if BCT.items[i] ~= nil then
			local arr = BCT.session.db.auras[BCT.ENCHANT]
			local search = arr[BCT.items[i][2]]
			if search ~= nil then
				if search[4] then 
					table.insert(BCT.aurasSorted, BCT.items[i][3])
					BCT.enchantsTotal = BCT.enchantsTotal + 1 
				end
			end
		end
	end
	
	-- add hidden
	for k, v in pairs(BCT.hidden) do
		table.insert(BCT.aurasSorted, k)
		BCT.hiddenTotal = BCT.hiddenTotal + 1
	end

    table.sort(BCT.aurasSorted)
	
	-- set next aura in line
    if next(BCT.aurasSorted) ~= nil then
		local function fill(inp) -- Prevents auto linebreak in enchants line (lua ecksdee)
			return string.len(inp) < 17 and inp .. "          " or inp
		end
        local t = BCT.aurasSorted[1]
		if BCT.buffs[t] ~= nil then
			local search = BCT.session.db.auras[BCT.BUFF]
			if search[BCT.buffs[t]] ~= nil then
				BCT.nextAura = fill(search[BCT.buffs[t]][1])
			else
				BCT.nextAura = fill(GetSpellInfo(BCT.buffs[t]))
			end
			BCT.nextAuraId = t
		elseif BCT.hidden[t] ~=	 nil then
			BCT.nextAura = fill(BCT.hidden[t])
		else
			-- enchant
			for i=1,19,1 do
				if BCT.items[i] ~= nil then
					if BCT.items[i][3] == t then
						
						BCT.nextAura = fill(BCT.session.db.auras[BCT.ENCHANT][BCT.items[i][2]][1])
					end
				end
			end
		end
	else
		BCT.nextAura = "                 " -- Prevents auto linebreak in enchants line (lua ecksdee)
	end
   
	local found, blacklisted, tracked = BCT.GetAura(BCT.nextAura:gsub("^%s*(.-)%s*$", "%1"))

	if found and tracked then
		BCT.nextAura = "|cffff0000" .. BCT.nextAura .. "|r"
	end

	-- count pushed enchants
    local counter = 32 - (BCT.buffsTotal + BCT.enchantsTotal)
	BCT.enchantsPushed = counter < 0 and abs(counter) or 0
	
	BCT.aurasMax = 32 - BCT.enchantsTotal + BCT.enchantsPushed

end
BCT.SetAurasSorted = SetAurasSorted
					
---------------------------------- String functions for display

---- tracked string

local function isNextTracked()
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
        if BCT.nextAuraId == k and v[3] then 
            return true 
        end
    end
    
    return false
end

local function GetSuffix (n)
    local lastTwo, lastOne = n % 100, n % 10
    if lastTwo > 3 and lastTwo < 21 then return "th" end
    if lastOne == 1 then return "st" end
    if lastOne == 2 then return "nd" end
    if lastOne == 3 then return "rd" end
    return "th"
end

local function Nth (n) return n .. GetSuffix(n) end

local function GetBuffNextString()
    if isNextTracked() then
        return ("|cffFF0000" .. BCT.nextAura .. "|r"):upper()
    else
        return ("|cff00FF00" .. BCT.nextAura .. "|r"):upper()
    end 
end

local function BuildBuffString()
    if (BCT.aurasMax - (BCT.buffsTotal + BCT.hiddenTotal)) <= BCT.session.db.blacklisting.buffer then
        BCT.buffStr = "|cffFF8000" .. BCT.buffsTotal + BCT.hiddenTotal .. "|r"
    elseif (BCT.aurasMax - (BCT.buffsTotal + BCT.hiddenTotal)) == 0 then
        BCT.buffStr = "|cffFF0000" .. BCT.buffsTotal + BCT.hiddenTotal .. "|r"
    else
        BCT.buffStr = "|cff00FF00" .. BCT.buffsTotal + BCT.hiddenTotal .. "|r"
    end
end
BCT.BuildBuffString = BuildBuffString

local function BuildEnchantString()
    local activeEnchants = BCT.enchantsTotal - BCT.enchantsPushed
    if (activeEnchants) < BCT.enchantsTotal then
        BCT.enchantsStr = "|cffff0000" .. activeEnchants .. "|r"
    else
        BCT.enchantsStr = "|cff00FF00" .. activeEnchants .. "|r"
    end
end
BCT.BuildEnchantString = BuildEnchantString

local function FindBuff(buffName, hasRank) -- shitty abstraction

    local key = 0;
    for k,v in pairs(BCT.buffs) do 
        if (hasRank and GetSpellInfo(tonumber(v)) == GetSpellInfo(tonumber(buffName)) or
			v == buffName) then 
            key = k
        end
    end
    
    if key > 0 then
        for k,v in pairs(BCT.aurasSorted) do 
            if v == key then 
                if k == 1 then
                    return ("|cffFF8000" .. Nth(k) .. "|r")
                else
                    return ("|cff00FF00" .. Nth(k) .. "|r")
                end
            end
        end
    end

    return "|cffFF0000N/A|r"
end

local function FindDebuff(name) -- shitty abstraction

	for i=1,40 do
		local buffname, _, _, _, _, _, _, _,  _, spellId = UnitDebuff("player", i)
		if buffname ~= nil then
			if tonumber(spellId) == name then
				return ("|cff00FF00Found|r")
			end
		end
	end
	
    return "|cffFF0000N/A|r"
end

local function GetAuraDur(name, buff, hasRank)
	local etime, timeTmp, buffname, expTime, spellId = "", "", "", "", ""

	for i=1,40 do
		if buff then
			buffname, _, _, _, _, expTime, _, _,  _, spellId = UnitBuff("player", i)
		else
			buffname, _, _, _, _, expTime, _, _,  _, spellId = UnitDebuff("player", i)
		end

		if buffname ~= nil then
			if (hasRank and GetSpellInfo(tonumber(spellId)) == GetSpellInfo(tonumber(name))
				or tonumber(spellId) == name) then
				if expTime == 0 then
					return "" 
				end
				etime = expTime
				break
			end
		end
	end
	
	if etime == "" then return "" end

    local timestamp = GetTime()
    local tmp = etime or ""
    
    if string.len(tmp) > 0 then 
        local secs = etime-timestamp
        local mins = math.floor(secs/60)
		
        if mins == 0 then 
            timeTmp = math.floor(secs) .. " secs" 
        else
            timeTmp = mins .. " mins"
        end
        
        tmp = " (" .. timeTmp .. ")" 
    end
    
    return tmp
end

local function BuildNextFiveString()

	local function GetBuffName(n)
		-- set next aura in line
		if next(BCT.aurasSorted) ~= nil and BCT.aurasSorted[n] ~= nil then
			local t = BCT.aurasSorted[n]
			if BCT.buffs[t] ~= nil then
				local search = BCT.session.db.auras[BCT.BUFF]
				if search[BCT.buffs[t]] ~= nil then
					return Nth (n) .. ": " .. search[BCT.buffs[t]][1]
				else
					return Nth (n) .. ": " .. GetSpellInfo(BCT.buffs[t])
				end
				BCT.nextAuraId = t
			elseif BCT.hidden[t] ~=	 nil then
				return Nth (n) .. ": " .. BCT.hidden[t]
			else
				-- enchant
				for i=1,19,1 do
					if BCT.items[i] ~= nil then
						if BCT.items[i][3] == t then
							
							return Nth (n) .. ": " .. BCT.session.db.auras[BCT.ENCHANT][BCT.items[i][2]][1]
						end
					end
				end
			end
		else
			return "" -- "                 "
	   end
	end
	
	BCT.nextFiveStr = ""
	
	for i=2,5,1 do
		BCT.nextFiveStr = BCT.nextFiveStr .. GetBuffName(i)
	end
	
end
BCT.BuildNextFiveString = BuildNextFiveString

local function BuildTrackedString()
    local tmp = ""
	local nl = false
	
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[3] and v[6] == BCT.CONSUMABLE then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindBuff(k) .. GetAuraDur(k, true) 
			nl = true
		end
	end
	if nl then 
		tmp = BCT.session.db.window.body.group_lines and tmp or (tmp .. "\n" )
		nl = false
	end
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[3] and v[6] == BCT.WORLDBUFF then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindBuff(k, true) .. GetAuraDur(k, true, true) 
			nl = true
		end
	end
	if nl then 
		tmp = BCT.session.db.window.body.group_lines and tmp or (tmp .. "\n" )
		nl = false
	end
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[3] and v[6] == BCT.PERSONALS then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindBuff(k) .. GetAuraDur(k, true) 
			nl = true
		end
	end
	if nl then 
		tmp = BCT.session.db.window.body.group_lines and tmp or (tmp .. "\n" )
		nl = false
	end
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[3] and v[6] == BCT.HOLIDAY then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindBuff(k) .. GetAuraDur(k, true) 
			nl = true
		end
	end
	if nl then 
		tmp = BCT.session.db.window.body.group_lines and tmp or (tmp .. "\n" )
		nl = false
	end
	for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[3] and v[6] == BCT.PLAYERBUFF then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindBuff(k) .. GetAuraDur(k, true) 
			nl = true
		end
	end
	if nl then 
		tmp = BCT.session.db.window.body.group_lines and tmp or (tmp .. "\n" )
		nl = false
	end
	for k, v in pairs(BCT.session.db.auras[BCT.DEBUFF]) do
		if v[3] and v[6] == BCT.DEBUFF then 
			tmp = tmp .. "\n" .. v[2] .. ": " .. FindDebuff(k) .. GetAuraDur(k, false)
			nl = true
		end
	end
	
	if BCT.session.db.window.text["profile"] and BCT.session.db.window.body.group_lines then
		tmp = tmp .. "\n"
	end

    BCT.trackedStr = tmp
end
BCT.BuildTrackedString = BuildTrackedString