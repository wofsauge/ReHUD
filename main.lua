if ReHUD then return end

ReHUD = RegisterMod("ReHUD", 1)
local json = require("json")
local fontTimer = Font()
fontTimer:Load("font/pftempestasevencondensed.fnt") -- default pftempestasevencondensed
local fontFloorName = Font()
fontFloorName:Load("font/terminus8.fnt") -- default terminus8
reHUDConfig={
    ["disable"]=false,
    ["spriteScale"]=0.5,
    ["textScale"]=0.5,
    ["columns"]=4,
    ["position"]=1,
    ["transparency"]=0.50,
    ["showPassive"]=true,
    ["showFamiliar"]=true,
    ["showActive"]=false,
    ["showTimer"]=true,
    ["showGulpedTrinkets"]=true,
    ["showHeldTrinkets"]=false,
    ["showItems"]=true,
    ["showFloor"]=true
}

ReHUD.SavedData = {
    ["collected"] = {},
}

require("modMenu") -- Add Mod Menu entry
local spriteTable = {}
local game = Game()
local Config = Isaac.GetItemConfig()

--------------------------------
-------Helper Functions---------
--------------------------------
--Special thanks to _Kilburn for this function
local function GetScreenSize()
    local room = Game():GetRoom()
    local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - Game().ScreenShakeOffset

    local rx = pos.X + 60 * 26 / 40
    local ry = pos.Y + 140 * (26 / 40)

    return Vector(rx*2 + 13*26, ry*2 + 7*26)
end
local function GetScreenCenter()
    return GetScreenSize()/2
end
local function leadingZero(val)
    if val<10 and val>=0 then
        return "0"..val
    end
    return val
end
local function hasValue(tab, val, isItem, count, player)
    for index, value in ipairs(tab) do
        if (isItem == (value["Type"] ~= ItemType.ITEM_TRINKET)) and (value["Id"] == val) then
            if (not isItem and player == value["Player"]) then return true end
            if (count == value["Count"] and player == value["Player"]) then
                return true
            end
        end
    end
    return false
end
local function GetMaxCollectibleID()
    local id = CollectibleType.NUM_COLLECTIBLES-1
    local step = 16
    while step > 0 do
        if Isaac.GetItemConfig():GetCollectible(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end
local function GetMaxTrinketID()
    local id = TrinketType.NUM_TRINKETS -1
    -- local step = 16
    -- while step > 0 do
    -- if Isaac.GetItemConfig():GetTrinket(id+step) ~= nil then
    -- id = id + step
    -- else
    -- step = step // 2
    -- end
    -- end

    return id
end

local sclSprWidth=32*(reHUDConfig["spriteScale"])
local mapPadding=80
local cardPaddingLeft=120
local cardPaddingTop=30
local trinketPadding=70

local function calcMaxDisplay()
    local bottomRight= GetScreenSize()
    local fillablePlace=0
    if reHUDConfig["position"]==1 then
        fillablePlace= bottomRight.Y-mapPadding-cardPaddingTop
    else
        fillablePlace= bottomRight.X-trinketPadding-cardPaddingLeft
    end
    return math.floor(fillablePlace/(sclSprWidth)*reHUDConfig["columns"])
end

local function tableRemove(t, item)
    for index, value in ipairs(t) do
        if (value["Type"] == item["Type"]) and (value["Id"] == item["Id"]) then
            table.remove(t, index)
        end
    end
end

local function isGulpedTrinket(trinket, playerId)
    if not REPENTANCE then return false end
    local player = Isaac.GetPlayer(playerId)
    if player == nil then return false end

    local isGulped = true

    for i = 0, player:GetMaxTrinkets(), 1 do
        if player:GetTrinket(i) == trinket then
            isGulped = false
        end
    end

    return isGulped
end

local function getItemConfig(item)
    if (item["Type"] == ItemType.ITEM_PASSIVE and reHUDConfig["showPassive"]) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_FAMILIAR and reHUDConfig["showFamiliar"]) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_ACTIVE and reHUDConfig["showActive"]) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_TRINKET) then
        local isGulped = isGulpedTrinket(item["Id"], item["Player"])
        if (isGulped and reHUDConfig["showGulpedTrinkets"]) then return Config:GetTrinket(item["Id"]) end
        if (not isGulped and reHUDConfig["showHeldTrinkets"]) then return Config:GetTrinket(item["Id"]) end
    end

    return nil
