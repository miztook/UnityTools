-- 界面管理 zai CUIManCore

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local bit = require "bit"
local CElementData = require "Data.CElementData"
local CEntity = require "Object.CEntity"
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local CPate = require "GUI.CPate".CPateBase

local _KeepUIs = 
{
    "CPanelRocker",
    "CPanelSkillSlot",
    "CPanelMainChat",
    "CPanelTracker",
    "CPanelMinimap",
    "CPanelUIHead",
    --"CPanelUIActivityEntrance",
    -- "CPanelUISystem",
    "CPanelSystemEntrance",
    "CPanelLoading",
    "CPanelLog",
    "CPanelDebug",
    "CpanelGuide",
    "CPanelUIQuickUse",
    "CPanelMainTips",
	"CPanelMainTipsLow",
    "CPanelUIGuildBattleMiniMap",
    "CPanelEnterMapTips",
    "CPanelUIBeginnerDungeonBoss",
    "CPanelDungeonNpcTalk",
    "CPanelUIBuffEnter",
    "CPanelInExtremis",
    "CPanelPVPHead",
    "CPanelBattleMiddle",
    "CPanelBattleResult",
	"CPanelPowerSaving",
    "CMsgBoxPanel",
}

-- real UI management unit
local CUIManCore = require "GUI.CUIManCore"

local CUIMan = Lplus.Class("CUIMan")
local def = CUIMan.define

def.field(CUIManCore)._UIManCore = nil
def.field("table")._UIForbidList = BlankTable
def.field("table")._FuncForbidList = BlankTable -- 地图禁止的功能ID列表
def.field("boolean")._UIIsHide = false -- 是否执行了隐藏UI操作
def.field("boolean")._UIIsHideNew = false
-- def.field("table")._TweenAllReadyMap = BlankTable
def.field("function")._OnTweenCompleteCallback = nil -- 主界面动效回调

def.static("=>", CUIMan).new = function()
    local obj = CUIMan()

    obj._UIManCore = CUIManCore.new()

    obj:Init()
    return obj
end

def.method().Init = function(self)
    self:GetAllOriginalPos()
    self._UIManCore:Init()
    self:ReInitTopPate(true)
end

def.method("boolean").ReInitTopPate = function(self, is_reloadPrefab)
    CPate.Setup(is_reloadPrefab)
end

-- 单个节点下的Pate数量限制，过多效率有问题
def.method("=>", "userdata").GetHudTopBoardRoot = function(self)
    -- TODO(lijian):
    --[[
    local count = self.m_hudTopBoard.childCount
    local best
    for i=1,count do
        local child = self.m_hudTopBoard:GetChild(i-1)
        if child.childCount < 100 then
            best = child
            break
        end
    end
    if not best then
        best = self:_CreateHudTopBoardGroup()
    end
    return best
    ]]
    return nil
end

def.method("userdata", "=>", "userdata").GetPanelRoot = function(self, obj)
    if IsNil(obj) then
        return nil
    else
        local listener = obj:GetComponent(ClassType.UIEventListener)
        if listener ~= nil then
            return obj
        else
            return self:GetPanelRoot(obj.parent)
        end
    end
end

def.method("string", "dynamic", "=>", "table").Open = function(self, panel_name, panel_data)
    if (panel_name == nil) then return nil end

    -- warn(" Pre OPen "..panel_name)


    local panel_script = require("GUI." .. panel_name).Instance()
    if panel_script == nil then
        warn("cant find the lua file named " .. panel_name)
        return nil
    end

    return self:OpenByScript(panel_name, panel_data, panel_script)
end

def.method("table", "=>", "boolean").Exist = function(self, panel_script)
    return self._UIManCore:Exist(panel_script)
end

def.method("string", "dynamic", "table", "=>", "table").OpenByScript = function(self, panel_name, panel_data, panel_script)
    -- 地图限制，禁止打开
    if self:IsUIForbid(panel_script) then return nil end

    local hp = game._HostPlayer
    -- 死亡 UI限制
    if hp ~= nil then
        if hp:IsDead() and not self:IsUIDeadAllow(panel_script) then
            self:ShowTipText(StringTable.Get(30103), false)
            return nil
        end
    end

    return self._UIManCore:OpenByScript(panel_name, panel_data, panel_script)
end

