-- [[-----------------------------------------
--     世界地图
--        ——by luee. 2016.10.20
--  --------------------------------------------
-- ]]
local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CQuest = require "Quest.CQuest"
local QuestDef = require "Quest.QuestDef"
local EWorldType = require "PB.Template".Map.EWorldType
local MapBasicConfig = require "Data.MapBasicConfig"
local CTransManage = require "Main.CTransManage"
local QuestFuncDef = require "Quest.QuestDef".QuestFunc
local QuestTypeDef = require "Quest.QuestDef".QuestType
local CTeamMan = require "Team.CTeamMan"
local CDungeonAutoMan = require"Dungeon.CDungeonAutoMan"
local CombatStateChangeEvent = require"Events.CombatStateChangeEvent"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CTransDataHandler = require "Transfer.CTransDataHandler"
local PBHelper = require "Network.PBHelper"
local ContinueTransEvent = require"Events.ContinueTransEvent"

local CPanelMap = Lplus.Extend(CPanelBase, "CPanelMap")
local def = CPanelMap.define

--地图展示内容
def.field('userdata')._Frame_WorldMap = nil
def.field('userdata')._Frame_Map = nil
def.field('userdata')._Host_Player = nil
def.field('userdata')._Obj_World_Player_Head = nil
def.field('userdata')._Obj_World_Player_Host = nil
def.field('userdata')._Img_Map = nil
def.field('userdata')._Obj_Map = nil
def.field('userdata')._Obj_WorldMap = nil
def.field('userdata')._Obj_BOSS = nil
def.field('userdata')._Obj_Npc = nil
def.field('userdata')._Obj_Transfer = nil
def.field('userdata')._Obj_EyeRegion = nil
def.field('userdata')._Obj_Region_Name = nil
def.field('userdata')._Obj_AutoPos = nil
def.field('userdata')._Obj_AutoPosFinal = nil
def.field('userdata')._Obj_Dungeon = nil
def.field('userdata')._Obj_TeamMem = nil
def.field('userdata')._Obj_Paths = nil
def.field('userdata')._Obj_RegionGroup = nil
def.field('userdata')._Btn_TransIcon = nil  --传送阵按钮
def.field('userdata')._ObjMenu = nil --menu
def.field("userdata")._ImgTransfer = nil 
def.field("userdata")._NpcIconList = nil 
def.field("userdata")._MonsterIconList = nil 
def.field("userdata")._EyeSingleList = nil 
def.field("userdata")._EyeMultiplayerList = nil 

--逻辑属性
def.field("number")._Page = 0--打开的页签，0=区域地图 1= 世界地图
def.field("number")._PlayerPos_TimerID = 0
def.field("number")._AutoPath_TimerID = 0
def.field("number")._CurMapID = 0 --当前打开地图的ID
def.field("number")._TransID =0   --传送模板ID

def.field("table")._TransDataTable = nil --传送数据
def.field("table")._Last_PlayerPos = nil --玩家最后保存的坐标
def.field('boolean')._IsUpdateMap = false
def.field("userdata")._FrameList = nil 

--数据分为全组和可见群组ListType，前者做地图显示，后者做list显示！！！！！
def.field("table")._ListType = nil--节点需要的数据
def.field("table")._Table_AllMonsters = nil
def.field("table")._Table_AllNpc = nil
def.field("table")._Table_AllRegion = nil
def.field("table")._Table_AllEyeDungeonEntrance = nil
def.field("table")._ReputationNPCData = nil 
local Table_Paths_Points = {} -- 计算寻路路径点的位置 不可为私有
def.field("table")._NodeName = nil--主节点名称
-- 不可更改
local Table_NpcObj = {} --所有NPC的图标
local Table_RegionImgObj = {} --所有区域图标
local Table_RegionNameObj = {}--所有区域的名字
local Table_BossImgObj = {} --所有BOSS的头像
local Table_ReputationImgObj = {} -- 所有声望
local Table_EyeDungeonEntranceImgObj = {} --鹰眼副本入口
def.field("table")._TeamMemberTable = nil --队伍成员


local PointerClickTargetPos = nil --点击地图的时候需要寻路的点
--刷新标示，只有打开地图刷新一次，不要频繁调用数据
def.field("boolean")._IsInitMap = false
def.field("boolean")._IsInitWorld = false
def.field("table")._MapInfo = nil
def.field("table")._CurrentSelectNodeItem = nil--当前选择的node
def.field("number")._MapWidth = 0 -- 地图width
def.field("number")._MapHeight = 0 --地图height

local IsShowCurMapPath = false --非玩家所在地图寻路路径显示
local Table_Path_Obj = {} --寻路点-- 必须是局部变量
def.field("boolean")._IsCheckRegionMap = false --是否查看了区域地图
def.field("number")._HostPlayerMapID = 0--玩家所在地图
def.field("boolean")._IsAutoPath = false
def.field("table")._TeamList = nil 
def.field("number")._CurrentSelectTabIndex = 0 
def.field("boolean")._IsTabOpen = false

def.field("userdata")._BeforeLocationObj = nil 

def.field("number")._CurMapType = 0
def.field("userdata")._CurSelectNodeObj = nil
def.field("table")._CurSelectNodeData = nil 
def.field("table")._MonsterNodeObjs = BlankTable
def.field("table")._NpcNodeObjs = BlankTable
def.field("userdata")._Lab_EyeRegionCount = nil
def.field("userdata")._Btn_EyeRegionCount = nil
def.field("userdata")._FrameTip = nil 
def.field("userdata")._BtnToggle = nil 
def.field("userdata")._BtnReputation = nil 
def.field("number")._CurNpcNodeIndex = 0



local MapType = 
{
	REGION = 0,
	WORLD = 1,
	REPUTATION = 2,

}

local NodeType =
{
	NPC = 1,
	MONSTER = 2,
	REGIONPOINT = 3,    -- 地图间的区域连接点
	TRANSLATEBTN = 4,    -- 传送阵
	ELSE = 5,
}

-- 神世类型
local EyeType = 
{
	Single = 1,
	Multiplayer = 2,
}

def.const("table").MapType = MapType

local instance = nil


def.static('=>', CPanelMap).Instance = function()
	-- body
	if not instance then
		instance = CPanelMap()
        instance._PrefabPath = PATH.UI_Map
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        
        instance:SetupSortingParam()
	end
	return instance
end

local function OnContinueTransEvent(sender,event)
	if instance ~= nil and instance:IsShow() then
		if event._MapID == instance._CurMapID then 
			instance: StopUpdateAutoPathing()
    		game._HostPlayer:SetAutoPathFlag(true)
    		instance._IsAutoPath = true
			local V3pos = Vector3.New(event._TargetPos.x,event._TargetPos.y,event._TargetPos.z)
     		game._HostPlayer._NavTargetPos = V3pos
     		instance:SetAutoPathTable(V3pos,true)
     		instance:OnlyShowAutoPathing(true)
		end
    end
end

def.override().OnCreate = function(self)
	-- body

	--self._MapInfo = MapBasicConfig.Get()

	self._Frame_WorldMap = self:GetUIObject("Frame_WorldMap")
   	self._Frame_Map = self:GetUIObject("Frame_Map")
    self._Host_Player = self:GetUIObject("Img_My")
    self._Obj_Map = self:GetUIObject("Icon")
    -- self._Obj_WorldMap = self._Panel:FindChild("Frame_WorldMap/Img_WorldMap")
    self._Obj_World_Player_Head = self:GetUIObject("Img_MyHead")
    -- self._Obj_World_Player_Host = self:GetUIObject("Img_Arrow")
    self._Obj_Dungeon = self:GetUIObject("Img_Copy")
    self._Obj_AutoPos = self:GetUIObject("Img_Point")
    self._Obj_AutoPosFinal = self:GetUIObject("Img_PointLast")
    self._Obj_Paths = self:GetUIObject("PathObj")
 	self._Obj_RegionGroup = self:GetUIObject("Region")
 	self._EyeSingleList = self:GetUIObject("EyeSingle")
 	self._EyeMultiplayerList = self:GetUIObject("EyeMultiplayer")
 	self._Img_Map = self:GetUIObject("Img_Map")
 	self._NpcIconList = self:GetUIObject("NpcIcon")
 	self._MonsterIconList = self:GetUIObject("MonsterIcon")
 	if self._Img_Map ~= nil then
 		local rectMap = self._Img_Map:GetComponent(ClassType.RectTransform)
 		if rectMap ~= nil then
 			self._MapWidth = rectMap.rect.width
 			self._MapHeight = rectMap.rect.height 			
 		end 		
 	end

    self._Obj_TeamMem = self:GetUIObject("Img_Team")
    self._Obj_TeamMem: SetActive(false)

 	self._Obj_BOSS = self:GetUIObject("Btn_BOSS")
    self._Obj_BOSS: SetActive(false)

    self._Obj_Npc = self:GetUIObject("Img_NPC")
    self._Obj_Npc: SetActive(false)

    self._Obj_Region_Name = self:GetUIObject("Label_RegionName")
    self._Obj_Region_Name: SetActive(false)

    self._Obj_Transfer = self:GetUIObject("Img_Transfer")
    self._Obj_Transfer: SetActive(false)

    self._Obj_EyeRegion = self:GetUIObject("Btn_EyeEntrance")
    self._Obj_EyeRegion: SetActive(false)

    self._Lab_EyeRegionCount = self:GetUIObject("Lab_EyeRegionCount")
    self._Lab_EyeRegionCount: SetActive(false)

    self._Btn_EyeRegionCount = self:GetUIObject("Btn_EyeRegionCount")
    self._Btn_EyeRegionCount: SetActive(false)

    self._FrameTip = self:GetUIObject("Frame_Tip")
    self._BtnToggle = self:GetUIObject("Btn_Toggle")
    

    self._Btn_TransIcon = self:GetUIObject("Btn_TransIcon")
    self._Btn_TransIcon: SetActive(false)

    self._BtnReputation = self:GetUIObject("Btn_Reputation")
    self._BtnReputation:SetActive(false)
    
 	self._FrameList = self:GetUIObject("Frame_List")  
 	self._TransDataTable = {}
	local allTransData = GameUtil.GetAllTid("Trans")
	for _,v in pairs(allTransData) do
		local transData = CElementData.GetTemplate("Trans", v)    
		self._TransDataTable[#self._TransDataTable + 1] = transData
	end
end

local SetPageToggle = function(panelScript,isRegionMap)
	local Lab_World = panelScript:GetUIObject("Lab_World")
	local Lab_Region = panelScript:GetUIObject("Lab_Region")
	if not isRegionMap then 
		panelScript._CurMapType = MapType.WORLD
	else
		panelScript._CurMapType = MapType.REGION
	end
	Lab_Region:SetActive(not isRegionMap)
	Lab_World:SetActive(isRegionMap)
end

-- -- 战斗状态下清除路径线()
-- local function OnCombatStateChangeEvent(sender,event)
-- 	if instance ~= nil then
-- 		if event._IsInCombatState and event._CombatType == 0 then 
-- 			instance:StopUpdateAutoPathing()
-- 			instance._IsAutoPath = false
-- 			game._HostPlayer:SetAutoPathFlag(false)
-- 		end
-- 	end
-- end

def.override("dynamic").OnData = function(self, data)

	-- CGame.EventManager:addHandler(CombatStateChangeEvent, OnCombatStateChangeEvent)

	-- Table_NpcObj = {}
	-- Table_RegionImgObj = {}
	-- Table_RegionNameObj = {}
	-- Table_BossImgObj = {}
	self._IsInitMap = false
	self._IsInitWorld = false 
	self._HostPlayerMapID = game._CurWorld._WorldInfo.SceneTid
	self._CurSelectNodeObj = nil
	self._Last_PlayerPos = nil 
	self._CurNpcNodeIndex = 0
	if data ~= nil then	
		if data._type == MapType.REGION then --区域地图
			self._CurMapID = data._MapID
			SetPageToggle(self ,true)
			self._IsCheckRegionMap = true
			self._CurMapType = MapType.REGION
			self:InitPanel("Map",nil)
		elseif data._type == MapType.WORLD then --世界地图
			self._CurMapID = self._HostPlayerMapID
			SetPageToggle(self ,false)
			self._CurMapType = MapType.WORLD
  	  		self:InitPanel("WorldMap",nil)
  	  	elseif data._type == MapType.REPUTATION then --声望地图
  	  		self._CurMapType = MapType.REPUTATION
  	  		self:InitPanel("Reputation",data.ReputationID)
		end	
	else
		self._CurMapID = self._HostPlayerMapID
		SetPageToggle(self ,true)
		self:InitPanel("Map",nil)
	end
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Map, 0)
    CGame.EventManager:addHandler(ContinueTransEvent, OnContinueTransEvent)

end 

