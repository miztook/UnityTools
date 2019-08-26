
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIDungeonIntroduction = Lplus.Extend(CPanelBase, "CPanelUIDungeonIntroduction")
local def = CPanelUIDungeonIntroduction.define

local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"

-- 所有界面通用
def.field("userdata")._Lab_Title = nil
def.field("userdata")._Lab_Introduction = nil
def.field("userdata")._View_Skill = nil
def.field("userdata")._List_Skill = nil

def.field("table")._SkillIds = BlankTable

local instance = nil
def.static("=>", CPanelUIDungeonIntroduction).Instance = function ()
	if not instance then
		instance = CPanelUIDungeonIntroduction()
		instance._PrefabPath = PATH.UI_DungeonIntroduction
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Lab_Title = self:GetUIObject("Lab_Title")
	self._Lab_Introduction = self:GetUIObject("Lab_Introduction")
	self._View_Skill = self:GetUIObject("View_Skill")
	self._List_Skill = self:GetUIObject("List_Skill"):GetComponent(ClassType.GNewList)
end

-- @param data:副本介绍弹窗Tid
def.override("dynamic").OnData = function(self, data)
	if type(data) ~= "number" then
		game._GUIMan:CloseByScript(self)
		return
	end

	local popupTemplate = CElementData.GetTemplate("DungeonIntroductionPopup", data)
	if popupTemplate ~= nil then
		GUI.SetText(self._Lab_Title, popupTemplate.Name)
		GUI.SetText(self._Lab_Introduction, popupTemplate.Introduction)

		self._SkillIds = {}
		local skillIds = string.split(popupTemplate.SkillIds, "*")
		for _, id in ipairs(skillIds) do
			table.insert(self._SkillIds, tonumber(id))
		end
		if #self._SkillIds > 0 then
			GUITools.SetUIActive(self._View_Skill, true)
			self._List_Skill:SetItemCount(#self._SkillIds)
		else
			GUITools.SetUIActive(self._View_Skill, false)
		end
	end
end

def.override("string").OnClick = function(self, id)
	if string.find(id, "Btn_Back") then
		game._GUIMan:Close("CPanelUIDungeonIntroduction")
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_Skill") then
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end

		local id = self._SkillIds[index+1]
		local template = CElementSkill.Get(id)
		if template == nil then return end
		-- 图标
		local iconPath = CElementSkill.GetSkillIconFullPath(id)
		if iconPath ~= "" then
			local img_icon = uiTemplate:GetControl(0)
			GUITools.SetSprite(img_icon, iconPath)
		end
		-- 名称
		local lab_name = uiTemplate:GetControl(1)
		GUI.SetText(lab_name, template.Name)
		-- 描述
		local lab_desc = uiTemplate:GetControl(2)
		GUI.SetText(lab_desc, template.SkillDescription)
	end
end

def.override().OnDestroy = function(self)
	self._Lab_Title = nil
	self._Lab_Introduction = nil
	self._View_Skill = nil
	self._List_Skill = nil
end

CPanelUIDungeonIntroduction.Commit()
return CPanelUIDungeonIntroduction