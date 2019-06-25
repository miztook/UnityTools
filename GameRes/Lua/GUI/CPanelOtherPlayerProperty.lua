--[[
		其他角色信息
			--by luee 2018/3/26
]]
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CUIModel = require "GUI.CUIModel"
local CInventory = require "Package.CInventory"
local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
local EProperty = require "PB.data".ENUM_FIGHTPROPERTY

local CPanelOtherPlayerProperty = Lplus.Extend(CPanelBase, 'CPanelOtherPlayerProperty')
local def = CPanelOtherPlayerProperty.define

def.field("userdata")._LabLevel = nil   		--等级 
def.field("userdata")._LabRoleName = nil 		--面板上的名称
def.field("userdata")._LabJob = nil 			--职业
def.field("userdata")._LabFamilyName = nil
def.field("userdata")._LabLV = nil
def.field("userdata")._LabExp = nil 
def.field("userdata")._LabFight = nil
def.field('userdata')._Img_Role = nil
def.field("userdata")._Img_Head = nil
def.field("userdata")._LabBldExp = nil
def.field("userdata")._Frame_RoleLeft = nil
def.field("userdata")._FrameDetailInfo = nil
def.field("userdata")._TipPosition = nil
def.field("userdata")._ImgScore = nil 
def.field("userdata")._ImgSan = nil 
def.field("userdata")._ImgSanNum = nil 
def.field("userdata")._FrameBaseInfo = nil 
def.field("userdata")._BtnAppltFriend = nil 
def.field("userdata")._LabEvilValue = nil 
def.field("boolean")._IsShowBaseInfo = true
def.field("userdata")._ImgUpArrow = nil 
def.field("userdata")._ImgDownArrow = nil 

def.field(CUIModel)._Model4ImgRender1 = nil
def.field(CFrameCurrency)._Frame_Money = nil
def.field("table")._BtnList1 = nil 
def.field("table")._BtnList2 = nil 
def.field("table")._ListAttrs = nil 		--属性List
def.field("table")._ListDress = nil 		--实装List
def.field("table")._ListEquip  = nil        --装备
def.field("table")._GroupStars = nil 
def.field("number")._Profession = 0        --职业
def.field("number")._RoleId = 0 

local instance = nil
def.static('=>', CPanelOtherPlayerProperty).Instance = function ()
	if not instance then
        instance = CPanelOtherPlayerProperty()
        instance._PrefabPath = PATH.UI_OtherPlayerInfo
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

--设置装备显示
local function SetEquipmentPanelShow(equips, fightScore)
	if instance._Frame_RoleLeft == nil then return end
	local equipPack = {}
	for i = 1, 8 do 
		local equip = {}
		equip.Index = i - 1
		if #equips == 0 then 
			equip.ItemData = nil
			table.insert(equipPack,equip)
		else
			equip.ItemData = nil 
			local isHaven = false
			for j,v in ipairs(equips) do
				if v.Index  == i - 1 then 
					isHaven = true
					equip.ItemData = v.ItemData 
				break end
			end
			table.insert(equipPack,equip)
		end
	end
	for i,item in ipairs(equipPack) do
		local index = item.Index

		local bGotEquip = false
		if item.ItemData ~= nil then 
			bGotEquip = item.ItemData.Tid > 0
		end
		local ui_equip = instance._Frame_RoleLeft:FindChild("Equipment/".. EnumDef.RoleEquipSlotImg[index])
		local frame_setting =
		{
			[EFrameIconTag.EmptyEquip] = bGotEquip and -1 or item.Index,
			[EFrameIconTag.ItemIcon] = bGotEquip,
		}
		IconTools.SetFrameIconTags(ui_equip, frame_setting)
		if bGotEquip then
			local setting =
			{
				[EItemIconTag.StrengthLv] = item.ItemData.InforceLevel,
			}
			IconTools.InitItemIconNew(ui_equip, item.ItemData.Tid, setting)
		end
	end

	local labelScore = instance:GetUIObject("Lab_FightScore_Data")   	
	GUI.SetText(labelScore, GUITools.FormatMoney(fightScore))
