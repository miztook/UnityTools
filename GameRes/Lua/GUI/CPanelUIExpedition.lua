--[[-----------------------------------------
    	远征显示
      		 ——by luee. 2017.12.25
 --------------------------------------------
]]

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIExpedition = Lplus.Extend(CPanelBase, "CPanelUIExpedition")
local def = CPanelUIExpedition.define
local CGame = Lplus.ForwardDeclare("CGame")

local CElementData = require "Data.CElementData"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CTeamMan = require "Team.CTeamMan"
local EAssistType = require "PB.Template".Instance.EAssistType
local EInstanceType = require "PB.Template".Instance.EInstanceType
local EInstanceDifficultyMode = require "PB.Template".Instance.EInstanceDifficultyMode

-- 界面
def.field(CFrameCurrency)._Frame_Money = nil
def.field("table")._RdoTable_Top = BlankTable
def.field("userdata")._Img_Bg = nil
def.field("userdata")._Img_Boss = nil
def.field("userdata")._View_Expedition  = nil     --远征副本List
def.field("userdata")._List_Expedition  = nil     --远征副本List
def.field("userdata")._Frame_Right = nil   --展示面板
def.field("userdata")._Lab_Name = nil  --选择的副本名称
def.field("userdata")._Lab_BossLevel = nil
def.field("userdata")._Frame_BuffList = nil
def.field("userdata")._List_Buff = nil		--状态List
def.field("userdata")._Lab_PlayDescription = nil 		--玩法类型描述
def.field("userdata")._Lab_PropertyLimit = nil  		--推荐战斗力
def.field("userdata")._Lab_CurProperty = nil
def.field("userdata")._Lab_NumLimit = nil --参与人数
def.field("userdata")._Lab_RewardCount = nil --奖励次数
def.field("userdata")._Frame_Assist = nil
def.field("userdata")._IOSToggle_Assist = nil
def.field("userdata")._Frame_CantAssist = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._View_Reward = nil    --奖励面板
def.field("userdata")._List_Reward = nil    --奖励List
def.field("userdata")._Frame_BuffTips = nil
def.field("userdata")._Lab_TipsTitle = nil 	--状态名称
def.field("userdata")._Img_BuffIcon = nil
def.field("userdata")._Lab_TipsDesc = nil 	--状态描述
def.field("userdata")._Btn_QuickJoin = nil
def.field("userdata")._Lab_QuickJoin = nil 	-- 前往组队 or 快速匹配
def.field("userdata")._Btn_Enter = nil
-- 缓存
def.field("table")._AllExpedtionDataMap = BlankTable
def.field("table")._SelectedIndexMap = BlankTable
def.field("table")._BossAffixDataList = BlankTable --远征词缀
def.field("table")._RewardsData = BlankTable       --奖励
def.field("number")._CurPageType = 0
def.field("number")._FightScoreUpperLimitRate = 0 		-- 战力对比上限百分比
def.field("number")._FightScoreLowerLimitRate = 0 		-- 战力对比下限百分比
def.field("boolean")._IsOpenAssist = true 				-- 是否开启好友助战

local EXPEDITION_POPUP_TID = 10 -- 远征介绍弹窗TID
local ColorHexFormat =
{
	Green = "<color=#7BDC1C>%s</color>",
	Yellow = "<color=#FFF4AD>%s</color>",
	Red = "<color=#E2260C>%s</color>"
}

-- 页签类型
local EPageType =
{
	Normal = 1,
	Nightmare = 2
}

