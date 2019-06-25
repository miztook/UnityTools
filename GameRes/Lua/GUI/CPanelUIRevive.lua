local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require 'Data.CElementData'
local EResurrectType = require "PB.net".ResurrectType
local MapBasicConfig = require "Data.MapBasicConfig"
local CPanelUIRevive = Lplus.Extend(CPanelBase, 'CPanelUIRevive')
local def = CPanelUIRevive.define

def.field('table')._PanelObject = BlankTable
def.field("number")._CountdownMax = 0               -- 倒计时
def.field("table")._InfoData = BlankTable           -- 外部参数
def.field("number")._TimerId = 0                    -- 计时器Id
def.field("boolean")._Inited = false                -- 是否初始化过

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local instance = nil
def.static('=>', CPanelUIRevive).Instance = function ()
    if not instance then
        instance = CPanelUIRevive()
        instance._PrefabPath = PATH.UI_Revive
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObject = {
        ReviveFrameList = {},
        Lab_KillerInfo = self:GetUIObject('Lab_KillerInfo'),
        Img_Drag = self:GetUIObject("Img_Drag"),
        Frame_DungeonDrag = self:GetUIObject("Frame_DungeonDrag"),
        Frame_QuitDungeon = self:GetUIObject("Frame_QuitDungeon"),
    }

    -- do
    --     self._PanelObject.Img_Drag:SetActive(true)
    --     self._PanelObject.Frame_DungeonDrag:SetActive(true)
    --     -- 设置拖拽位置
    --     GameUtil.SetUIAllowDrag(self._PanelObject.Img_Drag)
    --     for i = 1, 4 do
    --         local img_drag = self:GetUIObject("Img_Drag_" .. i)
    --         GameUtil.SetUIAllowDrag(img_drag)
    --     end
    -- end
    self._PanelObject.Img_Drag:SetActive(false)
    self._PanelObject.Frame_DungeonDrag:SetActive(false)
    
    do
        -- 复活页面 显示类型
        local root = self._PanelObject.ReviveFrameList
        root[EResurrectType.InPlaceFree]    = { Show = false }
        root[EResurrectType.InPlaceCharge]  = { Show = false }
        root[EResurrectType.SafeResurrent]  = { Show = false }
        root[EResurrectType.AutoRevive]     = { Show = false }
        root[EResurrectType.ReviveLimited]  = { Show = false }
        root[EResurrectType.TimesLimited]   = { Show = false }
    end

    do
        -- 立即复活免费 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.InPlaceFree]
        root.Root = self:GetUIObject('Frame_InPlaceFree')
    end

    do
        -- 钻石复活 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.InPlaceCharge]
        root.Root = self:GetUIObject('Frame_InPlaceCharge')
        root.Lab_ReviveLeftTimes = self:GetUIObject('Lab_ReviveLeftTimes')
        root.Lab_InPlaceChargeNeed = self:GetUIObject('Lab_InPlaceChargeNeed')
    end

    do
        -- 安全复活 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.SafeResurrent]
        root.Root = self:GetUIObject('Frame_Safe')
        root.Lab_ReviveDestination = self:GetUIObject('Lab_ReviveDestination')
        root.Lab_SafeTimeCounter = self:GetUIObject('Lab_SafeTimeCounter')
    end

    do
        -- 自动复活 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.AutoRevive]
        root.Root = self:GetUIObject('Frame_AutoRevive')
        root.Lab_AutoReviveTimeCounter = self:GetUIObject('Lab_AutoReviveTimeCounter')
    end

    do
        -- 复活限制 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.ReviveLimited]
        root.Root = self:GetUIObject('Frame_ReviveLimited')
    end

    do
        -- 复活次数用尽 组件
        local root = self._PanelObject.ReviveFrameList[EResurrectType.TimesLimited]
        root.Root = self:GetUIObject('Frame_TimesLimited')
    end
end

def.override("dynamic").OnData = function (self,data)
--[[
Parameters
----------
data: Table
    外部跳转装备类型, default: nil
    local data = 
    {
        CountDownMax,
        SceneId,
        RegionId,
        ButtonNeedShow,
    }
]]      
    if next(data) == nil then
        game._GUIMan:CloseByScript(self)
        return
    end

    self:UpdatePanel()
end

def.method("table").SetData = function(self, data)
    self._InfoData = data
end

