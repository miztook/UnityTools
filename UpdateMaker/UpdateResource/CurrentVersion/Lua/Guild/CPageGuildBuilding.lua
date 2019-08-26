local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local GuildEvent = require "Events.GuildEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local EGuildRedPointType = require "PB.net".EGuildRedPointType

local CPageGuildBuilding = Lplus.Class("CPageGuildBuilding")
local def = CPageGuildBuilding.define


def.field("table")._Parent = nil
def.field("userdata")._FrameRoot = nil
def.field("table")._UIObjects = nil
def.field("function")._GuildEventCB = nil

-- Lua配置表
def.field("table")._Building_Config = nil

local BUILDING_COUNT = 5   -- 建筑列表数目

def.static("table", "userdata", "=>", CPageGuildBuilding).new = function(parent, root)
	local obj = CPageGuildBuilding()
	obj._Parent = parent
	obj._FrameRoot = root
	return obj
end

-- 展示时调用
def.method().Show = function(self)
    game._GuildMan:SendC2SGuildBuildingInfo()
	self:InitUIObject()
	self._FrameRoot:SetActive(true)
	self:InitConfigData()
	self:UpdateHallInfo()
	self:UpdateBuildingList()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
	if self._UIObjects ~= nil then
		return
	end
	local parent = self._Parent

	local scrollBar = ClassType.Scrollbar
    self._UIObjects = {}
    self._UIObjects.Hall_Next = parent:GetUIObject("Hall_Next")
    self._UIObjects.Hall_BG = parent:GetUIObject("Hall_Bg0")
    self._UIObjects.Hall_Level = parent:GetUIObject("Hall_Level")
    self._UIObjects.Hall_Bar_Exp = parent:GetUIObject("Hall_Bar_Exp"):GetComponent(scrollBar)
	self._UIObjects.Hall_Exp_Num = parent:GetUIObject("Hall_Exp_Num")
	self._UIObjects.Hall_Bar_Member = parent:GetUIObject("Hall_Bar_Member"):GetComponent(scrollBar)
	self._UIObjects.Hall_Member_Num = parent:GetUIObject("Hall_Member_Num")
	self._UIObjects.Hall_Bar_Fund = parent:GetUIObject("Hall_Bar_Fund"):GetComponent(scrollBar)
	self._UIObjects.Hall_Fund_Num = parent:GetUIObject("Hall_Fund_Num")
	self._UIObjects.Img_BtnFloatFx = parent:GetUIObject("Img_BtnFloatFx1")
    self._UIObjects.Building_List = parent:GetUIObject("Guild_Building_List"):GetComponent(ClassType.GNewList)
    self._UIObjects.Btn_Hall_Level = parent:GetUIObject("Btn_Hall_Level")
    local OnGuildEvent = function(sender, event)
        if event ~= nil then
            if event._Type == "GuildLevelUp" then
                GameUtil.StopUISfx(PATH.UIFX_GuildLevel, self._UIObjects.Hall_BG)
                GameUtil.PlayUISfx(PATH.UIFX_GuildLevel, self._UIObjects.Hall_BG, self._UIObjects.Hall_BG, 2)
            elseif event._Type == "GuildBuildingLevelUp" then
                self:PlayBuildingLevelUpFX(event._Param)
            end
        end
    end
    --print("赋值 特效回调 ")
    self._GuildEventCB = OnGuildEvent
    CGame.EventManager:addHandler(GuildEvent, self._GuildEventCB)
end

