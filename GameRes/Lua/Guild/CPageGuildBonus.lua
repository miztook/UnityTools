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

def.field("userdata")._Bonus_Guild_Level = nil
def.field("userdata")._LabActivity = nil
def.field("userdata")._LabRank = nil
def.field("userdata")._ImgSalary = nil
def.field("userdata")._LabSalary = nil
def.field("userdata")._LabSalaryRemind = nil
def.field("userdata")._LabPoint = nil 
def.field("userdata")._LabBtnDonate = nil
def.field("userdata")._ListGuildMember = nil 
def.field("userdata")._BtnDonate = nil 
def.field("userdata")._ImgBtnDonate = nil 
def.field("userdata")._ImgPoint = nil 
def.field("userdata")._BtnBonusTip = nil 
-- 上次选中的Image
def.field("userdata")._LastSelected = nil
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
	if #game._HostPlayer._Guild._MemberID == 0 then
		game._GuildMan:SendC2SGuildMembersInfo(game._GuildMan:GetHostPlayerGuildID())
	end
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

	self._Max_Reward_Point = self._Guild_Reward_Points[#self._Guild_Reward_Points].NeedPoints

	local parent = self._Parent
	local scrollBar = ClassType.Scrollbar
	self._ImgPoint = parent:GetUIObject("Img_Point")
	self._LabActivity = parent:GetUIObject("Week_Activity_Num")
	self._LabRank = parent:GetUIObject("Week_Rank_Num")
	self._ImgSalary = parent:GetUIObject("Week_Salary_Icon")
	self._LabSalary = parent:GetUIObject("Week_Salary_Num")
	self._LabSalaryRemind = parent:GetUIObject("Week_Salary_Remind")
	-- self._Bar_Guild_Points = parent:GetUIObject("Bar_Guild_Points"):GetComponent(scrollBar)
	self._LabBtnDonate = parent:GetUIObject("Bonus_Donate_Num")
	self._LabPoint = parent:GetUIObject("Lab_RewardPoint")
	self._ListGuildMember = parent:GetUIObject("List_GuildBonus"):GetComponent(ClassType.GNewList)
	self._BtnDonate = parent:GetUIObject("Btn_Bonus_Donate")
	self._ImgBtnDonate = parent:GetUIObject("Img_Bonus_Donate")
	self._BtnBonusTip = parent:GetUIObject("Btn_BonusTip")
	for i = 1, 5 do
		self._Btn_Bonus[#self._Btn_Bonus + 1] = parent:GetUIObject("Btn_Bonus_" .. i)
	end
end

def.method().UpdatePageRedPoint = function(self)
end

-- 初始化信息(刷新也可能会调用)
def.method().Update = function(self)
	self._BtnBonusTip:SetActive(false)
	local _Guild = game._HostPlayer._Guild
	-- GUI.SetText(self._Bonus_Guild_Level, tostring(_Guild._GuildLevel))
	local guild = CElementData.GetTemplate("GuildLevel", _Guild._GuildModuleID)
	local hostMember = game._GuildMan:GetHostGuildMemberInfo()
	if hostMember == nil then warn("数据成员为空 ！！！！！！ ") return end
	game._GuildMan:SortByLiveness(game._HostPlayer._Guild._MemberID,true)
	self._ListGuildMember:SetItemCount(#game._HostPlayer._Guild._MemberID)
	local liveness = hostMember._Liveness
	local livenessRank = game._GuildMan:GetHostPlayerLivenessRank()
	if livenessRank == 0 then
		GUI.SetText(self._LabRank, StringTable.Get(8063))	
	else
		GUI.SetText(self._LabRank, tostring(livenessRank))
	end
	local showSalary = false 
	local index = 0
	for i, v in ipairs(self._Guild_Salary) do
		if not showSalary then
			if livenessRank <= v.GuildRank and liveness >= v.GuildPoints then
				showSalary = true
				break	
			elseif livenessRank <= v.GuildRank and liveness < v.GuildPoints then
				index = i
				break
			end
		end
	end
	liveness = GUITools.FormatNumber(liveness)
	if not showSalary  then
		liveness = "<color=#ff412d>" .. liveness .. "</color>"
		self._ImgSalary:SetActive(false)
		self._LabSalary:SetActive(false)
		self._LabSalaryRemind:SetActive(true)
		GUI.SetText(self._LabSalaryRemind,string.format(StringTable.Get(8130),self._Guild_Salary[index].GuildPoints))
	else
		self._ImgSalary:SetActive(true)
		self._LabSalary:SetActive(true)
		self._LabSalaryRemind:SetActive(false)
	end
	GUI.SetText(self._LabActivity, liveness)
	local salary = game._HostPlayer._Guild._MemberList[game._HostPlayer._ID]._Salary
	GUI.SetText(self._LabSalary, tostring(salary))
	local rewardPoints = _Guild._RewardPoints
	
	-- self._Bar_Guild_Points.size = rewardPoints / self._Max_Reward_Point
	-- 积分
	local averageValue = 1 / #self._Guild_Reward_Points
	local totalValue = 0
	for i = 1,#self._Guild_Reward_Points do 
		if rewardPoints - self._Guild_Reward_Points[i].NeedPoints > 0 then 
			totalValue = totalValue + averageValue
		else
			local value = 0
			if i == 1 then 
				value =  (rewardPoints / self._Guild_Reward_Points[i].NeedPoints) * 0.2
			else
				local value1 = self._Guild_Reward_Points[i].NeedPoints - self._Guild_Reward_Points[i - 1].NeedPoints
				value =  (rewardPoints - self._Guild_Reward_Points[i - 1].NeedPoints ) / value1 * 0.2
			end
			totalValue = totalValue + value   
			break
		end
	end
	self._ImgPoint:GetComponent(ClassType.Image).fillAmount = totalValue
	GUI.SetText(self._LabPoint, rewardPoints .. "/" .. self._Max_Reward_Point)
	if _Guild:GetDonateNum() == 0 then 
		GUITools.SetBtnGray(self._BtnDonate,true)
		-- GameUtil.MakeImageGray(self._ImgBtnDonate,true)
	else
		GUITools.SetBtnGray(self._BtnDonate,false)
		-- GameUtil.MakeImageGray(self._ImgBtnDonate,false)
	end
	GUI.SetText(self._LabBtnDonate, string.format(StringTable.Get(853), _Guild:GetDonateNum(),_Guild._MaxDonateNum))
    
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
	elseif id == "Btn_Notice" then 
		self._BtnBonusTip:SetActive(true)
	elseif id == "Btn_BonusTip" then 
		self._BtnBonusTip:SetActive(false)
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
    local _Guild = game._HostPlayer._Guild
    local rewardPoints = _Guild._RewardPoints
    local uiTemplate = btn:GetComponent(ClassType.UITemplate)
    local item_icon = uiTemplate:GetControl(2)
    local img_red_point = uiTemplate:GetControl(1)
    local lab_points = uiTemplate:GetControl(0)
	GameUtil.StopUISfx(PATH.UIFX_TongYongLingQu, btn)
	if self:IsReceived(index) then
		GUITools.SetGroupImg(item_icon,1)
	else			
		GUITools.SetGroupImg(item_icon,0)
		if rewardPoints >= self._Guild_Reward_Points[index].NeedPoints then
			GameUtil.PlayUISfx(PATH.UIFX_TongYongLingQu, btn, btn, -1)
		end	
	end
	img_red_point:SetActive(false)
	GUI.SetText(lab_points, tostring(bonus.NeedPoints))
end

-- 领取积分奖励
def.method("number").OnBtnBonus = function(self, index)
	if self:IsReceived(index) then
		local bonus = self._Guild_Reward_Points[index]
		CItemTipMan.ShowItemTips( bonus.BoxItemID, TipsPopFrom.OTHER_PANEL,nil, TipPosition.FIX_POSITION)
		game._GUIMan:ShowTipText(StringTable.Get(817), true)
	else
		if game._HostPlayer._Guild._RewardPoints < self._Guild_Reward_Points[index].NeedPoints then
			local bonus = self._Guild_Reward_Points[index]
			CItemTipMan.ShowItemTips( bonus.BoxItemID, TipsPopFrom.OTHER_PANEL,nil, TipPosition.FIX_POSITION)
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
	if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        return
    end
	if game._HostPlayer._Guild:GetDonateNum() == 0 then
		game._GUIMan:ShowTipText(StringTable.Get(855), true)
	else
		game._GUIMan:Open("CPanelUIGuildDonate", nil)
	end
end

-- 初始化列表
def.method("userdata", "string", "number").InitItem = function(self, item, id, index)
    if id == "List_GuildBonus" then
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)	
    	local _Guild = game._HostPlayer._Guild
    	local memberID = _Guild._MemberID[index + 1]
    	local baseContent = ""
    	if memberID == game._HostPlayer._ID then
    		baseContent = "<color=#E7BF30>%s</color>"
    	else
    		baseContent = "<color=white>%s</color>"
    	end
    	local labRank = uiTemplate:GetControl(1)
    	local labName = uiTemplate:GetControl(2)
    	local imgRank = uiTemplate:GetControl(3)
    	local labSalary = uiTemplate:GetControl(4)
    	local imgHead = uiTemplate:GetControl(5)
    	local labJob = uiTemplate:GetControl(6)
    	local imgRankBg = uiTemplate:GetControl(7)
    	local labLivness = uiTemplate:GetControl(9)
    	local labLevel = uiTemplate:GetControl(10)
    	local labPosition = uiTemplate:GetControl(11)
    	local member = _Guild._MemberList[memberID]
    	if index + 1 <= 3 then 
    		labRank:SetActive(false)
    		imgRankBg:SetActive(true)
    		imgRank:SetActive(true)
    		GUITools.SetGroupImg(imgRankBg,index)
    		GUITools.SetGroupImg(imgRank,index)
    	else
    		labRank:SetActive(true)
    		imgRank:SetActive(false)
    		GUI.SetText(labRank,tostring(index + 1))
    		imgRankBg:SetActive(false)
    	end
    	game:SetEntityCustomImg(imgHead, member._RoleID, member._CustomImgSet, Profession2Gender[member._ProfessionID], member._ProfessionID)
    	GUI.SetText(labName, string.format(baseContent, member._RoleName))
        GUI.SetText(labJob, StringTable.Get(10300 + member._ProfessionID - 1))
    	GUI.SetText(labLevel, string.format(baseContent, tostring(member._RoleLevel)))
    	GUI.SetText(labLivness, string.format(baseContent, GUITools.FormatNumber(member._Liveness)))
    	GUI.SetText(labSalary,string.format(baseContent, tostring(member._Salary)))
    	GUI.SetText(labPosition, string.format(baseContent, member:GetMemberTypeName()))

    end
end

-- 选中
def.method("userdata", "string", "number").SelectItem = function(self, item, id, index)
	if id == "List_GuildBonus" then
		if not IsNil(self._LastSelected) then
			self._LastSelected:SetActive(false)
		end
		local guild = game._HostPlayer._Guild
		local member = guild._MemberList[guild._MemberID[index + 1]]
		if member._RoleID ~= game._HostPlayer._ID then
			local uiTemplate = item:GetComponent(ClassType.UITemplate)
			uiTemplate:GetControl(8):SetActive(true)
			self._LastSelected = uiTemplate:GetControl(8)

			local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
            game:CheckOtherPlayerInfo(member._RoleID, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Guild)
		end
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
	self._Bonus_Guild_Level = nil
	self._LabActivity = nil
	self._LabRank = nil
	self._ImgSalary = nil
	self._LabSalary = nil
	self._LabSalaryRemind = nil
	self._LabBtnDonate = nil
	self._ListGuildMember = nil 
	self._BtnDonate = nil 
	self._Btn_Bonus = nil
	self._ImgBtnDonate = nil
	self._ImgPoint = nil 
	self._LastSelected = nil 
end

CPageGuildBonus.Commit()
return CPageGuildBonus