end

-- --设置强化属性
-- local function SetInforceLVShow()
-- 	local list = instance._ListEquipStruct
-- 	if list == nil or table.nums(list) <= 0 then return end
-- 	for i,v in pairs(list) do
-- 		local ui_equip = instance._Frame_RoleLeft:FindChild("Equipment/".. EnumDef.RoleEquipSlotImg[i])	

-- 		inforceLv:SetActive(false)
	
-- 		if v ~= nil and v > 0 then
-- 			--显示强化水平
-- 			inforceLv:SetActive(true)
-- 			GUI.SetText(inforceLv,"+"..tostring(v))
-- 		end
-- 	end
-- end

local function ShowGrade(self,PvpStage,PvpStageStar)
	self._GroupStars = {}
	for i= 3,5 do
		self._GroupStars[i] =
		{
			_GroupObj = self:GetUIObject("Frame_Star"..i),
			_start = nil
		}
	end
	--将不同群组的星星放到不同组管理
	for i,v in pairs(self._GroupStars) do
	 	if not IsNil(v._GroupObj) then
	 		if v._start == nil then
	 			v._start = {}
	 		end
	 		for j = 1,i do
	 			local starObj = v._GroupObj:FindChild("Img_Star"..j)
	 			if not IsNil(starObj) then
	 				v._start[#v._start + 1] = starObj
	 				-- 未点亮
	 				GUITools.SetGroupImg(starObj,0)
	 			end
	 		end 
	 		v._GroupObj: SetActive(false)
	 	end	 	
	end 
	local DataTemp = CElementData.GetPVP3v3Template(PvpStage)
	if DataTemp ~= nil then		
		GUITools.SetGroupImg(self._ImgSan,PvpStage - 1)
		GUITools.SetGroupImg(self._ImgSanNum,DataTemp.StageLevel - 1)
		local StarItem = self._GroupStars[DataTemp.CountUpLimit]
		if StarItem == nil then return end
		StarItem._GroupObj:SetActive(true)
		for i,v in ipairs(StarItem._start) do
			if not IsNil(v) and (i <= PvpStageStar) then
				-- 点亮
				GUITools.SetGroupImg(v,1)
			end
		end
	end		
end


def.override().OnCreate = function(self)
	self._BtnList1 = {}
	self._BtnList2 = {}
	self._LabLevel =  self:GetUIObject("Lab_RoleLv")   		
	self._LabRoleName =  self:GetUIObject("Lab_RoleName") 		
    self._LabJob =  self:GetUIObject("Lab_Job") 			
    self._LabFamilyName =  self:GetUIObject("Lab_Guild_Data")
	self._LabLV = self:GetUIObject("Lab_Level_Data")
 	self._LabExp =  self:GetUIObject("Lab_BldExp")
	self._LabFight =  self:GetUIObject("Lab_FightScore_Data")
	self._LabBldExp = self:GetUIObject("Bld_Exp"):GetComponent(ClassType.Slider)
	self._Img_Role = self:GetUIObject("Img_Role_1")
	self._Img_Head = self: GetUIObject("Img_Head")
	self._Frame_RoleLeft = self:GetUIObject("Frame_RoleLeft")
	self._FrameDetailInfo = self:GetUIObject("Frame_DetailInfo")
	self._TipPosition = self:GetUIObject("TipPosition")
	self._ImgScore = self:GetUIObject("Img_Score")
	self._ImgSan = self:GetUIObject("Img_San")
	self._ImgSanNum = self:GetUIObject("Img_SanNum")
	self._FrameBaseInfo = self:GetUIObject("Frame_BaseProperty")
	self._BtnAppltFriend = self:GetUIObject("Btn_ApplyFriend")
	self._LabEvilValue  = self:GetUIObject("Lab_GoodAndEvil")
	self._ImgUpArrow = self:GetUIObject("Img_IconUp")
	self._ImgDownArrow = self:GetUIObject("Img_IconDown")
end

def.override('dynamic').OnData = function(self, data)   
    if data == nil then
        warn("查看玩家信息失败！")
        game._GUIMan:CloseByScript(self)
    return end
    self._RoleId = data.RoleId
    local Info = data.Info
	local iExteriorData = Info.Exterior
	self._ListAttrs = {}
	self._ListAttrs = Info.CreatureAttrs

	self._ListDress = {}
	self._ListDress = Info.DressWear

	self._ListEquip = {}
	for i,v in ipairs(Info.Equips) do
		if v ~= nil then
			self._ListEquip[v.Index] = v
		end
	end

	if self._Frame_Money == nil then
        self:GetUIObject("Frame_Money"):SetActive(true)
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end

	self._IsShowBaseInfo = true
	self._Profession = Info.Profession
	game: SetEntityCustomImg(self._Img_Head,data.RoleId,iExteriorData.CustomImgSet,Info.Gender,Info.Profession)
	GUI.SetText(self._LabEvilValue,tostring(iExteriorData.EvilNum))
	if self._Model4ImgRender1 == nil then
       local ModelParams = require "Object.ModelParams"
		local params = ModelParams.new()
		params:MakeParam(iExteriorData, Info.Profession)
		self._Model4ImgRender1 = CUIModel.new(params, self._Img_Role, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, nil)

        self._Model4ImgRender1:AddLoadedCallback(function() 
            --故意服用背包界面参数
            self._Model4ImgRender1:SetModelParam(PATH.UI_RoleInfoNew, Info.Profession)
        end)   
    end

    --显示部分
    GUI.SetText(self._LabRoleName, Info.Name)
    GUI.SetText(self._LabJob, tostring(StringTable.Get(10300 + Info.Profession - 1)))
    if iExteriorData.guildName == "" then
		GUI.SetText(self._LabFamilyName,StringTable.Get(21501))
    else
    	GUI.SetText(self._LabFamilyName, iExteriorData.guildName)
    end

 --    local strDesignation =  game._DesignationMan:GetColorDesignationNameByTID(iExteriorData.DesignationId)
 --    if strDesignation == "" then 
	-- 	GUI.SetText(self._LabDesignation,StringTable.Get(21505))
	-- else
	-- 	GUI.SetText(self._LabDesignation, strDesignation)
	-- end
	if game._CFriendMan:IsFriend(self._RoleId) then 
		local labBtn = self._BtnAppltFriend:FindChild("Img_Bg/Lab_Engrave")
		GUI.SetText(labBtn,StringTable.Get(21509))
		local img_BG = self._BtnAppltFriend:FindChild("Img_Bg")
		GameUtil.MakeImageGray(img_BG, true)
		GameUtil.SetButtonInteractable(self._BtnAppltFriend,false)
	end
		
	GUI.SetText(self._LabLV, string.format(StringTable.Get(21508),Info.Level))
	GUI.SetText(self._LabLevel,string.format(StringTable.Get(21508),Info.Level))
	local levelUpExpTemplate = CElementData.GetLevelUpExpTemplate(Info.Level)
	local levelExp = 0
	if levelUpExpTemplate == nil then 
		levelExp = Info.Exp 
	else
		levelExp =levelUpExpTemplate.Exp
	end
	local value = Info.Exp / levelExp
    self._LabBldExp.value = value
   	GUI.SetText(self._LabExp, string.format(StringTable.Get(21518),Info.Exp,levelExp))
   	self: UpdateBaseProperty()

   	if Info.CreatureAttrs[ENUM.FIGHTSCORE] ~= nil then
   		SetEquipmentPanelShow(Info.Equips, math.ceil(Info.CreatureAttrs[ENUM.FIGHTSCORE].Value))
   	else
   		warn("查询玩家信息错误，没有战斗力属性  ",self._RoleId)
   	end


	--战斗力评级C,B,A,S
   	--推荐战斗力
	local basicValue = game._PlayerStrongMan: GetBasicValueByValueID(1)
	local groupID = game._PlayerStrongMan:GetImgScoreGroupID(math.ceil(Info.CreatureAttrs[ENUM.FIGHTSCORE].Value), basicValue)
	GUITools.SetGroupImg(self._ImgScore,groupID)
	-- 1v1排名
	local lab1V1No = self:GetUIObject("Lab_1V1No")
	local lab1V1Rank = self:GetUIObject("Lab_1V1Rank")
	if Info.JJCRank == 0 then 
		lab1V1No:SetActive(true)
		lab1V1Rank:SetActive(false)
	else
		lab1V1No:SetActive(false)
		lab1V1Rank:SetActive(true)
		GUI.SetText(lab1V1Rank,tostring(Info.JJCRank))
	end
	-- 3v3排名
	ShowGrade(self,Info.PvpStage,Info.PvpStageStar)
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Exit"	then 
		game._GUIMan:CloseSubPanelLayer()
	return end
	if id == "Btn_ApplyFriend" then 
		game._CFriendMan:DoApply(self._RoleId)
	elseif self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
	elseif id == "Btn_Chat" then 
		if not game._CFriendMan:IsInBlackList(self._RoleId) then 
            game._CFriendMan:AddChat(self._RoleId)
            game._GUIMan:CloseByScript(self)
        else
            game._GUIMan:ShowTipText(StringTable.Get(30325),false)
        end
	elseif id == "Btn_Detail" then 
		if not self._IsShowBaseInfo then 
			self._IsShowBaseInfo = true
			self._FrameDetailInfo:SetActive(false)
			self._FrameBaseInfo:SetActive(true)
			self._ImgUpArrow:SetActive(true)
			self._ImgDownArrow:SetActive(false)
		else
			self._IsShowBaseInfo = false
			self:UpdateOtherProperty()
			self._FrameDetailInfo:SetActive(true)
			self._FrameBaseInfo:SetActive(false)
			self._ImgUpArrow:SetActive(false)
			self._ImgDownArrow:SetActive(true)
		end
	elseif id == "Btn_Tip" then 
		game._GUIMan:Open("CPanelArrowTip",nil)
	else
		local enumIndex = tonumber(string.sub(id, -3))
		if type(enumIndex) ~= "number" then
			local slot = EnumDef.RoleEquipImg2Slot[id]
			if slot ~= nil then
				local itemData = self._ListEquip[slot]
				if itemData == nil or itemData.Tid == 0 then return end
				local item = CInventory.CreateItem(itemData)
				if item == nil then return end

				local  clickItem = self._Frame_RoleLeft:FindChild("Equipment/".. EnumDef.RoleEquipSlotImg[slot])
				item:ShowTipWithFuncBtns(TipsPopFrom.OTHER_PALYER,TipPosition.DEFAULT_POSITION,self._TipPosition,clickItem)
			end
	 	else 
			self:ShowPropertyTip(enumIndex)
	 	end
	end
end


-- 更新属性下的基础数据
def.method().UpdateBaseProperty = function(self)
	--基础属性
	local nameList = 
	{
		"002","003","004","005","010","011","030","069",
	}
	self:SetPropertyData(nameList, self:GetUIObject("Img_LittleBG"),true)
end

def.method().UpdateOtherProperty = function(self) ----subList2
	local nameList = {}
	--伤害
	do
		nameList = 
		{
			"010","080","030","032","096","050",
		}
		self:SetPropertyData(nameList, self:GetUIObject("Img_LittleBG1"),false)
	end

	--生存
	do
		nameList = 
		{
			"069","011","034","070","075","051",
		}
		self:SetPropertyData(nameList, self:GetUIObject("Img_LittleBG2"),false)
	end

	--元素伤害
	do
		nameList = 
		{
			"012","084","013","086","014","088",
			"015","090","016","092","017","094",
		}
		self:SetPropertyData(nameList, self:GetUIObject("Img_LittleBG3"),false)
	end

	-- 元素抗性
	do
		nameList = 
		{
			"018","019","020","021","022","023",
		}
		self:SetPropertyData(nameList, self:GetUIObject("Img_LittleBG4"),false)
	end
end

--设置属性的函数，按照现有结构定义
def.method("table","userdata","boolean").SetPropertyData = function(self, nameList, parentObj,IsBaseProperty)
	local info_data = self._ListAttrs
	local player_data = game._HostPlayer._InfoData._FightProperty

	for i,v in ipairs(nameList) do
		local enumIndex = tonumber(v)
		local objProperty = nil
		 
		if not IsBaseProperty then 
			if self._BtnList2[enumIndex] == nil then
				local strProperty = string.format("%s%s%s%s", "properties_", v, "/Lab_", v)
				objProperty = parentObj:FindChild(strProperty)
				self._BtnList2[enumIndex] = objProperty
			else
				objProperty = self._BtnList2[enumIndex]
			end
		else
			if self._BtnList1[enumIndex] == nil then
				local strProperty = string.format("%s%s%s%s", "properties_", v, "/Lab_", v)
				objProperty = parentObj:FindChild(strProperty)
				self._BtnList1[enumIndex] = objProperty
			else
				objProperty = self._BtnList1[enumIndex]
			end
		end

		local objValue = nil
		if parentObj == nil then
			objValue = self:GetUIObject("Lab_Number"..v)
		else
			local strValue = string.format("%s%s%s%s%s%s", "properties_", v, "/Img_Data", v, "/Lab_Number", v)
			objValue = parentObj:FindChild(strValue)
		end
		--读取数据,显示格式,显示属性名称
		if not IsNil(objProperty) and not IsNil(objValue) then
			
			local data = CElementData.GetTemplate("FightPropertyConfig", enumIndex)
			if data == nil then return end

			if  info_data[enumIndex] ~= nil then

				local valueTotal = info_data[enumIndex].Value --查看的其他玩家
				local valueIncrease = player_data[enumIndex][1]--玩家自身的
				GUI.SetText(objProperty, data.AttrName)

				local Img_Arrow = objValue:FindChild("Img_Arrow")
				Img_Arrow:SetActive(true)
				if valueTotal == valueIncrease then
					Img_Arrow:SetActive(false)
				elseif valueTotal < valueIncrease then
					GUITools.SetGroupImg(Img_Arrow, 1)
				else
					GUITools.SetGroupImg(Img_Arrow, 0)
				end

				if string.sub(data.ValueFormat, -1) == "%" then
					valueTotal = valueTotal * 100
				end
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
				GUI.SetText(objValue,strTotal)
			else
				warn("查询玩家信息错误：属性Index：",enumIndex)
			end
		end
	end
end

def.method("number").ShowPropertyTip = function(self, index)
	local Object = nil 

	if not self._IsShowBaseInfo  then 
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

	local info_data = self._ListAttrs
	local value = info_data[exchangeIndex1].Value
	if value == nil then return end

	if exchangeIndex2 == 0 then
		local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
		local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
		if config ~= nil and config.DESC ~= nil and config.DESC[index] ~= nil then
			strDesc = config.DESC[index][self._Profession]
		else
			local exchangeData = CElementData.GetTemplate("FightPropertyConfig", exchangeIndex1)
			if string.sub(exchangeData.ValueFormat, -1) == "%" then
				value = math.ceil(value * 100)
			end
			
			strDesc = string.format(data.DetailDesc, value)
		end		
	else
		local value1 = value * 100
		local value2 = info_data[exchangeIndex2].Value * 100
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

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	if self._Model4ImgRender1 ~= nil  then
       self._Model4ImgRender1:Destroy()		
       self._Model4ImgRender1 = nil
    end

    self._ListAttrs = nil 
	self._ListDress = nil
	self._ListEquip  = nil        --装备
	self._GroupStars = nil 
	self._Profession = 0        --职业
end

def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    instance = nil 
end

CPanelOtherPlayerProperty.Commit()
return CPanelOtherPlayerProperty