--小地图面板
--时间：2017/8/2
--Add by Yao

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
local QuestTypeDef = require "Quest.QuestDef".QuestType
local QuestFuncDef = require "Quest.QuestDef".QuestFunc
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CTeamMan = require "Team.CTeamMan"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local MapBasicConfig = require "Data.MapBasicConfig"
local CPath = require "Path.CPath"
local QuestUtil = require "Quest.QuestUtil"

local CombatStateChangeEvent = require"Events.CombatStateChangeEvent"

local CPageMiniMap = Lplus.Class("CPageMiniMap")
local def = CPageMiniMap.define

def.field("table")._Parent = nil
-- 界面
def.field("userdata")._Frame_HostPlayer = nil
def.field("userdata")._Rect_HostPlayer = nil
def.field("userdata")._Img_CameraSight = nil
def.field("userdata")._Img_Weather = nil
def.field("userdata")._Lab_MapName = nil
def.field("userdata")._Mask_Map = nil
def.field("userdata")._Frame_Map = nil
def.field("userdata")._Img_Map = nil
def.field("userdata")._Lab_Postion = nil
def.field("userdata")._Rect_Limit = nil
def.field("userdata")._Img_Pointing = nil
def.field("userdata")._Rect_Pointing = nil
def.field("userdata")._Frame_GuildConvoy = nil
def.field("userdata")._Rect_GuildConvoy = nil
def.field("userdata")._TweenMan_GuildConvoy = nil
def.field("userdata")._Img_TargetLocation = nil
def.field("userdata")._TweenMan_TargetLocation = nil
def.field("userdata")._Rect_TargetLocation = nil
def.field("userdata")._Img_HawkEye = nil
def.field("userdata")._Rect_HawkEye = nil
def.field("table")._Templates = BlankTable
def.field("table")._PointPool = BlankTable -- 各种点的缓存池
def.field("table")._ImgTable_HawkEye = BlankTable
-- 数据
def.field("number")._M_TimerId = 0
def.field("table")._M_NPCMap = BlankTable
def.field("table")._M_PlayerMap = BlankTable
def.field("table")._M_HawkEyeMap = BlankTable
def.field("number")._ImgMapFrameWidth = 0
def.field("number")._ImgMapFrameHeight = 0
def.field("number")._MaskFrameWidth = 0
def.field("number")._MaskFrameHeight = 0
def.field("number")._ImgHostCenterX = 0
def.field("number")._ImgHostCenterY = 0
def.field("number")._ImgHostOffsetX = 0
def.field("number")._ImgHostOffsetY = 0
def.field("number")._HostPlayerPosX = 0
def.field("number")._HostPlayerPosZ = 0
def.field("table")._IsTeamLeader2Index = BlankTable -- 队友身份对应的图片索引
def.field("table")._ERelation2Index = BlankTable -- 玩家阵营对应的图片索引
def.field("table")._AllNpcMap = BlankTable -- 一个地图内的所有npc信息
-- 缓存
def.field("number")._SceneTid = 0
def.field("table")._CurSceneTemplate = BlankTable
def.field("number")._LastPosX = 0
def.field("number")._LastPosZ = 0
def.field("table")._TmpVector3 = BlankTable
def.field("table")._MapOffset = BlankTable
def.field("number")._SightRangeSqr = 0 -- 视野范围的平方
def.field("function")._OnCombatStateChange = nil
def.field("boolean")._IsPlayingFx = false
def.field("number")._CurWeather = 0 -- 当前天气
-- 常量
local BIG_MAP_SIZE = 938	-- 大地图的尺寸
local IMG_MAP_SCALE_X = 1.0
local IMG_MAP_SCALE_Y = 1.0
local POOL_NUM = 5

def.static("=>", CPageMiniMap).New = function()
	return CPageMiniMap()
end

-- 设置坐标文本，防止出现“-0”
local function SetLabPosition(self, x, z)
	local posXStr = ""
	if x == 0 then
		posXStr = "0"
	else
		posXStr = tostring(x)
	end
	local posZStr = ""
	if z == 0 then
		posZStr = "0"
	else
		posZStr = tostring(z)
	end
	self._Lab_Postion.text = posXStr .. "," .. posZStr
end

