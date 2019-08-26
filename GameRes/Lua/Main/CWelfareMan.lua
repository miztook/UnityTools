local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local EScriptKeyType = require "PB.data".EScriptKeyType
local GainNewItemEvent = require "Events.GainNewItemEvent"
local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance".Instance()
local EScriptEventType = require "PB.data".EScriptEventType
local ESystemType = require "PB.Template".ScriptCalendar.ESystemType
local EBonusType = require "PB.Template".ScriptCalendar.EBonusType
local EActivityType = require "PB.Template".ActivityPage.EActivityType

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
def.field("boolean")._IsOpenGlory = false
def.field("boolean")._IsOnlineReward = true
def.field("boolean")._IsOpenGloryRedPoint = false
def.field("boolean")._IsOpenFestival = false
def.field("boolean")._IsOpenDice = false
def.field("boolean")._IsOpenHotEvent = false

def.field("number")._CurrentSignedDays = 0              --已签总天数
def.field("number")._CurFestivalId = 0                     -- 当前材料兑换活动id

def.field("number")._CurrentRollDiceNum = 0                     -- 投掷骰子数
def.field("number")._CurrentDicePos = 0                     -- 骰子当前位置
def.field("number")._CurTotalCount = 0                     -- 已投掷骰子数
def.field("string")._CurTotalGet = ""                    -- 骰子累计奖励领取数
def.field("number")._CurSpriteID = 0

def.field("table")._WelfareTypeTable = BlankTable
def.field("table")._SignInfoTable = BlankTable
def.field("table")._SignDaysTable = BlankTable
def.field("table")._GloryGiftsTable = BlankTable
def.field("table")._SpecialSignInfoTable = BlankTable
def.field("table")._GloryGiftBuyInfoList = BlankTable
def.field("table")._OnlineRewardDataTable = BlankTable
def.field("table")._DiceInfoTable = BlankTable

def.field("table")._HotEventInfoTable = BlankTable

def.field("table")._FestivalInfoList = BlankTable
def.field("table")._DiceItemInfoList = BlankTable

-- def.field("table")._WelfareTypeInfo = BlankTable    -- 福利页签信息

local GLORY_UNLOCKED_BY_TID = 110  -- 冒险生涯教学功能Tid

def.static("=>", CWelfareMan).new = function()
    local obj = CWelfareMan()
    return obj
end

local OnGainNewItemEvent = function(sender, event)
    game._CWelfareMan:WelfareRedPointState()
end

---------------------------------------------------------------------------------
--------------------------服务器相关通讯-server to client-------------------------
---------------------------------------------------------------------------------