--def.method("number", "table").ResetPanelLayer = function(self, layer, panel_script)
--    self._UIManCore:ReSetPanelLayer(layer, panel_script)
--end

def.method("string").Close = function(self, panel_name)
    -- warn("close")
    local panel_script = self._UIManCore:FindUIByName(panel_name)

    if panel_script ~= nil then
        self:CloseByScript(panel_script)
    end
end

def.method("table").CloseByScript = function(self, panel_script)
    -- warn("Close " .. panel_script._Name)

    self._UIManCore:CloseByScript(panel_script)
end

def.method("table").CloseAll = function(self, except)
    -- ToDo: Move this part to UIHead
    local CPanelUIHead = require "GUI.CPanelUIHead"
    local UIHead = CPanelUIHead.Instance()
    if not IsNil(UIHead) and UIHead:IsShow() then
        UIHead:HideProgressBoard(false, true)
    end
    MsgBox.ClearAllExceptDisconnect()
    self._UIManCore:CloseAll(except)
end

def.method().CloseToMain = function(self)
    self:CloseAll(_KeepUIs)
end

--关闭全屏界面
def.method().CloseSubPanelLayer = function(self)
	--local CExteriorMan = require "Main.CExteriorMan"
	--CExteriorMan.Instance():Quit()
    --MsgBox.ClearAllBoxes()
    self._UIManCore:CloseByLayer(self._UIManCore._UISetting.Sorting_Layer.SubPanel)
end

--联线清除
def.method().Clear = function(self)
    -- Clear all UIs
    self._UIManCore:Clear()

    -- 清除缓存
    self._UIIsHide = false
    self._UIIsHideNew = false
end

-- 死亡时 允许弹出的界面
local UIDeadUnAllowList = 
{
    "UI_Map",
    "UI_Buff",
    "UI_MessageBox",
    "UI_HuangxinTest",
    "UI_Revive",
    "UI_Head",
    "Panel_Loading",
    "Panel_Video",
    "Panel_SkillSlot",
    "Panel_Main_SkillNew",
    "Panel_Main_Move",
    "Panel_Main_QuestN",
    "Panel_MainTips",
    "UI_Main_Chat",
    "Panel_OperationTips",
    "Panel_Main_MiniMap",
    "UI_Guild_Battle_MiniMap",
    "UI_QuickUse",
    "UI_SystemEntrance",
    "UI_ChatNew",
    "UI_BuffEnter",
    "Panel_WorldMapName",
    "UI_CommonBuyGuide",
    "UI_Dungeon_End",
    "Panel_Circle",
}

-- 界面打开死亡限制
def.method("table", "=>", "boolean").IsUIDeadAllow = function(self, panel_script)
    if panel_script == nil then return false end
    local prefab_name = string.sub(panel_script:GetPrefabName(), 1, -8)
    for _, v in ipairs(UIDeadUnAllowList) do
        if v == prefab_name then
            return true
        end
    end

   --warn("prefab_name = ", prefab_name)

    return false
end

-- 界面打开是否被场景限制
def.method("table", "=>", "boolean").IsUIForbid = function(self, panel_script)
    if panel_script == nil then return false end
    local prefab_name = string.sub(panel_script:GetPrefabName(), 1, -8)
    for _, v in ipairs(self._UIForbidList) do
        if v == prefab_name then
            self:ShowTipText(StringTable.Get(15555), false)
            return true
        end
    end
    return false
end

-- 界面内的功能打开是否被场景限制
def.method("number", "=>", "boolean").IsFuncForbid = function(self, funcId)
    for _, v in ipairs(self._FuncForbidList) do
        if v == funcId then
            self:ShowTipText(StringTable.Get(15555), false)
            return true
        end
    end
    return false
end

-- 根据当前地图限制，设置禁止打开的界面列表
def.method().SetUIForbidList = function(self)
    local template = CElementData.GetMapTemplate(game._CurWorld._WorldInfo.MapTid)
    if template == nil then return end

    self._UIForbidList = {}
    if not IsNilOrEmptyString(template.ForbidWidget) then
        self._UIForbidList = string.split(template.ForbidWidget, '*')

        for _, v in ipairs(self._UIForbidList) do
            local script = self._UIManCore:FindUIByPrefab(v .. ".prefab")
            if script ~= nil then
                self:CloseByScript(script)
            end
        end
    end

    self._FuncForbidList = {}
    if not IsNilOrEmptyString(template.ForbidSystem) then
        local funcIdStrList = string.split(template.ForbidSystem, '*')
        for _, v in ipairs(funcIdStrList) do
            local funcId = tonumber(v)
            if funcId ~= nil then
                table.insert(self._FuncForbidList, funcId)
            end
        end
    end
