--
-- 月光庭院
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local CFrameCurrency = require "GUI.CFrameCurrency"
local GuildBuildingType = require "PB.data".GuildBuildingType
local CGame = Lplus.ForwardDeclare("CGame")
local ChatManager = require "Chat.ChatManager"
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local EItemType = require "PB.Template".Item.EItemType
local ItemQuality = require "PB.Template".Item.ItemQuality

local CPanelUIGuildPray = Lplus.Extend(CPanelBase, "CPanelUIGuildPray")
local def = CPanelUIGuildPray.define

-- 4个许愿池信息
def.field("table")._Pray_Data = nil
def.field("string")._Quality_Des = ""
-- 当前选中品质的背包贡品list
def.field("table")._OwnedPrayItems = nil
-- 当前是否在显示自己许愿池页
def.field("boolean")._IsShownSelfPool = true

-- 当前选中贡品信息
def.field("table")._Selected_Item = nil
-- 当前选中过滤品质
def.field("number")._Quality_Filter_Index = 1
-- 月光庭院建筑信息
def.field("table")._Building_Info = nil
-- 当前选中许愿池
def.field("number")._Selected_PoolIndex = 1
-- 别的玩家公会信息
def.field("table")._Member_Other = nil
-- 别人许愿池
def.field("table")._Pray_Data_Other = nil

def.field(CFrameCurrency)._Frame_Money = nil

def.field("userdata")._Money = nil
def.field("userdata")._Self = nil
def.field("userdata")._Center = nil
def.field("userdata")._Btn_Back = nil
def.field("userdata")._Lab_Num0 = nil
def.field("userdata")._Btn_Quality = nil
def.field("userdata")._Lab_Quality = nil
def.field("userdata")._Img_List_Quality = nil
def.field("userdata")._List_Quality = nil
def.field("userdata")._Img_List_Item = nil
def.field("userdata")._List_Item = nil
def.field("userdata")._Bottom = nil
def.field("userdata")._List_Reward = nil
def.field("userdata")._Btn_Puton = nil
def.field("userdata")._Btn_Approach = nil
def.field("userdata")._Other = nil
def.field("userdata")._Btn_Back_Other = nil
def.field("table")._Img_Lock_Other = nil
def.field("table")._Btn_Speed_Other = nil
def.field("table")._Lab_Sp_Time_Other = nil
def.field("table")._Lab_Sp_Speed_Other = nil
def.field("table")._Btn_Reward_Other = nil
def.field("table")._Btn_Reward_Other_Bg = nil

def.field("table")._Img_Sp_Icon = nil
def.field("table")._Lab_Sp_Time_C = nil
def.field("table")._Img_Other_Sfx = nil
def.field("userdata")._Lab_Num3 = nil
def.field("userdata")._DropDown = nil

def.field("userdata")._Self_BG = nil
def.field("userdata")._Other_BG = nil

def.field("userdata")._TitleLabel = nil

def.field("userdata")._ItemDescLabel_1 = nil
def.field("userdata")._ItemDescLabel_2 = nil
def.field("userdata")._ItemDescLabel_3 = nil

-- Pool UI States
def.field("table")._MyWishPool = BlankTable		-- .obj, .DT, .objUnLock, .objSelected, .isSelected, .colorID, .isDone,

local PRAY_OPEN_COUNT = 4
local PRAY_TOTAL_COUNT = 7

local instance = nil
def.static("=>", CPanelUIGuildPray).Instance = function()
	if not instance then
		instance = CPanelUIGuildPray()
		instance._PrefabPath = PATH.UI_Guild_Pray
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
		instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:InitUIObject()
	self:OnInit()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
	self._Money = self:GetUIObject("Frame_Money")
	self._Frame_Money = CFrameCurrency.new(self, self._Money, EnumDef.MoneyStyleType.None)
	self._TitleLabel = self:GetUIObject("Lab_Title")
	self._Self = self:GetUIObject("Frame_My")
	self._Center = self:GetUIObject("Frame_Center")
	self._Other = self:GetUIObject("Frame_Else")
	-- pools
	self:InitUIPoolItems()

	-- left/right list
	self._ItemDescLabel_1 = self:GetUIObject("Lab_Content_1")
	self._ItemDescLabel_2 = self:GetUIObject("Lab_Content_2")
	self._ItemDescLabel_3 = self:GetUIObject("Lab_Content_3")

	self._Img_List_Item = self:GetUIObject("Img_List_Item")
	self._List_Item = self:GetUIObject("List_Item"):GetComponent(ClassType.GNewListLoop)
	self._Bottom = self:GetUIObject("Bottom")
	self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewListLoop)
	self._Btn_Puton = self:GetUIObject("Btn_Puton")
    self._Btn_Approach = self:GetUIObject("Btn_Approach")
	self._DropDown = self:GetUIObject("DropDown_Down")

	GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_ImgBgSelf, self._Self, self._Self, -1)
	GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_ImgBgOther, self._Other, self._Other, -1)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._HelpUrlType = HelpPageUrlType.Pray
	local allTid = GameUtil.GetAllTid("GuildPrayPool")
	local buildingLevel = self._Building_Info._BuildingLevel
	self._Pray_Data = { }
	for i = 1, #allTid do
		local prayPool = CElementData.GetTemplate("GuildPrayPool", allTid[i])
		self._Pray_Data[i] = { }
		self._Pray_Data[i]._IsOwn = buildingLevel >= prayPool.NeedBuildLevel
		self._Pray_Data[i]._NeedLevel = prayPool.NeedBuildLevel
		-- self._Pray_Data[i]._TimerId = 0
	end
	for i = 1, #data._PrayItems do
		self._Pray_Data[data._PrayItems[i].PoolIndex]._PrayItem = data._PrayItems[i]
	end

	self:ShowSelfMoon()
