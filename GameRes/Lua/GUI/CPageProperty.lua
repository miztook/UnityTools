local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = Lplus.ForwardDeclare("CPanelRoleInfo")
local EntityEvilNumChangeEvent = require "Events.EntityEvilNumChangeEvent"
local CPageProperty = Lplus.Class("CPageProperty")
local def = CPageProperty.define

def.field("userdata")._Panel = nil
def.field("table")._PanelObject = BlankTable
def.field("table")._BtnList1 = nil 
def.field("table")._BtnList2 = nil 

def.field("boolean")._IsBaseProperty = false


local instance = nil
def.static("=>", CPageProperty).Instance = function()
	if instance == nil then
        instance = CPageProperty()
	end
	return instance
end

local OnEntityEvilNumChangeEvent = function (sender, event)
    if instance ~= nil then
    end
end

def.method("table", "userdata").Show = function(self, linkInfo, root)
        self._Panel = root              --该分解的root 节点
        self._PanelObject = linkInfo    --存储引用的table在上层传递进来
        self._PanelObject._FrameDetailInfo:SetActive(false)
        --GameUtil.SetCanvasGroupAlpha(self._PanelObject._FrameDetailInfo,0)
        self._PanelObject._FrameBaseInfo:SetActive(true)
        GameUtil.SetCanvasGroupAlpha(self._PanelObject._FrameBaseInfo,1)
        --local doTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
	--doTweenPlayer:Restart("BaseInfoAppear")
        self._IsBaseProperty = true
	self._BtnList1 = {}
	self._BtnList2 = {}
	self:UpdatePageProperty()
end

def.method().UpdatePageProperty = function(self)
	
	if self._Panel == nil then return end

	local info_data = game._HostPlayer._InfoData
	-- GUI.SetText(self._PanelObject._LabRoleName,info_data._Name)
	self._PanelObject._ImgUpArrow:SetActive(true)
	self._PanelObject._ImgDownArrow:SetActive(false)
	GUI.SetText(self._PanelObject._LabLevel,string.format(StringTable.Get(21508), info_data._Level))
	GUI.SetText(self._PanelObject._LabEvilValue,tostring(game._HostPlayer:GetEvilValue()))
	local professionTemplate = CElementData.GetProfessionTemplate(info_data._Prof)
	GUI.SetText(self._PanelObject._LabJob,professionTemplate.Name )
	
	self:UpdateGuildInfo()
	-- -- 更新称号
	-- self:UpdateHostPlayerTitle()
	self:UpdateExp()
	self._PanelObject._FrameDetailInfo:SetActive(false)
	self:UpdateCustomHead()
	self:UpdateBaseProperty()
end

def.method().UpdateGuildInfo = function(self)
	-- 工会名称
	if not game._GuildMan:IsHostInGuild() then 
		GUI.SetText(self._PanelObject._LabGuild,StringTable.Get(21501))
	else
		GUI.SetText(self._PanelObject._LabGuild,game._HostPlayer._Guild._GuildName) 
	end 
end

def.method().UpdateCustomHead = function(self)
	--设置头像
	local hp = game._HostPlayer
	game: SetEntityCustomImg(self._PanelObject._ImgHead,hp._ID,hp._InfoData._CustomImgSet,hp._InfoData._Gender,hp._InfoData._Prof)
end

def.method().UpdateExp = function(self)
	local info_data = game._HostPlayer._InfoData
	local levelUpExpTemplate = CElementData.GetLevelUpExpTemplate(info_data._Level)
	local value = info_data._Exp / levelUpExpTemplate.Exp
	GUI.SetText(self._PanelObject._LabBldExp, string.format(StringTable.Get(21518), info_data._Exp,levelUpExpTemplate.Exp))
	self._PanelObject._BldExp.value = value
end

def.method().UpdateEvil = function (self)
	GUI.SetText(self._PanelObject._LabEvilValue,tostring(game._HostPlayer:GetEvilValue()))
	-- body
end

-- --改变称号
-- def.method().UpdateTitle = function(self)
-- 	--称号
-- 	local titleName = game._HostPlayer._InfoData._TitleName
-- 	if titleName == "" then 
-- 		GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21505))
-- 	else
-- 		GUI.SetText(self._PanelObject._LabTitle,titleName)
-- 	end
-- end

-- 通过事件更新角色信息所有数据信息
def.method().UpdateDatePropertyValue = function(self)
	if IsNil(self._Panel) then return end

	if self._IsBaseProperty then
		self:UpdateBaseProperty()
	else
		self:UpdateOtherProperty()
	end
end

-- 更新属性下的基础数据
def.method().UpdateBaseProperty = function(self)
	--基础属性
	local nameList = 
	{
		"002","003","004","005",
		"010","011","030","032","034","069",
		"096","075","050","051",
	}
	
	local Img_LittleBG = self._PanelObject._RoleDataInfoList:FindChild("Img_LittleBG")
	self:SetPropertyData(Img_LittleBG, nameList,true)
