--[[
						副本NPC对话
								----by luee 2017.3.14
]]
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local DynamicText = require "Utility.DynamicText"
local CPanelDungeonNpcTalk = Lplus.Extend(CPanelBase, "CPanelDungeonNpcTalk")
local def = CPanelDungeonNpcTalk.define
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

--控件
def.field("userdata")._Img_Head  = nil
def.field("userdata")._Lab_NpcName = nil
def.field("userdata")._Lab_Dialog = nil

--数据
def.field('table')._Table_NpcDialog = BlankTable -- NPC对话
def.field("number")._Timer_Dialog = 0 --倒计时
def.field("number")._Index = 1 --对话索引

def.field("boolean")._IsResetTraker = true

local instance = nil
def.static("=>",CPanelDungeonNpcTalk).Instance = function ()
	if not instance then
        instance = CPanelDungeonNpcTalk()
        instance._PrefabPath = PATH.Panel_DungeonNpcTalk
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

	return instance
end

def.override().OnCreate = function(self)
	self._Img_Head = self:GetUIObject("Img_Head")
	self._Lab_NpcName = self:GetUIObject("Lab_NameLeft")
	self._Lab_Dialog = self:GetUIObject("Lab_DialogLeft")
end

local ClosePanel = function()
  if instance._Timer_Dialog > 0 then
	   _G.RemoveGlobalTimer(instance._Timer_Dialog)
      instance._Timer_Dialog = 0
	end
	instance._Table_NpcDialog = {}
	
	game._GUIMan:Close("CPanelDungeonNpcTalk")
end

def.method("number").SetNpcImg = function(self, NpcID)
  if NpcID <= 0 or NpcID == nil then return end

  local NpcTem  = CElementData.GetNpcTemplate(NpcID)
    if NpcTem == nil then 
       warn("NpcID: "..NpcID.."模板数据错误")
      return
    end

    if not IsNil(self._Lab_NpcName) then
      GUI.SetText(self._Lab_NpcName, NpcTem.TextOverlayDisplayName)
    end

    if not IsNil(self._Img_Head) then
      local strIcon = "Assets/Outputs/"..NpcTem.HalfPortrait..".png"
      GUITools.SetSprite(self._Img_Head, strIcon)
    end
end

def.method().SetDialog = function(self)
	if self._Table_NpcDialog == nil or #self._Table_NpcDialog < self._Index then
		ClosePanel()
	return end
  self: SetNpcImg(self._Table_NpcDialog[self._Index].Default.ModelId)
	
  GUI.SetText(self._Lab_Dialog, DynamicText.ParseDialogueText(self._Table_NpcDialog[self._Index].Default.TextContent))

  local sound = self._Table_NpcDialog[self._Index].Default.AudioAssetPath
  
  if not IsNilOrEmptyString(sound) then
      CSoundMan.Instance():Play3DVoice(sound, game._HostPlayer:GetPos(),0)
  else
      CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(),0)
  end

	if self._Timer_Dialog > 0 then
    _G.RemoveGlobalTimer(self._Timer_Dialog)
    self._Timer_Dialog = 0
  end

  local fTime = self._Table_NpcDialog[self._Index].MaxDuration/1000
  fTime = math.max(1, fTime)--防止填错是0的情况，默认最少有1秒
  self._Timer_Dialog = _G.AddGlobalTimer(fTime, true, function()
    self: SetDialog()
  end)  
	self._Index = self._Index + 1
end

--data = 对话ID
def.override("dynamic").OnData = function(self, data)
  self._Index = 1
  self._IsResetTraker = true
	if data == nil then 
		game._GUIMan:CloseByScript(self)
    warn("CPanelDungeonNpcTalk Data is nil")
	return end	

    local DialogTem = CElementData.GetDialogueTemplate(data) 
    if DialogTem == nil then
    	FlashTip("对话模板ID:"..data.."错误","tip",1)
    	ClosePanel()
    return end

  	self._Table_NpcDialog = DialogTem.Sentences
  	self: SetDialog()  
end

def.override("string").OnClick = function(self, id)
    if id == "btn_Click" then
      if self._Timer_Dialog > 0 then
          _G.RemoveGlobalTimer(self._Timer_Dialog)
          self._Timer_Dialog = 0
      end
      self: SetDialog()
    return end
end

def.method().HidePanelNotResetTracker = function(self)
  self._IsResetTraker = false
  ClosePanel()
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._Timer_Dialog = 0 --倒计时
    self._Index = 1 --对话索引
    if self._IsResetTraker then
      local CPanelTracker = require "GUI.CPanelTracker"
      CPanelTracker.Instance():ShowSelfPanel(true)
    end

    self._IsResetTraker = true
end

def.override().OnDestroy = function (self)
    self._Img_Head = nil
    self._Lab_NpcName = nil
    self._Lab_Dialog = nil

    self._Table_NpcDialog = nil
    if self._Timer_Dialog > 0 then
       _G.RemoveGlobalTimer(self._Timer_Dialog)
        self._Timer_Dialog = 0
    end
end

CPanelDungeonNpcTalk.Commit()
return CPanelDungeonNpcTalk