--
-- CPanelUIPlayerStrongCompare   养成信息对比。  lidaming 2018/08/10
--
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CDressMan = require "Dress.CDressMan"
local CScoreCalcMan = require "Data.CScoreCalcMan"

local CPanelUIPlayerStrongCompare = Lplus.Extend(CPanelBase, "CPanelUIPlayerStrongCompare")
local def = CPanelUIPlayerStrongCompare.define
local instance = nil

-- def.field("userdata")._Btn_Sure = nil
-- def.field("userdata")._Frame_Line = nil
-- def.field("userdata")._List_MenuType = nil

-- def.field("number")._CurSelectLine = 0

-- def.field("userdata")._Panel = nil
def.field("table")._ElsePlayerCompareInfo = BlankTable

def.field('userdata')._TabList_Menu  = nil      -- 类型list
def.field("number")._CurType = -1 				--当前选中分类
def.field("table")._ListData = nil 				--分类列表
def.field("boolean")._IsOpen = false 			--是否开启了list

-- red role info
def.field("userdata")._Lab_RedCurFight = nil
def.field("userdata")._Lab_RedLevel = nil
def.field("userdata")._Lab_RedName = nil
def.field("userdata")._Img_RedProfession = nil
def.field("userdata")._Img_RedHead = nil
def.field("userdata")._Img_RedWin = nil
def.field("userdata")._Img_RedDefBg = nil
def.field("userdata")._Lab_RedCurFight1 = nil   --红方胜利obj
def.field("userdata")._Img_RedHead1 = nil
-- blue role info
def.field("userdata")._Lab_BlueCurFight = nil
def.field("userdata")._Lab_BlueLevel = nil
def.field("userdata")._Lab_BlueName = nil
def.field("userdata")._Img_BlueProfession = nil
def.field("userdata")._Img_BlueHead = nil
def.field("userdata")._Img_BlueWin = nil
def.field("userdata")._Img_BlueDefBg = nil
def.field("userdata")._Lab_BlueCurFight1 = nil   --蓝方胜利obj
def.field("userdata")._Img_BlueHead1 = nil

def.field("table")._OtherRoleInfo = BlankTable 		--对比玩家信息

def.static("=>", CPanelUIPlayerStrongCompare).Instance = function ()
	if not instance then
        instance = CPanelUIPlayerStrongCompare()
        instance._PrefabPath = PATH.UI_PlayerStrongCompare
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Lab_RedCurFight = self:GetUIObject("Lab_RedCurFight")
	self._Lab_RedLevel = self:GetUIObject("Lab_RedLevel")
	self._Lab_RedName = self:GetUIObject("Lab_RedName")
	self._Img_RedProfession = self:GetUIObject("Img_RedProfession")
	self._Img_RedHead = self:GetUIObject("Img_RedHead")
	self._Img_RedWin = self:GetUIObject("Img_RedWin")
	self._Img_RedDefBg = self:GetUIObject("Img_RedBg")
	self._Lab_RedCurFight1 = self:GetUIObject("Lab_RedCurFight1")
	self._Img_RedHead1 = self:GetUIObject("Img_RedHead1")

	self._Lab_BlueCurFight = self:GetUIObject("Lab_BlueCurFight")
	self._Lab_BlueLevel = self:GetUIObject("Lab_BlueLevel")
	self._Lab_BlueName = self:GetUIObject("Lab_BlueName")
	self._Img_BlueProfession = self:GetUIObject("Img_BlueProfession")
	self._Img_BlueHead = self:GetUIObject("Img_BlueHead")
	self._Img_BlueWin = self:GetUIObject("Img_BlueWin")
	self._Img_BlueDefBg = self:GetUIObject("Img_BlueBg")
	self._Lab_BlueCurFight1 = self:GetUIObject("Lab_BlueCurFight1")
	self._Img_BlueHead1 = self:GetUIObject("Img_BlueHead1")

	self._TabList_Menu = self:GetUIObject("TabList_Menu"):GetComponent(ClassType.GNewTabList)