--进游戏接收福利信息
def.method("table", "boolean").OnWelfareInfo = function(self, data, IsOpenActivity)
    if data == nil then return end
    self._WelfareTypeTable = {}
    local ScriptConfig = nil
    local allTid = CElementData.GetAllTid("ScriptCalendar")
    for _,ScriptCalendarTid in ipairs(allTid) do     
        local ScriptCalendarTemp = CElementData.GetTemplate("ScriptCalendar", tonumber(ScriptCalendarTid))
        if ScriptCalendarTemp.SystemType == ESystemType.Bonus then        
            -- 脚本ID SystemType = ESystemType.Bonus 时显示      
            if data.ScriptId == ScriptCalendarTemp.ScriptId then
                ScriptConfig = ScriptCalendarTemp
            end  
        end
    end

    if ScriptConfig == nil then return end
    if ScriptConfig.BonusType == EBonusType.Sign then
        self._IsOpenSign = IsOpenActivity
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
                _ScriptCalendarId = data.ScriptCalendarId,
                _Data = SignContentData, --模板数据
            }
        else
            warn("Sign data ERROR ID："..ScriptConfig.TemplateId)
        end
        
    elseif ScriptConfig.BonusType == EBonusType.SpecialSign then        
        self._SpecialSignInfoTable[#self._SpecialSignInfoTable + 1] =
        {
            _ScriptID = data.ScriptId,
            _Tid = ScriptConfig.TemplateId, --模板ID
            _ScriptCalendarId = data.ScriptCalendarId,
            _OpenTime = data.OpenTime,
            _CloseTime = data.CloseTime,
            _Signed = "",                   --已签到的
            _CanSign = "",                  --可签到的
            _IsOpenSpecialSign = false,     --特殊签到是否开启
        }
    elseif ScriptConfig.BonusType == EBonusType.Dice then
        self._IsOpenDice = IsOpenActivity
        self._CurSpriteID = data.ScriptCalendarId
        self._DiceInfoTable = {}
    elseif ScriptConfig.BonusType == EBonusType.HotActivity then
        self._IsOpenHotEvent = IsOpenActivity
        self._HotEventInfoTable[#self._HotEventInfoTable + 1] =
        {
            _ScriptID = data.ScriptId,
            _Tid = ScriptConfig.TemplateId, --模板ID
            _ScriptCalendarId = data.ScriptCalendarId,
            _FinishHotEventID = "",         --已经完成
            _RewardHotEventID = "",         --已经领取
        }
    else
        warn("UnKnown Sign Type!!!")
    end
    -- 上线请求签到数据
    self:OnC2SScriptDataSync(data.ScriptId)
    CGame.EventManager:addHandler(GainNewItemEvent, OnGainNewItemEvent)
end

-- 回应签到数据
def.method("table").OnWelfareDatas = function(self, datas)
    if datas == nil or datas.ScriptId == nil then return end   

    local ScriptConfig = nil
    local allTid = CElementData.GetAllTid("ScriptCalendar")
    for _,ScriptCalendarTid in ipairs(allTid) do     
        local ScriptCalendarTemp = CElementData.GetTemplate("ScriptCalendar", tonumber(ScriptCalendarTid))
        if ScriptCalendarTemp.SystemType == ESystemType.Bonus then        
            -- 脚本ID SystemType = ESystemType.Bonus 时显示      
            if datas.ScriptId == ScriptCalendarTemp.ScriptId then
                ScriptConfig = ScriptCalendarTemp
            end  
        end
    end

    if ScriptConfig == nil then return end
    local WelfareType = EActivityType.EActivityType_Sign
    -- warn("WelfareDatas ScriptConfig.ConfigType  == ", ScriptConfig.ConfigType , "self._CurrentTempId == ", datas.ScriptId, #datas.Datas) 
    if ScriptConfig.BonusType == EBonusType.Sign then
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
                self._SignInfoTable = {}
                self._SignInfoTable[#self._SignInfoTable + 1] =    --SignContentData
                {
                    _ScriptID = datas.ScriptId,
                    _Data = SignContentData, --模板数据
                    _ScriptCalendarId = datas.ScriptCalendarId,
                }
            elseif v.Key == EScriptKeyType.SIGN_DAY_KEY then

                self._CurrentDay = tonumber(v.Param)
            -- elseif v.Key == EScriptKeyType.SIGN_TIME_KEY then

            elseif v.Key == EScriptKeyType.SIGN_SIGNED_DAY_KEY then
                self._CurrentSignedDays = tonumber(v.Param)
            end
        end
        WelfareType = EActivityType.EActivityType_Sign
    elseif ScriptConfig.BonusType == EBonusType.SpecialSign then
        for _,v in pairs(self._SpecialSignInfoTable) do            
            for _,k in pairs(datas.Datas) do
                if v._Tid == ScriptConfig.TemplateId then                    
                    if k.Key == EScriptKeyType.SPECIALSIGN_KEY then
                        v._Signed = k.Param
                    elseif k.Key == EScriptKeyType.SPECIALSIGN_CAN_KEY then
                        v._CanSign = k.Param
                    elseif k.Key == EScriptKeyType.SPECIALSIGN_ISSPECIAL then
                        if tonumber(k.Param) == 0 then
                            v._IsOpenSpecialSign = false
                        elseif tonumber(k.Param) == 1 then
                            v._IsOpenSpecialSign = true
                        end
                    end
                end
            end
        end
        WelfareType = EActivityType.EActivityType_SpecalSign
    elseif ScriptConfig.BonusType == EBonusType.Dice then
        self._DiceItemInfoList = {}
        -- self._CurSpriteID = datas.ScriptId
        for _,v in pairs(datas.Datas) do
            if v.Key == EScriptKeyType.DICE_TID_KEY then
                self._CurrentTempId = tostring(ScriptConfig.TemplateId)
                local DiceContentData = CElementData.GetTemplate("Dice", tonumber(ScriptConfig.TemplateId)) 
                if DiceContentData == nil then return end
                self._DiceInfoTable = {}
                self._DiceInfoTable = DiceContentData
                for i = 1, #DiceContentData.DiceEventStructs do
                    self._DiceItemInfoList[#self._DiceItemInfoList + 1] = DiceContentData.DiceEventStructs[i]
                end

            elseif v.Key == EScriptKeyType.DICE_POS_KEY then
                self._CurrentDicePos = tonumber(v.Param)
            -- elseif v.Key == EScriptKeyType.SIGN_TIME_KEY then

            elseif v.Key == EScriptKeyType.DICE_TOTLE_COUNT_KEY then
                self._CurTotalCount = tonumber(v.Param)
            elseif v.Key == EScriptKeyType.DICE_TOTLE_GET_KEY then
                self._CurTotalGet = v.Param
            end
        end
        WelfareType = EActivityType.EActivityType_Dice
    elseif ScriptConfig.BonusType == EBonusType.HotActivity then
        for _,v in pairs(self._HotEventInfoTable) do            
            for _,k in pairs(datas.Datas) do
                if v._Tid == ScriptConfig.TemplateId then                    
                    if k.Key == EScriptKeyType.HA_FINISH_KEY then
                        v._FinishHotEventID = k.Param
                    elseif k.Key == EScriptKeyType.HA_REWARD_KEY then
                        v._RewardHotEventID = k.Param
                    end
                end
            end
        end
        WelfareType = EActivityType.EActivityType_HotActivity
    end
    local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
    if CPanelUIWelfare:IsShow() then
        CPanelUIWelfare:RefrashWelfare(WelfareType)
        CPanelUIWelfare: RefrashWelfareType()	
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
        CPanelUIWelfare: RefrashWelfare(EActivityType.EActivityType_AdventureGuid)
    end
    self:WelfareRedPointState()
    -- CPanelSystemEntrance:UpdateWelfareRedPointStatus()	
end

-- 事件处理返回结果
def.method("table").OnWelfareEventType = function(self, data)
    if data.EvevtType == EScriptEventType.Sign_sign or data.EvevtType == EScriptEventType.SpecialSign_Sign then
        self:OnC2SScriptDataSync(data.ScriptId)
    elseif data.EvevtType == EScriptEventType.Dice_Roll then
        self._CurrentRollDiceNum = tonumber(data.Param1)              -- 固定param1 为骰子数
        self._CurrentDicePos = tonumber(data.Param2)                -- 当前位置
        self._CurTotalCount = self._CurTotalCount + 1
        local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
        if CPanelUIWelfare:IsShow() then
            CPanelUIWelfare:RefrashWelfare(EActivityType.EActivityType_Dice)
            -- CPanelUIWelfare: RefrashWelfareType()	
        end
        self:WelfareRedPointState()
    elseif data.EvevtType == EScriptEventType.Dice_TotleReward then
        self._CurTotalGet = self._CurTotalGet.."*".. data.Param1
        local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
        if CPanelUIWelfare:IsShow() then
            CPanelUIWelfare:RefrashWelfare(EActivityType.EActivityType_Dice)
            -- CPanelUIWelfare: RefrashWelfareType()	
        end
        self:WelfareRedPointState()

    elseif data.EvevtType == EScriptEventType.Dice_Buy then
        local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
        if CPanelUIWelfare:IsShow() then
            CPanelUIWelfare:RefrashWelfare(EActivityType.EActivityType_Dice)
            -- CPanelUIWelfare: RefrashWelfareType()	
        end
        self:WelfareRedPointState()
    elseif data.EvevtType == EScriptEventType.HA_GainReward then
        for i,v in pairs(self._HotEventInfoTable) do
            if v._ScriptID ~= nil and v._ScriptID == data.ScriptId then                    
                v._RewardHotEventID = v._RewardHotEventID.."*".. data.Param1
            end
        end
        local CPanelUIWelfare = require "GUI.CPanelUIWelfare".Instance()
        if CPanelUIWelfare:IsShow() then
            CPanelUIWelfare:RefrashWelfare(EActivityType.EActivityType_HotActivity)
            -- CPanelUIWelfare: RefrashWelfareType()	
        end
        self:WelfareRedPointState()
    end
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

    local allTid = CElementData.GetAllTid("OnlineReward")
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
        CPanelUIWelfare: RefrashWelfare(EActivityType.EActivityType_OnlineReward)	
        -- CPanelUIWelfare: RefrashWelfareType()	
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
        CPanelUIWelfare:RefrashWelfare(EActivityType.EActivityType_OnlineReward)
    end
    self:WelfareRedPointState()
end

-- 获取回应的材料兑换数据
def.method("table").OnFestivalInfo = function(self, datas)  
    self._FestivalInfoList = {}
    -- self._IsFestival = true
    if datas == nil then self._IsOpenFestival = false return end
    for _,k in pairs(datas) do
        if k ~= nil and k.FestivalId ~= nil then
            self._CurFestivalId = k.FestivalId
            self._IsOpenFestival = true
            local template = CElementData.GetTemplate("FestivalActivity", k.FestivalId)
            self._FestivalInfoList[#self._FestivalInfoList + 1] =
            {
                _Data = template,				--模板数据
                _FestivalRewardDatas = k.FestivalRewardDatas,
            }	
        end
    end    
end

def.method("table").OnFestivalExchange = function(self, datas)
    self._CurFestivalId = datas.FestivalId
    local MaterialList = self._FestivalInfoList[1]
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
        CPanelUIWelfare: RefrashWelfare(EActivityType.EActivityType_Festival)	
        -- CPanelUIWelfare: RefrashWelfareType()	
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
                    CPanelUIWelfare: RefrashWelfare(EActivityType.EActivityType_OnlineReward)	
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
    if SignInfo._ScriptCalendarId ~= nil then
        self:OnC2SScriptEnable(SignInfo._ScriptCalendarId)  
    end

    --请求荣耀之路数据
    self:OnC2SGloryCurrentInfo()
    -- 请求所有特殊签到数据
    for _,v in pairs(self._SpecialSignInfoTable) do            
        if v._Tid ~= nil then                    
            self:OnC2SScriptDataSync(v._ScriptID)
        end
    end

    --请求在线奖励数据
    self:OnC2SOnlineRewardViewInfo()
    --请求骰子是否开启
    self:OnC2SScriptEnable(self._CurSpriteID) 

    -- 请求热点活动数据
    for _,v in pairs(self._HotEventInfoTable) do            
        if v._ScriptID ~= nil then                    
            self:OnC2SScriptEnable(v._ScriptCalendarId)
        end
    end
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

local function sort_func_by_index(a, b)
    if a.Data.Sort ~= b.Data.Sort then
        -- 从小到大排序页签
        return a.Data.Sort < b.Data.Sort
    end
    return false
end

--获取所有福利类型
def.method("=>","table").GetAllWelfareTypes = function(self)
    self._WelfareTypeTable = {}
    -- 缓存福利页签所有模板数据
    local allTid = CElementData.GetAllTid("ActivityPage")
    for _,ActivityPageTid in ipairs(allTid) do     
        local ScriptCalendarTemp = CElementData.GetTemplate("ActivityPage", tonumber(ActivityPageTid))
        self._WelfareTypeTable[#self._WelfareTypeTable + 1] = 
        {
            Data = ScriptCalendarTemp,
            IsShow = false,
            IsShowRedPoint = false,
        }
    end
    -- warn("!!!!!!!!!!!!!!>>>", self._IsOpenSign, self:GetGloryLevel(), self._IsOpenGlory, self._IsOpenSpecialSign)
    if game._CFunctionMan:IsUnlockByFunTid(GLORY_UNLOCKED_BY_TID) then
        self._IsOpenGlory = true
    end 

    for _,WelfareType in ipairs(self._WelfareTypeTable) do
        if WelfareType.Data.ActivityType == EActivityType.EActivityType_Sign then
            WelfareType.IsShow = self._IsOpenSign
            WelfareType.IsShowRedPoint = self:GetSignRedPointState()
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_AdventureGuid then
            WelfareType.IsShow = self._IsOpenGlory
            WelfareType.IsShowRedPoint = self:GetGloryRedPointState()
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_SpecalSign then
            for _,v in pairs(self._SpecialSignInfoTable) do
                if v._Tid == WelfareType.Data.ActivityId and self:GetSpecialSignInfo(WelfareType.Data.ActivityId) ~= nil then
                    WelfareType.IsShow = v._IsOpenSpecialSign
                end
            end
            WelfareType.IsShowRedPoint = self:GetSpecialSignRedPointState(WelfareType.Data.ActivityId)
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_Festival then
            WelfareType.IsShow = self._IsOpenFestival
            WelfareType.IsShowRedPoint = self:IsShowExchangeRedPoint()
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_Dice then
            WelfareType.IsShow = self._IsOpenDice
            WelfareType.IsShowRedPoint = self:IsShowDiceRedPoint()
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_OnlineReward then
            WelfareType.IsShow = self._IsOnlineReward
            WelfareType.IsShowRedPoint = self:IsShowOnlineRewardRedPoint()
        elseif WelfareType.Data.ActivityType == EActivityType.EActivityType_HotActivity then
            WelfareType.IsShow = self._IsOpenHotEvent
            WelfareType.IsShowRedPoint = self:GetHotEventRedPointState(WelfareType.Data.ActivityId)
        else
            warn("Not Have WelfareType ==>>>", WelfareType.Data.ActivityType)
        end
    end
    local table_OpenWelfareType = {}
    for i,v in pairs(self._WelfareTypeTable) do
        if v.Data.ActivityType == EActivityType.EActivityType_SpecalSign then
            if self:GetSpecialSignInfo(v.Data.ActivityId) ~= nil and self:GetSpecialSignInfo(v.Data.ActivityId)._IsOpenSpecialSign then
                table_OpenWelfareType[#table_OpenWelfareType + 1] = v
            end
        elseif v.IsShow then
            table_OpenWelfareType[#table_OpenWelfareType + 1] = v
        end
    end
    self._WelfareTypeTable = table_OpenWelfareType
    table.sort(self._WelfareTypeTable, sort_func_by_index)
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
def.method("number", "=>","boolean").GetSpecialSignIsOpen = function(self, SpecialSignTid)
    for _,v in pairs(self._SpecialSignInfoTable) do
        if v._Tid == SpecialSignTid then
            return v._IsOpenSpecialSign
        end
    end
	return false
end

-- 获取所有荣耀之路数量
def.method("=>", "table").GetGloryGifts = function(self)
    self._GloryGiftsTable = {}
    local allGloryData = CElementData.GetAllTid("GloryLevel")
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
    local IsShowRedPoint = false

    if self._CurrentDay == self._CurrentSignedDays then
        IsShowRedPoint = false
    else
        IsShowRedPoint = true
    end
    return IsShowRedPoint
end


def.method("number", "=>", "boolean").GetSpecialSignRedPointState = function(self, SpecialSignTid)
    local CanSign = {}
    local IsShowRedPoint = false
    for _,v in pairs(self._SpecialSignInfoTable) do  
        if v._Tid == SpecialSignTid then       
            if v ~= nil and v._CanSign then                
                string.gsub(v._CanSign, '[^*]+', function(w) table.insert(CanSign, w) end )
            end
        end
    end
    if #CanSign <= 0 then
        IsShowRedPoint = false
    else
        IsShowRedPoint = true
    end
    return IsShowRedPoint
end

-- 荣耀之路暂时没有升级提示。
def.method("=>", "boolean").GetGloryRedPointState = function(self)
    return self._IsOpenGloryRedPoint
end


def.method("number", "=>", "boolean").GetHotEventRedPointState = function(self, HotEventIndex)
    local IsShowRedPoint = false
    local RewardHotEventIds = {}
    local FinishHotEventIds = {}
    local HotEventInfo = self:GetHotEventInfo(HotEventIndex)
    if HotEventInfo == nil then return IsShowRedPoint end
    if HotEventInfo._FinishHotEventID == nil then return IsShowRedPoint end
    if HotEventInfo._RewardHotEventID == nil then return IsShowRedPoint end
    string.gsub(HotEventInfo._FinishHotEventID, '[^*]+', function(w) table.insert(FinishHotEventIds, w) end )
    string.gsub(HotEventInfo._RewardHotEventID, '[^*]+', function(w) table.insert(RewardHotEventIds, w) end )

    if #FinishHotEventIds > #RewardHotEventIds then
        IsShowRedPoint = true
    end

    return IsShowRedPoint
end

-- 福利主界面红点提示
def.method().WelfareRedPointState = function(self)
    local welfareRedPoint = false
    local WelfareTypeTab = self:GetAllWelfareTypes()
    for i,v in ipairs(self._WelfareTypeTable) do
        if v.IsShowRedPoint then
            welfareRedPoint = true
            break
        end
    end
    -- warn("lidaming welfareRedPoint Main CRedDotMan.UpdateModuleRedDotShow==", welfareRedPoint)
    if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bonus) then
        CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Welfare, welfareRedPoint)
    end
end

def.method("number", "=>", "table").GetSpecialSignInfo = function(self, SpecialSignTid)
    for _,v in pairs(self._SpecialSignInfoTable) do
        if v._Tid == SpecialSignTid then
            return v
        end
    end
    return nil
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

-- 是否显示材料兑换红点
def.method("=>", "boolean").IsShowExchangeRedPoint = function(self)	
    -- 检查是否有可兑换材料


    -- 
    -- for _,v in pairs(self._FestivalInfo[1]._FestivalRewardDatas) do
    --     if v.RewardId == MaterialData.Id then		
    --         curLimitNum = v.RemainCount
    --    end
    -- end
    -- if curLimitNum == nil then curLimitNum = 0 end


    local normalPack = game._HostPlayer._Package._NormalPack
    for i, v in ipairs(self._FestivalInfoList) do
        if v._Data.ExchangeRewards ~= nil then
            local ItemID = {}
            local ItemNum = {} 
            local enoughItem = {}  
            local curLimitNum = 0  
            for _, ExchangeReward in ipairs(v._Data.ExchangeRewards) do
                string.gsub(ExchangeReward.ItemIds, '[^*]+', function(w) table.insert(ItemID, w) end )
                string.gsub(ExchangeReward.ItemNums, '[^*]+', function(w) table.insert(ItemNum, w) end )
                for i, v in pairs(ItemID) do
                    for _, k in pairs(ItemNum) do
                        local packageNum = normalPack:GetItemCount(tonumber(v))
                        local needNum = tonumber(k)
                        local isMaterialEnough = needNum <= packageNum
                        if isMaterialEnough then 
                            enoughItem[#enoughItem + 1] = v
                        end
                    end
                end

                for _,LimitNum in pairs(v._FestivalRewardDatas) do
                    if LimitNum.RewardId == ExchangeReward.Id then		
                        curLimitNum = LimitNum.RemainCount
                   end
                end
                
                if #ItemID == #enoughItem and curLimitNum > 0 then
                    return true
                end
            end
        end
	end
	return false
end

-- 是否显示骰子红点
def.method("=>", "boolean").IsShowDiceRedPoint = function(self)	
    if self._DiceInfoTable == nil then return false end
    if self._DiceInfoTable.CostItemTid == nil then return false end
    local packageNum = game._HostPlayer._Package._NormalPack:GetItemCount(self._DiceInfoTable.CostItemTid)
    -- 有骰子就显示true
    if packageNum > 0 then
        return true
    end

    -- 检查是否有可领取奖励, 有宝箱就显示
    local TotalNum = {}
    local TotalNumGet = {}
    if self._DiceInfoTable.TotleRewardIds == nil then return false end
    if self._DiceInfoTable.TotleCounts == nil then return false end
    if self._CurTotalGet == nil then return false end
    string.gsub(self._DiceInfoTable.TotleCounts, '[^*]+', function(w) table.insert(TotalNum, w) end )
    string.gsub(self._CurTotalGet, '[^*]+', function(w) table.insert(TotalNumGet, w) end )

    for i, v in ipairs(TotalNum) do
        if v ~= nil then
            for _, k in ipairs(TotalNumGet) do
                if self._CurTotalCount >= tonumber(v) and tonumber(v) ~= tonumber(k) then           
                    return true
                end
            end
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
---------------------骰子相关------------------------------
-- 当前骰子活动信息
def.method("=>", "table").GetDiceInfos = function(self)
    return self._DiceInfoTable
end

-- 当前骰子对应的物品列表信息
def.method("=>", "table").GetDiceItemInfoList = function(self)
    return self._DiceItemInfoList
end

-- 骰子当前位置
def.method("=>", "number").GetDicePos = function(self)
    return self._CurrentDicePos
end

-- 累计投掷骰子次数
def.method("=>", "number").GetDiceTotleCounts = function(self)
    return self._CurTotalCount
end

-- 累计投掷骰子次数对应宝箱领取状态
def.method("=>", "string").GetDiceTotleReward = function(self)
    return self._CurTotalGet
end

-- 投掷骰子数
def.method("=>", "string").GetRollDiceNum = function(self)
    return self._CurrentRollDiceNum
end

---------------------------------------------------------------
---------------------热点活动-------------------------------

-- 热点活动信息
def.method("number", "=>", "table").GetHotEventInfo = function(self, HotEventIndex)
    for _,v in pairs(self._HotEventInfoTable) do            
        if v._Tid == HotEventIndex then                    
            return v
        end
    end
    return self._HotEventInfoTable[1]
end
-----------------------------------------------------

-- 切换账号 或是 切换角色 恢复默认数据
def.method().Cleanup = function (self)
	self._UpdateInterval = 0
    self._CurrentDay = 0
    self._CurrentTempId = ""

    self._CurrentGloryLevel = 0
    self._IsOpenSign = false
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
    CGame.EventManager:removeHandler(GainNewItemEvent, OnGainNewItemEvent)
end

CWelfareMan.Commit()
return CWelfareMan