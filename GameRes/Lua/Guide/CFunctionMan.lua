--[[----------------------------------------------
         		 功能管理器
          				--- by ml 2017.2.20
--------------------------------------------------]]
local Lplus = require "Lplus"
local CFunctionMan = Lplus.Class("CFunctionMan")
local def = CFunctionMan.define
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = require "Quest.CQuest"
local QuestDef = require "Quest.QuestDef"
local NotifyFunctionEvent = require "Events.NotifyFunctionEvent"

-- 以Prefab为依据存储
def.field("table")._FunData = BlankTable
-- 以FunID为依据存储(每个FunID对应必须唯一)
def.field("table")._FunIDData = BlankTable
-- 除上述两种情况外，单纯判断某个功能是否解锁
def.field("table")._FunTidData = BlankTable
-- 是否作弊全开
def.field("boolean")._OpenAll4Debug = false

def.static("=>", CFunctionMan).new = function ()
    local obj = CFunctionMan()
    return obj
end

-- 发送解锁事件
def.method("number").SendFunctionEvent = function(self, funID)
	local event = NotifyFunctionEvent()
	event.FunID = funID
	CGame.EventManager:raiseEvent(nil, event)
end

-- 加载所有功能解锁数据
def.method().LoadAllFunctionData = function(self)
	self._FunData = {}
	self._FunIDData = {}
	self._FunTidData = {}
	local allTid = CElementData.GetAllFun()
	for i = 1, #allTid do
		local tid = allTid[i]
		local fun = CElementData.GetTemplate("Fun", tid)
		if fun.FunType == 0 then
			local value = fun.Prefab
			if value ~= "" then
				if self._FunData[value] == nil then
					self._FunData[value] = {}
					self._FunData[value]._Tid = {}
					self._FunData[value]._Panel = nil
				end
				if #fun.ConditionData.FunUnlockConditions > 0 then
					self._FunData[value]._Tid[tid] = false
				else
					self._FunData[value]._Tid[tid] = true
				end
			else
				if #fun.ConditionData.FunUnlockConditions > 0 then
					self._FunTidData[tid] = false
				else
					self._FunTidData[tid] = true
				end
			end
		else
			local funID = fun.FunID
			if self._FunIDData[funID] == nil then
				self._FunIDData[funID] = {}
			end
			self._FunIDData[funID]._Tid = tid
			if #fun.ConditionData.FunUnlockConditions > 0 then
				self._FunIDData[funID]._IsOpen = false
			else
				self._FunIDData[funID]._IsOpen = true
			end
		end
	end
end

-- 更改功能解锁数据(初始解锁)
def.method("table").ChangeFunctionData = function(self, data)
	for i, v in ipairs(data) do
		local tid = v - 10000
		for j, w in pairs(self._FunData) do
			for k, x in pairs(w._Tid) do
				if k == tid then
					self._FunData[j]._Tid[k] = true
				end
			end
		end
		for j, w in pairs(self._FunIDData) do
			if w._Tid == tid then
				self._FunIDData[j]._IsOpen = true
			end
		end
		for j, w in pairs(self._FunTidData) do
			if j == tid then
				self._FunTidData[j] = true
			end
		end
	end
end

-- 更改功能解锁数据(变化)
def.method("number").UpdateFunctionData = function(self, tid)
	local fun = CElementData.GetTemplate("Fun", tid)
	if fun == nil then
		warn("UpdateFunctionData Error tid(很可能是客户端与服务器数据不同步):", tid)
		return
	end
	if fun.FunType == 0 then
		for j, w in pairs(self._FunData) do
			for k, x in pairs(w._Tid) do
				if k == tid then
					if w._Panel ~= nil then
						if not IsNil(w._Panel._Panel) then
							local go = w._Panel:GetUIObject(fun.ObjectName)
							if not IsNil(go) then
								go:SetActive(true)
							end
						end
					end
					self._FunData[j]._Tid[k] = true
					self:SendFunctionEvent(tid)
				end
			end
		end
		for j, w in pairs(self._FunTidData) do
			if j == tid then
				self._FunTidData[j] = true
				self:SendFunctionEvent(tid)
			end
		end
	else
		for j, w in pairs(self._FunIDData) do
			if w._Tid == tid then
				self._FunIDData[j]._IsOpen = true
				self:SendFunctionEvent(j)
			end
		end
	end
end

-- Debug命令设置功能是否解锁
def.method("boolean").SetOpenAll4Debug = function(self, open)
	self._OpenAll4Debug = open
	local go = GameObject.Find("Panel_Main_QuestN(Clone)/Fram_Lists/List_Quest/_Content")
	if not IsNil(go) then
		local item = go:GetComponentsInChildren(ClassType.GItem)
		for i = 0, item.Length - 1 do
			item[i].enabled = true
		end
	end
	for i, v in pairs(self._FunData) do
		if v._Panel ~= nil then
			for j, w in pairs(v._Tid) do
				local fun = CElementData.GetTemplate("Fun", j)
				local go = v._Panel:GetUIObject(fun.ObjectName)
				if IsNil(go) then
					warn("-----CFunctionMan ObjectName is nil-----", j, fun.ObjectName)
				else
					go:SetActive(open)
				end
			end
		end
	end
	for i, v in pairs(self._FunIDData) do
		local fun = CElementData.GetTemplate("Fun", v._Tid)
		if fun.FunType == 1 then
			self:SendFunctionEvent(fun.FunID)
		end
	end
	for i, v in pairs(self._FunTidData) do
		self:SendFunctionEvent(i)
	end
