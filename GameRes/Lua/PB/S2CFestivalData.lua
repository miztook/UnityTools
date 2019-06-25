----------------------------------
------------节日兑换---------------S2CFestivalData
----------------------------------

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"
local ServerMessageBase = require "PB.data".ServerMessageBase
local ServerMessageGlory = require "PB.data".ServerMessageGlory
local ServerMessageOnlineReward = require "PB.data".ServerMessageOnlineReward

local ServerMessageScript = require "PB.data".ServerMessageFestival

--根据返回的code进行不同的提示
local function OnFestivalReturnCode(code)
    local ErrorCodeStr = ""
	if code == ServerMessageScript.Festival_Error then
		ErrorCodeStr = StringTable.Get(34300)
	elseif code == ServerMessageScript.Festival_Success then
		ErrorCodeStr = StringTable.Get(34302)
	elseif code == ServerMessageScript.Festival_OverLimit then
		ErrorCodeStr = StringTable.Get(34301)
	else
        ErrorCodeStr = tostring(code)
		warn("msg.returnCode == " ..code)
	end
    game._GUIMan: ShowTipText(ErrorCodeStr, true)
end

local function OnS2CFestivalDataSync(sender, msg)
    -- 回应数据
    if msg.FestivalDatas == nil and #msg.FestivalDatas <= 0 then return end
    -- warn("S2CFestivalDataSync ------------------ #msg.FestivalDatas == ", #msg.FestivalDatas)
    game._CWelfareMan:OnFestivalInfo(msg.FestivalDatas)
end
PBHelper.AddHandler("S2CFestivalDataSync", OnS2CFestivalDataSync)

--执行某事件结果
local function OnS2CFestivalExchange(sender,msg)
    -- 事件结果   
    OnFestivalReturnCode(msg.ErrorCode) 
    if msg.ErrorCode == ServerMessageScript.Festival_Success then
        game._CWelfareMan:OnFestivalExchange(msg)
    else
        -- game._GUIMan:ShowErrorCodeMsg(msg.ErrorCode, nil)
        warn("S2CFestivalExchange msg.ErrorCode == ", msg.ErrorCode)
		return
	end
end
PBHelper.AddHandler("S2CFestivalExchange", OnS2CFestivalExchange)