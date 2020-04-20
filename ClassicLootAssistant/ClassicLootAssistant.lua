local ADDON_NAME, ADDON_TABLE = ...

SLASH_CLA1 = "/cla"
CLA_VERSION = "2.3"
CLA_LOOTLIST = {} -- String encoded NAME:GUID
CLA_SKINNING_TARGET_IDS = {
    11671, -- Core hound
    11673, -- Ancient Core Hound
}
CLA_PLAYERS_WITH_ADDON = {}
CLA_ITEM_TRACKING_TABLE = {}
CLA_ONY_CLOAK_TRACKING_TABLE = {}
CLA_MESSAGE_COLOR = "96a9eb"
CLA_ADDON_PREFIX = "CLA"
CLA_AQUAL_QUINTESSENCE_ID = 17333
CLA_HOURGLASS_SAND_ID = 19183
CLA_DOWSE_SPELL_ID = 21358
CLA_CONFIG_DEFAULT = {
    showLoot = false,
    showTooltip = true,
    limitInspection = true
}
CLA_CONFIG_FRAME = nil
CLA_ITEM_FRAME = nil
CLA_PLAYER_FRAME = nil
CLA_LOOTLIST_MAP = {}

function SlashCmdList.CLA(command)
    if command == "" then               CLA_OpenAddonSettings()
    elseif command == "help" then       CLA_PrintHelp()
    elseif command == "players" then    CLA_CreatePlayersListFrame()
    elseif command == "aq" then         CLA_CreateItemListFrame(CLA_AQUAL_QUINTESSENCE_ID)
    elseif command == "osc" then        CLA_CreateOnyCloakListFrame()
    elseif command == "hs" then         CLA_CreateItemListFrame(CLA_HOURGLASS_SAND_ID)
    elseif string.sub(command, 1, 7) == "inspect" then
        local inspectionTarget = string.sub(command, 9)
        local itemId = tonumber(inspectionTarget)

        if itemId then
            CLA_CreateItemListFrame(itemId)
        else
            print("Invalid itemId " .. inspectionTarget)
        end
    else print("The command /cla " .. command .. " was not recognized")
    end
end