----------------------- 以下方法不能删除---------------------
def.method("table").Init = function(self, parent)
	self._Parent = parent

	self._ERelation2Index =
	{
		[RelationDesc[1]] = 0,		-- 友好
		[RelationDesc[2]] = 1,		-- 敌对
		[RelationDesc[0]] = 2,		-- 中立
	}
	self._IsTeamLeader2Index =
	{
		[true] = 0,					-- 队长
		[false] = 1,				-- 队友
	}

	self._Frame_HostPlayer = self._Parent:GetUIObject("Frame_HostPlayer")
	self._Rect_HostPlayer = self._Frame_HostPlayer:GetComponent(ClassType.RectTransform)
	self._Img_CameraSight = self._Parent:GetUIObject("Img_CameraSight")
	local rectCameraSight = self._Img_CameraSight:GetComponent(ClassType.RectTransform)
	rectCameraSight.pivot = Vector2.New(0.5, 0)
	self._Img_Weather = self._Parent:GetUIObject("Img_Weather")

	self._Frame_Map = self._Parent:GetUIObject("Frame_Map")
	self._Img_Map = self._Parent:GetUIObject("Img_Map")
	self._ImgMapFrameWidth, self._ImgMapFrameHeight = BIG_MAP_SIZE, BIG_MAP_SIZE
	local map_rect = self._Img_Map:GetComponent(ClassType.RectTransform)
	map_rect.sizeDelta = Vector2.New(self._ImgMapFrameWidth, self._ImgMapFrameHeight)
	map_rect = self._Frame_Map:GetComponent(ClassType.RectTransform)
	map_rect.sizeDelta = Vector2.New(self._ImgMapFrameWidth, self._ImgMapFrameHeight)

	self._Lab_MapName = self._Parent:GetUIObject("Lab_MapTitle"):GetComponent(ClassType.Text)
	self._Lab_Postion = self._Parent:GetUIObject("Lab_Postion"):GetComponent(ClassType.Text)
	-- self._Rect_Limit = self._Parent:GetUIObject("Frame_LimitPoint"):GetComponent(ClassType.RectTransform)
	self._Img_Pointing = self._Parent:GetUIObject("Img_Pointing")
	self._Rect_Pointing = self._Img_Pointing:GetComponent(ClassType.RectTransform)
	self._Rect_Pointing.pivot = Vector2.New(0.5, 1)
	self._Frame_GuildConvoy = self._Parent:GetUIObject("Frame_GuildConvoy")
	self._Rect_GuildConvoy = self._Frame_GuildConvoy:GetComponent(ClassType.RectTransform)
	self._TweenMan_GuildConvoy = self._Frame_GuildConvoy:GetComponent(ClassType.DOTweenPlayer)
	self._Img_TargetLocation = self._Parent:GetUIObject("Img_TargetLocation")
	self._Rect_TargetLocation = self._Img_TargetLocation:GetComponent(ClassType.RectTransform)
	self._TweenMan_TargetLocation = self._Img_TargetLocation:GetComponent(ClassType.DOTweenPlayer)
	self._Img_HawkEye = self._Parent:GetUIObject("Img_HawkEye")
	self._Rect_HawkEye = self._Img_HawkEye:GetComponent(ClassType.RectTransform)

	local imgEnemyTemplate = self._Parent:GetUIObject("Img_Enemy")
	local imgTeamTemplate = self._Parent:GetUIObject("Img_Team")
	local imgPlayerTemplate = self._Parent:GetUIObject("Img_Player")
	local imgQuestTemplate = self._Parent:GetUIObject("Img_Quest")
	local imgServiceTemplate = self._Parent:GetUIObject("Img_Service")
	local frameBossTemplate = self._Parent:GetUIObject("Frame_Boss")
	local imgHawkEyeTemplate = self._Parent:GetUIObject("Img_HawkEyePointing")

	imgEnemyTemplate:SetActive(false)
	imgTeamTemplate:SetActive(false)
	imgPlayerTemplate:SetActive(false)
	imgQuestTemplate:SetActive(false)
	imgServiceTemplate:SetActive(false)
	frameBossTemplate:SetActive(false)
	imgHawkEyeTemplate:SetActive(false)

	self._Mask_Map = self._Parent:GetUIObject("Mask_Map")
	local imgMapFrameRect = self._Mask_Map:GetComponent(ClassType.RectTransform)
	self._ImgHostCenterX = imgMapFrameRect.anchoredPosition3D.x
	self._ImgHostCenterY = imgMapFrameRect.anchoredPosition3D.y
	self._MaskFrameWidth = imgMapFrameRect.rect.width / 2
	self._MaskFrameHeight = imgMapFrameRect.rect.height / 2

	self._Templates =
	{
		["TeamPlayer"] = imgTeamTemplate,			-- 队伍玩家
		["OtherPlayer"] = imgPlayerTemplate,		-- 其他玩家
		["QuestNPC"] = imgQuestTemplate,			-- 任务Npc
		["ServiceNPC"] = imgServiceTemplate,		-- 服务Npc
		["Enemy"] = imgEnemyTemplate,				-- 普通怪
		["Boss"] = frameBossTemplate,				-- 精英或头目怪
		["HawkEye"] = imgHawkEyeTemplate			-- 鹰眼指示
	}
	self._PointPool =
	{
		["TeamPlayer"] = {},
		["OtherPlayer"] = {},
		["QuestNPC"] = {},
		["ServiceNPC"] = {},
		["Enemy"] = {},
		["Boss"] = {},
		["HawkEye"] = {}
	}
	self._TmpVector3 = Vector3.zero

	-- 第一次需要设置
	-- 天气图标
	GUITools.SetGroupImg(self._Img_Weather, CurrentWeather) -- CurrentWeather 在 EntryPoint
	-- 坐标
	local hpPosX, hpPosZ = game._HostPlayer:GetPosXZ()
	SetLabPosition(self, math.ceil(hpPosX), math.ceil(hpPosZ))
end

def.method("string").ParentOnClick = function (self, id)
	if id == "Mask_Map" then
		--3V3或1V1不能退出，给提示
		-- if game._HostPlayer:In3V3Fight() or game._HostPlayer:In1V1Fight() then
		-- 	game._GUIMan:ShowTipText(StringTable.Get(20004),false)
		-- 	return
		-- end
		game._GUIMan:Open("CPanelMap", nil)
	end
end

def.method().Show = function (self)
	self:Start()
end

def.method().Hide = function (self)
	self:EnableUISfx(false)
	if self._OnCombatStateChange ~= nil then
		CGame.EventManager:removeHandler(CombatStateChangeEvent, self._OnCombatStateChange)
		self._OnCombatStateChange = nil
	end
	self:Stop()
end

def.method().Destroy = function (self)
	self:Stop()

	self._Frame_HostPlayer = nil
	self._Rect_HostPlayer = nil
	self._Img_CameraSight = nil
	self._Img_Weather = nil
	self._Lab_MapName = nil
	self._Mask_Map = nil
	self._Frame_Map = nil
	self._Img_Map = nil
	self._Lab_Postion = nil
	self._Rect_Limit = nil
	self._Img_Pointing = nil
	self._Rect_Pointing = nil
	self._Frame_GuildConvoy = nil
	self._Rect_GuildConvoy = nil
	self._TweenMan_GuildConvoy = nil
	self._Img_TargetLocation = nil
	self._Rect_TargetLocation = nil
	self._TweenMan_TargetLocation = nil
	self._Img_HawkEye = nil
	self._Rect_HawkEye = nil

	self._Parent = {}
	self._Templates = {}
	self._PointPool = {}
	self._ImgTable_HawkEye = {}

	self._M_NPCMap = {}
	self._M_PlayerMap = {}
	self._M_HawkEyeMap = {}
	self._SceneTid = 0
end
-------------------------------------------------------------
def.method().Start = function(self)
	self:EnableUISfx(game._HostPlayer:IsInServerCombatState()) -- 更新特效状态
	-- 监听战斗状态
	self._OnCombatStateChange = function (sender,event)
		if event._CombatType == 1 then
			-- 服务器战斗状态更改
			self:EnableUISfx(event._IsInCombatState)
		end
	end

	CGame.EventManager:addHandler(CombatStateChangeEvent, self._OnCombatStateChange)

	-- Add Timer
	if self._M_TimerId == 0 then
		self._M_TimerId = game._HostPlayer:AddTimer(_G.minimap_update_time, false, function()
			self:UpdateMapInfo()
		end)
	end
