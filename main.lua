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
	["showItems"]=true,
	["showFloor"]=true
}

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
local function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
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
    local step = 16
    while step > 0 do
        if Isaac.GetItemConfig():GetTrinket(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end
    
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


--------------------------------
---------API Functions----------
--------------------------------

function ReHUD:isActive()
	return not reHUDConfig["disable"]
end

--------------------------------
-----------Main Logic-----------
--------------------------------




ReHUD.SavedData={["items"]={},["trinkets"]={},["floor"]={}}

local spriteTable={}

local game = Game()
local Config= Isaac.GetItemConfig()
local maxIDs= GetMaxCollectibleID()

local function onRender(t)
	if reHUDConfig["disable"] then return end
	local bottomLeft = Vector(0,GetScreenSize().Y)
	local topRight= Vector(GetScreenSize().X,0)
	local paused =""
	local player = Isaac.GetPlayer(0)
	if reHUDConfig["showTimer"] then 
		if game:IsPaused() then paused ="Paused!" end
		local time = game.TimeCounter
		local msecs= time%30
		local secs= math.floor(time/30)%60
		local mins= math.floor(time/30/60)%60
		local hours= math.floor(time/30/60/60)%24
		local timestring= leadingZero(hours)..":"..leadingZero(mins)..":"..leadingZero(secs).."."..leadingZero(math.floor(msecs * 3.33333))
		fontTimer:DrawStringScaled(paused.." "..timestring, GetScreenCenter().X-fontTimer:GetStringWidth(paused.." 00:00:00.00")/2,5,1,1,KColor(1,1,1,reHUDConfig["transparency"],0,0,0),0,false)
	end
		
	if reHUDConfig["showItems"] and #spriteTable>0  then 
		local counter = 1
		local lastFloor=""
		local padding=Vector(0,0)
		for i = #spriteTable, 1, -1 do
			value = spriteTable[i]
			local itemConfig=Config:GetCollectible(ReHUD.SavedData["items"][i])
			if itemConfig~=nil then
				if (itemConfig.Type==ItemType.ITEM_PASSIVE and reHUDConfig["showPassive"]) or (itemConfig.Type==ItemType.ITEM_FAMILIAR  and reHUDConfig["showFamiliar"])or (itemConfig.Type==ItemType.ITEM_ACTIVE and reHUDConfig["showActive"]) then
					local position = Vector(50,50)
					if reHUDConfig["showFloor"] then 
						if lastFloor~= ReHUD.SavedData["floor"][i] then
							if (counter-1)%reHUDConfig["columns"]~=0 and counter~=1 then
								counter = counter + reHUDConfig["columns"]-(counter-1)%reHUDConfig["columns"]
							end
							
							local namePosition= topRight+Vector((sclSprWidth/2-sclSprWidth*reHUDConfig["columns"]),mapPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]))+Vector(-sclSprWidth/2,-sclSprWidth/2-2+padding.Y)
							
							if reHUDConfig["position"]==2 then
								namePosition= bottomLeft+Vector(trinketPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]),(sclSprWidth/2-sclSprWidth*reHUDConfig["columns"]))+Vector(2+padding.X,-sclSprWidth)
								if counter==1 then namePosition= namePosition-Vector(sclSprWidth/2,0) end
							end
							-- render Floorname
							fontFloorName:DrawStringScaled(ReHUD.SavedData["floor"][i], namePosition.X,namePosition.Y,reHUDConfig["textScale"],reHUDConfig["textScale"],KColor(1,1,1,reHUDConfig["transparency"],0,0,0),0,false)
							lastFloor=ReHUD.SavedData["floor"][i]
							addedFloorName = true 
							if reHUDConfig["position"]==1 then
								padding=padding+Vector(0,sclSprWidth/2)
							elseif reHUDConfig["position"]==2 and counter~=1 then
								padding=padding+Vector(sclSprWidth/2,0)
							end
						end
					end
					if reHUDConfig["position"]==1 then-- under minimap
												-- center of sprite moved coloumn count to left      moved current slot right                         minimap height + spritescale* number of rows
						position= topRight+Vector((sclSprWidth/2-sclSprWidth*reHUDConfig["columns"])+sclSprWidth*((counter-1)%reHUDConfig["columns"]),mapPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]))
					elseif reHUDConfig["position"]==2 then -- bottom of screen
						position= bottomLeft+Vector(trinketPadding+sclSprWidth*math.floor((counter-1)/reHUDConfig["columns"]),(sclSprWidth/2-sclSprWidth*reHUDConfig["columns"])+sclSprWidth*((counter-1)%reHUDConfig["columns"]))
					end
					
					value.Color=Color(1,1,1,reHUDConfig["transparency"],0,0,0)
					value.Scale = Vector(reHUDConfig["spriteScale"],reHUDConfig["spriteScale"])
					value:Render(position+padding, Vector(0,0), Vector(0,0))
					
					if counter== calcMaxDisplay() then return end
					counter=counter+1
				end
			end
		end
	end
