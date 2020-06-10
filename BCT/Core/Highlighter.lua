local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local GetFrame = LibStub("LibGetFrame-1.0").GetFrame
local LCG = LibStub("LibCustomGlow-1.0")
local rc = LibStub("LibRangeCheck-2.0")

local function SetReservedBuffs()
	BCT.session.state.reservedBuffs = {}
	for k,v in pairs(BCT.session.db.auras[BCT.BUFF]) do
		if v[8] then
			BCT.session.state.reservedBuffs[GetSpellInfo(k)] = true
		end
	end
end
BCT.SetReservedBuffs = SetReservedBuffs

local classBuffs = {
	[1] = 2,
	[7] = 1,
	[11] = 3,
}

local function FrameGlow(name,show,cap)
	local frames = GetFrame(name, {ignorePlayerFrame = true, ignoreTargetFrame = true, ignoreTargettargetFrame = true, returnAll = true,})
	--local frame = GetFrame(name)
    if show then
		for k, frame in pairs(frames) do
			LCG.PixelGlow_Start(
				frame,
				{cap and BCT.session.db.highlighter.glowColorCap[1] or BCT.session.db.highlighter.glowColor[1],
				cap and BCT.session.db.highlighter.glowColorCap[2] or BCT.session.db.highlighter.glowColor[2],
				cap and BCT.session.db.highlighter.glowColorCap[3] or BCT.session.db.highlighter.glowColor[3]},
				BCT.session.db.highlighter.glowParticles,
				BCT.session.db.highlighter.glowFrequency,
				BCT.session.db.highlighter.glowLength,
				BCT.session.db.highlighter.glowThickness,
				BCT.session.db.highlighter.glowxOffset,
				BCT.session.db.highlighter.glowyOffset,
				BCT.session.db.highlighter.glowBorder
			)
		end
    else
		for k, frame in pairs(frames) do
			LCG.AutoCastGlow_Stop(frame)
			LCG.PixelGlow_Stop(frame)    
			LCG.ButtonGlow_Stop(frame)
		end
    end
end
BCT.FrameGlow = FrameGlow

local function CheckGlow(name)
	local frame = GetFrame(name)
	if frame then
		BCT.FrameGlow(name, false)
		local totalBuffs = BCT.session.state.raid[name][1] or 0
		local reservedBuffs = BCT.session.state.raid[name][2] or 0
		if BCT.session.db.highlighter.enabledCap and totalBuffs >= BCT.session.db.highlighter.cap then
			BCT.FrameGlow(name, true, true)
			return
		end
		if BCT.session.db.highlighter.enabled and reservedBuffs >= BCT.session.db.highlighter.buffer then
			BCT.FrameGlow(name, true)
		end
	end
end
BCT.CheckGlow = CheckGlow

local function DisableGlow()
	for unit=1,40 do
		local unitName = GetRaidRosterInfo(unit)
		if unitName then
			BCT.FrameGlow(unitName, false)
		end
	end
end
BCT.DisableGlow = DisableGlow

local function UpdateName(name)
	local _, _, classIdx = UnitClass(name)
	local extra = 0
	if classBuffs[classIdx] then extra = classBuffs[classIdx] end
	BCT.session.state.raid[name] = {0,0}
	for i=1,40 do 
		local buff = UnitBuff(name,i)
		if buff then
			local reserved = BCT.session.state.reservedBuffs[buff]
			BCT.session.state.raid[name][1] = (BCT.session.state.raid[name][1] or 0) + 1
			if reserved then 
				BCT.session.state.raid[name][2] = (BCT.session.state.raid[name][2] or 0) + 1
			end
		end
	end
	if BCT.session.state.raid[name][1] or 0 > 25 then
		BCT.session.state.raid[name][1] = (BCT.session.state.raid[name][1] or 0) + extra
	end
	BCT.CheckGlow(name)
end

local function UpdateRaid(name)
	if (BCT.session.db.highlighter.enabled or BCT.session.db.highlighter.enabledCap) and BCT.session.db.loading.enabled and BCT.session.db.loading.enabledHl then
		if name then -- Update name
			if BCT.session.state.rangeCheck[name] then
				UpdateName(name)
			end
		else -- Update raid
			BCT.session.state.raid = {}
			for unit=1,40 do
				local unitName, _, _, _, class, _, _, online, isDead = GetRaidRosterInfo(unit)
				if unitName and online and not isDead then
					if BCT.session.state.rangeCheck[unitName] then
						UpdateName(unitName)
					end
				end
				if unitName and (not online or isDead) then
					BCT.session.state.raid[unitName] = {0,0}
					BCT.FrameGlow(unitName, false)
				end
			end
		end
	end
end
BCT.UpdateRaid = UpdateRaid

local function RangeChecker()
	if (BCT.session.db.highlighter.enabled or BCT.session.db.highlighter.enabledCap) and BCT.session.db.loading.enabled and BCT.session.db.loading.enabledHl then
		if IsInGroup() then
			for unit=1,40 do
				local name, _, _, _, _, _,  _, online, isDead = GetRaidRosterInfo(unit)
				if name and online and not isDead then
					local minRange, maxRange = rc:GetRange(name)
					local range = true
					if maxRange == nil then
						range = false
					end
					if BCT.session.state.rangeCheck[name] ~= range then
						BCT.session.state.rangeCheck[name] = range
						BCT.UpdateRaid(name)
					end
					if not BCT.session.state.rangeCheck[name] then
						BCT.session.state.raid[name] = {0,0}
						BCT.FrameGlow(name, false)
					end
				end
				if name and (not online or isDead) then
					BCT.session.state.raid[name] = {0,0}
					BCT.FrameGlow(name, false)
				end
			end
		else
			BCT.session.state.rangeCheck[UnitName("player")] = true
		end
	end
end
BCT.RangeChecker = RangeChecker

local RangeTicker = C_Timer.NewTicker(1, function() BCT.RangeChecker() end)

local function SetRangeTicker()
	if not ((BCT.session.db.highlighter.enabled or BCT.session.db.highlighter.enabledCap) and BCT.session.db.loading.enabled and BCT.session.db.loading.enabledHl) then
		RangeTicker:Cancel()
		return
	end
	RangeTicker:Cancel()
	RangeTicker = C_Timer.NewTicker(BCT.session.db.highlighter.rangeCheckFreq, function() BCT.RangeChecker() end)
end
BCT.SetRangeTicker = SetRangeTicker