end

def.method().Stop = function(self)
	if self._M_TimerId == 0 then return end
	game._HostPlayer:RemoveTimer(self._M_TimerId)
	self._M_TimerId = 0
end

def.method("boolean").EnableUISfx = function (self, enable)
	if enable then
		if self._IsPlayingFx then return end
		GameUtil.PlayUISfx(PATH.UIFX_MiniMapInCombatState, self._Mask_Map, self._Mask_Map, -1)
		self._IsPlayingFx = true
	else
		if not self._IsPlayingFx then return end
		GameUtil.StopUISfx(PATH.UIFX_MiniMapInCombatState, self._Mask_Map)
		self._IsPlayingFx = false
	end
end

def.method().UpdateMapInfo = function (self)
	if game._CurWorld == nil then return end
	self:CheckSceneChanged()

	self:UpdateWeather() -- 更新天气

	self._HostPlayerPosX, self._HostPlayerPosZ = game._HostPlayer:GetPosXZ() -- 无内存分配的getPosition
	self:UpdateHostPosDir()
	self:UpdatePosBoard()

	self:UpdateTargetInstruction() -- 更新寻路目标点和指示
	self:UpdateHawkEyePointing() -- 更新鹰眼指示
	self:UpdateGuildConvoyPos() -- 更新公会护送位置

	self:UpdateNpcImageMarks()
	self:UpdateNpcPosDir()

	self:UpdatePlayerImageMarks()
	self:UpdatePlayerPosDir()
end

def.method().CheckSceneChanged = function (self)
	local sceneId = game._CurWorld._WorldInfo.SceneTid
	if sceneId == self._SceneTid then return end
	--self._CurSceneTemplate = _G.MapBasicInfoTable[game._CurWorld._WorldInfo.SceneTid]
	self._CurSceneTemplate = MapBasicConfig.GetMapBasicConfigBySceneID(game._CurWorld._WorldInfo.SceneTid)
	if self._CurSceneTemplate == nil then
		warn("Scene template is nil in mini map, scene id:", sceneId)
		return
	end
	self._SceneTid = sceneId
	self._AllNpcMap = self._CurSceneTemplate.Npc

	self._MapOffset = {}
    local start, _ = string.find(self._CurSceneTemplate.NavMeshName, "%.")
    local navMeshName = string.sub(self._CurSceneTemplate.NavMeshName, 1, start - 1)
	local offset = MapBasicConfig.GetMapOffset() or {}
	if offset[navMeshName] ~= nil then
		-- 读出来是大地图的参数，重新校正
		self._MapOffset.A1 = offset[navMeshName].A1
		self._MapOffset.A2 = offset[navMeshName].A2
		self._MapOffset.width = offset[navMeshName].width
		self._MapOffset.height = offset[navMeshName].height
	end

	-- 当前步骤--设置地图
	GUITools.SetMap(self._Img_Map, self._CurSceneTemplate.MiniMapAtlasPath)
	-- local imgRect = self._Img_Map:GetComponent(ClassType.RectTransform)

	-- sizeDelta.x = self._CurSceneTemplate.Width * IMG_MAP_SCALE_X
	-- sizeDelta.y = self._CurSceneTemplate.Length * IMG_MAP_SCALE_Y
	-- imgRect.sizeDelta = sizeDelta

	-- 更新视野范围
	local map_template = game:GetCurMapTemp()
	if map_template ~= nil then
		self._SightRangeSqr = math.pow(map_template.SightRange, 2)
	end
end

def.method().UpdateWeather = function (self)
	if self._CurWeather ~= CurrentWeather then
		self._CurWeather = CurrentWeather
		GUITools.SetGroupImg(self._Img_Weather, CurrentWeather)
	end
end

def.method().UpdateHostPosDir = function (self)
	-- 图标位置
	local x = self._ImgHostCenterX + self._ImgHostOffsetX
	local y = self._ImgHostCenterY + self._ImgHostOffsetY
	self._TmpVector3.x = x
	self._TmpVector3.y = y
	self._TmpVector3.z = 0
	self._Rect_HostPlayer.anchoredPosition3D = self._TmpVector3

	-- 主角方向
	local dirX, dirZ = game._HostPlayer:GetDirXZ()
	local z = math.rad2Deg * math.atan2(dirZ, dirX) - 90
	self._Frame_HostPlayer.rotation = Quaternion.Euler(0, 0, z)

	-- 相机方向
	local camX, camZ = GameUtil.GetGameCamDirXZ()
	local cam_deg = math.rad2Deg * math.atan2(camZ, camX) - 90
	self._Img_CameraSight.rotation = Quaternion.Euler(0, 0, cam_deg)
end

