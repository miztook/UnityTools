--
--公会战场主界面
--
--【孟令康】
--
--2018年08月02日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CGuildIconInfo = require "Guild.CGuildIconInfo"
local MemberType = require "PB.data".GuildMemberType

local CPanelUIGuildBattle = Lplus.Extend(CPanelBase, "CPanelUIGuildBattle")
local def = CPanelUIGuildBattle.define

-- 模板Tid
def.field("number")._Battle_Tid = 1
def.field("table")._Member_Set = nil
-- 显示内容
def.field("number")._Show_Index = 1
-- 提示内容
def.field("number")._Remind_Index = 2
def.field("boolean")._Is_Leader = false
def.field("table")._RewardData = nil

def.field("userdata")._Lab_Des = nil
def.field("userdata")._RewardList = nil
def.field("userdata")._Frame_OtherReward_1 = nil
--def.field("userdata")._Img_OtherReward_1 = nil
--def.field("userdata")._Lab_OtherReward_1 = nil
--def.field("userdata")._Img_OtherReward_2 = nil
--def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Lab_Level_Num = nil
def.field("userdata")._Lab_Member_Num = nil
def.field("userdata")._Btn_Member_Set = nil
def.field("userdata")._Lab_Sign_Num = nil
def.field("userdata")._Lab_Open_Num = nil
def.field("userdata")._Lab_Condition_Des = nil
def.field("userdata")._Btn_Sign = nil
def.field("userdata")._Img_Enter0 = nil
def.field("userdata")._Lab0 = nil
def.field("userdata")._Btn_Start = nil
def.field("userdata")._Img_Enter1 = nil
def.field("userdata")._Btn_Show = nil
def.field("userdata")._Lab_Remind= nil
def.field("userdata")._Close = nil
def.field("userdata")._Open = nil
def.field("userdata")._Lab_Need_Score = nil
def.field("userdata")._Lab_Have_Score = nil

local instance = nil
def.static("=>", CPanelUIGuildBattle).Instance = function()
	if not instance then
		instance = CPanelUIGuildBattle()
		instance._PrefabPath = PATH.UI_Guild_Battle
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:InitObject()
	self:Init()
	self._HelpUrlType = HelpPageUrlType.Guild_Battle
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self:InitData(data)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()	
	elseif id == "Btn_Member_Set" then
		self:OnBtnMemberSet()
	elseif id == "Btn_Sign" then
		self:OnBtnSign()
	elseif id == "Btn_Start" then
		self:OnBtnStart()
	elseif id == "Btn_Show" then
		self:OnBtnShow()
    elseif id == "Btn_Rank" then
        game._GUIMan:Open("CPanelRanking", 12)
    elseif id == "Btn_BattleRule" then
        game._GUIMan:Open("CPanelRuleDescription",7)
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_Reward" then
    	index = index + 1
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local data = self._RewardData[index]
        if data.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(uiTemplate:GetControl(0), data.Data.Id, data.Data.Count)
        else
		    local setting =
		    {
			    [EItemIconTag.Probability] = data.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
		    }
		    IconTools.InitItemIconNew(uiTemplate:GetControl(0), data.Data.Id, setting)
        end
    end
end

-- 选中列表按钮
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Reward" then
		local itemTid = self._RewardData[index + 1].Data.Id
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
    end
end

def.method().Init = function(self)
	local member = game._GuildMan:GetHostGuildMemberInfo()
    local liveness = game._HostPlayer._Guild._GuildLiveness
    local liveness_need = tonumber(CSpecialIdMan.GetDefault("GuildBattleNeedScore"))
	if member == nil then return end
	self._Member_Set = {}
	self._Member_Set[1] = StringTable.Get(8092)
	self._Member_Set[2] = StringTable.Get(8093)
	self._Is_Leader = (member._RoleType == MemberType.GuildLeader)
	self._Btn_Member_Set:SetActive(self._Is_Leader)
	local guildBattle = CElementData.GetTemplate("GuildBattle", self._Battle_Tid)
	GUI.SetText(self._Lab_Des, guildBattle.Description)
	self._RewardData = GUITools.GetRewardList(guildBattle.RewardId, true)
	self._RewardList:SetItemCount(#self._RewardData)
--	if self._MoneyData[1] ~= nil then
--		self._Frame_OtherReward_1:SetActive(true)
--		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, self._MoneyData[1].Data.Id)
--		GUI.SetText(self._Lab_OtherReward_1, tostring(self._MoneyData[1].Data.Count))
--	else
--		self._Frame_OtherReward_1:SetActive(false)
--	end
--	if self._MoneyData[2] ~= nil then
--		self._Frame_OtherReward_2:SetActive(true)
--		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, self._MoneyData[2].Data.Id)
--		GUI.SetText(self._Lab_OtherReward_2, tostring(self._MoneyData[2].Data.Count))
--	else
--		self._Frame_OtherReward_2:SetActive(false)
--	end
	GUI.SetText(self._Lab_Sign_Num, CSpecialIdMan.GetDefault("GuildBattleSignDes"))
	GUI.SetText(self._Lab_Open_Num, CSpecialIdMan.GetDefault("GuildBattleOpenDes"))
    GUI.SetText(self._Lab_Need_Score, liveness_need.."")
    if liveness >= liveness_need then
        GUI.SetText(self._Lab_Have_Score, liveness .. "")
    else
        GUI.SetText(self._Lab_Have_Score, string.format(StringTable.Get(20414), liveness))
    end
