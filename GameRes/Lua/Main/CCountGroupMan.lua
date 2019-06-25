--------------------------------------------
---------------次数组逻辑处理  by:lidaming  2019/05/31
--------------------------------------------

local Lplus = require "Lplus"
local CCountGroupMan = Lplus.Class("CCountGroupMan")
local def = CCountGroupMan.define
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

def.field("table")._CountGroupData = BlankTable -- 获取到所有次数组数据

def.static("=>", CCountGroupMan).new = function()
    local obj = CCountGroupMan()
	return obj
end


-- 次数组购买接口。
def.method("number", "number").BuyCountGroup = function (self, CurNum, CountGroupId)
	local NeedMoneyType = 0   	-- 花费的货币类型。
	local NeedMoneyCount = 0   	-- 花费的钱数。
	local BuyPlayName = ""		-- 购买的对应玩法名称
	local BuyCount = 0 			-- 已经购买的次数
	local UsedCount = 0			-- 已经使用的次数
	-- local MaxCount = 0			-- 最大次数
	local VIPAddCount = {}		-- VIP可购买次数
	local MaxBuyCount = 0		-- 最大可购买次数
	local CanBuyCount = 0		-- 可以购买的次数

	if CountGroupId ~= nil then
		if self._CountGroupData ~= nil then
			for i,v in pairs(self._CountGroupData) do
				if v.Tid == CountGroupId then 
					BuyCount = v.BuyCount
					UsedCount = v.Count
				end 
			end
		end
		-- warn("lidaming ---->BuyCount ==", BuyCount, UsedCount, CurNum)
		local countGroup = CElementData.GetTemplate("CountGroup", CountGroupId)
		if countGroup == nil then warn("countGroup data is nil!!!") return end
		NeedMoneyType = countGroup.CostMoneyId
		NeedMoneyCount = countGroup.CostMoneyCount + (BuyCount * countGroup.CostInc)
		BuyPlayName = countGroup.Name
		-- MaxCount = countGroup.MaxCount
		string.gsub(countGroup.VipInc, '[^*]+', function(w) table.insert(VIPAddCount, w) end )		
		if VIPAddCount[game._HostPlayer._InfoData._GloryLevel] ~= nil then
			MaxBuyCount = countGroup.InitBuyCount + tonumber(VIPAddCount[game._HostPlayer._InfoData._GloryLevel])
		else
			MaxBuyCount = countGroup.InitBuyCount
		end
	end

	CanBuyCount = MaxBuyCount - BuyCount
	if CanBuyCount <= 0 then
		CanBuyCount = "<color=#F70000>" ..CanBuyCount.."</color>"
	end
	-- -- 当前未消耗次数
	-- if CurNum == MaxCount and (MaxCount - UsedCount + BuyCount) >= MaxCount then
	-- 	self._GUIMan: ShowTipText(StringTable.Get(31103), false)
	-- 	return
	-- end
	local callback = function(val)
		if val then                                                     
            local callback1 = function(val1)
                if val1 then
                    local C2SCountBuyReq = require "PB.net".C2SCountBuyReq
					local protocol = C2SCountBuyReq()
					protocol.CountGroupId = CountGroupId
					PBHelper.Send(protocol)
                end
            end
            local limit = {
                [EQuickBuyLimit.CurBuyCount] = BuyCount,
                [EQuickBuyLimit.MaxBuyCount] = MaxBuyCount,
            }
            MsgBox.ShowQuickBuyBox(NeedMoneyType, NeedMoneyCount, callback1, limit)
		end
	end
	-- warn("---------------lidaming C2SCountBuyReq---------------", NeedMoneyCount, MaxBuyCount)
	-- 补签需要msgBox提示
	local bit = require "bit"
	local title, msg, closeType = StringTable.GetMsg(50)
	local str = string.format(msg, ("<color=#FE8F0C>" ..BuyPlayName.."</color>"))
	local setting = {
        [MsgBoxAddParam.SpecialStr] = string.format(StringTable.Get(31105), tostring(CanBuyCount), tonumber(MaxBuyCount)),
        [MsgBoxAddParam.CostMoneyID] = 3,
        [MsgBoxAddParam.CostMoneyCount] = NeedMoneyCount,
    }
	MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback,nil,nil,MsgBoxPriority.Disconnect,setting)
end