end

def.method("string", "boolean").ShowTipText = function(self, content, use_up_obj)
    local param =
    {
        use_up_obj = false,
        -- 李瑞龙说的，不需要上飘字了！！2017.10.20
        content = content,
    }
    self:Open("CPanelMainTips", param)
end

-- 打开webview
def.method("string").OpenUrl = function(self, url)
    self:Open("CPanelUICommonWebView", url)
end

-- showCircle:是否展示转圈效果
def.method("string", "boolean").ShowCircle = function(self, content, showCircle)
    GameUtil.EnableBlockCanvas(false)
    self:Close("CPanelCircle")

    self:Open("CPanelCircle", { text = content, show = showCircle })
    GameUtil.EnableBlockCanvas(true)

    --warn("ShowCircle: ", debug.traceback())
end

def.method("=>", "boolean").IsCircleShow = function (self)
    return self:IsShow("CPanelCircle")
end

def.method().CloseCircle = function (self)
    GameUtil.EnableBlockCanvas(false)
    self:Close("CPanelCircle")

   --warn("CloseCircle: ", debug.traceback())
end

def.method("string", "=>", "boolean").IsShow = function(self, panel_name)
    local panel_script = require("GUI." .. panel_name).Instance()
    if panel_script ~= nil then
        return panel_script:IsShow()
    end
    return false
end

-- 打开数字小键盘
def.method("userdata", "userdata", "number", "number", "function", "function").OpenNumberKeyboard = function(self, label, defaultLabel, min, max, endCb, countChangeCb)
    self:Open("CPanelNumberKeyboard", { label = label, defaultLabel = defaultLabel, min = min, max = max, endCb = endCb, changeCb = countChangeCb })
end

--[[带图标的上提示 显示格式 “获得道具 [ICON] 大宝剑”

]]

--def.method("string", "string", "string").ShowIconAndTextTip = function(self, icon_path, prefix_msg, suffix_msg)
--    local param =
--    {
--        use_up_obj = true,
--        content = prefix_msg,
--        icon = icon_path,
--        param = suffix_msg,
--    }
--    self:Open("CPanelMainTipsLow", param)
--end

--def.method("number").ShowGetCoinTip = function(self, count)
--    local iconPath = PATH.ICON_GOLD
--    local prefixMsg = StringTable.Get(7)
--    local suffixMsg = "X " .. tostring(count)
--    self:ShowIconAndTextTip(iconPath, prefixMsg, suffixMsg)
--end

--def.method("number", "boolean").ShowGetDiamondTip = function(self, count, is_bind)
--    local iconPath = PATH.ICON_DIAMOND
--    if is_bind then iconPath = PATH.ICON_BINDIAMOND end
--    local prefixMsg = StringTable.Get(7)
--    local suffixMsg = "X " .. tostring(count)
--    self:ShowIconAndTextTip(iconPath, prefixMsg, suffixMsg)
--end

--def.method("number").ShowGetItemTip = function(self, tid)
--    local itemTemp = CElementData.GetTemplate("Item", tid)
--    if itemTemp == nil then return end

--    local iconPath = _G.CommonAtlasDir .. "Icon/" .. itemTemp.IconAtlasPath .. ".png"
--    local prefixMsg = StringTable.Get(7)
--    local suffixMsg = itemTemp.TextDisplayName
--    self:ShowIconAndTextTip(iconPath, prefixMsg, suffixMsg)
--end

