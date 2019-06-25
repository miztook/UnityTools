local PBHelper = require "Network.PBHelper"
local ERedPointType = require "PB.data".ERedPointType
local CMallMan = require "Mall.CMallMan"

local function OnS2CRedPointRes(sender,msg)
	if msg.Datas ~= nil then		
		for i,v in ipairs(msg.Datas) do
			game._CCalendarMan._IsQuestFinish = false
			if v.TypeIndex == ERedPointType.ERedPointType_Manual then 
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,true)
				game._CManualMan._ManualServerRedPoint = true
			elseif v.TypeIndex == ERedPointType.ERedPointType_Guild then 
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList,true)
			elseif v.TypeIndex == ERedPointType.ERedPointType_Mail then 
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mail,true)
			elseif v.TypeIndex == ERedPointType.ERedPointType_Achieve then
				game._AcheivementMan:SetShowRedPoint(true)
			elseif v.TypeIndex == ERedPointType.ERedPointType_Sign then 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bonus) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Welfare,true)
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_PetDrop then
				-- print("cuifenggong ---- RedDotSystemType.PetDrop -- true")
                CMallMan.Instance():SaveRedPointState(EnumDef.MallStoreType.PetExtract, game._CFunctionMan:IsUnlockByFunTid(75) and game._CFunctionMan:IsUnlockByFunTid(80))
			elseif v.TypeIndex == ERedPointType.ERedPointType_AdventureGuid then 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Calendar) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Calendar, true)
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_SpecialSign then 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bonus) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Welfare,true)
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_DailyTask then
				-- warn("lidaming ----ERedPointType_DailyTask--->>> v.count = ", v.Count) 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Activity) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Activity,true)
					game._CCalendarMan._IsQuestFinish = true
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_OnlineReward then 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bonus) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Welfare,true)
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_AdvancedGuide then 
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Activity) then
					CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Activity, true)
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_HotTime then
				local CPanelUIBuffEnter = require "GUI.CPanelUIBuffEnter" 
				-- warn("lidaming ----ERedPointType_HotTime--->>> v.count = ", v.Count) 
				if v.Count == nil then return end
				if v.Count > 0 then
					CPanelUIBuffEnter.Instance():IsShowHottimeBuffEnterSfx(true) 
				elseif v.Count <= 0 then
					CPanelUIBuffEnter.Instance():IsShowHottimeBuffEnterSfx(false) 
				end
			elseif v.TypeIndex == ERedPointType.ERedPointType_PVP3v3 
				or v.TypeIndex == ERedPointType.ERedPointType_GuildGather
				or v.TypeIndex == ERedPointType.ERedPointType_GuildBattleField
				or v.TypeIndex == ERedPointType.ERedPointType_GuildDef then
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Calendar) then
					game._CCalendarMan:MainRedPointState()
				end
			end
			-- warn("lidaming ----ERedPointType_AdventureGuid--->>> v.count = ", game._CCalendarMan:GetCalendarRedPointState(), game._CCalendarMan:IsShowDailyTaskRedPoint())
			if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Calendar) then
				game._CCalendarMan:MainRedPointState()
			end
		end
	end
end
PBHelper.AddHandler("S2CRedPointRes", OnS2CRedPointRes)