def.method().UpdatePanel = function(self)
    if not self._Inited then
        --warn("复活：：初始化界面")

        -- 摄像机变灰
        GameUtil.SetCameraGreyOrNot(true)
        -- 设置拖拽遮罩
        -- self:SetDrag()
        -- 初始化界面
        self:InitFrame()
    else
        --warn("复活：： 重置界面")
        -- 重置界面
        self:ResetFrame( self._InfoData )
    end

    local hp = game._HostPlayer
    local bShowBtnQuitDungeon = hp:InDungeon() and
                                not hp:In1V1Fight() and
                                not hp:In3V3Fight() and
                                not hp:InEliminateFight()
    self._PanelObject.Frame_QuitDungeon:SetActive( bShowBtnQuitDungeon )
--[[
    local root = self._PanelObject.ReviveFrameList
    warn("InPlaceFree = ", root[EResurrectType.InPlaceFree].Show)
    warn("InPlaceCharge = ", root[EResurrectType.InPlaceCharge].Show)
    warn("SafeResurrent = ", root[EResurrectType.SafeResurrent].Show)
    warn("AutoRevive = ", root[EResurrectType.AutoRevive].Show)
    warn("ReviveLimited = ", root[EResurrectType.ReviveLimited].Show)
    warn("TimesLimited = ", root[EResurrectType.TimesLimited].Show)
]]
end
--[[
def.method("table").UpdatePanel = function(self, data)
    self._InfoData = data

    if not self._Inited then
        --warn("复活：：初始化界面")

        -- 摄像机变灰
        GameUtil.SetCameraGreyOrNot(true)
        -- 设置拖拽遮罩
        self:SetDrag()
        -- 初始化界面
        self:InitFrame()
    else
        --warn("复活：： 重置界面")
        -- 重置界面
        self:ResetFrame( data )
    end
    local root = self._PanelObject.ReviveFrameList
    warn("InPlaceFree = ", root[EResurrectType.InPlaceFree].Show)
    warn("InPlaceCharge = ", root[EResurrectType.InPlaceCharge].Show)
    warn("SafeResurrent = ", root[EResurrectType.SafeResurrent].Show)
    warn("AutoRevive = ", root[EResurrectType.AutoRevive].Show)
    warn("ReviveLimited = ", root[EResurrectType.ReviveLimited].Show)
    warn("TimesLimited = ", root[EResurrectType.TimesLimited].Show)

end
]]
-- 设置拖拽遮罩
def.method().SetDrag = function(self)
    local root = self._PanelObject
    if game._DungeonMan:InDungeon() then
        GUITools.SetUIActive(root.Img_Drag, false)
        GUITools.SetUIActive(root.Frame_DungeonDrag, true)
    else
        GUITools.SetUIActive(root.Img_Drag, true)
        GUITools.SetUIActive(root.Frame_DungeonDrag, false)
    end
end

def.method().InitFrame = function(self)
    do
        local root = self._PanelObject.ReviveFrameList
        local showInfo = self._InfoData.ButtonList
        root[EResurrectType.InPlaceFree].Show   = table.indexof(showInfo, EResurrectType.InPlaceFree) ~= false
        root[EResurrectType.InPlaceCharge].Show = table.indexof(showInfo, EResurrectType.InPlaceCharge) ~= false
        root[EResurrectType.SafeResurrent].Show = table.indexof(showInfo, EResurrectType.SafeResurrent) ~= false
        root[EResurrectType.AutoRevive].Show    = table.indexof(showInfo, EResurrectType.AutoRevive) ~= false
        root[EResurrectType.ReviveLimited].Show = table.indexof(showInfo, EResurrectType.ReviveLimited) ~= false
        root[EResurrectType.TimesLimited].Show = table.indexof(showInfo, EResurrectType.TimesLimited) ~= false
    end

    -- 初始化界面
    self:ReStartFrmaes()
    -- 设置刺杀者姓名 信息
    self:SetKillerName()

    self._Inited = true
end

-- 重置界面
def.method().ReStartFrmaes = function(self)
    local root = self._PanelObject.ReviveFrameList

    root[EResurrectType.InPlaceFree].Root:SetActive( root[EResurrectType.InPlaceFree].Show )
    root[EResurrectType.InPlaceCharge].Root:SetActive( root[EResurrectType.InPlaceCharge].Show )
    root[EResurrectType.SafeResurrent].Root:SetActive( root[EResurrectType.SafeResurrent].Show )
    root[EResurrectType.AutoRevive].Root:SetActive( root[EResurrectType.AutoRevive].Show )
    root[EResurrectType.ReviveLimited].Root:SetActive( root[EResurrectType.ReviveLimited].Show )
    root[EResurrectType.TimesLimited].Root:SetActive( root[EResurrectType.TimesLimited].Show )

    if root[EResurrectType.InPlaceFree].Show then self:Start_InPlaceFree() end
    if root[EResurrectType.InPlaceCharge].Show then self:Start_InPlaceCharge() end
    if root[EResurrectType.SafeResurrent].Show then self:Start_SafeResurrent() end
    if root[EResurrectType.AutoRevive].Show then self:Start_AutoRevive() end
    if root[EResurrectType.ReviveLimited].Show then self:Start_ReviveLimited() end
    if root[EResurrectType.TimesLimited].Show then self:Start_TimesLimited() end