end

local function getItemConfigSprite(item)
    if (item["Type"] == ItemType.ITEM_PASSIVE) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_FAMILIAR) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_ACTIVE) then
        return Config:GetCollectible(item["Id"])
    elseif (item["Type"] == ItemType.ITEM_TRINKET) then
        return Config:GetTrinket(item["Id"])
    end

    return nil
end


local function getSprite(item)
    local itemConfig = getItemConfigSprite(item)
    if itemConfig ~= nil then
        local itemSprite = Sprite()
        itemSprite:Load("gfx/005.100_collectible.anm2", false)
        itemSprite:Play("ShopIdle")
        itemSprite:ReplaceSpritesheet(1, itemConfig.GfxFileName)
        itemSprite:LoadGraphics()
        itemSprite:Update()

        return itemSprite
    end
end

--------------------------------
---------API Functions----------
--------------------------------

function ReHUD:isActive()
    return not reHUDConfig["disable"]
end

--------------------------------
-----------Main Logic-----------
--------------------------------
local maxIDs = GetMaxCollectibleID()
local maxTrinketIDs = GetMaxTrinketID()

local function isInFloorTable(t, name)
    for index, value in ipairs(t) do
        if value == name then
            return true
        end
    end
    return false
end

local function onRender(t)
    if reHUDConfig["disable"] then return end
    local bottomLeft = Vector(0,GetScreenSize().Y)
    local topRight = Vector(GetScreenSize().X, 0)
    local paused = ""

    if reHUDConfig["showTimer"] then
        if game:IsPaused() then paused = "Paused!" end
        local time = game.TimeCounter
        local msecs = time%30
        local secs = math.floor(time/30)%60
        local mins = math.floor(time/30/60)%60
        local hours = math.floor(time/30/60/60)%24
        local timestring = leadingZero(hours)..":"..leadingZero(mins)..":"..leadingZero(secs).."."..leadingZero(math.floor(msecs * 3.33333))
        fontTimer:DrawStringScaled(paused.." "..timestring, GetScreenCenter().X-fontTimer:GetStringWidth(paused.." 00:00:00.00")/2, 5, 1, 1, KColor(1,1,1,reHUDConfig["transparency"],0,0,0), 0, false)
    end

    local playerWithItems = {}
    local numPlayerWithItems = 0
    for i, v in ipairs(ReHUD.SavedData["collected"]) do
        local found = false
        if playerWithItems[v["Player"]] then
            found = true
        end
        if (not found) then
            playerWithItems[v["Player"]] = 1
            numPlayerWithItems = numPlayerWithItems + 1
        end
    end

    local columns = math.floor(reHUDConfig["columns"] / numPlayerWithItems)

    if reHUDConfig["showItems"] and #spriteTable > 0 and numPlayerWithItems > 0 then
        local highestCounter = 1
        local padding = Vector(0, 0)
        local renderedFloors = {}

        for i = #spriteTable, 1, -1 do
            item = spriteTable[i]

            local itemConfig = getItemConfig(item)
            if itemConfig then
                local position = Vector(50, 50)
                if reHUDConfig["showFloor"] then
                    -- Render stage name
                    if not isInFloorTable(renderedFloors, item["Floor"]) then
                        for i = 0, numPlayerWithItems-1 do
                            if (playerWithItems[i] and playerWithItems[i] > highestCounter) then
                                highestCounter = playerWithItems[i]
                            end
                        end

                        if (highestCounter - 1) % columns ~= 0 and highestCounter ~= 1 then
                            highestCounter = highestCounter + columns - (highestCounter-1) % columns
                        end

                        for i = 0, numPlayerWithItems-1 do
                            playerWithItems[i] = highestCounter
                        end

                        local namePosition = topRight + Vector((sclSprWidth/2 - sclSprWidth * reHUDConfig["columns"]), mapPadding + sclSprWidth * math.floor((highestCounter-1)/columns)) + Vector(-sclSprWidth/2, (-sclSprWidth/2) - 2 + padding.Y)

                        if reHUDConfig["position"] == 2 then
                            namePosition = bottomLeft+Vector(trinketPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]),(sclSprWidth/2-sclSprWidth*reHUDConfig["columns"]))+Vector(2+padding.X,-sclSprWidth)
                            if counter == 1 then namePosition = namePosition - Vector(sclSprWidth / 2, 0) end
                        end

                        -- render stage name
                        fontFloorName:DrawStringScaled(item["Floor"], namePosition.X, namePosition.Y, reHUDConfig["textScale"], reHUDConfig["textScale"], KColor(1, 1, 1, reHUDConfig["transparency"], 0, 0, 0), 0, false)
                        table.insert(renderedFloors, item["Floor"])

                        if reHUDConfig["position"] == 1 then
                            padding = padding + Vector(0, sclSprWidth / 2)
                        elseif reHUDConfig["position"] == 2 and counter ~= 1 then
                            padding = padding + Vector(sclSprWidth / 2, 0)
                        end

                        -- Render separator for multiplayer
                        if numPlayerWithItems > 1 then
                            itemSprite = item["Sprite"]
                            if itemSprite then
                                itemSprite.Color = Color(1, 1, 1, reHUDConfig["transparency"], 0, 0, 0)
                                itemSprite.Scale = Vector(0.05, math.floor((highestCounter-1)/columns))
                                itemSprite:Render(Vector(topRight.X - (sclSprWidth * columns), namePosition.Y + reHUDConfig["textScale"]))
                            end
                        end
                    end

                    -- Render collectibles
                    if reHUDConfig["position"] == 1 then
                        -- furthest left
                        local xStart = (sclSprWidth / 2) - (sclSprWidth * (reHUDConfig["columns"] / (item["Player"] + 1)))

                        -- get offset based on columns available
                        local xColumnOffset = sclSprWidth * math.floor((playerWithItems[item["Player"]] - 1) % columns)

                        local posX = xStart + xColumnOffset
                        local posY = mapPadding + sclSprWidth * math.floor((playerWithItems[item["Player"]] - 1) / columns)
                        position = topRight + Vector(posX, posY)

                    elseif reHUDConfig["position"] == 2 then -- bottom of screen
                        position = bottomLeft+Vector(trinketPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]), (sclSprWidth/2-sclSprWidth*reHUDConfig["columns"])+sclSprWidth*((counter-1)%reHUDConfig["columns"]))
                    end

                    itemSprite = item["Sprite"]
                    if itemSprite then
                        itemSprite.Color = Color(1, 1, 1, reHUDConfig["transparency"], 0, 0, 0)
                        itemSprite.Scale = Vector(reHUDConfig["spriteScale"], reHUDConfig["spriteScale"])
                        itemSprite:Render(position + padding, Vector(0, 0), Vector(0, 0))
                    end

                    if highestCounter == calcMaxDisplay() then return end
                    playerWithItems[item["Player"]] = playerWithItems[item["Player"]] + 1
                end
            end
        end
    end