def.method().UpdatePosBoard = function (self)
	--如果所在区域中，显示区域名字，否则显示map名字
	if self._CurSceneTemplate ~= nil then
		self._Lab_MapName.text = self:GetShowName(self._CurSceneTemplate)
	end

	local map_radius_z = 256
	local map_radius_x = 256

	if self._CurSceneTemplate == nil then
		if not IsNil(self._Frame_HostPlayer) and self._Frame_HostPlayer.activeSelf then
			self._Frame_HostPlayer:SetActive(false)
		end
	else
		if not IsNil(self._Frame_HostPlayer) and not self._Frame_HostPlayer.activeSelf then 
			self._Frame_HostPlayer:SetActive(true)
		end

		map_radius_x = self._ImgMapFrameWidth / 2
		map_radius_z = self._ImgMapFrameHeight / 2
	end

	--边界问题
	local xBorder = self._MaskFrameWidth
	local xLeftPos = -map_radius_x + xBorder -- 左

	local yBorder = self._MaskFrameHeight
	local yUpPos = -map_radius_z + yBorder -- 上

	-- 主角位置
	local xPosOnMap = self._HostPlayerPosX -- 在雷达图上的x
	local yPosOnMap = self._HostPlayerPosZ -- 在雷达图上的y
	if next(self._MapOffset) ~= nil then
		xPosOnMap = xPosOnMap * self._MapOffset.A1 + self._MapOffset.width
		yPosOnMap = yPosOnMap * self._MapOffset.A2 + self._MapOffset.height
	end

	if xPosOnMap < xLeftPos then
		self._ImgHostOffsetX = math.max(xPosOnMap - xLeftPos, -xBorder)
	elseif xPosOnMap > (-xLeftPos) then
		self._ImgHostOffsetX = math.min(xPosOnMap - (-xLeftPos), xBorder)
	else
		self._ImgHostOffsetX = 0
	end
	-- print("xPosOnMap:" .. xPosOnMap, "xLeftPos:" .. xLeftPos, "xBorder:" .. xBorder, "offsetX:" .. self._ImgHostOffsetX, "centerX:" .. self._ImgHostCenterX)

	if yPosOnMap < yUpPos then
		self._ImgHostOffsetY = math.max(yPosOnMap - yUpPos, -yBorder) 
	elseif yPosOnMap > (-yUpPos) then
		self._ImgHostOffsetY = math.min(yPosOnMap - (-yUpPos), yBorder)
	else
		self._ImgHostOffsetY = 0
	end
	-- print("yPosOnMap:" .. yPosOnMap, "yUpPos:" .. yUpPos, "yBorder:" .. yBorder, "offsetY:" .. self._ImgHostOffsetY, "centerY:" .. self._ImgHostCenterY)

	if self._CurSceneTemplate == nil then
		self._ImgHostOffsetX = 0
		self._ImgHostOffsetY = 0
	end

	local x = -self._HostPlayerPosX
	local y = -self._HostPlayerPosZ
	if next(self._MapOffset) ~= nil then
		x = x * self._MapOffset.A1 - self._MapOffset.width + self._ImgHostOffsetX
		y = y * self._MapOffset.A2 - self._MapOffset.height + self._ImgHostOffsetY
	else
		x = x * IMG_MAP_SCALE_X + self._ImgHostOffsetX
		y = y * IMG_MAP_SCALE_Y + self._ImgHostOffsetY
	end

	self._TmpVector3.x = x
	self._TmpVector3.y = y
	self._TmpVector3.z = 0
	self._Frame_Map.localPosition = self._TmpVector3

	local curHpPosX = math.ceil(self._HostPlayerPosX)
	local curHpPosZ = math.ceil(self._HostPlayerPosZ)
	if self._LastPosX ~= curHpPosX or self._LastPosZ ~= curHpPosZ then
		self._LastPosX = curHpPosX
		self._LastPosZ = curHpPosZ
		SetLabPosition(self, curHpPosX, curHpPosZ)
	end
end

-- 根据场景位置XZ，获取在雷达图坐标系中的坐标XY
local function GetAnchoredXY(self, x, z)
	local xPosOnMap = x -- 目标在地图上的位置x
	local yPosOnMap = z -- 目标在地图上的位置y
	local hpPosOnMapX = self._HostPlayerPosX -- 主角在雷达图的位置x
	local hpPosOnMapY = self._HostPlayerPosZ -- 主角在雷达图的位置y
	if next(self._MapOffset) ~= nil then
		-- 校正偏移量
		xPosOnMap = xPosOnMap * self._MapOffset.A1 + self._MapOffset.width
		yPosOnMap = yPosOnMap * self._MapOffset.A2 + self._MapOffset.height

		hpPosOnMapX = hpPosOnMapX * self._MapOffset.A1 + self._MapOffset.width
		hpPosOnMapY = hpPosOnMapY * self._MapOffset.A2 + self._MapOffset.height
	end
	local distanceX = xPosOnMap - hpPosOnMapX -- 目标点与主角的距离x
	local distanceY = yPosOnMap - hpPosOnMapY -- 目标点与主角的距离y
	local hpRealPosOnMapX = self._ImgHostCenterX + self._ImgHostOffsetX -- 主角在雷达图坐标系中的坐标x
	local hpRealPosOnMapY = self._ImgHostCenterY + self._ImgHostOffsetY -- 主角在雷达图坐标系中的坐标y
	local anchoredX = distanceX + hpRealPosOnMapX -- 目标点在雷达图坐标系中的坐标x
	local anchoredY = distanceY + hpRealPosOnMapY -- 目标点在雷达图坐标系中的坐标y

	-- print("distanceX:", distanceX, "distanceY:", distanceY)

	return anchoredX, anchoredY
end

-- 通过雷达图坐标系中的坐标XY，判断点是否在雷达图显示范围
local function IsPosInMiniMap(self, anchoredX, anchoredY)
	local xBorder = self._MaskFrameWidth
	local yBorder = self._MaskFrameHeight
	-- 雷达图为椭圆时
	-- 椭圆一般方程
	local ovalEquation = math.pow(anchoredX, 2) / math.pow(xBorder, 2) + math.pow(anchoredY, 2) / math.pow(yBorder, 2) - 1
	if ovalEquation > 0 then
		return false
	else
		return true
	end
end

-- 获取椭圆与直线的交点
-- 没有交点，返回 nil ；只有一个交点（相切），返回交点坐标；两个交点（相交），返回距离直线点1最近的交点坐标
-- @param ovalX 椭圆的X轴半径
-- @param ovalY 椭圆的Y轴半径
-- @param outX  直线点1的X坐标
-- @param outY  直线点1的Y坐标
-- @param inX   直线点2的X坐标
-- @param inY   直线点2的Y坐标
local function GetIntersectionPoint(ovalX, ovalY, outX, outY, inX, inY)
	local k = 0
	if outX ~= inX then
		k = (inY - outY) / (inX - outX)
	end
	local b = inY - k * inX

	local m, n = ovalX, ovalY

	local formula = math.pow(n, 2) + math.pow(k, 2) * math.pow(m, 2) - math.pow(b, 2)
	if formula < 0 then
		-- 没有交点
		warn("None Intersection Point, something goes wrong")
		return nil
	end

	local x1 = (-math.pow(m,2)*k*b + m*n*math.sqrt(math.pow(n,2) + math.pow(k,2)*math.pow(m,2) - math.pow(b,2)))
				/ (math.pow(n,2) + math.pow(m,2)*math.pow(k,2))
	local y1 = k * x1 + b

	if formula == 0 then
		-- 相切
		-- print(string.format("formula is zero, point:(%s, %s)", x1, y1))
		return Vector2.New(x1, y1)
	elseif formula > 0 then
		-- 两个交点
		local x2 = (-math.pow(m,2)*k*b - m*n*math.sqrt(math.pow(n,2) + math.pow(k,2)*math.pow(m,2) - math.pow(b,2)))
					/ (math.pow(n,2) + math.pow(m,2)*math.pow(k,2))
		local y2 = k * x2 + b

		local s1 = math.pow(x1 - outX, 2) + math.pow(y1 - outY, 2)
		local s2 = math.pow(x2 - outX, 2) + math.pow(y2 - outY, 2)

		-- print("s1:" .. s1, ", s2:" .. s2)
		-- print(string.format("formula over then zero, point1:(%s, %s), point2:(%s, %s)", x1, y1, x2, y2))
		-- 返回最接近圆外点的点
		if s1 < s2 then
			return Vector2.New(x1, y1)
		else
			return Vector2.New(x2, y2)
		end
	end
