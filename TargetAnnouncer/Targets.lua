Targets_targets={};

SLASH_TARGETS1 = "/targets"
SlashCmdList["TARGETS"] = function(msg)
   Targets_show();
end 

function Targets_setTarget(marker)
  if UnitExists("target") then Targets_targets[marker]=UnitName("target") else Targets_targets[marker]="" end
  markerStr = strjoin(marker,'Assigning {','}');
  -- print(strjoin(' -> ', markerStr, Targets_targets[marker]));
  Targets_setTargetTexts();
end

function Targets_setTargetBtn(marker, button)
  if button == "RightButton" then
    Targets_clearTarget(marker);
  else
    Targets_setTarget(marker);
  end
end

function Targets_clear()
  Targets_targets["rt1"] = "";
  Targets_targets["rt2"] = "";
  Targets_targets["rt3"] = "";
  Targets_targets["rt4"] = "";
  Targets_targets["rt5"] = "";
  Targets_targets["rt6"] = "";
  Targets_targets["rt7"] = "";
  Targets_targets["rt8"] = "";
  Targets_setTargetTexts();
end

function Targets_clearTarget(marker)
  Targets_targets[marker] = "";
  Targets_setTargetTexts();
end

function Targets_setTargetTexts()
  for m,n in pairs(Targets_targets) do 
      value = Targets_targets[m];
      if value == "" then
         value = "..."
      end
      textObj = getglobal(strjoin(m,'Targets_names_','Text'));
      if textObj ~= nil then
         textObj:SetText(value)
      end
  end
end

function Targets_anounce()
  chan="PARTY";
  hasNoEntry = true;
  isRaid = IsInRaid();
  if isRaid then
    chan = "RAID"
  end
  for m,n in pairs(Targets_targets) do 
    if n ~= "" then
       hasNoEntry = false;
    end
  end
  if hasNoEntry then
    print("No targets to announce. Target a player and click on a symbol to assign the them.");
  else
    h="Target assignment:";
    SendChatMessage(h, chan);
    SendChatMessage("-----", chan);
    for m,n in pairs(Targets_targets) do 
      if n ~= "" then
         SendChatMessage(strjoin(' -> ', strjoin(m,'{','}'), n), chan);
      end
    end
  end
end

function Targets_show() 
  Targets_setTargetTexts();
  Targets_Frame:Show();
end

function Targets_hide() 
  Targets_Frame:Hide();
end

Targets_clear();