local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPageGuildBonus = Lplus.Class("CPageGuildBonus")
local def = CPageGuildBonus.define

def.field("table")._Parent = nil
def.field("userdata")._FrameRoot = nil

-- 工资表
def.field("table")._Guild_Salary = BlankTable
-- 积分表
def.field("table")._Guild_Reward_Points = BlankTable
-- 积分最大值
def.field("number")._Max_Reward_Point = 0

def.field("table")._Guild_Icon_Image = BlankTable
def.field("userdata")._Bonus_Guild_Level = nil
def.field("userdata")._Bar_Guild_Exp = nil
def.field("userdata")._Guild_Exp_Num = nil
def.field("userdata")._Guild_Activity_Num = nil
def.field("userdata")._Guild_Rank_Num = nil
def.field("userdata")._Bar_Guild_Fund = nil
def.field("userdata")._Guild_Fund_Num = nil
def.field("userdata")._Bar_Guild_Energy = nil
def.field("userdata")._Guild_Energy_Num = nil
def.field("userdata")._Week_Activity_Num = nil
def.field("userdata")._Week_Rank_Num = nil
def.field("userdata")._Week_Salary_Icon = nil
def.field("userdata")._Week_Salary_Num = nil
def.field("userdata")._Week_Salary_Remind = nil
def.field("userdata")._Bar_Guild_Points = nil
def.field("userdata")._Guild_Points_Num = nil
def.field("userdata")._Bonus_Donate_Num = nil
def.field("table")._Btn_Bonus = BlankTable

def.static("table", "userdata", "=>", CPageGuildBonus).new = function(parent, frame)
	local obj = CPageGuildBonus()
	obj._Parent = parent
	obj._FrameRoot = frame
	return obj
end

-- 展示时调用
def.method().Show = function(self)
	self._FrameRoot:SetActive(true)
	self:Init()
	self:Update()

	if game._HostPlayer._Guild._ShowSalary then
		game._GUIMan:Open("CPanelUIGuildSalary", nil)
	end
end