end

def.method().SetKillerName = function(self)
    local root = self._PanelObject
    local str = string.format(StringTable.Get(1111), self._InfoData.KillerName)
    GUI.SetText(root.Lab_KillerInfo, str)
end

-- 原地复活免费
def.method().Start_InPlaceFree = function(self)
end

-- 原地复活收费
def.method().Start_InPlaceCharge = function(self)
    -- 获取配置 消耗
    local root = self._PanelObject.ReviveFrameList[EResurrectType.InPlaceCharge]

    local bActive = self._InfoData.ReviveLeftTimes + self._InfoData.ReviveMaxTimes > 0
    root.Lab_ReviveLeftTimes:SetActive( bActive )
    if bActive then
        local str = string.format(StringTable.Get(1112), self._InfoData.ReviveLeftTimes, self._InfoData.ReviveMaxTimes)
        GUI.SetText(root.Lab_ReviveLeftTimes, str)
    end

    GUI.SetText(root.Lab_InPlaceChargeNeed, tostring(self._InfoData.Cost))
end

-- 安全复活
def.method().Start_SafeResurrent = function(self)
    local root = self._PanelObject.ReviveFrameList[EResurrectType.SafeResurrent]
    local name = self:GetReviveDestinationName(self._InfoData.SceneId, self._InfoData.RegionId)
    local str = string.format(StringTable.Get(1114), name)
    GUI.SetText(root.Lab_ReviveDestination, str)
    -- 计时器
    self:AddTimer(self._InfoData.CountDownMax, root.Lab_SafeTimeCounter, StringTable.Get(1116))
end

-- 自动复活
def.method().Start_AutoRevive = function(self)
    local root = self._PanelObject.ReviveFrameList[EResurrectType.AutoRevive]
    -- 计时器
    self:AddTimer(self._InfoData.CountDownMax, root.Lab_AutoReviveTimeCounter, StringTable.Get(1115))
end

-- 复活限制
def.method().Start_ReviveLimited = function(self)
end

-- 复活次数限制
def.method().Start_TimesLimited = function(self)
end

-- 二次重置界面逻辑 页面切换
def.method("table").ResetFrame = function(self, data)
    local root = self._PanelObject.ReviveFrameList
    local showInfo = data.ButtonList

    local bNeedRemoveTimer = false
    bNeedRemoveTimer = (root[EResurrectType.SafeResurrent].Show and (table.indexof(showInfo, EResurrectType.SafeResurrent) == false)) or
                       (root[EResurrectType.AutoRevive].Show and (table.indexof(showInfo, EResurrectType.AutoRevive) == false))
    if bNeedRemoveTimer then
        self:RemoveTimer()
    end

    root[EResurrectType.InPlaceFree].Show   = table.indexof(showInfo, EResurrectType.InPlaceFree) ~= false
    root[EResurrectType.InPlaceCharge].Show = table.indexof(showInfo, EResurrectType.InPlaceCharge) ~= false
    root[EResurrectType.SafeResurrent].Show = table.indexof(showInfo, EResurrectType.SafeResurrent) ~= false
    root[EResurrectType.AutoRevive].Show    = table.indexof(showInfo, EResurrectType.AutoRevive) ~= false
    root[EResurrectType.ReviveLimited].Show = table.indexof(showInfo, EResurrectType.ReviveLimited) ~= false
    root[EResurrectType.TimesLimited].Show = table.indexof(showInfo, EResurrectType.TimesLimited) ~= false

    self:ReStartFrmaes()
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_InPlaceCharge' then
        self:OnBtnInPlaceChargeLogic()
    elseif id == 'Btn_InPlaceFree' then
        self:OnBtnInPlaceFreeLogic()
    elseif id == 'Btn_Safe' then
        self:OnBtnSafeLogic()
    elseif id == 'Btn_QuitDungeon' then
        self:OnBtnQuitDungeon()
    end
end

