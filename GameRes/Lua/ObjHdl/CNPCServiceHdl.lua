--[[ =============================
==	     服务处理入口
================================]]

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CNpc = require "Object.CNpc"
local QuestDef = require "Quest.QuestDef"
local CElementData = require "Data.CElementData"
local CQuest = require "Quest.CQuest"
local CPate = require "GUI.CPate".CPateBase
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local EServerUseType = require "PB.data".EServerUseType
local CPanelRoleInfo = require"GUI.CPanelRoleInfo"
local CNPCServiceHdl = Lplus.Class("CNPCServiceHdl")
do
	local def = CNPCServiceHdl.define

	local lookAtNpcEffectEnable = false

	local function EnableDialogEffect(npc, enable, call_back)

		if lookAtNpcEffectEnable == enable then return end

		local current_npc = npc

		if current_npc == nil then return end -- not in service

		local host = game._HostPlayer
		local serveNpcModel = current_npc._GameObject
		if IsNil(serveNpcModel) then return end

		-- 主界面效果
		game._GUIMan:SetMainUIMoveToHide(enable, nil)

		local serveNpcIconModel = current_npc._IconModel

		if enable then
			GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.NPC, false, current_npc._GameObject, 1, host:GetPos() - current_npc:GetPos(),function()
					if call_back then
						call_back()
					end
					if not IsNil(serveNpcIconModel) then
						GameUtil.SetLayerRecursively(serveNpcIconModel, EnumDef.RenderLayer.EntityAttached)
					end
				end)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.HostPlayer, false)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, false)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, false)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, false)
			CPate.ShowAll(false)
			GameUtil.SetLayerRecursively(serveNpcModel, EnumDef.RenderLayer.CG)
		else	
			CQuestAutoMan.Instance():Pause(_G.PauseMask.NpcService)	
			GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.NPC, false, current_npc._GameObject, 2, Vector3.zero,function()
					if call_back then
						call_back()
					end
					GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
					CQuestAutoMan.Instance():Restart(_G.PauseMask.NpcService)
				end)
			
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.HostPlayer, true)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, true)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, true)
			GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, true)
			CPate.ShowAll(true)
			GameUtil.SetLayerRecursively(serveNpcModel, EnumDef.RenderLayer.NPC)
			if not IsNil(serveNpcIconModel) then
				GameUtil.SetLayerRecursively(serveNpcIconModel, EnumDef.RenderLayer.EntityAttached)
			end
		end

		lookAtNpcEffectEnable = enable
	end

	-- 仅能在CHostOpHdl中调用
	def.static(CNpc, "table").BeginServ = function (npc, options)
		--warn("BeginServ", npc._ID, options, debug.traceback())
		if npc == nil or options == nil or #options < 1 then return end
		local function cb()
			local count = #options
			if count > 1 then
				EnableDialogEffect(npc, true,function()
						game._GUIMan:Open("CPanelNpcService", options)
					end)
			else
				CNPCServiceHdl.DealServiceOption(options[1])
			end
		end

		npc:EnterService(cb)
	end

	-- 仅能在CHostOpHdl中调用
	def.static(CNpc, "function").EndServ = function (npc, cb)
		--warn("EndServ", npc._ID, debug.traceback())
		if lookAtNpcEffectEnable then
			EnableDialogEffect(npc, false,function()
					if cb ~= nil then cb() end
				end)
			lookAtNpcEffectEnable = false
		else
			if cb ~= nil then cb() end
		end

		if npc ~= nil then
			npc:ExitService()
		end
	end

	local function onQuestDialogueClose(cur_npc, qid, qtype, sid, is_provide)
		--如果是接赏金任务 
		if qtype == QuestDef.QuestType.Reward and is_provide then
			local cb = function()
					CQuest.Instance():ProvideCyclic()
				end
			game._HostPlayer._OpHdl:EndNPCService(cb)
		else
			if is_provide then
	    		CQuest.Instance():DoReceiveQuest(cur_npc._ID, sid, qid)
	    	else
	    		--CQuest.Instance():DoDeliverQuest(cur_npc._ID, sid, qid, 0)
	    		local function cb()
	    			CQuest.Instance():DoDeliverQuest(cur_npc._ID, sid, qid, 0)
	    		end
	            local quest_model = CQuest.Instance():FetchQuestModel(qid)
	            local quest_data = quest_model:GetTemplate()
	            if quest_data.RewardId ~= 0 then
	                game._GUIMan:Open("CPanelUIQuestReward", { _QuestId = qid, OnFinish = cb })
                    --warn("P1")
                    --game._CGameTipsQ:ShowQuestFinishReward(qid, cb)
	            else
	                cb()
	            end
	    		
	    	end
			game._HostPlayer._OpHdl:EndNPCService(nil)
		end
	end

	def.static("table").DealServiceOption = function (option)
		local isUse = true
		-- 如果有一项不满足 则不通过
		local template = CElementData.GetServiceTemplate(option.service_id)
		-- if template.UseType == EServerUseType.UseType_Level then
		-- 	if template.UserTypeParam1 > game._HostPlayer._InfoData._Level then
		-- 		isUse = false
		-- 	end
		-- elseif template.UseType == EServerUseType.UseType_Guild then
		-- 	-- 如果使用的道具不等于配置的ID 不通过
		-- 	if not game._GuildMan:IsHostInGuild() then
		-- 		isUse = false
		-- 	end
		-- end
		--可以替换成 
		isUse = game._HostPlayer._OpHdl:JudgeServiceOptionIsUse(template)

		if isUse then
			local ho = game._HostPlayer._OpHdl
			local cur_server_npc = ho:GetCurServiceNPC()
			local isDurationService = false -- 是否移回主界面
			if option.service_type == EnumDef.ServiceType.Conversation then
				local conversation = option.service_data
				local function on_dialogue_close()
					CQuest.Instance():FinishConversationWithNpc(cur_server_npc._ID, option.service_id, conversation.DialogueId)
					game._HostPlayer._OpHdl:EndNPCService(nil)
				end
				local param = 
				{
					dialogue_id = option.service_data.DialogueId,
					on_close = on_dialogue_close,
				}
				game._GUIMan:Open("CPanelDialogue", param)	
				isDurationService = true
			elseif option.service_type == EnumDef.ServiceType.ProvideQuest then
				local provide_quest = option.service_data
				local quest_template = CElementData.GetQuestTemplate(provide_quest.Id)
				if quest_template ~= nil then
					local function on_dialogue_close()
						onQuestDialogueClose(cur_server_npc, option.service_data.Id, quest_template.Type, option.service_id, true)
					end

					if quest_template.ProvideRelated.DialogueId == 0 then
						on_dialogue_close()
					else
						local autoProvide = false
						if quest_template.ProvideRelated.ProvideMode.ViaNpc._is_present_in_parent then
							autoProvide = quest_template.ProvideRelated.ProvideMode.ViaNpc.IsAuto
						end
						local dlgid = quest_template.ProvideRelated.DialogueId
						local dialogue_model = CElementData.GetDialogueTemplate(dlgid)
						if dialogue_model == nil or dialogue_model.Sentences == nil or #dialogue_model.Sentences <= 0 then
							on_dialogue_close()
						else
							local is_camera_change = quest_template.Type == QuestDef.QuestType.Main or quest_template.Type == QuestDef.QuestType.Branch 
							is_camera_change = false
							local dialogue_data = 
							{
								dialogue_id = dlgid,
								on_close = on_dialogue_close,
								is_provide = true,
								is_autoProvide = autoProvide,
								is_camera_change = is_camera_change,
							}

							if is_camera_change and not lookAtNpcEffectEnable then
								EnableDialogEffect(cur_server_npc, true,function()
										game._GUIMan:Open("CPanelDialogue", dialogue_data)
									end)
							else
								game._GUIMan:Open("CPanelDialogue", dialogue_data)
							end
							isDurationService = true
						end
					end
				end
			elseif option.service_type == EnumDef.ServiceType.DeliverQuest then
				local deliver_quest = option.service_data
				local quest_template = CElementData.GetQuestTemplate(deliver_quest.Id)
				if quest_template ~= nil then
					local function on_dialogue_close()
						onQuestDialogueClose(cur_server_npc, option.service_data.Id, quest_template.Type, option.service_id, false)
					end
					if quest_template.DeliverRelated.DialogueId == 0 then
						on_dialogue_close()
					else
						local autoDeliver = false
						if quest_template.DeliverRelated.ViaNpc._is_present_in_parent then
							autoDeliver = quest_template.DeliverRelated.ViaNpc.IsAuto
						end
						local dlgid = quest_template.DeliverRelated.DialogueId
						local dialogue_model = CElementData.GetDialogueTemplate(dlgid)
						if dialogue_model == nil or dialogue_model.Sentences == nil or #dialogue_model.Sentences <= 0 then
							on_dialogue_close()
						else
							local is_camera_change = quest_template.Type == QuestDef.QuestType.Main or quest_template.Type == QuestDef.QuestType.Branch
							is_camera_change = false
							local dialogue_data = 
							{
								dialogue_id = dlgid,
								on_close = on_dialogue_close,
								is_provide = false,
								is_autoDeliver = autoDeliver,
								is_camera_change = is_camera_change,
							}
							if is_camera_change and not lookAtNpcEffectEnable then
								EnableDialogEffect(cur_server_npc, true,function()
										game._GUIMan:Open("CPanelDialogue", dialogue_data)
									end)
							else
								game._GUIMan:Open("CPanelDialogue", dialogue_data)
							end
						end
						isDurationService = true
					end
				end
			elseif option.service_type == EnumDef.ServiceType.CyclicQuest then
				local function on_dialogue_close()
					CQuest.Instance():ProvideCyclic()
					game._HostPlayer._OpHdl:EndNPCService(nil)
				end
				if template.CyclicQuest._is_present_in_parent then
					local dlgid = template.CyclicQuest.DialogueId
					local dialogue_model = CElementData.GetDialogueTemplate(dlgid)
					if dialogue_model == nil or dialogue_model.Sentences == nil or #dialogue_model.Sentences <= 0 then
						on_dialogue_close()
					else
						local dialogue_data = 
						{
							dialogue_id = dlgid,
							on_close = on_dialogue_close,
							is_provide = true,
							is_autoProvide = false,
							is_camera_change = false,
						}

						game._GUIMan:Open("CPanelDialogue", dialogue_data)
					end
					isDurationService = true
				else
					on_dialogue_close()
				end 
			elseif option.service_type == EnumDef.ServiceType.SellItem then
				
			elseif option.service_type == EnumDef.ServiceType.CreateGuild then
				local data = {_Index = 1}
				game._GUIMan:Open("CPanelUIGuildList", data)
			elseif option.service_type == EnumDef.ServiceType.GuildList then
				game._GuildMan:RequestAllGuildInfo()
			elseif option.service_type == EnumDef.ServiceType.GuildInfo then
				game._GuildMan:RequestAllGuildInfo()
			elseif option.service_type == EnumDef.ServiceType.GuildWareHouse then
				--game._GuildMan:OpenGuildWareHouse()
			elseif option.service_type == EnumDef.ServiceType.GuildSmithy then
				game._GuildMan:OpenGuildSmithy()
			elseif option.service_type == EnumDef.ServiceType.GuildPray then
				game._GuildMan:OpenGuildPray()
			elseif option.service_type == EnumDef.ServiceType.GuildDungeon then
				game._GuildMan:OpenGuildDungeon()
			elseif option.service_type == EnumDef.ServiceType.GuildShop then
				game._GuildMan:OpenGuildShop()
			elseif option.service_type == EnumDef.ServiceType.GuildLaboratory then
				game._GuildMan:OpenGuildLaboratory()
			elseif option.service_type == EnumDef.ServiceType.GuildKnowItem then
				game._GuildMan:OpenGuildKnowItem()
			elseif option.service_type == EnumDef.ServiceType.GuildSubmitItem then
				game._GuildMan:OpenGuildSubmitItem(option.service_data)
			elseif option.service_type == EnumDef.ServiceType.GuildApplyFortress then
				game._GuildMan:OpenGuildApplyFortress(option.service_data)
			elseif option.service_type == EnumDef.ServiceType.Transfer then
				game._GUIMan:Open("CPanelTransMap", option.service_data)
			elseif option.service_type == EnumDef.ServiceType.EnterDungeon then
				game._DungeonMan:TryEnterDungeon(option.service_data)
			elseif option.service_type == EnumDef.ServiceType.NpcSale then 
				local panelData = 
								{
									OpenType = 2,
									ShopId = option.service_data,
									ItemId = option.ItemId,
									Count  = option.Count,
									IsAuto = option.IsAuto,
								}
				game._GUIMan:Open("CPanelNpcShop",panelData)
				-- TODO: add other services
			elseif option.service_type ==  EnumDef.ServiceType.StoragePack then 
				local panelData = 
								{
									PageType = CPanelRoleInfo.PageType.BAG,
									IsByNpcOpenStorage = true
								}
				game._GUIMan:Open("CPanelRoleInfo",panelData)
			elseif option.service_type == EnumDef.ServiceType.ServiceQuestRandGroup then 
					local function on_dialogue_close()
						CQuest.Instance():QuestGroupProvide(option.service_id)
						game._HostPlayer._OpHdl:EndNPCService(nil)
					end


					if template.DialogueId == 0 then
						on_dialogue_close()
					else
						local dlgid = template.DialogueId
						local dialogue_model = CElementData.GetDialogueTemplate(dlgid)
						if dialogue_model == nil or dialogue_model.Sentences == nil or #dialogue_model.Sentences <= 0 then
							on_dialogue_close()
						else
							local is_camera_change = false
							local dialogue_data = 
							{
								dialogue_id = dlgid,
								on_close = on_dialogue_close,
								is_provide = true,
								is_autoProvide = true,
								is_camera_change = is_camera_change,
							}

							if is_camera_change and not lookAtNpcEffectEnable then
								EnableDialogEffect(cur_server_npc, true,function()
										game._GUIMan:Open("CPanelDialogue", dialogue_data)
									end)
							else
								game._GUIMan:Open("CPanelDialogue", dialogue_data)
							end
							isDurationService = true
						end
					end
			elseif option.service_type == EnumDef.ServiceType.FrontLine then
				CQuest.Instance():DoFrontLineInfo ( template.FrontLine.FrontLineId )
			end

			if not isDurationService then 
		    	game._HostPlayer._OpHdl:EndNPCService(nil)
		    end
		else
			game._GUIMan:ShowTipText(StringTable.Get(271), true)
			game._HostPlayer._OpHdl:EndNPCService(nil)
		end

	end

	def.static().Stop = function ()
		lookAtNpcEffectEnable = false
	end
end
return CNPCServiceHdl.Commit()