-- 错误码提示字
def.method("number", "dynamic").ShowErrorCodeMsg = function(self, errId, params)
    local ESystemNotifyDisplayType = require "PB.Template".SystemNotify.SystemNotifyDisplayType
    local ESyncChannel = require "PB.Template".SystemNotify.ESyncChannel
    local template = CElementData.GetSystemNotifyTemplate(errId)

    local curType = ESystemNotifyDisplayType.ScrollNotify
    local syncChannel = ESyncChannel.DontSync
    local message = nil

    if template ~= nil then
        curType = template.DisplayType
        syncChannel = template.SyncChannel
        message = template.TextContent
        -- 以下逻辑存在问题，message无法保证与params正好对应  added by lijian
        -- params为只支持一个string类型的参数
        local sunstr = string.split(message,'%s')
        if params ~= nil and (#sunstr - 1) <= 1 then
            message = string.format(message, params or "")
        end
    end
    if message == nil then
        message = "Unkown message {id = " .. tostring(errId) .. "}"
    end
    
    -- curType 显示方式
    if curType == ESystemNotifyDisplayType.ScrollNotify then
        -- 走马灯
        self:OpenSpecialTopTips(message)
    elseif curType == ESystemNotifyDisplayType.SystemChatChannel then
        -- 系统聊天频道
        local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
        local ChatManager = require "Chat.ChatManager"
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, message, false, 0, nil,nil)
    elseif curType == ESystemNotifyDisplayType.FloatingTipBottom then
        -- 底部飞字
        self:ShowTipText(message, false)
    elseif curType == ESystemNotifyDisplayType.FloatingTipTop then
        -- 顶部飞字
        self:ShowTipText(message, true)
    elseif curType == ESystemNotifyDisplayType.DungeonMessage then
        -- 副本信息
        self:ShowAttentionTips(message, 3, template.DurationSeconds > 0 and template.DurationSeconds or 1.5)
    elseif curType == ESystemNotifyDisplayType.SocialMessage then 
        -- 好友系统通知
        game._CFriendMan:AddFriendSystemNotifyMsg(message)
    elseif curType == ESystemNotifyDisplayType.GuildBFNormal then
        local CPanelMainTips = require "GUI.CPanelMainTips"
        CPanelMainTips.Instance():ShowGuildBFBaseTip(message)
    elseif curType == ESystemNotifyDisplayType.GuildBFDestroyTower then
        local CPanelMainTips = require "GUI.CPanelMainTips"
        local isRed = true
        if errId == 30014 then
            isRed = false
        elseif errId == 30015 then
            isRed = true
        end
        CPanelMainTips.Instance():ShowGuildBFTwerTip(isRed, message)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_GuildBFTowerDestroy, 0)

    elseif curType == ESystemNotifyDisplayType.GuildDefend then
        local CPanelMainTips = require "GUI.CPanelMainTips"
        CPanelMainTips.Instance():ShowFrameGuildDungeonTip(message)
    else
        -- 默认为 消息框
        local title = StringTable.Get(8)
        -- message = string.format("%s(%d)", message, errId)
        local close_type = EnumDef.CloseType.ClickAnyWhere
        if template and template.IsShowCloseBtn then
            close_type = EnumDef.CloseType.CloseBtn
        else
            close_type = EnumDef.CloseType.ClickAnyWhere
        end
        MsgBox.ShowMsgBox(message, title, close_type, MsgBoxType.MBBT_OK)
    end

    -- syncChannel 同步频道
    if syncChannel ~= nil and syncChannel ~= ESyncChannel.DontSync then
        -- 与显示方式重复则不同步
        local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
        local ChatManInstance = require "Chat.ChatManager".Instance()

        -- 系统频道，当前频道，世界频道，队伍频道，公会频道，战斗频道
        local enumTable =
        {
            [ESyncChannel.ChatChannelSystem] = ECHAT_CHANNEL_ENUM.ChatChannelSystem,
            [ESyncChannel.ChatChannelCurrent] = ECHAT_CHANNEL_ENUM.ChatChannelCurrent,
            [ESyncChannel.ChatChannelWorld] = ECHAT_CHANNEL_ENUM.ChatChannelWorld,
            [ESyncChannel.ChatChannelTeam] = ECHAT_CHANNEL_ENUM.ChatChannelTeam,
            [ESyncChannel.ChatChannelGuild] = ECHAT_CHANNEL_ENUM.ChatChannelGuild,
            [ESyncChannel.FightChannel] = ECHAT_CHANNEL_ENUM.ChatChannelCombat,
        }

        -- 同步频道为跑马灯，并且显示方式不是跑马灯
        if syncChannel == ESyncChannel.Scroll and curType ~= ESystemNotifyDisplayType.ScrollNotify then
            self:OpenSpecialTopTips(message)

        -- 同步频道为副本提示，并且显示方式不是副本提示
        elseif syncChannel == ESyncChannel.DungeonNotify and curType ~= ESystemNotifyDisplayType.DungeonMessage then
            self:ShowAttentionTips(message, 3 , template.DurationSeconds > 0 and template.DurationSeconds or 1.5)
        
        -- 同步频道为好友频道，并且显示方式不是好友频道
        elseif syncChannel == ESyncChannel.SocialChannel and curType ~= ESystemNotifyDisplayType.SocialMessage then
            game._CFriendMan:AddFriendSystemNotifyMsg(message)
        
        -- 同步频道不为跑马灯和副本提示，并且显示方式不是SystemChatChannel
        elseif (syncChannel ~= ESyncChannel.Scroll or syncChannel ~= ESyncChannel.DungeonNotify) and curType ~= enumTable[ESyncChannel.ChatChannelSystem] then
            if enumTable[syncChannel] == nil then return end
            ChatManInstance:ClientSendMsg(enumTable[syncChannel], message, false, 0, nil,nil)
        else
            warn("Not Find Notification Method !!!")
        end
    end                                                         