-- 钻石复活逻辑
def.method().OnBtnInPlaceChargeLogic = function(self)
    local hp = game._HostPlayer
    local EResourceType = require "PB.data".EResourceType
    local CTokenMoneyMan = require "Data.CTokenMoneyMan"
    
    local callback = function(val)
        if val then
            self:SendProtocol(EResurrectType.InPlaceCharge)
            game._GUIMan:CloseByScript(self)
        -- else
        --     SendFlashMsg(StringTable.Get(1113), false)
        end
    end

    local Do = function(ret)
        if ret then
            MsgBox.ShowQuickBuyBox(EResourceType.ResourceTypeBindDiamond, self._InfoData.Cost, callback)
        end
    end

    local title, msg, closeType = StringTable.GetMsg(109)
    local moneyName = CTokenMoneyMan.Instance():GetEmoji(EResourceType.ResourceTypeBindDiamond)
    msg = string.format(msg, moneyName,self._InfoData.Cost)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, Do)
end

-- 免费立即复活逻辑
def.method().OnBtnInPlaceFreeLogic = function(self)
    self:SendProtocol(EResurrectType.InPlaceFree)
    game._GUIMan:CloseByScript(self)
end

-- 安全复活逻辑
def.method().OnBtnSafeLogic = function(self)
    self:SendProtocol(EResurrectType.SafeResurrent)
    game._GUIMan:CloseByScript(self)
end

-- 退出副本逻辑
def.method().OnBtnQuitDungeon = function(self)
    -- 1V1不能退出，给提示
    if game._HostPlayer:In1V1Fight() then
        game._GUIMan:ShowTipText(StringTable.Get(20004), false) 
        return
    end
    -- 3V3不能退出，给提示
    if game._HostPlayer:In3V3Fight() then
        game._GUIMan: ShowTipText(StringTable.Get(20004),false)
        return
    end 
    -- 无畏战场不能退出
    if game._HostPlayer:InEliminateFight() then
        game._GUIMan: ShowTipText(StringTable.Get(20004),false)
        return
    end 

    local callback = function(value)
        local hp = game._HostPlayer
        if value then
            if hp:InDungeon() or hp:InImmediate() or game._HostPlayer:InPharse() then
                game._PlayerStrongMan:SetNeedPlayerStrong( true )
                game._DungeonMan:TryExitDungeon()
            end 
        end
    end
    local title,message = "",""
    local closeType = 0
    if game._HostPlayer:InImmediate() then
        title, message, closeType = StringTable.GetMsg(97)
    elseif game._HostPlayer:InPharse() then
        title, message, closeType = StringTable.GetMsg(82)
    elseif game._HostPlayer:InDungeon() then 
        if game._HostPlayer:IsInGlobalZone() then
            -- 跨服副本
            title, message, closeType = StringTable.GetMsg(131)
        else
            title, message, closeType = StringTable.GetMsg(17)
        end
    end
    MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

def.method("number").SendProtocol = function (self, iType)
    local C2SResurrect = require "PB.net".C2SResurrect
    local protocol = C2SResurrect()
    protocol.ResurrectType = iType

    SendProtocol(protocol)
end

-- 获取复活点名称
def.method('number', 'number', "=>", "string").GetReviveDestinationName = function (self, sceneId, regionId)
    local text = ""
    --local sceneTemplate = _G.MapBasicInfoTable[sceneId]
    local sceneTemplate = MapBasicConfig.GetMapBasicConfigBySceneID(sceneId)
    if sceneTemplate ~= nil then
        local posName = ""
        local regionRoot = sceneTemplate.Region
        if regionRoot ~= nil then
            for i, v in ipairs(regionRoot) do
                for j, k in pairs(v) do
                    if j == regionId then
                        posName = k.name
                        break
                    end
                end
            end
        end
        if posName == "" then
            posName = sceneTemplate.TextDisplayName
        end
        text = posName
    else
        warn("场景ID错误，ID： " .. sceneId)
    end

    return text
end

def.method("number", "userdata", "string").AddTimer = function (self, delta, labObj, fmtStr)
    self:RemoveTimer()

    local timerCount = delta
    self._TimerId = game._HostPlayer:AddTimer(1, false ,function()
        timerCount = timerCount - 1

        if timerCount <= 0 then
            game._HostPlayer:RemoveTimer(self._TimerId)
            game._GUIMan:CloseByScript(self)
        else
            local str = string.format(fmtStr, timerCount)
            GUI.SetText(labObj, str)
        end
    end)
end

def.method().RemoveTimer = function(self)
    if self._TimerId ~= 0 then
        game._HostPlayer:RemoveTimer(self._TimerId)
        self._TimerId = 0
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:RemoveTimer()
end

def.override().OnDestroy = function(self)
    self:RemoveTimer()
    self._Inited = false
    self._PanelObject = nil
end

CPanelUIRevive.Commit()
return CPanelUIRevive