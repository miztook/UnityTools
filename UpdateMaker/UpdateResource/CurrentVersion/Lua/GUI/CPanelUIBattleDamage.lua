--
-- 通用战场伤害面板
--
--【孟令康】
--
-- 2018年08月02日
--

-- _Self:己方;_Other:敌方
-- 详细结构参见net.proto message GuildBattleFieldRank

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIBattleDamage = Lplus.Extend(CPanelBase, "CPanelUIBattleDamage")
local def = CPanelUIBattleDamage.define

def.field("table")._Self = nil
def.field("table")._Other = nil

def.field("userdata")._Img_D0 = nil
def.field("userdata")._Img_D1 = nil
def.field("userdata")._Img_U0 = nil
def.field("userdata")._Img_U1 = nil
def.field("userdata")._Damage_List = nil

local instance = nil
def.static("=>", CPanelUIBattleDamage).Instance = function()
	if not instance then
		instance = CPanelUIBattleDamage()
		instance._PrefabPath = PATH.UI_BattleDamage
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	local countS = #data._Self
	for i = 1, countS do
		for j = i + 1, countS do
			if data._Self[i].Dmg < data._Self[j].Dmg then
				local temp = data._Self[i]
				data._Self[i] = data._Self[j]
				data._Self[j] = temp
			end
		end
	end
	self._Self = data._Self
	local countO = #data._Other
	for i = 1, countO do
		for j = i + 1, countO do
			if data._Other[i].Dmg < data._Other[j].Dmg then
				local temp = data._Other[i]
				data._Other[i] = data._Other[j]
				data._Other[j] = temp
			end
		end
	end
	self._Other = data._Other

	self._Img_D0 = self:GetUIObject("Img_D0")
	self._Img_D1 = self:GetUIObject("Img_D1")
    self._Img_U0 = self:GetUIObject("Img_U0")
    self._Img_U1 = self:GetUIObject("Img_U1")
	self._Damage_List = self:GetUIObject("Damage_List"):GetComponent(ClassType.GNewList)

	self:OnBtnSelf()
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Self" then
		self:OnBtnSelf()
	elseif id == "Btn_Other" then
		self:OnBtnOther()
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "Damage_List" then
		local data = nil
		if self._Img_D0.activeSelf then
			data = self._Self[index]
		else
			data = self._Other[index]
		end
        local img_bg = uiTemplate:GetControl(7) or item:FindChild("Img_BG")
        if img_bg ~= nil then
            if data.RoleId == game._HostPlayer._ID then
                img_bg:SetActive(true)
            else
                img_bg:SetActive(false)
            end
        end
		GUI.SetText(uiTemplate:GetControl(0), tostring(index))
		GUI.SetText(uiTemplate:GetControl(1), data.Name)
		GUITools.SetGroupImg(uiTemplate:GetControl(2), data.Profession - 1)
		GUI.SetText(uiTemplate:GetControl(3), string.format(StringTable.Get(10714), data.Level))
		GUI.SetText(uiTemplate:GetControl(4), tostring(data.KillNum))
		GUI.SetText(uiTemplate:GetControl(5), tostring(data.DeathNum))
		GUI.SetText(uiTemplate:GetControl(6), tostring(data.Dmg))
	end
end

def.method().OnBtnSelf = function(self)
	self._Img_D0:SetActive(true)
	self._Img_D1:SetActive(false)
    self._Img_U0:SetActive(false)
    self._Img_U1:SetActive(true)
	self._Damage_List:SetItemCount(#self._Self)
end

def.method().OnBtnOther = function(self)
	self._Img_D0:SetActive(false)
	self._Img_D1:SetActive(true)
    self._Img_U0:SetActive(true)
    self._Img_U1:SetActive(false)
	self._Damage_List:SetItemCount(#self._Other)
end

CPanelUIBattleDamage.Commit()
return CPanelUIBattleDamage