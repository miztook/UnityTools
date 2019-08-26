local Lplus = require "Lplus"
local CWingsMan = Lplus.Class("CWingsMan")
local def = CWingsMan.define

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local WingLevelUpDataUtil = require "Wings.WingLevelUpDataUtil"
local bit = require "bit"
local UserData = require "Data.UserData".Instance()

def.field("table")._AllWingsList = BlankTable							-- 所有翅膀列表（模版数据）
def.field("boolean")._HasPreloaded = false								-- 是否已预加载数据
def.field("table")._ServerWingsList = BlankTable						-- 已拥有翅膀列表
def.field("table")._TalentData = BlankTable								-- 天赋加点
def.field("table")._SkillNumTemp = BlankTable							-- 天赋加点缓冲表
def.field("number")._TotalPoint = 0 									-- 天赋加点的数量
def.field("number")._CostModulus = 1 									-- 升级辅助道具消耗数量系数
def.field("boolean")._IsUseLvUpAssistItem = false						-- 是否使用升级辅助道具

local WING_FUNC_TID = 23 	-- 翅膀的教学功能Tid

local _instance = nil
def.static("=>", CWingsMan).Instance = function ()
    if _instance == nil then
        _instance = CWingsMan()

		local template = CElementData.GetSpecialIdTemplate(195)
		if template ~= nil then
			_instance._CostModulus = tonumber(template.Value)
		end
    end
    return _instance
end

-- 获取翅膀的数据
-- WingName	 翅膀名字
-- ModelAssetPath	模型Path
-- DescribText 描述文本
-- Profession	 限制职业
-- Sex 限制性别
def.method("number", "=>", "dynamic").GetWingData = function(self, id)
	local data = CElementData.GetTemplate("Wing", id)	
	return data
end

-- 设置
def.method("number").SetWingPointsData = function(self, add_points)
	self._TotalPoint = add_points
end

def.method("number").AddWingPointsData = function(self, add_points)
	self._TotalPoint = self._TotalPoint + add_points

	for _, data in ipairs(self._TalentData) do
		data.TalentPoint = data.TalentPoint + add_points
	end
end

-- 获取
def.method("=>", "number").GetWingPointsData = function(self)
	return self._TotalPoint
end

-- 获取单阶内的最大等级
def.method("=>", "number").GetMaxLevelInGrade = function(self)
	return 20
end

-- 计算阶数  阶数 = 1+int（(等级-1)/单阶内最大等级）
def.method("number", "=>", "dynamic", "dynamic").CalcGradeByLevel = function(self, level)
	local max_level = self:GetMaxLevelInGrade()
	local grade = 1 + math.floor((level - 1) / max_level)
	local trans_level = (level -1) % max_level + 1
	return grade, trans_level
end

local function GetWingPropList(id, level)
	local prop = {}
	local lvUpTid = WingLevelUpDataUtil.GetTid(id, level)
	if lvUpTid > 0 then
		local lvUpTemplate = CElementData.GetTemplate("WingLevelUp", lvUpTid)
		if lvUpTemplate ~= nil then
			if lvUpTemplate.WingID == id and lvUpTemplate.Level == level then				
				-- 合并 				
				for _, val in ipairs(lvUpTemplate.WingProps) do
					-- 没有匹配
					local propInfo = {}
					propInfo.ID = val.PropType
					propInfo.Value = val.PropValue							
					table.insert(prop, propInfo)
				end
			end
		end
	end
	return prop
end

def.method("number", "number", "=>", "number").GetWingFightScore = function(self, id, level)
	local prop = GetWingPropList(id, level)
	--计算公式类 获取结果
	local score = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, prop)
	return score
end

def.method("=>", "number").GetAllWingsFightScore = function(self)
	local score = 0
	-- local all_prop = {}
	for _, v in ipairs(self._ServerWingsList) do
		-- local prop = GetWingPropList(v.Tid, v.Level)
		-- for _, info in ipairs(prop) do
		-- 	table.insert(all_prop, info)
		-- end
		score = score + v.FightScore
	end
	-- score = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, all_prop)
	return score
end

def.method("=>", "number").GetAllWingsLevel = function (self)
	local count = 0
	for _, v in ipairs(self._ServerWingsList) do
		count = count + v.Level
	end
	return count
end

