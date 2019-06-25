--
--公会战场结束界面
--
--【孟令康】
--
--2018年08月06日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelUIGuildBattleResult = Lplus.Extend(CPanelBase, "CPanelUIGuildBattleResult")
local def = CPanelUIGuildBattleResult.define

def.field("table")._Data = nil
def.field("table")._RewardData = nil

def.field("table")._Guild_Icon_Image = nil
def.field("userdata")._Guild_Level_Num = nil
def.field("userdata")._Guild_Name = nil
def.field("userdata")._Lab_Kill_Num = nil
def.field("userdata")._Lab_Dead_Num = nil
def.field("userdata")._Lab_Hp_Num = nil
def.field("userdata")._Lab_Progress_Num = nil
def.field("userdata")._RewardList = nil
def.field("userdata")._Lab_Tip = nil
def.field("boolean")._CanClose = false
def.field("number")._CloseTimer = 0
def.field("number")._LeftTime = 5

local instance = nil
def.static("=>", CPanelUIGuildBattleResult).Instance = function()
	if not instance then
		instance = CPanelUIGuildBattleResult()
		instance._PrefabPath = PATH.UI_Guild_Battle_Result
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitObject()
	self:OnInit()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Data = data
	GUI.SetText(self._Lab_Kill_Num, tostring(data.KillNum))
	GUI.SetText(self._Lab_Dead_Num, tostring(data.DeathNum))
	GUI.SetText(self._Lab_Hp_Num, tostring(data.Dmg))
	GUI.SetText(self._Lab_Progress_Num, game._GuildMan:GetTimeNum(data.PassTime))
    GUI.SetText(self._Lab_Tip, tostring( string.format(StringTable.Get(31606), self._LeftTime)))
	-- 维持与通用显示一致
	self._RewardData = {}
	for i, v in ipairs(data.Rewards) do
		local reward = {}
		if v.MoneyNum ~= 0 then
			reward.IsTokenMoney = true
			reward.Data = {}
			reward.Data.Id = v.MoneyId
			reward.Data.Count = v.MoneyNum
		else
			reward.IsTokenMoney = false			
			reward.Data = {}		
			reward.Data.Id = v.ItemId
			reward.Data.Count = v.ItemNum
		end
		self._RewardData[#self._RewardData + 1] = reward
	end
	self._RewardList:SetItemCount(#self._RewardData)
    self:AddCloseTimer()
end

def.method().OnInitObject = function(self)
	self._Guild_Icon_Image = {}
	self._Guild_Icon_Image[1] = self:GetUIObject("Img_Flag_Bg")
	self._Guild_Icon_Image[2] = self:GetUIObject("Img_Flag_Flower_1")
	self._Guild_Icon_Image[3] = self:GetUIObject("Img_Flag_Flower_2")
	self._Guild_Level_Num = self:GetUIObject("Guild_Level_Num")
	self._Guild_Name = self:GetUIObject("Guild_Name")
	self._Lab_Kill_Num = self:GetUIObject("Lab_Kill_Num")
	self._Lab_Dead_Num = self:GetUIObject("Lab_Dead_Num")
	self._Lab_Hp_Num = self:GetUIObject("Lab_Hp_Num")
	self._Lab_Progress_Num = self:GetUIObject("Lab_Progress_Num")
    self._Lab_Tip = self:GetUIObject("Lab0")
	self._RewardList = self:GetUIObject("RewardList"):GetComponent(ClassType.GNewList)
end

def.method().OnInit = function(self)
	game._GuildMan:SetGuildUseIcon(self._Guild_Icon_Image)
	GUI.SetText(self._Guild_Name, game._HostPlayer._Guild._GuildName)
	GUI.SetText(self._Guild_Level_Num, tostring(game._HostPlayer._Guild._GuildLevel))
end

def.method().AddCloseTimer = function(self)
    local callback = function()
        self._LeftTime = self._LeftTime - 1
        if self._LeftTime <= 0 then
            _G.RemoveGlobalTimer(self._CloseTimer)
            self._CloseTimer = 0
            self._CanClose = true
            GUI.SetText(self._Lab_Tip, tostring(StringTable.Get(31607)))
        else
            GUI.SetText(self._Lab_Tip, tostring( string.format(StringTable.Get(31606), self._LeftTime)))
        end
    end
    self._CloseTimer = _G.AddGlobalTimer(1, false, callback)
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "RewardList" then
    	index = index + 1
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local data = self._RewardData[index]
        if data.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(item, data.Data.Id, data.Data.Count)
        else
            local setting = {
                [EItemIconTag.Number] = data.Data.Count,
            }
            IconTools.InitItemIconNew(item, data.Data.Id, setting, EItemLimitCheck.AllCheck)
        end
    end
end

-- 选中列表按钮
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "RewardList" then
    	index = index + 1
		local itemTid = self._RewardData[index].Data.Id
        local data = self._RewardData[index]
        if data.IsTokenMoney then
            local panelData = 
            {
                _MoneyID = itemTid,
                _TipPos = TipPosition.FIX_POSITION,
                _TargetObj = item,
            } 
            CItemTipMan.ShowMoneyTips(panelData)
        else
		    CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
        end
    end
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Continue" then
		self:OnBtnContinue()
	elseif id == "Btn_Rank" then
		self:OnBtnRank()
	end
end


-- 查看排名
def.method().OnBtnRank = function(self)
	local data = {}
	if self._Data.Camp == 1 then
		data._Self = self._Data.RedList
		data._Other = self._Data.BlackList
	else
		data._Other = self._Data.RedList
		data._Self = self._Data.BlackList
	end
	game._GUIMan:Open("CPanelUIBattleDamage", data)
end

-- 点击屏幕继续
def.method().OnBtnContinue = function(self)
    if self._CanClose then
	    game._GUIMan:CloseByScript(self)
	    game._DungeonMan:TryExitDungeon()
    end
end

-- 当摧毁
def.override().OnDestroy = function(self)
    self._CanClose = false
    self._LeftTime = 5
    if self._CloseTimer ~= 0 then
        _G.RemoveGlobalTimer(self._CloseTimer)
        self._CloseTimer = 0
    end
	instance = nil
end

CPanelUIGuildBattleResult.Commit()
return CPanelUIGuildBattleResult