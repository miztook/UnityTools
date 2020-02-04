--[[----------------------------------------------
         		 万物志管理器
          				--- by ml 2017.5.18
--------------------------------------------------]]
local Lplus = require "Lplus"
local CManualMan = Lplus.Class("CManualMan")
local def = CManualMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelMainTips = require "GUI.CPanelMainTips"
--教学数据链表
def.field("table")._DataTable = nil
--万物志已领取数据
def.field("table")._TotleRewardIds = nil
--def.field("table").table_AnecdoteData = nil
def.field("number")._ManualOpenEId = 0 --要打开的条目ID
def.field("number")._ManualActiveCount = 0 --要打开的条目ID
def.field("boolean")._ManualServerRedPoint = false --服务器红点
def.field("function")._ManualIsEyesShowCallBack = nil

def.static("=>", CManualMan).new = function ()
    local obj = CManualMan()
    return obj
end

def.method().CleanData = function(self)
	self._DataTable = nil
	self._TotleRewardIds = nil
	self._ManualActiveCount = 0
end

def.method().Cleanup = function (self)
	self._ManualServerRedPoint = false
end

--获取所有万物志配置
def.method("=>","table").GetData = function(self)
	if self._DataTable == nil then return nil end
	return self._DataTable
end

def.method("=>","table").GetAllManualData = function(self)
	if self._DataTable == nil then return nil end
	return self._DataTable[EnumDef.ManualType.Manual]
end

def.method("number","number","=>","table").GetDataByTypeAndEntrieId = function(self,maType,entrieId)
	if self._DataTable == nil then return nil end
	local bigTypedataArray = self._DataTable[maType]
	if bigTypedataArray == nil then return nil end
	if maType == EnumDef.ManualType.Manual then
		local smallTypedataArray = nil
		local smallTypeData = nil
		local entrieData = nil
		for i,v in ipairs(bigTypedataArray) do
			--print("大类型数组中找到小类型数组bigTypedataArray[i]======",i)
			----print_r(v)
			smallTypedataArray = v.BigTypeDatas
			for i2,v2 in ipairs(smallTypedataArray) do
				--print("小类型数组中找到条目数组smallTypedataArray[i]======",i)
				--print_r(v)
				smallTypeData = v2.SmallTypeDatas
				for i3,v3 in ipairs(smallTypeData) do
					if v3.EntrieId == entrieId then
						--print("条目数组中找到条目entrieDataArray[i]======",i)
						entrieData = v3
						--赋值一下获得的index
						v3.index = i3  --条目
						v3.sindex = i2 --小类型
						v3.bindex = i   --大类型
						break
					end
				end
			end
		end
		return entrieData
	elseif maType == EnumDef.ManualType.Anecdote then
		local bigTypeData = nil
		local entrieData = nil
		for i,v in ipairs(bigTypedataArray) do
			--print("大类型数组中找到小类型数组bigTypedataArray[i]======",i)
			bigTypeData = v.BigTypeDatas
			for i2,v2 in ipairs(bigTypeData) do
				if v2.EntrieId == entrieId then

					--print("条目数组中找到条目entrieDataArray[i]======",i)
					entrieData = v2
					--赋值一下获得的index
					v2.index = i2
					break
				end
			end
		end
		return entrieData
	end
end

def.method("=>", "table").GetAllAnecdoteData = function(self)
	if self._DataTable == nil then return nil end
	return self._DataTable[EnumDef.ManualType.Anecdote]
end