end

-- 更新目标地点和指示
def.method().UpdateTargetInstruction = function (self)
	local tweenId = "Location"
	local targetPos = CPath.Instance():GetCurTargetPos()
	if targetPos == nil or next(targetPos) == nil then
		GUITools.SetUIActive(self._Img_Pointing, false)
		if self._Img_TargetLocation.activeSelf then
			self._Img_TargetLocation:SetActive(false)
			self._TweenMan_TargetLocation:Stop(tweenId)
		end
		return
	end

	local anchoredX, anchoredY = GetAnchoredXY(self, targetPos.x, targetPos.z)
	local isTargetPosOnMap = IsPosInMiniMap(self, anchoredX, anchoredY)

	GUITools.SetUIActive(self._Img_Pointing, not isTargetPosOnMap)
	if self._Img_TargetLocation.activeSelf == not isTargetPosOnMap then
		self._Img_TargetLocation:SetActive(isTargetPosOnMap)
		if isTargetPosOnMap then
			self._TweenMan_TargetLocation:Restart(tweenId)
		else
			self._TweenMan_TargetLocation:Stop(tweenId)
		end
	end

	if not isTargetPosOnMap then
		-- 目标点在雷达图范围外，显示指示
		local hpRealPosOnMapX = self._ImgHostCenterX + self._ImgHostOffsetX
		local hpRealPosOnMapY = self._ImgHostCenterY + self._ImgHostOffsetY
		local xBorder = self._MaskFrameWidth
		local yBorder = self._MaskFrameHeight

		-- print("xBorder:", xBorder, "yBorder:", yBorder)

		-- 指示位置
		local point = GetIntersectionPoint(xBorder, yBorder, anchoredX, anchoredY, hpRealPosOnMapX, hpRealPosOnMapY)
		if point ~= nil then
			self._TmpVector3.x = point.x
			self._TmpVector3.y = point.y
			self._TmpVector3.z = 0
			self._Rect_Pointing.anchoredPosition3D = self._TmpVector3
		end

		-- 指示方向
		local deg = math.rad2Deg * math.atan2(anchoredX, anchoredY)
		self._Img_Pointing.rotation = Quaternion.Euler(0, 0, 360 - deg)
	else
		-- 目标点在雷达图范围内，显示目标点
		self._TmpVector3.x = anchoredX
		self._TmpVector3.y = anchoredY
		self._TmpVector3.z = 0
		self._Rect_TargetLocation.anchoredPosition3D = self._TmpVector3
	end
end

local function AddImageMarkHawkEye(self, regionId, hawkEyeType)
	local obj = self:GetPointByPool("HawkEye")
	if IsNil(obj) then return end

	GUITools.SetGroupImg(obj, hawkEyeType - 1)
	local map =
	{
		Obj = obj,
		RectTrans = obj:GetComponent(ClassType.RectTransform)
	}
	-- map.RectTrans.pivot = Vector2.New(0.5, 1)
	self._M_HawkEyeMap[regionId] = map
end

-- 更新鹰眼指示
def.method().UpdateHawkEyePointing = function (self)
	local hawkEyePosTable = game._HostPlayer._TableHawkEyeTargetPos
	local bShowMapHawkEye = false -- 是否显示小地图范围内的鹰眼
	local allHawkEyes = {} -- 当前的鹰眼指示
	local isHideAll = false
	if hawkEyePosTable ~= nil and next(hawkEyePosTable) ~= nil then
		for regionId, v in pairs(hawkEyePosTable) do
			-- print("regionId:", regionId, " status:", v.status, " type:", v.type, " pos:", v.pos)
			--[[
			v.status 鹰眼状态 0:关闭 1:处于触发范围 2:处于更亮点范围 3:处于进入点范围
			v.pos 鹰眼进入点位置
			v.type 0:任务神视 1:单人神视 2:多人神视
			--]]
			if v.status == 1 then
				local anchoredX, anchoredY = GetAnchoredXY(self, v.pos.x, v.pos.z)
				local hpRealPosOnMapX = self._ImgHostCenterX + self._ImgHostOffsetX
				local hpRealPosOnMapY = self._ImgHostCenterY + self._ImgHostOffsetY
				local xBorder = self._MaskFrameWidth
				local yBorder = self._MaskFrameHeight

				-- 在目标方向适当延长距离，确保在小地图范围外
				local dir = Vector2.New(anchoredX, anchoredY) - Vector2.New(hpRealPosOnMapX, hpRealPosOnMapY)
				dir:SetNormalize()
				dir = dir * self._MaskFrameWidth * 2

				local point = GetIntersectionPoint(xBorder, yBorder, dir.x, dir.y, hpRealPosOnMapX, hpRealPosOnMapY)
				if point ~= nil then
					allHawkEyes[regionId] = true

					local map = self._M_HawkEyeMap[regionId]
					if map == nil then
						AddImageMarkHawkEye(self, regionId, v.hawkeyeType)
						map = self._M_HawkEyeMap[regionId]
					end

					self._TmpVector3.x = point.x
					self._TmpVector3.y = point.y
					self._TmpVector3.z = 0
					-- 指示位置
					map.RectTrans.anchoredPosition3D = self._TmpVector3
					-- 指示方向
					-- local deg = math.rad2Deg * math.atan2(anchoredX, anchoredY)
					-- map.Obj.rotation = Quaternion.Euler(0, 0, 360 - deg)
				end
			elseif v.status == 2 then
				-- 只会有一个神视处于小地图范围内
				GUITools.SetGroupImg(self._Img_HawkEye, v.hawkeyeType-1)
				local anchoredX, anchoredY = GetAnchoredXY(self, v.pos.x, v.pos.z)
				self._TmpVector3.x = anchoredX
				self._TmpVector3.y = anchoredY
				self._TmpVector3.z = 0
				self._Rect_HawkEye.anchoredPosition3D = self._TmpVector3
				bShowMapHawkEye = true
			elseif v.status == 3 then
				-- 只要有一个点可以进入，隐藏小地图所有鹰眼相关图标
				isHideAll = true
				bShowMapHawkEye = false
				break
			end
		end
	end

	-- 回收多余的图标
	for regionId, map in pairs(self._M_HawkEyeMap) do
		if isHideAll or allHawkEyes[regionId] == nil then
			self:RecyclingPoint(map.Obj, "HawkEye")
			self._M_HawkEyeMap[regionId] = nil
		end
	end
	GUITools.SetUIActive(self._Img_HawkEye, bShowMapHawkEye)