-- 获取翅膀升级信息
-- WingID	翅膀ID
-- Level		等级
-- NeedExp	需求经验值
-- WeightID	权重ID
-- GradeID	进阶ID
-- WingProps 增加属性（5种）
def.method("number", "number", "=>", "dynamic").GetWingLevelUpData = function(self, id, level)
	local prop = {}
	local lvUpTid = WingLevelUpDataUtil.GetTid(id, level)
	if lvUpTid > 0 then
		local lvUpTemplate = CElementData.GetTemplate("WingLevelUp", lvUpTid)
		if lvUpTemplate ~= nil then
			if lvUpTemplate.WingID == id and lvUpTemplate.Level == level then				
				-- 合并 				
				for _, val in ipairs(lvUpTemplate.WingProps) do
					-- 没有匹配				
					local tmp = {key = val.PropType, data = val.PropValue}
					prop[#prop+1] = tmp			
				end
			end
		end
	end

	local function SortByKey(item1, item2)
		if item1.key < item2.key then
			return true
		else			
			return false
		end
	end
	table.sort(prop, SortByKey)
	return prop
end

--  WingProp
--  {
-- 		int32	PropType
-- 		int32	PropValue
--  }
-- 获取属性加成 累计 
def.method("number", "number", "=>", "dynamic").GetWingLevelProp = function(self, id, level)
	local prop_all = {}
	local lvUpTid = WingLevelUpDataUtil.GetTid(id, level)
	if lvUpTid > 0 then
		local lvUpTemplate = CElementData.GetTemplate("WingLevelUp", lvUpTid)
		if lvUpTemplate ~= nil then
			if lvUpTemplate.WingID == id and lvUpTemplate.Level <= level then
				local match = false
				-- 合并 
				-- 用了有序化的ipair 因为pairs出现了奇怪的空表 应该是数据解析的问题
				for _, val in ipairs(lvUpTemplate.WingProps) do
					for m, n in pairs(prop_all) do 
						if n.key == val.PropType then
							match = true
							n.data = n.data + val.PropValue
						end
					end
					-- 没有匹配
					if not match then
						local tmp = {key = val.PropType, data = val.PropValue}
						table.insert(prop_all, tmp)
					end
				end
			end
		end
	end

	local function SortByKey(item1, item2)
		if item1.key <= item2.key then
			return true
		else			
			return false
		end
	end
	table.sort(prop_all, SortByKey)
	return prop_all
end

-- 获取升级信息
def.method("number", "number", "=>", "dynamic").GetWingLevelUpInfo = function(self, id, level)
	local lvUpTid = WingLevelUpDataUtil.GetTid(id, level)
	if lvUpTid > 0 then
		local lvUpTemplate = CElementData.GetTemplate("WingLevelUp", lvUpTid)
		return lvUpTemplate
	-- else
	-- 	warn("GetWingLevelUpInfo: can not find proper info ")
	end
	return nil
end

-- 根据权重id 获取成功率
-- required int32 Id				= 1;
-- required int32 Weight			= 2;	//权重
-- required int32 Multiple			= 3;	//暴击倍数（可以为0,0为失败）
-- repeated WeightMultiple	WeightMultiples			= 4;	//权重
def.method("number", "=>", "dynamic").GetWingSuccessRate = function(self, id)
	local data = CElementData.GetTemplate("WingLevelWeight", id)	
	local rate = 0
	local sum = 0
	local fail_sum = 0
	if data then
		for k,v in ipairs(data.WeightMultiples) do 
			sum = sum + v.Weight
			-- 失败的
			if v.Multiple == 0 then
				fail_sum = fail_sum + v.Weight
			end
		end
		rate = (sum - fail_sum) / sum
	end
	return rate
end

-- 根据失败率算 消耗数量
def.method("number", "number", "=>", "number").GetCostNeed = function(self, id, level)
	local info = self:GetWingLevelUpInfo(id, level)
	if info == nil then return 0 end
	local success = self:GetWingSuccessRate(info.WeightID)
	local fail = 1 - success
	-- 设失败率为n%，则消耗的米斯特调剂数量=n/s，向上取整，其中s为配置的系数（目前定的是10）
	local cost = math.ceil( (fail*100) / self._CostModulus )
	return cost
end

-- Grade 阶级
-- TalentPoint 进阶获得天赋点
-- CostItemNum 消耗进阶道具数量
def.method("number", "=>", "dynamic").GetWingGradeUpData = function(self, id)
	local data = CElementData.GetTemplate("WingGradeUp", id)	
	return data
end

-- 获取相关职业翅膀信息
-- 	TalentPageId
-- 	{
-- 		required int32	Id
-- 		required int32	PageId 
-- 	}
-- 	repeated TalentPageId	TalentPageIds 
def.method("number", "=>", "dynamic").GetTalentLevelTemplate = function(self, id)
	local data = CElementData.GetTemplate("WingTalentLevel", id)	
	return data
end

-- 重置临时数据 self._SkillNumTemp
def.method("number").ResetSkillTempList = function(self, talentPageIndex)
	self._SkillNumTemp[talentPageIndex].TalentPoint = self._TalentData[talentPageIndex].TalentPoint		
	local data = self._SkillNumTemp[talentPageIndex].WingTalents
	local ori = self._TalentData[talentPageIndex].WingTalents
	for i = 1, #data do 
		if ori[i] then
			data[i].WingTalentID = ori[i].WingTalentID
			data[i].AddPoint = ori[i].AddPoint
		else
			warn("not match error occur!!!! in ResetSkillTempList!")
		end
	end
end

-- 更新临时数据  self._SkillNumTemp
-- talentPageIndex: 三个系的索引  id: 技能的id   num: 新点数
def.method("number", "number", "number").SetSkillTempData = function(self, id, num, talentPageIndex)
	local data = self._SkillNumTemp[talentPageIndex]
	if data.TalentPoint > 0 then
		for k,v in ipairs(data.WingTalents) do 
			if v.WingTalentID == id then
			 	v.AddPoint = num
			 	-- k 为index
			 	data.TalentPoint = data.TalentPoint - 1
				break
			end
		end
	else
		warn("wing talent add point left not enough!")
	end
end


-- 更新临时数据  self._SkillNumTemp
-- talentPageIndex: 三个系的索引  id: 技能的id   num: 新点数
def.method("number", "number", "number").MinusSkillTempData = function(self, id, num, talentPageIndex)
	local data = self._SkillNumTemp[talentPageIndex]
	for k,v in ipairs(data.WingTalents) do 
		if v.WingTalentID == id then
		 	v.AddPoint = num
		 	-- k 为index
		 	data.TalentPoint = data.TalentPoint + 1

			-- local CPanelWingSoul = require 'GUI.CPanelWingSoul'
			-- if CPanelWingSoul and CPanelWingSoul.Instance():IsShow() then
			-- 	local panel_intance = CPanelWingSoul.Instance()
			-- 	panel_intance:UpdateTalentIconNum(num, id, data.TalentPoint)
			-- end
		 	break
		end
	end
end

-- 检查临时剩余加点数
def.method("number", "=>", "boolean").CheckTempPointLeft = function(self, talentPageIndex)
	local data = self._SkillNumTemp[talentPageIndex]
	if data.TalentPoint > 0 then
		return true
	end
	return false
end

-- 检查真正剩余加点数
def.method("number", "=>", "boolean").CheckPointLeft = function(self, pageId)
	for _, talentData in ipairs(self._TalentData) do
		if talentData.PageId == pageId then
			return talentData.TalentPoint > 0
		end
	end
	return false
end

-- 检查天赋技能是否解锁
def.method("number", "number", "=>", "boolean", "boolean", "boolean", "number", "number").CheckTalentUnlock = function(self, talentLvTid, talentPageIndex)
	local talent_lv_template = self:GetTalentLevelTemplate(talentLvTid)
	local pre_talent_lv_tid_1 = talent_lv_template.WingTalentID1
	local pre_talent_lv_tid_2 = talent_lv_template.WingTalentID2

	local is_unlock_1, is_unlock_2 = true, false -- 前置一，二是否满足条件
	local sqc_1, sqc_2 = 0, 0 -- 前置一，二的排序序号
	local unlock_limit_data = talent_lv_template.TalentPreLimits[1] -- 第一个前置限制就是解锁条件
	if pre_talent_lv_tid_1 > 0 then
		sqc_1 = self:GetTalentLevelTemplate(pre_talent_lv_tid_1).SequenceNum
		local add_point = self:GetTempTalentAddPoint(pre_talent_lv_tid_1, talentPageIndex)
		is_unlock_1 = add_point >= unlock_limit_data.PreLevel1
	end
	if pre_talent_lv_tid_2 > 0 then
		sqc_2 = self:GetTalentLevelTemplate(pre_talent_lv_tid_2).SequenceNum
		local add_point = self:GetTempTalentAddPoint(pre_talent_lv_tid_2, talentPageIndex)
		is_unlock_2 = add_point >= unlock_limit_data.PreLevel2
	end
	local is_unlock = is_unlock_1 or is_unlock_2 -- 当前天赋技能是否解锁
	return is_unlock, is_unlock_1, is_unlock_2, sqc_1, sqc_2
end

-- 检查能否加点
def.method("number", "number", "boolean", "=>", "boolean").CheckTalentPointUp = function(self, talentLvTid, talentPageIndex, isShowTips)
	local ret = false
	if self:CheckTalentUnlock(talentLvTid, talentPageIndex) then
		local talent_lv_template = self:GetTalentLevelTemplate(talentLvTid)
		if talent_lv_template ~= nil then
			local limit_list = talent_lv_template.TalentPreLimits
			local cur_add_point = self:GetTempTalentAddPoint(talentLvTid, talentPageIndex)
			local max_level = limit_list[#limit_list].MaxLevel
			if cur_add_point < max_level then
				local pre_talent_level_1, pre_talent_level_2 = 0, 0
				-- 找到当前的前置限制等级
				for _, limit_data in ipairs(talent_lv_template.TalentPreLimits) do
					if cur_add_point < limit_data.MaxLevel then
						pre_talent_level_1 = limit_data.PreLevel1
						pre_talent_level_2 = limit_data.PreLevel2
						break
					end
				end

				local is_unlock_1, is_unlock_2 = true, false -- 前置一，二是否满足条件
				local pre_talent_lv_tid_1 = talent_lv_template.WingTalentID1
				local pre_talent_lv_tid_2 = talent_lv_template.WingTalentID2
				if pre_talent_lv_tid_1 > 0 then
					-- 检查前置技能1
					local add_point = self:GetTempTalentAddPoint(pre_talent_lv_tid_1, talentPageIndex)
					is_unlock_1 = add_point >= pre_talent_level_1
				end
				if pre_talent_lv_tid_2 > 0 then
					-- 检查前置技能2
					local add_point = self:GetTempTalentAddPoint(pre_talent_lv_tid_2, talentPageIndex)
					is_unlock_2 = add_point >= pre_talent_level_2
				end
				ret = is_unlock_1 or is_unlock_2

				if not ret and isShowTips then
					game._GUIMan:ShowTipText(StringTable.Get(19521), false)
				end
			else
				-- 已满级
				if isShowTips then
					game._GUIMan:ShowTipText(StringTable.Get(19531), false)
				end
			end
		end
	else
		-- 技能未解锁
		if isShowTips then
			game._GUIMan:ShowTipText(StringTable.Get(19561), false)
		end
	end
	return ret
end

-- 能否减点
def.method("number", "number", "boolean", "=>", "boolean").CheckTalentPointDown = function(self, talentLvTid, talentPageIndex, isShowTips)
	if self._SkillNumTemp[talentPageIndex] ~= nil and self._TalentData[talentPageIndex] ~= nil then
		if not self:CheckTalentUnlock(talentLvTid, talentPageIndex) then
			-- 技能未解锁
			if isShowTips then
				game._GUIMan:ShowTipText(StringTable.Get(19561), false)
			end
			return false
		end
		local temp_list = self._SkillNumTemp[talentPageIndex].WingTalents
		local server_list = self._TalentData[talentPageIndex].WingTalents
		if temp_list ~= nil and server_list ~= nil then
			local server_data = nil -- 服务器数据
			local temp_data = nil -- 临时数据
			for i, v in ipairs(server_list) do
				if v.WingTalentID == talentLvTid then
					server_data = v
					break
				end
			end
			for i, v in ipairs(temp_list) do
				if v.WingTalentID == talentLvTid then
					temp_data = v
					break
				end
			end
			if temp_data == nil or server_data == nil then
				warn("Wing talent data is nil, talent level tid:" .. talentLvTid)
				return false
			end
			-- 是否临时加点了
			if temp_data.AddPoint > server_data.AddPoint then
				local next_talent_list = {} -- 所有的后置技能
				for _, v in ipairs(temp_list) do
					if v.AddPoint > 0 then
						local talentLvTemplate = self:GetTalentLevelTemplate(v.WingTalentID)
						if talentLvTid == talentLvTemplate.WingTalentID1 or
						   talentLvTid == talentLvTemplate.WingTalentID2 then
							local data =
							{
								_LvTemplate = talentLvTemplate,
								_AddPoint = v.AddPoint
							}
							table.insert(next_talent_list, data)
						end
					end
				end

				local can_point_down = true
				for _, v1 in ipairs(next_talent_list) do
					-- 是否属于后置技能的前置一
					local is_talent_1 = talentLvTid == v1._LvTemplate.WingTalentID1
					local pre_talent_level_1, pre_talent_level_2 = 0, 0
					for _, limit_data in ipairs(v1._LvTemplate.TalentPreLimits) do
						if v1._AddPoint <= limit_data.MaxLevel then
							-- 后置的前置一，二的当前解锁等级
							pre_talent_level_1 = limit_data.PreLevel1
							pre_talent_level_2 = limit_data.PreLevel2
							break
						end
					end
					local this_pre_talent_unlock, other_pre_talent_unlock = true, false
					local other_pre_talent_id = 0 -- 后置技能的另一个前置
					local other_pre_talent_level = 0
					if is_talent_1 then
						this_pre_talent_unlock = temp_data.AddPoint > pre_talent_level_1
						other_pre_talent_id = v1._LvTemplate.WingTalentID2
						other_pre_talent_level = pre_talent_level_2
					else
						this_pre_talent_unlock = temp_data.AddPoint > pre_talent_level_2
						other_pre_talent_id = v1._LvTemplate.WingTalentID1
						other_pre_talent_level = pre_talent_level_1
					end
					-- 检查另一个前置是否满足
					if other_pre_talent_id > 0 then
						for _, v2 in ipairs(temp_list) do
							if other_pre_talent_id == v2.WingTalentID then
								other_pre_talent_unlock = v2.AddPoint >= other_pre_talent_level
								break
							end
						end
					end
					if not this_pre_talent_unlock and not other_pre_talent_unlock then
						-- 后置技能的两个前置的等级都不大于后置技能的当前解锁等级
						can_point_down = false
						break
					end
				end
				if not can_point_down and isShowTips then
					game._GUIMan:ShowTipText(StringTable.Get(19549), false)
				end
				return can_point_down
			else
				-- 没有新加的点
				if isShowTips then
					game._GUIMan:ShowTipText(StringTable.Get(19547), false)
				end
			end
		end
	else
		warn("Wing talent page is nil, current page index:" .. talentPageIndex)
	end
	return false
end

-- 返回天赋数据
def.method("=>", "table").GetTalentListData = function(self)
	return self._TalentData
end

-- 返回临时天赋数据
def.method("=>", "table").GetTempTalentListData = function(self)
	return self._SkillNumTemp
end

-- 返回天赋数据长度
def.method("=>", "number").GetTalentListDataLenth = function(self)
	return #self._TalentData
end

-- 返回临时天赋数据长度
def.method("=>", "number").GetTempTalentListDataLenth = function(self)
	return #self._SkillNumTemp
end

local function ResetDeepCopyData(dp, ori)
	for i = 1, #dp do 
		if ori[i] then
			dp[i].WingTalentID = ori[i].WingTalentID
			dp[i].AddPoint = ori[i].AddPoint
		end
	end
end

-- 重置临时天赋数据
def.method().ResetTempTalentListData = function (self)
	self._SkillNumTemp = {}

	for _, data in ipairs(self._TalentData) do
		local clone_talent_data = clone(data.WingTalents)
		ResetDeepCopyData(clone_talent_data, data.WingTalents)
		local tmp = { PageId = data.PageId, TalentPoint = data.TalentPoint, WingTalents = clone_talent_data }
		table.insert(self._SkillNumTemp, tmp)
	end
end

def.method("table").SetTalentListData = function(self, data)
	-- 清理
	self._TalentData = {}

	-- 只操作序列化部分
	for i = 1, #data do
		-- 深拷贝
		local talents1 = clone(data[i].WingTalents)
		ResetDeepCopyData(talents1, data[i].WingTalents)

		local tmp1 = { PageId = data[i].PageId, TalentPoint = data[i].TalentPoint, WingTalents = talents1 }
		table.insert(self._TalentData, tmp1)				-- 服务器
	end
end

-- WingTalentPageInfo   
-- required int32				PageId			= 1;	//天赋页ID
-- required int32				TalentPoint		= 2;	//剩余天赋点
-- repeated WingTalentInfo		WingTalents		= 3;	//翅膀天赋信息
-- 获取加点后的页面信息，刷新界面
def.method("table").UpdateTalentDataLists = function(self, info)
	-- 
	for i = 1, #self._TalentData do 
		if self._TalentData[i].PageId == info.PageId then
			local lo_info1 = clone(info.WingTalents)
			ResetDeepCopyData(lo_info1, info.WingTalents)
			local info1_data = { PageId = info.PageId, TalentPoint = info.TalentPoint, WingTalents = lo_info1 }
			self._TalentData[i] = info1_data			
		end
	end

	for i = 1, #self._SkillNumTemp do 
		if self._SkillNumTemp[i].PageId == info.PageId then
			local lo_info2 = clone(info.WingTalents)
			ResetDeepCopyData(lo_info2, info.WingTalents)
			local info1_data = { PageId = info.PageId, TalentPoint = info.TalentPoint, WingTalents = lo_info2 }
			self._SkillNumTemp[i] = info1_data
		end
	end
end

-- 更新剩余点数
def.method("number", "number").ReSetTalentLeftPoints = function(self, pageid, left)
	for i = 1, #self._TalentData do 
		if self._TalentData[i].PageId == pageid then
			self._TalentData[i].TalentPoint = left
			for m = 1, #self._TalentData[i].WingTalents do 
				self._TalentData[i].WingTalents[m].AddPoint = 0
			end
		end
	end

	for i = 1, #self._SkillNumTemp do 
		if self._SkillNumTemp[i].PageId == pageid then
			self._SkillNumTemp[i].TalentPoint = left
			for n = 1, #self._SkillNumTemp[i].WingTalents do 
				self._SkillNumTemp[i].WingTalents[n].AddPoint = 0
			end
		end
	end
end

-- 加点有变化
def.method("number", "=>", "boolean").WingSoulChanged = function(self, talentPageIndex)
	local isDataChanged = false
	local static_data = self._TalentData[talentPageIndex]
	local tmp_data = self._SkillNumTemp[talentPageIndex]
	if static_data ~= nil and tmp_data ~= nil then
		for i = 1, #tmp_data.WingTalents do 
			if tmp_data.WingTalents[i].AddPoint ~= static_data.WingTalents[i].AddPoint then
				isDataChanged = true
				break
			end
		end
	end
	return isDataChanged
end

-- 加点有变化
def.method("number", "number", "=>", "boolean").WingSoulChangedSpecial = function(self, talentPageIndex, id)
	local static_data = self._TalentData[talentPageIndex].WingTalents
	local tmp_data = self._SkillNumTemp[talentPageIndex].WingTalents
	
	for i = 1, #tmp_data do 
		local data = tmp_data[i]
		if data.WingTalentID == id then
			if data.AddPoint ~= static_data[i].AddPoint then							
				return true
			end
		end
	end
	return false
end

def.method("number", "number", "=>", "number").GetStaticAddPoint = function(self, talentPageIndex, id)
	local static_data = self._TalentData[talentPageIndex].WingTalents
	for i = 1, #static_data do 
		local data = static_data[i]
		if data.WingTalentID == id then
			return static_data[i].AddPoint
		end
	end
	return 0
end

-- 检查特定技能是否有临时加点
def.method("number", "number", "=>", "boolean").CheckSkillHasTempAddPoint = function(self, id, talentPageIndex)
	local ret = false
	if self._SkillNumTemp[talentPageIndex] ~= nil and self._TalentData[talentPageIndex] ~= nil then
		local temp_list = self._SkillNumTemp[talentPageIndex].WingTalents
		local server_list = self._TalentData[talentPageIndex].WingTalents
		if temp_list ~= nil and server_list ~= nil then
			local server_data = nil -- 服务器数据
			local temp_data = nil -- 临时数据
			for i, v in ipairs(server_list) do
				if v.WingTalentID == id then
					server_data = v
					break
				end
			end
			for i, v in ipairs(temp_list) do
				if v.WingTalentID == id then
					temp_data = v
					break
				end
			end
			if temp_data ~= nil and server_data ~= nil then
				-- 是否临时加点了
				if temp_data.AddPoint > server_data.AddPoint then
					ret = true
				end
			end
		end
	end
	return ret
end

-- 获取翅膀天赋所加的战力
def.method("=>", "number").GetTalentFightScore = function(self)
	local score = 0
	local curPageId = game._HostPlayer:GetCurWingPageId()
	local prof = game._HostPlayer._InfoData._Prof
	for _, talentInfo in ipairs(self._TalentData) do
		if talentInfo.PageId == curPageId then
			for _, skillInfo in ipairs(talentInfo.WingTalents) do
				-- 添加的点数即等级
				if skillInfo.AddPoint > 0 then
					local talentLvUpTemplate = self:GetTalentLevelTemplate(skillInfo.WingTalentID)
					if talentLvUpTemplate ~= nil then
						score = score + CScoreCalcMan.Instance():CalcTalentSkillScore(prof, talentLvUpTemplate.TalentID, skillInfo.AddPoint)
					end
				end
			end
			break
		end
	end
	return score
end

-- 获取具体翅膀天赋页 内部数据 根据pageid
-- 	TalentName	 天赋页名称
-- 	ModelAssetPath 模型Path
-- 	WingElementType 翅膀元素类型（参照Data.EWingElementType）
-- TalentSkillId
-- 	{
-- 		required int32		Id		= 1;
-- 		required int32 		SkillId	= 2;
-- 	}
-- 	repeated TalentSkillId	TalentSkillIds			= 7;	//天赋技能Id（9组）
def.method("number", "=>", "dynamic").GetWingPageData = function(self, page_id)
	local data = CElementData.GetTemplate("WingTalentPage", page_id)	
	return data
end

-- 清楚数据
def.method().Cleanup = function(self)
	self._AllWingsList = {}
	self._ServerWingsList = {}
	self._TalentData = {}
	self._SkillNumTemp = {}
	self._HasPreloaded = false
	self._IsUseLvUpAssistItem = false
end

def.method().PreloadAllWings = function(self)
	if self._HasPreloaded then return end

	self._AllWingsList = {}
	local all_ids = CElementData.GetAllTid("Wing")
	local prof = game._HostPlayer._InfoData._Prof
	for i = 1, #all_ids do
		local template = self:GetWingData(all_ids[i])
		if EnumDef.Profession2Mask[prof] == bit.band(EnumDef.Profession2Mask[prof], template.Profession) then
			local temp =
			{
				Tid = all_ids[i],
				Level = 0,
				CurExp = 0,
				Template = template
			}
			table.insert(self._AllWingsList, temp)
		end
	end
	self._HasPreloaded = true
end

-- 返回翅膀数量
def.method("=>", "number").GetWingsTotalNum = function(self)
	return #self._ServerWingsList
end

def.method("number", "=>", "table").GetServerData = function (self, tid)
	for _, v in ipairs (self._ServerWingsList) do
		if v.Tid == tid then
			return v
		end
	end
	return nil
end

-- 获取服务器已获得数据列表
def.method("=>", "table").GetAllServerData = function(self)
	return self._ServerWingsList
end

local function AddWing(self, server_data)
	if server_data == nil then return end
	if server_data.WingID <= 0 then
		error("AddWing From Server failed, WingID must over than zero")
		return
	end
	local template = self:GetWingData(server_data.WingID)
	if template == nil then
		error("AddWing From Server failed, wing template got nil, wrong wing id:" .. server_data.WingID)
		return
	end
	local temp =
	{
		Tid = server_data.WingID,
		Level = server_data.WingLevel,
		CurExp = server_data.CurExp,
		FightScore = server_data.FightScore,
		Template = template
	}
	table.insert(self._ServerWingsList, temp)
end

-- 解析服务器数据
def.method("table").ResolveWingsData = function(self, list)
	self._ServerWingsList = {}
	for _, v in ipairs(list) do
		AddWing(self, v)
	end
end

-- 添加服务器数据
def.method("table").AddWingData = function (self, info_data)
	if info_data == nil then return end

	-- 保存红点显示状态
	local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
	if exteriorMap == nil then
		exteriorMap = {}
	end
	local key = "Wing"
	if exteriorMap[key] == nil then
		exteriorMap[key] = {}
	end
	exteriorMap[key][info_data.WingID] = true
	CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Exterior, exteriorMap)
	if game._CFunctionMan:IsUnlockByFunTid(WING_FUNC_TID) then
		-- 翅膀功能已解锁，更新系统菜单红点
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, true)
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.WingDevelop, true)
	end

	AddWing(self, info_data)