end

def.override("dynamic").OnData = function(self, playerData)
	self._OtherRoleInfo = playerData
	local allData = game._PlayerStrongMan :GetAllData()--获取所有数据。然后进行筛选
	if allData == nil or #allData <= 0 then	
		warn("PlayerStrongMan: 数据是空，打开失败")
		game._GUIMan:CloseByScript(self)
		return
	end

	self._IsOpen = false
	--将数据做处理。所有解锁的放入列表中
	self._ListData = {}	
	for _,v in ipairs(allData) do
		local FunID = v._Data.FunID
		local value = self:GetHostPlayerFightScoreByValueID(v._Data.Id)		
		local basicValue = self:GetOtherPlayerFightScoreByValueID(v._Data.Id)
		-- if value > 0 or basicValue > 0 then
		-- if game._CFunctionMan:IsUnlockByFunTid(FunID) then
			local nType = #self._ListData + 1
			self._ListData[nType] = 
			{
				_Data = v._Data,
				_Cells = {},
			}

			local cellIdex = 1
			for _, k in ipairs(v._Cells) do
				local data =  CElementData.GetTemplate("PlayerStrongCell", k)
				if data ~= nil and data.Id ~= nil then
					if data.Id ~= 16 and data.Id ~= 17 then   -- 宠物融合和宠物升星隐藏不显示
						local valueCell = game._PlayerStrongMan:GetCellFightScore(data.Id)
						local basicValueCell = self:GetOtherPlayerCellFightScore(data.Id)
						-- if valueCell > 0 or basicValueCell > 0 then
						-- if game._CFunctionMan:IsUnlockByFunTid(data.FunID) then
						self._ListData[nType]._Cells[cellIdex] = data
						cellIdex = cellIdex + 1
						-- end		
					end
				end				
			end
		-- end
	end	

	if self._ListData == nil or #self._ListData <= 0 then
		warn("PlayerStrongMan: 没有解锁的功能，打开失败")
		game._GUIMan:CloseByScript(self)
		return 
	end

	-- 红方战斗力
	local hp = game._HostPlayer
	-- 蓝方战斗力
	local basicValue = self._OtherRoleInfo.Competitive
	local redCurFight =  hp:GetHostFightScore()

	if redCurFight > basicValue then
		self._Img_RedWin:SetActive(true)
		self._Img_BlueWin:SetActive(false)
		self._Img_RedDefBg:SetActive(false)
		self._Img_BlueDefBg:SetActive(true)
		if not IsNil(self._Lab_RedCurFight1) then
			GUI.SetText(self._Lab_RedCurFight1, GUITools.FormatMoney(redCurFight))
		end
		TeraFuncs.SetEntityCustomImg(self._Img_RedHead1, hp._ID, hp._InfoData._CustomImgSet, hp._InfoData._Gender, hp._InfoData._Prof)
		if not IsNil(self._Lab_BlueCurFight) then
			GUI.SetText(self._Lab_BlueCurFight, GUITools.FormatMoney(basicValue))
		end
		TeraFuncs.SetEntityCustomImg(self._Img_BlueHead, self._OtherRoleInfo.OtherRoleId, self._OtherRoleInfo.CustomImgSet, self._OtherRoleInfo.Gender, self._OtherRoleInfo.Profession)
		GameUtil.PlayUISfx(PATH.UIFX_Compare_WIN, self._Img_RedHead1, self._Img_RedHead1, -1)
		GameUtil.StopUISfx(PATH.UIFX_Compare_WIN,self._Img_BlueHead1)
	else
		self._Img_RedWin:SetActive(false)
		self._Img_BlueWin:SetActive(true)
		self._Img_RedDefBg:SetActive(true)
		self._Img_BlueDefBg:SetActive(false)
		if not IsNil(self._Lab_RedCurFight) then
			GUI.SetText(self._Lab_RedCurFight, GUITools.FormatMoney(redCurFight))
		end
		TeraFuncs.SetEntityCustomImg(self._Img_RedHead, hp._ID, hp._InfoData._CustomImgSet, hp._InfoData._Gender, hp._InfoData._Prof)
		if not IsNil(self._Lab_BlueCurFight1) then
			GUI.SetText(self._Lab_BlueCurFight1, GUITools.FormatMoney(basicValue))
		end
		TeraFuncs.SetEntityCustomImg(self._Img_BlueHead1, self._OtherRoleInfo.OtherRoleId, self._OtherRoleInfo.CustomImgSet, self._OtherRoleInfo.Gender, self._OtherRoleInfo.Profession)
		GameUtil.PlayUISfx(PATH.UIFX_Compare_WIN, self._Img_BlueHead1, self._Img_BlueHead1, -1)
		GameUtil.StopUISfx(PATH.UIFX_Compare_WIN,self._Img_RedHead1)
	end

	
	GUI.SetText(self._Lab_RedLevel, tostring(hp._InfoData._Level))
	GUI.SetText(self._Lab_RedName, hp._InfoData._Name)
	GUITools.SetGroupImg(self._Img_RedProfession, hp._ProfessionTemplate.Id - 1)

	GUI.SetText(self._Lab_BlueLevel, tostring(self._OtherRoleInfo.RoleLevel))
	GUI.SetText(self._Lab_BlueName, self._OtherRoleInfo.RoleName)
	GUITools.SetGroupImg(self._Img_BlueProfession, self._OtherRoleInfo.Profession - 1)

	if self._TabList_Menu ~= nil then
		self._TabList_Menu:SetItemCount(#self._ListData)	
	end
end

--通过我要变强数值ID。获取具体推荐基础值

def.method("number","=>","number").GetHostPlayerFightScoreByValueID = function(self, ValueId)
	if ValueId == 1 then
		return self._OtherRoleInfo.MyScores.EquipScore.EquipBase + self._OtherRoleInfo.MyScores.EquipScore.EquipInforce + self._OtherRoleInfo.MyScores.EquipScore.EquipRecast
	elseif ValueId == 2 then
		return self._OtherRoleInfo.MyScores.SkillScores.skillFight + self._OtherRoleInfo.MyScores.SkillScores.runeFight + self._OtherRoleInfo.MyScores.SkillScores.proficientFight + self._OtherRoleInfo.MyScores.SwingScores.talentFight
	elseif ValueId == 3 then
		return self._OtherRoleInfo.MyScores.PetFightScores.petFightSum + self._OtherRoleInfo.MyScores.PetFightScores.skillFight
	elseif ValueId == 4 then
		return self._OtherRoleInfo.MyScores.CharmScores.normalFight + self._OtherRoleInfo.MyScores.CharmScores.godFight
	elseif ValueId == 5 then
		return self._OtherRoleInfo.MyScores.SwingScores.swingFight
	elseif ValueId == 6 then
		return self._OtherRoleInfo.MyScores.OtherScores.GuildSkills + self._OtherRoleInfo.MyScores.OtherScores.DressScore + self._OtherRoleInfo.MyScores.OtherScores.Manual + self._OtherRoleInfo.MyScores.OtherScores.Design
	else
		return 0
	end
end

def.method("number","=>","number").GetOtherPlayerFightScoreByValueID = function(self, ValueId)
	if ValueId == 1 then
		return self._OtherRoleInfo.BesidesScores.EquipScore.EquipBase + self._OtherRoleInfo.BesidesScores.EquipScore.EquipInforce + self._OtherRoleInfo.BesidesScores.EquipScore.EquipRecast
	elseif ValueId == 2 then
		return self._OtherRoleInfo.BesidesScores.SkillScores.skillFight + self._OtherRoleInfo.BesidesScores.SkillScores.runeFight + self._OtherRoleInfo.BesidesScores.SkillScores.proficientFight + self._OtherRoleInfo.BesidesScores.SwingScores.talentFight
	elseif ValueId == 3 then
		return self._OtherRoleInfo.BesidesScores.PetFightScores.petFightSum + self._OtherRoleInfo.BesidesScores.PetFightScores.skillFight
	elseif ValueId == 4 then
		return self._OtherRoleInfo.BesidesScores.CharmScores.normalFight + self._OtherRoleInfo.BesidesScores.CharmScores.godFight
	elseif ValueId == 5 then
		return self._OtherRoleInfo.BesidesScores.SwingScores.swingFight
	elseif ValueId == 6 then
		return self._OtherRoleInfo.BesidesScores.OtherScores.GuildSkills + self._OtherRoleInfo.BesidesScores.OtherScores.DressScore + self._OtherRoleInfo.BesidesScores.OtherScores.Manual + self._OtherRoleInfo.BesidesScores.OtherScores.Design
	else
		return 0
	end
end
--[[
def.method("number","=>","number").GetOtherPlayerFightScoreByValueID = function(self, ValueId)
	if ValueId == 1 then
		local AllEquipFightScore = 0
		for i,v in ipairs(self._OtherRoleInfo.Equip) do			
			if v ~= nil and v._Tid ~= 0 then 
				local equipedFight = CScoreCalcMan.Instance():CalcEquipFightScore(self._OtherRoleInfo.Profession, v, true)
				AllEquipFightScore = AllEquipFightScore + equipedFight[EnumDef.EquipFightScoreType.Base] + equipedFight[EnumDef.EquipFightScoreType.Refine] + equipedFight[EnumDef.EquipFightScoreType.Inforce] + equipedFight[EnumDef.EquipFightScoreType.Recast]
			end			
		end		
		return AllEquipFightScore
	elseif ValueId == 2 then
		return self._OtherRoleInfo.BesidesScores.SkillScores.skillFight + self._OtherRoleInfo.BesidesScores.SkillScores.runeFight + self._OtherRoleInfo.BesidesScores.SkillScores.proficientFight
	elseif ValueId == 3 then
		return self._OtherRoleInfo.BesidesScores.PetFightScores.petFightSum + self._OtherRoleInfo.BesidesScores.PetFightScores.skillFight
	elseif ValueId == 4 then
		return self._OtherRoleInfo.BesidesScores.CharmScores.normalFight + self._OtherRoleInfo.BesidesScores.CharmScores.godFight
	elseif ValueId == 5 then
		return self._OtherRoleInfo.BesidesScores.SwingScores.swingFight + self._OtherRoleInfo.BesidesScores.SwingScores.talentFight
	elseif ValueId == 6 then
		return self._OtherRoleInfo.BesidesScores.GuildSkills + self._OtherRoleInfo.BesidesScores.DressScore
	else
		return 0
	end
end
]]

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)	
	if id == 'Btn_Close' then
		game._GUIMan:CloseByScript(self)
	end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
	if string.find(list.name, "TabList_Menu") then
		if sub_index == -1 then
			self:OnInitTabListDeep1(item, main_index + 1)
		else
			self:OnInitTabListDeep2(item, main_index + 1, sub_index + 1)
		end
	end