-- 初始化信息
def.method().InitConfigData = function(self)
	local ret, msg, result = pcall(dofile, "Configs/GuildBuilding.lua")
	local guild = game._HostPlayer._Guild
	self._Building_Config = {}
	for i, v in ipairs(result) do
		if i == 1 then
			self._Building_Config[1] = {}
			self._Building_Config[1]._IconPath = v.IconPath
			self._Building_Config[1]._Name = StringTable.Get(838)
			local level = guild._GuildLevel
			self._Building_Config[1]._Level = level
			local guildLevel = CElementData.GetTemplate("GuildLevel", level)
            if guildLevel ~= nil then
            	self._Building_Config[1]._Des = guildLevel.Description
				self._Building_Config[1]._Tid = level
				self._Building_Config[1]._IsMaxLevel = game._HostPlayer._Guild._IsMaxLevel
				self._Building_Config[1]._BuildingType = -1
				if self._Building_Config[1]._IsMaxLevel then
					self._Building_Config[1]._LevelUp = false
				else
					if guild._Exp >= guildLevel.NextExperience and guild._Fund >= guildLevel.Fund then
						self._Building_Config[1]._LevelUp = true
					else
						self._Building_Config[1]._LevelUp = false
					end
				end
				self._Building_Config[1]._Lock = false
				self._Building_Config[1]._GuildLevel = level
				self._Building_Config[1]._IsRed = false
            else
                warn("error !!! 公会等级不对，现在是： ", level)
            end
		else
			local buildingList = game._HostPlayer._Guild._BuildingList
			for j, w in pairs(buildingList) do
				if i == (j + 1) then
					local index = #self._Building_Config + 1
					self._Building_Config[index] = {}
					self._Building_Config[index]._IconPath = v.IconPath
					self._Building_Config[index]._Name = w._BuildingName
					self._Building_Config[index]._Level = w._BuildingLevel
					local moduleID = w._BuildingModuleID
					local nowBuild = CElementData.GetTemplate("GuildBuildLevel", moduleID)
					local describID = nowBuild.DescribID	
					self._Building_Config[index]._Des = nowBuild.Description
					self._Building_Config[index]._Tid = moduleID
					self._Building_Config[index]._IsMaxLevel = w._IsMaxLevel
					self._Building_Config[index]._BuildingType = w._BuildingType
					self._Building_Config[index]._Lock = w._Lock
					self._Building_Config[index]._GuildLevel = w._GuildLevel
					self._Building_Config[index]._Unlock = w._Unlock
					self._Building_Config[index]._PlayerLevel = w._PlayerLevel
					self._Building_Config[index]._LevelUp = false
					if self._Building_Config[index]._IsMaxLevel then
						self._Building_Config[index]._LevelUp = false
					else
						-- 公会涉及到自动解锁
						-- 所需等级需要判断下一个ID;花销判断当前ID
						if guild._Fund >= nowBuild.CostFund then
							local allBuild = CElementData.GetAllGuildBuildLevel()
							for i = 1, #allBuild do
								local buildLevel = CElementData.GetTemplate("GuildBuildLevel", allBuild[i])
								local data = self._Building_Config[index]
								if buildLevel.BuildType == data._BuildingType then
									if buildLevel.BuildLevel == data._Level + 1 then
										if guild._GuildLevel >= buildLevel.GuildLevel then
											self._Building_Config[index]._LevelUp = true
										end
									end
								end
							end
						else
							self._Building_Config[index]._LevelUp = false
						end
					end
					self._Building_Config[index]._IsRed = false
					if w._BuildingType == 1 then
						if game._GuildMan:IsSmithyHasRedPoint() and self._Building_Config[index]._Unlock then
							self._Building_Config[index]._IsRed = true
						end
					end
					local points = game._HostPlayer._Guild._RedPoint
					for m, n in ipairs(points) do
						if n == EGuildRedPointType.EGuildRedPointType_Pray and w._BuildingType == 2 and self._Building_Config[index]._Unlock then
							self._Building_Config[index]._IsRed = true
						end
					end
				end
			end
		end
	end

    local sort = function(item1, item2)
        if item1._PlayerLevel == nil or item2._PlayerLevel == nil then
            return false
        end
        return item1._PlayerLevel < item2._PlayerLevel
    end
    table.sort(self._Building_Config, sort)
end

def.method().UpdateBuildingList = function(self)
    self:InitConfigData()
	self._UIObjects.Building_List:SetItemCount(BUILDING_COUNT)
