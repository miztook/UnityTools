--
--公会战场结束展示界面
--
--【孟令康】
--
--2018年08月06日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIGuildBattleEnd = Lplus.Extend(CPanelBase, "CPanelUIGuildBattleEnd")
local def = CPanelUIGuildBattleEnd.define

def.field("userdata")._Img_Success = nil
def.field("userdata")._Img_Failure = nil
def.field("userdata")._Img_Time = nil

def.field("number")._Timer_Id = 0
def.field("number")._Wait_Time = 3

local instance = nil
def.static("=>", CPanelUIGuildBattleEnd).Instance = function()
	if not instance then
		instance = CPanelUIGuildBattleEnd()
		instance._PrefabPath = PATH.UI_Guild_Battle_End
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:InitObject()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	if data.RewardState == 1 then
		self._Img_Success:SetActive(true)
		self._Img_Failure:SetActive(false)
		self._Img_Time:SetActive(false)	
		GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Vistory,self._Img_Success,self._Img_Success,-1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_GuildBFVictory, 0)
	elseif data.RewardState == 0 then
		self._Img_Success:SetActive(false)
		self._Img_Failure:SetActive(false)
		self._Img_Time:SetActive(true)	
		GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Tie,self._Img_Time,self._Img_Time,-1)
	else
		self._Img_Success:SetActive(false)
		self._Img_Failure:SetActive(true)
		self._Img_Time:SetActive(false)	
		GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Failed,self._Img_Failure,self._Img_Failure,-1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_GuildBFFail, 0)
	end
	local count = 0
	local callback = function()
		count = count + 1
		if count >= self._Wait_Time then
			game._GUIMan:CloseByScript(self)
			game._GUIMan:Open("CPanelUIGuildBattleResult", data)
			_G.RemoveGlobalTimer(self._Timer_Id)
		end
	end
	if self._Timer_Id == 0 then
		self._Timer_Id = _G.AddGlobalTimer(1, false, callback)
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	if self._Timer_Id ~= 0 then
		_G.RemoveGlobalTimer(self._Timer_Id)
        self._Timer_Id = 0
	end
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

def.method().InitObject = function(self)
	self._Img_Success = self:GetUIObject("Img_Success")
	self._Img_Failure = self:GetUIObject("Img_Failure")
	self._Img_Time = self:GetUIObject("Img_Time")
end

CPanelUIGuildBattleEnd.Commit()
return CPanelUIGuildBattleEnd