end

--初始化树节点
def.method("userdata","number").OnInitTabListDeep1 = function(self, item, index)
	local data = self._ListData[index]._Data
	if data.Id == nil then
		warn("CPanelUIPlayerStrong:: OnInitTabListDeep1-->类型"..index.."数据错误")
	return end

	local labName = GUITools.GetChild(item, 1)
	if not IsNil(labName) then
		GUI.SetText(labName, data.Name)
	end

	local value = self:GetHostPlayerFightScoreByValueID(data.Id)
	-- if data.Id == 6 then
	-- 	value = value + self._OtherRoleInfo.MyDressScore
	-- end
	local basicValue = self:GetOtherPlayerFightScoreByValueID(data.Id)
	-- warn("hhhhhhh------------------>>>", data.Id , value)
	local labRedFightScore = GUITools.GetChild(item, 5)
	if not IsNil(labRedFightScore) then
		GUI.SetText(labRedFightScore, GUITools.FormatMoney(value))
	end

	local labBlueFightScore = GUITools.GetChild(item, 6)
	if not IsNil(labBlueFightScore) then
		GUI.SetText(labBlueFightScore, GUITools.FormatMoney(basicValue))
	end

	local slider = GUITools.GetChild(item, 4):GetComponent(ClassType.Image)
	if slider ~= nil then
		if value == 0 and basicValue == 0 then
			slider.fillAmount = 0.5
		else
			slider.fillAmount = math.clamp((value/(value + basicValue)), 0, 1)
		end
	end

