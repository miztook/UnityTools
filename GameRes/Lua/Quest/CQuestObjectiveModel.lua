local Lplus = require 'Lplus'
local CQuestObjectiveModel = Lplus.Class('CQuestObjectiveModel')
local CQuestNavigation = require "Quest.CQuestNavigation"
local CTransManage = require "Main.CTransManage"
local CElementData = require "Data.CElementData"
local MapBasicConfig = require "Data.MapBasicConfig" 
local QuestDef = require "Quest.QuestDef"
local CFxObject = require "Fx.CFxObject"
local CPanelStrong = require "GUI.CPanelStrong"

--local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CQuest = Lplus.ForwardDeclare("CQuest")
local OutputType = 
{
    Monster = 0,    --怪物产出
    Npc = 1,        --npc产出
    Mine = 2        --矿物产出
}

local def = CQuestObjectiveModel.define
local NAME_COUNT_ONCE = {"Conversation", "ArriveRegion", "FinishDungeon", "EnterDungeon", "ArriveLevel"}

def.field("number").Id = 0
def.field("table")._QuestModel = nil
def.field("number")._BelongQuestId = 0   --  此ID可能是普通任务Tid 也可能是子任务Tid，不能是父任务Tid 
def.field("number")._BelongParentQuestId = 0    -- 所属父任务Tid，如果是普通任务，那和_BelongQuestId相同

def.field("table")._Template = nil
def.field("table")._Current = nil
def.field("number")._RemainingTime = -1
def.field("number").CurrentRemainingTimeID = 0                       --当前的目标剩余时间ID
def.field(CFxObject)._GfxObject = nil    -- 为什么将表现放进逻辑类中呢？ 差评！！ -- added by lijian

def.static("=>",CQuestObjectiveModel).new = function()
    local obj = CQuestObjectiveModel()
    return obj
end

def.method("table", "number", "table", "number").Init = function(self, belong_quest_model, belong_quest_id, objective, belong_partent_quest_id)
    self._QuestModel = belong_quest_model
    self._BelongQuestId = belong_quest_id
    self._BelongParentQuestId = belong_partent_quest_id
    self._Template = objective
    self.Id = objective.Id
end

def.method("=>", "table").GetTemplate = function(self)
    return self._Template
end

def.method("=>", "table").GetCurrent = function(self)
    if not self._Current then
        if self._QuestModel then
            self._Current = self._QuestModel:GetCurrentObjetiveById(self.Id)
            if not self._Current then
                self._Current = {}
            end
        else
            self._Current = {Counter = 0}
        end
    end
    local temp = self:GetTemplate()
    if temp.HoldItem._is_present_in_parent then
        self._Current.Counter = game._HostPlayer._Package:GetItemCountFromNormalOrTaskPack(temp.HoldItem.ItemTId)
    elseif temp.ArriveLevel._is_present_in_parent then
        if game._HostPlayer._InfoData._Level >= temp.ArriveLevel.Level then
            self._Current.Counter = 1
        else
            self._Current.Counter = 0
        end
    end
    return self._Current
end

--获得剩余的时间
def.method("=>", "number").GetRemainingTime = function(self)
    local temp = self:GetTemplate()
    if temp.WaitTime._is_present_in_parent then
        local ServerTime = GameUtil.GetServerTime()/1000
        -- 剩余的时间 = 需要等待的时间 - （ 现在的时间 - 接任务的时间 ）
        self._RemainingTime = temp.WaitTime.Seconds - (ServerTime - self._QuestModel.ProvideTimestamp)
    end
    
    return self._RemainingTime
end


def.method("=>", "boolean").IsComplete = function(self)
    if self._QuestModel and self._QuestModel:GetTemplate().IsPartentQuest and self._QuestModel:IsSubQuestComplete(self._BelongQuestId) then
        return true
    end

    --判断是否是记时任务
    if self:GetTemplate().WaitTime._is_present_in_parent and self:GetRemainingTime() <= 0 then
        return true
    end

    return self:GetCurrentCount() >= self:GetNeedCount()
end

