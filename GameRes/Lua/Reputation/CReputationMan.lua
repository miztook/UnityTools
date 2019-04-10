--[[----------------------------------------------
         		 声望管理器
--------------------------------------------------]]
local Lplus = require "Lplus"
local CReputationMan = Lplus.Class("CReputationMan")
local def = CReputationMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local QuestDef = require "Quest.QuestDef"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CPanelUIManual = require "GUI.CPanelUIManual"
def.field("table")._Reputations = BlankTable
def.field("table")._ReputationsTIDs = nil
def.field("number")._QuestFinishCount = 0
def.field("number")._RepShopSpecialID = 319     --声望商店特殊id

def.static("=>", CReputationMan).new = function()
    local obj = CReputationMan()
	return obj
end


--获取所有成就
def.method("=>","table").GetAllReputation = function(self)
	return self._Reputations
end

def.method("=>","table").GetAllReputationTIDs = function(self)
	if self._ReputationsTIDs == nil then
		self._ReputationsTIDs = {}
        local data_id_list = CElementData.GetAllReputation()
        for i = 1, #data_id_list do 
        	local template = CElementData.GetTemplate("Reputation", data_id_list[i])
        	if template.HasReputation then
        		self._ReputationsTIDs[#self._ReputationsTIDs+1] = data_id_list[i]
        	end	
        end        
	end
	return self._ReputationsTIDs
end

def.method("number","=>", "table").GetAllShopItemsByReputationID = function(self, repID)
    local goods = {}
    local shopID = tonumber(CElementData.GetSpecialIdTemplate(self._RepShopSpecialID).Value) or 9
    local shopItem = CElementData.GetTemplate("NpcSale", shopID)
    if shopItem ~= nil then
        for i,v in ipairs(shopItem.NpcSaleSubs) do
            if v.NpcSaleItems then
                for i1,v1 in ipairs(v.NpcSaleItems) do
                    if v1.IsShowInRep and v1.ReputationType == repID and self:CanUseItem(v1.ItemId) then
                        goods[#goods + 1] = v1
                    end
                end
            end
        end
    end
    return goods
end

def.method("number","=>","boolean").CanUseItem = function (self,itemId)
	local itemTemp = CElementData.GetItemTemplate(itemId)
    local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
    if profMask ~= bit.band(itemTemp.ProfessionLimitMask, profMask) then 
		return false
	end	
    return true
end

local function OnQuestEvents(sender, event)
	local name = event._Name
	local data = event._Data
	if name == EnumDef.QuestEventNames.QUEST_RECIEVE then		--接任务

		-- local quest_template = CElementData.GetQuestTemplate(data.Id)
		-- if quest_template.Type == QuestDef.QuestType.Reputation then
		-- 	local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
		-- 	if Map ~= nil and Map[4] ~= nil then
		-- 		for k,v in pairs(Map[4]) do
		--         	if quest_template.ProvideRelated.ReputationLimit.ReputationId == k then
		-- 		        if Map[4][k] ~= nil then
		-- 		            Map[4][k] = nil
		-- 		        end
		-- 		        break
		-- 		    end
	 --            end

	 --            CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
	 --            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
	 --            --CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,isShow)
		-- 	end
		-- end
	end
end
--------------------------S2C-----------------------------

--改变声望数据
def.method("table").OnS2CReputationChange = function(self, data)
	if data == nil then return end
	local index = -1
	if self._Reputations[data.ReputationID] ~= nil then
		index = self._Reputations[data.ReputationID].Index
	end
	if index == -1 then
		index = 1
		for k,v in pairs(self._Reputations) do
			index = index + 1
		end
	end
	self._Reputations[data.ReputationID] = 
	{
		Level = data.Level,
		Exp = data.Exp,
		Index = index
	}

	-- if CQuest.Instance():HaveReputationQuest(data.ReputationID) then
	-- 	-- 保存红点显示状态
	-- 	local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
	-- 	if Map == nil then
	-- 		Map = {}
	-- 	end
	-- 	if Map[4] == nil then
	-- 		Map[4] = {}
	-- 	end
	-- 	Map[4][data.ReputationID] = true
	-- 	--print("====================================",data.ReputationID)
	-- 	CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
	-- 	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,true)
	-- end
end

--初始化声望数据
def.method("table").OnS2CReputationView = function(self, data)	
	if data == nil then return end

	self._Reputations = {}
	print("OnS2CReputationView")
	-- 保存红点显示状态
	-- local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
	-- if Map == nil then
	-- 	Map = {}
	-- end
	-- Map[4] = nil
	-- Map[4] = {}


	for i,v in pairs(data.ReputationInfos) do
		if v and v.ReputationID and v.ReputationID > 0 then
			self._Reputations[v.ReputationID] = 
			{
				Level = v.Level,
				Exp = v.Exp,
				Index = i
			}
			-- print("OnS2CReputationView",i,v.ReputationID)
			-- if CQuest.Instance():HaveReputationQuest(v.ReputationID) then

			-- 	Map[4][v.ReputationID] = true
			-- 	print("====================================",v.ReputationID)
			-- 	CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
			-- 	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,true)
			-- end
		end
	end
	self._QuestFinishCount = data.QuestFinishCount
	CGame.EventManager:addHandler('QuestCommonEvent', OnQuestEvents)
end

def.method().Release = function(self)	
	CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestEvents)
end

CReputationMan.Commit()
return CReputationMan