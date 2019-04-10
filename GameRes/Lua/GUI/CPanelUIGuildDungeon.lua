--
-- 异界之门
--
--【孟令康】
--
-- 2018年3月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local CGame = Lplus.ForwardDeclare("CGame")
local GuildBuildingType = require "PB.data".GuildBuildingType
local CPanelUIGuildDungeon = Lplus.Extend(CPanelBase, "CPanelUIGuildDungeon")
local CFrameCurrency = require "GUI.CFrameCurrency"
local def = CPanelUIGuildDungeon.define

def.field("userdata")._List_Dungeon = nil
def.field("table")._Lab_Names = nil
def.field("userdata")._Lab_Hp = nil
def.field("userdata")._Bar_Hp = nil
def.field("userdata")._Lab_Hp_Num = nil
def.field("userdata")._Lab_Cost_Num = nil
def.field("userdata")._RewardList = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("table")._Img_Bg_1 = nil
def.field("table")._Img_Selected = nil
def.field("table")._Img_Boss = nil
def.field("table")._Img_Bg_2 = nil
def.field("table")._Img_Reward = nil
def.field("table")._Img_Reward_sfx = nil
def.field("table")._Img_Lock = nil
def.field("userdata")._Btn_Enter = nil
def.field("userdata")._Btn_QuickJoin = nil
def.field("userdata")._Lab_Remind = nil
def.field("table")._Data = nil
def.field("table")._RewardData = nil
def.field("table")._MoneyData = nil
def.field("number")._ExpeditionIndex = 1
def.field("userdata")._LastExpedition = nil
def.field("number")._BossIndex = 1
-- 对应建筑信息
def.field("table")._Building = nil
def.field(CFrameCurrency)._Frame_Money = nil

local instance = nil
def.static("=>", CPanelUIGuildDungeon).Instance = function()
	if not instance then
		instance = CPanelUIGuildDungeon()
		instance._PrefabPath = PATH.UI_Guild_Dungeon
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:ShowBtnBuy()
	end
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitUIObject()
	self:OnInit()
	CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)	
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self:OnInitData(data)
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
end

def.method("table").ShowDamageDatas = function(self, damageDatas)
	local data = {}
	local tid = self._Data._Template[self._ExpeditionIndex].Id
	data._TotalHP = self._Data._BossTotalHP
	data._Info = damageDatas
	game._GUIMan:Open("CPanelUIDamage", data)
end
-- 当摧毁
def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
	elseif id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
    	TODO(StringTable.Get(19))
	elseif id == "Btn_Damage" then
		self:OnBtnDamage()
	elseif id == "Btn_Buy" then
		self:OnBtnBuy()
	elseif id == "Btn_Enter" then
		self:OnBtnEnter()
	elseif id == "Btn_QuickJoin" then
		self:OnBtnQuickJion()
	else
		for i = 1, 3 do
			if id == "Btn_Boss_" .. i then
				self:OnBtnBoss(i)
			end
		end
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_Dungeon" then
		local data = self._Data._Template[index]
		GUITools.SetSprite(uiTemplate:GetControl(1), data.Icon)
		GUI.SetText(uiTemplate:GetControl(6), data.Name)
		GUI.SetText(uiTemplate:GetControl(9), data.Description)
        uiTemplate:GetControl(5):SetActive(false)
		local guild = game._HostPlayer._Guild
		if self._Building._BuildingLevel >= data.GuildLevel then
			GUI.SetText(uiTemplate:GetControl(7), string.format(StringTable.Get(10714), data.GuildLevel))
			if self._Data._Opened[data.Id] then
				uiTemplate:GetControl(8):SetActive(true)
				uiTemplate:GetControl(2):SetActive(false)
				uiTemplate:GetControl(11):SetActive(false)
			else
				uiTemplate:GetControl(8):SetActive(false)
				uiTemplate:GetControl(2):SetActive(false)	
				local member = game._GuildMan:GetHostGuildMemberInfo()
				if member ~= nil and member._RoleType == GuildMemberType.GuildLeader then
					-- 是否可以开启下一个章节(根据当前副本Tid是否为0)
					if self._Data._CurDungeonTid == 0 and (not self._Data._HasOpened) then
						uiTemplate:GetControl(11):SetActive(true)
					else
						uiTemplate:GetControl(11):SetActive(false)
					end
				else
					uiTemplate:GetControl(11):SetActive(false)
				end
			end
		else
			GUI.SetText(uiTemplate:GetControl(7), string.format(StringTable.Get(8012), StringTable.Get(841), data.GuildLevel))
			uiTemplate:GetControl(8):SetActive(false)
			uiTemplate:GetControl(11):SetActive(false)
            uiTemplate:GetControl(2):SetActive(true)
		end
		uiTemplate:GetControl(14):SetActive(index == self._ExpeditionIndex)
		if index == self._ExpeditionIndex then
			self._LastExpedition = item
		end
	elseif id == "List_Reward" then
		local data = self._RewardData[index]
		local setting =
		{
			[EItemIconTag.Probability] = data.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
		}
		IconTools.InitItemIconNew(uiTemplate:GetControl(0), data.Data.Id, setting)
	end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_Dungeon" then
		self._LastExpedition:FindChild("Frame_Item/Img_Selected"):SetActive(false)
		uiTemplate:GetControl(14):SetActive(true)
		self._ExpeditionIndex = index
		self._LastExpedition = item
		self:OnShowFrame()
	elseif id == "List_Reward" then
		local itemTid = self._RewardData[index].Data.Id
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
	end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	index = index + 1
	if id == "List_Dungeon" then
		if id_btn == "Btn_Open" then
			self:OnBtnOpen(index)
		end
	end
