local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"


local function OnS2CMoneyChanged(sender, protocol)
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
                --print("拾取到了"..nValue.."金币")
                local pack = game._HostPlayer._Package
                local offset = nValue - pack._GoldCoinCount
                pack._GoldCoinCount = nValue
				game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold = nValue

                if offset > 0 then
                    game._GUIMan:ShowGetCoinTip(offset)
                end
            end
        elseif EResourceType.ResourceTypeDiamond == nType then
            if -1 ~= nValue then
                local accountInfo = game._AccountInfo
                local offset = nValue - accountInfo._Diamond
                accountInfo._Diamond = nValue
                if offset > 0 then
                    game._GUIMan:ShowGetDiamondTip(offset, false)
                end
            end
        elseif EResourceType.ResourceTypeBindDiamond == nType then
            if -1 ~= nValue then
                local pack = game._HostPlayer._Package
                local offset = nValue - pack._BindDiamondCount
                pack._BindDiamondCount = nValue
                game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].BindDiamond = nValue

                if offset > 0 then
                    game._GUIMan:ShowGetDiamondTip(offset, true)
                end
            end
        end
    end

    local event = NotifyMoneyChangeEvent()
    event.ObjID = game._HostPlayer._ID
    event.Type = "All"
    CGame.EventManager:raiseEvent(nil, event) 
end

PBHelper.AddHandler("S2CMoneyChanged", OnS2CMoneyChanged)