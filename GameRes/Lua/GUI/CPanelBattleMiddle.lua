
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local ETableStateType = require 'PB.net'.TableState.eTableStateType
local CPanelMainTips = require'GUI.CPanelMainTips'
local CPanelBattleMiddle = Lplus.Extend(CPanelBase, 'CPanelBattleMiddle')
local def = CPanelBattleMiddle.define

def.field("table")._RankData = BlankTable 
def.field("userdata")._ImgGameIcon = nil
def.field("userdata")._LabGameName = nil 
def.field("number")._MyTableId = 0 
def.field("number")._OtherTableId = 0
def.field("number")._HasIconRoleId = 0 
def.field("number")._HasIconIndex = 0

local instance = nil
def.static('=>', CPanelBattleMiddle).Instance = function ()
	if not instance then
        instance = CPanelBattleMiddle()
        instance._PrefabPath = PATH.UI_BattleMiddle
        instance._PanelCloseType = EnumDef.PanelCloseType.None
	end
	return instance
end
 
def.override().OnCreate = function(self)
	self._ImgGameIcon = self:GetUIObject("Img_GameIcon")
	self._LabGameName = self:GetUIObject("Lab_GameName")
end

def.override("dynamic").OnData = function(self, data)
	self._HasIconIndex = 0 
	self._HasIconRoleId = 0
	if data == nil then return end
	GUITools.SetGroupImg(self._ImgGameIcon,data.State - 1)
	if data.State == ETableStateType.Normal then 
		local name = string.format(StringTable.Get(27005),data.Count)
		GUI.SetText(self._LabGameName,name)
		local item = self:GetUIObject("Item"..6)
		GUITools.SetUIActive(item, false)
		self:UpdateRankShow(self._RankData[self._MyTableId])
	elseif data.State == ETableStateType.Finals then
		GUI.SetText(self._LabGameName,StringTable.Get(27006))
		self:UpdateRankShow(self._RankData)
	end
end

def.method("table").UpdateRankShow = function (self,data)
	for i, v in ipairs(data) do 
		local item = self:GetUIObject("Item"..i)
		if item == nil then  return end 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHigh = uiTemplate:GetControl(0)
		local labName = uiTemplate:GetControl(2)
		local imgIcon = uiTemplate:GetControl(3)
		local labScore = uiTemplate:GetControl(4)
		if labName == nil then return end
		GUI.SetText(labName,v.Name)
		GUI.SetText(labScore,tostring(v.Score))
		if self._HasIconRoleId == v.RoleId then 
			GUITools.SetUIActive(imgIcon, true)
			self._HasIconIndex = i
		else
			GUITools.SetUIActive(imgIcon,false)
		end
		if v.RoleId == game._HostPlayer._ID then 
			GUITools.SetUIActive(imgHigh, true)
		else
			GUITools.SetUIActive(imgHigh, false)
		end
	end
end

