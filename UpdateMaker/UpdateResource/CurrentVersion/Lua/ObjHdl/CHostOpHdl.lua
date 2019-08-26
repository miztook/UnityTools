--CHostOpHdl
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")
local CNpc = Lplus.ForwardDeclare("CNpc")
local CQuest = require "Quest.CQuest"
local CElementData = require "Data.CElementData"
local CNPCServiceHdl = require "ObjHdl.CNPCServiceHdl"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local EServerShowType = require "PB.data".EServerShowType
local EServerUseType = require "PB.data".EServerUseType
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"

local CHostOpHdl = Lplus.Class("CHostOpHdl")
local def = CHostOpHdl.define

def.field(CHostPlayer)._Host = nil
def.field(CNpc)._CurServiceNPC = nil
def.field("number")._ServNPCCheckTimer = 0
def.field("boolean")._IsInNpcService = false
def.field("function")._OnNpcGreeting = nil
def.field("boolean")._SwitchAutoModeWhenEnd = false

local GuildOpenLevelId = 64
local GuildOpenLevel = nil
local max_npc_talk_dis = 5
local max_npc_talk_dis_sqr = 15 * 15
local max_npc_talk_stop_dis = 2

def.static(CHostPlayer, "=>", CHostOpHdl).new = function (hostplayer)
	local hdl = CHostOpHdl()
	hdl._Host = hostplayer
	return hdl
end

def.method("=>", CNpc).GetCurServiceNPC = function(self)
	return self._CurServiceNPC
end

local function ClearCurServerInfo(self, cb)
	if self._IsInNpcService then
    	CNPCServiceHdl.EndServ(self._CurServiceNPC, cb)
	   
    	self._CurServiceNPC = nil

	    if self._ServNPCCheckTimer ~= 0 then
		    _G.RemoveGlobalTimer(self._ServNPCCheckTimer)
		    self._ServNPCCheckTimer = 0
	    end

	    -- close ui
	    do
		    game._GUIMan:Close("CPanelNpcService")
		    game._GUIMan:Close("CPanelDialogue")
		    --game._GUIMan:Close("CPanelServiceProvideAndDeliverQuest")
	    end

        self._IsInNpcService = false
        self._SwitchAutoModeWhenEnd = false
    end
	self:RemoveNpcGreeting()
end