end

def.override("string", "number").OnDropDown = function(self, id, index)
	self._Selected_Item = nil
	self._Quality_Filter_Index = index + 1
	self:UpdateBagPrayInfo()
	self:UpdateUIRewardInfo()
end

-- Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self, id)
	if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return
	end

	if id == "Btn_Back" then
		if self._IsShownSelfPool then
			game._GUIMan:CloseByScript(self)
		else
			self:OnBtnBackOther()
		end
	elseif id == "Btn_Exit" then
		game._GUIMan:CloseSubPanelLayer()
	elseif id == "Btn_Question" then
		TODO(StringTable.Get(19))
	elseif id == "Btn_Shop" then
		self:OnBtnShop()
	elseif id == "Btn_Help" then
		self:OnBtnHelp()
	elseif id == "Btn_Event" then
		self:OnBtnEvent()
	elseif id == "Btn_Puton" then
		self:OnBtnPuton()
    elseif id == "Btn_Approach" then
        self:OnBtnApproach()
	elseif string.find(id, "Btn_Pool_") then
		if not self._IsShownSelfPool then return end
		local index = tonumber(string.sub(id, string.len("Btn_Pool_") + 1))
		self:OnBtnPrayPool(index)
	elseif string.find(id, "Btn_Speed_") then
		local index = tonumber(string.sub(id, string.len("Btn_Speed_") + 1))
		if self._IsShownSelfPool then
			self:OnBtnSpeed(index)
		else
			self:OnBtnPrayHelp(index)
		end
	elseif string.find(id, "Btn_Reward_") then
		if not self._IsShownSelfPool then return end
		local index = tonumber(string.sub(id, string.len("Btn_Reward_") + 1))
		self:OnBtnReward(index)
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_Item" then
		uiTemplate:GetControl(1):SetActive(false)
		if self._Selected_Item == nil then
			self._Selected_Item = { }
			self._Selected_Item._Item = item
			self._Selected_Item._Index = index
			uiTemplate:GetControl(1):SetActive(true)
		else
			if self._OwnedPrayItems ~= nil and self._Selected_Item._Index > #self._OwnedPrayItems then
				self._Selected_Item = { }
				self._Selected_Item._Index = 1
			end
			if self._Selected_Item._Index == index then
				self._Selected_Item._Item = item
				uiTemplate:GetControl(1):SetActive(true)
			end
		end
		local prayItemInfo = self._OwnedPrayItems[index]
		GUI.SetText(uiTemplate:GetControl(2), prayItemInfo.Template.TextDisplayName)
		GUI.SetText(uiTemplate:GetControl(3), game._GuildMan:GetTimeDes(prayItemInfo.GuildPrayTemplate.CompleteTime))
		local setting = {
			[EItemIconTag.Number] = prayItemInfo.Count,
			[EItemIconTag.CanUse] = prayItemInfo.Count > 0,
		}
		IconTools.InitItemIconNew(uiTemplate:GetControl(4), prayItemInfo.Tid, setting, EItemLimitCheck.AllCheck)
        local img_item_icon = uiTemplate:GetControl(4):FindChild("Frame_ItemIcon/Img_ItemIcon")
        GameUtil.MakeImageGray(img_item_icon, prayItemInfo.Count <= 0)
	elseif id == "List_Reward" then
		local prayItemInfo = self._OwnedPrayItems[self._Selected_Item._Index]
		local setting = { [EItemIconTag.Number] = prayItemInfo.GuildPrayTemplate.RewardItemNum, }
		IconTools.InitItemIconNew(uiTemplate:GetControl(0), prayItemInfo.GuildPrayTemplate.RewardItemID, setting, EItemLimitCheck.AllCheck)
	end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	index = index + 1
	if id == "List_Item" then
		if self._Selected_Item._Index == index then
			return
		end
		self._Selected_Item._Item:FindChild("Img_Selected"):SetActive(false)
		self._Selected_Item._Item = item
		self._Selected_Item._Index = index
		self._Selected_Item._Item:FindChild("Img_Selected"):SetActive(true)
		self:UpdateUIRewardInfo()
	end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	index = index + 1
	if id == "List_Item" then
		local itemBag = self._OwnedPrayItems[index]
		CItemTipMan.ShowItemTips(itemBag.Tid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
	elseif id == "List_Reward" then
		local itemBag = self._OwnedPrayItems[self._Selected_Item._Index]
		local itemTid = CElementData.GetTemplate("GuildPrayItem", itemBag.Template.PrayId).RewardItemID
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
	end
end

-- 初始化模板信息等
def.method().OnInit = function(self)
	self._Building_Info = game._HostPlayer._Guild._BuildingList[GuildBuildingType.PrayPool]

	self._Quality_Des = ""
	self._Quality_Des = self._Quality_Des .. StringTable.Get(10010) .. ","
	local quality_1 = game._GuildMan:GetPrayItemColor(StringTable.Get(10002) .. StringTable.Get(10007), 1)
	local quality_2 = game._GuildMan:GetPrayItemColor(StringTable.Get(10003) .. StringTable.Get(10007), 2)
	local quality_3 = game._GuildMan:GetPrayItemColor(StringTable.Get(10005) .. StringTable.Get(10007), 3)
	self._Quality_Des = self._Quality_Des .. quality_1 .. ","
	self._Quality_Des = self._Quality_Des .. quality_2 .. ","
	self._Quality_Des = self._Quality_Des .. quality_3

	self._Quality_Filter_Index = 1
	GUI.SetDropDownOption(self._DropDown, self._Quality_Des)
	GameUtil.SetDropdownValue(self._DropDown, self._Quality_Filter_Index - 1)
	local dropTemplate = self._DropDown:FindChild("Drop_Template")
	GUITools.SetupDropdownTemplate(self, dropTemplate)

	self:UpdateBagPrayInfo()
	self:UpdateUIRewardInfo()
end

local function GetCorrespondItemTid(prayItemTid)
	return prayItemTid + 24000 - 1  -- 默认的对应关系
end

def.method().UpdateUIRewardInfo = function(self)
	if self._Selected_Item == nil then
		return
	end

	local index = self._Selected_Item._Index
	local itemBag = self._OwnedPrayItems[index]
	local str = StringTable.Get(10000 + itemBag.Template.InitQuality)
	str = RichTextTools.GetQualityText(str, itemBag.Template.InitQuality)
	GUI.SetText(self._ItemDescLabel_2, str)
	GUI.SetText(self._ItemDescLabel_3, itemBag.Template.TextDescription)

	if itemBag.Count > 0 then
        self._Btn_Puton:SetActive(true)
        self._Btn_Approach:SetActive(false)
	else
        self._Btn_Puton:SetActive(false)
        self._Btn_Approach:SetActive(true)
	end

	self._List_Reward:SetItemCount(1)
end

-- 背包信息刷新
def.method().UpdateBagPrayInfo = function(self)
	if not self:IsShow() then return end
	self._OwnedPrayItems = { }

	local normalPack = game._HostPlayer._Package._NormalPack
	local allTid = GameUtil.GetAllTid("GuildPrayItem")

	for k, v in ipairs(allTid) do
		local tid = GetCorrespondItemTid(v)
		if tid > 0 then
			local item = CElementData.GetTemplate("Item", tid)
			if item.ItemType == EItemType.Pray then
				local quality = self._Quality_Filter_Index
				local canAdd2List = quality == 1  -- 全部品质
								or(quality == 2 and item.InitQuality == ItemQuality.Rare)  -- 稀有
								or(quality == 3 and item.InitQuality == ItemQuality.Epic)  -- 史诗
								or(quality == 4 and item.InitQuality == ItemQuality.Legend)  -- 传说
				if canAdd2List then
					local prayItemInfo = { }
					prayItemInfo.Tid = tid
					prayItemInfo.Template = item
					prayItemInfo.GuildPrayTemplate = CElementData.GetTemplate("GuildPrayItem", v)
					prayItemInfo.Count = normalPack:GetItemCount(tid)
					self._OwnedPrayItems[#self._OwnedPrayItems + 1] = prayItemInfo
				end
			else
				local msg = string.format("Item %d is not a prayItem. Need to Fix", tid)
				warn(msg)
			end
		end
	end

	local count = #self._OwnedPrayItems
	if count > 1 then
		local function sortFunc(itm1, itm2)
			if itm1.Count > 0 and itm2.Count == 0 then
				return true
			elseif itm1.Count == 0 and itm2.Count > 0 then
				return false
			else
				return itm1.Template.InitQuality < itm2.Template.InitQuality
			end
		end
		table.sort(self._OwnedPrayItems, sortFunc)
	end

	if count > 0 then
		self._Img_List_Item:SetActive(true)
		self._Bottom:SetActive(true)
		self._List_Item:SetItemCount(count)
		-- 目前仅有1个奖励ID
		self._List_Reward:SetItemCount(1)
	else
		self._Img_List_Item:SetActive(false)
		self._Bottom:SetActive(false)
	end
end

-- 返回自己月光庭院
def.method().OnBtnBackOther = function(self)
	self:ResetTimerID()
	self:ShowSelfMoon()
end

-- 打开商店界面
def.method().OnBtnShop = function(self)
	game._GuildMan:OpenGuildShop()
end

-- 打开帮助界面
def.method().OnBtnHelp = function(self)
	self:OnC2SGuildHelperList()
end

-- 打开事件界面
def.method().OnBtnEvent = function(self)
	self:OnC2SGuildPrayViewRecord()
end

-- 展示自己庭院
def.method().ShowSelfMoon = function(self)
	self._Self:SetActive(true)
	self._Center:SetActive(true)
	self._Money:SetActive(true)
	self._Other:SetActive(false)
	self._IsShownSelfPool = true
	self._Selected_PoolIndex = 1

	self:ShowUIPrayPool()
	self:UpdateUITitle()
end

-- 展示别人庭院
def.method().ShowOtherMoon = function(self)
	self._Self:SetActive(false)
	self._Center:SetActive(false)
	self._Money:SetActive(false)
	self._Other:SetActive(true)
	self._IsShownSelfPool = false
	self._Selected_PoolIndex = 0

	self:ShowUIPrayPool()
	self:UpdateUITitle()
end

-- 刷新许愿池信息
def.method("dynamic").UpdatePrayData = function(self, data)
	if type(data) == "table" then
		for i, v in ipairs(self._Pray_Data) do
			if i == data.PoolIndex then
				v._PrayItem = data
			end
		end
	else
		for i, v in ipairs(self._Pray_Data) do
			if i == data then
				v._PrayItem = nil
			end
		end
	end

	if self._IsShownSelfPool then
		self:ShowUIPrayPool()
	end

end

-----------------------------
-----------------------------界面柱子特效功能
def.method().InitUIPoolItems = function(self)
	local obj = nil
	local name_pfx = "Pool_My_"
	local pool = self._MyWishPool

	for i = 1, PRAY_OPEN_COUNT do
		local ui_pool_item = { }
		ui_pool_item.isUnlock = false
		ui_pool_item.colorID = 0
		ui_pool_item.canSpeedUp = false
		ui_pool_item.isDone = false
		ui_pool_item.timerID = 0

		obj = self:GetUIObject(name_pfx ..(i))

		local ui_template = obj:GetComponent(ClassType.UITemplate)
		ui_pool_item.obj = obj
		ui_pool_item.DT = obj:GetComponent(ClassType.DOTweenPlayer)
		ui_pool_item.objUnlock = ui_template:GetControl(0)
		-- Img_UnLock
		--GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_Img_Always, ui_pool_item.objUnlock, ui_pool_item.objUnlock, -1)
		ui_pool_item.objSelected = ui_template:GetControl(1)
		-- Img_Selected
		GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_Img_Selected, ui_pool_item.objSelected, ui_pool_item.objSelected, -1)

		ui_pool_item.objBtnSpeed = ui_template:GetControl(2)
		-- Btn_Speed_
		ui_pool_item.objLabTime = ui_template:GetControl(3)
		-- Lab_Sp_Time
		ui_pool_item.objBtnReward = ui_template:GetControl(4)
		-- Btn_Reward_
		ui_pool_item.objIconReward = ui_template:GetControl(5)
		pool[i] = ui_pool_item
	end