function CLA_OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_ChatInfo.RegisterAddonMessagePrefix("CLA")
        CLA_CreateOptionsFrame()
    elseif event == "LOOT_OPENED" then
        cla_report_loot()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        cla_render_corpse_tooltip()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGuid, spellId = ...

        if unitTarget == "player" and spellId == CLA_DOWSE_SPELL_ID then
            SendChatMessage("[Classic Loot Assistant]: I dowsed a rune!", cla_get_channel())
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target = ...

        -- Filter non-cla messages
        if prefix ~= "CLA" then return end

        -- This addon does not support SAY, YELL or GUILD so they are all filtered
        if channel == "SAY" or channel == "YELL" or channel == "GUILD" then return end

        -- Remove the realm part from the name
        sender = cla_get_player_name(sender)

        -- Used for discovering which players has the addon (and what version)
        if text == "DISCOVER" then
            cla_msg_whisper(sender, "REPORT_VER:" .. CLA_VERSION)

            return
        end

        -- LOOT_DETECTED@Creature@ItemLink
        if string.sub(text, 1, 13) == "LOOT_DETECTED" then
            local splitResult = cla_mysplit(text, '@')

            local theEvent = splitResult[1]
            local guid = splitResult[2]
            local itemLink = splitResult[3]

            if CLA_LOOTLIST_MAP[guid] ~= nil then
                local itemSplit = cla_mysplit(itemLink, ':')
                local itemId = itemSplit[2] -- itemId

                if cla_has_item_value(CLA_LOOTLIST_MAP[guid].loot, itemId) == false then
                    table.insert(CLA_LOOTLIST_MAP[guid].loot, itemLink)
                end
            else
                CLA_LOOTLIST_MAP[guid] = {
                    player = "?",
                    loot = { itemLink }
                }
            end

            return
        end

        -- Somebody reported their version. Add it to the CLA_PLAYERS_WITH_ADDON array
        if string.sub(text, 1, 10) == "REPORT_VER" then
            local addonVersion = string.sub(text, 12)

            table.insert(CLA_PLAYERS_WITH_ADDON, {
                player = sender,
                version = addonVersion
            })

            return
        end

        if text == "REPORT" then
            table.insert(CLA_PLAYERS_WITH_ADDON, {
                player = sender,
                version = "1.10"
            })

            return
        end

        if text == "ONYCLOAK" then
            local onyCloakIsEquipped = IsEquippedItem(15138);

            if onyCloakIsEquipped then
                cla_msg_whisper(sender, "REPORT_ONYCLOAK:YES")
            else
                cla_msg_whisper(sender, "REPORT_ONYCLOAK:NO")
            end

            return
        end

        if string.sub(text, 1, 13) == "DISCOVER_ITEM" then
            local itemId = tonumber(string.sub(text, 15))
            local itemCount = GetItemCount(itemId, false)
            local item = Item:CreateFromItemID(itemId);

            item:ContinueOnItemLoad(function ()
                local itemName, itemLink = GetItemInfo(itemId)
                local blockRequest = false

                if ClassicLootAssistantConfig.limitInspection then

                    if IsInRaid() then
                        local raidIndex = UnitInRaid(sender)
                        local _, rank = GetRaidRosterInfo(raidIndex)

                        if rank == 0 then -- 1 = promoted, 2 = raid leader
                            blockRequest = true
                        end
                    else
                        blockRequest = true
                    end
                end
                
                local msg = "REPORT_INSPECTION:" .. itemId .. ":"

                if blockRequest then
                    cla_msg_whisper(sender, msg .. "BLOCKED")
                else
                    cla_print_color(sender .. " inspected everyone for " .. itemLink, CLA_MESSAGE_COLOR)
                    cla_msg_whisper(sender, msg .. itemCount)
                end
            end)

            return
        end

        if string.sub(text, 1, 15) == "REPORT_ONYCLOAK" then
            local result = string.sub(text, 17);

            local entry = { player = sender, result = result };

            table.insert(CLA_ONY_CLOAK_TRACKING_TABLE, entry)

            return
        end

        if string.sub(text, 1, 17) == "REPORT_INSPECTION" then
            local item = string.sub(text, 19)

            -- First element is itemId
            -- Second element is count (if applicable)
            local res = cla_mysplit(item, ':')

            local entry = { player = sender, quantity = res[2] }

            if entry.quantity == nil then
                entry.quantity = "1+"
            end

            table.insert(CLA_ITEM_TRACKING_TABLE, entry)

            return
        end

        if string.sub(text, 1, 11) == "REPORT_ITEM" then
            local item = string.sub(text, 13)

            table.insert(CLA_ITEM_TRACKING_TABLE, { player = sender, quantity = "1+" })

            return
        end

        -- Deprecate ASAP....
        if text == "REPORT_AQ" then
            table.insert(CLA_ITEM_TRACKING_TABLE, {
                player = sender,
                quantity = "1+"
            })

            return;
        end

        -- At this point it must be a name:destGuid message.
        if CLA_LOOTLIST[text] ~= nil then
            CLA_LOOTLIST[text] = CLA_LOOTLIST[text] + 1
        else
            CLA_LOOTLIST[text] = 1
            cla_register_loot_event(text, sender)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, eventName, _, _, _, _, _, destGuid, destName = CombatLogGetCurrentEventInfo()
        local creatureDied = string.sub(destGuid, 1, 8) == "Creature"

        if eventName == "UNIT_DIED" and creatureDied then
            cla_callback(1, function()
                local hasLoot, _ = CanLootUnit(destGuid)

                if hasLoot then
                    local msg = destName .. ":" .. destGuid

                    if IsInGroup() then
                        cla_msg(msg)
                    else
                        CLA_LOOTLIST[msg] = 1

                        local pName, _ = UnitName("player")
                        cla_register_loot_event(msg, pName)
                    end

                    return
                end
            end)
        end
    end
end

function CLA_OpenAddonSettings()
    InterfaceOptionsFrame_OpenToCategory("Classic Loot Assistant")
    InterfaceOptionsFrame_OpenToCategory("Classic Loot Assistant")
    print("Use /cla help to get help on how to use the addon")
end

function CLA_PrintHelp()
    print([[The following commands are available for Classic Loot Assistant
              /cla -- Opens the addon settings
              /cla players -- Shows the players with the addon enabled in your party/raid group
              /cla aq -- Shows the players with the Aqual Quintessence in their inventory
              /cla inspect <itemId> -- Inspects players in the group for an item of the itemId
          ]])
end