def.method("=>","string").GetDisplayText = function(self)
    local temp = self:GetTemplate()
    local str = ""
    if temp.Conversation._is_present_in_parent then
        str = temp.Conversation.TextNpcName
        --return temp.Conversation.TextNpcName
    elseif temp.KillMonster._is_present_in_parent then
        str = temp.KillMonster.TextMonsterName
        --return temp.KillMonster.TextMonsterName
    elseif temp.Gather._is_present_in_parent then
        str = temp.Gather.TextMineName
        --return temp.Gather.TextMineName
    elseif temp.ArriveRegion._is_present_in_parent then
        str = temp.ArriveRegion.TextOverlayDisplayName
        --return temp.ArriveRegion.TextOverlayDisplayName
    elseif temp.FinishDungeon._is_present_in_parent then
        str = temp.FinishDungeon.TextDungeonName
        --return temp.FinishDungeon.TextDungeonName
    elseif temp.EnterDungeon._is_present_in_parent then
        str = temp.EnterDungeon.TextDungeonName
        --return temp.EnterDungeon.TextDungeonName
    elseif temp.UseItem._is_present_in_parent then
        str = temp.UseItem.TextItemName
        --return temp.UseItem.TextItemName
    elseif temp.HoldItem._is_present_in_parent then
        str = temp.HoldItem.TextItemName
        --return temp.HoldItem.TextItemName
    elseif temp.ArriveLevel._is_present_in_parent then
        str = temp.ArriveLevel.TextDescrib 
        --return temp.ArriveLevel.TextDescrib 
        --return "到达等级（等模板）"
    elseif temp.WaitTime._is_present_in_parent then
        str = temp.WaitTime.TextOverlayDisplayName 
        --return temp.WaitTime.TextOverlayDisplayName 
    elseif temp.Convoy._is_present_in_parent then
        str = temp.Convoy.TextOverlayDisplayName 
    elseif temp.KillGenerator._is_present_in_parent then
        str = temp.KillGenerator.TextOverlayDisplayName 
    elseif temp.Guide._is_present_in_parent then
        str = temp.Guide.TextOverlayDisplayName 
    elseif temp.Achievement._is_present_in_parent then
        str = temp.Achievement.TextOverlayDisplayName 
    end
    if str == nil then
        str = ""
    end
    return str
end

def.method("number").SetCurrentCount = function(self, count)
    self:GetCurrent().Counter = count
end

def.method("=>", "number").GetCurrentCount = function(self)
    return self:GetCurrent().Counter or 0
end

def.method("=>", "boolean").IsCountOnce = function(self)
    local temp = self:GetTemplate()
    for k,v in pairs(NAME_COUNT_ONCE) do
        if temp[v]._is_present_in_parent then
            return true
        end
    end
    return false
end

def.method("=>", "number").GetWaitTime = function(self)
    local temp = self:GetTemplate()
    if temp.WaitTime._is_present_in_parent then
        return temp.WaitTime.Seconds
    end
    return 0
end

def.method("=>", "number").GetNeedCount = function(self)
    local requireCount = 0
    local temp = self:GetTemplate()
    if temp.Conversation._is_present_in_parent then
        if temp.Conversation.NpcId ~= 0 then
            requireCount = 1
        end
    elseif temp.ArriveRegion._is_present_in_parent then
        requireCount = 1
    elseif temp.ArriveLevel._is_present_in_parent then
        requireCount = 1
    elseif temp.WaitTime._is_present_in_parent then
        requireCount = 1
    elseif temp.FinishDungeon._is_present_in_parent then
        requireCount = 1
    elseif temp.EnterDungeon._is_present_in_parent then
        requireCount = 1
    elseif temp.KillMonster._is_present_in_parent then
        requireCount = temp.KillMonster.Count
    elseif temp.Gather._is_present_in_parent then
        requireCount = temp.Gather.Count
    elseif temp.UseItem._is_present_in_parent then
        requireCount = temp.UseItem.Count
    elseif temp.HoldItem._is_present_in_parent then
        requireCount = temp.HoldItem.Count
    elseif temp.Convoy._is_present_in_parent then
        requireCount = 1
    elseif temp.KillGenerator._is_present_in_parent then
        requireCount = temp.KillGenerator.Count
    elseif temp.Guide._is_present_in_parent then
        requireCount = temp.Guide.Count
    elseif temp.Achievement._is_present_in_parent then
        requireCount = 1
    end
    return requireCount