end

-- 更新服务器数据
def.method("table").UpdateWingData = function(self, info_data)
	if info_data == nil then return end

	for i = 1, #self._ServerWingsList do
		local data = self._ServerWingsList[i]
		if data.Tid == info_data.WingID then
			data.Level = info_data.WingLevel
			data.CurExp = info_data.CurExp
			data.FightScore = info_data.FightScore
			break
		end
	end
end

-- 该天赋页是否已加点
def.method("number", "=>", "boolean").SoulDataAdded = function(self, talentPageIndex)
	local isDataChanged = false
	local static_data = self._TalentData[talentPageIndex].WingTalents
	for i = 1, #static_data do 
		if static_data[i].AddPoint > 0 then
			isDataChanged = true
			break
		end
	end
	return isDataChanged
end

-- 获取临时天赋技能的加点数量
def.method("number", "number", "=>", "number").GetTempTalentAddPoint = function(self, talentLvTid, talentPageIndex)
	local temp_talent_list = self._SkillNumTemp[talentPageIndex].WingTalents
	for _, data in ipairs(temp_talent_list) do
		if data.WingTalentID == talentLvTid then
			return data.AddPoint
		end
	end
	return 0
end

def.method("=>", "table").GetWingShowList = function (self)
	local serverMap = {}
	local showList = {}
	for _, v in ipairs(self._ServerWingsList) do
		serverMap[v.Tid] = true
		table.insert(showList, v)
	end
	for _, v in ipairs(self._AllWingsList) do
		if not serverMap[v.Tid] then
			table.insert(showList, v)
		end
	end
	local function sortFunc(a, b)
		if a.Tid < b.Tid then
			return true
		end
		return false
	end
	table.sort(showList, sortFunc)
	return showList
