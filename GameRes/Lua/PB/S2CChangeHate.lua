--
-- S2CChangeHate
--

local PBHelper = require "Network.PBHelper"
local HATE_OPTION = require "PB.net".HATE_OPT

local function OnS2CChangeHate(sender, msg)
    local hp = game._HostPlayer
	if hp == nil then return end
	for _,v in ipairs(msg.ChangeInfos) do
		local entityId = v.EntityID
    	local index = table.indexof(hp._HatedEntityMap, entityId)
		local entity = game._CurWorld:FindObject(entityId)
		
		if v.OptCode == HATE_OPTION.HATE_OPT_REMOVE then
			if index then  -- 如果有对应的id 就移除
				table.remove(hp._HatedEntityMap, index)
				game:UpdateCameraLockState(entityId, false)
				if hp._CurTarget ~= nil then
					hp:UpdateTargetInfo(hp._CurTarget, false)
				end
			end
		end
	
		if entity == nil then return end
	
		if entity:IsRole() then  -- 仇恨值变化只需要刷新名字颜色
			entity:SetPKMode(entity:GetPkMode())
			if entity._TopPate ~= nil then
				entity:UpdateTopPate(EnumDef.PateChangeType.HPLine)
				entity._TopPate:UpdateName(true)
				entity:UpdatePetName()
			end
		else
			entity:OnBattleTopChange(v.OptCode == HATE_OPTION.HATE_OPT_ADD)
		end
    end	
	
end
PBHelper.AddHandler("S2CChangeHate", OnS2CChangeHate)