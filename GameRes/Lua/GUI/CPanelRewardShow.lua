local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelRewardShow = Lplus.Extend(CPanelBase, "CPanelRewardShow")
local def = CPanelRewardShow.define

def.field("userdata")._Lab_MyData = nil 
def.field("userdata")._Lab_TitleTips = nil 
def.field("userdata")._Lab_Tips = nil
def.field("number")._MyStage = 0
def.field("userdata")._List_Item1 = nil 
def.field('table')._RewardInfo = BlankTable
def.field("table")._RankReward = nil 
def.field("userdata")._List_Item2 = nil
def.field("userdata")._List_Item3 = nil
def.field("number")._MyRank = 0
def.field("userdata")._View_Item1 = nil 
def.field("userdata")._View_Item2 = nil 
def.field("userdata")._View_Item3 = nil 
def.field("userdata")._FrameReward1 = nil 
def.field("userdata")._FrameReward2 = nil 
def.field("userdata")._RdoBattleGroup = nil 
def.field("userdata")._FrameMyReward = nil 


local instance = nil
def.static("=>", CPanelRewardShow).Instance = function()
	if not instance then
		instance = CPanelRewardShow()
		instance._PrefabPath = PATH.UI_RewardShow
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Lab_MyData = self:GetUIObject("Lab_MyData")
	self._Lab_Tips = self:GetUIObject("Lab_Tips")
	self._Lab_TitleTips = self:GetUIObject("Lab_TitleTips")
	self._List_Item1 = self:GetUIObject("List_Item1"):GetComponent(ClassType.GNewList)
	self._List_Item2 = self:GetUIObject("List_Item2"):GetComponent(ClassType.GNewList)
	self._List_Item3 = self:GetUIObject("List_Item3"):GetComponent(ClassType.GNewList)
	self._View_Item1 = self:GetUIObject("View_Item1")
	self._View_Item2 = self:GetUIObject("View_Item2")
	self._View_Item3 = self:GetUIObject("View_Item3")
	self._RdoBattleGroup = self:GetUIObject("Rdo_BattleGroup")
	self._FrameMyReward = self:GetUIObject("Frame_MyReward")

	self._FrameReward1 = self:GetUIObject("Frame_Reward1")
	self._FrameReward2 = self:GetUIObject("Frame_Reward2")
end

