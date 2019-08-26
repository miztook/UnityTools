--公会铁匠铺打造成功
--时间：2018/1/9
--Add by Yao

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUISmithyForgeSuccess = Lplus.Extend(CPanelBase, "CPanelUISmithyForgeSuccess")
local def = CPanelUISmithyForgeSuccess.define

local CElementData = require "Data.CElementData"

-- 界面
def.field("userdata")._TweenMan = nil
def.field("userdata")._Frame_Icon = nil
def.field("userdata")._Lab_BasicAttriTitle = nil
def.field("userdata")._Lab_BasicAttri = nil
def.field("userdata")._Frame_FixedAttri = nil
def.field("userdata")._List_FixedAttri = nil
def.field("userdata")._Frame_Legend = nil
def.field("userdata")._Lab_LegendTitle = nil
def.field("userdata")._Lab_LegendDesc = nil
def.field("userdata")._Btn_Next = nil
-- 缓存
def.field("table")._FixedAttriDatas = BlankTable
def.field("function")._CloseCallBack = nil
def.field("table")._UIFxDataList = BlankTable -- 特效信息列表
def.field("table")._UIFxTimerList = BlankTable -- 特效计时器列表

local instance = nil
def.static("=>", CPanelUISmithyForgeSuccess).Instance = function ()
	if instance == nil then
		instance = CPanelUISmithyForgeSuccess()
		instance._PrefabPath = PATH.UI_Guild_SmithyForgeSuccess
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self._TweenMan = self._Panel:GetComponent(ClassType.DOTweenPlayer)
	self._Frame_Icon = self:GetUIObject("Frame_EquipIcon")
	self._Lab_BasicAttriTitle = self:GetUIObject("Lab_BasicAttriTitle")
	self._Lab_BasicAttri = self:GetUIObject("Lab_BasicAttri")
	self._Frame_FixedAttri = self:GetUIObject("Frame_FixedAttri")
	self._List_FixedAttri = self:GetUIObject("List_FixedAttri"):GetComponent(ClassType.GNewList)
	self._Frame_Legend = self:GetUIObject("Frame_LegendAttri")
	self._Lab_LegendTitle = self:GetUIObject("Lab_LegendAttriTitle")
	self._Lab_LegendDesc = self:GetUIObject("Lab_LegendAttriDesc")
	self._Btn_Next = self:GetUIObject("Btn_Next")

    -- 初始化特效信息列表
    self._UIFxDataList =
    {
        [1] =
        {
            Delay = 0.5,
            Path = PATH.ETC_Fortify_Success_BG1,
            Root = self._Frame_Icon
        },
        [2] =
        {
            Delay = 0.7,
            Path = PATH.UIFX_DEV_Recast_Inc,
            Root = self:GetUIObject("Img_ResultTitle")
        },
    }
    for i=1, #self._UIFxDataList do
        self._UIFxTimerList[i] = 0
    end
end

-- data结构
-- @param	ItemDB			PB.net.ItemDB
-- @param	CloseCallBack	关闭回调
def.override("dynamic").OnData = function (self, data)
	if data == nil then return end
	self._CloseCallBack = data.CloseCallBack
	-- 属性
	self:ShowEquip(data.ItemDB)
	-- 动效和特效
	self:ShowEffect()
end