end
ReHUD:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)

local function getFloorName()
    local level = game:GetLevel()

    local stageName = level:GetName(level:GetStage(), level:GetStageType(), 0, 0, false)
    if StageAPI and StageAPI.Loaded then
        if StageAPI.InOverriddenStage() and StageAPI.GetCurrentStageDisplayName() ~= nil then
            stageName = StageAPI.GetCurrentStageDisplayName()
        end
    end
    return stageName
end

local function addCollectibleToList(collectibleType, id, count, player)
    local stageName = getFloorName()

    local entry = {
        ["Type"] = collectibleType,
        ["Id"] = id,
        ["Player"] = player,
        ["Floor"] = stageName,
        ["Count"] = count
    }

    table.insert(ReHUD.SavedData["collected"], entry)
    table.insert(spriteTable, {
        ["Type"] = collectibleType,
        ["Id"] = id,
        ["Player"] = player,
        ["Floor"] = stageName,
        ["Count"] = count,
        ["Sprite"] = getSprite(entry)
    })
end

local function updateCollectibleInList(index, oldItem, count, player)
    -- remove old data
    table.remove(ReHUD.SavedData["collected"], index)
    tableRemove(spriteTable, oldItem)

    -- readd with new floor name
    addCollectibleToList(oldItem["Type"], oldItem["Id"], count, player)
end