--获取已经完成的异闻录奖励
def.method("=>", "table").GetAllFinishAnecdote = function(self)
	if self._DataTable == nil then return nil end
	local FinishAnecdoteTypes = {}

	local bigTypedataArray = self._DataTable[EnumDef.ManualType.Anecdote]
	if bigTypedataArray == nil then return nil end
	
	local bigTypeData = nil
	for _,v in ipairs(bigTypedataArray) do
		--print("大类型数组中找到小类型数组bigTypedataArray[i]======",i)
		bigTypeData = v.BigTypeDatas
		local isFinish = true
		for i2,v2 in ipairs(bigTypeData) do
	        local finishIndex = 0 
	        for _,v3 in ipairs(v2.Details) do
	            if v3.IsUnlock then
	                finishIndex = finishIndex + 1
	            end
	        end
			if finishIndex < #v2.Details then
				--如果解锁的项目 没有全部完成，则整体没有完成
				isFinish = false
				break
			end
		end
		if isFinish == true then
			FinishAnecdoteTypes[#FinishAnecdoteTypes+1] = v.BigTypeId
			-- {
				
			-- }
		end
	end

	return FinishAnecdoteTypes
end

def.method("number","=>","boolean").NodeShowBigTypeRedPoint = function(self,bindex)
    local isShowBigType = false
    --local isShowBigTypeReward = false
    --local isShowBigTypeNew = false
    if bindex == 0 then
		isShowBigType = self:NodeShowTotleRewardRedPoint()
    else
        local data = self:GetData()
        local current_bigtype_manuals = data[EnumDef.ManualType.Manual][bindex]
        --local current_smalltype_manuals = current_bigtype_manuals.BigTypeDatas[sindex]

        for i,v in ipairs(current_bigtype_manuals.BigTypeDatas) do
            for i2,v2 in ipairs(v.SmallTypeDatas) do
                local tmpdata = self:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,v2.EntrieId)
                if bindex == tmpdata.bindex and not self:IsDrawReward(tmpdata) then
                    isShowBigType = true
                    break
                end
--626 红点修改
--[[            	local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
				if Map ~= nil and Map[v2.EntrieId] ~= nil then
					isShowBigType = true
					break
				end--]]
            end
        end      
    end

    --print("NodeShowBigTypeRedPoint",isShowBigType,bindex,debug.traceback())
    return isShowBigType
end

def.method("number","number","=>","boolean").NodeShowSmallTypeRedPoint = function(self,bindex,sindex)
    local isShowSmallType = false
    --local isShowSmallTypeReward = false
    --local isShowSmallTypeNew = false
    if bindex == 0 then
    	isShowSmallType = self:NodeShowTotleRewardRedPoint()
    else
        local data = self:GetData()
        local current_bigtype_manuals = data[EnumDef.ManualType.Manual][bindex]
        local current_smalltype_manuals = current_bigtype_manuals.BigTypeDatas[sindex]

        for i,v in ipairs(current_smalltype_manuals.SmallTypeDatas) do
            if v ~= nil then
                local tmpdata = self:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,v.EntrieId)
                if bindex == tmpdata.bindex and sindex == tmpdata.sindex and not self:IsDrawReward(tmpdata) then
                    isShowSmallType = true
                    break
                end
--626 红点修改
--[[            	local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
				if Map ~= nil and Map[v.EntrieId] ~= nil then
					isShowSmallType = true
					break
				end--]]
            end
        end    
    end

    --print("NodeShowSmallTypeRedPoint",isShowSmallType,bindex,sindex,debug.traceback())
    return isShowSmallType
end

def.method("=>","boolean").NodeShowTotleRewardRedPoint = function(self)
	local isShow = false

    local tids = CElementData.GetAllTid("ManualTotalReward")
    for i,v in ipairs(tids) do
    	local template = CElementData.GetManualTotalRewardTemplate(v)
    	if self._ManualActiveCount >= template.TotalCount and (self._TotleRewardIds == nil or #self._TotleRewardIds == 0 or self._TotleRewardIds[v] == nil) then
    		isShow = true
    		break
    	end
    end
	
	return isShow
end

def.method("=>","boolean").NodeShowNewManualRedPoint = function(self)
	local isShow = false

	local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
	if Map ~= nil then
		for k,v in pairs( Map ) do
			if v then
				isShow = true
				break
			end
		end
	end
	return isShow
end



def.method("=>","boolean").IsShowManualRedPoint = function (self)
    local isShow1 = self:NodeShowTotleRewardRedPoint()
    --626 红点修改
    local isShow2 = false--self:NodeShowNewManualRedPoint()
    local isShow3 = false

    local data = self:GetData()
    if data ~= nil then
		for i0,v0 in ipairs( data[EnumDef.ManualType.Manual] ) do
			local current_bigtype_manuals = v0
			for i1,v1 in ipairs( current_bigtype_manuals.BigTypeDatas ) do
				local current_smalltype_manuals = v1
			    for i2,v2 in ipairs(current_smalltype_manuals.SmallTypeDatas) do
		            local tmpdata = self:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,v2.EntrieId)
		            if not self:IsDrawReward(tmpdata) then
		                isShow3 = true
		                break
		            end
			    end 
			end
		end
		self._ManualServerRedPoint = isShow1 or isShow2 or isShow3
  	end

  	self._ManualServerRedPoint = self._ManualServerRedPoint or isShow1 or isShow2 or isShow3
  	--print("IsShowManualRedPoint",self._ManualServerRedPoint,isShow1,isShow2,isShow3,debug.traceback())
    return self._ManualServerRedPoint
