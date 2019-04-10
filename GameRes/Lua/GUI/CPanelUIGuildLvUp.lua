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

def.field("userdata")._Lab_Title = nil
def.field("userdata")._Cur_Exp = nil
def.field("userdata")._Exp_Num = nil
def.field("userdata")._Now_Con_Lab = nil
def.field("userdata")._Next_Con_Lab = nil
def.field("userdata")._Frame_Cost = nil
def.field("userdata")._Img_Money_10 = nil
def.field("userdata")._Lab_CostMoney_10 = nil
def.field("userdata")._Img_Money_20 = nil
def.field("userdata")._Lab_CostMoney_20 = nil
def.field("userdata")._Frame_Own = nil
def.field("userdata")._Img_Money_11 = nil
def.field("userdata")._Lab_CostMoney_11 = nil
def.field("userdata")._Img_Money_21 = nil
def.field("userdata")._Lab_CostMoney_21 = nil
def.field("userdata")._Btn_Upgrade_Building = nil
def.field("userdata")._Lab_Remind = nil

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
	self._Building_Type = data._BuildingType
	local member = game._GuildMan:GetHostGuildMemberInfo()	
	if member == nil then return end	
	local guild = game._HostPlayer._Guild
	GUI.SetText(self._Lab_Title, data._Name)
	GUI.SetText(self._Now_Con_Lab, data._Des)	
	GUITools.SetTokenMoneyIcon(self._Img_Money_10, self._Fund_Tid)
	GUITools.SetTokenMoneyIcon(self._Img_Money_11, self._Fund_Tid)
	if data._Name == StringTable.Get(838) then
		self._Cur_Exp:SetActive(not data._IsMaxLevel)
		if data._IsMaxLevel then
			GUI.SetText(self._Next_Con_Lab, StringTable.Get(846))
			self._Frame_Cost:SetActive(false)
			self._Frame_Own:SetActive(false)
			self._Btn_Upgrade_Building:SetActive(false)
		else
			self._Btn_Upgrade_Building:SetActive(0 ~= bit.band(member._Permission, PermissionMask.LevelUp)) 											
			GUI.SetText(self._Lab_Remind, StringTable.Get(8064))
			self._Lab_Remind:SetActive(not (0 ~= bit.band(member._Permission, PermissionMask.LevelUp)))
			local nowGuild = CElementData.GetTemplate("GuildLevel", data._Tid)
            local exp_str = ""
            if game._HostPlayer._Guild._Exp <= 0 then
                exp_str = string.format(StringTable.Get(8114), game._HostPlayer._Guild._Exp, nowGuild.NextExperience)
            else
                exp_str = string.format(StringTable.Get(8115), game._HostPlayer._Guild._Exp, nowGuild.NextExperience)
            end
			GUI.SetText(self._Exp_Num, exp_str)
			GUI.SetText(self._Lab_CostMoney_10, tostring(nowGuild.Fund))
			local nextGuild = CElementData.GetTemplate("GuildLevel", data._Tid + 1)
			GUI.SetText(self._Next_Con_Lab, nextGuild.Description)
			if guild._Fund >= nowGuild.Fund then
				GUI.SetText(self._Lab_CostMoney_11, tostring(guild._Fund))	
			else
				GUI.SetText(self._Lab_CostMoney_11, string.format(StringTable.Get(8116), guild._Fund))
			end
		end
		self._Img_Money_20:SetActive(false)
		self._Lab_CostMoney_20:SetActive(false)
		self._Img_Money_21:SetActive(false)
		self._Lab_CostMoney_21:SetActive(false)
	else
		self._Cur_Exp:SetActive(false)
		if data._IsMaxLevel then
			GUI.SetText(self._Next_Con_Lab, StringTable.Get(849))
			self._Frame_Cost:SetActive(false)
			self._Frame_Own:SetActive(false)
			self._Btn_Upgrade_Building:SetActive(false)
			self._Lab_Remind:SetActive(false)
		else
			self._Btn_Upgrade_Building:SetActive(0 ~= bit.band(member._Permission, PermissionMask.UpgradeBuild))		
			local nowBuild = CElementData.GetTemplate("GuildBuildLevel", data._Tid)
			GUI.SetText(self._Lab_CostMoney_10, tostring(nowBuild.CostFund))
			if guild._Fund >= nowBuild.CostFund then
				GUI.SetText(self._Lab_CostMoney_11, tostring(guild._Fund))	
			else
				GUI.SetText(self._Lab_CostMoney_11, string.format(StringTable.Get(8116), guild._Fund))
			end
			GUI.SetText(self._Lab_CostMoney_20, tostring(nowBuild.CostEnergy))
			if guild._Energy >= nowBuild.CostEnergy then
				GUI.SetText(self._Lab_CostMoney_21, tostring(guild._Energy))
			else
				GUI.SetText(self._Lab_CostMoney_21, "<color=#ff412d>" .. guild._Energy .. "</color>")
			end
			GUITools.SetTokenMoneyIcon(self._Img_Money_20, self._Energy_Tid)
			GUITools.SetTokenMoneyIcon(self._Img_Money_21, self._Energy_Tid)
			local allBuild = CElementData.GetAllGuildBuildLevel()
			for i = 1, #allBuild do
				local buildLevel = CElementData.GetTemplate("GuildBuildLevel", allBuild[i])
				if buildLevel.BuildType == data._BuildingType then
					if buildLevel.BuildLevel == data._Level + 1 then
						GUI.SetText(self._Next_Con_Lab, buildLevel.Description)
						if 0 ~= bit.band(member._Permission, PermissionMask.UpgradeBuild) then
							if buildLevel.GuildLevel > guild._GuildLevel then
								self._Btn_Upgrade_Building:SetActive(false)
								self._Lab_Remind:SetActive(true)
								GUI.SetText(self._Lab_Remind, string.format(StringTable.Get(8061), buildLevel.GuildLevel))

							else
								self._Btn_Upgrade_Building:SetActive(true)
								self._Lab_Remind:SetActive(false)
							end
						end
					end
				end
			end
			self._Img_Money_20:SetActive(false)
			self._Lab_CostMoney_20:SetActive(false)
			self._Img_Money_21:SetActive(false)
			self._Lab_CostMoney_21:SetActive(false)
		end
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
	self._Cur_Exp = self:GetUIObject("Cur_Exp")
	self._Exp_Num = self:GetUIObject("Exp_Num")
	self._Now_Con_Lab = self:GetUIObject("Now_Con_Lab")
	self._Next_Con_Lab = self:GetUIObject("Next_Con_Lab")
	self._Frame_Cost = self:GetUIObject("Frame_Cost")
	self._Img_Money_10 = self:GetUIObject("Img_Money_10")
	self._Lab_CostMoney_10 = self:GetUIObject("Lab_CostMoney_10")
	self._Img_Money_20 = self:GetUIObject("Img_Money_20")
	self._Lab_CostMoney_20 = self:GetUIObject("Lab_CostMoney_20")
	self._Frame_Own = self:GetUIObject("Frame_Own")
	self._Img_Money_11 = self:GetUIObject("Img_Money_11")
	self._Lab_CostMoney_11 = self:GetUIObject("Lab_CostMoney_11")
	self._Img_Money_21 = self:GetUIObject("Img_Money_21")
	self._Lab_CostMoney_21 = self:GetUIObject("Lab_CostMoney_21")
	self._Btn_Upgrade_Building = self:GetUIObject("Btn_Upgrade_Building")
	self._Lab_Remind = self:GetUIObject("Lab_Remind")
end

-- 升级按钮
def.method().OnBtnUpgradeBuilding = function(self)
	if self._Building_Type == -1 then
		self:OnC2SGuildLevelUp()
	else
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