end

ReHUD:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)

local function getItems()
	local player = Isaac.GetPlayer(0)
	local foundCount=0
	for index, value in ipairs(ReHUD.SavedData["items"]) do
		if player:HasCollectible(value) and player:GetCollectibleNum(value)>0 then
			foundCount=foundCount+1
		else
			table.remove(ReHUD.SavedData["items"], index)
			table.remove(ReHUD.SavedData["floor"], index)
			table.remove(spriteTable,index)
		end
	end
	if foundCount==player:GetCollectibleCount() then 
		return
	end
	local level = game:GetLevel()
	for i=1,maxIDs do

		if Config:GetCollectible(i) ~= nil then
			if player:HasCollectible(i) and player:GetCollectibleNum(i)>0 and not hasValue(ReHUD.SavedData["items"], i) then
				table.insert(ReHUD.SavedData["items"], i)
				local stageName= level:GetName(level:GetStage(),level:GetStageType(),0, 0,false)
				if StageAPI and StageAPI.Loaded then
					if StageAPI.InOverriddenStage() and StageAPI.GetCurrentStageDisplayName()~=nil then
						stageName = StageAPI.GetCurrentStageDisplayName()
					end
				end
				table.insert(ReHUD.SavedData["floor"],stageName )
				
				local itemSprite = Sprite()
				itemSprite:Load("gfx/005.100_collectible.anm2", false)
				itemSprite:Play("ShopIdle")
				itemConfig= Config:GetCollectible(i)
				itemSprite:ReplaceSpritesheet(1,itemConfig.GfxFileName)
				itemSprite:LoadGraphics()
				itemSprite:Update()
				table.insert(spriteTable, itemSprite)
				foundCount=foundCount+1
			end
			if foundCount==player:GetCollectibleCount() then 
				break
			end
		end
	end
end


--------------------------------
--------Handle Savadata---------
--------------------------------
local isGameStarted= false
function ReHUD:OnGameStart(isSave)
	--Loading Moddata--
	if ReHUD:HasData() then
		ReHUD.SavedData = json.decode(Isaac.LoadModData(ReHUD))
		reHUDConfig = ReHUD.SavedData["config"]
		sclSprWidth=32*(reHUDConfig["spriteScale"])
		spriteTable={}			
		for index, value in ipairs(ReHUD.SavedData["items"]) do
			local itemConfig= Config:GetCollectible(value)
			if itemConfig ~= nil then
				local itemSprite = Sprite()
				itemSprite:Load("gfx/005.100_collectible.anm2", false)
				itemSprite:Play("ShopIdle")
				itemSprite:ReplaceSpritesheet(1,itemConfig.GfxFileName)
				itemSprite:LoadGraphics()
				itemSprite:Update()
				table.insert(spriteTable, itemSprite)
			end
		end
	end
	if not isSave then
		--Resetting Moddata--
		ReHUD.SavedData["items"] = {}
		ReHUD.SavedData["floor"] = {}
		ReHUD.SavedData["trinkets"] = {}
		spriteTable={}
		getItems()
	end
	isGameStarted=true
end
ReHUD:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, ReHUD.OnGameStart)

--Saving Moddata--
function ReHUD:updateItems()
	if isGameStarted then
	getItems()
	end
end
ReHUD:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ReHUD.updateItems)
--Saving Moddata--
function ReHUD:SaveGame()
	ReHUD.SavedData["config"]= reHUDConfig
    ReHUD.SaveData(ReHUD, json.encode(ReHUD.SavedData))
end
ReHUD:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ReHUD.SaveGame)



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
	ModConfigMenu.AddSetting("ReHUD","General", {
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
	ModConfigMenu.AddSetting("ReHUD","General", {
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
	-- Show active items
	
end