def.method(CNpc, "table").TalkToServerNpc = function (self, npc, params)
	--需求变更这块不要了具体情况咨询孔令志
	-- if self._Host:IsInCombatState() then 
	-- 	warn("host player is combating! can not talk to any npc.")
	-- 	return 
	-- end

	if npc == nil then 
		self._SwitchAutoModeWhenEnd = false
		return 
	end

	--warn("lijian - TalkToServerNpc", npc._ID, " ", debug.traceback())

	if npc:IsDead() then 
		self._SwitchAutoModeWhenEnd = false
		return 
	end
	if not npc:CanBeInteracted() then 
		self._SwitchAutoModeWhenEnd = false
		return 
	end

	local hostX, hostZ = self._Host:GetPosXZ()
	local npcX, npcZ = npc:GetPosXZ()
	local distanceSqr = SqrDistanceH(hostX, hostZ, npcX, npcZ)
	if distanceSqr > max_npc_talk_dis_sqr then 
		self._SwitchAutoModeWhenEnd = false
		return 
	end

	if self._Host:IsInCanNotInterruptSkill() then   -- 技能状态
		local function WiaitToNpcTalk()
			self:TalkToServerNpc(npc, params)
		end
		self._Host:AddCachedAction(WiaitToNpcTalk)
		return
	end

	if not npc._ServiceOpenFlag then
		self._SwitchAutoModeWhenEnd = false
		return
	end

	local options = self:FilterServiceOptions(npc, params)
	if #options <= 0 and IsNilOrEmptyString(npc._NpcTemplate.TextDefaultConversation) then
		warn("not valid service or npc nothing to say.")
		self._SwitchAutoModeWhenEnd = false
		return
	end

	-- 已在服务中，不需要重新开始
	if self._CurServiceNPC ~= nil and self._CurServiceNPC._ID == npc._ID then
		return 
	end

	do
	-- 以下逻辑只限巡逻NPC
		local C2SNpcClick = require "PB.net".C2SNpcClick
		local protocol = C2SNpcClick()
		protocol.npcEntityId = npc._ID
		local PBHelper = require "Network.PBHelper"
		PBHelper.Send(protocol)	
	end
	
	local CHostAsyncTask = require "ObjHdl.CHostAsyncTask"
	local task = CHostAsyncTask.ApproachToEntityPos(npc:GetPos(), max_npc_talk_dis-1, max_npc_talk_stop_dis)
	task:completeWith( function()
		game._HostPlayer:Stand()
		if #options <= 0 then
			if not IsNilOrEmptyString(npc._NpcTemplate.TextDefaultConversation) then
				--播放npc默认声音 
				local soundPath = nil
				if npc._NpcTemplate ~= nil then
					soundPath = npc._NpcTemplate.DefaultSound
				end
				--避免点击和谈话重复
				if not IsNilOrEmptyString(soundPath) then
					CSoundMan.Instance():Play3DVoice(soundPath, npc:GetPos(), 0)
				else
					CSoundMan.Instance():Play3DVoice("", npc:GetPos(), 0)
				end
				self:StartNpcService(npc, options, params)
			end
			return
		end

		local PBHelper = require "Network.PBHelper"
		-- 注册回复消息
		self._OnNpcGreeting = function(sender, msg)
			ClearCurServerInfo(self, nil)
			local id = msg.EntityId
			-- TODO: 这里的逻辑是有问题的！！！！
			if npc ~= nil --[[and npc._ID == id]] then
				self:StartNpcService(npc, options, params)
			end
		end
		PBHelper.AddHandler("S2CNpcGreeting", self._OnNpcGreeting)

		-- 发送握手协议
		do
			local C2SServiceHello = require "PB.net".C2SServiceHello
			local msg = C2SServiceHello()
			msg.NpcId = npc._ID
		    PBHelper.Send(msg)
		end
		-- 开启超时检查
		_G.AddGlobalTimer(5, true, function()
			self:RemoveNpcGreeting()
		end)
	end)
	task:start()
end

def.method(CNpc, "table", "table").StartNpcService = function(self, npc, options, params)
	--warn("--> StartNpcService", npc._ID, debug.traceback())
	self._CurServiceNPC = npc
    self._IsInNpcService = true
	
	CAutoFightMan.Instance():Pause(_G.PauseMask.NpcService)

	if self._ServNPCCheckTimer ~= 0 then
		_G.RemoveGlobalTimer(self._ServNPCCheckTimer)
		self._ServNPCCheckTimer = 0
	end
	self._ServNPCCheckTimer = _G.AddGlobalTimer(1, false, function ()
		if self._Host ~= nil then
			local hostX, hostZ = self._Host:GetPosXZ()
			local npcX, npcZ = npc:GetPosXZ()
			local distanceSqr = SqrDistanceH(hostX, hostZ, npcX, npcZ)
			if distanceSqr > max_npc_talk_dis_sqr then
				self:EndNPCService(nil)
			end
		end
	end)

	local dir = self._Host:GetPos() - npc:GetPos()
	-- 主角也朝向NPC
	self._Host:SetDir(-dir)

	if #options > 0 then
		CNPCServiceHdl.BeginServ(npc, options)
	else
		local function cb()
			game._GUIMan:Open("CPanelNpcService", nil)
		end

		npc:EnterService(cb)
	end
	--warn("StartNpcService End")
end

def.method("function").EndNPCService = function(self, cb)
    if self._IsInNpcService then
		CAutoFightMan.Instance():Restart(_G.PauseMask.NpcService)
		if self._SwitchAutoModeWhenEnd then
			CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
		end
	end
    ClearCurServerInfo(self, cb)
end

def.method().RemoveNpcGreeting = function (self)
	if self._OnNpcGreeting ~= nil then
		local PBHelper = require "Network.PBHelper"
		PBHelper.RemoveHandler("S2CNpcGreeting", self._OnNpcGreeting)
		self._OnNpcGreeting = nil
	end
