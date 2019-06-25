local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local MapBasicConfig = require "Data.MapBasicConfig" 
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
local DungeonGoalType = require"PB.data".DungeonGoalType
local CQuest = require"Quest.CQuest"
local CPageQuest = require"GUI.CPageQuest"
local CTransManage = require "Main.CTransManage"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CElementData = require "Data.CElementData"
local CPanelPathDistance = require "GUI.CPanelPathDistance"
local CPanelLoading = require"GUI.CPanelLoading"
local CTransDataHandler = require "Transfer.CTransDataHandler"

local CPath = Lplus.Class("CPath")
local def = CPath.define

def.field("table")._AllPathPoints = BlankTable

def.field("userdata")._TargetObj = nil 
def.field("userdata")._TargetObjFxComps = nil 
def.field("table")._AllPathArrowObjs = BlankTable 

def.field("table")._MapInfo = BlankTable  -- 没用
def.field("userdata")._ParentObj = nil 
def.field("table")._TargetPos = BlankTable 
def.field("number")._ShowPathTimeID = 0   -- 没用
def.field("number")._UpdateDirTimeID = 0  -- 没用
def.field("number")._RhythmTimeID = 0     -- 没用
def.field("number")._MaxPointNumber = 20  
def.field("number")._QuestId = 0
def.field("number")._TotalDistance = 0
def.field("number")._Spacing = 3                 -- 箭头之间的间隔

def.field("number")._ArrowTimerID = 0 
def.field("number")._DistanceTimerID = 0 
def.field("number")._SightRangeShow = 0 
def.field("number")._SightRangeHide = 0
def.field("table")._PanelDistance = nil 
def.field("boolean")._IsKillMonster = false      -- 目标是否杀怪
def.field("number")._LimitDistance = 1           -- 副本目标杀怪后显示路径的限制距离
def.field("boolean")._IsDungeonPath = false
def.field("number")._AsyncLoadObjNum = 0         -- 异步加载数量
def.field("boolean")._IsSkillMoving = false

local instance = nil
def.static("=>", CPath).Instance = function ()
    if instance == nil then
		instance = CPath()
    end
	return instance
end

-- 技能位移控制(需要设置 状态)
local function ControlPathBySkillMoving(self)
	if not self._IsSkillMoving and game._HostPlayer:IsSkillMoving() then 
		self:SkillPause()
	elseif self._IsSkillMoving and not game._HostPlayer:IsSkillMoving() then 
		self:SkillRestart()
	end
end