end

def.method("=>", "table").GetWingsList = function(self)
	return self._AllWingsList
end

def.method("userdata").ResolveTalentData = function(self, data)
	self._TalentData = data
end

-- 是否显示主界面红点
def.method("=>", "boolean").IsShowRedPoint = function(self)
	-- 是否有未显示的
	local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
	if exteriorMap ~= nil then
		local redDotStatusMap = exteriorMap["Wing"]
		if redDotStatusMap ~= nil then
			for _, status in pairs(redDotStatusMap) do
				-- 有还未显示过的
				if status then
					return true
				end
			end
		end
	end
	-- 天赋页是否有红点
	-- if self:IsTalentHasRedPoint() then
	-- 	return true
	-- end
	-- 翅膀列表是否有可升级的
	do
		local function IsMaterialEnough(itemId, needNum)
			if itemId <= 0 then return false end
			local hasNum = game._HostPlayer._Package._NormalPack:GetItemCount(itemId)
			if needNum > hasNum then
				return false
			end
			return true
		end

		-- 道具ID读特殊ID表
		for _, info in ipairs(self._ServerWingsList) do
			local isMaxLv = self:GetWingLevelUpInfo(info.Tid, info.Level+1) == nil
			if not isMaxLv then
				-- 非满级
				local lvUpTemplate = self:GetWingLevelUpInfo(info.Tid, info.Level)
				if lvUpTemplate ~= nil then
					if lvUpTemplate.GradeID > 0 then
						-- 进阶
						local gradeUpTemplate = self:GetWingGradeUpData(lvUpTemplate.GradeID)
						if gradeUpTemplate ~= nil and IsMaterialEnough(lvUpTemplate.NeedItemTID, gradeUpTemplate.CostItemNum) then
							return true
						end
					else
						-- 升级
						if IsMaterialEnough(lvUpTemplate.NeedItemTID, lvUpTemplate.NeedItemNum) then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- 翅膀天赋技能是否有红点显示