local ClearTable = function(self)
	self._Table_AllMonsters = {}
	self._Table_AllNpc = {}	   	
	self._Table_AllRegion = {}
	self._Table_AllEyeDungeonEntrance = {}
	self._ReputationNPCData = {}
	if Table_NpcObj ~= nil then
		for i=#Table_NpcObj, 1, -1 do
			local v = Table_NpcObj[i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_NpcObj,i)
			end
		end
	end

	if Table_RegionImgObj ~= nil then
		for i=#Table_RegionImgObj, 1, -1 do
			local v = Table_RegionImgObj[i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_RegionImgObj,i)
			end
		end
	end

	if Table_RegionNameObj ~= nil then
		for i = #Table_RegionNameObj, 1, -1 do
			local v = Table_RegionNameObj[i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_RegionNameObj,i)
			end
		end
	end

	if Table_BossImgObj ~= nil then
		for i = #Table_BossImgObj, 1, -1 do
			local v = Table_BossImgObj[i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_BossImgObj,i)
			end
		end
	end

	if Table_ReputationImgObj ~= nil then
		for i = #Table_ReputationImgObj, 1, -1 do
			local v = Table_ReputationImgObj[i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_ReputationImgObj,i)
			end
		end
	end

	if Table_EyeDungeonEntranceImgObj[EyeType.Single] ~= nil then
		for i=#Table_EyeDungeonEntranceImgObj[EyeType.Single], 1, -1 do
			local v = Table_EyeDungeonEntranceImgObj[EyeType.Single][i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_EyeDungeonEntranceImgObj[EyeType.Single],i)
			end
		end
	end
	if Table_EyeDungeonEntranceImgObj[EyeType.Multiplayer] ~= nil then
		for i = #Table_EyeDungeonEntranceImgObj[EyeType.Multiplayer], 1, -1 do
			local v = Table_EyeDungeonEntranceImgObj[EyeType.Multiplayer][i]
			if not IsNil(v) then
				v: SetActive(false)
			else
				table.remove(Table_EyeDungeonEntranceImgObj[EyeType.Multiplayer],i)
			end
		end
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if id == "Rdo_NPC" then
		self._NpcIconList:SetActive(checked)
	elseif id == "Rdo_Monster" then
		self._MonsterIconList:SetActive(checked)
	elseif id == "Rdo_EyeSingle" then
		self._EyeSingleList:SetActive(checked)
	elseif id == "Rdo_EyeMultiplayer" then 
		self._EyeMultiplayerList:SetActive(checked)
	end
	local obj = self:GetUIObject(id)
	GUITools.SetBtnExpressGray(obj, checked)

end

--计算真实的坐标，tomap ： true 映射到地图上 false 通过地图映射到实际世界坐标
local GetTruePos = function(self,orginalPosX,orginalPosY,toMap)
	local posX, posY = nil,nil
--[[	local SceneWidth = self._MapInfo[self._CurMapID].Width
	local SceneHeight = self._MapInfo[self._CurMapID].Length--]]

	self._MapInfo = MapBasicConfig.GetMapBasicConfigBySceneID( self._CurMapID )
	local SceneWidth = self._MapInfo.Width
	local SceneHeight = self._MapInfo.Length
	local NavMeshName = self._MapInfo.NavMeshName
    local start, stop = string.find(NavMeshName, "%.")
    NavMeshName = string.sub(NavMeshName,1,start - 1)
	local offset = MapBasicConfig.GetMapOffset()[NavMeshName]
	if offset == nil then  
		if toMap or nil then
			posX = orginalPosX *self._MapWidth/SceneWidth
			posY = orginalPosY *self._MapHeight/SceneWidth
		else
			posX = orginalPosX *SceneWidth/self._MapWidth
			posY = orginalPosY *SceneWidth/self._MapHeight
		end
		return posX, posY
	else
		if toMap or nil then
			posX = orginalPosX *offset.A1 + offset.width 
			posY = orginalPosY *offset.A2 + offset.height
		else
			posX = (orginalPosX - offset.width) / offset.A1
			posY = (orginalPosY - offset.height) / offset.A2
		end
		return posX, posY
	end
end

-- 升序
local function sortFunction(item1,item2)
	if item2 == nil or item2.SortID == nil then return false end
	if item1 == nil or item1.SortID == nil then return false end
	return item1.SortID < item2.SortID
end

