----------------------------------
------------福利通信---------------S2CWelfare
----------------------------------

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"
local ServerMessageBase = require "PB.data".ServerMessageBase
local ServerMessageGlory = require "PB.data".ServerMessageGlory
local ServerMessageOnlineReward = require "PB.data".ServerMessageOnlineReward


local ServerMessageScript = require "PB.data".ServerMessageScript

local EScriptEventType = require "PB.data".EScriptEventType
local ESystemType = require "PB.Template".ScriptCalendar.ESystemType

--根据返回的code进行不同的提示
local function OnWelfareReturnCode(code)
    local ErrorCodeStr = ""
	if code == ServerMessageScript.SignNotVaildDay then
		ErrorCodeStr = StringTable.Get(19456)
	elseif code == ServerMessageScript.SignDiffDay then
		ErrorCodeStr = StringTable.Get(19457)
	elseif code == ServerMessageScript.SignDone then
		ErrorCodeStr = StringTable.Get(19458)
	elseif code == ServerMessageScript.SignRemedyDayErr then
		ErrorCodeStr = StringTable.Get(19459)
	elseif code == ServerMessageScript.SignTotleNotEnough then
		ErrorCodeStr = StringTable.Get(19460)
	elseif code == ServerMessageScript.SignGained then
		ErrorCodeStr = StringTable.Get(19461)    
    elseif code == ServerMessageGlory.GloryGiftNotEnoughMoney then
		ErrorCodeStr = StringTable.Get(260)
    elseif code == ServerMessageGlory.GloryGiftNotEnoughBagBox then
        ErrorCodeStr = StringTable.Get(256)
    elseif code == ServerMessageBase.NotEnoughMoney then
        ErrorCodeStr = StringTable.Get(19466)
    elseif code == ServerMessageOnlineReward.OnlineReward_TimeLimit then
        ErrorCodeStr = StringTable.Get(19466)
    elseif code == ServerMessageOnlineReward.OnlineReward_HasDraw then
        ErrorCodeStr = StringTable.Get(19466)
	else
        ErrorCodeStr = tostring(code)
		warn("msg.returnCode == " ..code)
	end
    game._GUIMan: ShowTipText(ErrorCodeStr, true)
end


--上线发放的福利消息
local function OnS2CScriptStateSync(sender, msg)
    local allTid = CElementData.GetAllTid("ScriptCalendar")
    for _,ScriptCalendarTid in ipairs(allTid) do     
        local ScriptCalendarTemp = CElementData.GetTemplate("ScriptCalendar", tonumber(ScriptCalendarTid))
        if ScriptCalendarTemp.SystemType == ESystemType.Bonus then
            for _,v in ipairs(msg.Datas) do          
                -- 脚本ID SystemType = ESystemType.Bonus 时显示      
                if v.ScriptId == ScriptCalendarTemp.ScriptId then
                    -- warn("--------S2CScriptStateSync------->>>", v.ScriptId, v.IsActivity, v.OpenTime, v.CloseTime)   
                    game._CWelfareMan:OnWelfareInfo(v, v.IsActivity)
                end
            end   
        end
    end    
end
PBHelper.AddHandler("S2CScriptStateSync", OnS2CScriptStateSync)


--请求脚本开启状态
local function OnS2CScriptEnable(sender,msg)
	-- -- 返回脚本当前的状态 msg.Data.ScriptCalendarId
    local allTid = CElementData.GetAllTid("ScriptCalendar")
    for _,ScriptCalendarTid in ipairs(allTid) do     
        local ScriptCalendarTemp = CElementData.GetTemplate("ScriptCalendar", tonumber(ScriptCalendarTid))
        if ScriptCalendarTemp.SystemType == ESystemType.Bonus then        
            -- 脚本ID SystemType = ESystemType.Bonus 时显示      
            if msg.Data.ScriptId == ScriptCalendarTemp.ScriptId then
                -- warn("--------S2CScriptEnable------->>>", msg.Data.ScriptId, msg.Data.IsActivity, msg.Data.OpenTime, msg.Data.CloseTime) 
                game._CWelfareMan:OnWelfareInfo(msg.Data, msg.Data.IsActivity)	
            end  
        end
    end  
