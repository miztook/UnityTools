--伤害统计面板
--时间：2017/8/2
--Add by Yao

local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CTeamMan = require "Team.CTeamMan"
local EStatistic = require "PB.net".DamageStatistics.EStatistic
local EDamageStatisticsOpt = require "PB.data".EDamageStatisticsOpt

local CPageDamageCount = Lplus.Class("CPageDamageCount")
local def = CPageDamageCount.define

-- 缓存的数据（跟预设的显示没有关系）
def.field("table")._DamageDataList = BlankTable -- 伤害数据
def.field("table")._EliminateRankData = BlankTable -- 无畏战场排名数据
-- 通用
def.field("table")._Parent = nil
-- 界面
def.field("userdata")._Frame_WorldBoss = nil
def.field("userdata")._Template_WorldBoss = nil
def.field("userdata")._Frame_Dungeon = nil
def.field("userdata")._Template_Dungeon = nil
def.field("userdata")._Frame_Rank = nil 
def.field("table")._DungeonObjList = BlankTable -- 副本伤害GameOjbect表
def.field("table")._WorldBossObjList = BlankTable -- 世界Boss伤害GameOjbect表
def.field("userdata")._EliminateRankList = nil 
def.field("userdata")._Lab_Title = nil 
def.field("userdata")._Img_DamageBG = nil
def.field("userdata")._Img_DamageBigBG = nil
-- 数据
def.field("number")._DamageShowType = -1
def.field("number")._ViewShowType = 0
def.field("number")._BossMaxHP = 0 -- Boss最大血量
def.field("number")._CurTitleType = -1
def.field("number")._DungeonShowDamgeMaxNum = 0 -- 副本伤害统计显示数量上限

local SHOW_DAMAGE_MAX_NUM = 5               -- 显示伤害统计的最大个数
-- 界面展示类型
local EViewShowType =
{
    Damage = 1,     -- 伤害统计
    Rank = 2,       -- 排行榜（无畏战场）
}

local ColorHexStr =
{
    Normal =
    {
        Name = "<color=#8EACCF>%s</color>", -- 正常名字颜色（灰色）
        Num = "<color=#BFC2C7>%s</color>", -- 正常数字颜色（灰色）
    },
    Green =
    {
        Name = "<color=#4BEC10>%s</color>", -- 自己名字颜色（绿色）
        Num = "<color=#4BEC10>%s</color>" -- 自己数字颜色（绿色）
    },
}

def.static("=>", CPageDamageCount).New = function()
    return CPageDamageCount()
end

--[[--------------------- 以下方法不能删除---------------------]]--
def.method("table").Init = function (self, parent)
    self._Parent = parent

    self._Frame_WorldBoss = self._Parent:GetUIObject("Frame_WorldBoss")
    self._Template_WorldBoss = self._Parent:GetUIObject("Temp_WorldBoss")
    self._Frame_Dungeon = self._Parent:GetUIObject("Frame_Dungeon")
    self._Template_Dungeon = self._Parent:GetUIObject("Temp_Dungeon")
    self._Frame_Rank = self._Parent:GetUIObject("Frame_Rank")
    self._EliminateRankList = self._Parent:GetUIObject("Frame_RankList")
    self._Lab_Title = self._Parent:GetUIObject("Lab_Title")
    self._Img_DamageBG = self._Parent:GetUIObject("Img_DamageBG")
    self._Img_DamageBigBG = self._Parent:GetUIObject("Img_DamageBigBG")

    self._Template_WorldBoss:SetActive(false)
    self._Template_Dungeon:SetActive(false)

    if self._ViewShowType <= 0 then
        self._ViewShowType = EViewShowType.Damage
    end
end

def.method("string").ParentOnClick = function (self, id)
    -- body
end

def.method().Show = function (self)
    self:ReadyToShow()
end

def.method().Hide = function (self)
    -- body
end

