-- 副本噩梦遗迹页
-- 时间：2017/9/8
-- Add by Yao

local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local EInstanceType = require "PB.Template".Instance.EInstanceType
local EInstanceOpenType = require "PB.Template".Instance.EInstanceOpenType
local PBHelper = require "Network.PBHelper"

local CPageNightmareDungeon = Lplus.Class("CPageNightmareDungeon")
local def = CPageNightmareDungeon.define

def.field("table")._Panel = nil
def.field("boolean")._PageInited = false -- 面板是否已初始化
-- 界面
def.field("table")._UITemplateMap = BlankTable -- 列表所有的UITemplate组件
-- 数据
def.field('number')._SelectedInstance = -1 -- 当前选中副本下标Index,-1为非法值
def.field('table')._M_DungeonTemplates = BlankTable -- 所有噩梦遗迹的模版ID
def.field("table")._SfxTimerIdMap = BlankTable
-- 通用
def.field("table")._RewardsData = BlankTable -- 奖励数据

def.static("table", "=>", CPageNightmareDungeon).new = function(panel_script)
	local obj = CPageNightmareDungeon()
	obj._Panel = panel_script
	return obj
end

def.method().Init = function (self)
    local allDungeonTid = game._DungeonMan:GetAllDungeonInfo()
    for _, v in ipairs(allDungeonTid) do
        local template = CElementData.GetInstanceTemplate(v)
        if template ~= nil then
            if template.InstanceType == EInstanceType.INSTANCE_RUINS_NIGHTMARE then
                -- 噩梦遗迹类型
                self._M_DungeonTemplates[#self._M_DungeonTemplates+1] = template
            end
        end
    end
    table.sort(self._M_DungeonTemplates, function (a, b)
        -- 按Id从小到大
        return a.Id < b.Id
    end)
end

---------------------------------以下方法不能删除-----------------------------
def.method("dynamic").Show = function(self, data)
    if not self._PageInited then
        -- 第一次打开，初始化
        self:Init()
        self._PageInited = true
    end
    if next(self._M_DungeonTemplates) == nil then
        warn("噩梦遗迹的模版数据为空")
        return
    end
    local selectedIndex = -1
    if type(data) == "number" then
        -- 指定副本，若不属于遗迹噩梦，则选择默认
        for i, v in ipairs(self._M_DungeonTemplates) do
            if v.Id == data then
                self._SelectedInstance = v.Id
                selectedIndex = i
                break
            end
        end
    end
    if self._SelectedInstance == -1 then
        selectedIndex = 1
        -- 默认打开已解锁中Id最大的
        for i = #self._M_DungeonTemplates, 1, -1 do
            local id = self._M_DungeonTemplates[i].Id
            local data = game._DungeonMan:GetDungeonData(id)
            if data ~= nil and data.IsOpen then
                selectedIndex = i
                break
            end
        end
        self._SelectedInstance = self._M_DungeonTemplates[selectedIndex].Id
    end

    self._Panel:SetRuinList(#self._M_DungeonTemplates, selectedIndex - 1)
    self:UpdateDungeonInfo(self._SelectedInstance)
end

def.method("userdata", "string", "number").OnPanelInitItem = function(self, item, id, index)
    if string.find(id, "List_Dungeon") then
        -- 左列表
        local template = self._M_DungeonTemplates[index+1]
        if template ~= nil then
            local uiTemplate = item:GetComponent(ClassType.UITemplate)
            local dungeonData = game._DungeonMan:GetDungeonData(template.Id)
            if uiTemplate ~= nil and dungeonData ~= nil then
                -- 副本图标
                local img_icon = uiTemplate:GetControl(0)
                if template.IconPath ~= "" then
                    -- 模版里配置的是背景图片路径，需要做规则转换才能得到图标路径
                    local path = string.gsub(template.IconPath, "Bg", "Btn03")
                    GUITools.SetSprite(img_icon, path)
                end
                GameUtil.MakeImageGray(img_icon, not dungeonData.IsOpen)
                -- 副本名称
                local lab_name = uiTemplate:GetControl(5)
                GUI.SetText(lab_name, template.TextDisplayName)
                -- 副本描述
                local lab_des = uiTemplate:GetControl(6)
                GUI.SetText(lab_des, template.Introduction)
                local bPlayFx = game._DungeonMan:IsUIFxNeedToPlay(template.Id)
                if bPlayFx then
                    -- 需要播放解锁特效
                    self:PlayUnlockSfx(uiTemplate)
                else
                    local frame_lock = uiTemplate:GetControl(1)
                    frame_lock:SetActive(not dungeonData.IsOpen)
                    if not dungeonData.IsOpen then
                        -- 是否解锁
                        local lab_lock = uiTemplate:GetControl(4)
                        if template.OpenType == EInstanceOpenType.ELevel then
                            -- 等级解锁
                            GUI.SetText(lab_lock, string.format(StringTable.Get(137), template.MinEnterLevel))
                        elseif template.OpenType == EInstanceOpenType.EDiffcultyFinish then
                            -- 难度解锁
                            GUI.SetText(lab_lock, StringTable.Get(913))
                        end
                    end
                end
                self._UITemplateMap[template.Id] = uiTemplate
            end
        end
    end
end

def.method("userdata", "string", "number").OnPanelSelectItem = function(self, item, id, index)
    if string.find(id, "List_Dungeon") then
        local template = self._M_DungeonTemplates[index+1]
        if template ~= nil then
            self._Panel:SetRuinListSelection(index)

            self._SelectedInstance = template.Id
            self:UpdateDungeonInfo(self._SelectedInstance)
        end
    end
end

def.method("string").OnPanelClick = function (self, id)
end

def.method("=>", "number").GetCurDungeonId = function (self)
    return self._SelectedInstance
end

def.method("=>", "table").GetDungeonRewardData = function (self)
    return self._RewardsData
end

def.method("number").UpdateLockStatus = function (self, unlockTid)
    local uiTemplate = self._UITemplateMap[unlockTid]
    self:PlayUnlockSfx(uiTemplate)
    game._DungeonMan:SaveUIFxStatusToUserData(unlockTid, false)
end

def.method().Hide = function(self)
    self._RewardsData = {}
end

def.method().Destroy = function (self)
    for _, timerId in pairs(self._SfxTimerIdMap) do
        _G.RemoveGlobalTimer(timerId)
    end

    self._Panel = nil
    self._PageInited = false
    self._SelectedInstance = -1
    self._M_DungeonTemplates = {}
    self._UITemplateMap = {}
	self:Hide()
end
------------------------------------------------------------------------------
-- 更新奖励列表
def.method("number").UpdateDungeonInfo = function (self, id)
	local instanceTemp = CElementData.GetInstanceTemplate(id)
	if instanceTemp == nil then
        warn("Instance template get nil on page NightmareDungeon, wrong tid:" .. id)
		return
	end
    self._Panel:ShowDungeonInfo(id)
    if instanceTemp.RewardId <= 0 then
        warn("Reward template get nil on page NightmareDungeon, wrong tid:" .. instanceTemp.RewardId)
    else
        local rewardList = GUITools.GetRewardList(instanceTemp.RewardId, true)
        local moneyRewardList = {}
        self._RewardsData = {}
        for _, v in ipairs(rewardList) do
            if v.IsTokenMoney then
                table.insert(moneyRewardList, v.Data)
            else
                table.insert(self._RewardsData, v)
            end
        end
        self._Panel:SetMoneyRewards(moneyRewardList) -- 设置货币奖励
        self._Panel:SetRewardsList(self._RewardsData) -- 设置物品列表奖励
    end
end

-- 播放解锁特效
def.method("userdata").PlayUnlockSfx = function (self, uiTemplate)
    if uiTemplate == nil then return end

    local frame_lock = uiTemplate:GetControl(1)
    local frame_sfx = uiTemplate:GetControl(7)
    --[[ 暂时屏蔽
    local function OnLoad ()
        -- 特效加载完毕
        local timerId = 0
        timerId = _G.AddGlobalTimer(self._Panel._UISfxDuration, true, function ()
            -- 特效播放结束后
            GUITools.SetUIActive(frame_lock, false)
            self._SfxTimerIdMap[timerId] = nil
        end)
        self._SfxTimerIdMap[timerId] = timerId
    end
    GameUtil.PlayUISfx(PATH.UIFX_DungeonUnlock, frame_sfx, frame_sfx, -1, 5, 1, OnLoad)
    --]]

    local img_icon = uiTemplate:GetControl(0)
    GameUtil.MakeImageGray(img_icon, false)
    GUITools.SetUIActive(frame_lock, false)
    GameUtil.PlayUISfxClipped(PATH.UIFX_CommonUnlock, frame_sfx, frame_sfx, self._Panel._View_Dungeon)
end

CPageNightmareDungeon.Commit()
return CPageNightmareDungeon