end

--飘字显示错误消息提示
def.method("number").ShowErrorTipText = function(self, errorCode)
    local template = CElementData.GetSystemNotifyTemplate(errorCode)
	local message = ""
	if template == nil then
		message = "Unkownn message ErrorCode = "..errorCode
	else
		message = template.TextContent
	end
	self:ShowTipText(message, false)
end

-- 走马灯提示
def.method("string").OpenSpecialTopTips = function(self, tips)
    if game._HostPlayer == nil then	return end
    self:Open("CPanelSpecialTopTips", tips)
end

-- 滚屏文字
def.method("string").ShowMoveTextTips = function(self, strTips)
    local CPanelMainTips = require "GUI.CPanelMainTips"
    CPanelMainTips.Instance():MoveText(strTips)

	--warn("ShowMoveTextTips : "..strTips)
end

-- 滚屏带道具的文字
def.method("number", "boolean", "number", "boolean").ShowMoveItemTextTips = function(self, ItemID, isTokenMoney, nCount, isFly)
		if game._CPowerSavingMan:IsSleeping() then
			game._CPowerSavingMan:AddDropItem(ItemID, isTokenMoney, nCount)
		else
			local CPanelMainTips = require "GUI.CPanelMainTips"
			CPanelMainTips.Instance():MoveItemText(ItemID, isTokenMoney, nCount, isFly)
			--warn("ShowMoveItemTextTips : "..tostring(ItemID)..tostring(isTokenMoney))
		end
end

-- 警戒提示
def.method("string", "number","number").ShowAttentionTips = function(self, strTips, nType, nTime)
    local CPanelMainTipsLow = require "GUI.CPanelMainTipsLow"
    CPanelMainTipsLow.Instance():ShowAttention(strTips, nType, nTime)
end

--副本中的消息提示
--stg_type = EnumDef.BattleStgType
def.method("number","string","number").PopSkillTip = function(self, stg_type, content, dur)
	--warn("PopSkillTip "..stg_type..", "..content..", "..dur)

    local panel_script = require("GUI.CPanelMainTipsLow").Instance()
	local PopSkillTipsType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventPopSkillTips.PopSkillTipsType
	if stg_type == PopSkillTipsType.SKILL  then
		panel_script:PopSkillTip(content, dur)
	else
		self:ShowAttentionTips(content, -1, dur)
	end
end

--成就解锁提示 名称，分类。第几个
def.method("string","number").ShowAchieveTips = function(self, strTips, nTId)
    --local CPanelMainTips = require "GUI.CPanelMainTips"
    --CPanelMainTips.Instance():ShowAchieveTips(strTips,nTId)
    game._CGameTipsQ:ShowAchieveTip(strTips,nTId)
end