end

-- 初始化模板信息等
def.method().OnInit = function(self)
	self._Data = {}
	self._Data._Template = {}	
	local allTid = GameUtil.GetAllTid("GuildExpedition")
	for i = 1, #allTid do
		self._Data._Template[i] = CElementData.GetTemplate("GuildExpedition", allTid[i]) 
	end
	-- 所有副本次数组共用，取1个计算
	local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
	local dungeon = CElementData.GetTemplate("Instance", dungeonTid)
	local countGroup = CElementData.GetTemplate("CountGroup", dungeon.CountGroupTid)
	self._Data._MaxCount = countGroup.MaxCount
	self._Data._CurCount = game._DungeonMan:GetRemainderCount(dungeonTid)

	self._Building = game._HostPlayer._Guild._BuildingList[3]
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._List_Dungeon = self:GetUIObject("List_Dungeon"):GetComponent(ClassType.GNewList)
    self._Lab_Names = {}
    for i = 1,3 do
        self._Lab_Names[i] = self:GetUIObject("Lab_Name"..i)
    end
	self._Lab_Hp = self:GetUIObject("Lab_Hp")
	self._Bar_Hp = self:GetUIObject("Bar_Hp"):GetComponent(ClassType.Scrollbar)
	self._Lab_Hp_Num = self:GetUIObject("Lab_Hp_Num")
	self._Lab_Cost_Num = self:GetUIObject("Lab_Cost_Num")
	self._RewardList = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Img_Bg_1 = {}
	self._Img_Selected = {}
	self._Img_Boss = {}
	self._Img_Bg_2 = {}
	self._Img_Reward = {}
	self._Img_Lock = {}
	self._Img_Reward_sfx = {}
	for i = 1, 3 do
		local index = i - 1
		self._Img_Bg_1[i] = self:GetUIObject("Img_Bg_1" .. index)
		self._Img_Selected[i] = self:GetUIObject("Img_Selected" .. i)
		-- 防止UE瞎打开选中
		self._Img_Selected[i]:SetActive(false)
		self._Img_Boss[i] = self:GetUIObject("Img_Boss" .. index)
		self._Img_Bg_2[i] = self:GetUIObject("Img_Bg_2" .. index)
		self._Img_Reward[i] = self:GetUIObject("Img_Reward" .. index)
		self._Img_Lock[i] = self:GetUIObject("Img_Lock" .. i)
	
	end
	self._Btn_Enter = self:GetUIObject("Btn_Enter")
	self._Btn_QuickJoin = self:GetUIObject("Btn_QuickJoin")
	self._Lab_Remind = self:GetUIObject("Lab_Remind")
end

