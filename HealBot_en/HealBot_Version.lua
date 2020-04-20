function HealBot_Version_Target()
    if HEALBOT_GAME_VERSION<4 then
        return true
    else
        return false
    end
end