end

def.method().ClearUIPoolItems = function(self)
	local ui_pool_item = nil
	for i = 1, PRAY_OPEN_COUNT do
		ui_pool_item = self._MyWishPool[i]
		ui_pool_item.isUnlock = false
		ui_pool_item.colorID = 0
		ui_pool_item.canSpeedUp = false
		ui_pool_item.isDone = false
		ui_pool_item.timerID = 0

		ui_pool_item.obj = nil
		ui_pool_item.DT = nil
		ui_pool_item.objUnlock = nil
		ui_pool_item.objSelected = nil

		ui_pool_item.objBtnSpeed = nil
		ui_pool_item.objLabTime = nil
		ui_pool_item.objBtnReward = nil
		ui_pool_item.objIconReward = nil
	end

	self._MyWishPool = { }
end

def.method("boolean", "number", "boolean").UpdateUIPoolUnlock = function(self, is_self, i, is_unlock)
	-- local function UpdateUIPoolUnLock(self, is_self, i, is_unlock)
	local ui_pool_item = self._MyWishPool[i]
	ui_pool_item.objUnlock:SetActive(is_unlock)
	if ui_pool_item.isUnlock ~= is_unlock then
		if is_unlock then
			ui_pool_item.DT:Restart("1")
		else
			ui_pool_item.DT:Stop("1")
		end
		ui_pool_item.isUnlock = is_unlock
	end