def.method().Destroy = function (self)
    self:ClearDamageData()
    self:ClearRankData()

    self._Parent = nil
    self._Frame_WorldBoss = nil
    self._Template_WorldBoss = nil
    self._Frame_Dungeon = nil
    self._Template_Dungeon = nil
    self._Frame_Rank = nil
    self._Lab_Title = nil
    self._DungeonObjList = {}
    self._WorldBossObjList = {}
    self._EliminateRankList = nil
end
--[[-----------------------------------------------------------]]--

-- 切换伤害统计标题
-- @param titleType 1:副本小兵标题 2:副本boss标题 3:世界boss标题
def.method("number").ChangeDamageTitle = function (self, titleType)
    if self._CurTitleType == titleType then return end

    local titleStr = ""
    if titleType == 1 then
        titleStr = StringTable.Get(21202)
    elseif titleType == 2 then
        titleStr = StringTable.Get(21203)
    elseif titleType == 3 then
        titleStr = StringTable.Get(21204)
    end
    if titleStr ~= "" then
        GUI.SetText(self._Lab_Title, titleStr)
    end
end

-- 处理伤害统计信息
def.method("table", "number").HandleDamageData = function (self, data, showType)
    if showType == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonRealTime then
        -- 副本
        self:HandleDungeonDamageData(data)
    elseif showType == EDamageStatisticsOpt.EDamageStatisticsOpt_boss then
        -- 世界Boss
        self:HandleWorldBossDamageData(data)
    end
end

-- 处理排行数据
def.method("table").HandleRankData = function (self, rankData)
    self._ViewShowType = EViewShowType.Rank
    self._EliminateRankData = nil
    self._EliminateRankData = rankData
    if self._Parent ~= nil then
        self:UpdateRankData()
    end
end

-- 准备展示
def.method().ReadyToShow = function (self)
    if self._ViewShowType == EViewShowType.Damage then
        GUITools.SetUIActive(self._Frame_Rank, false)
        if self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonRealTime then
            -- 副本
            local bIsBigTeam = CTeamMan.Instance():IsBigTeam()
            self._Img_DamageBG:SetActive(not bIsBigTeam)
            self._Img_DamageBigBG:SetActive(bIsBigTeam)
            GUITools.SetUIActive(self._Frame_Dungeon, true)
            GUITools.SetUIActive(self._Frame_WorldBoss, false)
            self._DungeonShowDamgeMaxNum = bIsBigTeam and 10 or 5 -- 团队的伤害统计显示10条，普通队伍的显示5条
        elseif self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_boss then
            -- 世界Boss
            self._Img_DamageBG:SetActive(true)
            self._Img_DamageBigBG:SetActive(false)
            GUITools.SetUIActive(self._Frame_Dungeon, false)
            GUITools.SetUIActive(self._Frame_WorldBoss, true)
        end
    elseif self._ViewShowType == EViewShowType.Rank then
        self._Img_DamageBG:SetActive(true)
        self._Img_DamageBigBG:SetActive(false)
        GUI.SetText(self._Lab_Title,StringTable.Get(21201))
        GUITools.SetUIActive(self._Frame_Dungeon, false)
        GUITools.SetUIActive(self._Frame_WorldBoss, false)
        GUITools.SetUIActive(self._Frame_Rank, true)
    end
end

local function InstantiateShowObj(template)
    local obj = GameObject.Instantiate(template)
    obj:SetParent(template.parent)
    obj.localPosition = template.localPosition
    obj.localScale = template.localScale
    obj.localRotation = template.localRotation
    return obj
end

local function GetShowDamageNumber(num)
    if num < 100 then return 0 end
    if num > 10000 then
        return (num - num % 1000) / 1000 -- 按k显示，不保留小数点
    else
        return (num - num % 100) / 1000 -- 按k显示，保留小数点后一位
    end
end

