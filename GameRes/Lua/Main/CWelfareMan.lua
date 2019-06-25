local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local EScriptKeyType = require "PB.data".EScriptKeyType
local EScriptConfigType = require "PB.Template".ScriptConfig.EScriptConfigType
local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance".Instance()

local CWelfareMan = Lplus.Class("CWelfareMan")
local def = CWelfareMan.define

def.field("number")._UpdateInterval = 0
def.field("number")._CurrentDay = 0
def.field("number")._CurrentTotalDay = 0
-- def.field("number")._CurrentMonth = 0
def.field("string")._CurrentTempId = ""
def.field("number")._OnlineTime = 0         -- 在线时间
def.field("number")._TimeId = 0  
def.field("number")._CurrentGloryLevel = 0
def.field("boolean")._IsOpenSign = false
def.field("boolean")._IsOpenSpecialSign = false
def.field("boolean")._IsOpenGlory = false
def.field("boolean")._IsOnlineReward = true
def.field("boolean")._IsOpenGloryRedPoint = false
def.field("number")._CurrentSignedDays = 0              --已签总天数
def.field("number")._CurFestivalId = 0                     -- 当前材料兑换活动id

def.field("table")._WelfareTypeTable = BlankTable
def.field("table")._SignInfoTable = BlankTable
def.field("table")._SignDaysTable = BlankTable
def.field("table")._GloryGiftsTable = BlankTable
def.field("table")._SpecialSignInfoTable = BlankTable
def.field("table")._GloryGiftBuyInfoList = BlankTable
def.field("table")._OnlineRewardDataTable = BlankTable

def.field("table")._FestivalInfoList = BlankTable

local GLORY_UNLOCKED_BY_TID = 110  -- 冒险生涯教学功能Tid
def.static("=>", CWelfareMan).new = function()
    local obj = CWelfareMan()
    return obj
end

---------------------------------------------------------------------------------
--------------------------服务器相关通讯-server to client-------------------------
---------------------------------------------------------------------------------

