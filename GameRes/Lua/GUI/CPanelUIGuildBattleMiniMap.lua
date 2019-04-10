-- 公会战场小地图
-- 2018/8/8

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIGuildBattleMiniMap = Lplus.Extend(CPanelBase, "CPanelUIGuildBattleMiniMap")
local def = CPanelUIGuildBattleMiniMap.define

local CElementData = require "Data.CElementData"
local MapBasicConfig = require "Data.MapBasicConfig"
local CTeamMan = require "Team.CTeamMan"

-- 界面
def.field("userdata")._Btn_LeaveDungeon = nil
def.field("userdata")._Frame_Time = nil
def.field("userdata")._Lab_TimeTitle = nil
def.field("userdata")._Lab_Time = nil
def.field("userdata")._Lab_Blue_Rank = nil
def.field("userdata")._Lab_Red_Rank = nil
def.field("table")._ImgTemplates = nil
-- 数据
def.field("table")._BuildingInfos = BlankTable          -- 建筑信息，包含基地和塔
def.field("table")._MineInfos = BlankTable              -- 矿物信息，包含祭品和祭坛
def.field("table")._PlayerInfos = BlankTable            -- 玩家信息，包含Boss，队友和主角
def.field("table")._AllNonPlayerType = BlankTable       -- 所有非玩家物体类型
-- 缓存
def.field("table")._MapOffset = BlankTable              -- 场景地图对应小地图的偏移表
def.field("table")._ImgPools = BlankTable               -- 图片缓存池
def.field("table")._TempVector3 = nil
def.field("number")._MapUpdateTimerId = 0               -- 小地图更新Timer
def.field("number")._EndTime = 0                        -- 剩余时间
def.field("number")._TimeShowType = 0                   -- 剩余时间的展示类型
def.field("number")._CountDownTimerId = 0               -- 祭品倒计时Timer
def.field("table")._CurAllPlayerInfos = BlankTable      -- 当前推送的所有玩家信息
def.field("table")._BuildingExploreTimers = nil         -- 建筑爆炸之后消失的timers

local MAP_UPDATE_INTERVAL = 0.5 -- 小地图刷新间隔(s)
local OBLATION_ICON_NUM = 3 -- 地图上祭品图标的数量
-- 战场颜色
local EBattleColor =
{
	Red = 1,
	Blue = 2,
    Neutral = 3,
}
-- 物体类型
local ENonPlayerType =
{
	Base = 1,
	Tower = 2,
	Altar = 3,
	HighAltar = 4,
	Oblation = 5,
	HighOblation = 6
}

local instance = nil
def.static("=>", CPanelUIGuildBattleMiniMap).Instance = function ()
	if instance == nil then
		instance = CPanelUIGuildBattleMiniMap()
		instance._PrefabPath = PATH.UI_Guild_Battle_MiniMap
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self._Btn_LeaveDungeon = self:GetUIObject("Btn_LeaveDungeon")
	self._Frame_Time = self:GetUIObject("Frame_OblationTime")
	self._Lab_TimeTitle = self:GetUIObject("Lab_OblationTitle")
	self._Lab_Time = self:GetUIObject("Lab_OblationTime")
    self._Lab_Red_Rank = self:GetUIObject("Lab_RedRank")
    self._Lab_Blue_Rank = self:GetUIObject("Lab_BlueRank")
	self._ImgTemplates =
	{
		["HostPlayer"] = self:GetUIObject("Img_HostPlayer"), -- 为了方便使用
		["Team"] = self:GetUIObject("Img_TeamMember"),
        ["GuildMember"] = self:GetUIObject("Img_GuildMember"),
		["Boss"] = self:GetUIObject("Img_Boss")
	}

	GUITools.SetUIActive(self._Frame_Time, false)
	for _, v in pairs(self._ImgTemplates) do
		GUITools.SetUIActive(v, false)
	end

	self._ImgPools =
	{
		["HostPlayer"] = {}, -- 为了方便使用
		["Team"] = {},
        ["GuildMember"] ={},
		["Boss"] = {}
	}
	self._TempVector3 = Vector3.zero
end

