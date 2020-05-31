function cla_create_player_frame(cols, rows)
    -- If the item frame is open when the player frame is opened, hide the item frame.
    if CLA_ITEM_FRAME ~= nil then
        CLA_ITEM_FRAME.frame:Hide()
    end

    if CLA_PLAYER_FRAME == nil then
        CLA_PLAYER_FRAME = cla_create_frame_with_table("Classic Loot Assistant", cols, rows)
    else
        CLA_PLAYER_FRAME.table:SetData(rows)
        CLA_PLAYER_FRAME.frame:Show()
    end
end

function cla_create_item_frame(name, cols, rows)
    -- If the player frame is open when the item frame is opened, hide the player frame.
    if CLA_PLAYER_FRAME ~= nil then
        CLA_PLAYER_FRAME.frame:Hide()
    end

    if CLA_ITEM_FRAME == nil then
        CLA_ITEM_FRAME = cla_create_frame_with_table(name, cols, rows)
    else
        CLA_ITEM_FRAME.frame.text:SetText(name)
        CLA_ITEM_FRAME.table:SetData(rows)
        CLA_ITEM_FRAME.frame:Show()
    end
end

function cla_create_frame_with_table(name, cols, rows)
    local frame = cla_create_frame(name)
    local ScrollingTable = LibStub("ScrollingTable");
    local scrollTable = ScrollingTable:CreateST(cols, 16, 20, nil, frame);

    scrollTable:SetData(rows);
    scrollTable.frame:SetPoint("CENTER");

    return {
        frame = frame,
        table = scrollTable
    }
end

function CLA_MakeCheckbox(label, parent, dbKey)
    local tooltipOnEnter = function(self, event)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, false);
        GameTooltip:Show();
    end

    local tooltipOnLeave = function(self, event)
        GameTooltip:Hide();
    end

    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(25)
    cb:SetHeight(25)
    cb:Show()

    local cblabel = cb:CreateFontString(nil, "OVERLAY")

    cblabel:SetFontObject("GameFontHighlight")
    cblabel:SetPoint("LEFT", cb,"RIGHT", 5,0)

    cb.label = cblabel
    cb.label:SetText(label)

    cb:SetScript("OnEnter", tooltipOnEnter)
    cb:SetScript("OnLeave", tooltipOnLeave)

    cb:SetScript("OnClick",function(self, button)
        f.Commands.hooktarget()
    end)

    cb:SetScript("OnClick",function(self,button)
        ClassicLootAssistantConfig[dbKey] = not ClassicLootAssistantConfig[dbKey]
    end)
    
    return cb
end

function cla_create_frame(name)
    local frame = CreateFrame("FRAME")
    frame.name = name

    frame:SetSize(250, 420)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
        tile=true,
        tileSize=5,
        edgeSize= 2,
    })
    frame:SetBackdropColor(0,0,0,1)
    frame:SetBackdropBorderColor(0,0,0,1)
    frame:SetMovable(true)
    frame:EnableMouse(true)

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
         self:StartMoving();
         self.isMoving = true;
        end
      end)

    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing();
            self.isMoving = false;
        end
    end)

    frame:SetScript("OnHide", function(self)
        if (self.isMoving ) then
            self:StopMovingOrSizing();
            self.isMoving = false;
        end
    end)

    frame.text = frame:CreateFontString(nil, "ARTWORK")
    frame.text:SetFont("Fonts\\ARIALN.ttf", 14, "OUTLINE")
    frame.text:SetPoint("TOP", 0, -5)
    frame.text:SetText(name)

    local b = CreateFrame("Button", "MyButton", frame, "UIPanelButtonTemplate")
    b:SetSize(120, 30)
    b:SetText("Close")
    b:SetPoint("BOTTOM", 0, 5)
    b:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

function CLA_GetOptionsDefault()
    local options = CLA_CONFIG_DEFAULT;
    local config = ClassicLootAssistantConfig;

    if config ~= nil then
        table.foreach(options, function (key, setting)
            local val = config[key]
    
            if val ~= nil then
                options[key] = val
            end
        end)
    end

    ClassicLootAssistantConfig = options

    return options
end

function CLA_CreateOptionsFrame()
    local config = CLA_GetOptionsDefault()

    local frame = CreateFrame("FRAME")
    frame.name = "Classic Loot Assistant"

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	label:SetPoint("TOPLEFT", 10, -15)
	label:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
	label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText("Classic Loot Assistant")

    local content = CreateFrame("Frame", "CADOptionsContent", frame)
	content:SetPoint("TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

    local showLoot = CLA_MakeCheckbox("Always show loot messages", content, 'showLoot')
    showLoot:SetPoint("TOPLEFT", 10, -60)
    content.hookTargetFrame = showLoot
    showLoot.tooltipText = "Usually only shown for the Master Looter"
    showLoot:SetChecked(config.showLoot)

    local showTooltip = CLA_MakeCheckbox("Show loot tooltip", content, 'showTooltip')
    showTooltip:SetPoint("TOPLEFT", 10, -100)
    content.hookTargetFrame = showTooltip
    showTooltip.tooltipText = "Show loot status in tooltip on corpse mouseover"
    showTooltip:SetChecked(config.showTooltip)

    local limitInspection = CLA_MakeCheckbox("Only allow assistants in a raid group to inspect you", content, 'limitInspection');
    limitInspection:SetPoint("TOPLEFT", 10, -140)
    content.hookTargetFrame = limitInspection
    limitInspection.tooltipText = "When unchecked, everyone in your group can inspect you for items"
    limitInspection:SetChecked(config.limitInspection)

    InterfaceOptions_AddCategory(frame)
    CLA_CONFIG_FRAME = frame
end