--
-- S2CPet
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

local function SendMsgToSysteamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
end
local function SendMsgToTeamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	TeraFuncs.SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, msg, false, 0, nil,nil)
end

local function UpdatePanel()
	local CPanelPet = require "GUI.CPanelPet"
	if CPanelPet ~= nil and CPanelPet.Instance():IsShow() then
		CPanelPet.Instance():Update()
	end
end

-- 宠物红点刷新
local function SendPetRetDotUpdateNotify()
	local Lplus = require "Lplus"
	local CGame = Lplus.ForwardDeclare("CGame")
	local PetRetDotUpdateEvent = require "Events.PetRetDotUpdateEvent"
    local event = PetRetDotUpdateEvent()

    CGame.EventManager:raiseEvent(nil, event)
end


local function SentUpdateEvnet( type )
	local Lplus = require "Lplus"
	local CGame = Lplus.ForwardDeclare("CGame")
	local PetUpdateEvent = require "Events.PetUpdateEvent"

	local event = PetUpdateEvent()
	event._Type = type
	CGame.EventManager:raiseEvent(nil, event)
end


--[[=============================================================================================================]]

--宠物同步
local function OnS2CPetInfo(sender,protocol)
--warn("=============OnS2CPetInfo=============")
	local hp = game._HostPlayer
	local petPackage = hp._PetPackage

	petPackage:InitPetList(protocol.petDetails)
end
PBHelper.AddHandler("S2CPetInfo", OnS2CPetInfo)