end
PBHelper.AddHandler("S2CScriptEnable", OnS2CScriptEnable)

local function OnS2CScriptDataSync(sender, msg)
    -- 回应数据
    if msg.ScriptId == nil then return end
    -- warn("S2CScriptDataSync msg.Param2 == ", msg.Param2)
    game._CWelfareMan:OnWelfareDatas(msg)
end
PBHelper.AddHandler("S2CScriptDataSync", OnS2CScriptDataSync)

--执行某事件结果
local function OnS2CScriptExec(sender,msg)
	-- 事件结果    
    -- warn("msg.ErrorCode == ", msg.ErrorCode)
    if msg.ErrorCode == 0 then
        game._CWelfareMan:OnWelfareEventType(msg)
    else
        if msg.ErrorCode == ServerMessageBase.NotEnoughItem then
            game._GUIMan: ShowTipText(StringTable.Get(34354), true)    
            return
        else
            game._GUIMan:ShowErrorCodeMsg(msg.ErrorCode, nil)
            return
        end
	end
end
PBHelper.AddHandler("S2CScriptExec", OnS2CScriptExec)

-- 返回荣耀之路数据
local function OnS2CGloryCurrentInfo(sender, msg)
    -- 回应数据
    if msg.curLevel == nil then return end
    -- warn("S2CGloryCurrentInfo msg.curLevel == ", msg.curLevel)
    game._HostPlayer._InfoData._GloryLevel = msg.curLevel
    game._CWelfareMan:OnGloryCurrentInfo(msg)
end
PBHelper.AddHandler("S2CGloryCurrentInfo", OnS2CGloryCurrentInfo)

-- 返回荣耀之路礼包购买数据
local function OnS2CGloryBuyLevelGift(sender, msg)
    warn("msg.errorCode ===", msg.errorCode)
    if msg.errorCode == 0 then
        if msg.curLevel == nil then return end
        -- warn("S2CGloryBuyLevelGift msg.curLevel == ", msg.curLevel)
        game._HostPlayer._InfoData._GloryLevel = msg.curLevel
        game._CWelfareMan:OnGloryCurrentInfo(msg)
    else
		OnWelfareReturnCode(msg.errorCode)
        -- game._GUIMan:ShowErrorCodeMsg(msg.errorCode, nil)
		return
	end
    
end
PBHelper.AddHandler("S2CGloryBuyLevelGift", OnS2CGloryBuyLevelGift)

-- 获取在线奖励数据
local function OnS2COnlineRewardViewInfo(sender, msg)
    -- 回应数据
    if msg.OnlineTime == nil then return end
    -- warn("S2COnlineRewardViewInfo msg.OnlineTime == ", msg.OnlineTime)
    game._CWelfareMan:OnOnlineRewardInfo(msg)
end
PBHelper.AddHandler("S2COnlineRewardViewInfo", OnS2COnlineRewardViewInfo)

-- 返回在线奖励领取返回数据
local function OnS2COnlineRewardDrawReward(sender, msg)
    if msg.ResCode == 0 then
        -- if msg.OnlineRewardId == nil then return end
        -- warn("S2COnlineRewardDrawReward msg.OnlineRewardId == ", #msg.DrawIdList)
        game._CWelfareMan:OnOnlineRewardDrawReward(msg.DrawIdList)
    else
		OnWelfareReturnCode(msg.ResCode)
        -- game._GUIMan:ShowErrorCodeMsg(msg.errorCode, nil)
		return
	end
end
PBHelper.AddHandler("S2COnlineRewardDrawReward", OnS2COnlineRewardDrawReward)