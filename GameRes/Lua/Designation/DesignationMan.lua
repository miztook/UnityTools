--[[----------------------------------------------
         		 称号管理器
          				--- by luee 2017.2.10
--------------------------------------------------]]
local Lplus = require "Lplus"
local DesignationMan = Lplus.Class("DesignationMan")
local def = DesignationMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelDesignation = require "GUI.CPanelDesignation"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageProperty = require "GUI.CPageProperty"
local DynamicText = require "Utility.DynamicText"

def.field("number")._CurDesignationID = 0 --当前称号的ID, =0 未装备

--称号链表
def.field("table")._Table_Designations = BlankTable--称号数据，组合好的数据
def.field("table")._Table_RedPoint = BlankTable --小红点信息
def.field("table")._Table_TypeRedPoint = BlankTable --分类红点信息

def.static("=>", DesignationMan).new = function()
   	--LoadAllDesignationData()
    local obj = DesignationMan()
	return obj
end
 
def.method().LoadAllDesignationData = function (self)
	self._Table_Designations = {}
	local allDesignation = GameUtil.GetAllTid("Designation")
	--warn("DesignationCount"..#allDesignation.."!!!!!!!!!!!!!!!!!!!!")

	for _,v in ipairs(allDesignation) do
		if v > 0 then
			local DesignationData = CElementData.GetTemplate("Designation", v)
			if DesignationData ~= nil then
				local ntype = DesignationData.TypeID
				
				if self._Table_Designations[ntype] == nil then
					self._Table_Designations[ntype] = {}
				end

				self._Table_Designations[ntype][#self._Table_Designations[ntype] + 1] =
				{  
					_Data = DesignationData,--模板数据
					_lock = 0,-- 0=锁定 1=解锁 2=当前称号
					_Time = DesignationData.TimeLimit --默认是表里面的时间
				}
			else
				warn("称号数据错误ID："..v)
			end	
		end
	end

	--[[
	for i,v in pairs(self._Table_Designations) do
		for _,k in pairs(v) do
			warn("Data_",k._Data)
		end
	end	
	]]

	self._Table_RedPoint = CRedDotMan.GetModuleDataToUserData("Designation")
	self._Table_TypeRedPoint = CRedDotMan.GetModuleDataToUserData("DesignationType")
end

--获得当前称号
def.method("=>","number").GetCurDesignation = function(self)
	return self._CurDesignationID
end


--获取称号数据
def.method("number","=>","table").GetDesignationDataByID = function(self, nID)
	if nID <= 0 then return nil end

	local data = CElementData.GetTemplate("Designation", nID)
	return data
end

--获取当前称号string
def.method("=>","string").GetCurDesignationName = function(self)
	local data = self: GetDesignationDataByID(self._CurDesignationID)
	if data == nil or data.Name == nil then
		return ""
	end

	return "<color="..data.ColorRGB..">" ..data.Name.."</color>"
end

--通过ID，获取称号名称，带颜色
def.method("number","=>","string").GetColorDesignationNameByTID = function(self, nID)
	local DataTem = self: GetDesignationDataByID(nID)
	if DataTem ~= nil and DataTem.Name ~= nil then
		return "<color="..DataTem.ColorRGB..">" ..DataTem.Name.."</color>"
	else
		return ""
	end
end

--通过TID获取称号分类
def.method("number","=>","number").GetTypeByTid = function(self, nID)
	for i,v in pairs(self._Table_Designations) do
		for _,k in pairs(v) do
			if k._Data.Id == nID then
				return i
			end
		end
	end

	return -1
end

--上线默认的称号
def.method("number","number").SetCurDesignationID = function(self,nRoleID,nID)
	
	local player = game._HostPlayer
	--玩家自己，处理数据
	if nRoleID == player._ID then		
		self._CurDesignationID = nID
	
		if self._Table_Designations == nil or table.nums(self._Table_Designations) <=0 then
			self:LoadAllDesignationData()
		end
	else
		local table_Player = game._CurWorld._PlayerMan._ObjMap
		if table_Player == nil or table.nums(table_Player) <= 0 then return end

		for _,v in pairs(table_Player) do
			if v._ID == nRoleID then
				player = v
			break
			end
		end
	end
	
	local DataTem = self: GetDesignationDataByID(nID)
	if DataTem ~= nil then 	
		player._InfoData._TitleName = "<color="..DataTem.ColorRGB..">" ..DataTem.Name.."</color>"	
	else
		player._InfoData._TitleName = ""
	end
	player:UpdateTopPate(EnumDef.PateChangeType.TitleName)
end

--排序
def.method().SortTable = function(self)
	local function DesignationSort(item1, item2)
		if item1._lock == item2._lock then
			return item1._Data.Id < item2._Data.Id
		else			
			return item1._lock > item2._lock
		end
	end

	for _,v in pairs(self._Table_Designations) do
		table.sort(v, DesignationSort)
	end
end

--获取所有称号数据
def.method("=>","table").GetAllDesignation = function(self)
	return self._Table_Designations
end

--获取所有称号给的数值加成
def.method("=>","number").GetDesignationFightScore = function(self)	
	local fightScore = 0
	local prop = {}
	for _,v in pairs(self._Table_Designations) do
		for _,k in pairs(v) do
			if k._lock ~= 0 then --获得的称号
				for _,m in ipairs(k._Data.Attrs) do		
    				if m ~= nil then
    					local propInfo = {}
						propInfo.ID = m.AttrId
						propInfo.Value = m.AttrValue							
						table.insert(prop, propInfo)
					end
				end
			end
		end
	end

	--计算公式类 获取结果
	local CScoreCalcMan = require "Data.CScoreCalcMan"
	fightScore = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, prop)

	return fightScore
end

--用于主界面的显示
def.method("=>","boolean").IsShowRedPoint = function(self)
	for i,v in pairs(self._Table_Designations) do
		if self: NeedRedPointByType(i) then
			return true
		end
	end

	return false
end

--分类是否需要小红点
def.method("number", "=>", "boolean").NeedRedPointByType = function(self, nType)
	if self._Table_TypeRedPoint == nil or table.nums(self._Table_TypeRedPoint) <= 0 then return false end

	if self._Table_TypeRedPoint[nType] == nil then
		return false
	else
		return self._Table_TypeRedPoint[nType]
	end
end

--是否需要显示小红点
def.method("number", "=>", "boolean").NeedRedPoint = function(self, nTID)
	if self._Table_RedPoint == nil or table.nums(self._Table_RedPoint) <= 0 then
		return false
	end

	--warn("NeedRedPoint:: nTID:",nTID,"/",self._Table_RedPoint[nTID])
	if self._Table_RedPoint[nTID] == nil then
		return false
	else
		return self._Table_RedPoint[nTID]
	end
end

--设置小红点属性
def.method("number","boolean").SetRedPointState = function(self, nTID, needRed)
	if self._Table_RedPoint == nil then
		self._Table_RedPoint = {}
	end
	
	if needRed then--只需要记录需要小红点的
		self._Table_RedPoint[nTID] = true
	else
		if self._Table_RedPoint[nTID] ~= nil then
			self._Table_RedPoint[nTID] = nil--删除
		end
	end
	
	if CPanelRoleInfo.Instance():IsShow() then 
		CPanelRoleInfo.Instance():UpdateHostPlayerTitle()
	end
end

--设置分类红点属性
def.method("number","boolean").SetTypeRedPointState = function(self, nType, needRed)
	if self._Table_TypeRedPoint == nil then
		self._Table_TypeRedPoint = {}
	end
	
	if needRed then
		self._Table_TypeRedPoint[nType] = true
	else
		if self._Table_TypeRedPoint[nType] ~= nil then
			self._Table_TypeRedPoint[nType] = nil
		end
	end
end

--清除所有分类里面的红点数据(查看过一次，就清除所有红点)
def.method("number").ClearAllTypeRedPoint = function(self, nType)
	if self._Table_Designations[nType] == nil then return end

	for _,k in pairs(self._Table_Designations[nType]) do
		self: SetRedPointState(k._Data.Id, false)
	end
end

--根据称号ID设置分类小红点
def.method("number","boolean").SetTypeRedPointStateByTId =function(self, nID, needRed)
	local nType = self: GetTypeByTid(nID)
	if nType <= 0 then return end

	self:SetTypeRedPointState(nType, needRed)
end

--存小红点数据
def.method().SaveRedPointData = function(self)	
	--称号小红点
	if self._Table_RedPoint == nil or table.nums(self._Table_RedPoint) <= 0 then
		CRedDotMan.DeleteModuleDataToUserData("Designation")
	else
		CRedDotMan.SaveModuleDataToUserData("Designation", self._Table_RedPoint)
	end


	--称号分类小红点
	if self._Table_TypeRedPoint == nil or table.nums(self._Table_TypeRedPoint) <= 0  then
		CRedDotMan.DeleteModuleDataToUserData("DesignationType")
	else
		CRedDotMan.SaveModuleDataToUserData("DesignationType", self._Table_TypeRedPoint)
	end
end

---------------------------S2C------------------------------------
--设置当前称号ID
def.method("number","number").ChangeDesignationID = function(self,nRoleID,nID)
	if self._Table_Designations == nil or table.nums(self._Table_Designations) <=0 then
		self:LoadAllDesignationData()
	end
	
	local player = game._HostPlayer
	--玩家自己，处理数据
	if nRoleID == player._ID then		
		if self._CurDesignationID == nID then return end
		for _,v in pairs(self._Table_Designations) do
			for _,k in pairs(v) do
				if k._lock > 0 then
					if k._Data.Id == self._CurDesignationID  then
						k._lock = 1--将前置状态设置回来
					end

					if nID == k._Data.Id then
						k._locl = 2 --当前称号
					end
				end	
			end
		end

		if CPanelDesignation.Instance():IsShow() then
			CPanelDesignation.Instance():TakeOffDesignation(self._CurDesignationID)
			CPanelDesignation.Instance():PutOnDesignation(nID)
		end

		self._CurDesignationID = nID		
	else--视野内玩家，只做头顶显示
		local table_Player = game._CurWorld._PlayerMan._ObjMap
		if table_Player == nil or table.nums(table_Player) <= 0 then return end

		for _,v in pairs(table_Player) do
			if v._ID == nRoleID then
				player = v
			break
			end
		end
	end	

	local DataTem = self: GetDesignationDataByID(nID)
	if DataTem ~= nil then 
		player._InfoData._TitleName = "<color="..DataTem.ColorRGB..">" ..DataTem.Name.."</color>"	
	else
		player._InfoData._TitleName = ""
	end
	player:UpdateTopPate(EnumDef.PateChangeType.TitleName)
end

--称号拥有状态改变
def.method("number","number").ChangeDesignationLockState = function(self, nID,nTimeLimit)	
	if self._Table_Designations == nil or #self._Table_Designations <= 0 then return end
	if nID == nil or nTimeLimit == nil then 
		warn("ChangeDesignationLockState---->nID",nID,"__TimeLimit",nTimeLimit)
	return end

	for _,v in pairs(self._Table_Designations) do
		for _,k in pairs(v) do
			if k._Data.Id == nID then
				if nID == self._CurDesignationID then
					k._lock = 2 --当前称号
				else
					k._lock = 1 --称号解锁
				end
				k._Time = nTimeLimit --时间		
			return end	
		end
	end
end

--时间到，移除称号
def.method("number","number").RemoveDesignation = function (self, nRoleID, nID)
	self: SetRedPointState(nID, false)
	if self._Table_Designations == nil or #self._Table_Designations <= 0 then return end

	--删除的称号是未解锁状态
	for _,v in pairs(self._Table_Designations) do
		for _,k in pairs(v) do
			if k._Data.Id == nID then
				if nID == self._CurDesignationID then
					k._lock = 0
					k._Time = k._Data.TimeLimit --时间					
					break;
				end				
			end	
		end
	end

	--如果删除的称号是当前装备的,要重置状态
	if nID == self._CurDesignationID then
		self._CurDesignationID = 0
		if CPanelDesignation.Instance():IsShow() then
			CPanelDesignation.Instance():RemoveDesignation(nID)
		end
	end

	local player = game._HostPlayer
	if nRoleID ~= player._ID then		
		local table_Player = game._CurWorld._PlayerMan._ObjMap
		if table_Player == nil or table.nums(table_Player) <= 0 then return end
			for _,v in pairs(table_Player) do
				if v._ID == nRoleID then
				player = v
				break
			end
		end
	end

	if player == nil then return end

	player._InfoData._TitleName = ""
	player:UpdateTopPate(EnumDef.PateChangeType.TitleName)
end

----------------------------C2S--------------------------------------
--装备称号
def.method("number").PutOnDesignationID =  function(self,nID)
	local C2SPutOn = require "PB.net".C2SDesignationPutOn
	local protocol = C2SPutOn()
    protocol.DesignationId = nID
    PBHelper.Send(protocol)
end

--卸载称号
def.method().TakeOffDesignation = function(self)
	local C2STakeOff = require "PB.net".C2SDesignationTakeOff
	local protocol = C2STakeOff()
    PBHelper.Send(protocol)
end

def.method().Release = function(self)	
	self._CurDesignationID = 0
	self._Table_Designations = {}
end

DesignationMan.Commit()
return DesignationMan