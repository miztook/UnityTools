----------------------------------
------------次数组购买---------------S2CCountBuyRes
------------2018/05/25-----------
----------------------------------
local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local ServerMessageCountGroup = require "PB.data".ServerMessageCountGroup
local CGame = Lplus.ForwardDeclare("CGame")

--根据返回的code进行不同的提示
local function OnWelfareReturnCode(code)
    local ErrorCodeStr = StringTable.Get(31101)
    if code == ServerMessageCountGroup.CountGroupIsMax then
		ErrorCodeStr = ErrorCodeStr ..",".. StringTable.Get(31103)
	elseif code == ServerMessageCountGroup.NoBuyCount then
		ErrorCodeStr = ErrorCodeStr ..",".. StringTable.Get(31104)
	else
        ErrorCodeStr = ErrorCodeStr ..",".. code
		warn("msg.returnCode == " ..code)
	end
    game._GUIMan: ShowTipText(ErrorCodeStr, false)
end

-- 次数组购买返回数据
local function OnS2CCountBuyRes(sender, msg)
    -- 回应数据
    if msg == nil then return end
    -- warn("S2CCountBuyRes msg.errorCode == ", msg.errorCode, CountGroupId)
    if msg.errorCode == 0 then
        game._GUIMan: ShowTipText(StringTable.Get(31100), false)
        warn("S2CCountBuyRes game._CCountGroupMan._CountGroupData == ", #game._CCountGroupMan._CountGroupData)
        if game._CCountGroupMan._CountGroupData ~= nil then
            for i,v in pairs(game._CCountGroupMan._CountGroupData) do
                if v.Tid == msg.CountGroupId then 
                    v.Count = v.Count + 1
                    v.BuyCount = v.BuyCount + 1
                end 
            end
        else
            game._CCountGroupMan._CountGroupData = msg.CountGroups
        end

        local  CountGroupUpdateEvent = require "Events.CountGroupUpdateEvent"
        local event = CountGroupUpdateEvent()
        event._CountGroupTid = msg.CountGroupId
        CGame.EventManager:raiseEvent(nil, event) 
    else
        OnWelfareReturnCode(msg.errorCode)
    end
end
PBHelper.AddHandler("S2CCountBuyRes", OnS2CCountBuyRes)

-- 上线次数组数据同步
local function OnS2CCountGroupSync(sender, msg)
    if msg == nil then return end
    -- warn("lidaming S2CCountGroupSync ----------------> msg.CountGroups == ", #msg.CountGroups)
    game._CCountGroupMan._CountGroupData = msg.CountGroups
end
PBHelper.AddHandler("S2CCountGroupSync", OnS2CCountGroupSync)