-- 进入时购买次数接口。
def.method("number").BuyCountGroupWhenEnter = function (self, CountGroupId)
	local NeedMoneyType = 0   	-- 花费的货币类型。
	local NeedMoneyCount = 0   	-- 花费的钱数。
	local BuyPlayName = ""		-- 购买的对应玩法名称
	local BuyCount = 0 			-- 已经购买的次数
	local UsedCount = 0			-- 已经使用的次数
	local VIPAddCount = {}		-- VIP可购买次数
	local MaxBuyCount = 0		-- 最大可购买次数
	local CanBuyCount = 0		-- 可以购买的次数

	if CountGroupId ~= nil then
		if self._CountGroupData ~= nil then
			for i,v in pairs(self._CountGroupData) do
				if v.Tid == CountGroupId then 
					BuyCount = v.BuyCount
					UsedCount = v.Count
				end 
			end
		end
		-- warn("lidaming ---->BuyCount ==", BuyCount, UsedCount)
		local countGroup = CElementData.GetTemplate("CountGroup", CountGroupId)
		if countGroup == nil then warn("countGroup data is nil!!!") return end
		NeedMoneyType = countGroup.CostMoneyId
		NeedMoneyCount = countGroup.CostMoneyCount + (BuyCount * countGroup.CostInc)
		BuyPlayName = countGroup.Name
		-- MaxCount = countGroup.MaxCount
		string.gsub(countGroup.VipInc, '[^*]+', function(w) table.insert(VIPAddCount, w) end )		
		if VIPAddCount[game._HostPlayer._InfoData._GloryLevel] ~= nil then
			MaxBuyCount = countGroup.InitBuyCount + tonumber(VIPAddCount[game._HostPlayer._InfoData._GloryLevel])
		else
			MaxBuyCount = countGroup.InitBuyCount
		end
	end
	CanBuyCount = MaxBuyCount - BuyCount
	if CanBuyCount <= 0 then
		CanBuyCount = "<color=#F70000>" ..CanBuyCount.."</color>"
	end
	local callback = function(val)
		if val then                                                     
            local callback1 = function(val1)
                if val1 then
                    local C2SCountBuyReq = require "PB.net".C2SCountBuyReq
					local protocol = C2SCountBuyReq()
					protocol.CountGroupId = CountGroupId
					PBHelper.Send(protocol)
                end
            end
            local limit = {
                [EQuickBuyLimit.CurBuyCount] = BuyCount,
                [EQuickBuyLimit.MaxBuyCount] = MaxBuyCount,
            }
            MsgBox.ShowQuickBuyBox(NeedMoneyType, NeedMoneyCount, callback1, limit)
		end
	end
	-- warn("---------------lidaming C2SCountBuyReq---------------", NeedMoneyCount, MaxBuyCount)
	-- 补签需要msgBox提示
	local bit = require "bit"
	local title, msg, closeType = StringTable.GetMsg(101)
	local str = string.format(msg, ("<color=#FE8F0C>" ..BuyPlayName.."</color>"))
	local setting = {
        [MsgBoxAddParam.SpecialStr] = string.format(StringTable.Get(31105), tostring(CanBuyCount), tonumber(MaxBuyCount)),
        [MsgBoxAddParam.CostMoneyID] = 3,
        [MsgBoxAddParam.CostMoneyCount] = NeedMoneyCount,
    }
	MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback,nil,nil,MsgBoxPriority.Normal,setting)
end


-- 次数组对应最大次数（最大次数 + 已购买次数）
def.method("number", "=>", "number").OnCurMaxCount = function (self, CountGroupId)
	-- warn("lidaming ---->BuyCount ==", BuyCount, UsedCount)
	local GroupMax = 0
	local BuyCount = 0
	if self._CountGroupData ~= nil then
		for i,v in pairs(self._CountGroupData) do
			if v.Tid == CountGroupId then 
				BuyCount = v.BuyCount
			end 
		end
	end
	
	local countGroup = CElementData.GetTemplate("CountGroup", CountGroupId)
	if countGroup == nil then
		warn("countGroup data is nil!!! Wrong Tid:" .. CountGroupId)
	else
		GroupMax = countGroup.MaxCount
	end

	return GroupMax     -- + BuyCount
end

-- 次数组剩余可购买次数
def.method("number", "=>", "number").OnCurLaveCount = function (self, CountGroupId)
	local BuyCount = 0 			-- 已经购买的次数
	local VIPAddCount = {}		-- VIP可购买次数
	local MaxBuyCount = 0		-- 最大可购买次数
	
	if CountGroupId ~= nil then
		if self._CountGroupData ~= nil then
			for i,v in pairs(self._CountGroupData) do
				if v.Tid == CountGroupId then 
					BuyCount = v.BuyCount
				end 
			end
		end
		-- warn("lidaming ---->BuyCount ==", BuyCount, UsedCount)
		local countGroup = CElementData.GetTemplate("CountGroup", CountGroupId)
		if countGroup == nil then warn("countGroup data is nil!!!") return 0 end
		string.gsub(countGroup.VipInc, '[^*]+', function(w) table.insert(VIPAddCount, w) end )		
		if VIPAddCount[game._HostPlayer._InfoData._GloryLevel] ~= nil then
			MaxBuyCount = countGroup.InitBuyCount + tonumber(VIPAddCount[game._HostPlayer._InfoData._GloryLevel])
		else
			MaxBuyCount = countGroup.InitBuyCount
		end
	end
	return MaxBuyCount - BuyCount
end

-- 购买次数需要货币和数量 {param.MoneyType    param.MoneyCount}
def.method("number" , "=>", "table").MoneyInfoByCountGroupId = function (self, CountGroupId)
	local param = nil
	local BuyCount = 0 			-- 已经购买的次数
	if CountGroupId ~= nil then
		if self._CountGroupData ~= nil then
			for i,v in pairs(self._CountGroupData) do
				if v.Tid == CountGroupId then 
					BuyCount = v.BuyCount
				end 
			end
		end
		local countGroup = CElementData.GetTemplate("CountGroup", CountGroupId)
		if countGroup == nil then warn("countGroup data is nil!!!") return nil end
		param = {}
		param.MoneyType = countGroup.CostMoneyId
		param.MoneyCount = countGroup.CostMoneyCount + (BuyCount * countGroup.CostInc)
	end
	return param
end

def.method().Release = function (self)
	self._CountGroupData = {}
end

CCountGroupMan.Commit()
return CCountGroupMan