function CLA_CreatePlayersListFrame()
    local playerName, _ = UnitName("player")

    if IsInGroup() then
        cla_msg("DISCOVER")
    else
        table.insert(CLA_PLAYERS_WITH_ADDON, {
            player = playerName,
            version = CLA_VERSION
        })
    end

    cla_callback(1, function()
        local cols = {
            { ["name"] = "Name", ["width"] = 100 },
            { ["name"] = "Version", ["width"] = 75 },
        }
    
        local players = CLA_GetPlayersInGroup()
        local data = {}

        for i, val in pairs(players) do
            local playerData = cla_table_find_player(CLA_PLAYERS_WITH_ADDON, val)
            local color = cla_get_cell_color_for_player(val)

            local playerCell = { value = nil, color = color }
            local versionCell = { value = nil }

            if playerData ~= nil then
                if type(playerData) == "string" then
                    playerCell.value = playerData
                    versionCell.value = "1.00"
                else
                    playerCell.value = playerData.player
                    versionCell.value = playerData.version
                end
            else
                playerCell.value = val
                versionCell.value = "MISSING"
            end

            table.insert(data, { cols = { playerCell, versionCell } })
        end

        cla_create_player_frame(cols, data)
        CLA_PLAYERS_WITH_ADDON = {}
    end)
end

function CLA_CreateOnyCloakListFrame()
    local playerName, _ = UnitName("player")
    local itemCount = GetItemCount(itemId, false)

    if IsInGroup() then
        cla_msg("ONYCLOAK")
    else
        if IsEquippedItem(15138) then
            table.insert(CLA_ONY_CLOAK_TRACKING_TABLE, {
                player = playerName,
                result = "YES"
            })
        else
            table.insert(CLA_ONY_CLOAK_TRACKING_TABLE, {
                player = playerName,
                result = "NO"
            })
        end
    end

    cla_callback(1, function()
        local cols = {
            { ["name"] = "Player", ["width"] = 120, ["align"] = "CENTER" },
            { ["name"] = "Result", ["width"] = 80, ["align"] = "CENTER" }
        }
    
        local players = CLA_GetPlayersInGroup()
        local data = {}

        for i, val in pairs(players) do
            local playerData = cla_table_find_player(CLA_ONY_CLOAK_TRACKING_TABLE, val)
            local color = cla_get_cell_color_for_player(val)

            if playerData == nil then
                playerData = {
                    player = val,
                    result = "?"
                }
            end

            local valueColor = cla_get_cell_color_for_value(playerData.result)

            table.insert(data, {
                cols = {
                    { value = val, color = color },
                    { value = playerData.result, color = valueColor }
                }
            })
        end

        cla_create_item_frame("Onyxia Scale Cloak equipped", cols, data)
    
        CLA_ONY_CLOAK_TRACKING_TABLE = {}
    end)
end

function CLA_CreateItemListFrame(itemId)
    local playerName, _ = UnitName("player")
    local itemCount = GetItemCount(itemId, false)

    if IsInGroup() then
        cla_msg("DISCOVER_ITEM:" .. itemId)
    else
        if itemCount > 0 then
            table.insert(CLA_ITEM_TRACKING_TABLE, {
                player = playerName,
                quantity = itemCount
            })
        end
    end

    cla_callback(1, function()
        local cols = {
            { ["name"] = "Player", ["width"] = 120, ["align"] = "CENTER" },
            { ["name"] = "Quantity", ["width"] = 80, ["align"] = "CENTER" }
        }
    
        local players = CLA_GetPlayersInGroup()
        local data = {}

        for i, val in pairs(players) do
            local playerData = cla_table_find_player(CLA_ITEM_TRACKING_TABLE, val)
            local color = cla_get_cell_color_for_player(val)

            if playerData == nil then
                playerData = {
                    player = val,
                    quantity = "?"
                }
            end

            table.insert(data, {
                cols = {
                    { value = val, color = color },
                    { value = playerData.quantity }
                }
            })
        end

        local item = Item:CreateFromItemID(itemId);

        item:ContinueOnItemLoad(function ()
            local itemName, itemLink = GetItemInfo(itemId)

            cla_create_item_frame(itemName, cols, data)
    
            CLA_ITEM_TRACKING_TABLE = {}
        end)
    end)
end

function CLA_GetPlayersInGroup()
    local plist = {}

    if IsInRaid() then
        for i=1,40 do
            local pName, _ = UnitName('raid' .. i)

            if pName then
                tinsert(plist, pName)
            end
        end
    elseif IsInGroup() then
        for i=1,4 do
            local pName, _ = UnitName('party' .. i)

            if pName then
                tinsert(plist, pName)
            end
        end
    end

    if IsInGroup() == false or IsInRaid() == false then
        local pName, _ = UnitName('player')
        tinsert(plist, pName)
    end

    return plist
