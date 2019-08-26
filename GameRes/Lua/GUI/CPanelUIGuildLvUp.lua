--
-- 公会升级
--
--【孟令康】
--
-- 2018年1月4日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUIGuildLvUp = Lplus.Extend(CPanelBase, "CPanelUIGuildLvUp")
local def = CPanelUIGuildLvUp.define

def.field("number")._Fund_Tid = 10
def.field("number")._Energy_Tid = 26
-- 当前升级建筑类型
def.field("number")._Building_Type = 0
def.field("boolean")._IsLackExp = false
def.field("boolean")._IsLackFund = false

def.field("userdata")._Lab_Title = nil
def.field("userdata")._HallExp = nil
def.field("userdata")._Exp_Num = nil
def.field("userdata")._NextConLab = nil
def.field("userdata")._ImgCostMoney = nil
def.field("userdata")._LabCostMoney = nil
def.field("userdata")._Img_Money_21 = nil
def.field("userdata")._Lab_CostMoney_21 = nil
def.field("userdata")._Btn_Upgrade_Building = nil
def.field("userdata")._Lab_Remind = nil
def.field("userdata")._LabCurLevel = nil 
def.field("userdata")._LabNextLevel = nil 
def.field("userdata")._ExpBar = nil 
def.field("userdata")._FundBar = nil 
def.field("userdata")._FundNum = nil 

local instance = nil
def.static("=>", CPanelUIGuildLvUp).Instance = function()
	if not instance then
		instance = CPanelUIGuildLvUp()
		instance._PrefabPath = PATH.UI_Guild_LvUp
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitUIObject()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	if data._IsMaxLevel then 
		warn(" Guild is Max Level") 
		game._GUIMan:CloseByScript(self)
	return end
	self._Building_Type = data._BuildingType
	local member = game._GuildMan:GetHostGuildMemberInfo()	
	if member == nil then return end	
	self._IsLackFund = false
	self._IsLackExp = false
	local guild = game._HostPlayer._Guild
	GUI.SetText(self._Lab_Title, data._Name)
	GUI.SetText(self._LabCurLevel,string.format(StringTable.Get(8124), data._Level))
	GUITools.SetTokenMoneyIcon(self._ImgCostMoney, self._Fund_Tid)

	if data._Name == StringTable.Get(838) then
		self._HallExp:SetActive(not data._IsMaxLevel)
		GUI.SetText(self._LabNextLevel,string.format(StringTable.Get(8124), data._Level + 1))
		self._Btn_Upgrade_Building:SetActive(0 ~= bit.band(member._Permission, PermissionMask.LevelUp)) 											
		GUI.SetText(self._Lab_Remind, StringTable.Get(8064))
		self._Lab_Remind:SetActive(not (0 ~= bit.band(member._Permission, PermissionMask.LevelUp)))
		local nowGuild = CElementData.GetTemplate("GuildLevel", data._Tid)
        self._ExpBar.size = guild._Exp / nowGuild.NextExperience
		GUI.SetText(self._Exp_Num, guild._Exp .. "/" .. nowGuild.NextExperience)
        self._FundBar.size = guild._Fund / nowGuild.MaxGuildFund
		GUI.SetText(self._FundNum, guild._Fund .. "/" .. nowGuild.MaxGuildFund)
		local nextGuild = CElementData.GetTemplate("GuildLevel", data._Level + 1)
		GUI.SetText(self._NextConLab, nextGuild.Description)
		if guild._Exp < nowGuild.NextExperience then 
			self._IsLackExp = true
			local imgBg = self._Btn_Upgrade_Building:FindChild("Image")
			GameUtil.MakeImageGray(imgBg,true)
			GUITools.SetBtnExpressGray(self._Btn_Upgrade_Building, true)
			GUI.SetText(self._LabCostMoney, GUITools.FormatNumber(nowGuild.Fund))
			return
		end
		if guild._Fund < nowGuild.Fund then
			self._IsLackFund = true
			GUI.SetText(self._LabCostMoney, string.format(StringTable.Get(8116), GUITools.FormatNumber(nowGuild.Fund)))
		else
			GUI.SetText(self._LabCostMoney, GUITools.FormatNumber(nowGuild.Fund))
		end
	else
		self._HallExp:SetActive(false)
		GUI.SetText(self._LabNextLevel,string.format(StringTable.Get(8124), data._Level + 1))
		self._Btn_Upgrade_Building:SetActive(0 ~= bit.band(member._Permission, PermissionMask.UpgradeBuild))		
		local nowBuild = CElementData.GetTemplate("GuildBuildLevel", data._Tid)

		if guild._Fund >= nowBuild.CostFund then
			GUI.SetText(self._LabCostMoney, GUITools.FormatNumber(nowBuild.CostFund))	
		else
			self._IsLackFund = true
			GUI.SetText(self._LabCostMoney, string.format(StringTable.Get(8116), GUITools.FormatNumber(nowBuild.CostFund)))
		end
		local nowGuild = CElementData.GetTemplate("GuildLevel", guild._GuildLevel)
		self._FundBar.size = guild._Fund / nowGuild.MaxGuildFund
		GUI.SetText(self._FundNum, guild._Fund .. "/" .. nowGuild.MaxGuildFund)
		GUI.SetText(self._NextConLab, nowBuild.LevelUpDescription)
		self._Lab_Remind:SetActive(false)
			
	end
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Upgrade_Building" then
		self:OnBtnUpgradeBuilding()
	end
end


-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._Lab_Title = self:GetUIObject("Lab_Title")
	self._HallExp = self:GetUIObject("Hall_Exp")
	self._NextConLab = self:GetUIObject("Next_Con_Lab")
	self._ImgCostMoney = self:GetUIObject("Img_Money_10")
	self._LabCostMoney = self:GetUIObject("Lab_CostMoney_10")
	self._Btn_Upgrade_Building = self:GetUIObject("Btn_Upgrade_Building")
	self._Lab_Remind = self:GetUIObject("Lab_Remind")
	self._LabCurLevel = self:GetUIObject("Lab_CurLevel")
	self._LabNextLevel = self:GetUIObject("Lab_NextLevel")
	self._ExpBar = self:GetUIObject("Hall_Bar_Exp"):GetComponent(ClassType.Scrollbar)
	self._Exp_Num = self:GetUIObject("Exp_Num")
	self._FundBar = self:GetUIObject("Hall_Bar_Fund"):GetComponent(ClassType.Scrollbar)
	self._FundNum = self:GetUIObject("Fund_Num")
end

-- 升级按钮
def.method().OnBtnUpgradeBuilding = function(self)
	if self._Building_Type == -1 then
		if self._IsLackExp then 
			game._GUIMan:ShowTipText(StringTable.Get(807), true)
			return
		end
		if self._IsLackFund then 
			game._GUIMan:ShowTipText(StringTable.Get(8125), true)
			return
		end
		self:OnC2SGuildLevelUp()
	else
		if self._IsLackFund then 
			game._GUIMan:ShowTipText(StringTable.Get(8125), true)
			return
		end
		self:OnC2SGuildBuildingLevelUp(self._Building_Type)
	end
end

-- 公会升级
def.method().OnC2SGuildLevelUp = function(self)
	PBHelper.Send((require "PB.net".C2SGuildLevelUp)())
end

-- 建筑升级
def.method("number").OnC2SGuildBuildingLevelUp = function(self, buildingType)
	local protocol = (require "PB.net".C2SGuildBuildingLevelUp)()
	protocol.buildingType = buildingType
	PBHelper.Send(protocol)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

CPanelUIGuildLvUp.Commit()
return CPanelUIGuildLvUp