end

local function _UpdateSeedFX(color_id, obj, is_play, is_done)
	if color_id == 0 then return end

	local fx_path = nil
	if is_done then
		if color_id == ItemQuality.Epic then
			fx_path = PATH.UI_Guild_Pray_Sfx_Done_Purple
		elseif color_id == ItemQuality.Legend then
			fx_path = PATH.UI_Guild_Pray_Sfx_Done_Yellow
		else
			fx_path = PATH.UI_Guild_Pray_Sfx_Done_Blue
		end
	else
		if color_id == ItemQuality.Epic then
			fx_path = PATH.UI_Guild_Pray_Sfx_Always_Purple
		elseif color_id == ItemQuality.Legend then
			fx_path = PATH.UI_Guild_Pray_Sfx_Always_Yellow
		else
			fx_path = PATH.UI_Guild_Pray_Sfx_Always_Blue
		end
	end

	if is_play then
		GameUtil.PlayUISfx(fx_path, obj, obj, -1)
	else
		GameUtil.StopUISfx(fx_path, obj)
	end
end

def.method("boolean", "number", "number", "boolean").UpdateUIPoolProgress = function(self, is_self, i, color_id, is_done)
	local ui_pool_item = self._MyWishPool[i]
	if ui_pool_item.colorID ~= color_id or ui_pool_item.isDone ~= is_done then
		_UpdateSeedFX(ui_pool_item.colorID, ui_pool_item.objUnlock, false, ui_pool_item.isDone)
		_UpdateSeedFX(color_id, ui_pool_item.objUnlock, true, is_done)

		ui_pool_item.colorID = color_id
		ui_pool_item.isDone = is_done
	end

	if color_id > 0 then
		if is_done then
			if is_self then
				ui_pool_item.objBtnReward:SetActive(true)
				GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_Btn_Speed_2_Reward, ui_pool_item.objIconReward, ui_pool_item.objIconReward, -1)
			else
				ui_pool_item.objBtnReward:SetActive(false)
			end
		else
			ui_pool_item.objBtnReward:SetActive(false)
		end
        GUITools.SetGroupImg(ui_pool_item.objUnlock, 0)
		ui_pool_item.objBtnSpeed:SetActive((not is_done) and ui_pool_item.canSpeedUp)
	else
		ui_pool_item.objBtnSpeed:SetActive(false)
		ui_pool_item.objBtnReward:SetActive(false)
        GUITools.SetGroupImg(ui_pool_item.objUnlock, 1)
	end