end

def.method("=>","boolean").IsShowRedPoint = function(self)	
	local isShow = self: IsShowManualRedPoint() or game._AcheivementMan:IsHaveRedPoint()
	return isShow
end

def.method("table","=>","boolean").IsDrawReward = function (self,selectdata)
    -- 是否已经领奖
    local IsDrawReward = true
	if selectdata == nil then
		return IsDrawReward
	end
    --  计算进度/总进度
    local finishIndex = 0 
    --print_r(data.Details)
    for i,v in ipairs(selectdata.Details) do
        if v.IsUnlock then
            finishIndex = finishIndex + 1
        end
    end

    local template = CElementData.GetManualEntrieTemplate(selectdata.EntrieId)
    if not selectdata.IsDrawReward and finishIndex == #selectdata.Details and template.RewardId ~= 0 then
        IsDrawReward = false
    end
    return IsDrawReward
end


def.method("=>","number").GetAcitveCountValue = function (self)
	return self._ManualActiveCount
end

def.method("=>","table").GetAddPropertys = function (self)
	local AddPropertys = {}

	if self._DataTable == nil then return nil end
	local bigTypedataArray = self._DataTable[EnumDef.ManualType.Manual]
	if bigTypedataArray == nil then return nil end
		local smallTypedataArray = nil
		local smallTypeData = nil
		local entrieData = nil
		for i,v in ipairs(bigTypedataArray) do
			--print("大类型数组中找到小类型数组bigTypedataArray[i]======",i)
			----print_r(v)
			smallTypedataArray = v.BigTypeDatas
			for i2,v2 in ipairs(smallTypedataArray) do
				--print("小类型数组中找到条目数组smallTypedataArray[i]======",i)
				--print_r(v)
				smallTypeData = v2.SmallTypeDatas
				for i3,v3 in ipairs(smallTypeData) do
					if v3.IsDrawReward then

						local template = CElementData.GetManualEntrieTemplate(v3.EntrieId)
						
						local ids = string.split(template.AttrIds, '*') 
						local values = string.split(template.AttrValues, '*') 

			            if ids ~= nil and values ~= nil then
			                for i, k in ipairs(ids) do
			                    local id = tonumber(ids[i])
			                   	local value = tonumber(values[i])
			                    if id ~= nil and value ~= nil then
			                    	if AddPropertys[id] == nil then
				                        AddPropertys[id] = 
				                        {
				                        	_ID = id,
				                        	_Value = value
				                    	}
				                    else
				                    	AddPropertys[id]._Value = AddPropertys[id]._Value + value
				                    end
			                    end
			                end
			            end	
					end
				end
			end
		end

	return AddPropertys
end

def.method().AddAllEntrieByClient = function(self)
	local allIds = CElementData.GetAllTid("ManualAnecdote")
	for i, tid in ipairs(allIds) do
		local data = CElementData.GetTemplate("ManualAnecdote", tid)
		for _, smallData in ipairs(data.SmallDatas) do
			local EntrieIDs = string.split(smallData.Entries, "*")
--[[			print("======================",tid,smallData.SmallTypeId)
			print( EntrieIDs )--]]
			for i=1, #EntrieIDs do
				local EntrieID = tonumber( EntrieIDs[i] )
				if EntrieID ~= nil then
					self:AddOneEntrieByClient(EntrieID,data.Id,smallData.SmallTypeId,data.MaType)
				end
			end

		end
	end
end