--进游戏接收福利信息
def.method("table", "boolean").OnWelfareInfo = function(self, data, IsOpenActivity)
    if data == nil then return end
    self._WelfareTypeTable = {}
    local ScriptConfig = CElementData.GetTemplate("ScriptConfig", data.ScriptId)
    if ScriptConfig == nil then return end
    if ScriptConfig.ConfigType == EScriptConfigType.SignNormal then
        self._IsOpenSign = true
        self._SignInfoTable = {}
        self._SignDaysTable = {}
        local SignContentData = {} 
        -- SignContentDatap["Reward_"..i]
        if data.Key == 3 then
            SignContentData = CElementData.GetTemplate("Sign", tonumber(data.Param))   

            local  month_type = SignContentData["RewardType"]
            local  totalDay = 0
            if month_type == 0 then
                totalDay = 28
            elseif month_type == 1 then
                totalDay = 29
            elseif month_type == 2 then
                totalDay = 30
            elseif month_type == 3 then
                totalDay = 31
            end

            self._CurrentTotalDay = totalDay

            for i = 1, totalDay do
                self._SignDaysTable[#self._SignDaysTable + 1] = SignContentData["Reward_"..i]
            end

        end

        if SignContentData ~= nil then
            self._SignInfoTable[#self._SignInfoTable + 1] =    --SignContentData
            {
                _ScriptID = data.ScriptId,
                _Data = SignContentData, --模板数据
            }
        else
            warn("Sign data ERROR ID："..ScriptConfig.TemplateId)
        end
    elseif ScriptConfig.ConfigType == EScriptConfigType.SignSpecial then
        self._SpecialSignInfoTable = {}
        self._SpecialSignInfoTable[#self._SpecialSignInfoTable + 1] =
        {
            _ScriptID = data.ScriptId,
            _Tid = ScriptConfig.TemplateId, --模板ID
            _OpenTime = data.OpenTime,
            _CloseTime = data.CloseTime,
            _Signed = "",                   --已签到的
            _CanSign = "",                  --可签到的
        }
    else
        warn("UnKnown Sign Type!!!")
    end
    -- 上线请求签到数据
    self:OnC2SScriptDataSync(data.ScriptId)
end

-- 回应签到数据
def.method("table").OnWelfareDatas = function(self, datas)
    if datas == nil then return end   
    local ScriptConfig = CElementData.GetTemplate("ScriptConfig", datas.ScriptId)
    if ScriptConfig == nil then return end
    local WelfareType = EnumDef.WelfareType._Sign
    -- warn("WelfareDatas ScriptConfig.ConfigType  == ", ScriptConfig.ConfigType , "self._CurrentTempId == ", datas.ScriptId, #datas.Datas) 
    if ScriptConfig.ConfigType == EScriptConfigType.SignNormal then
        -- 固定写死的，Param1为TempID  Param2为CurDay
        for _,v in pairs(datas.Datas) do
            if v.Key == EScriptKeyType.SIGN_TID_KEY then
                self._CurrentTempId = v.Param
                local SignContentData = CElementData.GetTemplate("Sign", tonumber(v.Param)) 
                if SignContentData == nil then return end
                local  month_type = SignContentData["RewardType"]
                local  totalDay = 0
                if month_type == 0 then
                    totalDay = 28
                elseif month_type == 1 then
                    totalDay = 29
                elseif month_type == 2 then
                    totalDay = 30
                elseif month_type == 3 then
                    totalDay = 31
                end
                self._CurrentTotalDay = totalDay
                self._SignDaysTable = {}
                for i = 1, totalDay do
                    self._SignDaysTable[#self._SignDaysTable + 1] = SignContentData["Reward_"..i]
                end

            elseif v.Key == EScriptKeyType.SIGN_DAY_KEY then
                self._CurrentDay = tonumber(v.Param)
            -- elseif v.Key == EScriptKeyType.SIGN_TIME_KEY then

            elseif v.Key == EScriptKeyType.SIGN_SIGNED_DAY_KEY then
                self._CurrentSignedDays = tonumber(v.Param)
            end
        end


        --当前月份信息
        -- if datas.Param3 ~= nil then
        --     self._CurrentMonth = tonumber(datas.Param3)
        -- end
        WelfareType = EnumDef.WelfareType._Sign

    elseif ScriptConfig.ConfigType == EScriptConfigType.SignSpecial then
        for _,v in pairs(self._SpecialSignInfoTable) do            
            for _,k in pairs(datas.Datas) do
                if v._Tid == ScriptConfig.TemplateId then                    
                    if k.Key == EScriptKeyType.SPECIALSIGN_KEY then
                        v._Signed = k.Param
                    elseif k.Key == EScriptKeyType.SPECIALSIGN_CAN_KEY then
                        -- warn("Special data ====", k.Key, k.Param)
                        v._CanSign = k.Param
                    elseif k.Key == EScriptKeyType.SPECIALSIGN_ISSPECIAL then
                        if tonumber(k.Param) == 0 then
                            self._IsOpenSpecialSign = false
                        elseif tonumber(k.Param) == 1 then
                            self._IsOpenSpecialSign = true
                        end
                    end
                end
            end
        end
        WelfareType = EnumDef.WelfareType._SpecialSign
    end
    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare:RefrashWelfare(WelfareType)
        -- CPanelUIWelfare: RefrashWelfareType()	
    end
    self:WelfareRedPointState()
    -- CPanelSystemEntrance:UpdateWelfareRedPointStatus()    
end

-- 获取回应的荣耀之路数据
def.method("table").OnGloryCurrentInfo = function(self, datas)  
    self._CurrentGloryLevel = 0  
    if datas ~= nil then
        self._CurrentGloryLevel = datas.curLevel
        if datas.isLevelUp then
            self._IsOpenGloryRedPoint = false
        end
    end

    self._GloryGiftBuyInfoList = {}
    self._GloryGiftBuyInfoList = datas.GloryGiftBuyInfoList

    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare: RefrashWelfare(EnumDef.WelfareType._GloryVIP)
    end
    self:WelfareRedPointState()
    -- CPanelSystemEntrance:UpdateWelfareRedPointStatus()	
end

-- 事件处理返回结果
def.method("number").OnWelfareEventType = function(self, scriptId)
    self:OnC2SScriptDataSync(scriptId)
end

-- 获取回应的在线奖励数据
def.method("table").OnOnlineRewardInfo = function(self, datas)  
    self._OnlineRewardDataTable = {}
    self._IsOnlineReward = true
    if datas ~= nil then
        -- self:AddOnlineRewardTimer(datas.OnlineTime)
        self._OnlineTime = datas.OnlineTime
        if self._TimeId ~= 0 then
            self:RemoveTimer()            
        end
        self:AddTimer()
    end

    local allTid = GameUtil.GetAllTid("OnlineReward")
    for _, tid in ipairs(allTid) do
        if tid ~= nil then
            local template = CElementData.GetTemplate("OnlineReward", tid)
			self._OnlineRewardDataTable[#self._OnlineRewardDataTable + 1] =
			{
				_Data = template,				--模板数据
                _IsDraw = false,			    --是否已领
                _IsGet = false,			        --是否可领
			}				
		else
			warn("在线奖励数据错误ID：", tid)
		end
    end
    for _,v in pairs(self._OnlineRewardDataTable) do
		for _,k in pairs(datas.DrawList) do
			if v._Data.Id == k then		
                 v._IsDraw = true
                 v._IsGet = false
            end
        
            if datas.OnlineTime > (v._Data.NeedMinute * 60) then
                v._IsGet = true
            end
		end
    end
    self:WelfareRedPointState()
    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare: RefrashWelfare(EnumDef.WelfareType._OnLineReward)	
        CPanelUIWelfare: RefrashWelfareType()	
    end
end

-- 获取回应的在线奖励领取数据
def.method("table").OnOnlineRewardDrawReward = function(self, OnlineRewardIds)  
    for _,v in pairs(self._OnlineRewardDataTable) do
        for _,k in pairs(OnlineRewardIds) do
			if v._Data.Id == k then	
                 v._IsDraw = true
                 v._IsGet = false
            end
		end
    end	
    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()

    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare:RefrashWelfare(EnumDef.WelfareType._OnLineReward)
    end
    self:WelfareRedPointState()
end

-- 获取回应的材料兑换数据
def.method("table").OnFestivalInfo = function(self, datas)  
    self._FestivalInfoList = {}
    -- self._IsFestival = true

    for _,k in pairs(datas) do
        if k ~= nil and k.FestivalId ~= nil then
            self._CurFestivalId = k.FestivalId
            local template = CElementData.GetTemplate("FestivalActivity", k.FestivalId)
            self._FestivalInfoList[#self._FestivalInfoList + 1] =
            {
                _Data = template,				--模板数据
                _FestivalRewardDatas = k.FestivalRewardDatas,
            }	
        end
    end    
    -- self:WelfareRedPointState()
    -- local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    -- if CPanelUIWelfare:IsShow() then
    --     CPanelUIWelfare: RefrashWelfare(EnumDef.WelfareType._Festival)	
    --     CPanelUIWelfare: RefrashWelfareType()	
    -- end
end

def.method("table").OnFestivalExchange = function(self, datas)
    self._CurFestivalId = datas.FestivalId
    local MaterialList = self._FestivalInfoList[datas.FestivalId]
    if MaterialList ~= nil then
        for _,v in pairs(MaterialList._FestivalRewardDatas) do
            if v.RewardId == datas.FestivalRewardDatas.RewardId then		
                v.RemainCount = datas.FestivalRewardDatas.RemainCount
           end
        end
    end
    

    self:WelfareRedPointState()
    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare: RefrashWelfare(EnumDef.WelfareType._Festival)	
        CPanelUIWelfare: RefrashWelfareType()	
    end
end

def.method().AddTimer = function (self)
    local TimeZone = tonumber(os.date("%z", 0))/100
    self._TimeId = _G.AddGlobalTimer(10, false, function()
        self._OnlineTime = self._OnlineTime + 1  
        for _,v in pairs(self._OnlineRewardDataTable) do
            if self._OnlineTime > (v._Data.NeedMinute * 60) then
                v._IsGet = true
                local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
                if CPanelUIWelfare:IsShow() then
                    CPanelUIWelfare: RefrashWelfare(EnumDef.WelfareType._OnLineReward)	
                    -- CPanelUIWelfare: RefrashWelfareType()	
                end
                self:WelfareRedPointState()
            end
        end      
    end)
end

def.method().RemoveTimer = function(self)
    if self._TimeId ~= 0 then
        _G.RemoveGlobalTimer(self._TimeId)
        self._TimeId = 0
    end
end

---------------------------------------------------------------------------------
--------------------------客户端请求数据-client to server-------------------------
---------------------------------------------------------------------------------
--请求脚本开启状态
def.method("number").OnC2SScriptEnable = function(self, scriptCalendarId)
	local C2SScriptEnable = require "PB.net".C2SScriptEnable
    local protocol = C2SScriptEnable()
    protocol.ScriptCalendarId = scriptCalendarId
	PBHelper.Send(protocol)
end

--请求签到数据
def.method("number").OnC2SScriptDataSync = function(self, scriptId)
	local C2SScriptDataSync = require "PB.net".C2SScriptDataSync
    local protocol = C2SScriptDataSync()
    protocol.ScriptId = scriptId
	PBHelper.Send(protocol)
end

--请求执行某事件
def.method("number","number","number").OnC2SScriptExec = function(self, scriptId , eventType, days)
	local C2SScriptExec = require "PB.net".C2SScriptExec
    local protocol = C2SScriptExec()
    protocol.ScriptId = scriptId
    protocol.EvevtType = eventType
    protocol.Param1 = tostring(days)
    protocol.Param2 = ""
    protocol.Param3 = ""
    protocol.Param4 = ""
	PBHelper.Send(protocol)
end

--请求荣耀之路数据
def.method().OnC2SGloryCurrentInfo = function(self)
	local C2SGloryCurrentInfo = require "PB.net".C2SGloryCurrentInfo
    local protocol = C2SGloryCurrentInfo()
	PBHelper.Send(protocol)
end

--请求购买荣耀之路某个礼包
def.method("number","number").OnC2SGloryBuyLevelGift = function(self, GloryLevel, GloryGiftId)
	local C2SGloryBuyLevelGift = require "PB.net".C2SGloryBuyLevelGift
    local protocol = C2SGloryBuyLevelGift()
    protocol.GloryLevel = GloryLevel
    protocol.GloryGiftId = GloryGiftId
	PBHelper.Send(protocol)
end

-- 打开界面请求所有数据
def.method().OnGetWelfareData = function(self)
    local SignInfo = self:GetAllSignInfo()
    -- open请求签到数据
    self:OnC2SScriptDataSync(SignInfo._ScriptID)  
    --请求荣耀之路数据
    self:OnC2SGloryCurrentInfo()
    -- 请求特殊签到数据
    local SpecialSignInfo = game._CWelfareMan:GetSpecialSignInfo()
    self:OnC2SScriptDataSync(SpecialSignInfo._ScriptID)
    --请求在线奖励数据
    self:OnC2SOnlineRewardViewInfo()
end

--请求在线奖励数据
def.method().OnC2SOnlineRewardViewInfo = function(self)
	local C2SOnlineRewardViewInfo = require "PB.net".C2SOnlineRewardViewInfo
    local protocol = C2SOnlineRewardViewInfo()
	PBHelper.Send(protocol)
end

--请求领取单个在线奖励奖励。
def.method("number").OnC2SOnlineRewardDrawReward = function(self, OnlineRewardId)
	local C2SOnlineRewardDrawReward = require "PB.net".C2SOnlineRewardDrawReward
    local protocol = C2SOnlineRewardDrawReward()
    protocol.OnlineRewardId = OnlineRewardId
	PBHelper.Send(protocol)
end

--请求材料兑换。  活动id，兑换奖励id
def.method("number", "number").OnC2SFestivalExchange = function(self, FestivalId, RewardId)
	local C2SFestivalExchange = require "PB.net".C2SFestivalExchange
    local protocol = C2SFestivalExchange()
    protocol.RoleId = game._HostPlayer._ID
    protocol.FestivalId = FestivalId
    protocol.RewardId = RewardId
    PBHelper.Send(protocol)
end

---------------------------------------------------------------------------------
-----------------------------------client--------------------------------
---------------------------------------------------------------------------------

--获取所有福利类型
def.method("=>","table").GetAllWelfareTypes = function(self)
    self._WelfareTypeTable = {}
    -- warn("!!!!!!!!!!!!!!>>>", self._IsOpenSign, self:GetGloryLevel(), self._IsOpenGlory, self._IsOpenSpecialSign)
    if game._CFunctionMan:IsUnlockByFunTid(GLORY_UNLOCKED_BY_TID) then
        self._IsOpenGlory = true
    end 

    if self._IsOpenSign then
        self._WelfareTypeTable[#self._WelfareTypeTable + 1] = EnumDef.WelfareType._Sign
    end

    if self._IsOpenGlory then
        self._WelfareTypeTable[#self._WelfareTypeTable + 1] = EnumDef.WelfareType._GloryVIP
    end

    self._WelfareTypeTable[#self._WelfareTypeTable + 1] = EnumDef.WelfareType._Festival

    if self._IsOpenSpecialSign then
        self._WelfareTypeTable[#self._WelfareTypeTable + 1] = EnumDef.WelfareType._SpecialSign
    end

    if self._IsOnlineReward then
        self._WelfareTypeTable[#self._WelfareTypeTable + 1] = EnumDef.WelfareType._OnLineReward
    end
    
	return self._WelfareTypeTable
end

--获取当前script签到信息
def.method("=>","table").GetAllSignInfo = function(self)
    -- warn("----------------------------->", #self._SignInfoTable, self._CurrentTempId)
    for i,v in pairs(self._SignInfoTable) do
        if v._Data.Id == self._CurrentTempId then
            return self._SignInfoTable[i]
        end
    end
    return self._SignInfoTable[1]
end

--获取所有签到天
def.method("=>","table").GetAllSignDays = function(self)
	return self._SignDaysTable
end

def.method("=>", "number").GetCurrentDay = function(self)
    return self._CurrentDay
end

def.method("=>", "number").GetCurrentTotalDay = function(self)
    return self._CurrentTotalDay
end

def.method("=>", "number").GetCurrentSignedDays = function(self)
    return self._CurrentSignedDays
end

--获取特殊签到是否开启
def.method("=>","boolean").GetSpecialSignIsOpen = function(self)
	return self._IsOpenSpecialSign
end

-- 获取所有荣耀之路数量
def.method("=>", "table").GetGloryGifts = function(self)
    self._GloryGiftsTable = {}
    local allGloryData = GameUtil.GetAllTid("GloryLevel")
    for _,v in ipairs(allGloryData) do
        if v > 0 then
            local GloryData = CElementData.GetTemplate("GloryLevel",v)
            if GloryData ~= nil and GloryData.Id ~= nil then
                self._GloryGiftsTable[#self._GloryGiftsTable + 1] = GloryData
            else
                warn("荣耀之路错误ID："..v)
            end	
       end
    end
    return self._GloryGiftsTable
end

--[[
    GloryUnlockType =
    {
        SelfPackUnlock                  = 0,    -- 解锁随身仓库
        BlackMarketUnlcok               = 1,    -- 解锁黑市
        No2PetUnlock                    = 2,    -- 解锁第2个出战宠物栏
        No3PetUnlock                    = 3,    -- 解锁第3个出战宠物栏
        GuildTaskFinishUnlock           = 4,    -- 解锁工会任务立即完成
        ReputationTaskFinishUnlock      = 5,    -- 解锁声望任务立即完成
        WorldAuctionUnlock              = 6,    -- 解锁世界拍卖行
    },
]]
-- 获取荣耀之路解锁数据  如果对应类型没有解锁，返回nil
def.method("number" ,"=>", "table").GetGloryUnlockData = function(self, Type)
    if #self._GloryGiftsTable <= 0 then
        -- 获取缓存数据，不用每次都GetTemplate
        self:GetGloryGifts()
    end
    for _,v in ipairs(self._GloryGiftsTable) do
        if Type == EnumDef.GloryUnlockType.SelfPackUnlock then
            if v.SelfPackUnlock then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.BlackMarketUnlcok then
            if v.BlackMarketUnlcok then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.No2PetUnlock then
            if v.No2PetUnlock then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.No3PetUnlock then
            if v.No3PetUnlock then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.GuildTaskFinishUnlock then
            if v.GuildTaskFinishUnlock then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.ReputationTaskFinishUnlock then
            if v.ReputationTaskFinishUnlock then
                return v
            end
        elseif Type == EnumDef.GloryUnlockType.WorldAuctionUnlock then
            if v.WorldAuctionUnlock then
                return v
            end
        end
    end
    return nil
end

-- 获取当前荣耀等级
def.method("=>", "number").GetGloryLevel = function(self)
    return game._HostPlayer:GetGloryLevel()
end

-- 获取荣耀礼包购买情况
def.method("number","=>", "table").GetGloryGiftBuyInfo = function(self, gloryLevel)
    if #self._GloryGiftBuyInfoList <= 0 then return nil end
    for _,v in ipairs(self._GloryGiftBuyInfoList) do
        if gloryLevel == v.Level and #v.GiftIds > 0 then
            return v
        end
    end
    return nil
end

-- 获取当前荣耀等级对应数据
def.method("=>", "table").GetCurGloryLevelData = function(self)
    if #self._GloryGiftsTable <= 0 then
        -- 获取缓存数据，不用每次都GetTemplate
        self:GetGloryGifts()
    end
    for _,v in ipairs(self._GloryGiftsTable) do
        if game._HostPlayer:GetGloryLevel() == v.Id then
            return v
        end
    end
    -- 当前没有荣耀等级，返回nil
    return nil
end

-- 获取荣耀等级对应数据
def.method("number", "=>", "table").GetDataByGloryLevel = function(self, gloryLevel)
    if #self._GloryGiftsTable <= 0 then
        -- 获取缓存数据，不用每次都GetTemplate
        self:GetGloryGifts()
    end
    for _,v in ipairs(self._GloryGiftsTable) do
        if gloryLevel == v.Id then
            return v
        end
    end
    -- 当前没有荣耀等级，返回nil
    return nil
end

def.method("=>", "boolean").GetSignRedPointState = function(self)
    -- local Signeds = {}
    -- local TotleRewards = {}
    local IsShowRedPoint = false

    if self._CurrentDay == self._CurrentSignedDays then
        IsShowRedPoint = false
    else
        IsShowRedPoint = true
    end
    -- local curSigned = false
    -- local totleSigneds = false
    -- -- warn("lidaming -------------> self:GetAllSignInfo()._Signed ==", self:GetAllSignInfo()._Signed, self._CurrentDay)
    -- string.gsub(self:GetAllSignInfo()._Signed, '[^*]+', function(w) table.insert(Signeds, w) end )
    -- string.gsub(self:GetAllSignInfo()._IsTotleReward, '[^*]+', function(w) table.insert(TotleRewards, w) end )
    -- -- warn("lidaming ---------------->#Signeds ==", #Signeds, #TotleRewards)
    -- if #Signeds == 0 then
    --     IsShowRedPoint = true
    -- else
    --     for _,k in pairs(Signeds) do
    --         if tonumber(k) == self._CurrentDay then
    --             curSigned = true
    --         end
    --     end
    -- end                 

    -- if curSigned == false or totleSigneds == true then
    --     IsShowRedPoint = true
    -- else
    --     IsShowRedPoint = false
    -- end
    return IsShowRedPoint
end


def.method("=>", "boolean").GetSpecialSignRedPointState = function(self)
    local CanSign = {}
    local IsShowRedPoint = false
    -- warn("self._SpecialSignInfoTable._CanSign ===", self:GetSpecialSignInfo()._CanSign)
    if self:GetSpecialSignInfo()._CanSign ~= nil then
        string.gsub(self:GetSpecialSignInfo()._CanSign, '[^*]+', function(w) table.insert(CanSign, w) end )
    end
    if #CanSign <= 0 then
        IsShowRedPoint = false
    else
        IsShowRedPoint = true
    end
    -- warn("GetSpecialSignRedPointState ==", #CanSign, IsShowRedPoint)
    return IsShowRedPoint
end

-- 荣耀之路暂时没有升级提示。
def.method("=>", "boolean").GetGloryRedPointState = function(self)
    return self._IsOpenGloryRedPoint
end

-- 福利主界面红点提示
def.method().WelfareRedPointState = function(self)
    local welfareRedPoint = false
    -- warn("lidaming ---->", self:GetSignRedPointState(), self:GetSpecialSignRedPointState(), self:IsShowOnlineRewardRedPoint(), self:GetGloryRedPointState())
    if self:GetSignRedPointState() or self:GetSpecialSignRedPointState() or self:IsShowOnlineRewardRedPoint() or self:GetGloryRedPointState() then
        welfareRedPoint = true
    else
        -- 目前没有荣耀之路的红点判断
        welfareRedPoint = false
    end
    -- warn("lidaming welfareRedPoint Main CRedDotMan.UpdateModuleRedDotShow==", welfareRedPoint)
    -- return welfareRedPoint
    if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bonus) then
        CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Welfare, welfareRedPoint)
    end
end

def.method("=>", "table").GetSpecialSignInfo = function(self)
    
    return self._SpecialSignInfoTable[1]
end

def.method("=>", "table").GetOnlineRewardDataTable = function(self)
    return self._OnlineRewardDataTable
end

def.method("=>", "number").GetOnlineTime = function(self)
    return self._OnlineTime
end

-- 是否显示在线奖励红点
def.method("=>", "boolean").IsShowOnlineRewardRedPoint = function(self)	
    -- 检查是否有可领取奖励
    for i, v in ipairs(self._OnlineRewardDataTable) do
        if v._IsGet and not v._IsDraw then            
            return true
        end
	end
	return false
end

---------------------------------------------------------------
---------------------材料兑换-------------------------------



def.method("=>", "table").GetFestivalInfos = function(self)
    return self._FestivalInfoList
end


-----------------------------------------------------

-- 切换账号 或是 切换角色 恢复默认数据
def.method().Release = function (self)
	self._UpdateInterval = 0
    self._CurrentDay = 0
    self._CurrentTempId = ""

    self._CurrentGloryLevel = 0
    self._IsOpenSign = false
    self._IsOpenSpecialSign = false
    self._IsOpenGlory = false

    self._WelfareTypeTable = {}
    self._SignInfoTable = {}
    self._SignDaysTable = {}
    self._GloryGiftsTable = {}
    self._SpecialSignInfoTable = {}
    self._GloryGiftBuyInfoList = {}
    self:RemoveTimer()
    self._OnlineTime = 0 
    self._OnlineRewardDataTable = {}
    self._IsOpenGloryRedPoint = false
    self._FestivalInfoList = {}
end

CWelfareMan.Commit()
return CWelfareMan