end

def.method("number","boolean").ShowUIPoolSpeedBtn = function(self, i, can_speedUp)
	local ui_pool_item = self._MyWishPool[i]
	ui_pool_item.canSpeedUp = can_speedUp

	local active = ui_pool_item.colorID > 0 and (not ui_pool_item.isDone) and ui_pool_item.canSpeedUp
	ui_pool_item.objBtnSpeed:SetActive(active)
end

def.method("boolean", "number", "boolean").UpdateUIPoolSelected = function(self, is_self, i, is_selected)
	local ui_pool_item = nil
	if i > 0 and i <= PRAY_OPEN_COUNT then
		ui_pool_item = self._MyWishPool[i]
		ui_pool_item.objSelected:SetActive(is_self and is_selected)
	end
end

-- 展示标题
def.method().UpdateUITitle = function(self)
	if self._IsShownSelfPool then
		GUI.SetText(self._TitleLabel, StringTable.Get(8121))
	else
		GUI.SetText(self._TitleLabel, string.format(StringTable.Get(8122), self._Member_Other._RoleName))
	end
end

def.method("number").SetSelectedIndex = function(self, index)
	self:UpdateUIPoolSelected(self._IsShownSelfPool, self._Selected_PoolIndex, false)
	self._Selected_PoolIndex = index
	self:UpdateUIPoolSelected(self._IsShownSelfPool, self._Selected_PoolIndex, true)
