--------------------------------
--------Mod config menu---------
--------------------------------
if ModConfigMenu then
    function AnIndexOf(t,val)
        for k,v in ipairs(t) do
            if v == val then return k end
        end
        return 1
    end

    -- Show hud
    ModConfigMenu.AddSetting("ReHUD","General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["disable"]
        end,
        Display = function()
            local onOff = "True"
            if reHUDConfig["disable"] then
                onOff = "False"
            end
            return "Show HUD: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["disable"] = currentBool
        end,
    })

    --size
    local sizes= {0.25,0.3,0.4,0.5,0.6,0.75,0.8,0.9,1}
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return AnIndexOf(sizes,reHUDConfig["spriteScale"])
        end,
        Minimum = 1,
        Maximum = #sizes,
        Display = function()
            return "Size: " .. reHUDConfig["spriteScale"]
        end,
        OnChange = function(currentNum)
            reHUDConfig["spriteScale"] = sizes[currentNum]
            sclSprWidth=32*(reHUDConfig["spriteScale"])
        end,
    })

    -- Show timer
    ModConfigMenu.AddSetting("ReHUD","General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showTimer"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showTimer"] then
                onOff = "True"
            end
            return "Show game timer: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showTimer"] = currentBool
        end,
    })

    -- Show itemlist
    ModConfigMenu.AddSetting("ReHUD","General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showItems"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showItems"] then
                onOff = "True"
            end
            return "Show items: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showItems"] = currentBool
        end,
    })

    -- Show floor
    ModConfigMenu.AddSetting("ReHUD","General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showFloor"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showFloor"] then
                onOff = "True"
            end
            return "Show floorname: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showFloor"] = currentBool
        end,
    })

    --Text size
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return AnIndexOf(sizes,reHUDConfig["textScale"])
        end,
        Minimum = 1,
        Maximum = #sizes,
        Display = function()
            return "Text Size: " .. reHUDConfig["textScale"]
        end,
        OnChange = function(currentNum)
            reHUDConfig["textScale"] = sizes[currentNum]
        end,
    })

    --position
    local positions= {"default","bottom"}
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return reHUDConfig["position"]
        end,
        Minimum = 1,
        Maximum = 2,
        Display = function()
            return "Position: " .. positions[reHUDConfig["position"]]
        end,
        OnChange = function(currentNum)
            reHUDConfig["position"] = currentNum
            if reHUDConfig["position"]==1 then
                reHUDConfig["columns"]=4
            else
                reHUDConfig["columns"]=1
            end
        end,
    })

    --Columns
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return reHUDConfig["columns"]
        end,
        Minimum = 1,
        Maximum = 8,
        Display = function()
            if reHUDConfig["position"]==1 then
                return "Columns: " .. reHUDConfig["columns"]
            else
                return "Rows: " .. reHUDConfig["columns"]
            end
        end,
        OnChange = function(currentNum)
            reHUDConfig["columns"] = currentNum

        end,
    })

    --transparency
    local transparencies= {0.25,0.3,0.4,0.5,0.6,0.75,0.8,0.9,1}
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return AnIndexOf(transparencies,reHUDConfig["transparency"])
        end,
        Minimum = 1,
        Maximum = #transparencies,
        Display = function()
            return "Transparency: " .. reHUDConfig["transparency"]
        end,
        OnChange = function(currentNum)
            reHUDConfig["transparency"] = transparencies[currentNum]
        end,
    })

    ModConfigMenu.AddSpace("ReHUD", "General")

    -- Show Passive items
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showPassive"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showPassive"] then
                onOff = "True"
            end
            return "Show passive items: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showPassive"] = currentBool
        end,
    })

    -- Show familiar items
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showFamiliar"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showFamiliar"] then
                onOff = "True"
            end
            return "Show familiar items: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showFamiliar"] = currentBool
        end,
    })

    -- Show held trinkets
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showHeldTrinkets"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showHeldTrinkets"] then
                onOff = "True"
            end
            return "Show held trinkets: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showHeldTrinkets"] = currentBool
        end,
    })

    -- Show gulped trinkets
    ModConfigMenu.AddSetting("ReHUD", "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return reHUDConfig["showGulpedTrinkets"]
        end,
        Display = function()
            local onOff = "False"
            if reHUDConfig["showGulpedTrinkets"] then
                onOff = "True"
            end
            return "Show gulped trinkets: " .. onOff
        end,
        OnChange = function(currentBool)
            reHUDConfig["showGulpedTrinkets"] = currentBool
        end,
    })
end