local instance = nil
def.static("=>", CPanelUIExpedition).Instance = function ()
	if not instance then
		instance = CPanelUIExpedition()
		instance._PrefabPath = PATH.UI_Expedition
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	local frame_top_tabs = self:GetUIObject("Frame_TopTabs")
	--GameUtil.LayoutTopTabs(frame_top_tabs)
	for _, v in pairs(EPageType) do
		local rdo = self:GetUIObject("Rdo_Main_"..v):GetComponent(ClassType.Toggle)
		self._RdoTable_Top[v] = rdo
	end
	self._Img_Bg = self:GetUIObject("Img_BG")
	self._Img_Boss = self:GetUIObject("Img_Boss")
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
	self._View_Expedition = self:GetUIObject("View_Expedition")
	self._List_Expedition = self:GetUIObject("List_Expedition"):GetComponent(ClassType.GNewList)
	self._Lab_Name = self:GetUIObject("Lab_ExpeditionName")
	self._Lab_BossLevel = self:GetUIObject("Lab_BossLevel")
	self._Frame_BuffList = self:GetUIObject("Frame_BuffList")
	self._List_Buff = self:GetUIObject("List_Buff"):GetComponent(ClassType.GNewList)
	self._Lab_PlayDescription = self:GetUIObject("Lab_PlayDescription")
	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
	self._Lab_PropertyLimit = self:GetUIObject("Lab_PropertyLimit")
	self._Lab_CurProperty = self:GetUIObject("Lab_CurProperty")
	self._Lab_NumLimit = self:GetUIObject("Lab_NumLimit")
	self._Lab_RewardCount = self:GetUIObject("Lab_RewardCountNum")
	self._Frame_Assist = self:GetUIObject("Frame_Assist")
	local obj_toggle_assist = self:GetUIObject("IOSToggle_Assist")
	GameUtil.RegisterUIEventHandler(self._Panel, obj_toggle_assist, ClassType.GNewIOSToggle) -- 注册点击事件 
	self._IOSToggle_Assist = obj_toggle_assist:GetComponent(ClassType.GNewIOSToggle)
	self._Frame_CantAssist = self:GetUIObject("Frame_CantAssist")
	self._Frame_BuffTips = self:GetUIObject("Frame_BuffTips")
	self._Lab_TipsTitle = self:GetUIObject("Lab_TipsTitle")
	self._Img_BuffIcon = self:GetUIObject("Img_BuffIcon")
	self._Lab_TipsDesc = self:GetUIObject("Lab_TipsDesc")
	self._Frame_Right = self:GetUIObject("Frame_Right")
	self._Lab_QuickJoin = self:GetUIObject("Lab_QuickJoin")
	self._Btn_QuickJoin = self:GetUIObject("Btn_QuickJoin")
	self._Btn_Enter = self:GetUIObject("Btn_Enter")
	self._Frame_BuffTips:SetActive(true)
	GUITools.SetUIActive(self._Frame_BuffTips, false)

	self:InitData()
end

def.method().InitData = function (self)
	self._AllExpedtionDataMap = { [EPageType.Normal] = {}, [EPageType.Nightmare] = {} }
	local allDungeonTid = game._DungeonMan:GetAllDungeonInfo()
	for _, v in ipairs(allDungeonTid) do
		local template = CElementData.GetInstanceTemplate(v)
		if template ~= nil and template.InstanceType == EInstanceType.INSTANCE_EXPEDITION then
			-- 远征类型
			if template.InstanceDifficultyMode == EInstanceDifficultyMode.NORMAL then
				table.insert(self._AllExpedtionDataMap[EPageType.Normal], template)
			elseif template.InstanceDifficultyMode == EInstanceDifficultyMode.NIGHTMARE then
			   table.insert(self._AllExpedtionDataMap[EPageType.Nightmare], template)
			end
		end
	end
	local function sortFunc(a, b)
		if a.MinEnterLevel ~= b.MinEnterLevel then
			return a.MinEnterLevel < b.MinEnterLevel
		elseif a.Id ~= b.Id then
			return a.Id < b.Id
		end
		return false
	end
	for _, pageData in pairs(self._AllExpedtionDataMap) do
		table.sort(pageData, sortFunc)
	end

	self._BossAffixDataList = {}
	local affixs = game._DungeonMan:GetExpeditionAffixs()
	for _, id in ipairs(affixs) do
		local talentTemplate = CElementData.GetTemplate("Talent", id)
		if talentTemplate ~= nil then
			local temp = 
			{
				_TID = id,
				_Name =  talentTemplate.Name,
				_Icon = talentTemplate.Icon,
				_Describe = talentTemplate.TalentDescribtion,
			}
			table.insert(self._BossAffixDataList, temp)
		end
	end

	local CSpecialIdMan = require "Data.CSpecialIdMan"
	local compareRange = string.split(CSpecialIdMan.Get("DungeonFightScoreCompareRange"), "*")
	if compareRange[1] ~= nil then
		self._FightScoreLowerLimitRate = tonumber(compareRange[1]) / 100
	end
	if compareRange[2] ~= nil then
		self._FightScoreUpperLimitRate = tonumber(compareRange[2]) / 100
	end