end

def.method("number").PlayUIPoolSpeedFX=function(self, index)
	local ui_pool_item = self._MyWishPool[index]
	if ui_pool_item.colorID == 0 then return end

	local fx_path = PATH.UI_Guild_Pray_Sfx_Speed_Blue
	if ui_pool_item.colorID == ItemQuality.Epic then
		fx_path = PATH.UI_Guild_Pray_Sfx_Speed_Purple
	elseif ui_pool_item.colorID == ItemQuality.Legend then
		fx_path = PATH.UI_Guild_Pray_Sfx_Speed_Yellow
	end
	GameUtil.PlayUISfx(fx_path, ui_pool_item.objUnlock, ui_pool_item.objUnlock, -1)
end

-- 重置计时器Id
def.method().ResetTimerID = function(self)
	for i, v in ipairs(self._MyWishPool) do
		if v.timerID ~= 0 then
			_G.RemoveGlobalTimer(v.timerID)
			v.timerID = 0
		end
	end
end

def.method().ShowUIPrayPool = function(self)
	local data = nil
	local ui_pool_item = nil
	self:ResetTimerID()
	if self._IsShownSelfPool then
		data = self._Pray_Data
	else
		data = self._Pray_Data_Other
	end

	local serverTime = GameUtil.GetServerTime() / 1000
	for i, v in ipairs(data) do
		ui_pool_item = self._MyWishPool[i]

		if self._IsShownSelfPool then
			self:UpdateUIPoolUnlock(true, i, v._IsOwn)
			self:UpdateUIPoolSelected(true, i, i == self._Selected_PoolIndex)

			if v._PrayItem ~= nil then
				local item = CElementData.GetTemplate("Item", v._PrayItem.ItemTID)
				local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
				local time = math.floor(v._PrayItem.CompleteTime -(serverTime - v._PrayItem.StartTime))
				--local maxTime = prayItem.CompleteTime
				if time > 0 then

					warn("ShowUIPoolSpeedBtn")
					self:ShowUIPoolSpeedBtn(i, true)

					local callback = function()
						local ui_pool_item = self._MyWishPool[i]
						GUI.SetText(ui_pool_item.objLabTime, game._GuildMan:GetTimeNum(time))
						ui_pool_item.objLabTime:SetActive(true)
						if time <= 0 then
							_G.RemoveGlobalTimer(ui_pool_item.timerID)
							self:UpdateUIPoolProgress(true, i, item.InitQuality, true)
						end
						time = time - 1
					end
					ui_pool_item.timerID = _G.AddGlobalTimer(1, false, callback)
				end
				self:UpdateUIPoolProgress(true, i, item.InitQuality, time <= 0)
			else
				ui_pool_item.objBtnSpeed:SetActive(false)
				ui_pool_item.objBtnReward:SetActive(false)
				self:UpdateUIPoolProgress(true, i, 0, false)
			end
		else
			-- Other
			self:UpdateUIPoolUnlock(false, i, v._IsOwn)
			self:UpdateUIPoolSelected(false, i, false)

			if v._PrayItem ~= nil then
				local item = CElementData.GetTemplate("Item", v._PrayItem.ItemTID)
				local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
				local time = math.floor(v._PrayItem.CompleteTime -(serverTime - v._PrayItem.StartTime))

				if time > 0 then
		 			local deltaTime = serverTime - v._PrayItem.LastHelpTime
		 			if deltaTime >= prayItem.PrayCD then
		 				GUI.SetText(ui_pool_item.objLabTime, StringTable.Get(8119))
						self:ShowUIPoolSpeedBtn(i,true)
		 			else
		 				GUI.SetText(ui_pool_item.objLabTime, StringTable.Get(8120))
						self:ShowUIPoolSpeedBtn(i,false)
		 			end

					local function callback()
							local ui_pool_item = self._MyWishPool[i]
							if time <= 0 then
								_G.RemoveGlobalTimer(ui_pool_item.timerID)
								self:UpdateUIPoolProgress(false, i, item.InitQuality, true)
							end

							if GameUtil.GetServerTime() / 1000 - v._PrayItem.LastHelpTime >= prayItem.PrayCD then
								ui_pool_item.objLabTime:SetActive(true)
								self:ShowUIPoolSpeedBtn(i,true)
							end

							time = time - 1
						end
					ui_pool_item.timerID = _G.AddGlobalTimer(1, false, callback)
				end
				ui_pool_item.objLabTime:SetActive(time > 0)
				self:UpdateUIPoolProgress(false, i, item.InitQuality, time <= 0)
			else
				ui_pool_item.objLabTime:SetActive(false)
				self:UpdateUIPoolProgress(false, i, 0, false)
			end
		end
	end