local function InstantiateObject(self,i,pos)
 	if self._AllPathPoints == nil or (#self._AllPathPoints < i+1) then return end
 	
 	local obj = Object.Instantiate(_G.PathArrowTemplate)
	local dir = Vector3.New(self._AllPathPoints[i+1].x - self._AllPathPoints[i].x,0,self._AllPathPoints[i+1].z - self._AllPathPoints[i].z)
	if obj ~= nil then
		GameUtil.SetLayerRecursively(obj, EnumDef.RenderLayer.Fx)
		obj:SetActive(true)
		pos.y = pos.y
		obj.localPosition = pos
		obj.forward = dir
		obj:SetParent(self._ParentObj)
		self._AllPathArrowObjs[#self._AllPathArrowObjs + 1] = obj	
	end 
	self._AsyncLoadObjNum = self._AsyncLoadObjNum + 1
end

local function AddNewArrowPathObj(self,index) 
	local point_count = #self._AllPathPoints - 1
	for i = index, point_count, 1 do
    	local pos = self._AllPathPoints[i]
        pos.y = GameUtil.GetMapHeight(self._AllPathPoints[i])
		InstantiateObject(self,i,pos)
	end	
end

def.method().Init = function(self)
	if self._ParentObj == nil then 
		self._ParentObj = GameObject.New("PathFx")
	end
end

-- 创建箭头 显示距离目标点位置(依据副本目标是否为空来判断走哪种寻路 计时副本和相位有可能提供目标为空走的大世界寻路)
def.method("table").ShowPath = function (self,TargetPos)
	-- warn(" ---ShowPat--- ",debug.traceback())
	self._TargetPos = TargetPos
	if self._TargetPos == nil then return end
	local dungeonGoal = game._DungeonMan: GetDungeonGoal()

	if dungeonGoal ~= nil then 	
		self._IsDungeonPath = true
		self._IsKillMonster = false
		if dungeonGoal.GoalType == DungeonGoalType.EDUNGEONGOAL_KILLMONSTER then 
			self._IsKillMonster = true
		end
		self:ShowPathInDungeon()
	else 
		self._IsDungeonPath = false
		self:ShowPathInWorld()
	end
end
----------------------------------- 大世界自动寻路 ------------------------------

--得到寻路点(间隔不能更改 对应 平均0.5秒删掉一个点)
local function GetAutoPathPoint(self,curDistance)
	self._AllPathPoints = {}
	-- warn("game._HostPlayer._IsAutoPathing ",game._HostPlayer._IsAutoPathing) 
	local spacingDistance = curDistance + self._Spacing

	while spacingDistance < self._TotalDistance do
		local point = GameUtil.GetPointInPath(spacingDistance)
		if point == nil then self._AllPathPoints = {} return end
		spacingDistance = spacingDistance + self._Spacing
		self._AllPathPoints[#self._AllPathPoints + 1] = point
		if #self._AllPathPoints >= self._MaxPointNumber then
		return end
	end
end 

def.method().ShowPathInWorld = function(self)
	local curPos = game._HostPlayer:GetPos()
	self._TotalDistance = GameUtil.GetNavDistOfTwoPoint(curPos,self._TargetPos)
	-- 区域寻路 若所配点无法到达 底层将转换目标点
	if self._TotalDistance == 0 then 
		self._TargetPos = GameUtil.GetCurrentTargetPos()
		self._TotalDistance = GameUtil.GetNavDistOfTwoPoint(curPos,self._TargetPos)
	end
	if self._TotalDistance > 1 then 
		self:UpdatePathInWorld()
		local param = 
				    {
				    	Value = self._TotalDistance,
				    	Position = nil,
					}	
		if self._PanelDistance == nil or not CPanelPathDistance.Instance():IsShow() then
			self._PanelDistance = game._GUIMan:Open("CPanelPathDistance", param)
		end
		self:UpdateDistancePanelInWorld()
	else
		self:HideTargetFxAndDistance()
	end
end

def.method().UpdatePathInWorld = function (self)
	self:HidePathArrow()

	local PassDistance = 0
	local LastDistance = 0
	local callback = function () 
		if self._ParentObj == nil then return warn("self._ParentObj = nil") end
		if not CPanelLoading.Instance():IsShow() then 

			local targetPos = GameUtil.GetCurrentTargetPos()
			if targetPos == nil then
				-- warn(" 193 targetPos  is  nil ")
			 	return 
			else
				if self._TargetPos == nil then self:Hide() return end
				if Vector3.DistanceH(self._TargetPos,targetPos) > 0.1 then 
					-- warn("198 Vector3.DistanceH(self._TargetPos,targetPos)" ,Vector3.DistanceH(self._TargetPos,targetPos))
					self:Hide() 
			 		return
			 	end 
			end
			ControlPathBySkillMoving(self)
			if not game._HostPlayer:IsSkillMoving() then 
				PassDistance = GameUtil.GetCurrentCompleteDistance()
				if PassDistance < 1 then 
					LastDistance = PassDistance 
				end
				-- 四舍五入
				local destroyNum = math.floor((PassDistance - LastDistance) /self._Spacing + 0.5)
				local distance = self._TotalDistance - PassDistance
				if distance > 0  then
					GetAutoPathPoint(self,PassDistance)
					self:SetAutoPathArrowObj(destroyNum)
					self:ShowTargetFx()
					LastDistance = LastDistance + self._Spacing * destroyNum
				else
					warn("212 distance < 0 ")
				end
			end
		end
	end
	self._ArrowTimerID = _G.AddGlobalTimer(0.1, false, callback)  
end

-- 控制自动寻路中的箭头显隐
def.method("number").SetAutoPathArrowObj = function(self,destroyNum)
	if destroyNum ~= 0 and #self._AllPathArrowObjs >= destroyNum then 
		for i = 1 , destroyNum do
			local obj = self._AllPathArrowObjs[1]
			obj:SetActive(false)
			table.remove(self._AllPathArrowObjs, 1)
			table.insert(self._AllPathArrowObjs, obj)
		end
	end
   	if #self._AllPathPoints <= 1 then return end 
   	self:AddAutoPathObj()
end

-- 路径最多显示 self._MaxPonitNumber(激活并刷新隐藏掉的Arrow Path Object 符合策划大世界中路径不可闪的需求)
def.method().AddAutoPathObj = function(self)
	if #self._AllPathArrowObjs ~= 0 and self._AsyncLoadObjNum ~= 0 then 
		for i, v in ipairs(self._AllPathArrowObjs) do
			if not v.activeSelf then
    			if #self._AllPathPoints == 0 then  return end
				if i <= #self._AllPathPoints - 1 then
					local pos = self._AllPathPoints[i]
    				pos.y = GameUtil.GetMapHeight(self._AllPathPoints[i])
    				local dir = nil 
					v.localPosition = pos
					v:SetActive(true)

					if self._AllPathPoints[i + 1] ~= nil then
						local dir = Vector3.New(self._AllPathPoints[i+1].x - self._AllPathPoints[i].x,0,self._AllPathPoints[i+1].z - self._AllPathPoints[i].z)
						v.forward = dir
			   		end
		   		end 
			end
		end
		if #self._AllPathArrowObjs < #self._AllPathPoints - 1 and self._AsyncLoadObjNum < #self._AllPathPoints - 1 then
			AddNewArrowPathObj(self, #self._AllPathArrowObjs + 1)
		end
	elseif #self._AllPathArrowObjs == 0 and self._AsyncLoadObjNum == 0 then
		AddNewArrowPathObj(self, #self._AllPathArrowObjs + 1)
	end	
end

-- 每隔1米刷一下距离
def.method().UpdateDistancePanelInWorld = function (self)
	local PassDistance = 0
	local Spacing = 1
	if self._DistanceTimerID > 0 then 
		_G.RemoveGlobalTimer(self._DistanceTimerID)
		self._DistanceTimerID = 0 
	end
	local callback = function () 
		if self._ParentObj == nil then return end
		if self._TargetPos == nil then return end
		
		ControlPathBySkillMoving(self)
		if not game._HostPlayer:IsSkillMoving() then 
			PassDistance = GameUtil.GetCurrentCompleteDistance()
			local distance = self._TotalDistance - PassDistance
			local TotalDistance = GameUtil.GetNavDistOfTwoPoint(game._HostPlayer:GetPos(),self._TargetPos)
			if TotalDistance == 0 then 
				self:HideTargetFxAndDistance()
			return end
			if CPanelPathDistance.Instance():IsShow() and distance >= 0 then 
				local param = 
					    {
					    	Value = distance,
					    	Position = nil,
						}
				self._PanelDistance:UpdateData(param)
			end
		end
	end
	self._DistanceTimerID = _G.AddGlobalTimer(0.1, false, callback)  
end

-- 大世界中玩家位移技能打断寻路
def.method().SkillPause = function (self)
	self._IsSkillMoving = true
	if self._PanelDistance ~= nil then 
		self._PanelDistance:Clear()
	end
	if self._TargetObj == nil then return end
	self._TargetObjFxComps:Stop()

	self._AllPathPoints = {}
	if self._AllPathArrowObjs == nil or #self._AllPathArrowObjs == 0 then return end
	for i,v in ipairs(self._AllPathArrowObjs) do
		if v.activeSelf then 
			v:SetActive(false)
		end
	end
end

-- 大世界中玩家位移技能播放完后恢复路径显示
def.method().SkillRestart = function (self)
	self._IsSkillMoving = false
	if self._DistanceTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._DistanceTimerID)
		self._DistanceTimerID = 0
	end
	if self._ArrowTimerID ~= 0 then 
		_G.RemoveGlobalTimer(self._ArrowTimerID)
		self._ArrowTimerID = 0
	end
	self:ShowPath(self._TargetPos)
end

--------------------------------- 大世界自动寻路End -----------------------------
---------------------------------- 副本自动寻路Start ----------------------------

--自动寻路点
local function GetPathPoint(self)
	self._AllPathPoints = {}
	local cur_pos = game._HostPlayer:GetPos() 
	local nCurMapID = game._CurWorld._WorldInfo.MapTid 
	local navmeshName = MapBasicConfig.GetNavmeshName(nCurMapID)
	if navmeshName == nil then return end
	local path_table = GameUtil.GetAllPointsInNavMesh(navmeshName, cur_pos, self._TargetPos, 1, 0.1)
	if(path_table == nil) or (table.nums(path_table) <= 0) then print("path_table is nil") return end
	
	local point_count = #path_table
	local pointNumber = 0
   	for i = 1, point_count, 1 do       
        local _, detla = math.modf(i/3)
       
		if(detla == 0) then
			self._AllPathPoints[#self._AllPathPoints+ 1] = Vector3.New(path_table[i].x,path_table[i].y,path_table[i].z)   						
			pointNumber = pointNumber + 1
		end
        if pointNumber >= self._MaxPointNumber + 1 then 
        	return
        end
    end 
end 

--副本中需要检测距离目标点的距离(目标为杀怪)
local function CheckDistanceInDungeon(self)
	if self._TargetPos == nil then
		warn("Target Pos is nil")
		return 1000, false
	end
	local curPos = game._HostPlayer:GetPos()
	local distance =  GameUtil.GetNavDistOfTwoPoint(curPos,self._TargetPos) 
	if self._IsKillMonster then 
		if distance <= self._LimitDistance then 
			-- warn("-------------杀怪的距离 小于设定距离-------------",distance)
			return distance, false
		else
			return distance, true
		end
	end
	return distance,true
end

--检查仇恨列表的头目 世界boss
local function CheckDungeonMonsterType()
	local EntityIdList = game._HostPlayer:GetHatedEntityList()
	if #EntityIdList == 0 then return true end
	for i,entityId in ipairs(EntityIdList) do 
		local entity = game._CurWorld:FindObject(entityId)
		if entity ~= nil and entity:IsMonster() then
			if entity._MonsterTemplate.MonsterQuality == EMonsterQuality.LEADER or entity._MonsterTemplate.MonsterQuality == EMonsterQuality.MACHINE then 
				return false
			end
		end
	end
	return true
end

-- 每隔一秒获取一次路径点 
def.method().ShowPathInDungeon = function(self)
	-- warn("------------------------------更换目标--------------------------------------",)
	if self._ArrowTimerID ~= 0 then 
		_G.RemoveGlobalTimer(self._ArrowTimerID)
		self._ArrowTimerID = 0
	end
	local distance, isShowPath = CheckDistanceInDungeon(self)
	if not isShowPath then return end
	GetPathPoint(self)
	self:UpdatePathInDungeon()
	self:UpdateDistancePanelInDungeon(distance)
	local oldTime = self._Spacing / game._HostPlayer:GetMoveSpeed()
	local starTime = 0
	local callback = function () 
			if self._ParentObj == nil then return end
			starTime = starTime + 0.5
			if not CheckDungeonMonsterType(self) then 
				self:Hide()
				return
			end
			local distance, isShowPath = CheckDistanceInDungeon(self)
			local newTime = self._Spacing / game._HostPlayer:GetMoveSpeed()
			if isShowPath then
				-- 变速
				if newTime ~= oldTime or  starTime >= oldTime then 
					GetPathPoint(self)
					self:UpdatePathInDungeon()
					self:ShowTargetFx()
					starTime = 0
					oldTime = newTime
				end
				self:UpdateDistancePanelInDungeon(distance)
			else
				self:Hide()
			end
		end
	self._ArrowTimerID = _G.AddGlobalTimer(0.5, false, callback)  
end

def.method("number").UpdateDistancePanelInDungeon = function (self,distance)
	if self._PanelDistance == nil or not CPanelPathDistance.Instance():IsShow() then
		local param = 
				    {
				    	Value = distance,
				    	Position = nil,
					}	
		self._PanelDistance = game._GUIMan:Open("CPanelPathDistance", param)
	elseif CPanelPathDistance.Instance():IsShow() and distance > 0 then 
		local param = 
			    {
			    	Value = distance,
			    	Position = nil,
				}
		self._PanelDistance:UpdateData(param)
	end
end

-- 自动寻路中 （直接更新路径位置）
def.method().UpdatePathInDungeon = function(self)
   	if #self._AllPathPoints == 0 then self:Hide() return end 
   	self:UpdateArrowPathPosition()
end

-- 刷新路径箭头Obj的位置
def.method().UpdateArrowPathPosition = function (self)
	if #self._AllPathArrowObjs >= #self._AllPathPoints - 1 then 
		for i,v in ipairs(self._AllPathArrowObjs) do
			if i <= #self._AllPathPoints - 1 then
				local pos = self._AllPathPoints[i]
				if self._AllPathPoints[i] == nil then return end
				pos.y = GameUtil.GetMapHeight(self._AllPathPoints[i])
				local dir = nil 
				v.localPosition = pos
				v:SetActive(true)
				if self._AllPathPoints[i + 1] == nil then return end
				dir = Vector3.New(self._AllPathPoints[i+1].x - self._AllPathPoints[i].x,0,self._AllPathPoints[i+1].z - self._AllPathPoints[i].z)
				v.forward = dir
	   		elseif i >= #self._AllPathPoints then
                v:SetActive(false)
	   		end 
		end
	elseif #self._AllPathArrowObjs == 0 and self._AsyncLoadObjNum == 0 then 
		AddNewArrowPathObj(self,1)
	elseif #self._AllPathArrowObjs < #self._AllPathPoints - 1 and self._AsyncLoadObjNum < #self._AllPathPoints - 1 then 
		for i,v in ipairs(self._AllPathArrowObjs) do
			local pos = self._AllPathPoints[i]
			if self._AllPathPoints[i] == nil then return end
			pos.y = GameUtil.GetMapHeight(self._AllPathPoints[i])
			local dir = nil 
			v.localPosition = pos
			v:SetActive(true)
			if self._AllPathPoints[i + 1] == nil then return end
			dir = Vector3.New(self._AllPathPoints[i+1].x - self._AllPathPoints[i].x,0,self._AllPathPoints[i+1].z - self._AllPathPoints[i].z)
			v.forward = dir
		end
		AddNewArrowPathObj(self,#self._AllPathArrowObjs + 1)
	end
end

def.method().PausePathDungeon = function(self)
	if not self._IsDungeonPath then return end
	self:HideTargetFxAndDistance()
	self:HidePathArrow()
end

def.method().ReStartPathDungeon = function(self)
	if not self._IsDungeonPath or self._TargetPos == nil then return end
	self:ShowPath(self._TargetPos)
end

---------------------------------- 副本自动寻路End ------------------------------

def.method().ShowTargetFx = function(self)
	if self._TargetObj == nil then
		self._TargetObj = GameUtil.RequestUncachedFx(PATH.Gfx_PathTarget)
		self._TargetObj.name = "PathTarget"
		self._TargetObj:SetParent(self._ParentObj)
		self._TargetObjFxComps = self._TargetObj:GetComponent(ClassType.CFxOne)
	end

	if #self._AllPathPoints <= self._MaxPointNumber and self._TargetPos ~= nil then 
		local posY = GameUtil.GetMapHeight(self._TargetPos)
		self._TargetObj.localPosition = Vector3.New (self._TargetPos.x,posY,self._TargetPos.z)
		self._TargetObjFxComps:Play(-1)
	else
		self._TargetObjFxComps:Stop()
	end
end

-- 消除箭头
def.method().HidePathArrow = function (self)
	if self._ArrowTimerID ~= 0 then 
		_G.RemoveGlobalTimer(self._ArrowTimerID)
		self._ArrowTimerID = 0
	end
	self._AllPathPoints = {}
	if #self._AllPathArrowObjs == 0 then return end
	for i,v in ipairs(self._AllPathArrowObjs) do
		if v.activeSelf then 
			v:SetActive(false)
		end
	end
end

def.method().HideTargetFxAndDistance = function (self)
	if self._DistanceTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._DistanceTimerID)
		self._DistanceTimerID = 0
	end
	if self._PanelDistance ~= nil then 
		self._PanelDistance:Clear()
	end
	if self._TargetObj == nil then return end
	self._TargetObjFxComps:Stop()
end

def.method("=>", "table").GetCurTargetPos = function (self)
	return self._TargetPos
end

-- 寻路中断调用 / 寻路位移中断
def.method().Hide = function (self)
	self:HideTargetFxAndDistance()
	self:HidePathArrow()
	-- warn("----hide------",debug.traceback())
	self._TargetPos = nil
	self._IsSkillMoving = false
end

--断线重连调用
def.method().CleanPathAndData = function (self)
	if self._DistanceTimerID ~= 0 then 
		_G.RemoveGlobalTimer(self._DistanceTimerID)
		self._DistanceTimerID = 0
	end
	if self._ArrowTimerID ~= 0 then 
		_G.RemoveGlobalTimer(self._ArrowTimerID)
		self._ArrowTimerID = 0
	end
	if self._RhythmTimeID ~= 0 then 
		_G.RemoveGlobalTimer(self._RhythmTimeID)
		self._RhythmTimeID = 0
	end
	if self._PanelDistance ~= nil then 
		self._PanelDistance:Clear()
		self._PanelDistance = nil
	end
		
	if self._AllPathArrowObjs ~= nil and #self._AllPathArrowObjs > 0 then 
		for i,v in ipairs(self._AllPathArrowObjs) do
			if v.activeSelf then 
				v:SetActive(false)
			end
		end
	end
	self._IsSkillMoving = false
	self._AllPathPoints = {}
	self._IsDungeonPath = false
	self._TargetObj = nil
	self._TargetObjFxComps = nil
end

CPath.Commit()
return CPath