-- 处理信息
def.method("table").OnInitData = function(self, data)
	self._Data._BossHP = data.BossHP
	self._Data._BossTid = data.BossTId
	self._Data._CurDungeonTid = data.CurDungeonTID
	self._Data._MaxExpeditionId = data.MaxExpeditionId
	self._Data._BossTotalHP = data.BossTotalHp
	if self._Data._BossTid == 0 then
		self._Data._BossTid = self._Data._Template[1].DungeonDatas[1].BossTID
	end
	self._Data._BossMaxHp = data.CurBossMaxHp
	if self._Data._BossHP > self._Data._BossMaxHp then
		self._Data._BossHP = self._Data._BossMaxHp
	end
    self._Data._HasOpened = false
	self._Data._Passed = {}
	self._Data._Opened = {}
	self._Data._Rewarded = {}
	local rewardList = game._HostPlayer._Guild._ExpeditionRewardList
	for i = 1, #self._Data._Template do
		local template = self._Data._Template[i]
		local dungeonDatas = template.DungeonDatas
		self._Data._Opened[template.Id] = false
		for j = 1, #dungeonDatas do
			local dungeonTid = dungeonDatas[j].DungeonTID
			if dungeonTid == self._Data._CurDungeonTid then
				self._Data._Opened[template.Id] = true
                self._Data._HasOpened = true
				self._ExpeditionIndex = i
				self._BossIndex = j
			end
			self._Data._Passed[dungeonTid] = false			
			self._Data._Rewarded[dungeonTid] = false
			for k = 1, #data.PassedDungeonIds do
				if data.PassedDungeonIds[k] == dungeonTid then					
					self._Data._Passed[dungeonTid] = true
                    self._Data._Opened[template.Id] = true
                    self._Data._HasOpened = true
				end
			end
			for k = 1, #rewardList do
				if rewardList[k] == dungeonTid then
					self._Data._Rewarded[dungeonTid] = true
				end
			end
		end
	end
    local bg1 = self._Panel:FindChild("Img_BG")
	GameUtil.PlayUISfx(PATH.UI_Guild_Defend_bg_sfx,bg1,bg1,-1)

	self._List_Dungeon:SetItemCount(#self._Data._Template)
	self:OnShowFrame()
end

-- 展示右侧显示信息
def.method().OnShowFrame = function(self)
    if self._List_Dungeon ~= nil then
	    self._List_Dungeon:SetSelection(self._ExpeditionIndex - 1)
    end

    self:UpdateLabCostNum()
	local expedition = self._Data._Template[self._ExpeditionIndex]
	for i = 1, 3 do
		local dungeonTid = expedition.DungeonDatas[i].DungeonTID
		local passed = self._Data._Passed[dungeonTid]
		self._Img_Bg_2[i]:SetActive(passed)
		self._Img_Reward[i]:SetActive(passed)
		--self._Img_Reward[i]:GetChild(0):SetActive(false)
        GameUtil.StopUISfx(PATH.UI_Guild_Dungeon_sfx_tip,self._Img_Reward[i])
        GameUtil.StopUISfx(PATH.UIFX_GuildDungeonExpore, self._Img_Reward[i])
		if passed and not self._Data._Rewarded[dungeonTid] then 
			GameUtil.PlayUISfx(PATH.UI_Guild_Dungeon_sfx_tip,self._Img_Reward[i],self._Img_Reward[i],-1)
            GameUtil.PlayUISfx(PATH.UIFX_GuildDungeonExpore, self._Img_Reward[i], self._Img_Reward[i], 3)
		end 
		local bossTid = self._Data._Template[self._ExpeditionIndex].DungeonDatas[i].BossTID
		local boss = CElementData.GetTemplate("Monster", bossTid)
		GUITools.SetHeadIcon(self._Img_Boss[i], boss.IconAtlasPath)		
		GameUtil.MakeImageGray(self._Img_Reward[i], self._Data._Rewarded[dungeonTid])

		if passed then
			self._Img_Lock[i]:SetActive(false)
		else
			if self._Data._CurDungeonTid == dungeonTid then
				self._Img_Lock[i]:SetActive(false)
			else
				self._Img_Lock[i]:SetActive(true)	
			end
		end
	end
	local percent = self._Data._BossHP / self._Data._BossMaxHp
	if self._Data._BossMaxHp == 0 then
		percent = 1
	end
	self._Bar_Hp.size = percent
	percent = string.format("%.2f", percent)
	GUI.SetText(self._Lab_Hp_Num, percent * 100 .. "%")
	self:OnBtnBoss(self._BossIndex)
	if not self._Data._Opened[expedition.Id] then
		self._Btn_Enter:SetActive(false)
		self._Btn_QuickJoin:SetActive(false)
		self._Lab_Remind:SetActive(true)
		if expedition.GuildLevel > self._Building._BuildingLevel then
			GUI.SetText(self._Lab_Remind, string.format(StringTable.Get(8012), StringTable.Get(841), expedition.GuildLevel))
		elseif expedition.GuildLevel == game._HostPlayer._Guild._GuildLevel then
			GUI.SetText(self._Lab_Remind, StringTable.Get(8068))
		else
            if self._Data._HasOpened then
                GUI.SetText(self._Lab_Remind, StringTable.Get(8087))
            else
                GUI.SetText(self._Lab_Remind, StringTable.Get(8068))
            end
--			if self._ExpeditionIndex == 1 then
--				GUI.SetText(self._Lab_Remind, StringTable.Get(8068))
--			else
--                GUI.SetText(self._Lab_Remind, StringTable.Get(8087))
--			end
		end
	end
end

-- 点击Boss按钮展示信息
def.method("number").OnBtnBoss = function(self, index)
	self._Img_Selected[self._BossIndex]:SetActive(false)
	self._BossIndex = index
	self._Img_Selected[self._BossIndex]:SetActive(true)
	local expeditionTid = self._Data._Template[self._ExpeditionIndex].Id
	local data = self._Data._Template[self._ExpeditionIndex].DungeonDatas[index]
	local dungeon = CElementData.GetTemplate("Instance", data.DungeonTID)
    for i = 1,3 do
        if index == i then
            self._Lab_Names[i]:SetActive(true)
            GUI.SetText(self._Lab_Names[i], dungeon.TextDisplayName)
        else
            self._Lab_Names[i]:SetActive(false)
        end
    end
	
	local dungeonTid = self._Data._Template[self._ExpeditionIndex].DungeonDatas[self._BossIndex].DungeonTID
	if dungeonTid == self._Data._CurDungeonTid then
		self._Lab_Hp:SetActive(true)
	else
		self._Lab_Hp:SetActive(false)
	end
	if self._Data._Opened[expeditionTid] then
		if self._Data._Passed[dungeonTid] then
			self._Btn_Enter:SetActive(false)
			self._Btn_QuickJoin:SetActive(false)
			self._Lab_Remind:SetActive(true)
			GUI.SetText(self._Lab_Remind, StringTable.Get(8069))
		else
			if self._Data._CurDungeonTid == dungeonTid then
				self._Btn_Enter:SetActive(true)
				self._Btn_QuickJoin:SetActive(true)
				self._Lab_Remind:SetActive(false)
			else
				self._Btn_Enter:SetActive(false)
				self._Btn_QuickJoin:SetActive(false)
				self._Lab_Remind:SetActive(true)	
				local tid = self._Data._Template[self._ExpeditionIndex].DungeonDatas[self._BossIndex - 1].DungeonTID
				local name = CElementData.GetTemplate("Instance", tid).TextDisplayName
				GUI.SetText(self._Lab_Remind, string.format(StringTable.Get(8067), name))
			end
		end
	end
	local rewardId = CElementData.GetTemplate("Instance", dungeonTid).RewardId
	local rewardList = GUITools.GetRewardList(rewardId, false)
	self._RewardData = {}
	self._MoneyData = {}
	for i, v in ipairs(rewardList) do
		if v.IsTokenMoney then
			table.insert(self._MoneyData, v)
		else
			table.insert(self._RewardData, v)
		end
	end
	self._RewardList:SetItemCount(#self._RewardData)
	if self._Data._Passed[dungeonTid] then
		if not self._Data._Rewarded[dungeonTid] then
			self:OnBtnReward(index)
		end
	end
	if self._MoneyData[1] ~= nil then
		self._Frame_OtherReward_1:SetActive(true)
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, self._MoneyData[1].Data.Id)
		GUI.SetText(self._Lab_OtherReward_1, tostring(self._MoneyData[1].Data.Count))
	else
		self._Frame_OtherReward_1:SetActive(false)
	end
	if self._MoneyData[2] ~= nil then
		self._Frame_OtherReward_2:SetActive(true)
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, self._MoneyData[2].Data.Id)
		GUI.SetText(self._Lab_OtherReward_2, tostring(self._MoneyData[2].Data.Count))
	else
		self._Frame_OtherReward_2:SetActive(false)
	end