def.override("dynamic").OnData = function(self, data)
	if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
		self._FrameReward1:SetActive(true)
		self._FrameReward2:SetActive(false)
		GUI.SetText(self._Lab_TitleTips,StringTable.Get(21600))
		GUI.SetText(self._Lab_Tips,StringTable.Get(21601))
		self._MyStage = data
		self:AllTemplateInfo(nil)
		GUI.SetText(self._Lab_MyData,self._RewardInfo[self._MyStage].Name)
		self._RdoBattleGroup:SetActive(false)
		self._View_Item1:SetActive(true)
		self._View_Item2:SetActive(false)
		self._View_Item3:SetActive(false)
		self._List_Item1:SetItemCount(#self._RewardInfo)
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then 
		self._FrameReward1:SetActive(true)
		self._FrameReward2:SetActive(false)
		GUI.SetText(self._Lab_TitleTips,StringTable.Get(21603))
		self._MyRank = data._MyRank
		if self._MyRank ~= 0 then 
			GUI.SetText(self._Lab_MyData,tostring(data._MyRank))
		else
			GUI.SetText(self._Lab_MyData,StringTable.Get(20103))
		end
		GUI.SetText(self._Lab_Tips,StringTable.Get(21604))
		self._RankReward = data._RewardData
		self._RdoBattleGroup:SetActive(false)
		self._View_Item1:SetActive(true)
		self._View_Item2:SetActive(false)
		self._View_Item3:SetActive(false)
		self._List_Item1:SetItemCount(#self._RankReward)
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then
		self._RdoBattleGroup:SetActive(true)
		self._FrameReward1:SetActive(false)
		self._FrameReward2:SetActive(true)
		self._View_Item1:SetActive(false)
		self._View_Item2:SetActive(false)
		self._View_Item3:SetActive(true)
		GUI.SetText(self._Lab_TitleTips,StringTable.Get(21603))
		self._MyRank = data._MyRank
		if self._MyRank ~= 0 then 
			GUI.SetText(self._Lab_MyData,tostring(data._MyRank))
		else
			GUI.SetText(self._Lab_MyData,StringTable.Get(20103))
		end
		GUI.SetText(self._Lab_Tips,StringTable.Get(21608))

		self:AllTemplateInfo(data._RewardData)
		if self._MyRank == 0  then 
			local myItem1 = self._FrameReward2:FindChild("Item1")
			local myItem2 = self._FrameReward2:FindChild("Item2")
			local myItem3 = self._FrameReward2:FindChild("Item3")
			local rewardInfo = self._RewardInfo["Season"]
			local myList = GUITools.GetRewardList(rewardInfo[#rewardInfo].RewardId,true)
			for i,data in ipairs(myList) do
				if i == 1 then 
					self:SetReward(myItem1,data)
				elseif i == 2 then 
					self:SetReward(myItem2,data)
				elseif i == 3 then 
					self:SetReward(myItem3,data)
				end
			end
		end
		-- self._List_Item:SetItemCount(#self._RewardInfo)
	end
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

def.method("table").AllTemplateInfo = function (self,data)
	if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
		local allIds = GameUtil.GetAllTid("PVP3v3")
		self._RewardInfo = {}
		for i,j in ipairs(allIds) do 
			local temp = CElementData.GetTemplate("PVP3v3",j)
			if temp ~= nil then 
				self._RewardInfo[#self._RewardInfo + 1] = {}
				self._RewardInfo[#self._RewardInfo].Name = temp.Name
				self._RewardInfo[#self._RewardInfo].StageType = temp.StageType
				self._RewardInfo[#self._RewardInfo].RewardList = GUITools.GetRewardList(temp.SeasonRewardId,true)
			end
		end
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then 
		-- 场内 和赛季(data 是赛季奖励List)
		self._RewardInfo = {}
		self._RewardInfo["Venue"] = {}
		self._RewardInfo["Season"] = data
		local rewardList2 = {}
		local allIds = GameUtil.GetAllTid("EliminateReward")
		for i,j in ipairs(allIds) do 
			local temp = CElementData.GetTemplate("EliminateReward",j)
			if temp ~= nil then 
				rewardList2[#rewardList2 + 1] = {}
				rewardList2[#rewardList2].Rank = temp.Id
				rewardList2[#rewardList2].RewardList = GUITools.GetRewardList(temp.RewardTid,true)
			end
		end
		self._RewardInfo["Venue"] = rewardList2
		self._List_Item3:SetItemCount(#self._RewardInfo["Season"])
		self._List_Item2:SetItemCount(#self._RewardInfo["Venue"])
	end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
	if id == "List_Item1" then 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgGradeIcon = uiTemplate:GetControl(0)		
		local labGradeName = uiTemplate:GetControl(1)
		local imgBg = uiTemplate:GetControl(2)
		local imgHighLight = uiTemplate:GetControl(4)
		local item1 = uiTemplate:GetControl(5)
		local item2 = uiTemplate:GetControl(6)
		local labRank = uiTemplate:GetControl(7)
		local imgRank = uiTemplate:GetControl(8)
		if index <= 2 then 
			imgRank:SetActive(true)
			GUITools.SetGroupImg(imgBg, index)
			GUITools.SetGroupImg(imgRank, index)
			labRank:SetActive(false)
		else
			imgRank:SetActive(false)
			GUITools.SetGroupImg(imgBg, 0)
			labRank:SetActive(true)
		end
		imgHighLight:SetActive(false)
		local myItem1 = self._FrameReward1:FindChild("Item1")
		local myItem2 = self._FrameReward1:FindChild("Item2")
		local rewardList = nil 
		if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
			imgRank:SetActive(false)
			imgGradeIcon:SetActive(true)
			labGradeName:SetActive(true)
			labRank:SetActive(false)
			GUI.SetText(labGradeName,self._RewardInfo[#self._RewardInfo - index].Name)
			GUITools.SetGroupImg(imgGradeIcon,self._RewardInfo[#self._RewardInfo - index].StageType - 1)
			if #self._RewardInfo - index == self._MyStage  then 
				if index + 1 > 3 then
					imgHighLight:SetActive(true)
				end
				for i,data in ipairs(self._RewardInfo[#self._RewardInfo - index].RewardList) do
					if i == 1 then 
						self:SetReward(myItem1,data)
					elseif i == 2 then 
						self:SetReward(myItem2,data)
					end
				end
			end
			rewardList = self._RewardInfo[#self._RewardInfo - index].RewardList	
		else
			imgGradeIcon:SetActive(false)
			labGradeName:SetActive(false)
			if self._RankReward[index + 1].RankMax == self._RankReward[index + 1].RankMin then 
				GUI.SetText(labRank,tostring(self._RankReward[index + 1].RankMax))
			else
				GUI.SetText(labRank,string.format(StringTable.Get(20073),self._RankReward[index + 1].RankMax,self._RankReward[index + 1].RankMin))
			end
			local myList = nil 
			if self._MyRank ~= 0 and self._MyRank >= self._RankReward[index + 1].RankMax and self._MyRank <= self._RankReward[index + 1].RankMin then 
				if index + 1 > 3 then
					imgHighLight:SetActive(true)
				end
				myList = GUITools.GetRewardList(self._RankReward[index + 1].RewardId,true)
				for i,data in ipairs(myList) do
					if i == 1 then 
						self:SetReward(myItem1,data)
					elseif i == 2 then 
						self:SetReward(myItem2,data)
					end
				end
			elseif self._MyRank == 0 and myList == nil then 
				myList = GUITools.GetRewardList(self._RankReward[#self._RankReward].RewardId,true)
				for i,data in ipairs(myList) do
					if i == 1 then 
						self:SetReward(myItem1,data)
					elseif i == 2 then 
						self:SetReward(myItem2,data)
					end
				end
			end
			rewardList = GUITools.GetRewardList(self._RankReward[index + 1].RewardId,true)
		end
		for i,data in ipairs(rewardList) do
			if i == 1 then 
				self:SetReward(item1,data)
			elseif i == 2 then 
				self:SetReward(item2,data)
			end
		end
	elseif id == "List_Item2" then 
		-- 无畏战场场内奖励
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgBg = uiTemplate:GetControl(0)
		local item1 = uiTemplate:GetControl(1)
		local item2 = uiTemplate:GetControl(2)
		local labRank = uiTemplate:GetControl(3)
		local imgRank = uiTemplate:GetControl(4)
		if index <= 2 then 
			GUITools.SetGroupImg(imgBg, index + 1)
			imgRank:SetActive(true)
			GUITools.SetGroupImg(imgRank, index)
			labRank:SetActive(false)
		else
			imgRank:SetActive(false)
			GUITools.SetGroupImg(imgBg, 0)
			labRank:SetActive(true)
		end
		local data = self._RewardInfo["Venue"][index + 1]
		GUI.SetText(labRank,tostring(data.Rank))
		for i,value in ipairs(data.RewardList) do
			if i == 1 then 
				self:SetReward(item1,value)
			elseif i == 2 then 
				self:SetReward(item2,value)
			end
		end
	elseif id =="List_Item3" then 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgBg = uiTemplate:GetControl(0)
		local imgHighLight = uiTemplate:GetControl(1)
		local labRank = uiTemplate:GetControl(2)
		local item1 = uiTemplate:GetControl(3)
		local item2 = uiTemplate:GetControl(4)
		local item3 = uiTemplate:GetControl(5)
		local imgRank = uiTemplate:GetControl(6)
		if index <= 2 then 
			GUITools.SetGroupImg(imgBg, index + 1)
			imgRank:SetActive(true)
			GUITools.SetGroupImg(imgRank, index)
			labRank:SetActive(false)
		else
			imgRank:SetActive(false)
			GUITools.SetGroupImg(imgBg, 0)
			labRank:SetActive(true)
		end
		
		local data = self._RewardInfo["Season"][index + 1]
		if data.RankMax == data.RankMin then 
			GUI.SetText(labRank,tostring(data.RankMax))
		else
			GUI.SetText(labRank,string.format(StringTable.Get(20073),data.RankMax,data.RankMin))
		end
		local myList = nil 
		if self._MyRank ~= 0 and self._MyRank >= data.RankMax and self._MyRank <= data.RankMin then 
			local myItem1 = self._FrameReward2:FindChild("Item1")
			local myItem2 = self._FrameReward2:FindChild("Item2")
			local myItem3 = self._FrameReward2:FindChild("Item3")
			if index + 1 > 3 then
				imgHighLight:SetActive(true)
			end
			myList = GUITools.GetRewardList(data.RewardId,true)
			for i,u in ipairs(myList) do
				if i == 1 then 
					self:SetReward(myItem1,u)
				elseif i == 2 then 
					self:SetReward(myItem2,u)
				else 
					self:SetReward(myItem3,u)
				end
			end
	
		end
		local rewardList = GUITools.GetRewardList(data.RewardId,true)
		for i,value in ipairs(rewardList) do
			if i == 1 then 
				self:SetReward(item1,value)
			elseif i == 2 then 
				self:SetReward(item2,value)
			elseif i == 3 then 
				self:SetReward(item3,value)
			end
		end
	end 
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
	local index1 = tonumber( string.sub(button_obj.name,-1))
	local rewardList = nil 
	if id == "List_Item1" then 
		if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then 
			rewardList =  GUITools.GetRewardList(self._RankReward[index + 1].RewardId,true)
		else
			rewardList = self._RewardInfo[index + 1].RewardList
		end
	elseif id == "List_Item2" then
		rewardList = self._RewardInfo["Venue"][index + 1].RewardList
	elseif id == "List_Item3" then
		rewardList = GUITools.GetRewardList(self._RewardInfo["Season"][index + 1].RewardId,true)
	end
	CItemTipMan.ShowItemTips(rewardList[index1].Data.Id, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
	if id == "Rdo_Venue"and checked then 
		self._View_Item2:SetActive(true)
		self._View_Item3:SetActive(false)
		self._FrameMyReward:SetActive(false)
		GUI.SetText(self._Lab_Tips,StringTable.Get(21609))
	elseif id == "Rdo_Season"and checked then
		self._View_Item2:SetActive(false)
		self._View_Item3:SetActive(true)
		self._FrameMyReward:SetActive(true)
		GUI.SetText(self._Lab_Tips,StringTable.Get(21608))
	end
end

def.method("userdata","table").SetReward = function (self,item,data)
	local index = tonumber(string.sub(item.name,-1))
	local imgIcon = item:FindChild("Img_ItemIcon")
	local BtnItem = item:FindChild("Btn_Item"..index)
	if data.IsTokenMoney then
		if BtnItem ~= nil then 
	    	BtnItem:SetActive(false)
	    end
		GUITools.SetTokenMoneyIcon(imgIcon, data.Data.Id)
	else
		if BtnItem ~= nil then 
			BtnItem:SetActive(true)
		end
		local temp = CElementData.GetItemTemplate(data.Data.Id)
		GUITools.SetItemIcon(imgIcon, temp.IconAtlasPath)
	end
	local labNum = item:FindChild("Lab_Number")
	GUI.SetText(labNum, GUITools.FormatMoney(data.Data.Count))
end

def.override().OnDestroy = function(self)
	instance = nil 
end


CPanelRewardShow.Commit()
return CPanelRewardShow