end

def.method("=>", "table").GetTextColor = function(self)
    return self:IsComplete() and EnumDef.QuestObjectiveColor.Finish or EnumDef.QuestObjectiveColor.InProgress
end

local function OnArriveNpcBuy(npc_tid, item_tid)
    local npc = game._CurWorld._NPCMan:GetByTid(npc_tid)
    if npc then
        game._HostPlayer._OpHdl:TalkToServerNpc(npc, nil)
    end
end

local function OnArriveNpcEnterDungeon(npc_tid)
    local npc = game._CurWorld._NPCMan:GetByTid(npc_tid)
    if npc then
        game._HostPlayer._OpHdl:TalkToServerNpc(npc, nil)
    end
end

def.method().DoShortcut = function(self)
    local temp = self:GetTemplate()

    if temp.Conversation._is_present_in_parent then
        if temp.Conversation.NpcId > 0 then
            CQuestNavigation.Instance():NavigatToNpc(temp.Conversation.NpcId, {EnumDef.ServiceType.Conversation, temp.Conversation.DialogueId})
        end
    elseif temp.ArriveRegion._is_present_in_parent then
        CTransManage.Instance():TransToRegionIsNeedBroken(temp.ArriveRegion.MapId,temp.ArriveRegion.RegionId,true,nil, true)
    elseif temp.ArriveLevel._is_present_in_parent then
        -- game._GUIMan:ShowTipText(StringTable.Get(31804), false)
        game._GUIMan:Open("CPanelStrong",{ PageType = CPanelStrong.PageType.GETEXP})
    elseif temp.WaitTime._is_present_in_parent then

    elseif temp.FinishDungeon._is_present_in_parent then
        local data = temp.FinishDungeon.DungeonTId
        --副本类型的开副本界面
        local EWorldType = require "PB.Template".Map.EWorldType
        if MapBasicConfig.GetMapType(data) == EWorldType.Instance then
            if CSpecialIdMan.Get("ArenaSceneOne") == data then
                local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(data)
                if not isOpen then 
                    game._GUIMan:ShowTipText(StringTable.Get(30109), false)
                return end
                game._CArenaMan:SendC2SOpenOne() 
            elseif CSpecialIdMan.Get("ArenaScene3V3") == data then
                local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(data)
                if not isOpen then 
                    game._GUIMan:ShowTipText(StringTable.Get(30109), false)
                return end
                game._CArenaMan:SendC2SOpenThree() 
            else
                local EInstanceType = require "PB.Template".Instance.EInstanceType
                local template = CElementData.GetInstanceTemplate(data)
                local iType = template.InstanceType
                if iType == EInstanceType.INSTANCE_EXPEDITION then
                    game._GUIMan:Open("CPanelUIExpedition", {DungeonID = data})
                elseif iType == EInstanceType.INSTANCE_GUILDEXPEDITION then
                    game._GuildMan:OpenGuildDungeon()
                else
                    game._GUIMan:Open("CPanelUIDungeon", data)
                end
            end
            
        --相位类型。做寻路
        elseif MapBasicConfig.GetMapType(data) == EWorldType.Pharse then
            local regeionTId, sceneTid = MapBasicConfig.GetLinkRegionID(data)
            if regeionTId <= 0 or sceneTid <= 0 then
                warn("FinishDungeon 错误,Mapid:"..data.."没有联通数据")
            else
                local pos = MapBasicConfig.GetRegionPos(sceneTid,regeionTId)
                if pos == nil then 
                    warn("MapBasicConfig错误，区域："..regeionTId.."不存在！！","tip", 3)
                    --self._EnterRegionData = nil
                    return end
                CTransManage.Instance():StartMoveByMapIDAndPos(data, pos, nil, false, false)
            end
        elseif MapBasicConfig.GetMapType(data) == EWorldType.Immediate then
            CTransManage.Instance():TransToInstance(data, nil, nil, false)
        --其他类型如果寻路ID > 0则执行寻路ID寻路
        else 
            if  temp.FinishDungeon.PathID > 0 then
                if temp.FinishDungeon.PathType == OutputType.Monster then
		          CQuestNavigation.Instance():NavigatToMonster(temp.FinishDungeon.PathID, self._BelongParentQuestId)
                elseif temp.FinishDungeon.PathType == OutputType.Npc then
		          CQuestNavigation.Instance():NavigatToNpc(temp.FinishDungeon.PathID, nil)
                elseif temp.FinishDungeon.PathType == OutputType.Mine then
		          CQuestNavigation.Instance():NavigatToMine(temp.FinishDungeon.PathID, self)
                end
            end
        end       
    elseif temp.EnterDungeon._is_present_in_parent then
        local data = temp.EnterDungeon.DungeonTId
        --副本类型的开副本界面
        local EWorldType = require "PB.Template".Map.EWorldType
        if MapBasicConfig.GetMapType(data) == EWorldType.Instance then
            if CSpecialIdMan.Get("ArenaSceneOne") == data then
                local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(data)
                if not isOpen then 
                    game._GUIMan:ShowTipText(StringTable.Get(30109), false)
                return end
                game._CArenaMan:SendC2SOpenOne() 
            elseif CSpecialIdMan.Get("ArenaScene3V3") == data then
                local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(data)
                if not isOpen then 
                    game._GUIMan:ShowTipText(StringTable.Get(30109), false)
                return end
                game._CArenaMan:SendC2SOpenThree() 
            else
                local EInstanceType = require "PB.Template".Instance.EInstanceType
                local template = CElementData.GetInstanceTemplate(data)
                local iType = template.InstanceType
                if iType == EInstanceType.INSTANCE_EXPEDITION then
                    game._GUIMan:Open("CPanelUIExpedition", {DungeonID = data})
                elseif iType == EInstanceType.INSTANCE_GUILDEXPEDITION then
                    game._GuildMan:OpenGuildDungeon()
                else
                    game._GUIMan:Open("CPanelUIDungeon", data)
                end
            end
            
        --相位类型。做寻路
        elseif MapBasicConfig.GetMapType(data) == EWorldType.Pharse then
            local regeionTId, sceneTid = MapBasicConfig.GetLinkRegionID(data)
            if regeionTId <= 0 or sceneTid <= 0 then
                warn("EnterDungeon 错误,Mapid:"..data.."没有联通数据")
            else
                local pos = MapBasicConfig.GetRegionPos(sceneTid,regeionTId)
                if pos == nil then 
                    warn("MapBasicConfig错误，区域："..regeionTId.."不存在！！","tip", 3)
                    --self._EnterRegionData = nil
                    return end
                CTransManage.Instance():StartMoveByMapIDAndPos(data, pos, nil, false, false)
            end
        elseif MapBasicConfig.GetMapType(data) == EWorldType.Immediate then
            CTransManage.Instance():TransToInstance(data, nil, nil, false)
        --其他类型如果寻路ID > 0则执行寻路ID寻路
        else 
            if  temp.EnterDungeon.PathID > 0 then
                if temp.EnterDungeon.PathType == OutputType.Monster then
                      CQuestNavigation.Instance():NavigatToMonster(temp.EnterDungeon.PathID, self._BelongParentQuestId)
                elseif temp.EnterDungeon.PathType == OutputType.Npc then
                      CQuestNavigation.Instance():NavigatToNpc(temp.EnterDungeon.PathID, nil)
                elseif temp.EnterDungeon.PathType == OutputType.Mine then
                      CQuestNavigation.Instance():NavigatToMine(temp.EnterDungeon.PathID, self)
                end
            else
                local data = temp.EnterDungeon.DungeonTId
                game._GUIMan:Open("CPanelUIDungeon", data)
            end
        end  
    elseif temp.KillMonster._is_present_in_parent then
        CQuestNavigation.Instance():NavigatToMonster(temp.KillMonster.MonsterId, self._BelongParentQuestId)
    elseif temp.Gather._is_present_in_parent then
        CQuestNavigation.Instance():NavigatToMine(temp.Gather.MineId, self)
    elseif temp.UseItem._is_present_in_parent then
        local item = game._HostPlayer._Package:GetItemFromNormalOrTaskPack(temp.UseItem.ItemTId)
        if item ~= nil then
            if item:CanUse() == EnumDef.ItemUseReason.Success then
                item:Use()
            else
                game._GUIMan:ShowTipText(StringTable.Get(521), false)
            end
        else
            if temp.UseItem.PathType == OutputType.Monster then
                CQuestNavigation.Instance():NavigatToMonster(temp.UseItem.PathID, self._BelongParentQuestId)
            elseif temp.UseItem.PathType == OutputType.Npc then
                CQuestNavigation.Instance():NavigatToNpc(temp.UseItem.PathID, nil)
            elseif temp.UseItem.PathType == OutputType.Mine then
                CQuestNavigation.Instance():NavigatToMine(temp.UseItem.PathID, self)
            end
        end
    elseif temp.HoldItem._is_present_in_parent then
        if temp.HoldItem.PathType == OutputType.Monster then     
            CQuestNavigation.Instance():NavigatToMonster(temp.HoldItem.PathID, self._BelongParentQuestId)
        elseif temp.HoldItem.PathType == OutputType.Npc then 
            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            local isAuto = CQuestAutoMan.Instance():IsOn()
            CQuestNavigation.Instance():NavigatToNpc(temp.HoldItem.PathID, {EnumDef.ServiceType.NpcSale, temp.HoldItem.ItemTId, temp.HoldItem.Count, isAuto})
        elseif temp.HoldItem.PathType == OutputType.Mine then 
            CQuestNavigation.Instance():NavigatToMine(temp.HoldItem.PathID, self)
        end
    elseif temp.Convoy._is_present_in_parent then
        if self._QuestModel:GetTemplate().Type == QuestDef.QuestType.GuildConvoy then
            local convoyPos = game._GuildMan:GetConvoyEntityPos()
            game:NavigatToPos(convoyPos, 0, nil, nil)
        else
            CQuest.Instance():QuestFollow(true,self._BelongParentQuestId)
        end
    elseif temp.KillGenerator._is_present_in_parent then
        CQuestNavigation.Instance():NavigatToMonsterGenerator(temp.KillGenerator.MapTId,temp.KillGenerator.GenerateID,self._BelongParentQuestId)
    elseif temp.Guide._is_present_in_parent then
        if temp.Guide.UIOpenId ~= 0 then
            game._AcheivementMan:DrumpToRightPanel(temp.Guide.UIOpenId,0)
        end
    elseif temp.Achievement._is_present_in_parent then
        if temp.Achievement.UIOpenId ~= 0 then
            game._AcheivementMan:DrumpToRightPanel(temp.Achievement.UIOpenId,0)
        end
    end