end

def.method().UpdateHallInfo = function(self)
	local data = self._Building_Config[1]
	local guild = game._HostPlayer._Guild
	local guildLevel = CElementData.GetTemplate("GuildLevel", data._Level)
    if guildLevel == nil then
        warn("error !!! guildLevel is Nil ", data._Level, debug.traceback())
        return
    end
	if data._IsMaxLevel then
		GUITools.SetBtnExpressGray(self._UIObjects.Btn_Hall_Level,true)
		local imgBtnBg = self._UIObjects.Btn_Hall_Level:FindChild("Img_Bg")
		GameUtil.MakeImageGray(imgBtnBg,true)
		self._UIObjects.Hall_Bar_Exp.size = 1		
		GUI.SetText(self._UIObjects.Hall_Exp_Num, "Max")
	else
		local imgBtnBg = self._UIObjects.Btn_Hall_Level:FindChild("Img_Bg")
		GameUtil.MakeImageGray(imgBtnBg,false)
		GUITools.SetBtnExpressGray(self._UIObjects.Btn_Hall_Level,false)
		self._UIObjects.Hall_Bar_Exp.size = guild._Exp / guildLevel.NextExperience		
		GUI.SetText(self._UIObjects.Hall_Exp_Num, guild._Exp .. "/" .. guildLevel.NextExperience)
	end
	self._UIObjects.Hall_Bar_Member.size = guild._MemberNum / guildLevel.MemberNumber
	GUI.SetText(self._UIObjects.Hall_Member_Num, guild._MemberNum .. "/" .. guildLevel.MemberNumber)
	self._UIObjects.Hall_Bar_Fund.size = guild._Fund / guildLevel.MaxGuildFund
	GUI.SetText(self._UIObjects.Hall_Fund_Num, guild._Fund .. "/" .. guildLevel.MaxGuildFund)
    GUI.SetText(self._UIObjects.Hall_Level, string.format(StringTable.Get(10641), data._Level))
    local uiTemplate = self._UIObjects.Hall_Next:GetComponent(ClassType.UITemplate)
    local data = self._Building_Config[1]
    local guildLevel = CElementData.GetTemplate("GuildLevel", data._Level)
    local lab_day_exp = uiTemplate:GetControl(0)
    local lab_day_money = uiTemplate:GetControl(1)
    GUI.SetText(lab_day_exp, string.format(StringTable.Get(8109), game._HostPlayer._Guild._DayExp ,guildLevel.DayMaxExp))
    GUI.SetText(lab_day_money, string.format(StringTable.Get(8109), game._HostPlayer._Guild._DayFund ,guildLevel.DayMaxFund))
	if data._LevelUp and self:CanLevelUpBuilding() then
		self._UIObjects.Img_BtnFloatFx:SetActive(true)
	else
		self._UIObjects.Img_BtnFloatFx:SetActive(false)
	end
end

def.method().UpdatePageRedPoint = function(self)
    self:UpdateBuildingList()
    self:UpdateHallInfo()
end

def.method("number").PlayBuildingLevelUpFX = function(self, buildingID)
    local index = 1
    for i,v in ipairs(self._Building_Config) do
        if i ~= 1 and v._BuildingType == buildingID then
            index = i - 2
        end
    end
    local item = self._UIObjects.Building_List:GetItem(index)
    if item ~= nil then
        local img_bg = item:FindChild("Img_BG_0")
        GameUtil.StopUISfx(PATH.UIFX_GuildBuildingLevelUp, img_bg)
        GameUtil.PlayUISfx(PATH.UIFX_GuildBuildingLevelUp, img_bg, img_bg, 2)
    end
end

-- 当点击
def.method("string").OnClick = function(self, id) 
	
	if id == "Btn_Hall_Level" then
		self:OnBtnHallLevel()
	end
end