local MoveUI = { }
def.method().GetAllOriginalPos = function(self)
    MoveUI["CPanelRocker"] = { }
    MoveUI["CPanelRocker"].Pos = nil
    MoveUI["CPanelRocker"].Distance = -350
    MoveUI["CPanelRocker"].Type = "MoveX"

    MoveUI["CPanelSkillSlot"] = { }
    MoveUI["CPanelSkillSlot"].Pos = nil
    MoveUI["CPanelSkillSlot"].Distance = 400
    MoveUI["CPanelSkillSlot"].Type = "MoveX"

    MoveUI["CPanelMainChat"] = { }
    MoveUI["CPanelMainChat"].Pos = nil
    MoveUI["CPanelMainChat"].Distance = -310
    MoveUI["CPanelMainChat"].Type = "MoveY"

    MoveUI["CPanelTracker"] = { }
    MoveUI["CPanelTracker"].Pos = nil
    MoveUI["CPanelTracker"].Distance = -350
    MoveUI["CPanelTracker"].Type = "MoveX"

    MoveUI["CPanelMinimap"] = { }
    MoveUI["CPanelMinimap"].Pos = nil
    MoveUI["CPanelMinimap"].Distance = 230
    MoveUI["CPanelMinimap"].Type = "MoveX"

    MoveUI["CPanelUIHead"] = { }
    MoveUI["CPanelUIHead"].Pos = nil
    MoveUI["CPanelUIHead"].Distance = 250
    MoveUI["CPanelUIHead"].Type = "MoveY"

    MoveUI["CPanelSystemEntrance"] = { }
    MoveUI["CPanelSystemEntrance"].Pos = nil
    MoveUI["CPanelSystemEntrance"].Distance = 373
    MoveUI["CPanelSystemEntrance"].Type = "MoveX"

    MoveUI["CPanelUIQuickUse"] = { }
    MoveUI["CPanelUIQuickUse"].Pos = nil
    MoveUI["CPanelUIQuickUse"].Distance = 500
    MoveUI["CPanelUIQuickUse"].Type = "MoveX"

    MoveUI["CPanelUIBuffEnter"] = { }
    MoveUI["CPanelUIBuffEnter"].Pos = nil
    MoveUI["CPanelUIBuffEnter"].Distance = -330
    MoveUI["CPanelUIBuffEnter"].Type = "MoveX"
end
--[[
-- 隐藏移动常驻UI false = 还原  true 隐藏
def.method("boolean", "number", "string", "dynamic").SetNormalUIMoveToHide = function(self, isHide, time, panelName, data)
    --warn("SetNormalUIMoveToHide *****************"..tostring(isHide),debug.traceback())

    if isHide then
        if self._UIIsHide then return end

        self._UIIsHide = isHide
        for k, v in pairs(MoveUI) do
            local panelClass = require("GUI." .. k).Instance()
            if panelClass ~= nil and panelClass:IsShow() and not IsNil(panelClass._Panel) then

                if v.Pos == nil then
                    v.Pos = panelClass._Panel.localPosition
                end

                local movePos = v.Pos
                if v.Type == "MoveX" then
                    movePos = Vector3.New(v.Pos.x + v.Distance, v.Pos.y, v.Pos.z)
                elseif v.Type == "MoveY" then
                    movePos = Vector3.New(v.Pos.x, v.Pos.y + v.Distance, v.Pos.z)
                end

                if k == "CPanelRocker" then
                    GUITools.DoLocalMove(panelClass._Panel, movePos, time, nil, function()
                        if panelName == "" or panelName == " " then return end
                        self:Open(panelName, data)
                    end )
                else
                    GUITools.DoLocalMove(panelClass._Panel, movePos, time, nil, nil)
                end

                if k == "CPanelSkillSlot" then
                    local bar = panelClass:GetUIObject("Sld_CastBar")
                    if bar ~= nil then
                        bar:SetActive(false)
                    end
                end
                --if isHide and k == "CPanelTracker" or k == "CPanelMainChat" then
                --    game._CGuideMan:IsShowGuide(false,panelClass._Panel.name)
                --end
            end
        end
        if isHide then
            game._CGuideMan:IsShowGuide(false,"")
        end
    else
        if not self._UIIsHide then return end

        self._UIIsHide = false
        local cbMax = 0
        local cbCur = 0
        for k, v in pairs(MoveUI) do
            local panelClass = require("GUI." .. k).Instance()
            if panelClass ~= nil and not IsNil(panelClass._Panel) then
                local movePos = v.Pos
                if v.Pos ~= nil then
                    movePos = Vector3.New(v.Pos.x, v.Pos.y, v.Pos.z)
                    local function TweenComplete()
                        --if not isHide then
                        --    game._CGuideMan:IsShowGuide(true,"Panel_Main_QuestN(Clone)")
                        --    game._CGuideMan:IsShowGuide(true,"UI_Main_Chat(Clone)")
                        --end
                        cbCur = cbCur + 1
                        if not isHide and cbCur == cbMax then
                            game._CGuideMan:IsShowGuide(true,"")
                        end
                    end

                    cbMax = cbMax + 1
                    GUITools.DoLocalMove(panelClass._Panel, movePos, time, nil, TweenComplete)
                end
            end
        end
    end
end
]]--