end

-- 更新公会护送点
def.method().UpdateGuildConvoyPos = function (self)
	local tweenId = "GuildConvoy"
	local convoyPos = game._GuildMan:GetConvoyEntityPos()
	if convoyPos == nil then
		self._Frame_GuildConvoy:SetActive(false)
		self._TweenMan_GuildConvoy:Stop(tweenId)
	else
		local anchoredX, anchoredY = GetAnchoredXY(self, convoyPos.x, convoyPos.z)
		local isOnMap = IsPosInMiniMap(self, anchoredX, anchoredY)
		if self._Frame_GuildConvoy.activeSelf ~= isOnMap then
			self._Frame_GuildConvoy:SetActive(isOnMap)
			if isOnMap then
				self._TweenMan_GuildConvoy:Restart(tweenId)
			else
				self._TweenMan_GuildConvoy:Stop(tweenId)
			end
		end
		if isOnMap then
			self._TmpVector3.x = anchoredX
			self._TmpVector3.y = anchoredY
			self._TmpVector3.z = 0
			self._Rect_GuildConvoy.anchoredPosition3D = self._TmpVector3
		end
	end
end

-- 检查点的边界情况
def.method("table").CheckPosBorder = function (self, targetPos)
	if targetPos == nil then return end
	local anchoredX, anchoredY = GetAnchoredXY(self, targetPos.x, targetPos.z)
	-- print("anchoredX:", anchoredX, "anchoredY:", anchoredY)

	-- 雷达图为椭圆时
	local isTargetPosOnMap = IsPosInMiniMap(self, anchoredX, anchoredY)
	if not isTargetPosOnMap then
		-- 目标点在雷达图范围外，显示指示
		-- 指示位置
		local hpRealPosOnMapX = self._ImgHostCenterX + self._ImgHostOffsetX
		local hpRealPosOnMapY = self._ImgHostCenterY + self._ImgHostOffsetY
		local xBorder = self._MaskFrameWidth
		local yBorder = self._MaskFrameHeight

		-- print("xBorder:", xBorder, "yBorder:", yBorder)

		local point = GetIntersectionPoint(xBorder, yBorder, anchoredX, anchoredY, hpRealPosOnMapX, hpRealPosOnMapY)
		self._TmpVector3.x = point.x
		self._TmpVector3.y = point.y
		self._TmpVector3.z = 0
	--[[
	-- 雷达图为矩形时
	if math.abs(anchoredX) > xBorder or math.abs(anchoredY) > yBorder then
		-- 目标点在雷达图范围外，显示指示
		-- 指示位置
		local offsetX = anchoredX -- 相对中心的偏移量x
		local offsetY = anchoredY -- 相对中心的偏移量y
		if anchoredX == 0 then
			offsetX = 0
			offsetY = yBorder
			if anchoredY < 0 then
				offsetY = -yBorder
			end
		elseif anchoredY == 0 then
			offsetX = xBorder
			offsetY = 0
			if anchoredX < 0 then
				offsetX = -xBorder
			end
		else
			local anchoredRate = anchoredX / anchoredY
			local mapRate = xBorder / yBorder
			if math.abs(anchoredRate) > mapRate then
				-- 右边界
				offsetX = xBorder
				offsetY = math.abs(xBorder / anchoredRate)

				-- 左边界
				if anchoredX < 0 then
					offsetX = -offsetX
				end
				if anchoredY < 0 then
					offsetY = -offsetY
				end
			elseif math.abs(1 / anchoredRate) > 1 / mapRate then
				-- 上边界
				offsetX = math.abs(anchoredRate * yBorder)
				offsetY = yBorder

				-- 下边界
				if anchoredX < 0 then
					offsetX = -offsetX
				end
				if anchoredY < 0 then
					offsetY = -offsetY
				end
			end
		end

		-- print("offsetX:", offsetX, "offsetY:", offsetY)

		self._TmpVector3.x = self._ImgHostCenterX + offsetX
		self._TmpVector3.y = self._ImgHostCenterY + offsetY
		self._TmpVector3.z = 0
	--]]

		-- 指示方向
		local deg = math.rad2Deg * math.atan2(anchoredX, anchoredY)
		self._Img_Pointing.rotation = Quaternion.Euler(0, 0, 360 - deg)
	else
		-- 目标点在雷达图范围内，显示目标点
		self._TmpVector3.x = anchoredX
		self._TmpVector3.y = anchoredY
		self._TmpVector3.z = 0
	end
	-- return isTargetPosOnMap, self._TmpVector3
end

