---@type Data
local Data = ECSLoader:ImportModule("Data")
---@type DataUtils
local DataUtils = ECSLoader:ImportModule("DataUtils")

local _GetTalentModifierDefense, _GetItemModifierBlockValue, _GetDefenseValueOnItems


---@return number
function Data:GetArmorValue()
    local _, effectiveArmor = UnitArmor("player")
    return DataUtils:Round(effectiveArmor, 2)
end

---@return string
function Data:GetDefenseValue()
    local numSkills = GetNumSkillLines()
    local skillIndex = 0

    for i = 1, numSkills do
        local skillName = select(1, GetSkillLineInfo(i))
        local isHeader = select(2, GetSkillLineInfo(i))

        if (isHeader == nil or (not isHeader)) and (skillName == DEFENSE) then
            skillIndex = i
            break;
        end
    end

    local skillRank = 0
    local skillModifier = 0
    if (skillIndex > 0) then
        skillRank = select(4, GetSkillLineInfo(skillIndex))
        skillModifier = select(6, GetSkillLineInfo(skillIndex))
    end

    skillModifier = skillModifier + _GetTalentModifierDefense()

    return skillRank .. " + " .. skillModifier
end

_GetDefenseValueOnItems = function ()
    local defense = 0
    for i = 1, 18 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            local stats = GetItemStats(itemLink)
            if stats then
                local statDefense = stats["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"]
                if statDefense then
                    defense = defense + statDefense + 1
                end
            end
            local enchant = DataUtils:GetEnchantFromItemLink(itemLink)
            if enchant and enchant == Data.enchantIds.BRACER_MANA_REGENERATION then
                defense = defense + 4
            end
            -- Priest ZG Enchant
            if enchant and enchant == Data.enchantIds.PROPHETIC_AURA then
                defense = defense + 4
            end
        end
    end

    -- Check weapon enchants (e.g. Mana Oil)
    local hasMainEnchant, _, _, mainHandEnchantID = GetWeaponEnchantInfo()
    mainHandEnchantID = tostring(mainHandEnchantID)
    if (hasMainEnchant) then
        if mainHandEnchantID == Data.enchantIds.BRILLIANT_MANA_OIL then
            defense = defense + 12
        end
        if mainHandEnchantID == Data.enchantIds.LESSER_MANA_OIL then
            defense = defense + 8
        end
        if mainHandEnchantID == Data.enchantIds.MINOR_MANA_OIL then
            defense = defense + 4
        end
    end

    return defense
end

---@return number
_GetTalentModifierDefense = function()
    local _, _, classId = UnitClass("player")
    local mod = 0

    if classId == Data.WARRIOR then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 2)
        mod = points * 2 -- 0-10 Anticipation
    end

    return mod
end

---@return string
function Data:GetDodgeChance()
    return DataUtils:Round(GetDodgeChance(), 2) .. "%"
end

---@return string
function Data:GetParryChance()
    return DataUtils:Round(GetParryChance(), 2) .. "%"
end

---@return string
function Data:GetBlockChance()
    return DataUtils:Round(GetBlockChance(), 2) .. "%"
end

---@return number
function Data:GetBlockValue()
    local setBonus = _GetItemModifierBlockValue()
    local blockValue = GetShieldBlock() + setBonus

    return DataUtils:Round(blockValue, 2)
end

_GetItemModifierBlockValue = function()
    local mod = 0

    if Data:HasSetBonusModifierBlockValue() then
        mod = mod + 30
    end

    return mod
end