local InitNode = function(self)
	self._NodeName = {}
	self._ListType = {}
	local NpcIndex = 0
	if self._CurMapType == MapType.REPUTATION then 
		-- 声望地图 只显示npc
		local temList = {}
		if (self._Table_AllNpc ~= nil) and table.nums(self._Table_AllNpc) > 0 and self._ReputationNPCData ~= nil and table.nums(self._ReputationNPCData) > 0 then
			for i,v in pairs(self._Table_AllNpc) do
				if v ~= nil and self._ReputationNPCData[i] ~= nil  then

					for j,k in ipairs(v) do
						if k ~= nil and (k.IsCanFind ~= nil and k.IsCanFind == 1) then
							local QuestId = self._ReputationNPCData[i].QuestId
							local QuestTemplate = self._ReputationNPCData[i].QuestTemplate
							temList[#temList + 1] = 
							{
								_ID = i, 
								_data = k,
								_NodeType = NodeType.NPC ,
								SortID = k.SortID,
								_QuestId = QuestId,
								_QuestTemplate = QuestTemplate,
							}
						end
					end
				end
			end
			if #temList > 0 then
				table.insert(self._NodeName,StringTable.Get(12003))
				table.sort(temList, sortFunction)
				self._ListType[#self._ListType + 1] = {}
				self._ListType[#self._ListType]._ItemList = temList
				self._ListType[#self._ListType]._IsOpen = true
			end	
		end		
	else
		--NPC显示
		if (self._Table_AllNpc ~= nil) then
			local countTableNpc = table.nums(self._Table_AllNpc)
			if(countTableNpc > 0) then
				local temList = {}
				for i,v in pairs(self._Table_AllNpc) do
					if v ~= nil then
						for j,k in ipairs(v) do
							if k ~= nil and (k.IsCanFind ~= nil and k.IsCanFind == 1)then
								if table.nums(self._ReputationNPCData) > 0 and self._ReputationNPCData[i]~= nil then 
									local QuestId = self._ReputationNPCData[i].QuestId
									local QuestTemplate = self._ReputationNPCData[i].QuestTemplate
									temList[#temList + 1] = 
									{
										_ID = i, 
										_data = k,
										_NodeType = NodeType.NPC ,
										SortID = k.SortID,
										_IsReputation = QuestId ~= 0,
										_QuestId = QuestId,
										_QuestTemplate = QuestTemplate,
									}
								else
								 	local npcTemplate =	CElementData.GetNpcTemplate(i)
								 	if not npcTemplate.IsReputationNPC then 
								 		temList[#temList + 1] = 
										{
											_ID = i, 
											_data = k,
											_NodeType = NodeType.NPC ,
											SortID = k.SortID,
											_IsReputation = false,
										}
								 	end
								end
							end
						end
					end
				end

				if #temList > 0 then
					table.insert(self._NodeName,StringTable.Get(12003))
					table.sort(temList, sortFunction)
					self._ListType[#self._ListType + 1] = {}
					self._ListType[#self._ListType]._ItemList = temList
					self._ListType[#self._ListType]._IsOpen = true
					NpcIndex = #self._ListType
				end			
			end	
		end

	    --怪物显示
	    if self._Table_AllMonsters ~= nil then
			local countTableMonster = table.nums(self._Table_AllMonsters)
			if(countTableMonster > 0) then

				local temList = {}
				for i,v in pairs(self._Table_AllMonsters) do
					if v ~= nil then
						for j,k in ipairs(v) do
							if k ~= nil and (k.IsCanFind ~= nil and k.IsCanFind == 1) then
								temList[#temList + 1] =
								{
									_ID = i, 
									_data = k,
									_NodeType = NodeType.MONSTER,
									SortID = k.SortID,
								}
							end
						end
					end
				end

				if #temList > 0 then
					table.insert(self._NodeName,StringTable.Get(12004))
					table.sort( temList, sortFunction )
					self._ListType[#self._ListType + 1] = {}
					self._ListType[#self._ListType]._ItemList = temList
					self._ListType[#self._ListType]._IsOpen = true
				end
			end	
		end

		-- 传送点和传送阵
		if self._Table_AllRegion[1] ~= nil or self._TransDataTable ~= nil then 
			local countTableRegion = table.nums(self._Table_AllRegion[1])
			local countTableTrans = #self._TransDataTable

			local temList = {}
			if(countTableRegion > 0) then
				for i,v in pairs(self._Table_AllRegion[1]) do
					if v ~= nil then
						temList[#temList + 1] =
						{
							_ID = i, 
							_data = v,
							_NodeType = NodeType.REGIONPOINT,
						}
					end
				end
			end
			if(countTableTrans > 0) then 
				for i,v in ipairs(self._TransDataTable) do 
					if v ~= nil and v.MapId == self._CurMapID then 
						local k = 
						{
							x = v.x,
							z = v.z,
							TransID = v.Id,
						}
						temList[#temList + 1] =
						{
							_ID = i, 
							_data = k,
							_NodeType = NodeType.TRANSLATEBTN,
						} 
					end
				end
			end
			if #temList > 0 then
				table.insert(self._NodeName,StringTable.Get(12036))
				self._ListType[#self._ListType + 1] = {}
				self._ListType[#self._ListType]._ItemList = temList
				self._ListType[#self._ListType]._IsOpen = true
			end
		end
	end
	
	
	-- --区域显示
 --    if self._Table_AllRegion ~= nil then
	-- 	local countTableRegion = table.nums(self._Table_AllRegion)	
	-- 	if(countTableRegion >0) then
			
	-- 		local temList = {}
	-- 		for i,v in pairs(self._Table_AllRegion) do
	-- 			if v ~= nil then		
	-- 				for j,k in pairs(v) do
	-- 					if k ~= nil and (k.IsCanFind ~= nil and k.IsCanFind == 1) then
	-- 						--print_r(k)
	-- 						temList[#temList + 1] = 
	-- 						{
	-- 							_ID = j, 
	-- 							_data = k,
	-- 							_IsNpc = false,
								-- SortID = k.SortID,
	-- 						}
	-- 					end
	-- 				end
	-- 			end
	-- 		end

	-- 		if #temList > 0 then
	-- 			table.insert(self._NodeName,StringTable.Get(12005))
	-- 			self._ListType[#self._ListType + 1] = temList
	-- 		end
	-- 	end	
	-- end

	if #self._ListType == 0 then
		self._FrameList: SetActive(false)
	else
		self._FrameList: SetActive(true)
		GameUtil.SetScrollPositionZero(self._FrameList)
		for i = 1,4 do 
			if #self._ListType < i then
				self:GetUIObject("NodeItem"..i):SetActive(false)
				self:GetUIObject("Btn_Title"..i):SetActive(false)
			else
				local itemObj = self:GetUIObject("NodeItem"..i)
				itemObj:SetActive(true)
				self:GetUIObject("Btn_Title"..i):SetActive(true)
				local Node_list = self._ListType[i]._ItemList
				GUI.SetText(self:GetUIObject("Lab_Tag"..i),self._NodeName[i])
            	local current_type_count = #Node_list
           		if current_type_count > 0 then
	        		itemObj:GetComponent(ClassType.GNewList):SetItemCount(current_type_count)
	        	end
        	end
		end	
	end
	return NpcIndex
end

local function IsClearSelectNode(curObj ,curData,isClear)
	local colorTextId = 12033
	local alpha = 153
	if not isClear then 
		colorTextId = 12032
		alpha = 225
	end
	if not IsNil(curObj) and curData ~= nil then 
    	curObj:FindChild("Img_D"):SetActive(not isClear)
    	if curData._data.Describe ~= nil and curData._NodeType == NodeType.NPC then
       		GUI.SetText(curObj:FindChild("NpcOrRegion/Lab_Tag1"),string.format(StringTable.Get(colorTextId),curData._data.Describe))
       		if curData._data.FunctionName ~= nil and curData._NodeType == NodeType.NPC then
       			GUI.SetText(curObj:FindChild("NpcOrRegion/Lab_Function"),string.format(StringTable.Get(colorTextId),curData._data.FunctionName))
       		end
       	elseif curData._NodeType == NodeType.REGIONPOINT or curData._NodeType == NodeType.TRANSLATEBTN then 
			local labText  = curObj:FindChild("NpcOrRegion/Lab_Tag1")
			if curData._data.worldId ~= nil then
				local mapTemplate = CElementData.GetMapTemplate(curData._data.worldId)
				if mapTemplate == nil then return end
				GUI.SetText(labText,string.format(StringTable.Get(colorTextId),mapTemplate.TextDisplayName))
			elseif curData._data.TransID ~= nil then 
				local mapTemplate = CElementData.GetMapTemplate(curData._data.TransID)
				if mapTemplate == nil then return end
				GUI.SetText(labText,string.format(StringTable.Get(colorTextId),mapTemplate.TextDisplayName))
			end
   		end
       	if curData._data.Describe ~= nil and curData._NodeType == NodeType.MONSTER then
   			local strDesc = string.split(curData._data.Describe,",")
   			local strList = {}
    		for _,w in pairs(strDesc) do
				table.insert(strList,w)
			end
   			local str = ""
       		if not isClear then 
       			-- 点亮
				str = StringTable.Get(12039)..curData._data.level.." "..string.format(StringTable.Get(colorTextId),strList[2])
       		else
				str = StringTable.Get(12039)..curData._data.level.." "..string.format(StringTable.Get(colorTextId),strList[2])
       		end
   			GUI.SetText(curObj:FindChild("Monster/Btn_Path/Lab_Describe"),str)
       	end
       	if curData._data.DropItemIds ~= nil and curData._NodeType == NodeType.MONSTER then
       		local img = curObj:FindChild("Monster/Btn_Detail/Image")
       		GUI.SetAlpha(img, alpha)
       	end
   		
    end
end

-- 获取声望数据
local function GetReputationData(self,QuestIds)
	for i,questId in ipairs(QuestIds) do 
		local questModel = CQuest.Instance():FetchQuestModel( questId)
		local template = questModel:GetTemplate()
		local npc_tid = template.ProvideRelated.ProvideMode.ViaNpc.NpcId
		self._ReputationNPCData[npc_tid] = {}
		self._ReputationNPCData[npc_tid].QuestTemplate = template
		self._ReputationNPCData[npc_tid].QuestId = questId 
	end
end

def.method("string","dynamic").InitPanel = function (self, panelType,ReputationId)
    if not self._Frame_Map then	
  		warn( "find out :_Frame_Map")
    return end

    if not self._Frame_WorldMap then	
  		warn("find out :_Frame_WorldMap")
    return end

  	if panelType == "Map" then
  		--当前场景
  	   self._Frame_Map:SetActive(true)
  	   self._Frame_WorldMap:SetActive(false)
  	   self._Lab_EyeRegionCount:SetActive(false)
  	   self._Btn_EyeRegionCount:SetActive(false)
  	   self._FrameTip:SetActive(true)
  	   self._BtnToggle:SetActive(true)
  	   self._IsUpdateMap = true
  	   self._Page = 0
  	   self._IsCheckRegionMap = false

  	   self: BeginUpdateMapUI()
  	   self:InitShowPath()

		self._CurSelectNodeObj = nil 
		self._CurSelectNodeData = nil 
        if(not self._IsInitMap) then
        	self._IsInitMap = true	
        	ClearTable(self)

	   		local mapId = self._CurMapID
	   		-- warn("????????Mapid",mapId)
	   		--local map = _G.MapBasicInfoTable[mapId]
	   		self._MapInfo = MapBasicConfig.GetMapBasicConfigBySceneID(mapId)
			
			if mapId == self._HostPlayerMapID then
				game._CWorldBossMan:SendC2SEliteBossMapStateInfo(true, mapId)
			else
				game._CWorldBossMan:SendC2SEliteBossMapStateInfo(false, mapId)
			end
			   
        	--warn("MiniMapAtlasPath",MiniMapAtlasPath)

 			--if((self._MapInfo == nil) or (self._MapInfo[mapId] == nil)) then 
			if self._MapInfo == nil then 
 				FlashTip("mapID:"..mapId.."模板错误","tip",2)
 				game._GUIMan:CloseByScript(self)
 			return end

 			GUITools.SetMap(self._Img_Map, self._MapInfo.MiniMapAtlasPath)
        	GUI.SetText(self:GetUIObject("Lab_MapName"),self._MapInfo.TextDisplayName)

 			if self._IsAutoPath and CTransManage.Instance():IsTransState() then
 				local transID,pos = CTransManage.GetTransData()
 				if self._CurMapID == transID and transID ~= self._HostPlayerMapID then
 					self._Obj_AutoPosFinal: SetActive(true)
 					local trueX, trueY = GetTruePos(self,pos.x, pos.z,true)
 					self._Obj_AutoPosFinal.localPosition = Vector3.New(trueX,trueY,0)
 				end
 			end
 			--所有群组
 			self._Table_AllMonsters = self._MapInfo.Monster			
			if(self._Table_AllMonsters ~= nil) then
				-- warn("-*-----self._Table_AllMonsters ==", mapId, i)				
				for i,v in pairs(self._Table_AllMonsters) do
					if(v ~= nil) then
						for j,k in ipairs(v) do	
							if k ~= nil and k.IsBoss ~= nil and k.IsBoss then	
								-- 设置当前地图世界boss的状态
								local WorldBossData = game._CWorldBossMan:GetWorldBossByID(i)
								--Monster 不显示，只显示BOSS
								if WorldBossData ~= nil then 
									
									local trueX, trueY = GetTruePos(self,k.x, k.z,true)
									if trueX ~= nil and trueY ~= nil  then
										self:AddBossObj(Vector3.New(trueX,trueY,0),i,nil)
										local bossBtnBg = self._MonsterIconList:FindChild("Btn_Boss"..i.."/Img_Boss")
										if WorldBossData._Isopen == false or WorldBossData._IsDeath == true then
											GameUtil.MakeImageGray(bossBtnBg, true)
										else
											GameUtil.MakeImageGray(bossBtnBg, false)
										end	
									end
								end
							elseif k ~= nil and k.IsEliteBoss ~= nil and k.IsEliteBoss and k.BossIconPath ~= nil and k.BossIconPath ~= "" then
								local EliteBossData = game._CWorldBossMan:GetEliteBossByID(i)
								if EliteBossData ~= nil then 
									local trueX, trueY = GetTruePos(self,k.x, k.z,true)
									if trueX ~= nil and trueY ~= nil  then
										self:AddBossObj(Vector3.New(trueX,trueY,0),i,k.BossIconPath)
										local bossBtnBg = self._MonsterIconList:FindChild("Btn_Boss"..i.."/Img_Boss")
										if not EliteBossData._IsDeath then
											GameUtil.MakeImageGray(bossBtnBg, true)
										else
											GameUtil.MakeImageGray(bossBtnBg, false)
										end	
									end
								end
							end
						end						
					end
				end
			else
				warn("self._Table_AllMonsters is NIl")	
			end

	   		self._Table_AllNpc = self._MapInfo.Npc	   	
	   		self._Table_AllRegion = self._MapInfo.Region
	   		-- 获取声望npc 数据
	   		local questIds = CQuest.Instance():GetReputationQuestIDsByMapID(mapId)

 			GetReputationData(self,questIds)
	   		self:SendC2SHawkeyeMapInfo()
	   		self: InitMapPanelShow()   
	   		self._CurNpcNodeIndex = InitNode(self)
       end		
 	elseif panelType == "WorldMap" then
 	 	--世界大地图
 	 	self._Page = 1
		self: StopUpdateMapUI()
  	    self._Frame_Map:SetActive(false)
  	    self._Frame_WorldMap:SetActive(true)
  	    self._IsUpdateMap = false
  	    self._FrameTip:SetActive(true)
  	    self._BtnToggle:SetActive(true)
  	    if(not self._IsInitWorld) then
  	       self:InitWorldPanel()
  	       self._IsInitWorld = true
  	    end
  	elseif panelType == "Reputation" then 
  		self._Page = 0
  		self._FrameTip:SetActive(false)
  	    self._BtnToggle:SetActive(false)
  	    self._Frame_Map:SetActive(true)
  	    self._Frame_WorldMap:SetActive(false)
  	    self._IsUpdateMap = true
  	    self:BeginUpdateMapUI()
  	    self._CurSelectNodeObj = nil 
		self._CurSelectNodeData = nil 
  	    self._IsCheckRegionMap = false
  	    if(not self._IsInitMap) then
        	self._IsInitMap = true	
        	ClearTable(self)
    	    local QuestIds = CQuest.Instance():GetQuestIDsByReputationID(ReputationId)

    	    GetReputationData(self,QuestIds)
    	    local template = CElementData.GetTemplate("Reputation", ReputationId)
	        self._CurMapID = template.MapTId
	   		self._MapInfo = MapBasicConfig.GetMapBasicConfigBySceneID(self._CurMapID)
			if self._MapInfo == nil then 
 				FlashTip("mapID:"..self._CurMapID.."模板错误","tip",2)
 				game._GUIMan:CloseByScript(self)
 			return end
 			GUITools.SetMap(self._Img_Map, self._MapInfo.MiniMapAtlasPath)
        	GUI.SetText(self:GetUIObject("Lab_MapName"),self._MapInfo.TextDisplayName)
        	self._Table_AllNpc = self._MapInfo.Npc
        	self:InitMapPanelShow()
        	InitNode(self)	
        end
 	end
end

--对路径线的初始化显示
def.method().InitShowPath = function (self)
	if(game._HostPlayer._IsAutoPathing) and (self._CurMapID == self._HostPlayerMapID) then 
    	if Table_Paths_Points ~= nil and #Table_Paths_Points > 0 then
    		if IsShowCurMapPath then
    			self:SetAutoPathTable(game._HostPlayer._NavTargetPos,true)
				IsShowCurMapPath = false
    		end
    	else 
    		if game._HostPlayer._NavTargetPos ~= nil then 
    			self:SetAutoPathTable(game._HostPlayer._NavTargetPos,true)
    		else
    			if CDungeonAutoMan.Instance():GetGoalPos() == nil then return end
    			self:SetAutoPathTable(CDungeonAutoMan.Instance():GetGoalPos(),true)
    		end
    	end	
    	self._IsAutoPath = true
    	self:OnlyShowAutoPathing(true)	 
    elseif(game._HostPlayer._IsAutoPathing) and (self._CurMapID ~= self._HostPlayerMapID) then
    	local transID,targetPos = CTransManage.GetTransData()

		if self._CurMapID == transID then
			if self._AutoPath_TimerID ~= 0 then
				_G.RemoveGlobalTimer(self._AutoPath_TimerID)
				self._AutoPath_TimerID = 0
			end	
			self._IsAutoPath = true
	   		self:SetAutoPathTable(targetPos,false)
	   		self:OnlyShowAutoPathing(false)
	   		IsShowCurMapPath = true
       	end	
   	else
   		self:HideAllPathObj()  
    end
end

--初始化地图显示
def.method().InitMapPanelShow = function(self)
	--NPC
	if self._CurMapType == MapType.REPUTATION then
		if not IsNil(self._Btn_TransIcon) then
			self._Btn_TransIcon: SetActive(false)
		end	
		if self._ReputationNPCData == nil and table.nums(self._ReputationNPCData) == 0 then return end
		if(self._Table_AllNpc ~= nil) then
			for i,v in pairs(self._Table_AllNpc) do
				local NpcTemplate = CElementData.GetNpcTemplate(i)
				local questList = CQuest.Instance():CalcNPCQuestList(NpcTemplate)
				if questList ~= nil and #questList > 0 then 
					local Quest = nil
					if self._ReputationNPCData[i] ~= nil then 
						for k,v in ipairs(questList) do
							--if v[1] == self._ReputationNPCData[i].QuestId then 
							if v[1] == CQuest.Instance():GetReputationListCurQuestID( self._ReputationNPCData[i].QuestId ) then 
								Quest = v
							end
						end
					end

					if Quest ~= nil then 
						if Quest[3] == QuestTypeDef.Reputation and Quest[2] == QuestFuncDef.CanProvide then 
							if v ~= nil and v[1] ~= nil then
								local trueX, trueY = GetTruePos(self,v[1].x, v[1].z,true)
								if trueX ~= nil and trueY ~= nil then
									self:AddReputationObj(Vector3.New(trueX,trueY,0),i)
								end
							end
						else
							local NPCTaskIconIndex = -1
							if Quest[3] == QuestTypeDef.Reputation then
								if Quest[2] == QuestFuncDef.GoingOn then
								    --进行中
									NPCTaskIconIndex = 0
									-- 声望、赏金、活动（活动即公会）、扫荡，绿色图标
								else
									NPCTaskIconIndex = 4 + Quest[2]
								end
							end
							if NPCTaskIconIndex ~= -1 and v[1] ~= nil then
								local trueX, trueY = GetTruePos(self,v[1].x, v[1].z,true)
								if trueX ~= nil and trueY ~= nil then
									self: AddNpcObj(Vector3.New(trueX,trueY,0),NPCTaskIconIndex,true)	
								end										
							end	
						end
					end
					-- warn("NpcTemplate.Id  ",NpcTemplate.Id ,NPCTaskIconIndex,debug.traceback())			
				end
					
			end

		end
	return end
	if(self._Table_AllNpc ~= nil) then
		for i,v in pairs(self._Table_AllNpc) do

			local NpcTemplate = CElementData.GetNpcTemplate(i)
			local questList = CQuest.Instance():CalcNPCQuestList(NpcTemplate)
			if questList == nil or #questList <= 0 then
				local QuestUtil = require "Quest.QuestUtil"
				local hasQuestRandGroupServer = QuestUtil.HasQuestRandGroupServer(NpcTemplate)
				if hasQuestRandGroupServer then
					-- 有随机任务组的服务
					local NPCTaskIconIndex = 6 -- 必定显示赏金任务的可领取图标
					if NPCTaskIconIndex ~= -1 and v[1] ~= nil then
						local trueX, trueY = GetTruePos(self,v[1].x, v[1].z,true)
						if trueX ~= nil and trueY ~= nil then
							self: AddNpcObj(Vector3.New(trueX,trueY,0),v[1].IconPath,true)	
						end										
					end
				elseif(v ~= nil) then
					for j,k in ipairs(v) do
						local npcTemplate =	CElementData.GetNpcTemplate(i)
						if((k.IconPath ~= nil) and (k.IconPath ~= "") and (k.IconPath ~= " ")) and not npcTemplate.IsReputationNPC then
							local trueX, trueY = GetTruePos(self,k.x, k.z,true)
							if trueX ~= nil and trueY ~= nil then
								-- warn("k.IconPath",)
								-- warn("------ lidaming 没有任何服务的NPC Icon index:", k.IconPath)
								--没有任何服务的NPC
								self: AddNpcObj(Vector3.New(trueX,trueY,0),k.IconPath,false)	
							end
						end				
					end
				end	
			else
				local firstQuest = questList[1]
				
				if firstQuest ~= nil then --可交付
					if firstQuest[3] == QuestTypeDef.Reputation and firstQuest[2] == QuestFuncDef.CanProvide then 
						if self._ReputationNPCData ~= nil and table.nums(self._ReputationNPCData) > 0 and self._ReputationNPCData[i] ~=nil then
							-- warn("npcid ",i)
							if v ~= nil and v[1] ~= nil then
								local trueX, trueY = GetTruePos(self,v[1].x, v[1].z,true)
								if trueX ~= nil and trueY ~= nil then
									self:AddReputationObj(Vector3.New(trueX,trueY,0),i)
								end
							end
						end
					else
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
						if NPCTaskIconIndex ~= -1 and v[1] ~= nil then

							local trueX, trueY = GetTruePos(self,v[1].x, v[1].z,true)
							if trueX ~= nil and trueY ~= nil then
								self: AddNpcObj(Vector3.New(trueX,trueY,0),NPCTaskIconIndex,true)	
							end										
						end	
					end
					-- warn("NpcTemplate.Id  ",NpcTemplate.Id ,NPCTaskIconIndex,debug.traceback())
				end				
			end	
		end
	else
	   warn("self._Table_AllNpc is NIl")		
	end

	if(self._Table_AllRegion ~= nil) then
		for i,v in pairs(self._Table_AllRegion) do	
			if v~= nil then
				if(i ==1) then--目前只显示传送点！！！！
					for j,k in pairs(v) do
						if k ~= nil then
							local trueX, trueY = GetTruePos(self,k.x, k.z,true)
							if trueX ~= nil and trueY ~= nil then
								local strIcon = ""
								if k.IconPath ~= nil then
									strIcon = k.IconPath
								end
								self: AddRegionObj(Vector3.New(trueX,trueY,0),strIcon)	
							end		
						end									   
					end	
				else  --显示区域Namelabel
					for j,k in pairs(v) do
						if k ~= nil and (k.IsCanFind ~= nil and k.IsCanFind == 1) and k.isShowName ~= nil and k.isShowName and k.name ~= "" then
							local trueX, trueY = GetTruePos(self,k.x, k.z,true)
							if trueX ~= nil and trueY ~= nil then
								self: AddRegionLab(Vector3.New(trueX,trueY,0),k.name)
							end		
						end								   
					end	
				end	
			end
		end
	else
		warn("self._Table_AllRegion is NIl")
	end
	
	self._TransID = 0
	--显示传送阵
	if not IsNil(self._Btn_TransIcon) then
		self._Btn_TransIcon: SetActive(false)
		for _,v in ipairs(self._TransDataTable) do
			if v ~= nil then
				if v.MapId == self._CurMapID then
					self._Btn_TransIcon: SetActive(true)
					local trueX, trueY = GetTruePos(self,v.x,v.z,true)
					self._Btn_TransIcon.localPosition = Vector3.New(trueX,trueY,0)
					self._TransID = v.Id
				end
			end
		end
	end
end

def.method("table","dynamic","boolean").AddNpcObj = function(self,v3Pos,strIcon,isQuest)
	-- Table_NpcObj = {}
	local AddNewNpcObj = function (objPos,iconName)
		local obj = GameObject.Instantiate(self._Obj_Npc)
		if(obj ~= nil) then
			obj:SetParent(self._NpcIconList)
			obj.localPosition = v3Pos
			-- 暂时应用
   			obj.localScale = Vector3.one					
   			obj:SetActive(true)
   			if isQuest then 
	   			local doTweenPlayer = obj:GetComponent(ClassType.DOTweenPlayer)
	   			doTweenPlayer:Restart("QuestTween")
	   		end
   			if iconName ~= nil then
   				GUITools.SetGroupImg(obj,iconName)
   			end

   			Table_NpcObj[#Table_NpcObj + 1] = obj
   		end
	end

	if Table_NpcObj == nil or #Table_NpcObj <= 0 then
		-- warn(" ---AddNewNpcObj------ ")
		AddNewNpcObj(v3Pos,strIcon)
	else
		-- warn(" ---not v.activeSelf ------ ")
		for _,v in ipairs(Table_NpcObj) do
			if not v.activeSelf then
				v: SetActive(true)
				v.localPosition = v3Pos
				GUITools.SetGroupImg(v,strIcon)
				return
			end
		end
		AddNewNpcObj(v3Pos,strIcon)
	end
end


def.method("table","string").AddRegionObj = function(self,v3Pos,strIcon)
	-- Table_RegionImgObj = {}
	local AddNewRegionObj = function (objPos,iconName)
		local obj = GameObject.Instantiate(self._Obj_Transfer)
		if(obj ~= nil) then
			obj:SetParent(self._Obj_Map)
			obj.localPosition = v3Pos
   			obj.localScale = Vector3.one 						
   			obj:SetActive(true)
   			if(iconName ~= " ") then
   				GUITools.SetGroupImg(obj,iconName)
   			end   			
   			Table_RegionImgObj[#Table_RegionImgObj + 1] = obj
   		end
	end

	if Table_RegionImgObj == nil or #Table_RegionImgObj <= 0 then
		AddNewRegionObj(v3Pos,strIcon)
	else
		for _,v in ipairs(Table_RegionImgObj) do
			if not v.activeSelf then
				v: SetActive(true)
				v.localPosition = v3Pos
				if(strIcon ~= " ") then
   					GUITools.SetGroupImg(v,strIcon)	
   				end   	
			return end
		end

		AddNewRegionObj(v3Pos,strIcon)
	end
end

def.method("table","string").AddRegionLab = function(self,v3Pos,regionName)
	-- Table_RegionNameObj = {}
	local AddNewRegionLab = function (objPos,regionName)
		local obj = GameObject.Instantiate(self._Obj_Region_Name)
		if(obj ~= nil) then
			obj:SetParent(self._Obj_RegionGroup)
			obj.localPosition = v3Pos
   			obj.localScale = Vector3.one 						
   			obj:SetActive(true)
   			GUI.SetText(obj, regionName)		
   			Table_RegionNameObj[#Table_RegionNameObj + 1] = obj
   		end
	end

	if Table_RegionNameObj == nil or #Table_RegionNameObj <= 0 then
		Table_RegionNameObj = {}
		AddNewRegionLab(v3Pos,regionName)
	else
		for _,v in ipairs(Table_RegionNameObj) do
			if not v.activeSelf then
				v: SetActive(true)
				v.localPosition = v3Pos				
				GUI.SetText(v, regionName)
				return				
			end
		end

		AddNewRegionLab(v3Pos,regionName)
	end
end

def.method("table","number","dynamic").AddBossObj = function(self,v3Pos,BossID,IconPath)
	-- Table_BossImgObj = {}
	local AddNewBossObj = function (objPos)
		local obj = GameObject.Instantiate(self._Obj_BOSS)
		if(obj ~= nil) then
			obj:SetParent(self._MonsterIconList)
			obj.localPosition = v3Pos
   			obj.localScale = Vector3.one 						
   			obj:SetActive(true)
   			obj.name = "Btn_Boss"..BossID
   			local doTweenPlayer = obj:GetComponent(ClassType.DOTweenPlayer)
   			doTweenPlayer:Restart("Boss")
			-- local bossData = CElementData.GetTemplate("Monster", BossID)
			if IconPath ~= nil then 
				GUITools.SetGroupImg(obj:FindChild("Img_Boss"),IconPath)
			end
   			GUITools.RegisterButtonEventHandler(self._Panel,obj)		
   			Table_BossImgObj[#Table_BossImgObj + 1] = obj
   		end
	end

	if Table_BossImgObj == nil or #Table_BossImgObj <= 0 then
		AddNewBossObj(v3Pos)
	else
		for _,v in ipairs(Table_BossImgObj) do
			if not v.activeSelf then
				local bossId = tonumber(string.sub(v.name,9,-1))
				if bossId == BossID then 
					v:SetActive(true)
					v.localPosition = v3Pos 	
				return end
			end
		end

		AddNewBossObj(v3Pos)
	end
end

def.method("table","number").AddReputationObj = function(self,v3Pos,NpcID)
	local AddNewReputationObj = function (objPos)
		local obj = GameObject.Instantiate(self._BtnReputation)
		if(obj ~= nil) then
			obj:SetParent(self._NpcIconList)
			obj.localPosition = v3Pos
   			obj.localScale = Vector3.one 						
   			obj:SetActive(true)
   			obj.name = "Btn_Reputation"..NpcID
   			GUITools.RegisterButtonEventHandler(self._Panel,obj)		
   			Table_ReputationImgObj[#Table_ReputationImgObj + 1] = obj
   		end
	end
	if Table_ReputationImgObj == nil or #Table_ReputationImgObj <= 0 then
		AddNewReputationObj(v3Pos)
	else
		for _,v in ipairs(Table_ReputationImgObj) do
			if not v.activeSelf then
				v:SetActive(true)
				v.localPosition = v3Pos 
				v.name = "Btn_Reputation"..NpcID	
			return end
		end
		AddNewReputationObj(v3Pos)
	end
end

def.method("table","number","number","number","number","number").AddEyeRegionObj = function(self,v3Pos,regionID,dungeonId,remainCount,challengeCount,hawkeyeType)
	local AddNewEyeRegionObj = function (objPos)
		local obj = GameObject.Instantiate(self._Obj_EyeRegion)
		if(obj ~= nil) then
			if hawkeyeType == EyeType.Single then
				obj:SetParent(self._EyeSingleList)
			elseif hawkeyeType == EyeType.Multiplayer then
				obj:SetParent(self._EyeMultiplayerList)
			end
			obj.localPosition = v3Pos 
   			obj.localScale = Vector3.one 						
   			obj:SetActive(true)
   			obj.name = "Btn_EyeEntrance"..regionID
   			local btnBG = obj:FindChild( "Img_Boss" )

			if remainCount == 0 or challengeCount == 0 then
				GUITools.MakeBtnBgGray(btnBG, true)
			else
				GUITools.MakeBtnBgGray(btnBG, false)
			end	
			GUITools.SetGroupImg(btnBG,hawkeyeType - 1)
   			GUITools.RegisterButtonEventHandler(self._Panel,obj)	
   			if Table_EyeDungeonEntranceImgObj[hawkeyeType] == nil then 
   				Table_EyeDungeonEntranceImgObj[hawkeyeType] = {}
   			end
   			Table_EyeDungeonEntranceImgObj[hawkeyeType][#Table_EyeDungeonEntranceImgObj[hawkeyeType] + 1] = obj
   		end
	end

	if Table_EyeDungeonEntranceImgObj == nil or Table_EyeDungeonEntranceImgObj[hawkeyeType] == nil then
		AddNewEyeRegionObj(v3Pos)
	else
		for _,v in ipairs(Table_EyeDungeonEntranceImgObj[hawkeyeType]) do
			if not v.activeSelf then
				v.name = "Btn_EyeEntrance"..regionID
				v:SetActive(true)
				v.localPosition = v3Pos 	

    			local dungeondata = CElementData.GetInstanceTemplate(dungeonId)
	   			local btnBG = v:FindChild( "Img_Boss" )
				if remainCount == 0 or challengeCount == 0 or dungeondata.MinEnterLevel > game._HostPlayer._InfoData._Level then
					GUITools.MakeBtnBgGray(btnBG, true)
				else
					GUITools.MakeBtnBgGray(btnBG, false)
				end	
				GUITools.SetGroupImg(btnBG,hawkeyeType - 1)
				return 
			end
		end

		AddNewEyeRegionObj(v3Pos)
	end
end

def.method("table").ShowEyeRegions = function(self,protocol)
	for k, v in pairs(protocol.infos) do
		--print("ShowEyeRegions",v.regionId,v.remainCount,self._Table_AllRegion[v.regionId])
		if v and v.regionId and v.regionId > 0 and self._Table_AllRegion[2] ~= nil and self._Table_AllRegion[2][v.regionId] ~= nil then
			local trueX, trueY = GetTruePos(self,self._Table_AllRegion[2][v.regionId].x, self._Table_AllRegion[2][v.regionId].z,true)
			if trueX ~= nil and trueY ~= nil then
				self._Table_AllEyeDungeonEntrance[v.regionId] = {mapID = protocol.mapID,regionId = v.regionId,dungeonId = v.dungeonId,remainCount = v.remainCount, challengeCount = v.challengeCount, hawkeyeType = v.hawkeyeType}
				self: AddEyeRegionObj(Vector3.New(trueX,trueY,0),v.regionId,v.dungeonId,v.remainCount,v.challengeCount,v.hawkeyeType)
			end	
		end
	end

	if not IsNil(self._Lab_EyeRegionCount) then
		local str = ""
		if protocol.remainCount > 0 then 
			str = string.format(StringTable.Get(12017),protocol.remainCount)
		else
			str = string.format(StringTable.Get(12035),protocol.remainCount)
		end
		self._Lab_EyeRegionCount:SetActive(true)
		self._Btn_EyeRegionCount:SetActive(true) 
		GUI.SetText(self._Lab_EyeRegionCount,str)
	--protocol.remainCount
	end
end 

-- local function ShowPlayerHeadInWorldMap(panel,headpos,BGpos,parentCell)
-- 	panel._Obj_World_Player_Head:SetActive(true)
--     panel._Obj_World_Player_Head:SetParent(parentCell)
--     panel._Obj_World_Player_Head.localPosition = headpos
--    	panel._Obj_World_Player_Head.localScale = Vector3.one 						
   		   	 

--    	panel._Obj_World_Player_Host:SetActive(true)
--    	panel._Obj_World_Player_Host:SetParent(parentCell)
--     panel._Obj_World_Player_Host.localPosition = BGpos
--    	panel._Obj_World_Player_Host.localScale = Vector3.one 

--     local headIconPath = ""
-- 	local hp = game._HostPlayer
-- 	if hp._InfoData._Gender == EnumDef.Gender.Female then
-- 		headIconPath =  hp._ProfessionTemplate.FemaleIconAtlasPath
-- 	else
-- 		headIconPath = hp._ProfessionTemplate.MaleIconAtlasPath
-- 	end

--     GUITools.SetHeadIcon(panel._Obj_World_Player_Head, headIconPath)
-- end 

def.method().InitWorldPanel = function (self)
	-- body
	if( self._MapInfo == nil) then return end

	self._Obj_World_Player_Head:SetActive(false)
	-- self._Obj_World_Player_Host:SetActive(false)
	local nLevel = game._HostPlayer._InfoData._Level
    local nWorld = game._CurWorld._WorldInfo.MapTid 
 
    local textType = ClassType.Text
	for i,v in ipairs(GameUtil.GetAllTid("Map")) do
	  local mapName = 'CityGroup/Btn_City'..v
	  local worldCell = self._Frame_WorldMap: FindChild(mapName)
	  if( worldCell ~= nil) then
	      	local worldData = CElementData.GetMapTemplate(v)	
	      	if(worldData ~= nil) then
	      	 	local nameLab = worldCell: FindChild("Lab_City")	  	  	
	  	  		local levelLab = worldCell: FindChild("Lab_CityLV")
	  	  		local imgBg = worldCell:FindChild("Img_Bg")
	  			local imgLock = worldCell:FindChild("Img_Lock")
				local nLimitedLV = worldData.LimitEnterLevel
				local nMaxLV = worldData.RecommendMaxLevel
	  	  		local levelText = ""
				if nLimitedLV == nMaxLV then 
	  	  			levelText = string.format(StringTable.Get(12010),nLimitedLV)
	  	  		elseif nLimitedLV < nMaxLV then 
	  	  			levelText = string.format(StringTable.Get(12009),nLimitedLV,nMaxLV)
	  	  		else
	  	  		    warn("map Template level limit is wrong")
	  	  		end
	  	  		if(nLevel < nLimitedLV) then
	  	  			imgBg :SetActive(false)
  					imgLock:SetActive(true)
	  	  			if(levelLab ~= nil) then
	  	  				levelText = string.format(StringTable.Get(12010),nLimitedLV)..StringTable.Get(12011)  	  	  				
             	  		levelLab:GetComponent(textType).text = levelText
             	  	end
             	  	if(nameLab ~= nil) then
             	  		GameUtil.SetActiveOutline(nameLab,false)
	  	      			nameLab:GetComponent(textType).text =  worldData.TextDisplayName
	  	  			end
	  	  		else
	  	  			imgBg :SetActive(true)
  					imgLock:SetActive(false)
					if(nameLab ~= nil) then
	  	      			nameLab:GetComponent(textType).text =  worldData.TextDisplayName
	  	  			end

	  	  			if(levelLab ~= nil) then	  	  				
             	  		levelLab:GetComponent(textType).text = levelText
             	  	end
	  	  		end
	      	end	
		else
			local regionName = 'RegionGroup/Btn_Region'..v
	  		local regionCell = self._Frame_WorldMap: FindChild(regionName)
	  		if regionCell ~= nil then
	  			local labName = regionCell:FindChild("Lab_Name")
	  			local imgBg = regionCell:FindChild("Img_Bg")
	  			local imgLock = regionCell:FindChild("Img_Lock")
        		local name = labName:GetComponent(ClassType.Text).text
        		local levelLab = regionCell: FindChild("Lab_Region"..v)
        		if levelLab ~= nil then
        			local worldData = CElementData.GetMapTemplate(v)	
	      			if(worldData ~= nil) then
	      				local nMinLV = worldData.LimitEnterLevel
	      				local nBasicLV = worldData.RecommendMaxLevel
	      				local strText =""
	      				if nMinLV == nBasicLV then 
	      					strText = string.format(StringTable.Get(12009),nMinLV,nBasicLV)	
			  	  		elseif nMinLV < nBasicLV then 
			  	  			strText = string.format(StringTable.Get(12009),nMinLV,nBasicLV)
			  	  		else
			  	  		    warn("map Template level limit is wrong")
			  	  		end
	      				if nLevel < nMinLV then
	      					strText = string.format(StringTable.Get(12010),nMinLV)..StringTable.Get(12011)
	      					imgBg:SetActive(false)
	      					imgLock:SetActive(true)
	      				else
	      					imgBg :SetActive(true)
	      					imgLock:SetActive(false)
	      				end
	      				GUI.SetText(labName,name)
	      				GUI.SetText(levelLab, strText)
	      			end	 
        		end	  		 	
	  		end
		end  
	end
	-- 显示玩家所在地图	
	if not IsNil(self._BeforeLocationObj) then 
		self._BeforeLocationObj:SetActive(false)
	end
	local imgName = "Img_Location"..self._HostPlayerMapID
	local img_Location = self:GetUIObject(imgName)
	if not IsNil(img_Location) then 
		img_Location:SetActive(true)
		self._BeforeLocationObj = img_Location
	end
		
end

--刷新区域地图s
def.method().BeginUpdateMapUI = function (self)
    self:UpdatePlayerPosition()
    if(not self._IsUpdateMap) then return end

	self._PlayerPos_TimerID = _G.AddGlobalTimer(0.1001, false, function()
		if self._IsUpdateMap then
			self: UpdatePlayerPosition()
		end
	end)
end

def.method().StopUpdateMapUI = function(self)
    if(not self._IsUpdateMap) then return end
    if self._PlayerPos_TimerID ~= 0 then
		_G.RemoveGlobalTimer(self._PlayerPos_TimerID)
		self._PlayerPos_TimerID = 0
	end
end

--刷新寻路点
def.method("number").BeginUpdateAutoPathing = function(self,nTime)
    if( not self._IsAutoPath) then return end
    if self._AutoPath_TimerID ~= 0 then
	   _G.RemoveGlobalTimer(self._AutoPath_TimerID)
	end
	self._AutoPath_TimerID = _G.AddGlobalTimer(nTime, false, function()	
			self: UpdateAutoPathing()
	end)
end

def.method().UpdateAutoPathing = function(self)
	if Table_Paths_Points ~= nil then 
		table.remove(Table_Paths_Points,1)
	end
	if not self:IsShow() then return end
	if(Table_Path_Obj == nil) or (#Table_Path_Obj <= 0) then return end
	Table_Path_Obj[1]:Destroy()
	table.remove(Table_Path_Obj,1) 	
end

def.method().StopUpdateAutoPathing = function(self)	
	-- self: ClearAllPathObj()
	self:HideAllPathObj()
	Table_Paths_Points = nil
	PointerClickTargetPos = nil
    if self._AutoPath_TimerID ~= 0 then
		_G.RemoveGlobalTimer(self._AutoPath_TimerID)
		self._AutoPath_TimerID = 0
	end	
end

-- 打断寻路 隐藏地图上的寻路路线
def.method().InterruptAutoPathing = function(self)
	self._IsAutoPath = false
	self:StopUpdateAutoPathing()
end

def.override("string").OnClick = function(self, id)
 	CPanelBase.OnClick(self,id)
   
    if id == "Btn_Back" then
       self: ClosePanel()
    return end

    if id == "Btn_Toggle" then 
    	self:ChangeWorldAndRegionMap(self._CurMapType)
	return end

    if id == "Btn_TransIcon" then
    	self:TranslateElseMap(self._TransID)
    return end

    if id == "Btn_GuildBase" then
    	local hp = game._HostPlayer
		if hp:IsDead() then
			game._GUIMan:ShowTipText(StringTable.Get(30103), false)
		    return
		end
    	--跨服判断
		if game._HostPlayer:IsInGlobalZone() then
	        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
	        return
	    end
    	if not game._GuildMan:IsHostInGuild() then
    		game._GUIMan:ShowTipText(StringTable.Get(12031), false)
    	return end

    	if game._HostPlayer:IsInServerCombatState() then
			game._GUIMan:ShowTipText(StringTable.Get(139), false)
		return end

        if game._CurMapType == EWorldType.Pharse then
            local callback = function(val)
                if val then
                    game:StopAllAutoSystems()
                    game._GuildMan:EnterGuildMap()
 				    game._GUIMan:CloseByScript(self)
                end
            end
            local title, msg, closeType = StringTable.GetMsg(82)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)   
        else
            local callback = function(val)
    		    if val then      
                    game:StopAllAutoSystems()
 				    game._GuildMan:EnterGuildMap()
 				    game._GUIMan:CloseByScript(self)				
    		    end
    	    end

    	    local title, msg, closeType = StringTable.GetMsg(15)
    	    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)  	
        end
    return end

    if id == "Btn_EyeRegionCount" then 
    	game._GUIMan:Open("CPanelEyeRegionIntroduction",nil)
    return end

    --主城，点击传送
    local nLevel = game._HostPlayer._InfoData._Level
    if string.find(id,"Btn_City") then
    	--跨服判断
		if game._HostPlayer:IsInGlobalZone() then
	        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
	        return
	    end

    	if game._HostPlayer:IsInServerCombatState() then
			game._GUIMan:ShowTipText(StringTable.Get(139), false)
		return end

    	local WorldID = string.sub(id, string.len("Btn_City")+1,-1)
    	local nWorld = game._CurWorld._WorldInfo.MapTid 
    	if(WorldID ~= "") then
    		local nWorldID = tonumber(WorldID)
        	if(nWorld == nWorldID) then 
          	 	game._GUIMan: ShowTipText(StringTable.Get(12001),true)
        	return end

			local worldData = CElementData.GetMapTemplate(nWorldID)	
			if((worldData == nil) or (worldData.LimitEnterLevel == nil)) then return end        
        

        	if(nLevel < worldData.LimitEnterLevel) then game._GUIMan: ShowTipText(StringTable.Get(12008),false)  return end
       
			local callback = function(val)
    			if val then
    				CQuestAutoMan.Instance():Stop()
				   	CDungeonAutoMan.Instance():Stop()
				   	CAutoFightMan.Instance():Stop()
					CTransManage.Instance():TransToCity(nWorldID)
    				self: ClosePanel()  								
    			end
    		end

    		local title, strInfo, closeType = StringTable.GetMsg(16)
    		local msg = string.format(strInfo, worldData.TextDisplayName)
    		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)  	
		end
	 --区域，点击打开区域地图
    elseif string.find(id,"Btn_Region") then
    	-- 区域数据没有 提示区域未开放
    	self._CurMapType = MapType.REGION
    	local RegionID = string.sub(id, string.len("Btn_Region")+1,-1)	
		if  RegionID == " "  or tonumber(RegionID) <= 0 then 
			game._GUIMan: ShowTipText(StringTable.Get(12008),true)
		return end 
	   
	   	local nRegionID =  tonumber(RegionID)
    	local nWorld = game._CurWorld._WorldInfo.MapTid
    	local RegionInfo = MapBasicConfig.GetMapBasicConfigBySceneID( nRegionID )
    	--if self._MapInfo[nRegionID] == nil then
		if RegionInfo == nil then
    		FlashTip("区域："..nRegionID.."数据不存在","tip",1)
    	return end
		
		local mapData = CElementData.GetMapTemplate(nRegionID)
		if mapData ~= nil then
			if nLevel < mapData.LimitEnterLevel then game._GUIMan: ShowTipText(StringTable.Get(12008),false) return end
		end

		--warn("nRegionID:"..nRegionID)
		self:HideAllPathObj()
		ClearTable(self)
		self._IsInitMap = false
		self._IsCheckRegionMap = true
		SetPageToggle(self,true)
    	self._CurMapID = nRegionID	
    	self:InitPanel("Map",nil) 
	elseif string.find(id,"Btn_Boss") then		    
		local BossID = string.sub(id, string.len("Btn_Boss")+1,-1)	
		game._GUIMan:Open("CPanelWorldBoss", BossID)
	elseif string.find(id,"Btn_EyeEntrance") then	
		local regionID = string.sub(id, string.len("Btn_EyeEntrance")+1,-1)	
		game._GUIMan:Open("CPanelUIEyeEntranceTips", { _Data = self._Table_AllEyeDungeonEntrance[tonumber(regionID)],_ParentUI = self }) 
	elseif string.find(id,"Btn_Reputation") then 
		local NpcID = tonumber( string.sub(id, string.len("Btn_Reputation")+1,-1))	
		if self._ReputationNPCData[NpcID] == nil then warn("-----self._ReputationNPCData[NpcID] = nil---",debug.traceback()) end
		local smallTypeIndex = 0
		
		local okCallback = nil

		if self._CurMapType == MapType.REGION then
			local questid = self._ReputationNPCData[NpcID].QuestId
			local function callback()
		        local questmodel = CQuest.Instance():FetchQuestModel(questid)
		        if questmodel ~= nil then
		            questmodel:DoShortcut()
		        end
			end
			okCallback = callback
		elseif self._CurMapType == MapType.REPUTATION then
			self._CurNpcNodeIndex = 1
		end
		for i ,data in ipairs(self._ListType[self._CurNpcNodeIndex]._ItemList) do 
			if data._ID == NpcID then 
				smallTypeIndex = i
			break end
		end
		if smallTypeIndex == 0  then return end
		self:UpateSelectNpcNodeByBtn(self._CurNpcNodeIndex,smallTypeIndex)
		local PanelData = 
		{
			QuestId = self._ReputationNPCData[NpcID].QuestId,
			QuestTemplate = self._ReputationNPCData[NpcID].QuestTemplate,
			IsClosePanel = true,
			OkCallBack = okCallback,
		}
		game._GUIMan:Open("CPanelReputationIntroduction",PanelData)
	elseif string.find(id,"Btn_Title") then 
		local index = tonumber(string.sub(id,-1))
		local ItemObj = self:GetUIObject("NodeItem"..index)
		local btnTitle = self:GetUIObject("Btn_Title"..index)
		local imgBg = btnTitle:FindChild("Img_Bg")
		local imgArrow = btnTitle:FindChild("Img_Arrow")
		local labTitle = btnTitle:FindChild("Lab_Tag"..index)
		if not self._ListType[index]._IsOpen then 
			ItemObj:SetActive(true)
			self._ListType[index]._IsOpen = true
			GUITools.SetGroupImg(imgBg,0)
			GUITools.SetGroupImg(imgArrow,2)
			GUI.SetText(labTitle,string.format(StringTable.Get(12032),self._NodeName[index]))
		else
			ItemObj:SetActive(false)
			GUITools.SetGroupImg(imgBg,1)
			GUITools.SetGroupImg(imgArrow,1)
			self._ListType[index]._IsOpen = false
			warn(" self._NodeName[index]) ",self._NodeName[index])
			GUI.SetText(labTitle,string.format(StringTable.Get(12040),self._NodeName[index]))
		end
    end  
end


def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)	
	if string.find(id, "Item") then 
		local bigTypeIndex = tonumber(string.sub(id, -1))
		local current_Node_list = self._ListType[bigTypeIndex]._ItemList
        local cur = current_Node_list[index + 1]
        item:FindChild("Img_D"):SetActive(false)
        local MonsterObj = item:FindChild("Monster")
        local NpcOrRegion = item:FindChild("NpcOrRegion")
        if cur._NodeType == NodeType.MONSTER then 
        	table.insert(self._MonsterNodeObjs,item)
        	MonsterObj:SetActive(true)
        	NpcOrRegion:SetActive(false)
        	local btnPath = item:FindChild("Monster/Btn_Path")
        	local btnDetail = item:FindChild("Monster/Btn_Detail")
        	if cur._data.Describe ~= nil then
        		btnPath:SetActive(true)
        		local strDesc = string.split(cur._data.Describe,',')
	   			local str = ""
       			local strList = {}
	    		for _,w in pairs(strDesc) do
					table.insert(strList,w)
    			end
				local str = StringTable.Get(12039)..cur._data.level.." "..strList[2]
            	GUI.SetText(btnPath:FindChild("Lab_Describe"),str)
            else
            	btnPath:SetActive(false)
            end
            if cur._data.DropItemIds == nil then 
            	btnDetail:SetActive(false)
            else
            	btnDetail:SetActive(true)
	       		local img = btnDetail:FindChild("Image")
            	GUI.SetAlpha(img, 153)
            end
        elseif cur._NodeType == NodeType.NPC then
        	table.insert(self._NpcNodeObjs,item)
        	MonsterObj:SetActive(false)
        	NpcOrRegion:SetActive(true)
        	if cur._data.Describe ~= nil then
       			GUI.SetText(NpcOrRegion:FindChild("Lab_Tag1"),string.format(StringTable.Get(12033),cur._data.Describe))
       		end
       		if cur._data.IconPath ~= nil and cur._data.IconPath ~= "" then 
       			GUITools.SetGroupImg(NpcOrRegion:FindChild("Img_Icon"),cur._data.IconPath)
       		end
       		local labfunction = NpcOrRegion:FindChild("Lab_Function")
       		if cur._data.FunctionName ~= nil and cur._data.FunctionName ~= "" then 
       			labfunction:SetActive(true)
       			GUI.SetText(labfunction,cur._data.FunctionName)
       		else
       			labfunction:SetActive(false)
       		end
       	elseif cur._NodeType == NodeType.REGIONPOINT then 
       		MonsterObj:SetActive(false)
        	NpcOrRegion:SetActive(true)
       		NpcOrRegion:FindChild("Lab_Function"):SetActive(false)
        	GUITools.SetGroupImg(NpcOrRegion:FindChild("Img_Icon"),"CBT_Map_Tag_020")
        	local mapTemplate = CElementData.GetMapTemplate(cur._data.worldId)
        	if mapTemplate == nil then return end
        	GUI.SetText(NpcOrRegion:FindChild("Lab_Tag1"),mapTemplate.TextDisplayName)
       	elseif cur._NodeType == NodeType.TRANSLATEBTN then 
       		MonsterObj:SetActive(false)
        	NpcOrRegion:SetActive(true)
        	NpcOrRegion:FindChild("Lab_Function"):SetActive(false)
        	GUITools.SetGroupImg(NpcOrRegion:FindChild("Img_Icon"),"CBT_Map_Tag_019")
        	local transTemp = CElementData.GetTemplate("Trans", cur._data.TransID)
        	local mapTemplate = CElementData.GetMapTemplate(transTemp.MapId)
        	if mapTemplate == nil then return end
        	GUI.SetText(NpcOrRegion:FindChild("Lab_Tag1"),mapTemplate.TextDisplayName)
       	end
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if string.find(id, "Item") then 
		if self._CurMapType == MapType.REPUTATION then 
			self:UpateSelectNode(id,index,item)
			if self._CurSelectNodeData._QuestId == 0 or self._CurSelectNodeData._QuestTemplate == nil then 
				warn(" Reputation Id is 0 or QuestTemplate is nil ",debug.traceback())
				return 
			end
			local PanelData = 
			{
				QuestId = self._CurSelectNodeData._QuestId,
				QuestTemplate = self._CurSelectNodeData._QuestTemplate,
				IsClosePanel = true,
			}
			game._GUIMan:Open("CPanelReputationIntroduction",PanelData)
	    else
	    	local function callback()
				self:ClickItemMoveToPos()
			end
	    	self:UpateSelectNode(id,index,item)
	    	if self._CurSelectNodeData._NodeType == NodeType.NPC and self._CurSelectNodeData._IsReputation then
	    		local PanelData = 
				{
					QuestId = self._CurSelectNodeData._QuestId,
					QuestTemplate = self._CurSelectNodeData._QuestTemplate,
					IsClosePanel = true,
					OkCallBack = callback,
				}
				game._GUIMan:Open("CPanelReputationIntroduction",PanelData)
	    	else
	        	self:ClickItemMoveToPos()
	        end
	    end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
	if id_btn == "Btn_Detail" then 
		self:UpateSelectNode(id,index,self._MonsterNodeObjs[index + 1])
		local function callback()
			self:ClickItemMoveToPos()
		end
		local itemIds = {}
		local ids = string.split(self._CurSelectNodeData._data.DropItemIds, '*') 
		for _,id in pairs(ids) do
			table.insert(itemIds,tonumber(id))
		end
		local PanelData = 
		{
			MonsterName = self._CurSelectNodeData._data.name,
			ItemIds = itemIds ,
			OkCallBack = callback,
		}
		game._GUIMan:Open("CPanelMonsterDropItems",PanelData)
	elseif id_btn == "Btn_Path" then
		self:UpateSelectNode(id,index,self._MonsterNodeObjs[index + 1])
		self:ClickItemMoveToPos()
	end
end

def.method("string","number","userdata").UpateSelectNode = function (self,id,index,item)
	local isClearSlect = true
	IsClearSelectNode(self._CurSelectNodeObj,self._CurSelectNodeData,isClearSlect)
    local bigTypeIndex = tonumber(string.sub(id, -1))
    local smallTypeIndex = index + 1
    self._CurSelectNodeData = self._ListType[bigTypeIndex]._ItemList[index + 1]
    self._CurSelectNodeObj = item 
	self._CurSelectNodeObj:FindChild("Img_D"):SetActive(true)
	isClearSlect = false
	IsClearSelectNode(self._CurSelectNodeObj,self._CurSelectNodeData,false)
end

def.method("number","number").UpateSelectNpcNodeByBtn = function(self,bigTypeIndex,smallTypeIndex)
	IsClearSelectNode(self._CurSelectNodeObj,self._CurSelectNodeData,true)
	self._CurSelectNodeData = self._ListType[bigTypeIndex]._ItemList[smallTypeIndex]
    self._CurSelectNodeObj = self._NpcNodeObjs[smallTypeIndex]
	self._CurSelectNodeObj:FindChild("Img_D"):SetActive(true)
	IsClearSelectNode(self._CurSelectNodeObj,self._CurSelectNodeData,false)
end

-- 点击左侧的LIst的Item直接追踪目标(NPC 寻路需要偏移)
def.method().ClickItemMoveToPos = function(self)
	-- body
	local curNodeData = self._CurSelectNodeData
	if(curNodeData == nil) then return end
	game._HostPlayer:StopAutoTrans()
	CQuestAutoMan.Instance():Stop()
   	CDungeonAutoMan.Instance():Stop()
   	CAutoFightMan.Instance():Stop()

	--同场景寻路
	if self._CurMapID == self._HostPlayerMapID then
		if curNodeData._NodeType == NodeType.MONSTER or curNodeData._NodeType == NodeType.REGIONPOINT then 
			self:AutoPathingToTarget(self._CurSelectNodeData._data.x, self._CurSelectNodeData._data.y, self._CurSelectNodeData._data.z,false)  
		elseif curNodeData._NodeType == NodeType.NPC then 
			self:AutoPathingToTarget(self._CurSelectNodeData._data.x, self._CurSelectNodeData._data.y, self._CurSelectNodeData._data.z,true)
		elseif curNodeData._NodeType == NodeType.TRANSLATEBTN then
			self:TranslateElseMap(curNodeData._data.TransID)
		end
	else--跨场景寻路 
		
		--跨服判断
		if game._HostPlayer:IsInGlobalZone() then
	        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
	        return
	    end
		local onReach = function( ... )   
        	self:StopUpdateAutoPathing() 
        	game._HostPlayer:SetAutoPathFlag(false)
        	self._IsAutoPath = false
		end

		self._IsAutoPath = true 
		local targetPos = Vector3.New(self._CurSelectNodeData._data.x,self._CurSelectNodeData._data.y,self._CurSelectNodeData._data.z)
		local isNpc = (curNodeData._NodeType == NodeType.NPC)
		CTransManage.Instance():StartMoveByMapIDAndPos(self._CurMapID, targetPos, onReach, isNpc, false)		
		local isNonstop, regionPos = CTransDataHandler.Instance():IsNonstopTrans(self._CurMapID)
		if isNonstop then
			self:TransMapShow(regionPos)
			self._CurMapID = self._HostPlayerMapID
			self._IsInitMap = false
			self:InitPanel("Map",nil)
		end
	end
end

-- 传送阵 传送
def.method("number").TranslateElseMap = function(self,transID)
	--跨服判断
	if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        return
    end
	if transID <= 0 then return end
    CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
	CTransManage.Instance():TransToPortalTargetByTransID(transID)
	self: ClosePanel() 
--	if game._HostPlayer:InImmediate() or game._HostPlayer:InPharse() then 
--		local callback = function(value)
--			local hp = game._HostPlayer
--			if value then
--				CQuestAutoMan.Instance():Stop()
--			   	CDungeonAutoMan.Instance():Stop()
--			   	CAutoFightMan.Instance():Stop()
--				CTransManage.Instance():TransToPortalTargetByTransID(transID)
--				self: ClosePanel() 
--			end
--		end
--		local title, message, closeType = StringTable.GetMsg(82)
--		MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
--	else
--		CQuestAutoMan.Instance():Stop()
--	   	CDungeonAutoMan.Instance():Stop()
--	   	CAutoFightMan.Instance():Stop()
--		CTransManage.Instance():TransToPortalTargetByTransID(transID)
--		self: ClosePanel() 
--	end
end

def.method("table","number","boolean").AddTeamObj = function(self,teamMemPos,ID,isTeamLeader)

	local AddNewTeamObj = function (teamMemPos,ID,isTeamLeader)
		local obj = GameObject.Instantiate(self._Obj_TeamMem)	
		if(obj ~= nil) then
			obj:SetParent(self._Obj_Map)
	    	local posx, posy = GetTruePos(self,teamMemPos.x,teamMemPos.z,true)
			obj.localPosition = Vector3.New(posx,posy,0)
			obj.localScale = Vector3.New(2,2,2)						
			obj:SetActive(true)	
			if not isTeamLeader then
				GUITools.SetGroupImg(obj,1)
			else
				GUITools.SetGroupImg(obj,0)
			end	
			self._TeamMemberTable[ID] = obj
   		end
	end
	if self._TeamMemberTable == nil  then
		self._TeamMemberTable = {}
		-- warn("---ID -------1  ",ID)
		AddNewTeamObj(teamMemPos,ID,isTeamLeader)
	else
		for i,v in pairs(self._TeamMemberTable) do
			if i == ID and v ~= nil then
				v:SetActive(true)
				local posx, posy = GetTruePos(self,teamMemPos.x,teamMemPos.z,true)
				v.localPosition = Vector3.New(posx,posy,0)
				v.localScale = Vector3.New(2,2,2)
				if not isTeamLeader then
					GUITools.SetGroupImg(v,1)
				else
					GUITools.SetGroupImg(v,0)
				end	
				return
			end
		end
		-- warn("---ID ------- 2 ",ID)
		AddNewTeamObj(teamMemPos,ID,isTeamLeader)
	end
end

-- 更新位置信息(个人和队友位置)
def.method().UpdatePlayerPosition = function(self)
	-- body
	if not self._Host_Player then
		warn("find out :_host_Player")
	return end

	if game._HostPlayer == nil then 
		self:StopUpdateMapUI()
	return end

    --个人所在坐标显示，同地图才显示！
    if self._CurMapID == self._HostPlayerMapID then
    	self._Host_Player: SetActive(true)
    	local playerPos = game._HostPlayer:GetPos()	
    	if self._Last_PlayerPos ~= playerPos then 
    		local dir = game._HostPlayer:GetDir()
			local z = math.rad2Deg * math.atan2(dir.z, dir.x)- 90
			self._Host_Player.rotation = Quaternion.Euler(0, 0, z)
			local trueX, trueY = GetTruePos(self,playerPos.x,playerPos.z,true)
    		self._Host_Player.localPosition = Vector3.New(trueX,trueY,0)
    		self._Last_PlayerPos = playerPos
    	end	
    else
   		self._Host_Player: SetActive(false)
   	end	

    -- 队伍成员
    local hostPlayerID = game._HostPlayer._ID
    self._TeamList = CTeamMan.Instance():GetMemberList()
    if((self._TeamList ~= nil) or (table.nums(self._TeamList) > 0)) then
    	local obj = nil
    	-- warn(" self._TeamList ",#self._TeamList)
    	for i,teamMemeber in pairs(self._TeamList) do 
    		if teamMemeber ~= nil and teamMemeber._ID ~= hostPlayerID then
				if(teamMemeber._IsOnLine) then 
					local teamMemPos = CTeamMan.Instance():GetMemberPositionInfo(teamMemeber._ID)
					local isTeamLeader = CTeamMan.Instance():IsTeamLeaderById(teamMemeber._ID)
					if teamMemPos ~= nil then
    					if(teamMemPos.MapId == self._CurMapID) then
          	   				self:AddTeamObj(teamMemPos.Position,teamMemeber._ID,isTeamLeader)
          	   			else
          	   				if self._TeamMemberTable == nil then return end
          	   				if(self._TeamMemberTable[teamMemeber._ID] ~= nil) then
          	   					self._TeamMemberTable[teamMemeber._ID]:SetActive(false)
    						end
          	   			end 
    				else
    					if self._TeamMemberTable == nil then return end
    					if(self._TeamMemberTable[teamMemeber._ID] ~= nil) then
    						self._TeamMemberTable[teamMemeber._ID]: Destroy()
    						self._TeamMemberTable[teamMemeber._ID] = nil
    					end
    				end
    			end
    		end
    	end
    end 
    -- 检查之前数组有没有非法队员
    self: CheckTeamMem()
end

def.method().CheckTeamMem = function(self)
  
  if((self._TeamMemberTable == nil) or (table.nums(self._TeamMemberTable) <= 0)) then return end

  for i,v in pairs(self._TeamMemberTable) do
  	   if(v ~= nil) then
  	      	if (not self: IsHaveTeamMem(i)) then
           		v:Destroy()
           		v = nil
  		  	end 
  	   end
  end
end

def.method("number","=>","boolean").IsHaveTeamMem = function (self, key)
	if((self._TeamList == nil) or (table.nums(self._TeamList) <= 0)) then return false end
	
	for i,v in pairs(self._TeamList) do
		if(v._ID == key) then return true end	
	end	

	return false 
end

def.method("number").ChangeWorldAndRegionMap = function (self,mapType)
	if mapType == MapType.REGION then 
    	if not self._IsCheckRegionMap then
	    	if self._CurMapID ~= self._HostPlayerMapID then
	    		self._CurMapID = self._HostPlayerMapID
	    		self._IsInitMap = false
	    	end
	    end
  	    self._CurMapType = MapType.WORLD
		SetPageToggle(self ,false) 

		self:InitPanel("WorldMap",nil)
	elseif mapType == MapType.WORLD then 
		if not self._IsCheckRegionMap then
  	    	if self._CurMapID ~= self._HostPlayerMapID then
  	    		self._CurMapID = self._HostPlayerMapID
  	    		self._IsInitMap = false
  	    	end
  	    end
		self:InitPanel("Map",nil) 
  		SetPageToggle(self ,true) 
  		self._CurMapType = MapType.REGION
	end
end

def.method().ClosePanel = function (self)

	self: StopUpdateMapUI()
	self._IsUpdateMap = false
	game._GUIMan:CloseByScript(self)
	-- warn("--- CPanelMap ------- OnHide  ",debug.traceback())

   
    if((self._TeamMemberTable ~= nil) and (table.nums(self._TeamMemberTable) > 0)) then
 		for i,v in pairs(self._TeamMemberTable) do
 			v: Destroy()
 		end 		
 		self._TeamMemberTable = nil
    end  
end

def.method().ClearAllPathObj = function(self)	
	if not IsNil(self._Obj_AutoPosFinal) then
		self._Obj_AutoPosFinal: SetActive(false)
	end
	if((Table_Path_Obj == nil) or (table.nums(Table_Path_Obj) <= 0)) then return end
	for _,v in pairs(Table_Path_Obj) do
		v:Destroy()
	end	
	Table_Path_Obj = nil
end

def.method().HideAllPathObj = function(self)
	if not IsNil(self._Obj_AutoPosFinal) then
		self._Obj_AutoPosFinal: SetActive(false)
	end

	if Table_Path_Obj ~= nil and table.nums(Table_Path_Obj) > 0 then
		for _,v in pairs(Table_Path_Obj) do
			v:SetActive(false)
		end	
	end
end

def.method("=>","number").GetUpdateDeltaTime = function(self)
	if Table_Paths_Points == nil or #Table_Paths_Points <= 0 then return 2.5 end
	local cur_pos = game._HostPlayer:GetPos()
	local disPos = nil 
	if game._HostPlayer._NavTargetPos ~= nil then 
		disPos =  GameUtil.GetNavDistOfTwoPoint(cur_pos, game._HostPlayer._NavTargetPos) 
		if disPos == 0 then 
			disPos =  GameUtil.GetNavDistOfTwoPoint(cur_pos, GameUtil.GetCurrentTargetPos()) 
		end 
	else
		local destPos = CDungeonAutoMan.Instance():GetGoalPos()
		if destPos == nil or destPos.class ~= "Vector3" then
			disPos = 0
		else
			disPos =  GameUtil.GetNavDistOfTwoPoint(cur_pos, CDungeonAutoMan.Instance():GetGoalPos())
		end 
	end
	local speed =  game._HostPlayer:GetMoveSpeed()
	local nDetlaTime = (disPos /speed) /(#Table_Paths_Points - 1)
	return nDetlaTime
end

--Debug 快捷移动 
def.method("number","number","number","=>","boolean").DebugJumpping = function(self, mapID, x, z)
    if GameUtil.DebugKey("left ctrl") then
        local cmdstr="c 81 "..mapID.." ".. math.round(x).. " ".. math.round(z)
        warn("Debug : "..cmdstr)
        game:DebugString(cmdstr)
        self:ClosePanel()
        return true
    end
    return false
end

def.override("userdata").OnPointerClick = function(self,target)
	if not target then return end	
	if target.name ~= "Img_Map" then return end
	if self._Page ~= 0 then return end	

  	local clickPos = GameUtil.GetScreenPosToTargetPos(target)
  	
  	if clickPos == nil then return end
  	local trueX, trueY = GetTruePos(self,clickPos.x, clickPos.y,false)
   	local PointerPos = Vector3.New(trueX, 0, trueY)
   	PointerPos.y = GameUtil.GetMapHeight(clickPos)  

   	if PointerPos == nil then return end
   	
   	if not CTransDataHandler.Instance():CheckMoveToTargetPosResult(self._CurMapID,PointerPos)  then 
   		game._GUIMan: ShowTipText(StringTable.Get(12012),false)
   		return
   	end
   	if not IsNil(self._Obj_AutoPosFinal) then
		self._Obj_AutoPosFinal: SetActive(false)
	end

    --Debug 快捷移动 
    if not self:DebugJumpping(self._CurMapID,trueX,trueY) then
    	CTransManage.Instance():BrokenTrans()
	   	CQuestAutoMan.Instance():Stop()
	   	CDungeonAutoMan.Instance():Stop()
	   	CAutoFightMan.Instance():Stop()

   	    if self._CurMapID == self._HostPlayerMapID and game._HostPlayer:CanMove() then
            self:AutoPathingToTarget(PointerPos.x,PointerPos.y,PointerPos.z,false)
	    else
		    local onReach = function( ... )   
        	    self: StopUpdateAutoPathing() 
        	    game._HostPlayer:SetAutoPathFlag(false)
        	    self._IsAutoPath = false
        	    self._Obj_AutoPosFinal:SetActive(false)
		    end

		    self._IsAutoPath = true 		
		    --跨服判断
			if game._HostPlayer:IsInGlobalZone() then
		        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
		        return
		    end
		    CTransManage.Instance():StartMoveByMapIDAndPos(self._CurMapID, PointerPos, onReach, false, false)
		    local isNonstop, regionPos = CTransDataHandler.Instance():IsNonstopTrans(self._CurMapID)
		    if isNonstop then
			    self: TransMapShow(regionPos)	
		    end	

		    self:ChangeWorldAndRegionMap(MapType.WORLD)
	    end      
    end
end

--寻路点(是否是玩家所在地图)
def.method("table","boolean").SetAutoPathTable = function(self,TargetPos,IsHostPlayerMapID)
	Table_Paths_Points = {}
	
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	local cur_pos = {}
	if not  IsHostPlayerMapID then 
		local isNonstop,pos = CTransDataHandler.Instance():GetMapJoinPoint(self._CurMapID,nCurMapID)
		nCurMapID = self._CurMapID
		if isNonstop then 
			cur_pos = pos
		end
	else
		cur_pos = game._HostPlayer:GetPos() 
	end
	local navmeshName = MapBasicConfig.GetNavmeshName(nCurMapID)
	if navmeshName == nil then return end
	local path_table = GameUtil.GetAllPointsInNavMesh(navmeshName, cur_pos, TargetPos, 1, 0.1)

	if(path_table == nil) or (table.nums(path_table) <= 0) then 
		TargetPos = GameUtil.GetCurrentTargetPos()
		path_table = GameUtil.GetAllPointsInNavMesh(navmeshName, cur_pos, TargetPos, 1, 0.1)
		if(path_table == nil) or (table.nums(path_table) <= 0) then warn(" (path_table == nil) or (table.nums(path_table) <= 0) ") return end
	end
	local point_count = #path_table
   	for i = 1, point_count, 1 do       
        if(i == point_count) then
            Table_Paths_Points[#Table_Paths_Points + 1] = Vector3.New(path_table[i].x,path_table[i].z,0)           
        else
            local _, detla = math.modf(i/ 11)
			if(detla == 0) then
				Table_Paths_Points[#Table_Paths_Points + 1] = Vector3.New(path_table[i].x,path_table[i].z,0)   						
    		end
        end 
    end 
end 

--显示寻路点，并且进行寻路操作
def.method("number","number","number","boolean").AutoPathingToTarget = function(self, posx, posy, posz, bSearchEntity)
    --正在寻路的，需要打断
  	if self._IsAutoPath then
    	self: StopUpdateAutoPathing()
    	game._HostPlayer:SetAutoPathFlag(false)
    	self._IsAutoPath = false
    end

    -- 此处不能调用Stand，如果角色处于技能中，会影响影响动作表现  -added by lijian
	--hp:Stand() 

    local V3pos = Vector3.New(posx, posy, posz)
    if CTransDataHandler.Instance():CanMoveToTargetPos(self._CurMapID, V3pos) then
     	self:SetAutoPathTable(V3pos,true)
	else
		local movePos = CTransManage.Instance():GetForceTransDestPos(self._CurMapID, V3pos)
		if movePos ~= nil then 
			self:SetAutoPathTable(movePos,true)
        else
            self:SetAutoPathTable(V3pos,true)
        end
	end
    if(Table_Paths_Points == nil) or (#Table_Paths_Points <= 0) then warn("=========#Table_Paths_Points==============" ,#Table_Paths_Points) return end 

  	PointerClickTargetPos = V3pos
	self._IsAutoPath = true 
	game._HostPlayer:SetAutoPathFlag(true)
    local onReach = function()
        self:StopUpdateAutoPathing() 
        self._IsAutoPath = false
        game._HostPlayer:SetAutoPathFlag(false)	  
    end

	CTransManage.Instance():StartMoveByMapIDAndPos(self._CurMapID, V3pos, onReach, bSearchEntity, false)
	
	-- 备注：StartMoveByMapIDAndPos存在条件不满足，无法移动的情况，此时以下逻辑就不该调用
    local hp = game._HostPlayer
	if hp:CheckAutoHorse(V3pos) then 
    	--寻路自动上马逻辑
		hp:NavMountHorseLogic(V3pos)	
    end 

    self:OnlyShowAutoPathing(true)	
end

def.method().AddAutoPathObj = function(self)
	if not self:IsShow() then  return end
	local AddNewAutoPathObj = function (index)
		local point_count = #Table_Paths_Points
    	for i = index, point_count, 1 do
	    	local obj = nil
	        if(i == point_count) then
	            obj = GameObject.Instantiate(self._Obj_AutoPosFinal)	         		
	        else 
			    obj  = GameObject.Instantiate(self._Obj_AutoPos)
	        end 
	        if(obj ~= nil) then
				obj:SetParent(self._Obj_Paths)
				if Table_Paths_Points[i] == nil then 
					self:HideAllPathObj()
					return 
				end
				local trueX,trueY = GetTruePos(self,Table_Paths_Points[i].x, Table_Paths_Points[i].y, true)
				obj.localPosition = Vector3.New(trueX, trueY,0)
	   			obj.localScale = Vector3.one 						
	   			obj:SetActive(true)
	   			Table_Path_Obj[#Table_Path_Obj + 1] = obj	
	    	end 
		end	
	end
	if Table_Path_Obj == nil or #Table_Path_Obj <= 0 then
		Table_Path_Obj = {}
		AddNewAutoPathObj(1)
	else	
		if #Table_Path_Obj >= #Table_Paths_Points then 
			for i,v in ipairs(Table_Path_Obj) do
				if not v.activeSelf then
					if i < #Table_Paths_Points then
						v: SetActive(true)
						local trueX,trueY = GetTruePos(self,Table_Paths_Points[i].x, Table_Paths_Points[i].y, true)
						v.localPosition = Vector3.New(trueX, trueY,0)
			   			v.localScale = Vector3.one
			   		elseif i == #Table_Paths_Points then
			   			local finalObj = Table_Path_Obj[#Table_Path_Obj]
			   			finalObj: SetActive(true)
			   			local trueX,trueY = GetTruePos(self,Table_Paths_Points[i].x, Table_Paths_Points[i].y, true)
						finalObj.localPosition = Vector3.New(trueX, trueY,0)
			   			finalObj.localScale = Vector3.one
			   		elseif i > #Table_Paths_Points then
			   			v: SetActive(false)
			   		end 
				end
			end
		else
			table.remove(Table_Path_Obj,#Table_Path_Obj)
			for i,v in ipairs(Table_Path_Obj) do
				if v == nil then return end
				if not v.activeSelf then		
					v: SetActive(true)
					local trueX,trueY = GetTruePos(self,Table_Paths_Points[i].x, Table_Paths_Points[i].y, true)
					v.localPosition = Vector3.New(trueX, trueY,0)
		   			v.localScale = Vector3.one
				end
			end
			local index = 1 
			if #Table_Path_Obj > 0 then 
				index = #Table_Path_Obj
			end
			AddNewAutoPathObj(index)
		end	
	end
end
--仅仅显示寻路点(是否更新寻路点)
def.method("boolean").OnlyShowAutoPathing = function(self,IsUpdatePathing)
	
	self:HideAllPathObj()
   	if(Table_Paths_Points == nil) or (#Table_Paths_Points <= 0) then   return end 
    if not IsUpdatePathing then
   		self:AddAutoPathObj()
   	else
   		local cur_pos = game._HostPlayer:GetPos()
   		table.insert(Table_Paths_Points,1,cur_pos)--从玩家当前坐标开始显示
   		self:AddAutoPathObj()
   		local nTime = self: GetUpdateDeltaTime()
   		self:BeginUpdateAutoPathing(nTime)
   	end
end


def.method().ChangeAutoPathing = function(self)
	if(not game._HostPlayer._IsAutoPathing) or (Table_Paths_Points == nil) or (#Table_Paths_Points <= 0) then return end

	self:OnlyShowAutoPathing(true)
end

def.method('number','number','number' ,"=>","table").GetItemDataFormTable = function(self,itemType,itemID,itemIdex)
	-- NPC
	if(itemType == 1) then
		for i,v in pairs(self._Table_AllNpc) do
			if (i == itemID) then
				if (v ~= nil) then
				  return v[itemIdex]
				end				
			end
		end
     --Monster
	elseif (itemType == 2) then
		for i,v in pairs(self._Table_AllMonsters) do
			if (i == itemID) then
				if (v ~= nil) then
				  return v[itemIdex]
				end		
			end			
		end
	--区域
	elseif (itemType == 3) then
		for i,v in pairs(self._Table_AllRegion) do
			if (i == itemID) then
				if (v ~= nil) then
				  return v[itemIdex]
				end
			end
		end
	end

	return nil
end
-- def.virtual("string", "number").OnScaleChanged = function(self, id, value)
-- 	if id == 
-- end

def.method().UpdateMapBossState = function(self)
	if Table_BossImgObj ~= nil then
		for i = #Table_BossImgObj, 1, -1 do
			local v = Table_BossImgObj[i]
			if not IsNil(v) then
				local BossID = string.sub(v.name, string.len("Btn_Boss")+1,-1)
				local bossBtnBg = self._MonsterIconList:FindChild("Btn_Boss"..BossID.."/Img_Boss")
				if game._CWorldBossMan:GetWorldBossByID(tonumber(BossID)) then
					local WorldBossData = game._CWorldBossMan:GetWorldBossByID(tonumber(BossID))
					if WorldBossData._Isopen and not WorldBossData._IsDeath then
						GUITools.MakeBtnBgGray(bossBtnBg, false)
					else
						GUITools.MakeBtnBgGray(bossBtnBg, true)
					end	

				elseif game._CWorldBossMan:GetEliteBossByID(tonumber(BossID)) then
					local EliteBossData = game._CWorldBossMan:GetEliteBossByID(tonumber(BossID))
					if not EliteBossData._IsDeath then
						GUITools.MakeBtnBgGray(bossBtnBg, false)
					else
						GUITools.MakeBtnBgGray(bossBtnBg, true)
					end	
				end
			end
		end
	end

end

--跨地图路径点UI显示
def.method("table").TransMapShow = function(self,TargetPos)
	if not self._IsAutoPath then return end
	if TargetPos == nil then return end 
 	self: HideAllPathObj() 
	self:SetAutoPathTable(TargetPos,true)
	PointerClickTargetPos = TargetPos
	self: OnlyShowAutoPathing(true)	 
 	game._HostPlayer:SetAutoPathFlag(true)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	ClearTable(self)
	-- CGame.EventManager:removeHandler(CombatStateChangeEvent, OnCombatStateChangeEvent)
 	CGame.EventManager:removeHandler(ContinueTransEvent, OnContinueTransEvent)
	self._Last_PlayerPos = nil
	self: ClearAllPathObj()
	self:ClosePanel()
	-- self: StopUpdateMapUI()
	self: StopUpdateAutoPathing()
	self._IsCheckRegionMap = false

	self._MonsterNodeObjs = {}
	self._NpcNodeObjs = {} 
	self._ReputationNPCData = {}
	self._CurNpcNodeIndex = 0
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Close_Map, 0)
end

def.override().OnDestroy = function (self)
	ClearTable(self)
	PointerClickTargetPos = nil
	
	if Table_Path_Obj ~= nil and table.nums(Table_Path_Obj) > 0 then 
		for _,v in pairs(Table_Path_Obj) do
			v:Destroy()
		end	
	end

	Table_NpcObj = {}
	Table_RegionImgObj = {}
	Table_RegionNameObj = {}
	Table_BossImgObj = {}
	Table_ReputationImgObj = {}
	Table_EyeDungeonEntranceImgObj = {}
	Table_Path_Obj = nil

	self._Frame_WorldMap = nil
	self._Frame_Map = nil
	self._Host_Player = nil
	self._Obj_World_Player_Head = nil
	self._Obj_World_Player_Host = nil
	self._Img_Map = nil
	self._Obj_Map = nil
	self._NpcIconList = nil 
	self._MonsterIconList = nil 
	self._Obj_WorldMap = nil
	self._Obj_BOSS = nil
	self._Obj_Npc = nil
	self._Obj_Transfer = nil
	self._Obj_EyeRegion = nil
	self._Obj_Region_Name = nil
	self._Obj_AutoPos = nil
	self._Obj_AutoPosFinal = nil
	self._Obj_Dungeon = nil
	self._Obj_TeamMem = nil
	self._Obj_Paths = nil
	self._Obj_RegionGroup = nil
	self._EyeSingleList = nil 
	self._EyeMultiplayerList = nil 
	self._Btn_TransIcon = nil
	self._ObjMenu = nil
	self._FrameList = nil
	self._BeforeLocationObj = nil
	self._Lab_EyeRegionCount = nil
	self._Btn_EyeRegionCount = nil
	self._FrameTip = nil 
	self._BtnToggle = nil
	self._MonsterNodeObjs = {}
	self._NpcNodeObjs = {} 
	self._CurNpcNodeIndex = 0
	self._ImgTransfer = nil
	self._BtnReputation = nil
end

--请求数据
def.method().SendC2SHawkeyeMapInfo = function(self)
	local C2SHawkeyeMapInfo = require "PB.net".C2SHawkeyeMapInfo
	local protocol = C2SHawkeyeMapInfo()
	protocol.mapID = self._CurMapID
	PBHelper.Send(protocol)
end

CPanelMap.Commit()
return CPanelMap