end

-- 初始化别人许愿池信息
def.method("table").InitPrayDataOther = function(self, data)
	if not self:IsShow() then return end
	self:ResetTimerID()
	self._Member_Other = game._HostPlayer._Guild._MemberList[data._MemberInfo.roleID]
	local allTid = GameUtil.GetAllTid("GuildPrayPool")
	local buildingLevel = self._Building_Info._BuildingLevel
	self._Pray_Data_Other = { }
	for i = 1, #allTid do
		local prayPool = CElementData.GetTemplate("GuildPrayPool", allTid[i])
		self._Pray_Data_Other[i] = { }
		self._Pray_Data_Other[i]._IsOwn = buildingLevel >= prayPool.NeedBuildLevel
		self._Pray_Data_Other[i]._NeedLevel = prayPool.NeedBuildLevel
	end
	for i = 1, #data._PrayItems do
		self._Pray_Data_Other[data._PrayItems[i].PoolIndex]._PrayItem = data._PrayItems[i]
	end

	self:ShowOtherMoon()
end

-- 刷新别人许愿池信息
def.method("table").OnUpdatePrayDataOther = function(self, data)
	for i, v in ipairs(self._Pray_Data_Other) do
		if i == data.PoolIndex then
			v._PrayItem = data
		end
	end

	if not self._IsShownSelfPool then
		self:ShowUIPrayPool()
	end
end

-- 打开祈祷池
def.method("number").OnBtnPrayPool = function(self, index)
	if index >= 1 and index <= PRAY_OPEN_COUNT then
		local data = self._Pray_Data[index]
		local ui_pool_item = self._MyWishPool[index]
		if data._IsOwn then
			GameUtil.PlayUISfx(PATH.UI_Guild_Pray_Sfx_Img_Selected2, ui_pool_item.objUnlock, ui_pool_item.objUnlock, -1)

			if index == self._Selected_PoolIndex then
				return
			end

			self:SetSelectedIndex(index)
		else
			game._GUIMan:ShowTipText(string.format(StringTable.Get(895), self._Building_Info._BuildingName, data._NeedLevel), true)
		end
	elseif index <= PRAY_TOTAL_COUNT then
		game._GUIMan:ShowTipText(StringTable.Get(900), true)
	end
end

-- 点击加速按钮
def.method("number").OnBtnSpeed = function(self, index)
	if index < 1 and index > PRAY_OPEN_COUNT then return end

	local data = self._Pray_Data[index]._PrayItem
	local item = CElementData.GetTemplate("Item", data.ItemTID)
	local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
	local time = data.CompleteTime -(GameUtil.GetServerTime() / 1000 - data.StartTime)
	local scale = time / data.CompleteTime
	local cost = math.ceil(prayItem.CompleteCost * scale)

	local callback = function(value)
		if value then
			self:OnC2SGuildPrayReduceTime(index)
		end
	end
	if game._HostPlayer:GetBindDiamonds() < cost then
		MsgBox.ShowQuickBuyBox(3, cost, callback)
		return
	end
	local title, msg, closeType = StringTable.GetMsg(32)
    local setting = {
        [MsgBoxAddParam.CostMoneyID] = 3,
        [MsgBoxAddParam.CostMoneyCount] = cost,
    }
	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Normal, setting)
	self:SetSelectedIndex(index)
end

-- 点击帮助按钮
def.method("number").OnBtnPrayHelp = function(self, index)
	if index < 1 and index > PRAY_OPEN_COUNT then return end

	if game._HostPlayer._Guild:GetHelpNum() == 0 then
		game._GUIMan:ShowTipText(StringTable.Get(8043), true)
	else
		local data = self._Pray_Data_Other[index]._PrayItem
		local item = CElementData.GetTemplate("Item", data.ItemTID)
		local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
		local deltaTime = GameUtil.GetServerTime() / 1000 - data.LastHelpTime
		if deltaTime > prayItem.PrayCD then
			self:OnC2SGuildPrayHelpPray(self._Member_Other._RoleID, index)
		else
			game._GUIMan:ShowTipText(StringTable.Get(8044), true)
		end
	end
end