end

--赫男专用 找任务怪物目标ID
def.method("=>","table").GetQuestTargetMonsters = function(self)
    local temp = self:GetTemplate()

    if temp.KillMonster._is_present_in_parent then
        return {temp.KillMonster.MonsterId}
    elseif temp.KillGenerator._is_present_in_parent then
        local tids = MapBasicConfig.GetGeneratorTargetMonsters(temp.KillGenerator.MapTId, temp.KillGenerator.GenerateID)
        local Targets = {}
        for k,v in pairs(tids) do
            Targets[#Targets+1] = k
        end
        return Targets
    elseif temp.HoldItem._is_present_in_parent then
        if temp.HoldItem.PathType == OutputType.Monster then     
            return {temp.HoldItem.PathID}
        end
    end
    return nil
end
def.method("=>","number","table").GetShortcutWorldIDAndPos = function(self)
    local sceneID,targetPos = -1,nil
    --"Npc","Monster","Mine","Region"
    local key = nil
    local TargetTId = nil

    local temp = self:GetTemplate()
    if temp.Conversation._is_present_in_parent then
        if temp.Conversation.NpcId > 0 then
            key = "Npc"
            TargetTId = temp.Conversation.NpcId
        end
    elseif temp.ArriveRegion._is_present_in_parent then
            key = "Region"
            sceneID = temp.ArriveRegion.MapId
            TargetTId = temp.ArriveRegion.RegionId
    elseif temp.ArriveLevel._is_present_in_parent then
    elseif temp.WaitTime._is_present_in_parent then
    elseif temp.FinishDungeon._is_present_in_parent then
        if  temp.FinishDungeon.PathID > 0 then
            if temp.FinishDungeon.PathType == OutputType.Monster then
                key = "Monster"
                TargetTId = temp.FinishDungeon.PathID
            elseif temp.FinishDungeon.PathType == OutputType.Npc then
                key = "Npc"
                TargetTId = temp.FinishDungeon.PathID
            elseif temp.FinishDungeon.PathType == OutputType.Mine then
                key = "Mine"
                TargetTId = temp.FinishDungeon.PathID
            end
        end
    elseif temp.EnterDungeon._is_present_in_parent then
        if  temp.EnterDungeon.PathID > 0 then
            if temp.EnterDungeon.PathType == OutputType.Monster then
                key = "Monster"
                TargetTId = temp.EnterDungeon.PathID
            elseif temp.EnterDungeon.PathType == OutputType.Npc then
                key = "Npc"
                TargetTId = temp.EnterDungeon.PathID
            elseif temp.EnterDungeon.PathType == OutputType.Mine then
                key = "Mine"
                TargetTId = temp.EnterDungeon.PathID
            end
        else

        end
    elseif temp.KillMonster._is_present_in_parent then
        key = "Monster"
        TargetTId = temp.KillMonster.MonsterId
    elseif temp.Gather._is_present_in_parent then
        key = "Mine"
        TargetTId = temp.Gather.MineId
    elseif temp.UseItem._is_present_in_parent then
        local drug = game._HostPlayer._Package:GetItemFromNormalOrTaskPack(temp.UseItem.ItemTId)

        if drug ~= nil then
            key = "Region"
            sceneID = drug._Template.UseMapId
            TargetTId = drug._Template.UseRegionId

            -- 同彭仲天确认，UseRegionId == 0是有效值，表示当前地图都可以用
            if TargetTId == 0 then
                return sceneID, nil
            end
        else
            if temp.UseItem.PathType == OutputType.Monster then
                key = "Monster"
                TargetTId = temp.UseItem.PathID
            elseif temp.UseItem.PathType == OutputType.Npc then
                key = "Npc"
                TargetTId = temp.UseItem.PathID
            elseif temp.UseItem.PathType == OutputType.Mine then
                key = "Mine"
                TargetTId = temp.UseItem.PathID
            end
        end
    elseif temp.HoldItem._is_present_in_parent then
        if temp.HoldItem.PathType == OutputType.Monster then     
            key = "Monster"
            TargetTId = temp.HoldItem.PathID
        elseif temp.HoldItem.PathType == OutputType.Npc then 
            key = "Npc"
            TargetTId = temp.HoldItem.PathID
        elseif temp.HoldItem.PathType == OutputType.Mine then 
            key = "Mine"
            TargetTId = temp.HoldItem.PathID
        end
    end

    if key ~= nil and TargetTId ~= nil then
        if key == "Region" then
            targetPos = MapBasicConfig.GetRegionPos(sceneID,TargetTId)
        else
            sceneID,targetPos = MapBasicConfig.GetDestParams(key, TargetTId, {})
        end
    end
    return sceneID,targetPos
end

def.method("number", "=>", "boolean").IsConversationTarget = function(self, id)
    local temp = self:GetTemplate()
    return temp.Conversation._is_present_in_parent and temp.Conversation.DialogueId == id  
end

def.method("number", "=>", "boolean").IsGatherTarget = function(self, id)
    local temp = self:GetTemplate()
    return temp.Gather._is_present_in_parent and temp.Gather.MineId == id
end

def.method("=>", "number").GetTargetMonsterId = function(self)
    local temp = self:GetTemplate()
    if temp ~= nil and temp.KillMonster._is_present_in_parent then
        return temp.KillMonster.MonsterId
    end
    return -1
end

--判断需要的产出物品个数是否满足需求
local function IsItemSatisfy(temp, toutput, tid)
    local param = nil
    if temp.UseItem._is_present_in_parent then
        param = temp.UseItem
    elseif temp.HoldItem._is_present_in_parent then
        param = temp.HoldItem
    end
    if param then
        local pack = game._HostPlayer._Package._TaskItemPack
        local item = pack:GetItem(param.ItemTId)
        if not item then
            return param.PathType == toutput and param.PathID == tid and pack:GetItemCount(param.ItemTId) < param.Count 
        end
    end
    return false
end

--判断此区域是否满足需求
local function IsRegionSatisfy(temp, tid)
    local param = nil
    if temp.ArriveRegion._is_present_in_parent then
        param = temp.ArriveRegion
    end
    if param then
        return game._CurWorld._WorldInfo.MapTid == param.MapId and tid == param.RegionId
    end
    return false
end

--判断此区域是否满足需求
def.method("table", "=>", "boolean").IsWaitTimeSatisfy = function(self, temp)
    local param = nil
    if temp.WaitTime._is_present_in_parent then
        param = temp.WaitTime
    end
    if param then
        local ServerTime = GameUtil.GetServerTime()/1000
        return param.Seconds < ServerTime - self._QuestModel.CurrentQuests.ProvideTimestamp
    end
    return false

    --倒计时 = 目标等待时间 - （就用当前时间 - 任务接取时间）
end

local FieldNames = {"Conversation","KillMonster","Gather","ArriveRegion","FinishDungeon","EnterDungeon","UseItem","HoldItem","WaitTime"}
local FieldIds = {"NpcId","MonsterId","MineId","RegionId","DungeonTId","DungeonTId","ItemTId","ItemTId","Seconds"}
def.method("number", "number", "=>", "boolean").IsQuestTarget = function(self, objective_type, target_id)
    local temp = self:GetTemplate()

    --此处为特殊处理，只判断npc有没有当前目标的购买服务
    if objective_type == QuestDef.ObjectiveType.Buy then
        return IsItemSatisfy(temp, OutputType.Npc, target_id)
    end

    local target_field_name = FieldNames[objective_type] or ""
    local target_field_id = FieldIds[objective_type] or ""
    local data = temp[target_field_name]
    local rst = false
    if data then
         rst = data[target_field_id] == target_id
        if not rst then
            local toutput = -1
            if objective_type == QuestDef.ObjectiveType.Conversation then
                toutput = OutputType.Npc
                rst = IsItemSatisfy(temp, toutput, target_id)
            elseif objective_type == QuestDef.ObjectiveType.KillMonster then
                toutput = OutputType.Monster
                rst = IsItemSatisfy(temp, toutput, target_id)
            elseif objective_type == QuestDef.ObjectiveType.Gather then
                toutput = OutputType.Mine
                rst = IsItemSatisfy(temp, toutput, target_id)
            elseif objective_type == QuestDef.ObjectiveType.ArriveRegion then
                rst = IsRegionSatisfy(temp, target_id)  
            elseif objective_type == QuestDef.ObjectiveType.WaitTime then
                rst = self:IsWaitTimeSatisfy(temp)  
            end
            
        end
    end
    return rst
end

def.method("number").ChangeRegionTip = function(self,regionID)
    --如果目前的世界是 指示的世界
    if self:GetTemplate().ArriveRegion.MapId == game._CurWorld._WorldInfo.MapTid then
        --如果目前的区域是 指示的区域
        if  regionID == self:GetTemplate().ArriveRegion.RegionId then
            --print("到达区域，隐藏指示特效",regionID)
            CFxMan.Instance():Stop( self._GfxObject )
            self._GfxObject = nil
        else   
            --warn("显示此区域的位置做指示特效",regionID, game._CurWorld._IsReady)      
            if game:IsWorldReady() then                       
                --获得此区域的位置
                if self._GfxObject == nil then
                    local pos = require "Data.MapBasicConfig".GetRegionPos(self:GetTemplate().ArriveRegion.MapId,self:GetTemplate().ArriveRegion.RegionId)
                    if pos ~= nil then
                        pos.y = GameUtil.GetMapHeight(Vector3.New(pos.x,0,pos.z))
                        self._GfxObject = CFxMan.Instance():Play(PATH.Etc_Mubiaodidianbiaoji, pos, Quaternion.identity, -1, -1, EnumDef.CFxPriority.Always)
                    end
                end
            end
        end
    else
        --print("不在此地图中隐藏指示特效",regionID)
        CFxMan.Instance():Stop( self._GfxObject )
        self._GfxObject = nil
    end
end

def.method().ObjectiveModelEffectClose = function(self)
    if self._GfxObject ~= nil then
        CFxMan.Instance():Stop( self._GfxObject )
        self._GfxObject = nil
    end
end

CQuestObjectiveModel.Commit()
return CQuestObjectiveModel