end

def.method().UpdateOtherProperty = function(self) ----subList2
	local subProperty = self._PanelObject._Property
	local nameList = {}

	--伤害
	do
		nameList = 
		{
			"010","080","030","032","096","050",
		}
		self:SetPropertyData(self._PanelObject._ImgLittleBG1, nameList,false)
	end

	--生存
	do
		nameList = 
		{
			"069","011","034","070","075","051",
		}
		self:SetPropertyData(self._PanelObject._ImgLittleBG2, nameList,false)
	end

	--元素伤害
	do
		nameList = 
		{
			"012","084","013","086","014","088",
			"015","090","016","092","017","094",
		}
		self:SetPropertyData(self._PanelObject._ImgLittleBG3, nameList,false)
	end

	-- 元素抗性
	do
		nameList = 
		{
			"018","019","020","021","022","023",
		}
		self:SetPropertyData(self._PanelObject._ImgLittleBG4, nameList,false)
	end
end

--设置属性的函数，按照现有结构定义。UE修改结构，此方法将不能适用。
def.method("userdata", "table","boolean").SetPropertyData = function(self, obj, nameList,IsBaseProperty)
	local info_data = game._HostPlayer._InfoData._FightProperty
	local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	for i,v in ipairs(nameList) do
		local enumIndex = tonumber(v)
		local objProperty = nil
		if not IsBaseProperty then 
			if self._BtnList2[enumIndex] == nil then
				local strProperty = string.format("%s%s%s%s", "properties_", v, "/Lab_", v)
				objProperty = obj:FindChild(strProperty)
				self._BtnList2[enumIndex] = objProperty
			else
				objProperty = self._BtnList2[enumIndex]
			end
		else
			if self._BtnList1[enumIndex] == nil then
				local strProperty = string.format("%s%s%s%s", "properties_", v, "/Lab_", v)
				objProperty = obj:FindChild(strProperty)
				self._BtnList1[enumIndex] = objProperty
			else
				objProperty = self._BtnList1[enumIndex]
			end
		end	
		local strValue = string.format("%s%s%s%s%s%s", "properties_", v, "/Img_Data", v, "/Lab_Number", v)
		local objValue = obj:FindChild(strValue)
		
		--读取数据,显示格式,显示属性名称
		if not IsNil(objProperty) and not IsNil(objValue) then
			
			local data = CElementData.GetTemplate("FightPropertyConfig", enumIndex)
			if data == nil then return end

			local valueData = info_data[enumIndex]
			local valueTotal = valueData[1]
			local valueIncrease = valueData[2]
			GUI.SetText(objProperty, data.AttrName)
			
			local strTotal = ""
			if string.sub(data.ValueFormat, -1) == "%" then
				valueTotal = valueTotal * 100

				if string.find(data.ValueFormat, "f") then
					-- 取小数
					if string.find(data.ValueFormat, ".1f") then
						valueTotal = fixFloat(valueTotal, 1)
					elseif string.find(data.ValueFormat, ".2f") then
						valueTotal = fixFloat(valueTotal, 2)
					end
				end
				strTotal = GUITools.FormatNumber(valueTotal)
				strTotal = string.format(StringTable.Get(10981), strTotal)
			else
				
				if string.find(data.ValueFormat, "f") then
					-- 取小数
					if string.find(data.ValueFormat, ".1f") then
						valueTotal = fixFloat(valueTotal, 1)
					elseif string.find(data.ValueFormat, ".2f") then
						valueTotal = fixFloat(valueTotal, 2)
					end
					-- 数值格式化 逗号
					strTotal = GUITools.FormatNumber(valueTotal)
					-- 加百分号
					if string.find(data.ValueFormat, "%%") then
						strTotal = string.format(StringTable.Get(10981), strTotal)
					end
				elseif string.find(data.ValueFormat, "d") then
					valueTotal = fixFloat(valueTotal, 0)
					strTotal = GUITools.FormatNumber(valueTotal)
				end
			end

			GUI.SetText(objValue, strTotal)

			local Img_Arrow = objValue:FindChild("Img_Arrow")
			Img_Arrow:SetActive(valueIncrease ~= 0)
			if valueIncrease == 0 then
			elseif valueIncrease > 0 then
				GUITools.SetGroupImg(Img_Arrow, 2)
			elseif valueIncrease < 0 then
				GUITools.SetGroupImg(Img_Arrow, 0)
			end
		end
	end
end

