local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelInviteTip = Lplus.Extend(CPanelBase, 'CPanelInviteTip')
local def = CPanelInviteTip.define

def.field('userdata')._Lab_Tip = nil
def.field('userdata')._Lab_Cancle = nil
def.field("userdata")._Lab_DungeonName = nil
def.field("table")._CurrentNotify = nil
def.field("number")._AutoCancleTimer = 0
def.field("number")._StartTime = 0

local instance = nil
def.static('=>', CPanelInviteTip).Instance = function ()
	if not instance then
        instance = CPanelInviteTip()
        instance._PrefabPath = PATH.UI_TeamInviteTip
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = false
	instance._ForbidESC = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Lab_Tip = self:GetUIObject("Lab_InviteTip")
    self._Lab_Cancle = self:GetUIObject("Lab_Cancel")
    self._Lab_DungeonName = self:GetUIObject("Lab_InviteTarget")
end

def.override("dynamic").OnData = function(self,data)
	self._CurrentNotify = data
    self:UpdateTip()
    if self._CurrentNotify ~= nil then
        local all_time = MsgNotify.DisappearTime
        local left_time = math.ceil(all_time - (Time.time - self._CurrentNotify._BornTime))
        GUI.SetText(self._Lab_Cancle, string.format(StringTable.Get(22036), left_time))
    end
end

def.method().UpdateTip = function(self)
    if self._CurrentNotify == nil then return end
    local title = self._CurrentNotify:GetTitle()
    local des = self._CurrentNotify:GetDes()
    if title == nil or title == "" then
        self._Lab_Tip:SetActive(false)
    else
        self._Lab_Tip:SetActive(true)
        GUI.SetText(self._Lab_Tip, title)
    end

    GUI.SetText(self._Lab_DungeonName, self._CurrentNotify:GetDes())
end

def.method().ShowNotifyTip = function(self)
    local notify = MsgNotify.Front()
	if notify == nil then
        self._CurrentNotify = nil
        return
    end

    self._CurrentNotify = notify
    if self:IsShow() then
        self:UpdateTip()
    else
        game._GUIMan:Open("CPanelInviteTip", notify)
    end
    self:AddTimer()
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Msg_Invite, 0)
end

def.method().CloseNotifyTip = function(self)
	if self._AutoCancleTimer ~= 0 then
        _G.RemoveGlobalTimer(self._AutoCancleTimer)
        self._AutoCancleTimer = 0
    end
    game._GUIMan:CloseByScript(self)
end

def.method().AddTimer = function(self)
    if self._CurrentNotify == nil then return end
    if self._AutoCancleTimer ~= 0 then
        _G.RemoveGlobalTimer(self._AutoCancleTimer)
        self._AutoCancleTimer = 0
    end
    local callback = function()
        local all_time = MsgNotify.DisappearTime
        local left_time = math.ceil(all_time - (Time.time - self._CurrentNotify._BornTime))
        if left_time <= 0 then
            if self._AutoCancleTimer ~= 0 then
                _G.RemoveGlobalTimer(self._AutoCancleTimer)
                self._AutoCancleTimer = 0
            end
            if self._CurrentNotify ~= nil then
                self._CurrentNotify._IsClickCancle = true
                self._CurrentNotify:DONotify(not self._CurrentNotify._IsClickCancle)
            end
            MsgNotify.PopUp()
            MsgNotify.NotifyUI()
        end
        if self._Lab_Cancle then
            GUI.SetText(self._Lab_Cancle, string.format(StringTable.Get(22036), left_time))
        end
    end
    self._AutoCancleTimer = _G.AddGlobalTimer(1, false, callback)
end

def.override("string").OnClick = function(self,id)
	if id == "Btn_Ok" then
        if self._CurrentNotify ~= nil then
            self._CurrentNotify:DONotify(true)
            self._CurrentNotify._IsClickCancle = false
        end
        MsgNotify.PopUp()
        MsgNotify.NotifyUI()
    elseif id == "Btn_Cancel" then
        if self._CurrentNotify ~= nil then
            self._CurrentNotify:DONotify(false)
            self._CurrentNotify._IsClickCancle = true
        end
        MsgNotify.PopUp()
	    MsgNotify.NotifyUI()
	end
end

def.override().OnHide = function(self)
    if self._AutoCancleTimer ~= 0 then
        _G.RemoveGlobalTimer(self._AutoCancleTimer)
        self._AutoCancleTimer = 0
    end
end

def.override().OnDestroy = function(self)
    self._CurrentNotify = nil
    self._Lab_Tip = nil
    self._Lab_Cancle = nil
    self._Lab_DungeonName = nil
end

CPanelInviteTip.Commit()
return CPanelInviteTip