local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
BCT.modules.Stats = BCT:NewModule("Stats", "AceEvent-3.0", "AceHook-3.0")
local Stats = BCT.modules.Stats

Stats.bosses = {}

Stats.scan = false

Stats.PULL = 1
Stats.DURING = 2
Stats.KILL = 3

BCTStats = {
	session = {
		boss = {
			[12118] = false, -- Lucifron
			[11982] = false, -- Magmadar
			[12259] = false, -- Gehennas
			[12057] = false, -- Garr
			[12264] = false, -- Shazzrah
			[12056] = false, -- Geddon
			[11988] = false, -- Golemagg
			[12098] = false, -- Sulfuron
			[12018] = false, -- Majordomo
			[11502] = false, -- Ragnaros
			},
		date = date("%m/%d/%y",GetTime()),
	},
	stats = {
		mc = {
			[12118] = {0,0,0}, -- Lucifron
			[11982] = {0,0,0}, -- Magmadar
			[12259] = {0,0,0}, -- Gehennas
			[12057] = {0,0,0}, -- Garr
			[12264] = {0,0,0}, -- Shazzrah
			[12056] = {0,0,0}, -- Geddon
			[11988] = {0,0,0}, -- Golemagg
			[12098] = {0,0,0}, -- Sulfuron
			[12018] = {0,0,0}, -- Majordomo
			[11502] = {0,0,0}, -- Ragnaros
		},
		zones = {
		},
	},
	snapshots = {}
}

function Stats:CheckGUID()
	local _, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, missType = CombatLogGetCurrentEventInfo()
	
	local _, _, _, _, _, npcID = string.match(destGUID or "","(%a+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)")
	
	npcID = tonumber(npcID)
	
	local isTracked = BCT.session.db.statistics.mc[npcID]
	
	if not isTracked then return end
	
	local isEngaged = Stats.bosses[npcID]
	local buffs = BCT.buffsTotal + BCT.enchantsTotal + BCT.hiddenTotal
	local timestamp = GetTime()
	
	-- Boss engaged
	if not isEngaged then
		
		Stats.bosses[npcID] = true
		BCT.session.db.statistics.mc[npcID][1] = buffs
		--date("%m/%d/%y")
	end
	
	-- Boss died
	if subEvent == "UNIT_DIED" then
		table.insert(BCTStats.snapshots, {timestamp,npcID,Stats.KILL,buffs})
	end
	
	
end

--Stats:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CheckGUID", arg)
--[[
Stats:RegisterEvent("PLAYER_REGEN_DISABLED", function() Stats.scan = true end, arg)
Stats:RegisterEvent("PLAYER_REGEN_ENABLED", function() Stats.scan = false end, arg)

Stats:RegisterEvent("PLAYER_DEAD", function() Stats.scan = false end, arg)

local ScanTicker = C_Timer.NewTicker(0.1, function() 
	if Stats.scan then
		
	end
end)
--]]
--[[
function IsBoss()
    
    local _, _, _, _, _, id_mouseover = string.match(UnitGUID("mouseover") or "","(%a+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)")
    
    if aura_env.bosses[tonumber(id_mouseover or 0)] == true then return true, UnitName("mouseover"), UnitHealth("mouseover") end
    
    if aura_env.timeTick + 0.5 < GetTime() then
        aura_env.timeTick = GetTime() 
        
        for unit in WA_IterateGroupMembers() do
            local _, _, _, _, _, id = string.match(UnitGUID(unit .. "target") or "","(%a+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)")
            
            if aura_env.bosses[tonumber(id or 0)] == true then
                return true, UnitName(unit .. "target"), UnitHealth(unit .. "target") 
            end
        end
        
    end
    
    return false
end
--]]