-- 点击奖励按钮
def.method("number").OnBtnReward = function(self, index)
	if index < 1 and index > PRAY_OPEN_COUNT then return end

	local item = CElementData.GetTemplate("Item", self._Pray_Data[index]._PrayItem.ItemTID)
	local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
	if not game._HostPlayer:HasEnoughSpace(prayItem.RewardItemID, true, prayItem.RewardItemNum) then
		game._GUIMan:ShowTipText(StringTable.Get(256), true)
		return
	end
	self:OnC2SGuildPrayDrawReward(index)
	self:SetSelectedIndex(index)
end

-- 点击放入按钮
def.method().OnBtnPuton = function(self)
	if self._Selected_Item == nil then
		return
	end
	local data = self._Pray_Data[self._Selected_PoolIndex]
	if data._PrayItem == nil then
		local itemTid = self._OwnedPrayItems[self._Selected_Item._Index].Tid
		self:OnC2SGuildPrayPutOnItem(self._Selected_PoolIndex, itemTid)
	else
		local time = data._PrayItem.CompleteTime -(GameUtil.GetServerTime() / 1000 - data._PrayItem.StartTime)
		if time > 0 then
			game._GUIMan:ShowTipText(StringTable.Get(8041), true)
		else
			game._GUIMan:ShowTipText(StringTable.Get(8042), true)
		end
	end
end

def.method().OnBtnApproach = function(self)
    local index = self._Selected_Item._Index
	local itemBag = self._OwnedPrayItems[index]
    local PanelData = 
    {
        ApproachIDs = itemBag.Template.ApproachIDs,
        ParentObj = self._Btn_Approach,
        IsFromTip = false,
        TipPanel = self,
        ItemId = itemBag.Tid,
    }
    game._GUIMan:Open("CPanelItemApproach",PanelData)
end

-- =========================================协议开始===========================================
-- 领取祈祷奖励
def.method("number").OnC2SGuildPrayDrawReward = function(self, index)
	local protocol =(require "PB.net".C2SGuildPrayDrawReward)()
	protocol.PoolIndex = index
	PBHelper.Send(protocol)
end

-- 查看祈祷记录
def.method().OnC2SGuildPrayViewRecord = function(self)
	local protocol =(require "PB.net".C2SGuildPrayViewRecord)()
	PBHelper.Send(protocol)
end

-- 祈祷加速
def.method("number").OnC2SGuildPrayReduceTime = function(self, index)
	local protocol =(require "PB.net".C2SGuildPrayReduceTime)()
	protocol.PoolIndex = index
	PBHelper.Send(protocol)
end

-- 查看帮助列表
def.method().OnC2SGuildHelperList = function(self)
	local protocol =(require "PB.net".C2SGuildPrayHelperList)()
	PBHelper.Send(protocol)
end

-- 放置祈祷道具
def.method("number", "number").OnC2SGuildPrayPutOnItem = function(self, index, itemTid)
	local protocol =(require "PB.net".C2SGuildPrayPutOnItem)()
	protocol.PoolIndex = index
	protocol.ItemTID = itemTid
	PBHelper.Send(protocol)
end

-- 帮助祈祷
def.method("number", "number").OnC2SGuildPrayHelpPray = function(self, roleId, index)
	local protocol =(require "PB.net".C2SGuildPrayHelpPray)()
	protocol.TargetRole = roleId
	protocol.PoolIndex = index
	PBHelper.Send(protocol)
end

--S2C

--放置祈祷道具
def.method("table").OnS2CGuildPrayPutOnItem = function(self, pray_item)
	if self:IsShow() then
		self:UpdatePrayData(pray_item)
		self:UpdateBagPrayInfo()
		self:UpdateUIRewardInfo()
	end
end

--帮别人加速
def.method("table").OnS2CGuildPrayHelpPray = function(self, pray_item)
	if self:IsShow() then
        self:OnUpdatePrayDataOther(pray_item)
		if not self._IsShownSelfPool then
			self:PlayUIPoolSpeedFX(pray_item.PoolIndex)

			self:ShowUIPoolSpeedBtn(pray_item.PoolIndex, false)
		end
	end
end

--别人给我加速
def.method("table").OnS2CGuildPrayReduceTime = function(self, pray_item)
	if self:IsShow() then
		self:UpdatePrayData(pray_item)

		if self._IsShownSelfPool then
			self:PlayUIPoolSpeedFX(pray_item.PoolIndex)
		end
	end
end

-- =========================================协议结束===========================================

-- 当摧毁
def.override().OnDestroy = function(self)
	self:ResetTimerID()
	self:ClearUIPoolItems()

	self._Center=nil

	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	instance = nil
end

CPanelUIGuildPray.Commit()
return CPanelUIGuildPray