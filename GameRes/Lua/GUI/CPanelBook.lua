local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local CDungeonAutoMan = require"Dungeon.CDungeonAutoMan"
local DynamicText = require "Utility.DynamicText"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"

local CPanelBook = Lplus.Extend(CPanelBase, 'CPanelBook')
local def = CPanelBook.define

def.field("userdata")._Title = nil
def.field("userdata")._Content = nil
def.field("userdata")._LabTime = nil
def.field("userdata")._LabWriter = nil
def.field("number")._CloseTimerId = 0


local instance = nil
def.static('=>', CPanelBook).Instance = function()
    if not instance then
        instance = CPanelBook()
        instance._PrefabPath = PATH.Panel_Book
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Title = self:GetUIObject('lab_Title')
    self._Content = self:GetUIObject('Lab_Content')
    self._LabTime = self:GetUIObject('Lab_Time')
    self._LabWriter = self:GetUIObject("Lab_Writer")
end

def.override("dynamic").OnData = function (self,data)
    local strTitle = DynamicText.ParseDialogueText(data.Title)
    local strContent = DynamicText.ParseDialogueText(data.Content)
    local closeInterval = data.Interval

    GUI.SetText(self._Title, strTitle)
    GUI.SetText(self._Content, strContent)

    if closeInterval <= 0 then
        closeInterval = 30
    end

    if not IsNil(self._LabWriter) then
        if data.writter == "" or data.writter == nil then
            self._LabWriter:SetActive(false)
        else
            self._LabWriter:SetActive(true)
            GUI.SetText(self._LabWriter,data.writter)
        end
    end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Book, 0)

    self._CloseTimerId = _G.AddGlobalTimer(1, false, function()
        closeInterval = closeInterval - 1
        local strTime = string.format(StringTable.Get(926), closeInterval)
        GUI.SetText(self._LabTime, strTime)   

        if closeInterval <= 0 then            
            game._GUIMan:CloseByScript(self)
        end
    end)

    CQuestAutoMan.Instance():Pause(_G.PauseMask.UIShown)
    CDungeonAutoMan.Instance():Pause(_G.PauseMask.UIShown)
    CAutoFightMan.Instance():Pause(_G.PauseMask.UIShown)
end

def.override("string").OnClick = function(self, id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    if self._CloseTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._CloseTimerId)
        self._CloseTimerId = 0         
    end
    CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
    CDungeonAutoMan.Instance():Restart(_G.PauseMask.UIShown)
    CAutoFightMan.Instance():Restart(_G.PauseMask.UIShown)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Close_Book, 0)
end

def.override().OnDestroy = function (self)
    self._Title = nil
    self._Content = nil
    self._LabTime = nil
    self._LabWriter = nil
end

CPanelBook.Commit()
return CPanelBook