def.method("=>", "boolean").IsTalentHasRedPoint = function(self)
	local talentDataList = self:GetTalentListData()
	if talentDataList ~= nil then
		local temp_data = nil
		local curPageId = game._HostPlayer:GetCurWingPageId()
		for _, talentData in ipairs(talentDataList) do
			if talentData.PageId == curPageId then
				temp_data = talentData
				break
			end
		end
		if temp_data ~= nil then
			if temp_data.TalentPoint > 0 then
				local isAllMaxLevel = true
				for _, talentInfo in ipairs(temp_data.WingTalents) do
					local template = self:GetTalentLevelTemplate(talentInfo.WingTalentID)
					if template ~= nil then
						local limit_length = #template.TalentPreLimits
						if limit_length > 0 then
							local max_level = template.TalentPreLimits[limit_length].MaxLevel
							if talentInfo.AddPoint < max_level then
								isAllMaxLevel = false
								break
							end
						end
					end
				end
				if not isAllMaxLevel then
					-- 天赋页剩余点大于0，且还有技能未满级
					return true
				end
			end
		end
	end
	return false
end

---------------------------------- 协议 -----------------------------------------
--翅膀列表 开启界面
def.method().C2SWingViewOpen = function(self)
	local C2SWingViewList = require "PB.net".C2SWingViewList
	local protocol = C2SWingViewList()
	PBHelper.Send(protocol)