local function GetShowName(name, length)
    if IsNilOrEmptyString(name) then
        warn("CPageDamageCount GetShowName failed, name got nil or empty")
        return ""
    end
    if GameUtil.GetUnicodeStrLength(name) > length then
        return GameUtil.SubUnicodeString(name, 1, length) .. "..."
    end
    return name
end

------------------------------副本实时伤害统计 start---------------------------
-- 处理
def.method("table").HandleDungeonDamageData = function (self, data)
    local ui_data =
    {
        RoleId = 0,             -- 角色Id
        RoleName = "Unknown",   -- 角色名称（协议只会推一次）
        TotalDamage = 0,        -- 队伍总伤害
        RoleDamage = 0,         -- 角色伤害
    }
    for _, v in ipairs(data) do
        if v.key == EStatistic.EStatistic_roleId then
            ui_data.RoleId = v.value
        elseif v.key == EStatistic.EStatistic_roleName then
            if v.originParam ~= nil and v.originParam < 0 then
                -- 镜头名字，从模板获取
                local textTid = tonumber(v.strValue)
                if textTid ~= nil then
                    local template = CElementData.GetTemplate("Text", textTid)
                    if template ~= nil and not IsNilOrEmptyString(template.TextContent) then
                        ui_data.RoleName = template.TextContent
                    end
                end
            else
                if not IsNilOrEmptyString(v.strValue) then
                    ui_data.RoleName = v.strValue
                end
            end
        elseif v.key == EStatistic.EStatistic_damage then
            ui_data.RoleDamage = v.value
        elseif v.key == EStatistic.EStatistic_damage_total then
            ui_data.TotalDamage = v.value
        elseif v.key == EStatistic.EStatistic_BossHp then
            self._BossMaxHP = v.value
        end
    end
    -- warn("Boss HP:", self._BossMaxHP)
    -- warn("RoleId:"..ui_data.RoleId, " RoleName:"..ui_data.RoleName, " RoleDamage:"..ui_data.RoleDamage, " TotalDamage:"..ui_data.TotalDamage)

    self:RefreshDungeonDamageStatistics(ui_data)
end