-- 新版隐藏常驻UI(DOTweenAnimation)
def.method("boolean", "function").SetMainUIMoveToHide = function (self, isHide, callback)
    --warn("SetMainUIMoveToHide *****************"..tostring(isHide),debug.traceback())

    if isHide == self._UIIsHideNew then
        warn("As required, MainUI hide status has been ", isHide)
        return
    end
    self._UIIsHideNew = isHide

    -- self._TweenAllReadyMap = {}
    
    local bStartTween = false
    local tweenId = isHide and "1" or "2"
    local otherTweenId = isHide and "2" or "1"
    for k, _ in pairs(MoveUI) do
        local panelClass = require("GUI." .. k).Instance()
        if panelClass ~= nil and not IsNil(panelClass._Panel) then
            local do_tween_player = panelClass._Panel:GetComponent(ClassType.DOTweenPlayer)
            if do_tween_player ~= nil then
                if panelClass:IsShow() then
                        bStartTween = true
                        -- self._TweenAllReadyMap[k] = false
                        do_tween_player:Stop(otherTweenId) -- 停止另外一个动效
                        do_tween_player:Restart(tweenId)

                    -- 特殊处理
                    if isHide then
                        if k == "CPanelMainChat" then
                            panelClass:IsShowRelaxPanel(false)
                        elseif k == "CPanelSystemEntrance" then
                            panelClass:ShowFloatingFrame(false)
                        elseif k == "CPanelUIHead" then
                            panelClass:OnPKFight(false)
                        end
                    end
                    --if isHide and k == "CPanelTracker" or k == "CPanelMainChat" then
                    --    game._CGuideMan:IsShowGuide(false,panelClass._Panel.name)
                    --end
                else
                    --warn("11111111111111111111111")
                    do_tween_player:Stop(tweenId)
                    do_tween_player:Stop(otherTweenId)
                    do_tween_player:GoToEndPos(tweenId) -- 直接到指定位置
                end
            end
        end
    end
    if isHide then
        game._CGuideMan:IsShowGuide(false,"")
    end
    self:Close("CPanelChatNew")
    if not bStartTween then
        self._OnTweenCompleteCallback = nil
        if callback ~= nil then 
            callback()
        end
    else
        GameUtil.EnableBlockCanvas(true) -- 阻挡点击
        local function TweenComplete()
            if callback ~= nil then 
                callback()
            end
            --if not isHide then
            --    game._CGuideMan:IsShowGuide(true,"Panel_Main_QuestN(Clone)")
            --    game._CGuideMan:IsShowGuide(true,"UI_Main_Chat(Clone)")
            --end
            if not isHide then
                game._CGuideMan:IsShowGuide(true,"")
            end
        end
        self._OnTweenCompleteCallback = TweenComplete
    end
    local ShowMainUIEvent = require "Events.ShowMainUIEvent"
	local event = ShowMainUIEvent()
    event._IsShow = not isHide
	CGame.EventManager:raiseEvent(nil, event)
end

def.method("=>", "boolean").IsMainUIShowing = function(self)
    return not self._UIIsHideNew
end

def.method("string").OnMainUITweenComplete = function(self, name)
    -- self._TweenAllReadyMap[name] = true
    -- for _, v in pairs(self._TweenAllReadyMap) do
    --     if not v then
    --         return
    --     end
    -- end
    GameUtil.EnableBlockCanvas(false)
    if self._OnTweenCompleteCallback ~= nil then
        self._OnTweenCompleteCallback()
        self._OnTweenCompleteCallback = nil
    end
    game._CGuideMan:AnimationEndCallBack(require("GUI.CPanelRocker").Instance())
end