end

def.method().InitObject = function(self)
	self._Lab_Des = self:GetUIObject("Lab_Des")
	self._RewardList = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
--	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
--	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
--	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
--	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
--	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
--	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Lab_Level_Num = self:GetUIObject("Lab_Level_Num")
	self._Lab_Member_Num = self:GetUIObject("Lab_Member_Num")
	self._Btn_Member_Set = self:GetUIObject("Btn_Member_Set")
	self._Lab_Sign_Num = self:GetUIObject("Lab_Sign_Num")
	self._Lab_Open_Num = self:GetUIObject("Lab_Open_Num")
	self._Lab_Condition_Des = self:GetUIObject("Lab_Close")
	self._Btn_Sign = self:GetUIObject("Btn_Sign")
	self._Img_Enter0 = self:GetUIObject("Img_Enter0")
	self._Lab0 = self:GetUIObject("Lab0")
	self._Btn_Start = self:GetUIObject("Btn_Start")
	self._Img_Enter1 = self:GetUIObject("Img_Enter1")
	self._Btn_Show = self:GetUIObject("Btn_Show")
	self._Lab_Remind = self:GetUIObject("Lab_Remind")
    self._Open = self:GetUIObject("Open")
    self._Close = self:GetUIObject("Close")
    self._Lab_Need_Score = self:GetUIObject("Lab_NeedScore")
    self._Lab_Have_Score = self:GetUIObject("Lab_HaveScore")


    local bg = self:GetUIObject("Img_BG")
	local Img_Vs = self:GetUIObject("Img_Vs")
	GameUtil.PlayUISfx(PATH.UI_Guild_Battle_Sfx_ImgBG,bg,bg,-1)
	GameUtil.PlayUISfx(PATH.UI_Guild_Battle_Sfx_ImgVS,Img_Vs,Img_Vs,-1)
	
end