-----------------三种表结构----------------------
local function GetBuildingTable()
	return
	{
		FrameObj = nil,
		ImageComponent = nil,
		MaxHP = 1,
		CurHP = -1,
        CampColor = EBattleColor.Red,
		IsBase = false
	}
end

local function GetMineTable()
	return
	{
		UIObj = nil,
		ProcessTimer = 0,
        CampColor = EBattleColor.Red,
        Status = 0              -- 0 是消失， 1 是开启， 2 是充能
	}
end

local function GetPlayerTable()
	return
	{
		UIObj = nil,
		RectComponent = nil,
        IsTeamMember = false,
		IsBoss = false,
		PosX = 0,
		PosZ = 0
	}
end
---------------------------------------------------------

-----------------------本地方法 start---------------------
local function GetBattleSceneTid()
	local mapTid = 0
	local EInstanceType = require "PB.Template".Instance.EInstanceType
	local dungeonTids = game._DungeonMan:GetAllDungeonInfo()
	for _, tid in ipairs(dungeonTids) do
		local template = CElementData.GetInstanceTemplate(tid)
		if template ~= nil and template.InstanceType == EInstanceType.INSTANCE_GUILD_BATTLEFIELD then
			-- 公会战场类型
			mapTid = template.AssociatedWorldId
			break
		end
	end
	local sceneTid = 0
	if mapTid > 0 then
		local template = CElementData.GetMapTemplate(mapTid)
		if template ~= nil then
			sceneTid = template.AssociatedMapId
		end
	end
	return sceneTid
end

local function GetGameObjectByTemplate(template)
	if IsNil(template) then return nil end

	local obj = GameObject.Instantiate(template)
	obj:SetParent(template.parent)
	obj.localPosition = template.localPosition
	obj.localScale = template.localScale
	obj.localRotation = template.localRotation
	GUITools.SetUIActive(obj, true)
	return obj
end

local function SetPos(self, rect, x, z)
	if rect == nil then return end

	local xPosOnMap = x
	local yPosOnMap = z
	if next(self._MapOffset) ~= nil then
		-- 校正偏移量
		xPosOnMap = xPosOnMap * self._MapOffset.A1 + self._MapOffset.width
		yPosOnMap = yPosOnMap * self._MapOffset.A2 + self._MapOffset.height
	end
	self._TempVector3.x = xPosOnMap
	self._TempVector3.y = yPosOnMap
	self._TempVector3.z = 0

	rect.anchoredPosition3D = self._TempVector3
end

local function IsTeamMember(id)
    if (not CTeamMan.Instance():HaveTeamMember()) or id == game._HostPlayer._ID then
        return false
    end
    local teamList = CTeamMan.Instance():GetMemberList()
	for _, teamMemeber in ipairs(teamList) do
        if teamMemeber._ID == id then
            return true
        end
	end
    return false
end

local function AddPlayerInfo(self, id, isBoss, color)
	local obj = nil
	if isBoss then
		obj = self:GetImgByPools("Boss")
		if color > 0 then
			GUITools.SetGroupImg(obj, color - 1)
		end
	else
		if id == game._HostPlayer._ID then
			-- 主角
			obj = self:GetImgByPools("HostPlayer")
		elseif IsTeamMember(id) then
			obj = self:GetImgByPools("Team")
        else
            obj = self:GetImgByPools("GuildMember")
		end
	end
	local info = GetPlayerTable()
	info.UIObj = obj
	info.RectComponent = obj:GetComponent(ClassType.RectTransform)
	info.IsBoss = isBoss
    info.IsTeamMember = IsTeamMember(id)
    if isBoss then
        print("变身 BOSS ,     color : ", color)
        if color == EBattleColor.Red then
            GameUtil.PlayUISfx(PATH.UIFX_GuildBFBossRed, info.UIObj, info.UIObj, -1)
        elseif color == EBattleColor.Blue then
            GameUtil.PlayUISfx(PATH.UIFX_GuildBFBossBlue, info.UIObj, info.UIObj, -1)
        end
    else
        if color == EBattleColor.Red then
            GameUtil.StopUISfx(PATH.UIFX_GuildBFBossRed, info.UIObj)
        elseif color == EBattleColor.Blue then
            GameUtil.StopUISfx(PATH.UIFX_GuildBFBossBlue, info.UIObj)
        end
    end
	self._PlayerInfos[id] = info
	return info