end

-- 开启某个章节
def.method("number").OnBtnOpen = function(self, index)
	local protocol = (require "PB.net".C2SGuildExpeditionOpen)()
	protocol.ExpeditionId = self._Data._Template[index].Id
	PBHelper.Send(protocol)
end

-- 查看伤害统计
def.method().OnBtnDamage = function(self)
	local protocol = (require "PB.net".C2SGuildExpeditionDamageInfo)()
	PBHelper.Send(protocol)
end

-- 购买副本次数
def.method().OnBtnBuy = function(self)
	-- TODO("-----------lidaming CPanelUIGuildDungeon---------------")
	local hasOpen = false
	for _, state in pairs(self._Data._Opened) do
		if state then
			hasOpen = true
			break
		end
	end
	if not hasOpen then
		-- 没有一个开启
		game._GUIMan:ShowTipText(StringTable.Get(954), false)
		return
	end
	-- 所有副本次数组共用，取1个计算
	local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
	local dungeon = CElementData.GetTemplate("Instance", dungeonTid)
	game:BuyCountGroup(game._DungeonMan:GetRemainderCount(dungeonTid) ,dungeon.CountGroupTid)
end

-- 购买副本次数后刷新
def.method().ShowBtnBuy = function(self)
    local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
    self._Data._CurCount = game._DungeonMan:GetRemainderCount(dungeonTid)
    self:UpdateLabCostNum()