--宠物信息变更
local function OnS2CPetUpdate(sender,protocol)
	local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
	local curType = protocol.optType
	local hp = game._HostPlayer
	local petPackage = hp._PetPackage
	if curType == EPetOptType.EPetOptType_reName then
		--warn("重命名")
		if protocol.reName == nil then 
			warn("Error: protocol.reName is null!")
			return
		end

		-- 自己的同步UI逻辑
		if hp._ID == protocol.reName.roleId then
			local pet = petPackage:GetPetById(protocol.reName.petId)
			if pet == nil then 
				warn("Error Can not find in client cache petId : ", protocol.reName.petId)
				return
			else
				pet:UpdateNickName(protocol.reName.name)
			end
			SentUpdateEvnet(curType)
		end

		-- 刷新 entity toppate
		local petEntity = game._CurWorld:FindObject(protocol.reName.petEntityId) 
		if petEntity then
			petEntity:UpdateName(protocol.reName.name)
			petEntity:SetColorName()
		end

	elseif curType == EPetOptType.EPetOptType_gain then
		--warn("获得宠物")
		if protocol.gain == nil then 
			warn("Error: protocol.gain is null!")
			return
		end
		petPackage:UpdatePetList(true, protocol.gain.petDetails)
		SentUpdateEvnet(curType)

	elseif curType == EPetOptType.EPetOptType_free then
		--warn("放生")
		if protocol.free == nil then 
			warn("Error: protocol.free is null!")
			return
		end
		petPackage:UpdatePetList(false, protocol.free.petId)
		SentUpdateEvnet(curType)

	elseif curType == EPetOptType.EPetOptType_fight then
		--warn("出战",protocol.fight.petId)
		if protocol.fight == nil then 
			warn("Error: protocol.fight is null!")
			return
		end
		hp:SetCurrentFightPetId(protocol.fight.petId)
		SentUpdateEvnet(curType)

	elseif curType == EPetOptType.EPetOptType_help then
		--warn("助战",protocol.help.petId)
		if protocol.help == nil then 
			warn("Error: protocol.help is null!")
			return
		end

		--warn("protocol.help.helpCellIndex = ", protocol.help.helpCellIndex)
		hp:SetCurrentHelpPetList(protocol.help.petId, protocol.help.helpCellIndex+1)
		SentUpdateEvnet(curType)
		
	elseif curType == EPetOptType.EPetOptType_talent then
		--warn("被动技能获得")
		if protocol.talent == nil then 
			warn("Error: protocol.talent is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.talent.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.talent.petId)
			return
		else
			local talentTemplate1 = CElementData.GetTemplate("Talent", protocol.talent.newTalentTId)
            local talentName1 = RichTextTools.GetQualityText(talentTemplate1.Name, talentTemplate1.InitQuality)
            local name = RichTextTools.GetQualityText(pet:GetNickName(), pet._Quality)
            local str = ""
			if protocol.talent.opt == 1 then
				-- 新增
				str = string.format(StringTable.Get(19067), name, talentName1)
			else
				-- 替换
				local talentTemplate2 = CElementData.GetTemplate("Talent", protocol.talent.oldTalentTId)
            	local talentName2 = RichTextTools.GetQualityText(talentTemplate2.Name, talentTemplate2.InitQuality)
            	str = string.format(StringTable.Get(19068), name, talentName1, talentName2)
			end

			TeraFuncs.SendFlashMsg(str)
			SendMsgToSysteamChannel(str)
			pet:InitSkill(protocol.talent.petSkillDatas)
			pet:UpdateFightScore(protocol.talent.fightScore)
			pet:UpdateInsteadSkillIndex(protocol.talent.newTalentTId)
			SentUpdateEvnet(curType)

			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Skill, 0)
		end
	elseif curType == EPetOptType.EPetOptType_takedown then
		-- warn("摘除")
		if protocol.takedown == nil then 
			warn("Error: protocol.talent is null!")
			return
		end
		local pet = petPackage:GetPetById(protocol.takedown.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.takedown.petId)
			return
		else
			local str = StringTable.Get(19087)
			TeraFuncs.SendFlashMsg(str)
			SendMsgToSysteamChannel(str)
			pet:InitSkill(protocol.takedown.petSkillDatas)
			pet:UpdateFightScore(protocol.takedown.fightScore)
			pet:SetLastTakedownIndex(protocol.takedown.slotIndex + 1)
			SentUpdateEvnet(curType)
			pet:SetLastTakedownIndex(0)
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Skill, 0)
		end

	elseif curType == EPetOptType.EPetOptType_confirmRecast then
		--warn("确认洗练")
		if protocol.confirmRecast == nil then 
			warn("Error: protocol.confirmRecast is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.confirmRecast.petDetail.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.confirmRecast.petDetail.petId)
			return
		else
			local skill_field_count = pet:GetSkillFieldCount()
			pet:UpdateAll(protocol.confirmRecast.petDetail)
            if pet:GetSkillFieldCount() > skill_field_count then
                TeraFuncs.SendFlashMsg(StringTable.Get(19076))
            end
			SentUpdateEvnet(curType)
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillCommon, 0)
			
			-- if not protocol.confirmRecast.bReset then
			-- 	local name = RichTextTools.GetQualityText(pet:GetNickName(), pet._Quality)
			-- 	local str = string.format(StringTable.Get(19064), name)
			-- 	SendMsgToSysteamChannel(str)
			-- end
   --          
			-- pet:UpdateAll(protocol.confirmRecast.petDetail)
   --          if pet:GetSkillFieldCount() > skill_field_count then
   --              TeraFuncs.TeraFuncs.SendFlashMsg(StringTable.Get(19076))
   --          end
			-- SentUpdateEvnet(curType)

			-- 需要新加数据
			-- local CPanelCommonCultivae = require"GUI.CPanelCommonCultivate"
			-- local PanelData = 
			-- {
			-- 	NewData = protocol.confirmRecast.petDetail ,
			-- 	OldData = protocol.confirmRecast.petDetailOld,
			-- 	Type = CPanelCommonCultivae.OpenType.PetRecastResult,
			-- }
			-- game._GUIMan:Open("CPanelCommonCultivate",PanelData )
		end

	elseif curType == EPetOptType.EPetOptType_levelup then
		--warn("升级")
		if protocol.levelUp == nil then 
			warn("Error: protocol.levelUp is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.levelUp.petDetails.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.levelUp.petDetails.petId)
			return
		else
			local name = RichTextTools.GetQualityText(pet:GetNickName(), pet._Quality)
			local str = string.format(StringTable.Get(19063), name, protocol.levelUp.petDetails.level)
            local skill_field_count = pet:GetSkillFieldCount()
			SendMsgToSysteamChannel(str)
			TeraFuncs.SendFlashMsg(str)
			pet:UpdateAll(protocol.levelUp.petDetails)
            if pet:GetSkillFieldCount() > skill_field_count then
                TeraFuncs.SendFlashMsg(StringTable.Get(19076))
            end
			SentUpdateEvnet(curType)

			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Levelup, 0)
		end

	elseif curType == EPetOptType.EPetOptType_rest then
		--warn("休息",protocol.rest.petId)
		if protocol.rest == nil then 
			warn("Error: protocol.rest is null!")
			return
		end
		hp:RestPetById(protocol.rest.petId)
		SentUpdateEvnet(curType)

	elseif curType == EPetOptType.EPetOptType_advance then
		--warn("升阶")
		if protocol.advance == nil then 
			warn("Error: protocol.advance is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.advance.petDetails.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.advance.petDetails.petId)
			return
		else
            local skill_field_count = pet:GetSkillFieldCount()
			SendMsgToSysteamChannel(string.format(StringTable.Get(19065)))
			pet:UpdateAll(protocol.advance.petDetails)
			petPackage:UpdatePetList(false, protocol.advance.deletePetId)
            if pet:GetSkillFieldCount() > skill_field_count then
                TeraFuncs.SendFlashMsg(StringTable.Get(19076))
            end
			SentUpdateEvnet(curType)
			local CPanelCommonCultivae = require"GUI.CPanelCommonCultivate"
			local PanelData = 
			{
				NewData = protocol.advance.petDetails ,
				OldData = protocol.advance.petDetailsOld,
				Type = CPanelCommonCultivae.OpenType.PetAdvanceResult,
				Exp = protocol.materialPetTotalExp,
			}
	        game._GUIMan:Open("CPanelCommonCultivate",PanelData )
	        
	        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Advance, 0)
		end

	elseif curType == EPetOptType.EPetOptType_petBagCell then
		--warn("宠物背包格子变化")
		local hp = game._HostPlayer
		hp._PetPackage:ReSize(protocol.petBagCell.currentCellNumber)
		SentUpdateEvnet(curType)

	elseif curType == EPetOptType.EPetOptType_petHelpFightingCellNumnber then
		--warn("宠物助战栏格子变化", protocol.petHelpFightingCellNumber.currentHelpFightingCellNumber)
		if protocol.petHelpFightingCellNumber == nil then 
			warn("Error: protocol.petHelpFightingCellNumber is null!")
			return
		end
		local hp = game._HostPlayer
		hp:SetCurrentHelpPetList(0, protocol.petHelpFightingCellNumber.currentHelpFightingCellNumber)

	elseif curType == EPetOptType.EPetOptType_exp then
		--warn("宠物经验同步")
		if protocol.petUpdateExp == nil then 
			warn("Error: protocol.petUpdateExp is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.petUpdateExp.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.petUpdateExp.petId)
			return
		else
			pet:UpdateExp(protocol.petUpdateExp.exp)
			local str = string.format(StringTable.Get(19015), GUITools.FormatNumber(protocol.petUpdateExp.addTotalExp))
			TeraFuncs.SendFlashMsg(str)
			SentUpdateEvnet(curType)
		end
	elseif curType == EPetOptType.EPetOptType_ResetRecastCount then
		--warn("宠物 洗练重置")
		if protocol.petResetRecastCount == nil then 
			warn("Error: protocol.petResetRecastCount is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.petResetRecastCount.petId)
		if pet == nil then
			warn("Error Can not find in client cache petId : ", protocol.petResetRecastCount.petId)
			return
		else
			pet:UpdateRecastCount(protocol.petResetRecastCount.recastCount)
		end
		local name = RichTextTools.GetQualityText(pet:GetNickName(), pet._Quality)
		local str = string.format(StringTable.Get(19066), name)
		SendMsgToSysteamChannel(str)
		TeraFuncs.SendFlashMsg(str)
		SentUpdateEvnet(curType)
	elseif curType == EPetOptType.EPetOptType_TotalFightSocre then
		-- warn("宠物 宠物提供人物战斗力")
		petPackage:SetTotalFightScore(protocol.totalFightScore.fightScore)
		SentUpdateEvnet(curType)
	elseif curType == EPetOptType.EPetOptType_fuse then
		-- warn("宠物 融合")
		if protocol.fuse == nil then 
			warn("Error: protocol.fuse is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.fuse.petDetails.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.fuse.petDetails.petId)
			return
		else
            local skill_field_count = pet:GetSkillFieldCount()
			SendMsgToSysteamChannel(string.format(StringTable.Get(19086)))
			pet:UpdateAll(protocol.fuse.petDetails)

			for i,deletePetId in ipairs(protocol.fuse.deletePetIds) do
				petPackage:UpdatePetList(false, deletePetId)
			end
			
            if pet:GetSkillFieldCount() > skill_field_count then
                TeraFuncs.SendFlashMsg(StringTable.Get(19076))
            end
			SentUpdateEvnet(curType)
			local CPanelCommonCultivae = require"GUI.CPanelCommonCultivate"
			local PanelData = 
			{
				NewData = protocol.fuse.petDetails ,
				OldData = protocol.fuse.petDetailsOld,
				Type = CPanelCommonCultivae.OpenType.PetFuseResult,
			}
	        game._GUIMan:Open("CPanelCommonCultivate", PanelData)
	        
	        CSoundMan.Instance():Play2DAudio(PATH.GUISound_PetProcessing, 0)
		end
	elseif curType == EPetOptType.EPetOptType_star then
		-- warn("升星")
		if protocol.star == nil then 
			warn("Error: protocol.star is null!")
			return
		end

		local pet = petPackage:GetPetById(protocol.star.petDetails.petId)
		if pet == nil then 
			warn("Error Can not find in client cache petId : ", protocol.star.petDetails.petId)
			return
		else
            local skill_field_count = pet:GetSkillFieldCount()
			SendMsgToSysteamChannel(string.format(StringTable.Get(19065)))
			pet:UpdateAll(protocol.star.petDetails)
			petPackage:UpdatePetList(false, protocol.star.deletePetId)
            if pet:GetSkillFieldCount() > skill_field_count then
                TeraFuncs.SendFlashMsg(StringTable.Get(19076))
            end
			SentUpdateEvnet(curType)
			local CPanelCommonCultivae = require"GUI.CPanelCommonCultivate"
			local PanelData = 
			{
				NewData = protocol.star.petDetails ,
				OldData = protocol.star.petDetailsOld,
				Type = CPanelCommonCultivae.OpenType.PetAdvanceResult,
				Exp = protocol.materialPetTotalExp,
			}
	        game._GUIMan:Open("CPanelCommonCultivate", PanelData)
	        
	        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Advance, 0)
		end
		
	else
		warn("Error:: S2CPetUpdate.optType Unknown!")
		return
	end

	-- 宠物红点刷新检测
	SendPetRetDotUpdateNotify()	
end
PBHelper.AddHandler("S2CPetUpdate", OnS2CPetUpdate)