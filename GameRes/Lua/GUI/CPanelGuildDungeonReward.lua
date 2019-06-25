local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelGuildDungeonReward = Lplus.Extend(CPanelBase, "CPanelGuildDungeonReward")
local def = CPanelGuildDungeonReward.define

def.field("table")._RewardTable = nil
def.field("userdata")._List_Reward = nil

local instance = nil
def.static("=>", CPanelGuildDungeonReward).Instance = function()
	if not instance then
		instance = CPanelGuildDungeonReward()
		instance._PrefabPath = PATH.UI_Guild_Dungeon_Reward
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
    self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
    local reward_id = tonumber(data)
    self._RewardTable = {}
    if reward_id ~= nil then
        self._RewardTable = GUITools.GetDropLibraryItemList(reward_id)
    end
    self._List_Reward:SetItemCount(#self._RewardTable)
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local index = index + 1
    local data = self._RewardTable[index]
	local setting =
	{
		[EItemIconTag.Number] = data.MinNum,
	}
	IconTools.InitItemIconNew(item, data.ItemId, setting)
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local index = index + 1
    local data = self._RewardTable[index]
    CItemTipMan.ShowItemTips(data.ItemId, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

CPanelGuildDungeonReward.Commit()
return CPanelGuildDungeonReward