local function getItems(playerId)
    local player = Isaac.GetPlayer(playerId)
    if player == nil then return end
    local foundCount = 0

    -- Remove items no longer in possession
    for index, value in ipairs(ReHUD.SavedData["collected"]) do
        if (value["Type"] ~= ItemType.ITEM_TRINKET) and player:HasCollectible(value["Id"]) and player:GetCollectibleNum(value["Id"]) > 0 then
            foundCount = foundCount + 1
        else
            if (value["Type"] ~= ItemType.ITEM_TRINKET) and (value["Player"] == playerId) then
                table.remove(ReHUD.SavedData["collected"], index)
                tableRemove(spriteTable, value)
            end
        end
    end

    -- Add items if not already in list
    for i = 1, maxIDs do
        local collectible = Config:GetCollectible(i)
        if collectible ~= nil then
            if player:HasCollectible(i) and player:GetCollectibleNum(i) > 0 and not hasValue(ReHUD.SavedData["collected"], i, true, player:GetCollectibleNum(i), playerId) then
                addCollectibleToList(collectible.Type, i, player:GetCollectibleNum(i), playerId)
            end
        end
    end
end

local function getTrinkets(playerId)
    if not REPENTANCE then return end
    local player = Isaac.GetPlayer(playerId)
    if player == nil then return end

    -- Remove trinkets no longer in possession
    for index, value in ipairs(ReHUD.SavedData["collected"]) do
        if (value["Type"] == ItemType.ITEM_TRINKET) and (not player:HasTrinket(value["Id"]) and (value["Player"] == playerId)) then
            table.remove(ReHUD.SavedData["collected"], index)
            tableRemove(spriteTable, value)
        end
    end

    -- Add trinkets if not already in list
    for i = 1, maxTrinketIDs do
        if Config:GetTrinket(i) ~= nil then
            if player:HasTrinket(i, true) and not hasValue(ReHUD.SavedData["collected"], i, false, 1, 0) then
                addCollectibleToList(ItemType.ITEM_TRINKET, i, 1, 0)
            end
        end
    end

    -- Update floor value for held trinkets
    local currentFloor = getFloorName()
    for index, value in ipairs(ReHUD.SavedData["collected"]) do
        if (value["Type"] == ItemType.ITEM_TRINKET) and (value["Floor"] ~= currentFloor) and (not isGulpedTrinket(value, playerId)) then
            updateCollectibleInList(index, value, 1, 0)
        end
    end
end

--------------------------------
--------Handle Savadata---------
--------------------------------
local isGameStarted = false
function ReHUD:OnGameStart(isSave)
    --Loading Moddata--
    if ReHUD:HasData() then
        ReHUD.SavedData = json.decode(Isaac.LoadModData(ReHUD))
        reHUDConfig = ReHUD.SavedData["config"]
        sclSprWidth = 32*(reHUDConfig["spriteScale"])
        spriteTable = {}

        if (ReHUD.SavedData["collected"] == nil) then
            ReHUD.SavedData["collected"] = {}
        end

        -- Add item/trinket to sprite table
        for index, value in ipairs(ReHUD.SavedData["collected"]) do
            table.insert(spriteTable, {
                ["Type"] = value["Type"],
                ["Id"] = value["Id"],
                ["Player"] = value["Player"],
                ["Floor"] = value["Floor"],
                ["Sprite"] = getSprite(value)
            })
        end
    end

    if not isSave then
        -- Resetting Moddata
        ReHUD.SavedData["collected"] = {}
        spriteTable = {}

        -- Load current data
        for i = 0, game:GetNumPlayers()-1 do
            getItems(i)
            getTrinkets(i)
        end
    end

    isGameStarted = true
end
ReHUD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, ReHUD.OnGameStart)

--Saving Moddata--
function ReHUD:updateItems()
    if isGameStarted then
        for i = 0, game:GetNumPlayers()-1 do
            getItems(i)
            getTrinkets(i)
        end
    end
end
ReHUD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ReHUD.updateItems)

--Saving Moddata--
function ReHUD:SaveGame()
    ReHUD.SavedData["config"] = reHUDConfig
    ReHUD.SaveData(ReHUD, json.encode(ReHUD.SavedData))
end
ReHUD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ReHUD.SaveGame)