end

-- 通用功能解锁设置
def.method("string", "table").FunctionCheck = function(self, prefab, panel)
	if self._OpenAll4Debug then
		return
	end
	for i, v in pairs(self._FunData) do
		if i == prefab then
			v._Panel = panel
			for j, w in pairs(v._Tid) do
				if not w then
					local fun = CElementData.GetTemplate("Fun", j)
					local go = panel:GetUIObject(fun.ObjectName)
					if IsNil(go) then
						warn("-----CFunctionMan ObjectName is nil-----", j, fun.ObjectName)
					else
						go:SetActive(w)
					end
				end
			end
		end
	end
end

-- 判断动态菜单是否解锁(如系统菜单界面)
def.method("number", "=>", "boolean").IsUnlockByFunID = function(self, funID)
	if self._OpenAll4Debug then
		return true
	end

	if self._FunIDData[funID] == nil then
		--warn("There is no such funID:" .. funID)
		return true
	end
	return self._FunIDData[funID]._IsOpen
end

-- 根据功能解锁Tid判断是否解锁
def.method("number", "=>", "boolean").IsUnlockByFunTid = function(self, tid)
	if self._OpenAll4Debug then
		return true
	end

	if tid <= 0 then
		return true
	end
	local fun = CElementData.GetTemplate("Fun", tid)
	if fun == nil then
		warn("Template Fun is nil:", tid)
		return true
	end
	if fun.FunType == 0 then
		for i, v in pairs(self._FunData) do
			for j, w in pairs(v._Tid) do
				if j == tid then
					return w
				end
			end
		end
		for i, v in pairs(self._FunTidData) do
			if i == tid then
				return v
			end
		end
	else
		return self._FunIDData[fun.FunID]._IsOpen
	end
	return true
end

-- 检测教学部分
def.method("boolean", "number", "number", "number", "=>", "boolean").IsGuideFunOpen = function(self, isTid, condition, id, param)
	if self._OpenAll4Debug then
		return true
	end
	local isOpen = false
	local fun = nil
	if isTid then
		fun = CElementData.GetTemplate("Fun", id)
	else
		fun = CElementData.GetTemplate("Fun", self._FunIDData[id]._Tid)
	end
	-- 遍历是否符合前置条件 如果有一项不满足 则不通过
	for i, v in ipairs(fun.ConditionData.FunUnlockConditions) do
		if v.ConditionFinishTask._is_present_in_parent and condition == EnumDef.EGuideBehaviourID.FinishTask then	
			if v.ConditionFinishTask.FinishTaskID == param then
				isOpen = true
			end
		elseif v.ConditionLevelUp._is_present_in_parent and condition == EnumDef.EGuideBehaviourID.LevelUp  then
			if v.ConditionLevelUp.LevelUp <= param then
				isOpen = true
			end
		elseif v.ConditionPassDungeon._is_present_in_parent and condition == EnumDef.EGuideBehaviourID.DungeonPass then
			if v.ConditionPassDungeon.PassDungeonID == param then
				isOpen = true
			end
		elseif v.ConditionUseProp._is_present_in_parent and condition == EnumDef.EGuideBehaviourID.UseProp then
			-- 如果使用的道具不等于配置的ID 不通过
			if v.ConditionUseProp.UsePropID == param then
				isOpen = true
			end
		elseif v.ConditionReceiveTask._is_present_in_parent and condition == EnumDef.EGuideBehaviourID.ReceiveTaskID then	
			if v.ConditionReceiveTask.ReceiveTaskID == param then
				isOpen = true
			end
		elseif v.ConditionGuide._is_present_in_parent then
			if v.ConditionGuide.GuideID == param then
				isOpen = true
			end
		end
	end
	if isTid then
		for i, v in pairs(self._FunData) do
			for j, w in pairs(v._Tid) do
				if j == id then
					if isOpen then
						if v._Panel ~= nil then
							if not IsNil(v._Panel._Panel) then
								local go = v._Panel:GetUIObject(fun.ObjectName)
								if not IsNil(go) then
									go:SetActive(isOpen)
								end
							end
						end
						self._FunData[i]._Tid[j] = true
						return isOpen
					end
				end
			end
		end
	else
		if isOpen then
			self._FunIDData[id]._IsOpen = true
			self:SendFunctionEvent(id)
		end
	end

	return isOpen
end

CFunctionMan.Commit()
return CFunctionMan