def.method("table").InitData = function(self, data)
	if data.Position == 3 then
		self._Show_Index = 2
		self._Remind_Index = 1
	end
    local bIsNoEnemy = false
	GUI.SetText(self._Lab_Member_Num, self._Member_Set[self._Show_Index])

	if data.Retcode == -1 then
		self._Btn_Sign:SetActive(self._Is_Leader)
		self._Btn_Start:SetActive(false)
		self._Btn_Show:SetActive(false)
		self._Lab_Remind:SetActive(false)
		self._Btn_Member_Set:SetActive(true)
	elseif data.Retcode == 0 then
		self._Btn_Sign:SetActive(false)
		self._Btn_Start:SetActive(false)
		self._Btn_Show:SetActive(false)
		self._Lab_Remind:SetActive(true)
		self._Btn_Member_Set:SetActive(false)
        GUI.SetText(self._Lab_Remind, StringTable.Get(8100))
	elseif data.Retcode == 1 then
		self._Btn_Sign:SetActive(false)
		self._Btn_Start:SetActive(true)
		self._Btn_Show:SetActive(false)
		self._Lab_Remind:SetActive(false)
		self._Btn_Member_Set:SetActive(false)		
	elseif data.Retcode == 2 then
		self._Btn_Sign:SetActive(false)
		self._Btn_Start:SetActive(false)
		self._Btn_Show:SetActive(false)
		self._Lab_Remind:SetActive(true)
		self._Btn_Member_Set:SetActive(false)
		GUI.SetText(self._Lab_Remind, StringTable.Get(8098))
        bIsNoEnemy = (data.Retcode == 2)
	end
    self._Open:SetActive(false)
    self._Close:SetActive(true)
	if data.OpenStatus == 0 then
		GUI.SetText(self._Lab_Condition_Des, StringTable.Get(8094))
	elseif data.OpenStatus ~= 0 and data.Retcode == -1 then
		GUI.SetText(self._Lab_Condition_Des, StringTable.Get(31605))
	else
        self._Open:SetActive(true)
        self._Close:SetActive(false)
        if data.OpenStatus == 3 then
            self._Btn_Sign:SetActive(false)
		    self._Btn_Start:SetActive(false)
		    self._Btn_Show:SetActive(false)
		    self._Lab_Remind:SetActive(true)
		    self._Btn_Member_Set:SetActive(false)
		    GUI.SetText(self._Lab_Remind, StringTable.Get(8099))
        end
        local uiTemplate = self._Open:GetComponent(ClassType.UITemplate)
        local lab_vs = uiTemplate:GetControl(2)
        local lab_guild_name1 = uiTemplate:GetControl(0)
        local lab_guild_name2 = uiTemplate:GetControl(1)
        local img_flag1 = uiTemplate:GetControl(3)
        local img_flag2 = uiTemplate:GetControl(4)
        local lab_my = uiTemplate:GetControl(5)
        local lab_enemy = uiTemplate:GetControl(6)
        lab_my:SetActive(false)
        lab_enemy:SetActive(false)
        local my_guild_icon = {}
        my_guild_icon[1] = img_flag1:FindChild("Img_Flag_BG")
        my_guild_icon[2] = img_flag1:FindChild("Img_Flag_Flower_1")
        my_guild_icon[3] = img_flag1:FindChild("Img_Flag_Flower_2")
        game._GuildMan:SetGuildUseIcon(my_guild_icon)
        GUI.SetText(lab_guild_name1, game._HostPlayer._Guild._GuildName)
        if bIsNoEnemy then
            img_flag2:SetActive(false)
            lab_guild_name2:SetActive(false)
        else
            img_flag2:SetActive(true)
            lab_guild_name2:SetActive(true)
            local go_GuildIcon = {}
            go_GuildIcon[1] = img_flag2:FindChild("Img_Flag_BG")
            go_GuildIcon[2] = img_flag2:FindChild("Img_Flag_Flower_1")
            go_GuildIcon[3] = img_flag2:FindChild("Img_Flag_Flower_2")
            local guildInfo = CGuildIconInfo.new()
            guildInfo._BaseColorID = data.GuildIcon.BaseColorID
            guildInfo._FrameID = data.GuildIcon.FrameID
            guildInfo._ImageID = data.GuildIcon.ImageID
            game._GuildMan:SetPlayerGuildIcon(guildInfo, go_GuildIcon)
            GUI.SetText(lab_guild_name2, data.Guildname)
        end
        if data.OpenStatus == 1 then
            GUI.SetText(lab_vs, StringTable.Get(8095))
        elseif data.OpenStatus == 2 then
            GUI.SetText(lab_vs, StringTable.Get(8096))
        elseif data.OpenStatus == 3 then
            GUI.SetText(lab_vs, StringTable.Get(8097))
            if data.Result == 0 then            -- 胜
                lab_my:SetActive(true)
                lab_enemy:SetActive(false)
                GUI.SetText(lab_my, StringTable.Get(8117))
            elseif data.Result == 1 then        -- 负
                lab_my:SetActive(false)
                lab_enemy:SetActive(true)
                GUI.SetText(lab_enemy, StringTable.Get(8117))
            elseif data.Result == 2 then        -- 平
                lab_my:SetActive(true)
                lab_enemy:SetActive(true)
                GUI.SetText(lab_my, StringTable.Get(8118))
                GUI.SetText(lab_enemy, StringTable.Get(8118))
            else                                -- 没结果
                lab_my:SetActive(false)
                lab_enemy:SetActive(false)
            end
        end
	end
	local guildBattle = CElementData.GetTemplate("GuildBattle", self._Battle_Tid)
	GUI.SetText(self._Lab_Level_Num, string.format(StringTable.Get(8104), data.PlayerNum, guildBattle.MaxMember))
	-- 不是公会会长,不可见设置按钮
	if not self._Is_Leader then
		self._Btn_Member_Set:SetActive(false)
		if data.Retcode == -1 then
			self._Btn_Sign:SetActive(false)
			self._Lab_Remind:SetActive(true)
			GUI.SetText(self._Lab_Remind, StringTable.Get(8103))
		end
	end
end

-- 设置准入人员
def.method().OnBtnMemberSet = function(self)
	local callback = function(value)
		if value then
			local temp = self._Show_Index
			self._Show_Index = self._Remind_Index
			self._Remind_Index = temp
			GUI.SetText(self._Lab_Member_Num, self._Member_Set[self._Show_Index])
		end
	end
	local title, msg, closeType = StringTable.GetMsg(83)
	local member = self._Member_Set[self._Remind_Index]
	msg = string.format(msg, member)
	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

def.method().OnBtnSign = function(self)
    local callback = function(val)
        if val then
            local protocol = (require "PB.net".C2SGuildBattleFieldOperate)()
	        protocol.OpType = 1
	        protocol.Position = 5 - self._Show_Index
	        PBHelper.Send(protocol)
        end
    end
	local title, msg, closeType = StringTable.GetMsg(110)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

def.method("table").ShowBtnSign = function(self, data)
	self:InitData(data)
end

def.method().OnBtnStart = function(self)
	local protocol = (require "PB.net".C2SGuildBattleFieldOperate)()
	protocol.OpType = 2
	protocol.Position = 5 - self._Show_Index
	PBHelper.Send(protocol)
    game._GUIMan:CloseSubPanelLayer()
end

def.method().OnBtnShow = function(self)
	game._GUIMan:ShowTipText(StringTable.Get(8100), true)
end

CPanelUIGuildBattle.Commit()
return CPanelUIGuildBattle