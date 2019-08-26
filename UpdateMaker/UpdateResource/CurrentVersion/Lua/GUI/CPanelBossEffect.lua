local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelBossEffect = Lplus.Extend(CPanelBase, 'CPanelBossEffect')
local def = CPanelBossEffect.define 

def.field("userdata")._HangPointTop = nil
def.field("userdata")._HangPointRight = nil
def.field("userdata")._HangPointBtm = nil
def.field("userdata")._HangPointLeft = nil
def.field("userdata")._HangPointMid = nil
def.field("number")._PanelGfxType = 0
def.field("string")._PanelGfxPath = ""

local instance = nil
def.static('=>', CPanelBossEffect).Instance = function ()
    if not instance then
        instance = CPanelBossEffect()
        instance._PrefabPath = PATH.UI_BossEffect
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

def.method("string", "userdata").PlayGfxOnHangPoint = function(self, path, parent)
    GameUtil.PlayUISfx(path, parent, parent, -1)
    self._PanelGfxPath = path
end


def.override('dynamic').OnData = function(self, data)
    local CElementSkill = require "Data.CElementSkill"
    local actor_template = CElementSkill.GetActor(data.ActorId)
    if actor_template == nil then 
        warn("template error occur in CPanelBossEffect data.ActorId = "..data.ActorId)
        return 
    end
    self._PanelGfxType = data.HangType
    if data.HangType == 0 then
        self:PlayGfxOnHangPoint(actor_template.GfxAssetPath, self._HangPointTop)
        self:PlayGfxOnHangPoint(actor_template.GfxAssetPath, self._HangPointRight)
        self:PlayGfxOnHangPoint(actor_template.GfxAssetPath, self._HangPointBtm)
        self:PlayGfxOnHangPoint(actor_template.GfxAssetPath, self._HangPointLeft)
    end
end

def.override().OnCreate = function(self)
    self._HangPointTop = self:GetUIObject('Point1')
    self._HangPointRight = self:GetUIObject('Point2')
    self._HangPointBtm = self:GetUIObject('Point3')
    self._HangPointLeft = self:GetUIObject('Point4')
    self._HangPointMid = self:GetUIObject('Point5')
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    if self._PanelGfxPath ~= "" then
        if self._PanelGfxType == 0 then
            GameUtil.StopUISfx(self._PanelGfxPath, self._HangPointTop)
            GameUtil.StopUISfx(self._PanelGfxPath, self._HangPointRight)
            GameUtil.StopUISfx(self._PanelGfxPath, self._HangPointBtm)
            GameUtil.StopUISfx(self._PanelGfxPath, self._HangPointLeft)
        end
    end

    self._PanelGfxPath = ""
    self._HangPointTop = nil
    self._HangPointRight = nil
    self._HangPointBtm = nil
    self._HangPointLeft = nil
    self._HangPointMid = nil
end

CPanelBossEffect.Commit()
return CPanelBossEffect