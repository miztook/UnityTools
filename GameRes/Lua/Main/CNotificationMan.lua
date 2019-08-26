local Lplus = require "Lplus"
local CPanelInviteTip = require "GUI.CPanelInviteTip"
local ShowMainUIEvent = require "Events.ShowMainUIEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CNotificationMan = Lplus.Class("CNotificationMan")
do 
    local def = CNotificationMan.define

    def.field("table")._NotifyList = BlankTable
    def.field("number")._NotificationType = 0 --NotificationType.SystemNotify
--    def.field("boolean")._IsShowNotifyUI = false

    local instance = nil
    def.static('=>',CNotificationMan).Instance = function()
        if instance == nil then
            instance = CNotificationMan()
        end
        return instance
    end

    local function OnShowMainUI(sender, event)
        if event._IsShow then
            instance:NotifyUI()
        else
            CPanelInviteTip.Instance():CloseNotifyTip()
        end
    end

    def.method().Init = function(self)
        --print("CNotificationMan.Init()")
        CGame.EventManager:addHandler(ShowMainUIEvent, OnShowMainUI)
    end

    def.method().NotifyUI = function(self)
        self:RemoveExpired()
        if table.isEmpty(self._NotifyList) then
--            self._IsShowNotifyUI = false
            CPanelInviteTip.Instance():CloseNotifyTip()
        else
--            self._IsShowNotifyUI = true
            CPanelInviteTip.Instance():ShowNotifyTip()
        end
    end

    def.method("table").Add = function(self, notify)
        for _,v in ipairs(self._NotifyList) do
            if v:Compare(notify) then
                v:ResetBornTime(Time.time)
                return
            end
        end

        notify._BornTime = Time.time
        table.insert(self._NotifyList, 1, notify)
        if game._GUIMan:IsMainUIShowing() then
            self:NotifyUI()
        end
    end

    def.method("dynamic", "dynamic", "function").ShowNormalNotify = function(self, title, des, callback)
        local NotifyComponents = require "GUI.NotifyComponents"
        local notify = NotifyComponents.NormalNotify.new(title or "", des or "", callback)
        MsgNotify.Add(notify)
    end

    def.method("=>","table").Front = function(self)
        local notify = table.front(self._NotifyList)
        return notify
    end

    def.method("=>", "table").PopUp = function(self)
        local notify = table.pop_front(self._NotifyList)
        if notify._IsClickCancle then
            if notify._IsCancleRemoveSameType then
                self:Remove(notify._NotifyType)
            end
        else
            if notify._IsOkRemoveSameType then
                self:Remove(notify._NotifyType)
            end
        end
        return notify
    end

    -- 移除过期的notifys
    def.method().RemoveExpired = function(self)
        local now_time = Time.time
        for i = #self._NotifyList, 1, -1 do
            local v = self._NotifyList[i]
            if (now_time - v._BornTime) >= MsgNotify.DisappearTime then
                table.remove(self._NotifyList, i)
            end
        end
    end

    def.method("number").Remove = function(self, notifyType)
        local resultMap = {}
        for i=1, #self._NotifyList do
            local data = self._NotifyList[i]

            if data.Notify._NotifyType ~= notifyType then
                table.insert(resultMap, data)
            end
        end

        self._NotifyList = resultMap
        self:NotifyUI()
    end

    def.method().Cleanup = function(self)
        self._NotifyList = {}
        CGame.EventManager:removeHandler(ShowMainUIEvent, OnShowMainUI) 
    end

    --[[
        Local Notification
    ]]
    -- iOS需要申请权限
    def.method().RegisterLocalNotificationPermission = function(self)
        if _G.IsIOS() then
            GameUtil.RegisterLocalNotificationPermission()
        end
    end

    -- 注册本地消息推送
    def.method("string", "string", "number", "number", "boolean").RegisterLocalNotificationMessage = function(self, title, message, hour, minute, isRepeatDay)
        warn("RegisterLocalNotificationMessage : ", title, message, hour, minute, isRepeatDay)
        GameUtil.RegisterLocalNotificationMessage(title, message, hour, minute, isRepeatDay)
    end

    -- 清空本地消息推送
    def.method().CleanLocalNotification = function(self)
        GameUtil.CleanLocalNotification()
    end
end
CNotificationMan.Commit()
return CNotificationMan
