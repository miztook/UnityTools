local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"

-- 获得货币发送系统消息提示
local function SendMsgToSysteamChannel(ItemID, nCount, AddCause)
    --[[ 取消获得货币系统提示
    local ENUM_ITEM_SRC = require "PB.data".ENUM_ITEM_SRC
    local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
	local ItemName = ""
    local ItemCount = nCount

    if nCount == nil then
        warn("ShowMoveItemTextTips-->货币数量错误")
        warn(debug.traceback())
    return end

    local CTokenMoneyMan = require "Data.CTokenMoneyMan"
    ItemName = CTokenMoneyMan.Instance():GetName(ItemID)

    local msg = nil
    if AddCause == ENUM_ITEM_SRC.SELL_ITEM then
        msg = string.format(StringTable.Get(13030), GUITools.FormatMoney(nCount))
    elseif AddCause == ENUM_ITEM_SRC.ITEM_DECOMPOSE or AddCause == ENUM_ITEM_SRC.DRESS_DECOMPOSE then
        -- 物品加工已经有显示提示
        msg = nil
    else
        msg = string.format(StringTable.Get(13032), ItemName, GUITools.FormatMoney(nCount))
    end
    if msg ~= nil then
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
    end
    ]]
end

local function OnS2CMoneyChanged(sender, protocol)
    -- 装备红点刷新检测
    local function SendEquipRetDotUpdateNotify()
        local Lplus = require "Lplus"
        local CGame = Lplus.ForwardDeclare("CGame")
        local EquipRetDotUpdateEvent = require "Events.EquipRetDotUpdateEvent"
        local event = EquipRetDotUpdateEvent()
        CGame.EventManager:raiseEvent(nil, event)     
    end

	--print("OnS2CMoneyChanged")
    local EResourceType = require "PB.data".EResourceType
	for i = 1, #protocol.AttrTypes do  

        local attr = protocol.AttrTypes[i]
        local nType = -1
        local nValue = -1

        nType = attr.AttrType
        nValue = attr.AttrValue
        if EResourceType.ResourceTypeGold == nType then
            if -1 ~= nValue then
                
                
                local pack = game._HostPlayer._Package
                local offset = nValue - pack._GoldCoinCount
                pack._GoldCoinCount = nValue
				game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold = nValue

                if offset > 0 then
                    --game._GUIMan:ShowGetCoinTip(offset)
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end

                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        elseif EResourceType.ResourceTypeDiamond == nType then
            if -1 ~= nValue then
                local accountInfo = game._AccountInfo
                local offset = nValue - accountInfo._Diamond
                accountInfo._Diamond = nValue
                if offset > 0 then
                   -- game._GUIMan:ShowGetDiamondTip(offset, false)
                   SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end

                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        elseif EResourceType.ResourceTypeBindDiamond == nType then
            if -1 ~= nValue then
                local pack = game._HostPlayer._Package
                local offset = nValue - pack._BindDiamondCount
                pack._BindDiamondCount = nValue
                game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].BindDiamond = nValue

                if offset > 0 then
                    --game._GUIMan:ShowGetDiamondTip(offset, true)
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end

                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        elseif EResourceType.ResourceTypeMarketDiamond == nType then
            if -1 ~= nValue then
                local pack = game._HostPlayer._Package
                local offset = nValue - pack._GreenDiamondCount
                pack._GreenDiamondCount = nValue
                game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].MarketDiamond = nValue

                if offset > 0 then
                    --game._GUIMan:ShowGetDiamondTip(offset, true)
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end

                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        elseif EResourceType.ResourceTypeArena == nType then
            if -1 ~= nValue then
                local offset = nValue - game._HostPlayer._InfoData._RoleResources[nType]
                if offset > 0 then
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end
                game._HostPlayer._InfoData._RoleResources[nType] = nValue
                
            end
        elseif EResourceType.ResourceTypePetDebris == nType then
            if -1 ~= nValue then
                local offset = nValue - game._HostPlayer._InfoData._RoleResources[nType]
                if offset > 0 then
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, true)
                end
                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        else 
            if -1 ~= nValue then
                local offset = nValue - game._HostPlayer._InfoData._RoleResources[nType]
                if offset > 0 then
                    SendMsgToSysteamChannel(nType, offset, protocol.AddCause)
                    game._GUIMan:ShowMoveItemTextTips(nType,true,offset, false)
                end
                game._HostPlayer._InfoData._RoleResources[nType] = nValue
            end
        end
    end

    local event = NotifyMoneyChangeEvent()
    event.ObjID = game._HostPlayer._ID
    event.Type = "All"
    CGame.EventManager:raiseEvent(nil, event)

    -- 装备红点刷新检测
    SendEquipRetDotUpdateNotify()

    -- 技能升级红点刷新
    local CSkillUtil = require "Skill.CSkillUtil"
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp()) 
end

PBHelper.AddHandler("S2CMoneyChanged", OnS2CMoneyChanged)