def.method("table" ,"=>", "string").GetShowName = function(self, map)
	local regionIds = game._HostPlayer._CurrentRegionIds
	local regionCount = #regionIds
	local showName = map.TextDisplayName
	local regions = map.Region

	--倒叙查找最后一个进入的有名字的区域
	for i = 1, regionCount do
		for j, w in ipairs(regions) do
			for k, x in pairs(w) do
				if k == regionIds[regionCount-i+1] then
					--warn("regionId = ", w.Id, "Show? = ", w.ShowName, "TextDisplayName = ", w.TextDisplayName)
					if x.isShowName ~= nil and x.isShowName and x.name ~= ""  then
						return x.name
					end
				end
			end
		end
	end
	return showName
end

local function GetNPCMap(obj, pointType, tag)
	return 
	{
		Obj = obj,
		RectTrans = obj:GetComponent(ClassType.RectTransform),
		PointType = pointType,
		Tag = tag,
	}
end

local function AddImageMarkNPC(self, npc, isMonster, iconIndexOrName)
    if self._M_NPCMap[npc._ID] ~= nil then return end
    local map = nil
    if isMonster then
        -- 怪物
        local npcQuality = npc:GetMonsterQuality()
        if npcQuality == EMonsterQuality.LEADER or npcQuality == EMonsterQuality.BEHEMOTH or npcQuality == EMonsterQuality.ELITE_BOSS then
            -- 头目或巨兽或精英Boss
            local obj = self:GetPointByPool("Boss")
            if IsNil(obj) then return end
            local img_boss = GUITools.GetChild(obj, 2)
            if not IsNil(img_boss) then
                local img_index = npcQuality == EMonsterQuality.ELITE_BOSS and 1 or 0
                GUITools.SetGroupImg(img_boss, img_index)
            end
            -- 动特效
            local tween_man = obj:GetComponent(ClassType.DOTweenPlayer)
            tween_man:Restart("Boss")

            map = GetNPCMap(obj, "Boss", "Monster")
        else
            local obj = self:GetPointByPool("Enemy")
            if IsNil(obj) then return end
            map = GetNPCMap(obj, "Enemy", "Monster")
        end
    else
        -- NPC
        if type(iconIndexOrName) == "number" then
            -- 任务NPC
            local obj = self:GetPointByPool("QuestNPC")
            if IsNil(obj) then return end
            GUITools.SetGroupImg(obj, iconIndexOrName)
            map = GetNPCMap(obj, "QuestNPC", iconIndexOrName)
        elseif type(iconIndexOrName) == "string" then
            -- 服务NPC
            local obj = self:GetPointByPool("ServiceNPC")
            if IsNil(obj) then return end
            GUITools.SetGroupImg(obj, iconIndexOrName)
            map = GetNPCMap(obj, "ServiceNPC", iconIndexOrName)
        else
        	return
        end
    end
    self._M_NPCMap[npc._ID] = map
end

local function RemoveImageMarkNPC(self, id)
    local map = self._M_NPCMap[id]
    if map == nil then return end
    self:RecyclingPoint(map.Obj, map.PointType)
    self._M_NPCMap[id] = nil
end

def.method().UpdateNpcImageMarks = function (self)
	local npcObjMap = game._CurWorld._NPCMan._ActiveNpcList

	for _, v in pairs(npcObjMap) do
		local bInRange = false
		
		local vPosX, vPosZ = v:GetPosXZ()
		local distanceSqr = SqrDistanceH(self._HostPlayerPosX, self._HostPlayerPosZ, vPosX, vPosZ)

		if self._SightRangeSqr <= 0 or distanceSqr < self._SightRangeSqr then
			local npcType = v:GetObjectType()

			bInRange = true
			if npcType == OBJ_TYPE.MONSTER then
				AddImageMarkNPC(self, v, true, false)
			elseif npcType == OBJ_TYPE.NPC then
				local map = self._M_NPCMap[v._ID]
				local bRemoveIcon = true
				local iconIndexOrName = nil
				-- 先检查NPC是否有任务
				local firstQuest = v:GetFirstQuestInfo()
				if firstQuest ~= nil then
					local NPCTaskIconIndex = -1
					if firstQuest[2] == QuestFuncDef.GoingOn then
						-- 进行中
						NPCTaskIconIndex = 0
					elseif firstQuest[3] == QuestTypeDef.Main then
						-- 主线，红色图标
						NPCTaskIconIndex = 0 + firstQuest[2]
					elseif firstQuest[3] == QuestTypeDef.Branch then
						-- 支线，黄色图标
						NPCTaskIconIndex = 2 + firstQuest[2]
					elseif firstQuest[3] == QuestTypeDef.Reputation or
						   firstQuest[3] == QuestTypeDef.Reward or
						   firstQuest[3] == QuestTypeDef.Activity or
						   firstQuest[3] == QuestTypeDef.Sweep then
						-- 声望、赏金、活动（活动即公会）、扫荡，绿色图标
						NPCTaskIconIndex = 4 + firstQuest[2]
					else
						-- 其他类型，蓝色图标
						NPCTaskIconIndex = 6 + firstQuest[2]
					end
					-- print("firstQuest:", firstQuest[1].."_"..firstQuest[2].."_"..firstQuest[3], "Icon index:", NPCTaskIconIndex)

					if map == nil or (map.PointType == "QuestNPC" and map.Tag == NPCTaskIconIndex) then
						bRemoveIcon = false
					end
					iconIndexOrName = NPCTaskIconIndex
				else
					local hasQuestRandGroupServer = QuestUtil.HasQuestRandGroupServer(v._NpcTemplate)
					if hasQuestRandGroupServer then
						-- 有随机任务组的服务
						local NPCTaskIconIndex = 6 -- 必定显示赏金任务的可领取图标
						if map == nil or (map.PointType == "QuestNPC" and map.Tag == NPCTaskIconIndex) then
							bRemoveIcon = false
						end
						iconIndexOrName = NPCTaskIconIndex
					end
				end
				-- 若没有任务，或随机任务的服务，继续检查NPC是否有其他服务
				if iconIndexOrName == nil then
					local iconName = ""
					if self._AllNpcMap ~= nil and self._AllNpcMap[v._NpcTemplate.Id] then
						if self._AllNpcMap[v._NpcTemplate.Id][1].MapIcon ~= nil then
							iconName = self._AllNpcMap[v._NpcTemplate.Id][1].MapIcon
						end
						if iconName ~= "" and iconName ~= " " then
							iconIndexOrName = iconName
						end
					end

					if map == nil or (map.PointType == "ServiceNPC" and map.Tag == iconIndexOrName) then
						bRemoveIcon = false
					end
				end

				if bRemoveIcon then
					RemoveImageMarkNPC(self, v._ID)
				end
				if iconIndexOrName ~= nil then
					AddImageMarkNPC(self, v, false, iconIndexOrName)
				end
			end
		end
		
		if not bInRange then
			RemoveImageMarkNPC(self, v._ID)
		end
	end

	--当npc消失时
	for k, v in pairs(self._M_NPCMap) do
		if npcObjMap[k] == nil then
			self:RecyclingPoint(v.Obj, v.PointType)
			self._M_NPCMap[k] = nil
		end
	end
