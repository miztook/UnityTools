--
-- 通用伤害面板
--
--【孟令康】
--
-- 2018年05月04日
--

-- 举例：
-- local data = {}
-- data._TotalHP = totalHp 总伤害
-- data._Info = info 服务器返回信息
-- game._GUIMan:Open("CPanelUIDamage", data)

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelUIDamage = Lplus.Extend(CPanelBase, "CPanelUIDamage")
local def = CPanelUIDamage.define

def.field("table")._Data = nil
def.field("number")._MaxDamage = 1
def.field("number")._TotalDamage = 0

local instance = nil
def.static("=>", CPanelUIDamage).Instance = function()
	if not instance then
		instance = CPanelUIDamage()
		instance._PrefabPath = PATH.UI_Damage
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	local count = #data._Info
	for i = 1, count do
		for j = i + 1, count do
			if data._Info[i].Damage < data._Info[j].Damage then
				local temp = data._Info[i]
				data._Info[i] = data._Info[j]
				data._Info[j] = temp
			end
		end
        if data._TotalHP == nil then
            self._TotalDamage = self._TotalDamage + data._Info[i].Damage
        end
        if data._Info[i].Damage > self._MaxDamage then
            self._MaxDamage = data._Info[i].Damage
        end
	end
    if data._TotalHP ~= nil then
        self._TotalDamage = data._TotalHP
    end
	self._Data = data
	self:GetUIObject("Damage_List"):GetComponent(ClassType.GNewList):SetItemCount(#self._Data._Info)
    self:UpdateSelfRankInfo()
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

-- 更新自己的排名UI
def.method().UpdateSelfRankInfo = function(self)
    local finded = false
    local index = 1
    local data = nil
    local host_id = game._HostPlayer._ID
    for i,v in ipairs(self._Data._Info) do
        if v.RoleId == host_id then
            finded = true
            index = i
            data = v
        end
    end
    local item = self:GetUIObject("Item_Player")
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local img_back = uiTemplate:GetControl(0)
    local img_ranking_back = uiTemplate:GetControl(1)
    local img_number = uiTemplate:GetControl(2)
    local img_exp = uiTemplate:GetControl(3)
    local lab_number = uiTemplate:GetControl(4)
    local lab_name = uiTemplate:GetControl(5)
    local img_job = uiTemplate:GetControl(6)
    local lab_damage = uiTemplate:GetControl(7)
    local lab_tip = uiTemplate:GetControl(8)
    if finded then
        if index <= 3 then
            img_back:SetActive(false)
            img_ranking_back:SetActive(true)
            img_number:SetActive(true)
            lab_number:SetActive(false)
            GUITools.SetGroupImg(img_ranking_back, index - 1)
            GUITools.SetGroupImg(img_number, index - 1)
        else
            img_back:SetActive(true)
            img_ranking_back:SetActive(false)
            img_number:SetActive(false)
            lab_number:SetActive(true)
            GUI.SetText(lab_number, tostring(index))
        end
        lab_tip:SetActive(false)
        lab_damage:SetActive(true)
        GUI.SetText(lab_name, data.RoleName)
--        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + data.ProfessionId - 1)))
        local professionTemplate = CElementData.GetProfessionTemplate(data.ProfessionId)
        if professionTemplate == nil then
	        warn("设置职业徽记时 读取模板错误：profession:", data.ProfessionId)
        else
	        GUITools.SetProfSymbolIcon(img_job, professionTemplate.SymbolAtlasPath)
        end
        GUITools.SetBtnExpressGray(item, false)
        img_exp:GetComponent(ClassType.Image).fillAmount = data.Damage/self._MaxDamage
        GUI.SetText(lab_damage, string.format(StringTable.Get(10685), GUITools.FormatPreciseDecimal(data.Damage/self._TotalDamage * 100, 2)))
    else
        img_number:SetActive(false)
        lab_number:SetActive(false)
        lab_tip:SetActive(true)
        local info_data = game._HostPlayer._InfoData
        GUI.SetText(lab_name, info_data._Name)
    --        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + data.ProfessionId - 1)))
        local professionTemplate = CElementData.GetProfessionTemplate(info_data._Prof)
        if professionTemplate == nil then
	        warn("设置职业徽记时 读取模板错误：profession:", info_data._Prof)
        else
	        GUITools.SetProfSymbolIcon(img_job, professionTemplate.SymbolAtlasPath)
        end
        GUITools.SetBtnExpressGray(item, true)
        img_exp:GetComponent(ClassType.Image).fillAmount = 0
        lab_damage:SetActive(false)
    end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
    if id == "Damage_List" then
        local data = self._Data._Info[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local img_back = uiTemplate:GetControl(0)
        local img_ranking_back = uiTemplate:GetControl(1)
        local img_number = uiTemplate:GetControl(2)
        local img_exp = uiTemplate:GetControl(3)
        local lab_number = uiTemplate:GetControl(4)
        local lab_name = uiTemplate:GetControl(5)
        local img_job = uiTemplate:GetControl(6)
        local lab_damage = uiTemplate:GetControl(7)
        if index <= 3 then
            img_back:SetActive(false)
            img_ranking_back:SetActive(true)
            img_number:SetActive(true)
            lab_number:SetActive(false)
            GUITools.SetGroupImg(img_ranking_back, index - 1)
            GUITools.SetGroupImg(img_number, index - 1)
        else
            img_back:SetActive(true)
            img_ranking_back:SetActive(false)
            img_number:SetActive(false)
            lab_number:SetActive(true)
            GUI.SetText(lab_number, tostring(index))
        end
        GUI.SetText(lab_name, data.RoleName)
--        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + data.ProfessionId - 1)))
        local professionTemplate = CElementData.GetProfessionTemplate(data.ProfessionId)
        if professionTemplate == nil then
	        warn("设置职业徽记时 读取模板错误：profession:", data.ProfessionId)
        else
	        GUITools.SetProfSymbolIcon(img_job, professionTemplate.SymbolAtlasPath)
        end

        img_exp:GetComponent(ClassType.Image).fillAmount = data.Damage/self._MaxDamage
        GUI.SetText(lab_damage, string.format(StringTable.Get(10685), GUITools.FormatPreciseDecimal(data.Damage/self._TotalDamage * 100, 2)))
    end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end


CPanelUIDamage.Commit()
return CPanelUIDamage