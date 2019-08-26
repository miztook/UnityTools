--
--公会护送对比界面
--
--【孟令康】
--
--2018年04月26日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CUIModel = require "GUI.CUIModel"
local ModelParams = require "Object.ModelParams"
local CPanelUIGuildConvoyVs = Lplus.Extend(CPanelBase, "CPanelUIGuildConvoyVs")
local def = CPanelUIGuildConvoyVs.define

def.field("userdata")._Img_Role_1 = nil
def.field(CUIModel)._Model_1 = nil
def.field("userdata")._Guild_Max_Num0 = nil
def.field("table")._Guild_Icon_Image_1 = nil
def.field("userdata")._Guild_Level_Num0 = nil
def.field("userdata")._Guild_Name0 = nil
def.field("userdata")._Guild_Des0 = nil
def.field("userdata")._Guild_Member_Num0 = nil
def.field("userdata")._Guild_Score_Num0 = nil
def.field("userdata")._Img_Role_2 = nil
def.field(CUIModel)._Model_2 = nil
def.field("userdata")._Guild_Max_Num1 = nil
def.field("table")._Guild_Icon_Image_2 = nil
def.field("userdata")._Guild_Level_Num1 = nil
def.field("userdata")._Guild_Name1 = nil
def.field("userdata")._Guild_Des1 = nil
def.field("userdata")._Guild_Member_Num1 = nil
def.field("userdata")._Guild_Score_Num1 = nil

local instance = nil
def.static("=>", CPanelUIGuildConvoyVs).Instance = function()
	if not instance then
		instance = CPanelUIGuildConvoyVs()
		instance._PrefabPath = PATH.UI_Guild_Convoy_Vs
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
	local params1 = ModelParams.new()
	params1:MakeParam(data.Self.Exterior, data.Self.ProfessionId)
	self._Model_1 = CUIModel.new(params1, self._Img_Role_1, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)
	self._Model_1:AddLoadedCallback(function() 
        self._Model_1:SetModelParam(self._PrefabPath, data.Self.ProfessionId)
        end)
	local icon1 = {}
	icon1[1] = data.Self.MatchInfo.GuildIcon.BaseColorID
	icon1[2] = data.Self.MatchInfo.GuildIcon.FrameID
	icon1[3] = data.Self.MatchInfo.GuildIcon.ImageID
	game._GuildMan:SetGuildIcon(icon1, self._Guild_Icon_Image_1)
	GUI.SetText(self._Guild_Max_Num0, data.Self.StrongestName)
	GUI.SetText(self._Guild_Level_Num0, tostring(data.Self.MatchInfo.Level))
	GUI.SetText(self._Guild_Name0, data.Self.MatchInfo.GuildName)
	GUI.SetText(self._Guild_Member_Num0, tostring(data.Self.MatchInfo.MemberNum))
	GUI.SetText(self._Guild_Score_Num0, tostring(data.Self.MatchInfo.FightScore))

	local params2 = ModelParams.new()
	params2:MakeParam(data.Other.Exterior, data.Other.ProfessionId)
	self._Model_2 = CUIModel.new(params2, self._Img_Role_2, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)
	self._Model_2:AddLoadedCallback(function() 
        self._Model_2:SetModelParam(self._PrefabPath, data.Other.ProfessionId)
        end)
	local icon2 = {}
	icon2[1] = data.Other.MatchInfo.GuildIcon.BaseColorID
	icon2[2] = data.Other.MatchInfo.GuildIcon.FrameID
	icon2[3] = data.Other.MatchInfo.GuildIcon.ImageID
	game._GuildMan:SetGuildIcon(icon2, self._Guild_Icon_Image_2)
	GUI.SetText(self._Guild_Max_Num1, data.Other.StrongestName)
	GUI.SetText(self._Guild_Level_Num1, tostring(data.Other.MatchInfo.Level))
	GUI.SetText(self._Guild_Name1, data.Other.MatchInfo.GuildName)
	GUI.SetText(self._Guild_Member_Num1, tostring(data.Other.MatchInfo.MemberNum))
	GUI.SetText(self._Guild_Score_Num1, tostring(data.Other.MatchInfo.FightScore))

	if data.Other.BaseInfo.IsAttacker then
		GUI.SetText(self._Guild_Des0, StringTable.Get(8074))
		GUI.SetText(self._Guild_Des1, StringTable.Get(8075))		
	else
		GUI.SetText(self._Guild_Des0, StringTable.Get(8075))
		GUI.SetText(self._Guild_Des1, StringTable.Get(8074))
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	if self._Model_1 then
		self._Model_1:Destroy()
		self._Model_1 = nil
	end
	if self._Model_2 then
		self._Model_2:Destroy()
		self._Model_2 = nil
	end
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Screen" then
		game._GUIMan:CloseByScript(self)
	end
end

def.method().OnInitObject = function(self)
	self._Img_Role_1 = self:GetUIObject("Img_Role_1")
	self._Guild_Max_Num0 = self:GetUIObject("Guild_Max_Num0")
	self._Guild_Icon_Image_1 = {}
	self._Guild_Icon_Image_1[1] = self:GetUIObject("Img_Flag0")
	self._Guild_Icon_Image_1[2] = self:GetUIObject("Img_Flag_Flower_10")
	self._Guild_Icon_Image_1[3] = self:GetUIObject("Img_Flag_Flower_20")
	self._Guild_Level_Num0 = self:GetUIObject("Guild_Level_Num0")
	self._Guild_Name0 = self:GetUIObject("Guild_Name0")
	self._Guild_Des0 = self:GetUIObject("Guild_Des0")
	self._Guild_Member_Num0 = self:GetUIObject("Guild_Member_Num0")
	self._Guild_Score_Num0 = self:GetUIObject("Guild_Score_Num0")
	self._Img_Role_2 = self:GetUIObject("Img_Role_2")
	self._Guild_Max_Num1 = self:GetUIObject("Guild_Max_Num1")
	self._Guild_Icon_Image_2 = {}
	self._Guild_Icon_Image_2[1] = self:GetUIObject("Img_Flag1")
	self._Guild_Icon_Image_2[2] = self:GetUIObject("Img_Flag_Flower_11")
	self._Guild_Icon_Image_2[3] = self:GetUIObject("Img_Flag_Flower_21")
	self._Guild_Level_Num1 = self:GetUIObject("Guild_Level_Num1")
	self._Guild_Name1 = self:GetUIObject("Guild_Name1")
	self._Guild_Des1 = self:GetUIObject("Guild_Des1")
	self._Guild_Member_Num1 = self:GetUIObject("Guild_Member_Num1")
	self._Guild_Score_Num1 = self:GetUIObject("Guild_Score_Num1")
end

CPanelUIGuildConvoyVs.Commit()
return CPanelUIGuildConvoyVs