-- 初始化列表
def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "Guild_Building_List" then
    	index = index + 2
    	local data = self._Building_Config[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local img_bg = uiTemplate:GetControl(1)
        local lab_name = uiTemplate:GetControl(2)
        local lab_level = uiTemplate:GetControl(4)
        local lab_des = uiTemplate:GetControl(3)
        local btn_building_up = uiTemplate:GetControl(8)
        local lock = uiTemplate:GetControl(6)
        local lab_level1 = uiTemplate:GetControl(7)
        local btn_building_enter = uiTemplate:GetControl(9)
        local red_point = uiTemplate:GetControl(5)
    	GUITools.SetSprite(img_bg, data._IconPath)
    	GUI.SetText(lab_name, data._Name)
    	GUI.SetText(lab_level, tostring(data._Level))
    	GUI.SetText(lab_des, data._Des)
    	-- self:CanLevelUpBuilding()
    	btn_building_up:SetActive(data._LevelUp and self:CanLevelUpBuilding() and data._Unlock)
    	lock:SetActive(not data._Unlock)

    	item:FindChild("Panel"):SetActive(data._Unlock)
    	btn_building_enter:SetActive(data._Unlock)
    	if not data._Unlock then
    		GUI.SetText(lab_level1, string.format(StringTable.Get(8108), data._PlayerLevel))
            GameUtil.MakeImageGray(img_bg, true)
        else
            GameUtil.MakeImageGray(img_bg, false)
    	end
    	red_point:SetActive(data._IsRed)
    end
end

-- 选中列表
def.method("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if id == "Guild_Building_List" then

	end
end

-- 选中列表按钮
def.method("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	if id == "Guild_Building_List" then
		index = index + 2
		if id_btn == "Btn_Building_Up" then
			if game._HostPlayer:IsInGlobalZone() then
		        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
		        return
		    end
			game._GUIMan:Open("CPanelUIGuildLvUp", self._Building_Config[index])
		else
			local buildingType = self._Building_Config[index]._BuildingType
			if buildingType == 1 then
				game._GuildMan:OpenGuildSmithy()
			elseif buildingType == 2 then
				game._GuildMan:OpenGuildPray()			
			elseif buildingType == 3 then
				game._GuildMan:OpenGuildDungeon()
			elseif buildingType == 4 then
				game._GuildMan:OpenGuildShop()
			elseif buildingType == 5 then
				game._GuildMan:OpenGuildLaboratory()
			end
		end
	end
end

-- 获取建筑红点(为保证便于维护，牺牲一定的耦合性)
def.method("=>", "boolean").CanLevelUpBuilding = function(self)
	if game._GuildMan:IsSmithyHasRedPoint() then
		return true
	end
	local member = game._GuildMan:GetHostGuildMemberInfo()		
	-- warn(" member._Permission, PermissionMask.UpgradeBuild  ", member._Permission, PermissionMask.UpgradeBuild,bit.band(member._Permission, PermissionMask.UpgradeBuild) )
	if member ~= nil and 0 ~= bit.band(member._Permission, PermissionMask.UpgradeBuild) then	
		for i, v in ipairs(self._Building_Config) do
			if v._LevelUp then
				return true
			end
		end
		return false
	else
		return false
	end
end

-- 大厅升级
def.method().OnBtnHallLevel = function(self)
	if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        return
    end
	if self._Building_Config[1]._IsMaxLevel then
		game._GUIMan:ShowTipText(StringTable.Get(8123),true)
		return
	end
	game._GUIMan:Open("CPanelUIGuildLvUp", self._Building_Config[1])
end

-- 隐藏时调用
def.method().Hide = function(self)
	self._FrameRoot:SetActive(false)
end

-- 摧毁时调用
def.method().Destroy = function(self)
	self._Parent = nil
	self._FrameRoot = nil
	self._UIObjects = nil

	self._Building_Config = nil
    CGame.EventManager:removeHandler(GuildEvent, self._GuildEventCB)
end

CPageGuildBuilding.Commit()
return CPageGuildBuilding