end

def.method().UpdateLabCostNum = function(self)
	local remainderTime = self._Data._CurCount
	local maxTime = self._Data._MaxCount
	local colorFormat = "%d"
	if remainderTime == 0 then
		-- 剩余次数为0时变红
		colorFormat = "<color=#DB2E1C>%d</color>"
	elseif remainderTime > maxTime then
		-- 剩余次数大于初始最大次数时变绿
		colorFormat = "<color=#5CBE37>%d</color>"
	end
	GUI.SetText(self._Lab_Cost_Num, string.format(colorFormat, remainderTime) .. "/" .. maxTime)
end

-- 进入副本
def.method().OnBtnEnter = function(self)
	if self._Data._CurCount < 1 then
		game._GUIMan:ShowTipText(StringTable.Get(8071), true)
		return
	end
	local tid = self._Data._Template[self._ExpeditionIndex].DungeonDatas[self._BossIndex].DungeonTID
	local protocol = (require "PB.net".C2SGuildExpeditionEnter)()
	protocol.DungeonTID = tid
	PBHelper.Send(protocol)
end

-- 前往组队
def.method().OnBtnQuickJion = function(self)
	if self._Data._CurCount < 1 then
		game._GUIMan:ShowTipText(StringTable.Get(8071), true)
		return
	end
	if game._HostPlayer:InTeam() then
		game._GUIMan:ShowTipText(StringTable.Get(22018), false)
	else
		-- 进入对应的组队界面
		game._GUIMan:Open("CPanelUITeamCreate", nil)
	end
end

-- 领取奖励
def.method("number").OnBtnReward = function(self, index)
	GameUtil.MakeImageGray(self._Img_Reward[index], true)
	GameUtil.PlayUISfx(PATH.UI_Guild_Dungeon_sfx_reward,self._Img_Reward[index],self._Img_Reward[index],-1)
	self._Img_Reward[index]:GetChild(0):SetActive(false)
	local tid = self._Data._Template[self._ExpeditionIndex].DungeonDatas[index].DungeonTID
	local protocol = (require "PB.net".C2SGuildExpeditionDungeonReward)()
	protocol.DungeonTID = tid
	PBHelper.Send(protocol)
end

-- 展示领取奖励
def.method("number").OnShowBtnReward = function(self, tid)
	self._Data._Rewarded[tid] = true	
end

CPanelUIGuildDungeon.Commit()
return CPanelUIGuildDungeon