-- 设置装备属性
def.method("table").ShowEquip = function (self, itemDB)
	if itemDB == nil then return end

	local itemTemplate = CElementData.GetItemTemplate(itemDB.Tid)
	if itemTemplate == nil then return end
	self._Btn_Next:SetActive(false)
	-- 图标
	IconTools.InitItemIconNew(self._Frame_Icon, itemDB.Tid, { [EItemIconTag.Grade] = itemDB.FightProperty.star })

	-- 基础属性
	do
		local propertyGeneratorElement = CElementData.GetAttachedPropertyGeneratorTemplate( itemDB.FightProperty.index )
		if propertyGeneratorElement ~= nil then
			local fightElement = CElementData.GetAttachedPropertyTemplate( propertyGeneratorElement.FightPropertyId )
			if fightElement ~= nil then
				GUI.SetText(self._Lab_BasicAttriTitle, fightElement.TextDisplayName)
				GUI.SetText(self._Lab_BasicAttri, "+" .. itemDB.FightProperty.value)
			end
	    end
	end
	-- 附加属性
	do
		local fixedPorpGroupTemp = CElementData.GetAttachedPropertyGroupGeneratorTemplateMap(itemTemplate.AttachedPropertyGroupGeneratorId)
		local fixedPorpCountInfo = fixedPorpGroupTemp.CountData.GenerateCounts
		local fixedPorpMaxNum = fixedPorpCountInfo[#fixedPorpCountInfo].Count
		if fixedPorpMaxNum <= 0 or #itemDB.EquipBaseAttrs <= 0 then
			-- 属性生成器上限为0，或附加属性数量为0
			GUITools.SetUIActive(self._Frame_FixedAttri, false)
		else
			GUITools.SetUIActive(self._Frame_FixedAttri, true)
			self._FixedAttriDatas = {}
			for _, v in ipairs(itemDB.EquipBaseAttrs) do
				local generator = CElementData.GetAttachedPropertyGeneratorTemplate(v.index)
				local fightElement = CElementData.GetAttachedPropertyTemplate(generator.FightPropertyId)
				local data =
				{
					Name = fightElement.TextDisplayName,
					Value = v.value
				}
				table.insert(self._FixedAttriDatas, data)
			end
			self._List_FixedAttri:SetItemCount(#self._FixedAttriDatas)
		end
	end
	-- 传奇属性
	do
		if itemDB.TalentId == nil or itemDB.TalentId == 0 then
			-- 没有传奇属性
			GUITools.SetUIActive(self._Frame_Legend, false)
		else
			GUITools.SetUIActive(self._Frame_Legend, true)
			local talentInfo  = CElementData.GetSkillInfoByIdAndLevel(itemDB.TalentId, itemDB.TalentLevel, true)
			if talentInfo.Name ~= nil then
				GUI.SetText(self._Lab_LegendTitle, "[" .. talentInfo.Name .. "]")
			end
			if talentInfo.Desc ~= nil then
				GUI.SetText(self._Lab_LegendDesc, talentInfo.Desc)
			end
		end
	end
end

-- 展示动/特效
def.method().ShowEffect = function (self)
    self._TweenMan:Restart("ForgeSuccess")
	GameUtil.PlayUISfx(PATH.ETC_Fortify_Success_BG2, self._Panel, self._Panel, -1)
	self:RemoveUIFxTimers()
	for i, fxData in ipairs(self._UIFxDataList) do
        self._UIFxTimerList[i] = _G.AddGlobalTimer(fxData.Delay, true, function()
            GameUtil.PlayUISfx(fxData.Path, fxData.Root, fxData.Root, -1)
        end)
    end
end

def.override("string").OnClick = function (self, id)
	if string.find(id, "Btn_Next") then
		if self._CloseCallBack ~= nil then
			local cb = self._CloseCallBack
			cb()
			self._CloseCallBack = nil
		end
		game._GUIMan:CloseByScript(self)
	end
end

def.override("userdata", "string", "number").OnInitItem = function (self, item, id, index)
	if string.find(id, "List_FixedAttri") then
		-- 附加属性列表
		local data = self._FixedAttriDatas[index+1]
		-- 属性名
		local lab_title = GUITools.GetChild(item, 0)
		if not IsNil(lab_title) then
			GUI.SetText(lab_title, data.Name)
		end
		-- 属性值
		local lab_value = GUITools.GetChild(item, 1)
		if not IsNil(lab_value) then
			GUI.SetText(lab_value, tostring(data.Value))
		end
	end
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	if dot_id == "ForgeSuccess" then
		self._Btn_Next:SetActive(true)
	end
end

def.method().RemoveUIFxTimers = function (self)
    local length = #self._UIFxTimerList
    for i=1, length do
        local timer = self._UIFxTimerList[i]
        if timer > 0 then
            _G.RemoveGlobalTimer(timer)
            self._UIFxTimerList[i] = 0
        end
    end
end

def.override().OnDestroy = function (self)
	self:RemoveUIFxTimers()

	self._CloseCallBack = nil

	self._TweenMan = nil
	self._Frame_Icon = nil
	self._Lab_BasicAttriTitle = nil
	self._Lab_BasicAttri = nil
	self._Frame_FixedAttri = nil
	self._List_FixedAttri = nil
	self._Frame_Legend = nil
	self._Lab_LegendTitle = nil
	self._Lab_LegendDesc = nil
	self._Btn_Next = nil
end

CPanelUISmithyForgeSuccess.Commit()
return CPanelUISmithyForgeSuccess