end

function cla_register_loot_event(text, sender)
    cla_callback(1, function()
        local tableSplitResult = cla_mysplit(text, ':')
        local creatureName = tableSplitResult[1]
        local creatureGuid = tableSplitResult[2]
        local _, mlPlayerId = GetLootMethod();
        local playerIsMasterLooter = mlPlayerId == 0
        local _, _, _, _, _, npcId = strsplit("-", creatureGuid)

        if CLA_LOOTLIST[text] > 1 then
            CLA_LOOTLIST_MAP[creatureGuid] = {
                player = "multiple players",
                loot = {}
            }

            if ClassicLootAssistantConfig.showLoot then
                cla_print_color("The " .. creatureName .. " that just died has loot on it!", CLA_MESSAGE_COLOR)
            end

        elseif CLA_LOOTLIST[text] == 1 then

            CLA_LOOTLIST_MAP[creatureGuid] = {
                player = sender,
                loot = {}
            }

            if cla_has_value(CLA_SKINNING_TARGET_IDS, tonumber(npcId)) then
                cla_print_color(sender .. " can loot the " .. creatureName, CLA_MESSAGE_COLOR)

                if playerIsMasterLooter then
                    local msg = "[Classic Loot Assistant]: You can loot the " .. creatureName .. " that just died"
                    SendChatMessage(msg, "WHISPER", nil, sender)
                end
            end
        end
    end)
end

function cla_report_loot()
    local guid = UnitGUID("target")

    if guid and UnitIsDead("target") then
        -- Add if missing
        if CLA_LOOTLIST_MAP[guid] == nil then
            CLA_LOOTLIST_MAP[guid] = {
                player = "?",
                loot = {}
            }
        end

        for i = 1, GetNumLootItems() do

            if LootSlotHasItem(i) then
                local itemLink = GetLootSlotLink(i)

                if itemLink then
                    local _, _, _, _, rarity = GetLootSlotInfo(i);
    
                    if rarity < GetLootThreshold() then
                        -- Do nothing
                    else
                        local itemLinkSplit = cla_mysplit(itemLink, ':')
                        local itemId = itemLinkSplit[2]
        
                        if IsInGroup() then
                            local msg = "LOOT_DETECTED" .. "@" .. guid .. "@" .. itemLink;
                            cla_msg(msg)
                        else
                            if cla_has_value(CLA_LOOTLIST_MAP[guid].loot, itemLink) == false then
                                table.insert(CLA_LOOTLIST_MAP[guid].loot, itemLink)
                            end
                        end
                    end

                end
            end
        end
    end
end

function cla_render_corpse_tooltip(destGuid)
    if ClassicLootAssistantConfig.showTooltip == false then
        return
    end

    if UnitIsDead("mouseover") then
        local unitGuid = UnitGUID("mouseover");

        if CLA_LOOTLIST_MAP[unitGuid] ~= nil then
            GameTooltip:AddLine("Lootable by " .. CLA_LOOTLIST_MAP[unitGuid].player)

            if next(CLA_LOOTLIST_MAP[unitGuid].loot) ~= nil then
                local hasLoot, _ = CanLootUnit(unitGuid);

                if hasLoot then
                    table.foreach(CLA_LOOTLIST_MAP[unitGuid].loot, function (k, v)
                        GameTooltip:AddLine(v)
                    end)
                else
                    CLA_LOOTLIST_MAP[unitGuid].loot = {}
                end
            end
            GameTooltip:Show()
        end
    end
end

function cla_msg(msg)
    C_ChatInfo.SendAddonMessage("CLA", msg, cla_get_channel())
end

function cla_msg_whisper(player, msg)
    C_ChatInfo.SendAddonMessage("CLA", msg, "WHISPER", player)
end

function cla_get_cell_color_for_player(player)
    local _, playerClass = UnitClass(player)
    local r, g, b, _ = GetClassColor(playerClass)

    return {
        r = r,
        g = g,
        b = b,
        a = 1
    }
end

function cla_get_cell_color_for_value(value)
    if value == "?" then
        return {
            r = 1,
            g = 1,
            b = 0,
            a = 1
        }
    elseif value == "YES" then
        return {
            r = 0,
            g = 1,
            b = 0,
            a = 1
        }
    elseif value == "NO" then
        return {
            r = 1,
            g = 0,
            b = 0,
            a = 1
        }
    end
end