end

-- 获取主角小类战力值
def.method("number","=>","number").GetHostPlayerCellFightScore = function(self, Id)
	if Id == 1 then --当前装备基础战力（基础 + 精炼）
		return self._OtherRoleInfo.MyScores.EquipScore.EquipBase
	elseif Id == 2 then--装备强化	
		return self._OtherRoleInfo.MyScores.EquipScore.EquipInforce
	elseif Id == 3 then--重铸		
		return self._OtherRoleInfo.MyScores.EquipScore.EquipRecast
	elseif Id == 4 then--技能等级
		return self._OtherRoleInfo.MyScores.SkillScores.skillFight
	elseif Id == 5 then--技能文章
		return self._OtherRoleInfo.MyScores.SkillScores.runeFight
	elseif Id == 6 then--部位精通
		return self._OtherRoleInfo.MyScores.SkillScores.proficientFight
	elseif Id == 7 then--出战和助战宠物等级
		return self._OtherRoleInfo.MyScores.PetFightScores.petFightSum
	elseif Id == 8 then--出战宠物技能加成
		return self._OtherRoleInfo.MyScores.PetFightScores.skillFight
	elseif Id == 9 then--铭符等级
		return self._OtherRoleInfo.MyScores.CharmScores.normalFight
	elseif Id == 10 then--神符等级
		return self._OtherRoleInfo.MyScores.CharmScores.godFight
	elseif Id == 11 then--翅膀数量
		return self._OtherRoleInfo.MyScores.SwingScores.swingFight
	elseif Id == 12 then--天赋技能
		return self._OtherRoleInfo.MyScores.SwingScores.talentFight
	elseif Id == 13 then--公会技能
		return self._OtherRoleInfo.MyScores.OtherScores.GuildSkills
	elseif Id == 14 then--实装评分
		return self._OtherRoleInfo.MyScores.OtherScores.DressScore
	elseif Id == 15 then--万物志评分
		return self._OtherRoleInfo.MyScores.OtherScores.Manual
	elseif Id == 18 then--称号评分
		return self._OtherRoleInfo.MyScores.OtherScores.Design
	else
		return 0
	end