--添加条目 --模板、大类型、小类型
def.method("number","number","number","number").AddOneEntrieByClient = function(self,EntrieID,BigTypeId,SmallTypeId,MaType)
	local v = CElementData.GetTemplate("ManualEntrie", EntrieID) 
	if not v.IsOpen then
		return
	end
	--条目数据内容
	local tmpDetails = {}
	for k2,v2 in ipairs(v.Details) do
		--if v2 and v2.Id then
			tmpDetails[#tmpDetails+1] 		= 
			{
				DetailId 		= v2.DetailId,
				IsUnlock 		= false,--v2.isUnlock,	-- 是否已解锁
				UnlockParam 	= 0,--v2.UnlockParam	-- 解锁参数
			}

			-- print("------------------------------------------",v.EntrieId,k2)
			-- print_r(tmpDetails)

			-- print("endendendendendendend000000000")
		--end
	end

	--	已解锁的排序
	local function sortfunction(value1, value2)
		if value1 == nil or value2 == nil then
			return false
		end

--[[		if value1.IsUnlock and not value2.IsUnlock then
	        return true
	    elseif not value1.IsUnlock and value2.IsUnlock then
	    	return false
	    else--]]
	    if value1.DetailId < value2.DetailId then
	    	return true
	    else
	        return false
	    end
		--return value1.isUnlock and not value2.isUnlock
	end
	table.sort(tmpDetails, sortfunction)
	--条目数据
	local data = 
	{
		EntrieId		= EntrieID, --v.EntrieId,	-- 条目ID
		BigTypeId 		= BigTypeId, --v.BigTypeId,	-- 大分类ID
		SmallTypeId		= SmallTypeId, --v.SmallTypeId,	-- 小分类ID
		MaType 			= MaType,--v.MaType,	-- 类型 Data.EManualAnecdoteType
		IsShow 			= false,--v.isShow,	-- 是否已显示
		ShowParam 		= 0,--v.ShowParam,	-- 可显示参数
		IsDrawReward	= false, --v.isDrawReward,	-- 是否已领取条目奖励
		Details         = tmpDetails
	}


	if self._DataTable[MaType] == nil then
		self._DataTable[MaType] = {}
	end
	-------------------------------遍历大类型数组------------------------------------

	local bigTypedataArray = self._DataTable[MaType]
	local smallTypedataArray = nil
	--如果 数组里面有这个类型
	for i2,bigTypedata in ipairs(bigTypedataArray) do
		if bigTypedata.BigTypeId == BigTypeId then
			smallTypedataArray = bigTypedata.BigTypeDatas
			break
		end
	end

	--如果 数组里面没有这个类型
	if smallTypedataArray == nil then
		--先创建这个类型
		local bigTypedata = {}
		bigTypedata.BigTypeId = BigTypeId
		bigTypedata.BigTypeDatas = {}
		bigTypedataArray[#bigTypedataArray+1] = bigTypedata

		smallTypedataArray = bigTypedata.BigTypeDatas
	end

	-------------------------------遍历小类型数组------------------------------------
	local smallisHave = false
	for i3,smallTypedata in ipairs(smallTypedataArray) do
		if smallTypedata.SmallTypeId == SmallTypeId then
			smallTypedata.SmallTypeDatas[#smallTypedata.SmallTypeDatas+1] = data
			smallisHave = true
		end
	end

	--如果 数组里面没有这个类型
	if smallisHave == false then
		--先创建这个类型
		local smallTypedata = {}
		smallTypedata.SmallTypeId = SmallTypeId
		smallTypedata.SmallTypeDatas = {}
		smallTypedataArray[#smallTypedataArray+1] = smallTypedata
		--再将此类型放入数据
		smallTypedata.SmallTypeDatas[#smallTypedata.SmallTypeDatas+1] = data --smallTypedata
	end
end

--添加条目
def.method("table").AddOneEntrie = function(self,v)
	--条目数据内容
	local tmpDetails = {}
	for k2,v2 in ipairs(v.Details) do
		--if v2 and v2.Id then
			tmpDetails[#tmpDetails+1] 		= 
			{
				DetailId 		= v2.DetailId,
				IsUnlock 		= v2.isUnlock,	-- 是否已解锁
				UnlockParam 	= v2.UnlockParam	-- 解锁参数
			}

			-- print("------------------------------------------",v.EntrieId,k2)
			-- print_r(tmpDetails)

			-- print("endendendendendendend000000000")
		--end
	end

	--	已解锁的排序
	local function sortfunction(value1, value2)
		if value1 == nil or value2 == nil then
			return false
		end

--[[		if value1.IsUnlock and not value2.IsUnlock then
	        return true
	    elseif not value1.IsUnlock and value2.IsUnlock then
	    	return false
	    else--]]
	    if value1.DetailId < value2.DetailId then
	    	return true
	    else
	        return false
	    end
		--return value1.isUnlock and not value2.isUnlock
	end
	table.sort(tmpDetails, sortfunction)
	--条目数据
	local data = 
	{
		EntrieId		= v.EntrieId,	-- 条目ID
		BigTypeId 		= v.BigTypeId,	-- 大分类ID
		SmallTypeId		= v.SmallTypeId,	-- 小分类ID
		MaType 			= v.MaType,	-- 类型 Data.EManualAnecdoteType
		IsShow 			= v.isShow,	-- 是否已显示
		ShowParam 		= v.ShowParam,	-- 可显示参数
		IsDrawReward	= v.isDrawReward,	-- 是否已领取条目奖励
		Details         = tmpDetails
	}

	--激活 暂时用 领奖代替
	if v.isDrawReward then
		self._ManualActiveCount = self._ManualActiveCount + 1
	end
	 -- print("------------------------------------------",v.EntrieId)
	 -- print_r(data)

	if self._DataTable[v.MaType] == nil then
		self._DataTable[v.MaType] = {}
	end
	-------------------------------遍历大类型数组------------------------------------

	local bigTypedataArray = self._DataTable[v.MaType]

	if data.MaType == EnumDef.ManualType.Manual then
		local smallTypedataArray = nil
		--如果 数组里面有这个类型
		for i2,bigTypedata in ipairs(bigTypedataArray) do
			if bigTypedata.BigTypeId == v.BigTypeId then
				smallTypedataArray = bigTypedata.BigTypeDatas
				break
			end
		end

		--如果 数组里面没有这个类型
		if smallTypedataArray == nil then
			--先创建这个类型
			local bigTypedata = {}
			bigTypedata.BigTypeId = v.BigTypeId
			bigTypedata.BigTypeDatas = {}
			bigTypedataArray[#bigTypedataArray+1] = bigTypedata

			smallTypedataArray = bigTypedata.BigTypeDatas
		end

		-------------------------------遍历小类型数组------------------------------------
		local smallisHave = false
		for i3,smallTypedata in ipairs(smallTypedataArray) do
			if smallTypedata.SmallTypeId == v.SmallTypeId then

				local dataisHave = false
				-- 如果有数据 则 覆盖
				for i4,SmallTypeData in ipairs(smallTypedata.SmallTypeDatas) do
					if SmallTypeData.EntrieId == data.EntrieId then
						smallTypedata.SmallTypeDatas[i4] = data
						dataisHave = true
						break
					end
				end

				if dataisHave == false then
					smallTypedata.SmallTypeDatas[#smallTypedata.SmallTypeDatas+1] = data
				end
				smallisHave = true
			end
		end

		--如果 数组里面没有这个类型
		if smallisHave == false then
			--先创建这个类型
			local smallTypedata = {}
			smallTypedata.SmallTypeId = v.SmallTypeId
			smallTypedata.SmallTypeDatas = {}
			smallTypedataArray[#smallTypedataArray+1] = smallTypedata
			--再将此类型放入数据
			smallTypedata.SmallTypeDatas[#smallTypedata.SmallTypeDatas+1] = data --smallTypedata
		end
	elseif data.MaType == EnumDef.ManualType.Anecdote then
		local bigisHave = false
		for i2,bigTypedata in ipairs(bigTypedataArray) do
			if bigTypedata.BigTypeId == v.BigTypeId then
				bigTypedata.BigTypeDatas[#bigTypedata.BigTypeDatas+1] = data
				bigisHave = true
				break
			end
		end
		if bigisHave == false then
			--先创建这个类型
			local bigTypedata = {}
			bigTypedata.BigTypeId = v.BigTypeId
			bigTypedata.BigTypeDatas = {}
			bigTypedataArray[#bigTypedataArray+1] = bigTypedata
			--再将此类型放入数据
			bigTypedata.BigTypeDatas[#bigTypedata.BigTypeDatas+1] = data --smallTypedata
		end
	end
end
--加载所有万物志数据
def.method("table").OnS2CManualData = function(self,srcdata)
	self._DataTable = {}
	self._TotleRewardIds = {}
	self._ManualActiveCount = 0

	self:AddAllEntrieByClient()

	for k,v in ipairs(srcdata.Mas) do
		--显示的添加
		if v.isShow then
			self:AddOneEntrie(v)
		end
	end

	for i,v in ipairs(srcdata.TotleRewardIds) do
		self._TotleRewardIds[v] = 1
	end
	--print_r(self._DataTable)
	--print("#smallTypedataArray",#self._DataTable)
end

--领奖
def.method("table").OnS2CManualDraw = function(self,srcdata)
	
	local event = require("Events.ManualDataChangeEvent")()
	event._Type = EnumDef.EManualEventType.Manual_RECIEVE

	local dataManual = self:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,srcdata.EntrieId)
	if dataManual ~= nil then
		self._ManualActiveCount = self._ManualActiveCount + 1

		dataManual.IsDrawReward = true
		event._Data = dataManual
		CGame.EventManager:raiseEvent(nil, event)
	end

	local dataAnecdote = self:GetDataByTypeAndEntrieId(EnumDef.ManualType.Anecdote,srcdata.EntrieId)
	if dataAnecdote ~= nil then
		dataAnecdote.IsDrawReward = true
		event._Data = dataAnecdote
		CGame.EventManager:raiseEvent(nil, event)
	end
end

def.method("number").OnS2CManualTotalDraw = function(self,id)
	self._TotleRewardIds[id] = 1
	local event = require("Events.ManualDataChangeEvent")()
	event._Type = EnumDef.EManualEventType.Manual_RECIEVETOTAL
	event._Data = { _ID = id } 
	CGame.EventManager:raiseEvent(nil, event)	
end

--新增数据
def.method("table").OnS2CManualInc = function(self,srcdata)
	--print("OnS2CManualInc=")
	--TODO("您新解锁了一项万物志")

	local IsShowRed = false
	for i,v in ipairs(srcdata) do
		local template = CElementData.GetManualEntrieTemplate(v.EntrieId)
		--新增TIPS 屏蔽
		--CPanelMainTips.Instance():ShowFindManualTips(template.DisPlayName,v.EntrieId)

	    -- 是否已经领奖
        local IsDrawReward = true
        local finishIndex = 0 
	    for k2,v2 in ipairs(v.Details) do
	        if v2.isUnlock then
	            finishIndex = finishIndex + 1
	        end
	    end
	    if not v.isDrawReward and finishIndex == #v.Details and template.RewardId ~= 0 then
        	IsDrawReward = false
    	end

		for k2,v2 in ipairs(v.Details) do
			if not IsDrawReward then
	            IsShowRed = true
			end
		end

		-- 保存红点显示状态
		local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
		if Map == nil then
			Map = {}
		end
		if Map[v.EntrieId] == nil then
			Map[v.EntrieId] = true
		end
		CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Manual, Map)
	end
	--new531
	if IsShowRed then
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,true)
	end
	--newend

	--print_r(srcdata)
	if self._DataTable == nil then return end 

	local fristdata = nil
	for i,v in ipairs(srcdata) do
		if v.isShow then
			if fristdata == nil then
				fristdata = v
			end
			self:AddOneEntrie(v)
		end
	end

	--print_r(self._DataTable)
	--显示到第一个刷新页
	if fristdata ~= nil then
		local event = require("Events.ManualDataChangeEvent")()
		event._Type = EnumDef.EManualEventType.Manual_UPDATE
		event._Data = self:GetDataByTypeAndEntrieId(fristdata.MaType,fristdata.EntrieId)
		CGame.EventManager:raiseEvent(nil, event)
	end
end

--更新已有数据
def.method("table").OnS2CManualUpdate = function(self,srcdata)
--print("OnS2CManualUpdate=============")
	--print_r(data)
	--new531
	-- 是否已经领奖
    local IsShowRed = false
    --newend
	for i,v in ipairs(srcdata) do
		if v.IsDetailUnLock then
			local template = CElementData.GetManualEntrieTemplate(v.EntrieId)
            if v.IsAllUnLock and template.RewardId ~= 0 then
            	--只赋值一次
            	if not IsShowRed then
                	IsShowRed = true
                end

            end

			if v.IsAllUnLock then
				CPanelMainTips.Instance():ShowFindManualTips(template.DisPlayName,StringTable.Get(20809),v.EntrieId)
			else
				CPanelMainTips.Instance():ShowFindManualTips(template.DisPlayName,StringTable.Get(20810),v.EntrieId)
			end
		end
	end
	--new531
	if IsShowRed then
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,true)
	end
	--newend

	if self._DataTable == nil then return end 

	local fristdata = nil
	for i,v in ipairs(srcdata) do
		local entrieData = self:GetDataByTypeAndEntrieId(v.MaType,v.EntrieId)
		if entrieData == nil then
			--print("警告：更新中没有这条数据",v.MaType,v.EntrieId)
			break
		end
		entrieData.IsShow = true
		if fristdata == nil then
			fristdata = entrieData
		end
		for i1,v1 in ipairs(entrieData.Details) do
			if v1.DetailId == v.DetailId then
				--print("条目子内容数组中找到子内容detailsDataArray[i]======",i)
				v1.IsUnlock = v.IsDetailUnLock
				break
			end
		end
		--entrieData.IsAllUnLock = v.IsAllUnLock
		--	已解锁的排序
		local function sortfunction(value1, value2)
			if value1 == nil or value2 == nil then
				return false
			end

--[[			if value1.IsUnlock and not value2.IsUnlock then
		        return true
		    elseif not value1.IsUnlock and value2.IsUnlock then
		    	return false
		    else--]]
		    if value1.DetailId < value2.DetailId then
		    	return true
		    else
		        return false
		    end
		end
		table.sort(entrieData.Details, sortfunction)
	end

	local event = require("Events.ManualDataChangeEvent")()
	event._Type = EnumDef.EManualEventType.Manual_UPDATE
	event._Data = fristdata
	CGame.EventManager:raiseEvent(nil, event)
end

-- local function ManualFinishCallBack(isEnable)
-- {

-- }
--local ManualIsEyesShowCallBack = nil
def.method("table").OnS2CManualIsEyesShow = function(self,srcdata)
	local isUnlock = false
	for i,v in ipairs(srcdata) do
		isUnlock = v.IsShow
		if isUnlock then
			break
		end
	end

	if self._ManualIsEyesShowCallBack ~= nil then
		self._ManualIsEyesShowCallBack(isUnlock)
		self._ManualIsEyesShowCallBack = nil
	end
	--print("OnS2CManualIsFinish=",isUnlock)
end

------------------C2S----------------------------
--同步消息 
def.method().SendC2SManualDataSync = function(self)
	local C2SManualDataSync = require "PB.net".C2SManualDataSync
	local protocol = C2SManualDataSync()
	PBHelper.Send(protocol)
	--print("SendC2SManualDataSync =")
end

--领取奖励
def.method('number').SendC2SManualDraw = function(self,entrieId)
	local C2SManualDraw = require "PB.net".C2SManualDraw
	local protocol = C2SManualDraw()
	protocol.EMAType = 0
	protocol.EntrieId = entrieId
	PBHelper.Send(protocol)
	--print("SendC2SManualDraw =")
end

--领取万物志阶段奖励
def.method('number').SendC2SManualTotalDraw = function(self,Id)
	local C2SManualTotalDraw = require "PB.net".C2SManualTotalDraw
	local protocol = C2SManualTotalDraw()
	protocol.TotalRewardId = Id
	PBHelper.Send(protocol)
	--print("SendC2SManualDraw =")
end



--询问是否完成
def.method('table','function').SendC2SManualIsEyesShow = function(self,entrieDetails,CallBack)
	local C2SManualIsEyesShow = require "PB.net".C2SManualIsEyesShow
	local protocol = C2SManualIsEyesShow()

	for i,v in ipairs(entrieDetails) do
		table.insert(protocol.EntrieDetailIds,tonumber(v))
	end

	PBHelper.Send(protocol)
	self._ManualIsEyesShowCallBack = CallBack
	--print("SendC2SManualIsEyesShow")
end

CManualMan.Commit()
return CManualMan