end

-- 选择展示翅膀
def.method("number").C2SWingSelectShow = function(self, id)
	local C2SWingSelectShow = require "PB.net".C2SWingSelectShow
	local protocol = C2SWingSelectShow()
	protocol.WingID = id
	PBHelper.Send(protocol)	
end 

-- 翅膀升级
def.method("number", "boolean", "boolean").C2SWingLevelUp = function(self, id, assist, quick)
	local C2SWingLevelUp = require "PB.net".C2SWingLevelUp
	local protocol = C2SWingLevelUp()
	protocol.WingID = id
	-- protocol.UseAssistItem = assist 		--是否使用辅助道具
	-- protocol.QuickUse = quick 				--是否快捷使用
	PBHelper.Send(protocol)
end 

--翅膀进阶
def.method("number").C2SWingGradeUp = function(self, id)
	local C2SWingGradeUp = require "PB.net".C2SWingGradeUp
	local protocol = C2SWingGradeUp()
	protocol.WingID = id
	PBHelper.Send(protocol)
end 

--翅膀天赋查看
def.method().C2SWingTalentView = function(self)
	local C2SWingTalentView = require "PB.net".C2SWingTalentView
	local protocol = C2SWingTalentView()
	PBHelper.Send(protocol)
end 

-- 翅膀天赋选择
-- TalentPageID
def.method("number").C2SWingTalentSelect = function(self, talentPageIndex)
	local C2SWingTalentSelect = require "PB.net".C2SWingTalentSelect
	local protocol = C2SWingTalentSelect()
	protocol.TalentPageID = self._SkillNumTemp[talentPageIndex].PageId					 --天赋页ID
	PBHelper.Send(protocol)