end

-- 获取对比玩家小类战力值
def.method("number","=>","number").GetOtherPlayerCellFightScore = function(self, Id)
	if Id == 1 then --当前装备基础战力（基础 + 精炼）
		return self._OtherRoleInfo.BesidesScores.EquipScore.EquipBase
	elseif Id == 2 then--装备强化	
		return self._OtherRoleInfo.BesidesScores.EquipScore.EquipInforce
	elseif Id == 3 then--重铸		
		return self._OtherRoleInfo.BesidesScores.EquipScore.EquipRecast
	elseif Id == 4 then--技能等级
		return self._OtherRoleInfo.BesidesScores.SkillScores.skillFight
	elseif Id == 5 then--技能文章
		return self._OtherRoleInfo.BesidesScores.SkillScores.runeFight
	elseif Id == 6 then--部位精通
		return self._OtherRoleInfo.BesidesScores.SkillScores.proficientFight
	elseif Id == 7 then--出战和助战宠物等级
		return self._OtherRoleInfo.BesidesScores.PetFightScores.petFightSum
	elseif Id == 8 then--出战宠物技能加成
		return self._OtherRoleInfo.BesidesScores.PetFightScores.skillFight
	elseif Id == 9 then--铭符等级
		return self._OtherRoleInfo.BesidesScores.CharmScores.normalFight
	elseif Id == 10 then--神符等级
		return self._OtherRoleInfo.BesidesScores.CharmScores.godFight
	elseif Id == 11 then--翅膀数量
		return self._OtherRoleInfo.BesidesScores.SwingScores.swingFight
	elseif Id == 12 then--天赋技能
		return self._OtherRoleInfo.BesidesScores.SwingScores.talentFight
	elseif Id == 13 then--公会技能
		return self._OtherRoleInfo.BesidesScores.OtherScores.GuildSkills
	elseif Id == 14 then--实装评分
		return self._OtherRoleInfo.BesidesScores.OtherScores.DressScore
	elseif Id == 15 then--万物志评分
		return self._OtherRoleInfo.BesidesScores.OtherScores.Manual
	elseif Id == 18 then--称号评分
		return self._OtherRoleInfo.BesidesScores.OtherScores.Design
	else
		return 0
	end
