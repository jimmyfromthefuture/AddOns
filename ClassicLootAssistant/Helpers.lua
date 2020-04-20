function cla_callback(duration, callback)
    local newFrame = CreateFrame("Frame")
    newFrame:SetScript("OnUpdate", function (self, elapsed)
        duration = duration - elapsed
        if duration <= 0 then
            callback()
            newFrame:SetScript("OnUpdate", nil)
        end
    end)
end

function cla_has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function cla_has_item_value(tab, val)
    for index, value in ipairs(tab) do
        local splitResult = cla_mysplit(value, ':')
        local itemId = splitResult[2] -- itemId

        if itemId == val then
            return true
        end
    end

    return false
end

function cla_table_find_player(tab, name)
    for index, value in ipairs(tab) do
        if type(value) == "string" then
            if value == name then
                return value
            end
        else
            if value.player == name then
                return value
            end
        end
    end

    return nil
end

function cla_mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end

function cla_print_color(text, color)
    print("\124cff" .. color .. "[Classic Loot Assistant]: " .. text .. "\124r")
end

function cla_bool_to_string(bool)
    return bool and 'true' or 'false'
end

function cla_get_channel()
    if IsInRaid() then
        return "RAID"
    else
        return "PARTY"
    end
end

function cla_get_player_name(name)
    local splits = cla_mysplit(name, "-")

    return splits[1]
end
