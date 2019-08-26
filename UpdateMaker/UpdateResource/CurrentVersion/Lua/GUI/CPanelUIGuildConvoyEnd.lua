--
--公会护送结束展示界面
--
--【孟令康】
--
--2018年04月26日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local EConvoyFailReason = require "PB.net".EConvoyFailReason
local CPanelUIGuildConvoyEnd = Lplus.Extend(CPanelBase, "CPanelUIGuildConvoyEnd")
local def = CPanelUIGuildConvoyEnd.define

def.field("userdata")._Img_Success = nil
def.field("userdata")._Img_Failure = nil
def.field("userdata")._Img_Time = nil

def.field("number")._Timer_Id = 0
def.field("number")._Wait_Time = 3

local instance = nil
def.static("=>", CPanelUIGuildConvoyEnd).Instance = function()
	if not instance then
		instance = CPanelUIGuildConvoyEnd()
		instance._PrefabPath = PATH.UI_Guild_Convoy_End
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitObject()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	if data.IsWin then
		self._Img_Success:SetActive(true)
		self._Img_Failure:SetActive(false)
		self._Img_Time:SetActive(false)	
		GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Vistory,self._Img_Success,self._Img_Success,-1)
	else
		if data.FailReason == EConvoyFailReason.EConvoyFailReason_TimeOut then
			self._Img_Success:SetActive(false)
			self._Img_Failure:SetActive(false)
			self._Img_Time:SetActive(true)	
			GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Tie,self._Img_Time,self._Img_Time,-1)
		else
			self._Img_Success:SetActive(false)
			self._Img_Failure:SetActive(true)
			self._Img_Time:SetActive(false)	
			GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_End_Sfx_Failed,self._Img_Failure,self._Img_Failure,-1)
		end
	end
	local count = 0
	local callback = function()
		count = count + 1
		if count >= self._Wait_Time then
			game._GUIMan:CloseByScript(self)
			game._GUIMan:Open("CPanelUIGuildConvoyResult", data)
			_G.RemoveGlobalTimer(self._Timer_Id)
		end
	end
	if self._Timer_Id == 0 then
		self._Timer_Id = _G.AddGlobalTimer(1, false, callback)
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	self._Img_Success = nil
	self._Img_Failure = nil
	self._Img_Time = nil

	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

def.method().OnInit = function(self)
end

def.method().OnInitObject = function(self)
	self._Img_Success = self:GetUIObject("Img_Success")
	self._Img_Failure = self:GetUIObject("Img_Failure")
	self._Img_Time = self:GetUIObject("Img_Time")
end

CPanelUIGuildConvoyEnd.Commit()
return CPanelUIGuildConvoyEnd