-- 刷新
def.method("table").RefreshDungeonDamageStatistics = function (self, data)
    if data == nil then return end
    local isNewData = true
    local isReorder = false
    for _, v in ipairs(self._DamageDataList) do
        if v.RoleId == data.RoleId then
            if v.RoleDamage ~= data.RoleDamage then
                isReorder = true
            end
            v.TotalDamage = data.TotalDamage
            v.RoleDamage = data.RoleDamage
            isNewData = false
            break
        end
    end

    -- 新数据
    if isNewData then
        isReorder = true
        self._DamageDataList[#self._DamageDataList+1] = data
    end

    -- 重新排序
    if isReorder then
        local function sort_func(a, b)
            -- 根据总伤害排序
            if a.RoleDamage > b.RoleDamage then
                return true
            end
            return false
        end
        table.sort(self._DamageDataList, sort_func)
    end

    -- warn("RoleId", data.RoleId, "RoleName", data.RoleName, "RoleDamage", data.RoleDamage)
    -- warn("isNewData", isNewData, "isReorder", isReorder)

    if self._Parent ~= nil then
        -- 已初始化（小地图已显示）
        self:ShowDungeonDamageInfo(isReorder)
    end
end

-- 显示
def.method("boolean").ShowDungeonDamageInfo = function (self, isReorder)
    self:ReadyToShow()
    local hp_id = game._HostPlayer._ID
    local count = 1
    for i, data in ipairs(self._DamageDataList) do
        if i > self._DungeonShowDamgeMaxNum then break end
        
        local item = self._DungeonObjList[i]
        if item == nil then
            -- 新建Item
            local obj = InstantiateShowObj(self._Template_Dungeon)
            obj.name = self._Template_Dungeon.name .. "_" .. i
            local uiTemplate = obj:GetComponent(ClassType.UITemplate)
            item =
            {
                _Item = obj,
                _Lab_Name = uiTemplate:GetControl(0),
                _Lab_Damage = uiTemplate:GetControl(1),
                _Lab_Rank = uiTemplate:GetControl(2),
                _Sld_RankPercent = uiTemplate:GetControl(3),
                _Img_SldFill = uiTemplate:GetControl(4),
            }
            self._DungeonObjList[i] = item
        end

        local isMe = data.RoleId == hp_id
        -- 伤害
        local percent = 0
        if self._BossMaxHP > 0 then
            percent = data.RoleDamage / self._BossMaxHP * 100
        else
            if data.TotalDamage > 0 then
                percent = data.RoleDamage / data.TotalDamage * 100
            end
        end
        percent = math.floor(percent * 10) / 10
        GUI.SetText(item._Lab_Damage, percent .. "%")
        -- 排名
        GUI.SetText(item._Lab_Rank, tostring(i))
        if isReorder then
            -- 角色名
            local nameStr = GetShowName(data.RoleName, 7) -- 只显示前七个字
            GUI.SetText(item._Lab_Name, nameStr)

            -- 背景条
            local sldPercent = 0
            local firstDamage = self._DamageDataList[1].RoleDamage -- 第一名的伤害
            if firstDamage > 0 then
                sldPercent = data.RoleDamage / firstDamage
                if isMe then
                    GUITools.SetGroupImg(item._Img_SldFill, 1)
                else
                    GUITools.SetGroupImg(item._Img_SldFill, 0)
                end
            end
            GUITools.DoSlider(item._Sld_RankPercent, sldPercent, _G.minimap_update_time, nil, nil)
        end

        count = i
        item._Item:SetActive(true)
    end

    -- 隐藏多余的
    for i = count + 1, #self._DungeonObjList do
        local item = self._DungeonObjList[i]._Item
        item:SetActive(false)
    end
end
------------------------------副本实时伤害统计 end-----------------------------

----------------------------世界Boss实时伤害统计 start-------------------------
-- 处理（data暂定服务器最多推送10条）
def.method("table").HandleWorldBossDamageData = function (self, data)
    local ui_data =
    {
        GuildId = 0,        -- 公会Id
        GuildName = "",     -- 公会名称
        TotalDamage = 0,    -- 总伤害
    }
    for i, v in ipairs(data) do
        if v.key == EStatistic.EStatistic_guildId then
            ui_data.GuildId = v.value
        elseif v.key == EStatistic.EStatistic_guildName then
            ui_data.GuildName = v.strValue
        elseif v.key == EStatistic.EStatistic_damage then
            ui_data.TotalDamage = v.value
        elseif v.key == EStatistic.EStatistic_damage_rank then
            ui_data.Rank = v.value
        elseif v.key == EStatistic.EStatistic_BossHp then
            self._BossMaxHP = v.value
        end
    end

    self:RefreshWorldBossDamageStatistics(ui_data)
end

-- 刷新
def.method("table").RefreshWorldBossDamageStatistics = function (self, data)
    if data == nil then return end
    local isNewData = true
    local isReorder = false
    for _, v in ipairs(self._DamageDataList) do
        if v.GuildId == data.GuildId then
            if v.TotalDamage ~= data.TotalDamage then
                isReorder = true
            end
            v.TotalDamage = data.TotalDamage
            isNewData = false
            break
        end
    end

    -- 新数据
    if isNewData then
        isReorder = true
        self._DamageDataList[#self._DamageDataList+1] = data
    end

    -- 重新排序
    if isReorder then
        local function sort_func(a, b)
            -- 根据总伤害排序
            if a.TotalDamage > b.TotalDamage then
                return true
            end
            return false
        end
        table.sort(self._DamageDataList, sort_func)
    end

    -- print("GuildId", data.GuildId, "GuildName", data.GuildName, "TotalDamage", data.TotalDamage)
    -- print("isNewData", isNewData, "isReorder", isReorder)

    if self._Parent ~= nil then
        -- 已初始化（小地图已显示）

        self:ShowWorldBossDamageInfo()
    end
end

-- 显示
def.method().ShowWorldBossDamageInfo = function (self)
    local function GetItemTable(index)
        local item = self._WorldBossObjList[index]
        if item == nil then
            -- 新建Item
            local obj = InstantiateShowObj(self._Template_WorldBoss)
            obj.name = self._Template_WorldBoss.name .. "_" .. index
            local uiTemplate = obj:GetComponent(ClassType.UITemplate)
            item =
            {
                _Item = obj,
                _Lab_Name = uiTemplate:GetControl(0),
                _Lab_Damage = uiTemplate:GetControl(1),
                _Lab_Rank = uiTemplate:GetControl(2),
                _Sld_RankPercent = uiTemplate:GetControl(3),
                _Img_SldFill = uiTemplate:GetControl(4),
            }
            self._WorldBossObjList[index] = item
        end
        if item._Item.activeSelf == false then
            item._Item:SetActive(true)
        end
        return item
    end

    self:ReadyToShow()
    local guild_id = game._GuildMan:GetHostPlayerGuildID()
    local hp_id = game._HostPlayer._ID
    local count = 0 -- 当前Item数量
    local hasInitHostPlayer = false -- 是否已初始化自己的伤害统计
    local firstDamage = 0 -- 排名第一的伤害量
    for i, data in ipairs(self._DamageDataList) do
        if count >= SHOW_DAMAGE_MAX_NUM then break end

        local isMe = false
        if data.GuildId > 0 then
            isMe = data.GuildId == guild_id
        elseif data.GuildId < 0 then
            -- 公会Id为负数时，代表是个人，公会Id为Entity实例Id的负数
            isMe = data.GuildId == -hp_id 
        end
        if isMe then
            hasInitHostPlayer = true
        end

        if count < SHOW_DAMAGE_MAX_NUM - 1 or hasInitHostPlayer then
            -- 还没到最后一个，或者到最后一个而且自己的已经初始化了
            count = count + 1
            if i == 1 and data.TotalDamage > 0 then
                firstDamage = data.TotalDamage
            end

            local item = GetItemTable(count)
            -- 背景条
            local sldPercent = 0
            if firstDamage > 0 then
                -- 第一名伤害大于0
                sldPercent = data.TotalDamage / firstDamage
                if isMe then
                    GUITools.SetGroupImg(item._Img_SldFill, 1)
                else
                    GUITools.SetGroupImg(item._Img_SldFill, 0)
                end
            end
            GUITools.DoSlider(item._Sld_RankPercent, sldPercent, _G.minimap_update_time, nil, nil)
            -- 伤害
            local bShowDamage = self._BossMaxHP > 0
            GUITools.SetUIActive(item._Lab_Damage, bShowDamage)
            if bShowDamage then
                local percent = data.TotalDamage / self._BossMaxHP * 100
                percent = math.floor(percent * 10) / 10 -- 保留一位小数向下取整
                GUI.SetText(item._Lab_Damage, percent .. "%")
            end
            -- 排名
            GUITools.SetUIActive(item._Lab_Rank, true)
            GUI.SetText(item._Lab_Rank, tostring(i))
            -- 公会名
            GUI.SetText(item._Lab_Name, data.GuildName)
        end
    end
    if not hasInitHostPlayer and count + 1 == SHOW_DAMAGE_MAX_NUM then
        -- 伤害列表里没有自己，而且显示位置还剩最后一个，显示未上榜
        count = count + 1

        local item = GetItemTable(count)
        GUITools.SetUIActive(item._Lab_Rank, false)
        GUI.SetText(item._Lab_Damage, StringTable.Get(8063))
        local nameStr = ""
        if game._GuildMan:IsHostInGuild() then
            -- 有公会，显示公会名字
            nameStr = game._HostPlayer._Guild._GuildName
        else
            -- 没有公会，显示玩家名字
            nameStr = game._HostPlayer._InfoData._Name
        end
        GUI.SetText(item._Lab_Name, nameStr)
        item._Sld_RankPercent.value = 0
    end

    -- 隐藏多余的
    for i = count + 1, #self._WorldBossObjList do
        local item = self._WorldBossObjList[i]._Item
        if item.activeSelf == true then
            item:SetActive(false)
        end
    end
end
----------------------------世界Boss实时伤害统计 end---------------------------

----------------------------------外部接口 start-------------------------------
-- 更新排行显示
def.method("userdata", "string", "number").OnInitItemRankData = function(self, item, id, index)
    if id == "Frame_RankList" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local Lab_Name = uiTemplate:GetControl(0)
        local Lab_Data = uiTemplate:GetControl(1)
        if self._EliminateRankData == nil then return end
        local name = self._EliminateRankData[index + 1].Name
        local data = tostring(self._EliminateRankData[index + 1].Score)
        if self._EliminateRankData[index + 1].RoleId == game._HostPlayer._ID then 
            name = "<color=#4BEC10>"..name.."</color>"
            data = "<color=#4BEC10>"..data.."</color>"
        end
        GUI.SetText(Lab_Name,name)
        GUI.SetText(Lab_Data,data)
    end
end

-- 清除伤害统计数据
def.method().ClearDamageData = function (self)
    self._DamageDataList = {}
    self._BossMaxHP = 0
    self._CurTitleType = -1
end

-- 清理伤害统计显示
def.method().ClearDamageUI = function (self)
    GUI.SetText(self._Lab_Title, StringTable.Get(21200))
    if self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonRealTime then
        GUITools.SetUIActive(self._Frame_Dungeon, false)
    elseif self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_boss then
        GUITools.SetUIActive(self._Frame_WorldBoss, false)
    end
    self._DamageShowType = -1
end

-- 清除排行榜数据
def.method().ClearRankData = function (self)
    self._EliminateRankData = {}
    self._ViewShowType = EViewShowType.Damage
end

-- 清理排行榜显示
def.method().ClearRankUI = function (self)
    GUITools.SetUIActive(self._Frame_Rank, false)
end

-- 是否已缓存伤害数据
def.method("=>", "boolean").HasDamageData = function (self)
    return #self._DamageDataList > 0
end

-- 是否已缓存排名数据
def.method("=>", "boolean").HasRankData = function (self)
    return #self._EliminateRankData > 0
end

def.method("=>","boolean").HasData = function (self)
    return self:HasDamageData() or self:HasRankData()
end

-- 获取目前展示的伤害统计类型
def.method("=>", "number").GetDamageShowType = function (self)
    return self._DamageShowType
end

-- 更新显示
def.method().UpdateView = function (self)
    if self._ViewShowType == EViewShowType.Damage then
        self:UpdateDamageShowInfo()
    elseif self._ViewShowType == EViewShowType.Rank then 
        self:UpdateRankData()
    end
end

-- 更新伤害统计展示
def.method().UpdateDamageShowInfo = function (self)
    if self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonRealTime then
        self:ShowDungeonDamageInfo(true)
    elseif self._DamageShowType == EDamageStatisticsOpt.EDamageStatisticsOpt_boss then
        self:ShowWorldBossDamageInfo()
    end
end

-- 更新排行显示
def.method().UpdateRankData = function (self)
    self:ReadyToShow()
    self._EliminateRankList:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._EliminateRankData)
end

def.method("number").SetShowType = function (self, showType)
    if showType <= 0 then return end
    self._DamageShowType = showType
end
-----------------------------------外部接口 end--------------------------------

CPageDamageCount.Commit()
return CPageDamageCount