end

-- 选中当前副本模板
local function GetCurTemplate(self)
	local pageData = self._AllExpedtionDataMap[self._CurPageType]
	if pageData ~= nil then
		local selectedIndex = self._SelectedIndexMap[self._CurPageType]
		if selectedIndex ~= nil then
			return pageData[selectedIndex]
		end
	end
	return nil
end

-- 监听副本解锁事件
local function OnDungeonUnlockEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		local template = CElementData.GetInstanceTemplate(event._UnlockTid)
		if template.InstanceType ~= EInstanceType.INSTANCE_EXPEDITION then return end
		instance:UnlockDungeon(event._UnlockTid)
		instance:UpdateBtnState()
	end
end

-- 监听次数组购买事件
local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		local template = GetCurTemplate(instance)
		if template == nil then return end
		instance:UpdateRewardCount(template.Id)
	end
end

-- 监听快速匹配事件
local function OnQuickMatchStateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateQuickJoinState()
	end
end

def.override("dynamic").OnData = function(self, data)
	local curPageType = EPageType.Normal
	if data ~= nil and type(data.DungeonID) == "number" then
		for pageType, pageData in pairs(self._AllExpedtionDataMap) do
			for index, template in ipairs(pageData) do
				if template.Id == data.DungeonID then
					curPageType = pageType
					self._SelectedIndexMap[pageType] = index
					break
				end
			end
		end
	end
	if self._SelectedIndexMap[curPageType] == nil then
		-- 默认选中已解锁的最高等级的副本
		local pageData = self._AllExpedtionDataMap[curPageType]
		for i=#pageData, 1, -1 do
			local data = game._DungeonMan:GetDungeonData(pageData[i].Id)
			if data ~= nil and data.IsOpen then
				self._SelectedIndexMap[curPageType] = i
				break
			end
		end
	end
	self._RdoTable_Top[curPageType].isOn = true
	self:SelectPage(curPageType)
	-- 初始化远征Boss Buff
	if #self._BossAffixDataList > 0 then
		GUITools.SetUIActive(self._Frame_BuffList, true)
		self._List_Buff:SetItemCount(#self._BossAffixDataList)
	else
		GUITools.SetUIActive(self._Frame_BuffList, false)
	end
	self:EnableAssist(true)

	-- 播放背景特效
	GameUtil.PlayUISfx(PATH.UIFX_DungeonBG, self._Img_Bg, self._Img_Bg, -1)

	CGame.EventManager:addHandler("DungeonUnlockEvent", OnDungeonUnlockEvent)
	CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:addHandler("QuickMatchStateEvent", OnQuickMatchStateEvent)
end

-- 选中难度
def.method("number").SelectPage = function (self, pageType)
	local pageData = self._AllExpedtionDataMap[pageType]
	if pageData == nil then return end

	self._CurPageType = pageType
	if self._SelectedIndexMap[pageType] == nil then
		self._SelectedIndexMap[pageType] = 1 -- 默认选中第一个
	end
	local selectedIndex = self._SelectedIndexMap[pageType]
	local bShow = #pageData > 0
	self._View_Expedition:SetActive(bShow)
	GUITools.SetUIActive(self._Frame_Right, bShow)
	GUITools.SetUIActive(self._Img_Boss, bShow)
	if #pageData > 0 then
		self._List_Expedition:SetItemCount(#pageData)
		self._List_Expedition:SetSelection(selectedIndex-1)
		self:SelectDungeon(selectedIndex)
	end
end

def.override("userdata").OnPointerClick = function(self, target)
	if target.name ~= "Frame_BuffTips" then
		GUITools.SetUIActive(self._Frame_BuffTips, false)
	end
end

def.override("string").OnClick = function(self, id)
	GUITools.SetUIActive(self._Frame_BuffTips, false)
	if self._Frame_Money:OnClick(id) then return end

	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
		game._GUIMan:Close("CPanelUIDungeonIntroduction")
	elseif id == "Btn_Exit" then
		game._GUIMan:CloseSubPanelLayer()
		game._GUIMan:Close("CPanelUIDungeonIntroduction")
	elseif id == "Btn_Enter" then
		self:EnterLogic()
	elseif id == "Btn_QuickJoin" then
		self:QuickJoinLogic()
	elseif id == "Btn_Buy" then
		-- 购买次数
		local template = GetCurTemplate(self)
		if template == nil then return end
		
		local dungeonData = game._DungeonMan:GetDungeonData(template.Id)
		if dungeonData == nil then return end

		if not dungeonData.IsOpen then
			game._GUIMan:ShowTipText(StringTable.Get(954), false)
			return
		end
		
		game:BuyCountGroup(game._DungeonMan:GetRemainderCount(template.Id), template.CountGroupTid)
	elseif id == "IOSToggle_Assist" then
		-- 好友助战
		self:EnableAssist(not self._IsOpenAssist)
	elseif id == "Btn_Rule" then
		-- 规则介绍
		game._GUIMan:Open("CPanelUIDungeonIntroduction", EXPEDITION_POPUP_TID)
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	GUITools.SetUIActive(self._Frame_BuffTips, false)
	if string.find(id, "Rdo_Main_") and checked then
		local pageType = tonumber(string.sub(id, string.len("Rdo_Main_")+1, -1))
		if pageType == nil or pageType == self._CurPageType then return end

		self:SelectPage(pageType)
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_Expedition") then
		self:OnInitExpeditionList(item, index)
	elseif string.find(id, "List_Buff") then
		self:OnInitBuffList(item, index)
	elseif string.find(id, "List_Reward") then
		self:OnInitRewardList(item, index)
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	GUITools.SetUIActive(self._Frame_BuffTips, false)
	if string.find(id, "List_Expedition") then
		-- 远征副本列表
		self:OnSelectExpeditionList(item, index)
	elseif string.find(id, "List_Buff") then
		-- 首领Buff列表
		self:OnSelectBuffList(item, index)
	elseif string.find(id, "List_Reward") then
		-- 奖励列表
		self:OnSelectRewardList(item, index)
	end
end

def.method("number").OpenMatchingBoard = function(self, roomId)
	local panel_data = {}
	panel_data.TargetId = roomId
	game._GUIMan:Open("CPanelUITeamMatchingBoard", panel_data)
end

def.method().QuickJoinLogic = function(self)
	local dungeonTemp = GetCurTemplate(self)
	if dungeonTemp == nil then return end

	local dungeon_id = dungeonTemp.Id
	if not game._DungeonMan:DungeonIsOpen(dungeon_id) then
		-- 等级不足
		game._GUIMan:ShowTipText(StringTable.Get(915), false)
		return
	end

	-- warn("dungeonTemp.IsQuickMatching = ", dungeonTemp.IsQuickMatch,
	-- 								   	   dungeonTemp.TextDisplayName,
	-- 									   dungeonTemp.Id)

	if dungeonTemp.IsQuickMatch then
		local roomId = CTeamMan.Instance():ExchangeToRoomId(dungeon_id)
		if roomId > 0 then
			local curMatchDungeonId = CTeamMan.Instance():ExchangeToDungeonId(game._DungeonMan:GetQuickMatchTargetId())
			-- 快捷匹配
			if curMatchDungeonId == dungeon_id then
				-- 停止
				self:OpenMatchingBoard(roomId)
			else
				-- 开启规则
				if CTeamMan.Instance():InTeam() then
					if CTeamMan.Instance():IsTeamLeader() then
						if CTeamMan.Instance():GetMemberCount() > dungeonTemp.MaxRoleNum then
							-- 1. 队伍人数大于副本人数上限
							game._GUIMan:ShowTipText(string.format(StringTable.Get(937), dungeonTemp.MaxRoleNum), false)
						elseif CTeamMan.Instance():GetMemberCount() == dungeonTemp.MaxRoleNum then
							-- 2. 队伍人数 等于副本人数上限，直接进入副本逻辑
							self:EnterLogic()
						else
							-- 3. 队伍人数 小于副本人数上限，快捷匹配规则
							self:OpenMatchingBoard(roomId)
						end
					else
						game._GUIMan:ShowTipText(StringTable.Get(933), false)
					end
				else
					-- 4. 没有队伍 快捷匹配规则
					self:OpenMatchingBoard(roomId)
				end
			end
		else
			warn("Error: unknown RoomID", roomId, dungeon_id)
		end
	else
		if game._HostPlayer:InTeam() then
			game._GUIMan:ShowTipText(StringTable.Get(22018), false)
		else
			-- 进入对应的组队界面
			game._GUIMan:Open("CPanelUITeamCreate", {TargetId = dungeon_id})
		end
	end
end

def.method().EnterLogic = function(self)
	local dungeonTemp = GetCurTemplate(self)
	if dungeonTemp == nil then return end

	if CTeamMan.Instance():InTeam() then
		-- 队伍中
		if not CTeamMan.Instance():IsTeamLeader() then
			-- 非队长
			game._GUIMan:ShowTipText(StringTable.Get(933), false)
			return
		end
	end
	local dungeon_id = dungeonTemp.Id
	local remainderTime = game._DungeonMan:GetRemainderCount(dungeon_id) -- 副本剩余次数
	if remainderTime == 0 then
		-- 副本没有剩余次数
		local countGroupTemplate = CElementData.GetTemplate("CountGroup", dungeonTemp.CountGroupTid)
		if countGroupTemplate ~= nil then
			if countGroupTemplate.InitBuyCount > 0 then
				-- 属于可购买次数的副本
				-- local leftTime = game:OnCurLaveCount(dungeonTemp.CountGroupTid) -- 剩余可购买次数
				-- if leftTime > 0 then
					-- 还可以购买
					game:BuyCountGroupWhenEnter(dungeonTemp.CountGroupTid)
					return
				-- end
			end
		end
	end
	if dungeonTemp.AssistType == EAssistType.Friend and dungeonTemp.AssistSuggestionNumber > 1 and self._IsOpenAssist then
		-- 好友助战
		if (not CTeamMan.Instance():InTeam()) or 								-- 没有队伍
		   (CTeamMan.Instance():GetMemberCount() < dungeonTemp.AssistSuggestionNumber) then	-- 队伍人数不足
			game._GUIMan:Open("CPanelFriendFight", dungeon_id)
			return
		end
	end

	-- local C2SExpedition = require "PB.net".C2SExpedition
	-- local Etype = require"PB.net".C2SExpedition.EExpeditionType
	-- local msg = C2SExpedition()
	-- msg.optType = Etype.EExpeditionType_enterDungeon
	-- msg.dungeonTId = dungeon_id
	
	-- local PBHelper = require "Network.PBHelper"
	-- PBHelper.Send(msg)
	game._DungeonMan:TryEnterDungeon(dungeon_id)
end

--设置状态ICON的显示
def.method("userdata","number").OnInitBuffList = function(self, item, index)
	local talentData = self._BossAffixDataList[index+1]
	if talentData == nil then return end

	local img_icon = GUITools.GetChild(item, 2)
 	GUITools.SetIcon(img_icon, talentData._Icon)
end

def.method("userdata","number").OnInitRewardList = function(self, item, index)
	local reward = self._RewardsData[index + 1]
	if reward == nil then return end
	-- 图标
	local frame_icon = GUITools.GetChild(item, 0)
	if not IsNil(frame_icon) then
		local setting =
		{
			[EItemIconTag.Probability] = reward.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
		}
		IconTools.InitItemIconNew(frame_icon, reward.Data.Id, setting)
	end
end

def.method("userdata", "number").OnInitExpeditionList = function (self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local template = self._AllExpedtionDataMap[self._CurPageType][index+1]
	local dungeonData = game._DungeonMan:GetDungeonData(template.Id)
	if dungeonData == nil then return end

	-- 背景
	local img_bg_d = uiTemplate:GetControl(1)
	GameUtil.MakeImageGray(img_bg_d, not dungeonData.IsOpen)
	-- 名字
	local grayColorHex = "<color=#909AA8>%s</color>"
	local nameStr = dungeonData.IsOpen and template.TextDisplayName or string.format(grayColorHex, template.TextDisplayName)
	local lab_name_d = uiTemplate:GetControl(2)
	local lab_name_u = uiTemplate:GetControl(5)
	GUI.SetText(lab_name_d, nameStr)
	GUI.SetText(lab_name_u, nameStr)
	-- 等级
	local lab_level_d = uiTemplate:GetControl(3)
	local lab_level_u = uiTemplate:GetControl(6)
	GUITools.SetUIActive(lab_level_u, dungeonData.IsOpen)
	GUITools.SetUIActive(lab_level_d, dungeonData.IsOpen)
	GUI.SetText(lab_level_d, StringTable.Get(23001) .. template.MinEnterLevel)
	GUI.SetText(lab_level_u, StringTable.Get(23001) .. template.MinEnterLevel)
	-- 解锁状态
	local frame_lock = uiTemplate:GetControl(7)
	GUITools.SetUIActive(frame_lock, not dungeonData.IsOpen)
	if not dungeonData.IsOpen then
		local lab_lock = uiTemplate:GetControl(9)
		GUI.SetText(lab_lock, string.format(StringTable.Get(137), template.MinEnterLevel))
	end
	if game._DungeonMan:IsUIFxNeedToPlay(template.Id) then
		-- 需要播放特效
		local frame_sfx = uiTemplate:GetControl(10)
		GameUtil.PlayUISfxClipped(PATH.UIFX_CommonUnlock, frame_sfx, frame_sfx, self._View_Expedition)
	end
end

def.method("userdata", "number").OnSelectExpeditionList = function (self, item, index)
	local selectedIndex = self._SelectedIndexMap[self._CurPageType]
	if index+1 == selectedIndex then return end

	self._SelectedIndexMap[self._CurPageType] = index+1
	self._List_Expedition:SetSelection(index)
	self:SelectDungeon(index+1)
end

def.method("userdata", "number").OnSelectBuffList = function (self, item, index)
	local talentData = self._BossAffixDataList[index + 1]
	if talentData == nil then return end

	GameUtil.SetTipsPosition(item, self._Frame_BuffTips)
	GUI.SetText(self._Lab_TipsTitle, talentData._Name)
	GUI.SetText(self._Lab_TipsDesc, talentData._Describe)
	GUITools.SetIcon(self._Img_BuffIcon, talentData._Icon)
	GUITools.SetUIActive(self._Frame_BuffTips, true)
end

def.method("userdata", "number").OnSelectRewardList = function (self, item, index)
	local rewardData = self._RewardsData[index + 1]
	if not rewardData.IsTokenMoney then
		CItemTipMan.ShowItemTips(rewardData.Data.Id, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
	else
		local panelData = 
		{
			_MoneyID = rewardData.Data.Id,
			_TipPos = TipPosition.FIX_POSITION,
			_TargetObj = item,
		}
		CItemTipMan.ShowMoneyTips(panelData)
	end
end

--选择远征副本
def.method("number").SelectDungeon = function(self, nIndex)
	local template = self._AllExpedtionDataMap[self._CurPageType][nIndex]
	if template == nil then return end
	local dungeonData = game._DungeonMan:GetDungeonData(template.Id)
	if dungeonData == nil then return end
	-- 图标
	GUITools.SetSprite(self._Img_Boss, template.IconPath)
	-- 名称
	GUI.SetText(self._Lab_Name, template.TextDisplayName)
	-- 等级
	GUI.SetText(self._Lab_BossLevel, StringTable.Get(23001) .. template.MinEnterLevel)
	-- 玩法类型描述
	GUI.SetText(self._Lab_PlayDescription, template.PlayTypeDescription)
	-- 推荐战力
	local recommendedFightScore = template.RecommendedFightScore -- 推荐战力
	GUI.SetText(self._Lab_PropertyLimit, GUITools.FormatNumber(recommendedFightScore, false, 7))
	local curFightScore = game._HostPlayer:GetHostFightScore() -- 当前战力
	local curFightScoreStr = GUITools.FormatNumber(curFightScore, false, 7)
	if curFightScore < recommendedFightScore * self._FightScoreLowerLimitRate then
		-- 低于下限，显示红色
		curFightScoreStr = string.format(ColorHexFormat.Red, curFightScoreStr)
	elseif curFightScore < recommendedFightScore * self._FightScoreUpperLimitRate then
		-- 高于下限，低于上限，显示黄色
		curFightScoreStr = string.format(ColorHexFormat.Yellow, curFightScoreStr)
	else
		-- 高于上限，显示绿色
		curFightScoreStr = string.format(ColorHexFormat.Green, curFightScoreStr)
	end
	GUI.SetText(self._Lab_CurProperty, curFightScoreStr)
	-- 准入人数
	local numStr = tostring(template.MinRoleNum)
	if template.MaxRoleNum > template.MinRoleNum then
		numStr = numStr .. " - " .. template.MaxRoleNum
	end
	GUI.SetText(self._Lab_NumLimit, numStr)
	-- 好友助战
	local canAssist = template.AssistType ~= EAssistType.NotSupport
	GUITools.SetUIActive(self._Frame_Assist, canAssist)
	GUITools.SetUIActive(self._Frame_CantAssist, not canAssist)
	-- 奖励
	local moneyRewardList = {} -- 货币奖励
	self._RewardsData = {}
	local rewardList = GUITools.GetRewardList(template.RewardId, true)
	for _, v in ipairs(rewardList) do
		if v.IsTokenMoney then
			table.insert(moneyRewardList, v.Data)
		else
			table.insert(self._RewardsData, v)
		end
	end
	-- 货币奖励
	do
		local enable = false
		if moneyRewardList[1] ~= nil then
			enable = true
			GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, moneyRewardList[1].Id)
			GUI.SetText(self._Lab_OtherReward_1, GUITools.FormatNumber(moneyRewardList[1].Count, true))
		end
		GUITools.SetUIActive(self._Frame_OtherReward_1, enable)

		enable = false
		if moneyRewardList[2] ~= nil then
			enable = true
			GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, moneyRewardList[2].Id)
			GUI.SetText(self._Lab_OtherReward_2, GUITools.FormatNumber(moneyRewardList[2].Count, true))
		end
		GUITools.SetUIActive(self._Frame_OtherReward_2, enable)
	end
	-- 奖励列表
    if #self._RewardsData < 1 then
		GUITools.SetUIActive(self._View_Reward, false)
	else
		GUITools.SetUIActive(self._View_Reward, true)
		self._List_Reward:SetItemCount(#self._RewardsData)
		self._List_Reward:ScrollToStep(0) -- 默认回到顶部
	end
	self:UpdateBtnState()
	-- 奖励次数
	self:UpdateRewardCount(template.Id)
end

-- 更新按钮状态
def.method().UpdateBtnState = function (self)
	local dungeonTemp = GetCurTemplate(self)
	if dungeonTemp == nil then return end

	local dungeonData = game._DungeonMan:GetDungeonData(dungeonTemp.Id)
	if dungeonData == nil then return end

	GUITools.SetUIActive(self._Btn_QuickJoin, dungeonData.IsOpen)
	GUITools.SetUIActive(self._Btn_Enter, dungeonData.IsOpen)
	if dungeonData.IsOpen then
		self:UpdateQuickJoinState()
	end
end

-- 更新快速匹配状态
def.method().UpdateQuickJoinState = function(self)
	local dungeonTemp = GetCurTemplate(self)
	if dungeonTemp == nil then return end

	GUI.SetText(self._Lab_QuickJoin, StringTable.Get(dungeonTemp.IsQuickMatch and (game._DungeonMan:IsQuickMatching() and 936 or 935) or 934))
end

-- 更新奖励次数
def.method("number").UpdateRewardCount = function (self, tid)
	local data = game._DungeonMan:GetDungeonData(tid)
	if data ~= nil then
		local remainderTime = data.RemainderTime
		local maxTime = game._DungeonMan:GetMaxRewardCount(tid)
		local colorFormat = "%d"
		if remainderTime == 0 then
			-- 剩余次数为0时变红
			colorFormat = "<color=#DB2E1C>%d</color>"
		elseif remainderTime > maxTime then
			-- 剩余次数大于初始最大次数时变绿
			colorFormat = "<color=#5CBE37>%d</color>"
		end
		GUI.SetText(self._Lab_RewardCount, string.format(colorFormat, remainderTime) .. "/" .. maxTime)
	end
end

def.method("boolean").EnableAssist = function (self, enable)
	self._IsOpenAssist = enable
	self._IOSToggle_Assist.Value = enable
end

-- 解锁副本
def.method("number").UnlockDungeon = function (self, dungeonTid)
	local pageData = self._AllExpedtionDataMap[self._CurPageType]
	if pageData == nil then return end

	local index = 0
	local dungeonTemplate = nil
	for i, template in ipairs(pageData) do
		if template.Id == dungeonTid then
			index = i
			dungeonTemplate = template
			break
		end
	end
	if index <= 0 or dungeonTemplate == nil then return end

	local item = self._List_Expedition:GetItem(index-1)
	if IsNil(item) then return end

	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local frame_lock = uiTemplate:GetControl(7)
	GUITools.SetUIActive(frame_lock, false)
	local lab_name_d = uiTemplate:GetControl(2)
	local lab_name_u = uiTemplate:GetControl(5)
	GUI.SetText(lab_name_d, dungeonTemplate.TextDisplayName)
	local lab_level_d = uiTemplate:GetControl(3)
	local lab_level_u = uiTemplate:GetControl(6)
	GUITools.SetUIActive(lab_level_d, true)
	GUITools.SetUIActive(lab_level_u, true)
	local frame_sfx = uiTemplate:GetControl(10)
	GameUtil.PlayUISfxClipped(PATH.UIFX_CommonUnlock, frame_sfx, frame_sfx, self._View_Expedition)
	game._DungeonMan:SaveUIFxStatusToUserData(dungeonTid, false)
end


def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler("DungeonUnlockEvent", OnDungeonUnlockEvent)
	CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:removeHandler("QuickMatchStateEvent", OnQuickMatchStateEvent)

	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end

	self._RdoTable_Top = {}
	self._Img_Bg = nil
	self._Img_Boss = nil
	self._View_Expedition  = nil
	self._List_Expedition  = nil
	self._Frame_Right = nil
	self._Lab_Name = nil
	self._Lab_BossLevel = nil
	self._Frame_BuffList = nil
	self._List_Buff = nil
	self._Lab_PlayDescription = nil
	self._Lab_PropertyLimit = nil
	self._Lab_CurProperty = nil
	self._Lab_NumLimit = nil
	self._Lab_RewardCount = nil
	self._Frame_Assist = nil
	self._IOSToggle_Assist = nil
	self._Frame_CantAssist = nil
	self._Frame_OtherReward_1 = nil
	self._Img_OtherReward_1 = nil
	self._Lab_OtherReward_1 = nil
	self._Frame_OtherReward_2 = nil
	self._Img_OtherReward_2 = nil
	self._Lab_OtherReward_2 = nil
	self._View_Reward = nil
	self._List_Reward = nil
	self._Frame_BuffTips = nil
	self._Lab_TipsTitle = nil
	self._Img_BuffIcon = nil
	self._Lab_TipsDesc = nil
	self._Btn_QuickJoin = nil
	self._Lab_QuickJoin = nil
	self._Btn_Enter = nil

	self._CurPageType = 0
	self._AllExpedtionDataMap = {}
	self._SelectedIndexMap = {}
	self._BossAffixDataList = {}
	self._RewardsData = {}
end

CPanelUIExpedition.Commit()
return CPanelUIExpedition