end

local function RemovePlayerInfo(self, id, isTeamMember)
	local info = self._PlayerInfos[id]
	if info == nil then return end
	local imgType = ""
	if info.IsBoss then
		imgType = "Boss"
	else
		if id == game._HostPlayer._ID then
			-- 主角
			imgType = "HostPlayer"
		elseif isTeamMember then
			imgType = "Team"
        else
            imgType = "GuildMember"
		end
	end
	self:RecyclingImg(info.UIObj, imgType)
	self._PlayerInfos[id] = nil
end

local function AddCurPlayerInfo(self, id, isBoss, color)
    local n_id = id
	local map =
	{
		C_IsBoss = isBoss,
        C_IsTeamMember = IsTeamMember(n_id),
		C_Color = color,
		C_PosX = 0,
		C_PosZ = 0
	}
	self._CurAllPlayerInfos[id] = map
	return map
end
----------------------本地方法 end---------------------

def.method().InitAllBuilding = function (self)
	local sceneTid = GetBattleSceneTid()
	if sceneTid <= 0 then
		error("CPanelUIGuildBattleMiniMap InitBuilding failed, scenTid error")
		return
	end

	local offset = MapBasicConfig.GetMapOffset() or {}
	if offset[sceneTid] ~= nil then
		self._MapOffset.A1 = offset[sceneTid].A1
		self._MapOffset.A2 = offset[sceneTid].A2
		self._MapOffset.width = offset[sceneTid].width
		self._MapOffset.height = offset[sceneTid].height
	end

	local allMonsters = {} -- 所有怪物
	--local mapInfo = _G.MapBasicInfoTable[sceneTid]
	local mapInfo = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid)
	for tid, data in pairs(mapInfo.Monster) do
		if #data > 0 then
			allMonsters[tid] = { x = data[1].x, z = data[1].z }
		end
	end
	local allMines = {} -- 所有矿物
	for tid, data in pairs(mapInfo.Mine) do
		if #data > 0 then
			allMines[tid] = { x = data[1].x, z = data[1].z }
		end
	end

	local function InitBuildingInfo(template, color, isBase, x, z)
		local obj = GetGameObjectByTemplate(template)
		GUITools.SetUIActive(obj, false) -- 是否显示根据服务器推送数据
		local rect = obj:GetComponent(ClassType.RectTransform)
		SetPos(self, rect, x, z)
		-- 背景
		local img_bg = GUITools.GetChild(obj, 0)
		GUITools.SetGroupImg(img_bg, color - 1)
		-- 血量填充
		local img_fill = GUITools.GetChild(obj, 1)
		GUITools.SetGroupImg(img_fill, color - 1)

		local info = GetBuildingTable()
		info.FrameObj = obj
		info.ImageComponent = img_fill:GetComponent(ClassType.Image)
		info.IsBase = isBase
        info.CampColor = color
		return info
	end

    -- 初始化祭坛信息
	local function InitMineInfo(template, color, isHighLv, x, z)
		local obj = GetGameObjectByTemplate(template)
		local info = GetMineTable()
		info.UIObj = obj
        info.Status = 0
        info.CampColor = color
        if isHighLv then
            GUITools.SetGroupImg(obj, color - 1)
        else
            local uiTemplate = obj:GetComponent(ClassType.UITemplate)
            local img_bg = uiTemplate:GetControl(0)
            local img = uiTemplate:GetControl(1)
            GUITools.SetGroupImg(img, color - 1)
            GUITools.SetGroupImg(img_bg, color - 1)
        end
		local rect = obj:GetComponent(ClassType.RectTransform)
		SetPos(self, rect, x, z)
		return info
	end

	-- 图片模版
	local imgOblationTemplate = self:GetUIObject("Img_Oblation")
	local frameAltarTemplate = self:GetUIObject("Frame_Altar")
	local imgHighAltarTemplate = self:GetUIObject("Img_HighAltar")
	local frameTowerTemplate = self:GetUIObject("Frame_Tower")
	local frameBaseTemplate = self:GetUIObject("Frame_Base")
	GUITools.SetUIActive(imgOblationTemplate, false)
	GUITools.SetUIActive(frameAltarTemplate, false)
	GUITools.SetUIActive(imgHighAltarTemplate, false)
	GUITools.SetUIActive(frameTowerTemplate, false)
	GUITools.SetUIActive(frameBaseTemplate, false)

	local CSpecialIdMan = require "Data.CSpecialIdMan"
	-- 防御塔
	do
		local redTowerTids = string.split(CSpecialIdMan.Get("GuildBattleRedTower"), "*")
		for _, tidStr in ipairs(redTowerTids) do
			local tid = tonumber(tidStr)
			if allMonsters[tid] ~= nil then
				local info = InitBuildingInfo(frameTowerTemplate, EBattleColor.Red, false, allMonsters[tid].x, allMonsters[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.Tower
				self._BuildingInfos[tid] = info
			end
		end
		local blueTowerTids = string.split(CSpecialIdMan.Get("GuildBattleBlueTower"), "*")
		for _, tidStr in ipairs(blueTowerTids) do
			local tid = tonumber(tidStr)
			if allMonsters[tid] ~= nil then
				local info = InitBuildingInfo(frameTowerTemplate, EBattleColor.Blue, false, allMonsters[tid].x, allMonsters[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.Tower
				self._BuildingInfos[tid] = info
			end
		end
	end
	-- 基地
	do
		local redBaseTid = CSpecialIdMan.Get("GuildBattleRedBase")
		if allMonsters[redBaseTid] ~= nil then
			local info = InitBuildingInfo(frameBaseTemplate, EBattleColor.Red, true, allMonsters[redBaseTid].x, allMonsters[redBaseTid].z)
			self._AllNonPlayerType[redBaseTid] = ENonPlayerType.Base
			self._BuildingInfos[redBaseTid] = info
		end
		local blueBaseTid = CSpecialIdMan.Get("GuildBattleBlueBase")
		if allMonsters[blueBaseTid] ~= nil then
			local info = InitBuildingInfo(frameBaseTemplate, EBattleColor.Blue, true, allMonsters[blueBaseTid].x, allMonsters[blueBaseTid].z)
			self._AllNonPlayerType[blueBaseTid] = ENonPlayerType.Base
			self._BuildingInfos[blueBaseTid] = info
		end
	end
	-- 普通祭坛
	do
		local redAltarTids = string.split(CSpecialIdMan.Get("GuildBattleRedAltar"), "*")
		for _, tidStr in ipairs(redAltarTids) do
			local tid = tonumber(tidStr)
			if allMines[tid] ~= nil then
				local info = InitMineInfo(frameAltarTemplate, EBattleColor.Red, false, allMines[tid].x, allMines[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.Altar
				self._MineInfos[tid] = info
			end
		end
		local blueAltarTids = string.split(CSpecialIdMan.Get("GuildBattleBlueAltar"), "*")
		for _, tidStr in ipairs(blueAltarTids) do
			local tid = tonumber(tidStr)
			if allMines[tid] ~= nil then
				local info = InitMineInfo(frameAltarTemplate, EBattleColor.Blue, false, allMines[tid].x, allMines[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.Altar
				self._MineInfos[tid] = info
			end
		end
	end
	-- 高级祭坛
	do
		local redHighAltarTids = string.split(CSpecialIdMan.Get("GuildBattleRedHighAltar"), "*")
		for _, tidStr in ipairs(redHighAltarTids) do
			local tid = tonumber(tidStr)
			if allMines[tid] ~= nil then
				local info = InitMineInfo(imgHighAltarTemplate, EBattleColor.Red, true, allMines[tid].x, allMines[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.HighAltar
				self._MineInfos[tid] = info
			end
		end
		local blueHighAltarTids = string.split(CSpecialIdMan.Get("GuildBattleBlueHighAltar"), "*")
		for _, tidStr in ipairs(blueHighAltarTids) do
			local tid = tonumber(tidStr)
			if allMines[tid] ~= nil then
				local info = InitMineInfo(imgHighAltarTemplate, EBattleColor.Blue, true, allMines[tid].x, allMines[tid].z)
				self._AllNonPlayerType[tid] = ENonPlayerType.HighAltar
				self._MineInfos[tid] = info
			end
		end
	end
	-- 祭品
	do
		--local oblationTids = string.split(CSpecialIdMan.Get("GuildBattleOblation"), "*")
		local highOblationTids = string.split(CSpecialIdMan.Get("GuildBattleHighOblation"), "*")
		for i = 1, OBLATION_ICON_NUM do
			-- 祭品和高级祭品在特殊ID里一一对应
--			local normalTid = oblationTids[i]
--			if normalTid ~= nil then
--				normalTid = tonumber(normalTid)
--			end
			local highTid = highOblationTids[i]
			if highTid ~= nil then
				highTid = tonumber(highTid)
			end
			if highTid ~= nil then
--				if allMines[normalTid] ~= nil then
--					-- 相同位置的祭品和高级祭品共享同一个图标
--					local obj = GetGameObjectByTemplate(imgOblationTemplate)
--					GUI.SetAlpha(obj, 127) -- 默认关闭状态，图标半透
--					local rect = obj:GetComponent(ClassType.RectTransform)
--					SetPos(self, rect, allMines[normalTid].x, allMines[normalTid].z)

--					local info = GetMineTable()
--					info.UIObj = obj
--                    info.IsAltar = false
--					self._MineInfos[normalTid] = info
--					self._AllNonPlayerType[normalTid] = ENonPlayerType.Oblation
--				end
                if allMines[highTid] ~= nil then
                    local obj = GetGameObjectByTemplate(imgOblationTemplate)
					GUI.SetAlpha(obj, 127) -- 默认关闭状态，图标半透
					local rect = obj:GetComponent(ClassType.RectTransform)
					SetPos(self, rect, allMines[highTid].x, allMines[highTid].z)
                    local info = GetMineTable()
					info.UIObj = obj
                    info.IsAltar = false
					self._MineInfos[highTid] = info
					self._AllNonPlayerType[highTid] = ENonPlayerType.HighOblation
                end
			end
		end
	end
end

def.override("dynamic").OnData = function (self, data)
	if self._MapUpdateTimerId ~= 0 then return end -- 已经打开过了

	self:InitAllBuilding()
    self:UpdateAllMinesStatus()
	-- Add Timer
	if self._MapUpdateTimerId == 0 then
		self._MapUpdateTimerId = game._HostPlayer:AddTimer(MAP_UPDATE_INTERVAL, false, function()
			self:UpdateMapInfo()
		end)
	end
    self:UpdateRankInfo()
end

------------------------小地图更新逻辑 start---------------------------
def.method().UpdateMapInfo = function (self)
	self:UpdateBattleInfo()
	self:UpdateHostPlayerInfo()
	self:UpdateTeamPlayerInfo()

	self:UpdateAllPlayersState()
	self:UpdateAllPlayersPos()
end

def.method().UpdateAllMinesStatus = function(self)
    for tid,v in pairs(self._MineInfos) do
        local mine_type = self._AllNonPlayerType[tid]
        if mine_type == ENonPlayerType.Altar or mine_type == ENonPlayerType.HighAltar then
            self:UpdateMineStatus(tid, v.Status, 0)
        end
    end
end

-- 更新战场信息
def.method().UpdateBattleInfo = function (self)
	local entityInfos = game._GuildMan:GetBattleEntityInfo()
	if entityInfos ~= nil then
		self._CurAllPlayerInfos = {}

		for _, info in pairs(entityInfos) do
			-- info 结构: PB.net.GuildBFEntityInfo
			local entityId = info.EntityId
			if type(entityId) == "number" then
				local nonPlayerTid = info.Tid
				-- print("tid:", nonPlayerTid)
				if nonPlayerTid ~= nil and nonPlayerTid > 0 then
					-- 属于非玩家
					local entityType = self._AllNonPlayerType[nonPlayerTid]
					if entityType == ENonPlayerType.Base or entityType == ENonPlayerType.Tower then
						-- 建筑
						-- print("curHP:", info.CurrentHp, ", maxHp:", info.MaxHp)

						self:SetBuildingHP(nonPlayerTid, info.CurrentHp, info.MaxHp)
                    end
				else
					-- 属于玩家（包含主角，队友）
					-- print("entityId:", entityId, "isBoss:", info.Isboss, ", camp:", info.camp)

					local color = 0
					if info.Isboss == true and info.camp ~= nil then
						-- 变身成Boss
						if info.camp == 1 then
							-- 1 代表红方
							color = EBattleColor.Red
						elseif info.camp == 2 then
							-- 2 代表蓝方
							color = EBattleColor.Blue
						end
					end
					local curInfo = AddCurPlayerInfo(self, entityId, info.Isboss == true, color)
					curInfo.C_PosX = info.Posx
					curInfo.C_PosZ = info.Posz
				end
			end
		end
	end
end

-- 更新主角信息
def.method().UpdateHostPlayerInfo = function (self)
	local hostPlayerId = game._HostPlayer._ID
	local curInfo = self._CurAllPlayerInfos[hostPlayerId]
	if curInfo == nil then
		curInfo = AddCurPlayerInfo(self, hostPlayerId, false, 0)
	end
	curInfo.C_PosX, curInfo.C_PosZ = game._HostPlayer:GetPosXZ()
end

-- 更新队友信息
def.method().UpdateTeamPlayerInfo = function (self)
	if CTeamMan.Instance():HaveTeamMember() then
		local teamList = CTeamMan.Instance():GetMemberList()
		for _, teamMemeber in ipairs(teamList) do
			local id = teamMemeber._ID
			if id ~= game._HostPlayer._ID then
				if teamMemeber._IsOnLine then 
					local teamMemPos = CTeamMan.Instance():GetMemberPositionInfo(id)
					if teamMemPos ~= nil then
						if teamMemPos.MapId == game._CurWorld._WorldInfo.SceneTid then
							local curInfo = self._CurAllPlayerInfos[id]
							if curInfo == nil then
								curInfo = AddCurPlayerInfo(self, id, false, 0)
							end
							curInfo.C_PosX = teamMemPos.Position.x
							curInfo.C_PosZ = teamMemPos.Position.z
						end
					end
				end
			end
		end
	end
end

-- 更新所有玩家的状态
def.method().UpdateAllPlayersState = function (self)
	-- 更新Boss状态
	for id, info in pairs(self._CurAllPlayerInfos) do
		local playerInfo = self._PlayerInfos[id]
		if playerInfo ~= nil then
			if playerInfo.IsBoss ~= info.C_IsBoss or playerInfo.IsTeamMember ~= info.C_IsTeamMember then
				RemovePlayerInfo(self, id, playerInfo.IsTeamMember)
				AddPlayerInfo(self, id, info.C_IsBoss, info.C_Color)
			end
		else
			AddPlayerInfo(self, id, info.C_IsBoss, info.C_Color)
		end
	end
	-- 移除已消失的
	local removeIds = {}
	for id, _ in pairs (self._PlayerInfos) do
		if self._CurAllPlayerInfos[id] == nil then
			if id ~= game._HostPlayer._ID then
				table.insert(removeIds, id)
			end
		end
	end
	for _, id in ipairs(removeIds) do
		RemovePlayerInfo(self, id, self._PlayerInfos[id].IsTeamMember)
	end
end

-- 更新所有玩家的位置
def.method().UpdateAllPlayersPos = function (self)
	for id, info in pairs(self._CurAllPlayerInfos) do
		local playerInfo = self._PlayerInfos[id]
		if playerInfo ~= nil then
			SetPos(self, playerInfo.RectComponent, info.C_PosX, info.C_PosZ)

			if id == game._HostPlayer._ID and not info.C_IsBoss then
				-- 主角为非Boss状态，更新主角朝向
				local dirX, dirZ = game._HostPlayer:GetDirXZ()
				local z = math.rad2Deg * math.atan2(dirZ, dirX) - 90
				playerInfo.UIObj.rotation = Quaternion.Euler(0, 0, z)
			end
		end
	end
end

-- 设置建筑血量
def.method("number", "number", "number").SetBuildingHP = function (self, tid, curHP, maxHP)
	local buildingInfo = self._BuildingInfos[tid]
	if buildingInfo == nil then
		warn("SetBuildingHP failed, got empty buildingInfo, wrong tid: " .. tid)
		return
	end

	if buildingInfo.CurHP ~= curHP then
		
		if curHP > 0 then
			local hpPercent = curHP / maxHP
			buildingInfo.ImageComponent.fillAmount = hpPercent
		end
        if curHP <= 0 then
            if buildingInfo.CampColor == EBattleColor.Red then
                GameUtil.PlayUISfx(PATH.UIFX_GuildBFBaseExploreRed, buildingInfo.FrameObj, buildingInfo.FrameObj, 3)
            else
                GameUtil.PlayUISfx(PATH.UIFX_GuildBFBaseExploreBlue, buildingInfo.FrameObj, buildingInfo.FrameObj, 3)
            end
            if self._BuildingExploreTimers == nil then
                self._BuildingExploreTimers = {}
            end
            if self._BuildingExploreTimers[tid] then
                _G.RemoveGlobalTimer(self._BuildingExploreTimers[tid])
            end
            local callback = function()
                GUITools.SetUIActive(buildingInfo.FrameObj, false)
                self._BuildingExploreTimers[tid] = nil
            end
            self._BuildingExploreTimers[tid] = _G.AddGlobalTimer(0.5, true, callback)
        else
            GUITools.SetUIActive(buildingInfo.FrameObj, true)
        end
	end
end

-- 更新矿物状态
def.method("number", "number", "number").UpdateMineStatus = function (self, tid, status, endTime)
	local entityType = self._AllNonPlayerType[tid]
	if entityType ~= nil then
        local mineInfo = self._MineInfos[tid]
		if entityType == ENonPlayerType.Altar or entityType == ENonPlayerType.HighAltar then
	        if mineInfo ~= nil then
                GUITools.SetBtnExpressGray(mineInfo.UIObj, status ~= 1)
                if entityType == ENonPlayerType.Altar then
                    local img_altar = mineInfo.UIObj:GetComponent(ClassType.UITemplate):GetControl(1)
                    local img_comp = img_altar:GetComponent(ClassType.Image)
                    if mineInfo.ProcessTimer ~= 0 then
                        _G.RemoveGlobalTimer(mineInfo.ProcessTimer)
                        mineInfo.ProcessTimer = 0
                    end
                    if status == 2 then         -- 如果祭坛是处在充能状态
                        print("进入充能状态")
                        local start_time = GameUtil.GetServerTime()/1000
                        img_comp.fillAmount = 0
                        local callback = function()
                            local now_time = GameUtil.GetServerTime()/1000
                            local runed_time = now_time - start_time
                            if now_time >= endTime then
                                _G.RemoveGlobalTimer(mineInfo.ProcessTimer)
                                mineInfo.ProcessTimer = 0
                                img_comp.fillAmount = 1
                            end
                            img_comp.fillAmount = math.min(1, math.max(0, runed_time/(endTime - start_time)))
                        end
                        mineInfo.ProcessTimer = _G.AddGlobalTimer(MAP_UPDATE_INTERVAL, false, callback)
                    elseif status == 0 then     -- 如果祭坛是处在未激活状态
                        img_comp.fillAmount = 0
                    else                        -- 如果祭坛是处在激活状态
                        img_comp.fillAmount = 1
                    end
                else
                    
                end
                if mineInfo.Status ~= status then
                    if mineInfo.CampColor == EBattleColor.Red then
                        if entityType == ENonPlayerType.Altar then
                            if status == 1 then
                                GameUtil.PlayUISfx(PATH.UIFX_GuildBFNormalAltarRed, mineInfo.UIObj, mineInfo.UIObj, -1)
                            else
                                GameUtil.StopUISfx(PATH.UIFX_GuildBFNormalAltarRed, mineInfo.UIObj)
                            end
                        else
                            if status == 1 then
                                GameUtil.PlayUISfx(PATH.UIFX_GuildBFHighAltarRed, mineInfo.UIObj, mineInfo.UIObj, -1)
                            else
                                GameUtil.StopUISfx(PATH.UIFX_GuildBFHighAltarRed, mineInfo.UIObj)
                            end
                        end
                    elseif mineInfo.CampColor == EBattleColor.Blue then
                        if entityType == ENonPlayerType.Altar then
                            if status == 1 then
                                GameUtil.PlayUISfx(PATH.UIFX_GuildBFNormalAltarBlue, mineInfo.UIObj, mineInfo.UIObj, -1)
                            else
                                GameUtil.StopUISfx(PATH.UIFX_GuildBFNormalAltarBlue, mineInfo.UIObj)
                            end
                        else
                            if status == 1 then
                                GameUtil.PlayUISfx(PATH.UIFX_GuildBFHighAltarBlue, mineInfo.UIObj, mineInfo.UIObj, -1)
                            else
                                GameUtil.StopUISfx(PATH.UIFX_GuildBFHighAltarBlue, mineInfo.UIObj)
                            end
                        end
                    end
                end
	        end
		elseif entityType == ENonPlayerType.Oblation then
		    GUITools.SetBtnExpressGray(mineInfo.UIObj, status ~= 1)
            if mineInfo.Status ~= status then
                if status == 1 then
                    GameUtil.PlayUISfx(PATH.UIFX_GuildBFOblation, mineInfo.UIObj, mineInfo.UIObj, -1)
                else
                    GameUtil.StopUISfx(PATH.UIFX_GuildBFOblation, mineInfo.UIObj)
                end
            end
		elseif entityType == ENonPlayerType.HighOblation then
		    -- TODO
            GUITools.SetBtnExpressGray(mineInfo.UIObj, status ~= 1)
            if mineInfo.Status ~= status then
                if status == 1 then
                    GameUtil.PlayUISfx(PATH.UIFX_GuildBFOblation, mineInfo.UIObj, mineInfo.UIObj, -1)
                else
                    GameUtil.StopUISfx(PATH.UIFX_GuildBFOblation, mineInfo.UIObj)
                end
            end
		end
        if mineInfo ~= nil then
            mineInfo.Status = status
        end
	end
end


def.method().UpdateRankInfo = function(self)
    local guild_man = game._GuildMan
    GUI.SetText(self._Lab_Red_Rank, tostring(guild_man._RedRank))
    GUI.SetText(self._Lab_Blue_Rank, tostring(guild_man._BlueRank))
end

-- 从回收池获取
def.method("string", "=>", "userdata").GetImgByPools = function (self, imgType)
	local pool = self._ImgPools[imgType]
	if pool == nil then return nil end

	local obj = nil
	if next(pool) == nil then
		obj = GetGameObjectByTemplate(self._ImgTemplates[imgType])
	else
		obj = table.remove(pool)
		GUITools.SetUIActive(obj, true)
	end
	return obj
end

-- 释放到回收池
def.method("userdata", "string").RecyclingImg = function (self, obj, imgType)
	if IsNil(obj) then return end

	local pool = self._ImgPools[imgType]
	if pool == nil then
		obj:Destory()
		return
	end

	GUITools.SetUIActive(obj, false)
	table.insert(pool, obj)
end
------------------------小地图更新逻辑 end----------------------------


def.override("string").OnClick = function (self, id)
    if id == "Btn_LeaveDungeon" then
        if game._HostPlayer:IsDead() then
            game._GUIMan:ShowTipText(StringTable.Get(30103), false)
        else
	        local function callback(value)
		        if value then
			        local hp = game._HostPlayer
			        if hp:InDungeon() or hp:InImmediate() then
				        game._DungeonMan:TryExitDungeon()
				        -- GUITools.SetUIActive(self._Btn_LeaveDungeon, false)
			        end
		        end
	        end
	        local title, msg, closeType = StringTable.GetMsg(84)
	        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
        end
    end
end

def.override().OnDestroy = function (self)
	if self._MapUpdateTimerId ~= 0 then
		game._HostPlayer:RemoveTimer(self._MapUpdateTimerId)
		self._MapUpdateTimerId = 0
	end
    if self._BuildingExploreTimers ~= nil then
        for i,v in pairs(self._BuildingExploreTimers) do
            if v ~= nil then
                _G.RemoveGlobalTimer(v)
            end
        end
    end
    self._BuildingExploreTimers = nil
	self._Btn_LeaveDungeon = nil
	self._Frame_Time = nil
	self._Lab_TimeTitle = nil
	self._Lab_Time = nil
	self._ImgTemplates = {}
	self._BuildingInfos = {}
	self._MineInfos = {}
	self._PlayerInfos = {}
	self._AllNonPlayerType = {}
	self._ImgPools = {}
end

CPanelUIGuildBattleMiniMap.Commit()
return CPanelUIGuildBattleMiniMap