def.method().Init = function(self)
	if #self._Guild_Salary > 0 then return end

	local allTid1 = GameUtil.GetAllTid("GuildSalary")
	for i = 1, #allTid1 do
		self._Guild_Salary[#self._Guild_Salary + 1] = CElementData.GetTemplate("GuildSalary", allTid1[i])
	end
	local allTid2 = GameUtil.GetAllTid("GuildRewardPoints")
	for i = 1, #allTid2 do
		self._Guild_Reward_Points[#self._Guild_Reward_Points + 1] = CElementData.GetTemplate("GuildRewardPoints", allTid2[i])
	end
	self._Max_Reward_Point = self._Guild_Reward_Points[5].NeedPoints

	local parent = self._Parent

	local bonus_Img_Flag = parent:GetUIObject("Bonus_Img_Flag")
	self._Guild_Icon_Image[1] = bonus_Img_Flag:FindChild("Bonus_Img_Flag_BG")
	self._Guild_Icon_Image[2] = bonus_Img_Flag:FindChild("Bonus_Img_Flag_Flower_1")
	self._Guild_Icon_Image[3] = bonus_Img_Flag:FindChild("Bonus_Img_Flag_Flower_2")
	local scrollBar = ClassType.Scrollbar
	self._Bonus_Guild_Level = parent:GetUIObject("Bonus_Guild_Level")
	self._Bar_Guild_Exp = parent:GetUIObject("Bar_Guild_Exp"):GetComponent(scrollBar)
	self._Guild_Exp_Num = parent:GetUIObject("Guild_Exp_Num")
	self._Guild_Activity_Num = parent:GetUIObject("Guild_Activity_Num")
	self._Guild_Rank_Num = parent:GetUIObject("Guild_Rank_Num")
	self._Bar_Guild_Fund = parent:GetUIObject("Bar_Guild_Fund"):GetComponent(scrollBar)
	self._Guild_Fund_Num = parent:GetUIObject("Guild_Fund_Num")
	self._Bar_Guild_Energy = parent:GetUIObject("Bar_Guild_Energy"):GetComponent(scrollBar)
	self._Guild_Energy_Num = parent:GetUIObject("Guild_Energy_Num")
	self._Week_Activity_Num = parent:GetUIObject("Week_Activity_Num")
	self._Week_Rank_Num = parent:GetUIObject("Week_Rank_Num")
	self._Week_Salary_Icon = parent:GetUIObject("Week_Salary_Icon")
	self._Week_Salary_Num = parent:GetUIObject("Week_Salary_Num")
	self._Week_Salary_Remind = parent:GetUIObject("Week_Salary_Remind")
	self._Bar_Guild_Points = parent:GetUIObject("Bar_Guild_Points"):GetComponent(scrollBar)
	self._Guild_Points_Num = parent:GetUIObject("Guild_Points_Num")
	self._Bonus_Donate_Num = parent:GetUIObject("Bonus_Donate_Num")

	for i = 1, 5 do
		self._Btn_Bonus[#self._Btn_Bonus + 1] = parent:GetUIObject("Btn_Bonus_" .. i)
		self:SetBtnBonus(i)
	end
end

def.method().UpdatePageRedPoint = function(self)
end

-- 初始化信息(刷新也可能会调用)
def.method().Update = function(self)
	local _Guild = game._HostPlayer._Guild
	game._GuildMan:SetGuildUseIcon(self._Guild_Icon_Image)
	GUI.SetText(self._Bonus_Guild_Level, tostring(_Guild._GuildLevel))
	local guild = CElementData.GetTemplate("GuildLevel", _Guild._GuildModuleID)
	self._Bar_Guild_Exp.size = _Guild._Exp / guild.NextExperience
	GUI.SetText(self._Guild_Exp_Num, _Guild._Exp .. "/" .. guild.NextExperience)
	GUI.SetText(self._Guild_Activity_Num, tostring(_Guild._GuildLiveness))
	GUI.SetText(self._Guild_Rank_Num, tostring(_Guild._LivenessRank))
	self._Bar_Guild_Fund.size = _Guild._Fund / guild.MaxGuildFund
	GUI.SetText(self._Guild_Fund_Num, _Guild._Fund .. "/" .. guild.MaxGuildFund)
	self._Bar_Guild_Energy.size = _Guild._Energy / guild.MaxGuildEnergy
	GUI.SetText(self._Guild_Energy_Num, _Guild._Energy .. "/" .. guild.MaxGuildEnergy)
	local hostMember = game._GuildMan:GetHostGuildMemberInfo()
	if hostMember == nil then warn("数据成员为空 ！！！！！！ ") return end
	local liveness = hostMember._Liveness
	local livenessRank = game._GuildMan:GetHostPlayerLivenessRank()
	if livenessRank == 0 then
		GUI.SetText(self._Week_Rank_Num, StringTable.Get(8063))	
	else
		GUI.SetText(self._Week_Rank_Num, tostring(livenessRank))
	end
	local flag = true
	local salary = 0
	for i, v in ipairs(self._Guild_Salary) do
		if flag then
			if livenessRank <= v.GuildRank and liveness >= v.GuildPoints then
				flag = false
				local reward = GUITools.GetRewardListByLevel(v.RewardID, true, _Guild._GuildLevel)
				for j, w in ipairs(reward) do
					if w.IsTokenMoney then
						GUITools.SetTokenMoneyIcon(self._Week_Salary_Icon, w.Data.Id)
						salary = w.Data.Count
					end
				end
			end
		end
	end
	if salary == 0 then
		liveness = "<color=#ff412d>" .. liveness .. "</color>"
		self._Week_Salary_Icon:SetActive(false)
		self._Week_Salary_Num:SetActive(false)
		self._Week_Salary_Remind:SetActive(true)
	else
		self._Week_Salary_Icon:SetActive(true)
		self._Week_Salary_Num:SetActive(true)
		self._Week_Salary_Remind:SetActive(false)
	end
	GUI.SetText(self._Week_Activity_Num, tostring(liveness))
	GUI.SetText(self._Week_Salary_Num, tostring(salary))
	local rewardPoints = _Guild._RewardPoints
	for i = 1, 5 do
        local uiTemplate = self._Btn_Bonus[i]:GetComponent(ClassType.UITemplate)
        local item_icon = uiTemplate:GetControl(0)
        local img_get = uiTemplate:GetControl(2)
        local img_mask = uiTemplate:GetControl(4)
		GameUtil.StopUISfx(PATH.UIFX_TongYongLingQu, item_icon)
		if self:IsReceived(i) then
			img_get:SetActive(true)
            img_mask:SetActive(false)
		else			
			img_get:SetActive(false)
			if rewardPoints >= self._Guild_Reward_Points[i].NeedPoints then
				img_mask:SetActive(false)
				GameUtil.PlayUISfx(PATH.UIFX_TongYongLingQu, item_icon, item_icon, -1)
			else
				img_mask:SetActive(true)
			end	
		end
	end
	self._Bar_Guild_Points.size = rewardPoints / self._Max_Reward_Point
	GUI.SetText(self._Guild_Points_Num, rewardPoints .. "/" .. self._Max_Reward_Point)
	GUI.SetText(self._Bonus_Donate_Num, string.format(StringTable.Get(853), _Guild:GetDonateNum()))
    for i = 1, 5 do
		self:SetBtnBonus(i)
	end
end

-- 是否已领取
def.method("number", "=>", "boolean").IsReceived = function(self, id)
	local pointsList = game._HostPlayer._Guild._PointsList
	for i = 1, #pointsList do
		if pointsList[i] == id then
			return true
		end
	end
	return false
end

-- 当点击
def.method("string").OnClick = function(self, id)
	if id == "Btn_Bonus_Donate" then
		self:OnBtnBonusDonate()
	else
		for i = 1, 5 do			
			if id == "Btn_Bonus_" .. i then
				self:OnBtnBonus(i)
			end
		end
	end
end

-- 设置积分奖励按钮(初始化设置不刷新的)
def.method("number").SetBtnBonus = function(self, index)
	local btn = self._Btn_Bonus[index]
	local bonus = self._Guild_Reward_Points[index]
	local item = CElementData.GetTemplate("Item", bonus.BoxItemID)
	--btn:FindChild("Lab_Number"):SetActive(false)
    local _Guild = game._HostPlayer._Guild
    local rewardPoints = _Guild._RewardPoints
    local uiTemplate = btn:GetComponent(ClassType.UITemplate)
    local icon_new = uiTemplate:GetControl(0)
    local img_red_point = uiTemplate:GetControl(1)
    local lab_points = uiTemplate:GetControl(3)
    local setting = {
        [EItemIconTag.Bind] = (not self:IsReceived(index)) and rewardPoints < self._Guild_Reward_Points[index].NeedPoints,
    }
    IconTools.InitItemIconNew(icon_new, bonus.BoxItemID, setting)

--	GUITools.SetGroupImg(btn:FindChild("Img_Quality"), item.InitQuality)
--	GUITools.SetItemIcon(btn:FindChild("Img_ItemIcon"), item.IconAtlasPath)
--	if item.BindMode == 1 then
--		btn:FindChild("Img_Bind"):SetActive(true)
--	else
--		btn:FindChild("Img_Bind"):SetActive(false)
--	end
	img_red_point:SetActive(false)
	GUI.SetText(lab_points, tostring(bonus.NeedPoints))
end

-- 领取积分奖励
def.method("number").OnBtnBonus = function(self, index)
	if self:IsReceived(index) then
		game._GUIMan:ShowTipText(StringTable.Get(817), true)
	else
		if game._HostPlayer._Guild._RewardPoints < self._Guild_Reward_Points[index].NeedPoints then
			game._GUIMan:ShowTipText(StringTable.Get(866), true)	
		else
			local protocol = (require "PB.net".C2SGuildPointsReward)()
			protocol.PointsTID = index
			PBHelper.Send(protocol)
		end
	end
end

-- 打开捐献界面
def.method().OnBtnBonusDonate = function(self)
	if game._HostPlayer._Guild:GetDonateNum() == 0 then
		game._GUIMan:ShowTipText(StringTable.Get(855), true)
	else
		game._GUIMan:Open("CPanelUIGuildDonate", nil)
	end
end

-- 隐藏时调用
def.method().Hide = function(self)
	self._FrameRoot:SetActive(false)
end

-- 摧毁时调用
def.method().Destroy = function(self)
	self._Guild_Salary = nil
	self._Guild_Reward_Points = nil
	self._Max_Reward_Point = 0
	self._Guild_Icon_Image = nil
	self._Bonus_Guild_Level = nil
	self._Bar_Guild_Exp = nil
	self._Guild_Exp_Num = nil
	self._Guild_Activity_Num = nil
	self._Guild_Rank_Num = nil
	self._Bar_Guild_Fund = nil
	self._Guild_Fund_Num = nil
	self._Bar_Guild_Energy = nil
	self._Guild_Energy_Num = nil
	self._Week_Activity_Num = nil
	self._Week_Rank_Num = nil
	self._Week_Salary_Icon = nil
	self._Week_Salary_Num = nil
	self._Week_Salary_Remind = nil
	self._Bar_Guild_Points = nil
	self._Guild_Points_Num = nil
	self._Bonus_Donate_Num = nil
	self._Btn_Bonus = nil
end

CPageGuildBonus.Commit()
return CPageGuildBonus