--[[ --------------------------------功能入口函数-------------------------------- ]]
def.method("number").OpenPanelByFuncId = function(self, funcId)

    --[[
        --FIXME::2017-11-06 客户端未完成界面，禁掉开界面逻辑
        local notDoneList = {2, 6, 11, 43,}
        for i=1, #notDoneList do
            if notDoneList[i] == funcId then
                TODO()
                return
            end
        end
        --FIXME::2017-11-06 客户端未完成界面，禁掉开界面逻辑
    ]]

    local FuncType = EnumDef.EGuideTriggerFunTag
    if funcId == FuncType.Role then
        -- "角色"
        self:Open("CPanelRoleInfo", nil)
    elseif funcId == FuncType.Equip then
        -- "装备
        self:Open("CPanelUIEquipProcess", nil)
    elseif funcId == FuncType.Exterior then
        -- "外观
        local CExteriorMan = require "Main.CExteriorMan"
        CExteriorMan.Instance():Enter(nil)
    elseif funcId == FuncType.Skill then
        -- "技能
        local data = { _PageTag = "Tab_Skill" }
        self:Open("CPanelUISkill", data)
    elseif funcId == FuncType.Pet then
        -- "宠物
        self:Open("CPanelUIPetProcess", nil)
    elseif funcId == FuncType.Charm then
        -- "神符
        local data = { pageType = 1, data = nil }
        self:Open("CPanelCharm", data)
    elseif funcId == FuncType.Manual then
        -- "万物志
        self:Open("CPanelUIManual", {_type = 2})
    elseif funcId == FuncType.Guild then
        -- "工会
        --跨服判断
        if game._HostPlayer:IsInGlobalZone() then
            self:ShowTipText(StringTable.Get(15556), false)
            return
        end
        if game._GuildMan:IsHostInGuild() then 
            self:Open("CPanelUIGuild", _G.GuildPage.Info)
        else
            game._GuildMan:SendC2SGuildList()
        end
    elseif funcId == FuncType.Rank then
        -- "排行榜
        self:Open("CPanelRanking", 1)
    elseif funcId == FuncType.Shop then
        -- "商店
        local panelData =
        {
            OpenType = 1,
            ShopId = ENpcSaleServiceType.NpcSale_Grocery,
            SubShopId = 1,
            RepID = 2
        }
        self:Open("CPanelNpcShop", panelData)
        -- game._ShopMan:OpenNpcShop(1)
    elseif funcId == FuncType.Operation then
        -- "商店
        self:Open("CPanelUISetting", nil)
    elseif funcId == FuncType.Dungeon then
        -- 副本
        self:Open("CPanelUIDungeon", nil)
    elseif funcId == FuncType.Mall then
        -- 商城
        --TODO()
        self:Open("CPanelMall", nil)
--        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Mall, 0)
    elseif funcId == FuncType.Auction then
        -- 拍卖
        --TODO("敬请期待")
         self:Open("CPanelAuction", nil)
    elseif funcId == FuncType.Calendar then
        -- 冒险指南
        -- self:Open("CPanelAdventureGuide", nil)
        self:Open("CPanelCalendar", nil)        
        --CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Calendar, 0)
    elseif funcId == FuncType.Bonus then
        -- 福利
        self:Open("CPanelUIWelfare", nil)
    elseif funcId == FuncType.PVP then
        -- 斗技
        -- self:Open("CPanelArenaEnter", nil)
    elseif funcId == FuncType.Honor then
        -- 生涯
        -- self:Open("CPanelManual", nil)
        -- TODO("敬请期待")
        self:Open("CPanelUIManual", {_type = 1})
        -- game._CManualMan:SendC2SManualDataSync()
    elseif funcId == FuncType.Task then
        self:Open("CPanelUIQuestList", nil)
        -- CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Quest, 0)
    elseif funcId == FuncType.WingEnter then
        self:Open("CPanelUIWing", nil)
    elseif funcId == FuncType.Activity then
        self:Open("CPanelUIActivity", nil)
    elseif funcId == FuncType.Power then
        game._CPowerSavingMan:BeginSleeping()
    elseif funcId == FuncType.Summon then
        self:Open("CPanelSummon", nil)
    else
        warn("没有设置的功能界面，请检查ID:", funcId)
    end
end

--wraps

--def.method("boolean").HideMainCamera = function(self, flag)
--    self._UIManCore:HideMainCamera(flag)
--end

def.method("table","boolean").BlockMainCamera = function(self, ui,flag)
    self._UIManCore:BlockMainCamera(ui,flag)
end

def.method("number").RefUILight = function(self, count)
    self._UIManCore:RefUILight(count)
end

--Android回退键--
def.method("=>", "boolean").HandleEscapeKey = function(self)
	local b=self._UIManCore:HandleEscapeKey()
	--warn("HandleEscapeKey "..tostring(b))
    return b
end

CUIMan.Commit()
return CUIMan