end

--初始化2级菜单
def.method("userdata","number","number").OnInitTabListDeep2 = function(self, item, mainIndex, index) 
	local cellData = self._ListData[mainIndex]._Cells[index]
	
	if cellData == nil or cellData.Id == nil then
		warn("CPanelUIPlayerStrong--OnInitTabListDeep2->分类："..mainIndex.."的ID"..index.."数据错误")
	return end

	local labName = GUITools.GetChild(item, 0)
	if not IsNil(labName) then
		GUI.SetText(labName, cellData.Name)
	end
	
	local value = self:GetHostPlayerCellFightScore(cellData.Id)

	-- if cellData.Id == 14 then   -- 自己的时装战力特殊处理
	-- 	value = self._OtherRoleInfo.MyDressScore
	-- end
	local basicValue = self:GetOtherPlayerCellFightScore(cellData.Id)
	-- warn("--- lidaming --->>> value ".. value .. "  basicvalue ==".. basicValue)

	local labRedFightScore = GUITools.GetChild(item, 2)
	if not IsNil(labRedFightScore) then
		GUI.SetText(labRedFightScore, GUITools.FormatMoney(value))
	end

	local labBlueFightScore = GUITools.GetChild(item, 3)
	if not IsNil(labBlueFightScore) then
		GUI.SetText(labBlueFightScore, GUITools.FormatMoney(basicValue))
	end

	local slider = GUITools.GetChild(item, 1):GetComponent(ClassType.Image)
	if slider ~= nil then
		if value == 0 and basicValue == 0 then
			slider.fillAmount = 0.5
		else
			slider.fillAmount = math.clamp((value/(value + basicValue)), 0, 1)
		end
	end
end

--点击Item,-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
  	if string.find(list.name, "TabList_Menu") then
    	if sub_index == -1 then
    		if self._CurType == main_index + 1 then 
    			if not self._IsOpen  then
    				self._IsOpen = true
					self: ShowDataByType(item, main_index)	
					GUITools.SetGroupImg(GUITools.GetChild(item, 3), 0)
    			else
    				self._TabList_Menu:OpenTab(0)
					self._IsOpen = false
					GUITools.SetGroupImg(GUITools.GetChild(item, 3), 2)
    			end
    		else
    			self._IsOpen = true
				self: ShowDataByType(item, main_index)	
				GUITools.SetGroupImg(GUITools.GetChild(item, 3), 0)
    		end
    	end
    end
end

--设置分类显示
def.method("userdata","number").ShowDataByType = function(self,item, nType)
	self._CurType = nType + 1
	if not IsNil(self._ListData) then
		self._TabList_Menu:OpenTab(#self._ListData[self._CurType]._Cells)
	end
end

def.override().OnHide = function (self)
	CPanelBase.OnHide(self)
	self._CurType = -1
	self._IsOpen = false
	self._ListData = nil
	self._ElsePlayerCompareInfo = {}
	self._OtherRoleInfo = {}
end

def.override().OnDestroy = function(self)
	--instance = nil
end

CPanelUIPlayerStrongCompare.Commit()
return CPanelUIPlayerStrongCompare