end

def.method("table", "=>", "boolean").JudgeServiceOption = function (self, ServiceTemplate)
	local isLook = true
	-- 遍历是否符合前置条件 如果有一项不满足 则不通过
	if ServiceTemplate.ShowType == EServerShowType.ShowType_ProgressQuest then	
		if (not CQuest.Instance():IsQuestInProgress(tonumber(ServiceTemplate.ShowParam1))) and (not CQuest.Instance():IsQuestInProgressBySubID (tonumber(ServiceTemplate.ShowParam1))) then
			isLook = false
		end
	elseif ServiceTemplate.ShowType == EServerShowType.ShowType_FinishQuest then
		if not CQuest.Instance():IsQuestCompleted(tonumber(ServiceTemplate.ShowParam1)) then
			isLook = false
		end
	elseif ServiceTemplate.ShowType == EServerShowType.ShowType_Level then
		local Levels = string.split(ServiceTemplate.ShowParam1,'|')
        if Levels ~= nil then
			if ( Levels[1] ~= nil and tonumber(Levels[1]) > game._HostPlayer._InfoData._Level) or ( Levels[2] ~= nil and tonumber(Levels[2]) < game._HostPlayer._InfoData._Level ) then
				isLook = false
			end
        end

	elseif ServiceTemplate.ShowType == EServerShowType.ShowType_Guild then
		-- 如果使用的道具不等于配置的ID 不通过
		if not game._GuildMan:IsHostInGuild() then
			isLook = false
		end
	end 

	return isLook
end

def.method("table", "=>", "boolean").JudgeServiceOptionIsUse = function (self, ServiceTemplate)
	local isUse = true
	-- 如果有一项不满足 则不通过
	if ServiceTemplate.UseType == EServerUseType.UseType_Level then
		if ServiceTemplate.UserTypeParam1 > game._HostPlayer._InfoData._Level then
			isUse = false
		end
	elseif ServiceTemplate.UseType == EServerUseType.UseType_Guild then
		-- 如果使用的道具不等于配置的ID 不通过
		if not game._GuildMan:IsHostInGuild() then
			isUse = false
		end
	end 

	return isUse
end