def.method("number").ShowPropertyTip = function(self, index)
	local Object = nil 
	if not self._IsBaseProperty  then 
		if self._BtnList2[index] == nil then return end
		Object = self._BtnList2[index].parent
	else
		if self._BtnList1[index] == nil then return end
		Object = self._BtnList1[index].parent
	end
	local data = CElementData.GetTemplate("FightPropertyConfig", index)
	if data == nil or data.DetailDesc == "" then return end

	local cnt = 0
	local replaceIdStr = data.ReplaceIdStr
	local strIds = {}

	if replaceIdStr ~= nil and replaceIdStr ~= "" then
		strIds = string.split(replaceIdStr, "*")
		cnt = #strIds
	end

	local exchangeIndex1 = index
	local exchangeIndex2 = 0
	local strDesc = ""

	if cnt == 1 then
		exchangeIndex1 = tonumber(strIds[1])
	elseif cnt == 2 then
		exchangeIndex1 = tonumber(strIds[1])
		exchangeIndex2 = tonumber(strIds[2])
	end

	local info_data = game._HostPlayer._InfoData._FightProperty
	local value = info_data[exchangeIndex1][1]
	if value == nil then return end

	if exchangeIndex2 == 0 then
		local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
		local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
		if config ~= nil and config.DESC ~= nil and config.DESC[index] ~= nil then
			strDesc = config.DESC[index][game._HostPlayer._InfoData._Prof]
		else
			local exchangeData = CElementData.GetTemplate("FightPropertyConfig", exchangeIndex1)
			if string.sub(exchangeData.ValueFormat, -1) == "%" then
				value = value * 100
			end
			
			strDesc = string.format(data.DetailDesc, value)
		end		
	else
		local value1 = value*100
		local value2 = info_data[exchangeIndex2][1]*100
		strDesc = string.format(data.DetailDesc, value1, value2)
	end
    local param = 
    {
    	Obj = Object,
    	Value = strDesc,
    	AlignType = EnumDef.AlignType.Top,
	}
    game._GUIMan:Open("CPanelRoleInfoTips", param)
end

-- 属性界面按钮点击事件
def.method("string").Click = function (self,id)
	
		-- game._GUIMan:CloseByScript(self)
	if string.find(id, "Img_Role") then 
		--self._InCombatState = not self._InCombatState
		--ChangeCombatStateImmediately(self._Model4ImgRender1, self._InCombatState)
	elseif id == "Btn_Head" then 
		-- TODO()
		game._GUIMan:Open("CPanelSetHead", nil)
	elseif id == "Btn_Guild"then 
			--跨服判断
        if game._HostPlayer:IsInGlobalZone() then
            game._GUIMan:ShowTipText(StringTable.Get(15556), false)
            return
        end
		    if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Guild) then
				game._CGuideMan:OnShowTipByFunUnlockConditions(1, EnumDef.EGuideTriggerFunTag.Guild)
			else
				if not game._GuildMan:IsHostInGuild() then 
					game._GUIMan:ShowTipText(StringTable.Get(21502),false)
					game._GuildMan:RequestAllGuildInfo()
				else
					game._GUIMan:Open("CPanelUIGuild", _G.GuildPage.Info)
				end
			end
	elseif id == "Btn_Detail" then 
		local doTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
		GameUtil.PlayUISfx(PATH.UIFx_PropertyChangeBg,self._Panel,self._Panel,-1)
		if not self._IsBaseProperty then 

			self._IsBaseProperty = true
			doTweenPlayer:Stop("BaseInfoDisappear")
                        doTweenPlayer:Stop("DetailAppear")
			doTweenPlayer:Restart("DetailDisappear")
			self._PanelObject._FrameBaseInfo:SetActive(true)
			doTweenPlayer:Restart("BaseInfoAppear")
			self._PanelObject._ImgUpArrow:SetActive(true)
			self._PanelObject._ImgDownArrow:SetActive(false)
		else
			self._IsBaseProperty = false
			doTweenPlayer:Stop("DetailDisappear")
                        doTweenPlayer:Stop("BaseInfoAppear")
			doTweenPlayer:Restart("BaseInfoDisappear")
			self._PanelObject._FrameDetailInfo:SetActive(true)
			doTweenPlayer:Restart("DetailAppear")
			self:UpdateOtherProperty()
			self._PanelObject._ImgUpArrow:SetActive(false)
			self._PanelObject._ImgDownArrow:SetActive(true)
		end
	elseif id == "Btn_GoodAndiEvil" then 
		game._GUIMan:Open("CPanelEvilValueTip",nil)
	else
		local enumIndex = tonumber(string.sub(id, -3))
		if enumIndex ~= nil then
			self:ShowPropertyTip(enumIndex)
		end
	end
end

def.method("string", "string").DOTComplete = function(self,go_name, dot_id)
	if go_name == "Frame_DetailInfo" and dot_id == "DetailDisappear" then 
		self._PanelObject._FrameDetailInfo:SetActive(false)
	elseif go_name == "Frame_BaseProperty" and dot_id == "BaseInfoDisappear" then 
		self._PanelObject._FrameBaseInfo:SetActive(false)
	end
end


def.method().Hide = function(self)
	self._Panel = nil 
	self._BtnList1 = nil 
	self._BtnList2 = nil 
end

def.method().Destroy = function(self)
	instance = nil 
end

CPageProperty.Commit()
return CPageProperty