-- 清零参加决赛玩家的积分 初始化决赛排行数据
def.method("table").InitFinalRankData = function (self,data)
	self._RankData = {}
	self._MyTableId = 0 
	self._OtherTableId = 0
	for i ,v in ipairs(data) do
		self._RankData[#self._RankData + 1]  = {}
		self._RankData[#self._RankData].RoleId = v.RoleId
		self._RankData[#self._RankData].Name = v.Name
		self._RankData[#self._RankData].Score = 0
		self._RankData[#self._RankData].KillNum = v.KillNum
		self._RankData[#self._RankData].Profession = v.Profession
		self._RankData[#self._RankData].Gender = v.Gender
		self._RankData[#self._RankData].CustomImgSet = v.CustomImgSet
		self._RankData[#self._RankData].Time = i
		if i >= 6 then return end
	end
end

def.method("=>","table").GetRankData = function (self)
	return self._RankData
end

def.method().ClearRankData = function (self)
	self._RankData = nil
end

def.override().OnDestroy = function(self)
	self._LabGameName = nil
	self._ImgGameIcon = nil
end

-- 按照积分降序当积分相同时(先到排到前面)后来者居上
local function sortfunction(item1,item2)
	if item1.Score ~= item2.Score then 
		return item1.Score > item2.Score
	else
		if item1.Time < item2.Time then 
			return true
		elseif item1.Time > item2.Time then 
			return false
		else
			return false
		end
	end
end  

-- 初始化玩家排行数据(初始积分相同)
def.method("table").InitRankData = function (self,roleList)
	self._RankData = {}
	local tableId1,tableId2 = 0,0
	self._MyTableId = 0 
	self._OtherTableId = 0 
	for i,v in ipairs(roleList) do 
		if self._RankData[v.TableId] == nil then 
			self._RankData[v.TableId] = {}
		end
		if i == 1 then 
			tableId1 = v.TableId
		end
		if tableId1 ~= 0 and tableId2 == 0 and tableId1~= v.TableId then 
			tableId2 = v.TableId
		end
		if self._MyTableId == 0 and  v.RoleId == game._HostPlayer._ID then 
			self._MyTableId = v.TableId
		end
		self._RankData[v.TableId][#self._RankData[v.TableId] + 1]  = {}
		self._RankData[v.TableId][#self._RankData[v.TableId]].RoleId = v.RoleId
		self._RankData[v.TableId][#self._RankData[v.TableId]].Name = v.Name
		self._RankData[v.TableId][#self._RankData[v.TableId]].Score = v.Score
		self._RankData[v.TableId][#self._RankData[v.TableId]].KillNum = 0
		self._RankData[v.TableId][#self._RankData[v.TableId]].Profession = v.Profession
		self._RankData[v.TableId][#self._RankData[v.TableId]].Gender = v.Gender
		self._RankData[v.TableId][#self._RankData[v.TableId]].CustomImgSet = v.CustomImgSet
		if  v.ScoreUpdatTime == nil and v.Rank == nil  then  
			self._RankData[v.TableId][#self._RankData[v.TableId]].Time = i
		elseif v.ScoreUpdatTime ~= nil then
			self._RankData[v.TableId][#self._RankData[v.TableId]].Time = v.ScoreUpdatTime
		elseif v.Rank ~= nil then 
			self._RankData[v.TableId][#self._RankData[v.TableId]].Time = v.Rank
		end
	end
	if tableId1 ~= self._MyTableId then 
		self._OtherTableId = tableId1 
	elseif tableId2 ~= self._MyTableId then
		self._OtherTableId = tableId2
	end
end

-- 下线重连后重新初始化数据
def.method("table","boolean").ReconnectionInitData = function (self,data,isOut)
	if not isOut and  data.EliminateTS.State == ETableStateType.Normal then 
		self:InitRankData(data.Infos)
		table.sort(self._RankData[self._MyTableId],sortfunction)
	elseif not isOut and data.EliminateTS.State == ETableStateType.Finals then	
		self._RankData = {}
		-- 决赛的台子id是3 
		for i ,v in ipairs(data.Infos) do
			if v.TableId == 3 then
				self._RankData[#self._RankData + 1]  = {}
				self._RankData[#self._RankData].RoleId = v.RoleId
				self._RankData[#self._RankData].Name = v.Name
				self._RankData[#self._RankData].Score = v.Score
				self._RankData[#self._RankData].KillNum = v.KillNum
				self._RankData[#self._RankData].Profession = v.Profession
				self._RankData[#self._RankData].Gender = v.Gender
				self._RankData[#self._RankData].CustomImgSet = v.CustomImgSet
				self._RankData[#self._RankData].Time = v.ScoreUpdatTime
			end
		end
		table.sort(self._RankData,sortfunction)
	elseif isOut then 
		-- 从S2CEliminateReward获取排名数据
		self:InitRankData(data)
		table.sort(self._RankData[self._MyTableId],sortfunction)
	end
end

def.method("number","number","number","number").UpdateRoleData = function (self,roleId,score,killNum,TableId)
	if not game._CArenaMan._IsBattleFinalGame then 
		local data = self._RankData[TableId]
		local isUpdateMyTable = false
		local isUpdateOtherTable = false
		if data == nil then return end
		for i ,v in ipairs(data) do 
			if v.RoleId == roleId and v.Score ~= score then 
				if TableId == self._MyTableId then 
					isUpdateMyTable  = true
				else 
					isUpdateOtherTable = true
				end
				v.Score = score
				v.KillNum = v.KillNum
				v.Time = GameUtil.GetServerTime()
				break
			elseif v.RoleId == roleId and v.Score == score then
				v.KillNum = v.KillNum
				break
			end
		end
		if isUpdateOtherTable then 
			table.sort(self._RankData[self._OtherTableId], sortfunction)
		end
		if not isUpdateMyTable then return end 
		table.sort(self._RankData[self._MyTableId], sortfunction)
		if not self:IsShow() then return end
		self:UpdateRankShow(self._RankData[self._MyTableId])
	else
		local isUpdate = false
		if self._RankData == nil or #self._RankData == 0 then return end
		for i ,v in ipairs(self._RankData) do 
			if v.RoleId == roleId and v.Score ~= score then 
				isUpdate = true
				v.Score = score
				v.KillNum = v.KillNum
				v.Time = GameUtil.GetServerTime()
				break
			elseif v.RoleId == roleId and v.Score == score then
				v.KillNum = v.KillNum
				break
			end
		end
		if not isUpdate then return end 
		table.sort(self._RankData, sortfunction)
		if not self:IsShow() then return end
		self:UpdateRankShow(self._RankData)
	end
end

-- 获取中场结算排行数据 (A组包括主角 B组)
def.method("=>","table","table").GetMidRankData = function (self)
	return self._RankData[self._MyTableId] ,self._RankData[self._OtherTableId]
end

-- 更新持有中心物件的Icon
def.method("number","number").UpdateCenterItemIcon = function (self,TableId,RoleId)
	if not self:IsShow() then return end
	local data = nil 
	if self._MyTableId ~= 0 then 
		if TableId ~= self._MyTableId then return end
		if TableId == self._MyTableId and RoleId == self._HasIconRoleId then return end
		data = self._RankData[self._MyTableId]
	else
		data = self._RankData
	end
	if self._HasIconRoleId ~= 0 then 
		local item = self:GetUIObject("Item"..self._HasIconIndex) 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgIcon = uiTemplate:GetControl(3)
		GUITools.SetUIActive(imgIcon,false)
	end
	self._HasIconRoleId = RoleId
	for i,v in ipairs(data) do 
		if self._HasIconRoleId == v.RoleId then 
			self._HasIconIndex = i
			local item = self:GetUIObject("Item"..self._HasIconIndex) 
			local uiTemplate = item:GetComponent(ClassType.UITemplate)
			local imgIcon = uiTemplate:GetControl(3)
			GUITools.SetUIActive(imgIcon,true)
		end
	end
end

-- 击杀广播
def.method("table").ShowKillTip = function(self,data)
	local KillData = nil 
	local DeathData = nil 
	if self._MyTableId ~= 0 and self._OtherTableId ~= 0 then 
		for i,v in ipairs(self._RankData[self._MyTableId]) do
			if v.RoleId ==  data.KillerId then 
				KillData = v
			elseif v.RoleId == data.DeathRoleId then
				DeathData = v
			end
			if KillData ~= nil and DeathData ~= nil then break end
		end
		if KillData == nil or DeathData == nil then 
			for i,v in ipairs(self._RankData[self._OtherTableId]) do
				if v.RoleId ==  data.KillerId then 
					KillData = v
				elseif v.RoleId == data.DeathRoleId then
					DeathData = v
				end
				if KillData ~= nil and DeathData ~= nil then break end
			end
		end
	elseif self._MyTableId == 0 and self._OtherTableId == 0 then
		for i,v in ipairs(self._RankData) do
			if v.RoleId ==  data.KillerId then 
				KillData = v
			elseif v.RoleId == data.DeathRoleId then
				DeathData = v
			end
			if KillData ~= nil and DeathData ~= nil then break end
		end
	end 
	local PanelData = 
				{
					KillData = KillData,
					DeathData = DeathData,
					HitNum = data.Hit,
				}
	CPanelMainTips.Instance():ShowKillTips(PanelData)
end

CPanelBattleMiddle.Commit()
return CPanelBattleMiddle