end

local function SetImageMarkPos(self, vPosX, vPosZ, img_rect)
	if img_rect == nil then return end

	local anchoredX, anchoredY = GetAnchoredXY(self, vPosX, vPosZ)
	self._TmpVector3.x = anchoredX
	self._TmpVector3.y = anchoredY
	self._TmpVector3.z = 0
	img_rect.anchoredPosition3D = self._TmpVector3
end

def.method().UpdateNpcPosDir = function (self)
	local npcObjMap = game._CurWorld._NPCMan._ActiveNpcList
	for k, v in pairs(self._M_NPCMap) do
		local x, z = npcObjMap[k]:GetPosXZ()
		SetImageMarkPos(self, x, z, v.RectTrans)
	end
end

local function AddImageMarkPlayer(self, id, is_team_member, img_index, tag)
	local pointType = ""
	if is_team_member then
		pointType = "TeamPlayer"
	else
		pointType = "OtherPlayer"
	end
	local obj = self:GetPointByPool(pointType)
	if IsNil(obj) then return end
	GUITools.SetGroupImg(obj, img_index)
	local map =
	{
		Obj = obj,
		RectTrans = obj:GetComponent(ClassType.RectTransform),
		PointType = pointType,
		Tag = tag,
	}
	self._M_PlayerMap[id] = map
end

local function RemoveImageMarkPlayer(self, id)
	local map = self._M_PlayerMap[id]
	if map == nil then return end
	self:RecyclingPoint(map.Obj, map.PointType)
	self._M_PlayerMap[id] = nil
end

def.method().UpdatePlayerImageMarks = function (self)
	local playerObjMap = game._CurWorld._PlayerMan._ActivePlayerList

	for _,v in pairs(playerObjMap) do
		local vPosX, vPosZ = v:GetPosXZ()
		local distanceSqr = SqrDistanceH(self._HostPlayerPosX, self._HostPlayerPosZ, vPosX, vPosZ)

		if self._SightRangeSqr <= 0 or distanceSqr < self._SightRangeSqr then
			local teamMan = CTeamMan.Instance()
			local id = v._ID
			local map = self._M_PlayerMap[id]
			-- warn("player id:", id, " relation:", v:GetRelationWithHost(), " isTeamMember: ", teamMan ~= nil and teamMan:IsTeamMember(id) or "false", " map info: ", map ~= nil and map.Tag or "nil")
			if teamMan ~= nil and teamMan:IsTeamMember(id) then
				-- 队友
				if map == nil then
					AddImageMarkPlayer(self, id, true, self._IsTeamLeader2Index[teamMan:IsTeamLeaderById(id)], "Team")
				elseif map.Tag ~= "Team" then
					-- 从非队友转变为队友
					RemoveImageMarkPlayer(self, id)
					AddImageMarkPlayer(self, id, true, self._IsTeamLeader2Index[teamMan:IsTeamLeaderById(id)], "Team")
				end
			else
				-- 非队友
				local relation = v:GetRelationWithHost()
				if map == nil then
					AddImageMarkPlayer(self, id, false, self._ERelation2Index[relation], relation)
				elseif map.Tag ~= relation then
					-- 阵营改变
					RemoveImageMarkPlayer(self, id)
					AddImageMarkPlayer(self, id, false, self._ERelation2Index[relation], relation)
				end
			end
		end
	end

	--当player消失时
	for k,v in pairs(self._M_PlayerMap) do
		if playerObjMap[k] == nil then
			self:RecyclingPoint(v.Obj, v.PointType)
			self._M_PlayerMap[k] = nil
		end
	end
end

def.method().UpdatePlayerPosDir = function (self)
	local playerObjMap = game._CurWorld._PlayerMan._ActivePlayerList

	for k,v in pairs(self._M_PlayerMap) do
		local player = playerObjMap[k]
		local x, z = player:GetPosXZ()
		SetImageMarkPos(self, x, z, v.RectTrans)
	end
end

-- 根据模版设置对象
local function GetObjByTemplate(template)
	if IsNil(template) then return nil end
	local obj = GameObject.Instantiate(template)
	obj:SetParent(template.parent)
	obj.localPosition = template.localPosition
	obj.localScale = template.localScale
	obj.localRotation = template.localRotation
	return obj
end

-- 获取各种点
def.method("string", "=>", "userdata").GetPointByPool = function (self, poolType)
	local pool = self._PointPool[poolType]
	if pool == nil then return nil end
	local obj = nil
	if #pool < 1 then
		local template = self._Templates[poolType]
		if IsNil(template) then return nil end
		obj = GetObjByTemplate(template)
	else
		obj = pool[#pool]
		pool[#pool] = nil
	end
	if not IsNil(obj) and obj.activeSelf ~= true then
		obj:SetActive(true)
	end
	return obj
end

-- 回收各种点
def.method("userdata", "string").RecyclingPoint = function (self, obj, poolType)
	if IsNil(obj) then return end
	local pool = self._PointPool[poolType]
	if pool == nil then
		obj:Destroy()
		return
	end
	if #pool < POOL_NUM then
		pool[#pool+1] = obj
		if obj.activeSelf ~= false then
			obj:SetActive(false)
		end
		if poolType == "Boss" then
			local tween_man = obj:GetComponent(ClassType.DOTweenPlayer)
			tween_man:Stop("Boss")
		end
	else
		obj:Destroy()
	end
end

CPageMiniMap.Commit()
return CPageMiniMap