end 

--翅膀天赋加点
def.method("number").C2SWingTalentAddPoint = function(self, talentPageIndex)
	local C2SWingTalentAddPoint = require "PB.net".C2SWingTalentAddPoint
	local protocol = C2SWingTalentAddPoint()
	local WingTalentInfo = require "PB.net".WingTalentInfo
	local isDataChanged = false
	local static_data = self._TalentData[talentPageIndex].WingTalents
	local tmp_data = self._SkillNumTemp[talentPageIndex].WingTalents
	
	for i = 1, #tmp_data do 
		if tmp_data[i].AddPoint ~= static_data[i].AddPoint then
			local tmp = WingTalentInfo()
			tmp.WingTalentID = tmp_data[i].WingTalentID
			tmp.AddPoint = tmp_data[i].AddPoint
			table.insert(protocol.TalentInfos, tmp)								
			isDataChanged = true
		end
	end
	protocol.TalentPageID = self._SkillNumTemp[talentPageIndex].PageId
	if isDataChanged then
		PBHelper.Send(protocol)
	end
end 

--翅膀天赋洗点
def.method("number").C2SWingTalentWashPoint = function(self, talentPageIndex)
	local C2SWingTalentWashPoint = require "PB.net".C2SWingTalentWashPoint
	local protocol = C2SWingTalentWashPoint()
	protocol.TalentPageID = self._SkillNumTemp[talentPageIndex].PageId			--天赋页ID
	PBHelper.Send(protocol)
end 

CWingsMan.Commit()
return CWingsMan