def.method(CNpc, "table", "=>", "table").FilterServiceOptions = function (self, npc, params)
	local servOptions = {}
	local services = npc._NpcTemplate.Services
	if services == nil or #services <= 0 then return {} end
	local hp = self._Host
	for i, v in ipairs(services) do
		local service_id = v.Id
		local service = CElementData.GetServiceTemplate(service_id)

		local isLook = self:JudgeServiceOption(service)
		
		if not service.IsBattleUse and self._Host:IsInServerCombatState() then
			isLook = false
		end

		--是否满足可见的限制
		if isLook then
			local option = nil
			if service.Conversation._is_present_in_parent then
				if not service.Conversation.QuestUse or CQuest.Instance():IsMyConversationTarget(npc._NpcTemplate.Id) then
					local dialogue_template = CElementData.GetDialogueTemplate(service.Conversation.DialogueId)
					if dialogue_template ~= nil then
						local dialogue_name = IsNilOrEmptyString(dialogue_template.TextDisplayName) and dialogue_template.Name or dialogue_template.TextDisplayName
						option = 
						{
							service_id = service.Id, 
							service_name = dialogue_name,
							service_type = EnumDef.ServiceType.Conversation, 
							service_data = service.Conversation
						}
						if option ~= nil then
							servOptions[#servOptions + 1] = option
						end
					end
				end
			elseif service.ProvideQuest._is_present_in_parent then
				for _, quest in ipairs(service.ProvideQuest.Quests) do
					if CQuest.Instance():CanRecieveQuest(quest.Id) then	
						local quest_template = CElementData.GetQuestTemplate(quest.Id)
						local str_type = StringTable.Get(536+quest_template.Type)
						option = 
						{
							service_id = service.Id,
							service_name = str_type..quest_template.TextDisplayName,
							service_type = EnumDef.ServiceType.ProvideQuest, 
							service_data = quest
						}
						if option ~= nil then
							servOptions[#servOptions + 1] = option
						end
					end
				end
			elseif service.DeliverQuest._is_present_in_parent then
				for _, quest in ipairs(service.DeliverQuest.Quests) do
					if CQuest.Instance():CanDeliverQuest(quest.Id) then
						local quest_template = CElementData.GetQuestTemplate(quest.Id)
						local str_type = StringTable.Get(536+quest_template.Type)
						option = 
						{
							service_id = service.Id, 
							service_name = str_type..quest_template.TextDisplayName,
							service_type = EnumDef.ServiceType.DeliverQuest, 
							service_data = quest
						}
						if option ~= nil then
							servOptions[#servOptions + 1] = option
						end
					end
				end
			elseif service.CyclicQuest._is_present_in_parent then
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.CyclicQuest, 
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end
			elseif service.SellItem._is_present_in_parent then
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.SellItem, 
					service_data = service.SellItem.NpcShopId
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end
			elseif service.CreateGuild._is_present_in_parent then
				--当玩家没公会的时候才会显示这个创建功能(前置任务之类后边再考虑)
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if (not game._GuildMan:IsHostInGuild()) and hp._InfoData._Level > GuildOpenLevel then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.CreateGuild, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildList._is_present_in_parent then
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if (not game._GuildMan:IsHostInGuild()) and hp._InfoData._Level > GuildOpenLevel then

					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildList, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildInfo._is_present_in_parent then
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if game._GuildMan:IsHostInGuild() then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildInfo, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildWareHouse._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildWareHouse, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildSmithy._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildSmithy,
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildPray._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildPray, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildDungeon._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildDungeon, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildShop._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then				
					local param =
					{
						GuildShopId_1 = service.GuildShop.GuildShopId_1,
						GuildShopId_2 = service.GuildShop.GuildShopId_2
					}
					
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildShop,
						service_data = param
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildLaboratory._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
				
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildLaboratory, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildKnowItem._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
			
					option = 
					{
						service_id = service.Id, 
						service_name = service.TextDisplayName,
						service_type = EnumDef.ServiceType.GuildKnowItem, 
						service_data = service
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end

				end
			elseif service.GuildSubmitItem._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					local fortress = CElementData.GetTemplate("Fortress", service.GuildSubmitItem.FortressId)

					option = 
					{
						service_id = service.Id, 
						service_name = string.format(StringTable.Get(8002), fortress.Name),
						service_type = EnumDef.ServiceType.GuildSubmitItem, 
						service_data = fortress.Id
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.GuildApplyFortress._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
					local fortress = CElementData.GetTemplate("Fortress", service.GuildApplyFortress.FortressId)

					option = 
					{
						service_id = service.Id, 
						service_name = string.format(StringTable.Get(899), fortress.Name),
						service_type = EnumDef.ServiceType.GuildApplyFortress, 
						service_data = fortress
					}
					if option ~= nil then
						servOptions[#servOptions + 1] = option
					end
				end
			elseif service.Portal._is_present_in_parent then
				
				option = 
				{
					service_id = service.Id, 
					service_name = string.format(StringTable.Get(12007),service.Portal.PortalId),
					service_type = EnumDef.ServiceType.Transfer, 
					service_data = service.Portal.PortalId
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end
			elseif service.EnterDungeon._is_present_in_parent then	
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.EnterDungeon, 
					service_data = service.EnterDungeon.DungeonTID
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end	
			elseif service.NpcSale._is_present_in_parent then
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.NpcSale, 
					service_data = service.NpcSale.NpcSaleId
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end	
			elseif service.StoragePack ._is_present_in_parent then 
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.StoragePack, 
					service_data = 1 -- 默认值代表从NPC进入
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end	
			elseif service.QuestRandGroup ._is_present_in_parent then 
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.ServiceQuestRandGroup, 
					service_data = 1 -- 默认值代表从NPC进入
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end	
			elseif service.FrontLine ._is_present_in_parent then 
				option = 
				{
					service_id = service.Id, 
					service_name = service.TextDisplayName,
					service_type = EnumDef.ServiceType.FrontLine, 
					service_data = service.FrontLine.FrontLineId
				}
				if option ~= nil then
					servOptions[#servOptions + 1] = option
				end	
			end
		end
	end

	-- 如果有参数，表示特定目的，直接打开该服务项
	if params ~= nil then
		local option = nil
		for i,v in ipairs(servOptions) do
			if v.service_type == params[1] and params[1] == EnumDef.ServiceType.Conversation and v.service_data.DialogueId == params[2] then
				option = v  
				break
			elseif v.service_type == params[1] and (params[1] == EnumDef.ServiceType.ProvideQuest or params[1] == EnumDef.ServiceType.DeliverQuest) and v.service_data.Id == params[2] then
				option = v  
				break
			elseif v.service_type == params[1] and (params[1] == EnumDef.ServiceType.NpcSale) then
				option = v  
				option.ItemId = params[2]
				option.Count  = params[3]
				option.IsAuto  = params[4]
				break				
			end
		end
		
		if option ~= nil then
			return {option}
		else
			return {}
		end
	else
		return servOptions
	end
end

def.method(CNpc, "table", "=>", "boolean").HaveServiceOptions = function (self, npc, params)
	return self:HaveServiceOptionsByNPCTid(npc:GetTemplateId())
end

def.method("number", "=>", "boolean").HaveServiceOptionsByNPCTid = function (self, npcTid)
	local NPCTemplate = CElementData.GetNpcTemplate(npcTid)
	local services = NPCTemplate.Services
	if services == nil or #services <= 0 then return false end

	local hp = self._Host
	for i, v in ipairs(services) do
		local service_id = v.Id
		local service = CElementData.GetServiceTemplate(service_id)

		local isLook = self:JudgeServiceOption(service)

		if isLook then 
			local option = nil
			if service.Conversation._is_present_in_parent then
				if not service.Conversation.QuestUse or CQuest.Instance():IsMyConversationTarget(NPCTemplate.Id) then
					local dialogue_template = CElementData.GetDialogueTemplate(service.Conversation.DialogueId)
					if dialogue_template ~= nil then
						return true
					end
				end
			elseif service.ProvideQuest._is_present_in_parent then
				for _, quest in ipairs(service.ProvideQuest.Quests) do
					if CQuest.Instance():CanRecieveQuest(quest.Id) then
						return true
					end
				end
			elseif service.DeliverQuest._is_present_in_parent then
				for _, quest in ipairs(service.DeliverQuest.Quests) do
					if CQuest.Instance():CanDeliverQuest(quest.Id) then
						return true
					end
				end
			elseif service.CyclicQuest._is_present_in_parent then
				return true
			elseif service.SellItem._is_present_in_parent then
				return true
			elseif service.CreateGuild._is_present_in_parent then
				--当玩家没公会的时候才会显示这个创建功能(前置任务之类后边再考虑)
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if (not game._GuildMan:IsHostInGuild()) and hp._InfoData._Level > GuildOpenLevel then
						return true
				end
			elseif service.GuildList._is_present_in_parent then
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if (not game._GuildMan:IsHostInGuild()) and hp._InfoData._Level > GuildOpenLevel then
						return true
				end
			elseif service.GuildInfo._is_present_in_parent then
				if GuildOpenLevel == nil then
					GuildOpenLevel = tonumber(CElementData.GetSpecialIdTemplate(GuildOpenLevelId).Value)
				end
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildWareHouse._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildSmithy._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildPray._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildDungeon._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildShop._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then				
						return true
				end
			elseif service.GuildLaboratory._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildKnowItem._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildSubmitItem._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.GuildApplyFortress._is_present_in_parent then
				if game._GuildMan:IsHostInGuild() then
						return true
				end
			elseif service.Portal._is_present_in_parent then
						return true
			elseif service.NpcSale._is_present_in_parent then
						return true
			elseif service.StoragePack ._is_present_in_parent then
						return true
			elseif service.QuestRandGroup ._is_present_in_parent then
						return true
			elseif service.FrontLine ._is_present_in_parent then
						return true
			end
		end
	end
	return false
end

CHostOpHdl.Commit()
return CHostOpHdl