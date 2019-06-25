local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelMinimap = Lplus.ForwardDeclare("CPanelMinimap")
local CPanelMirrorArena = Lplus.ForwardDeclare("CPanelMirrorArena")
local CPanelArenaEnter = Lplus.ForwardDeclare("CPanelArenaEnter")
local EResourceType = require "PB.data".EResourceType
local ERankId = require"PB.data".ERankId
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CElementData = require "Data.CElementData"
local CUIModel = require "GUI.CUIModel"
local CPageBattle = require"GUI.CPageBattle"
local PBHelper = require "Network.PBHelper"
local net = require "PB.net"
local CPanelCalendar = require "GUI.CPanelCalendar"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local EMatchType = require "PB.net".EMatchType

local CPage3V3 = Lplus.Class("CPage3V3")
local def = CPage3V3.define

def.field("userdata")._Panel = nil
def.field("table")._PanelObject = BlankTable
def.field(CUIModel)._Model4ImgRender_Left = nil
def.field(CUIModel)._Model4ImgRender_Right = nil
def.field("table")._GroupStars = nil 
def.field("table")._RewardDataList = nil
def.field("number")._BanMatchTimerID = 0
def.field("number")._Matching_TimerID =0
def.field("number")._Matching_Waiting_time =0

local instance = nil
def.static("=>", CPage3V3).Instance = function()
	if instance == nil then
        instance = CPage3V3()
	end
	return instance
end

local function UpdateRoleInfo (self,obj)
	local data  = game._CArenaMan._3V3HostData
	local labFightScore_Data = obj:FindChild("Lab_FightScore_Data")
	GUI.SetText(labFightScore_Data,GUITools.FormatNumber(data.FightScore))
	local num = data.ObtainedHonor/data.MaxHonor
	self._PanelObject._HonorIndicator.value = num
	GUI.SetText(self._PanelObject._LabBlood,string.format(StringTable.Get(20061),data.ObtainedHonor,data.MaxHonor))
	
	if  data.TotalTimes == nil or data.TotalTimes == 0 then
		data.TotalTimes = 1 
	end
	--战绩
	GUI.SetText(self._PanelObject._LabWin, tostring(data.WinTimes))
	GUI.SetText(self._PanelObject._LabWinPoint, string.format("%.0f", (data.WinTimes / data.TotalTimes) * 100) .. "%")
	--时间 等 显示 
	self._PanelObject._FrameSeasonTime:SetActive(true)
	local Time = math.abs(data.SeasonLeftTime)
	GUI.SetText(self._PanelObject._LabSeasonTime,GUITools.FormatTimeSpanFromSeconds(Time))
	GUI.SetText(self._PanelObject._LabChance,StringTable.Get(20058))
	--奖励todo
	GUI.SetText(self._PanelObject._LabAwardStage2,StringTable.Get(20059))
end

local function ShowGrade(self)
	local data = game._CArenaMan._3V3HostData
	self._PanelObject._FrameBadge:SetActive(true)
	self._GroupStars = {}
	for i= 3,5 do
		self._GroupStars[i] =
		{
			_GroupObj = self._PanelObject._FrameBadge:FindChild("Frame_Star"..i),
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
	local DataTemp = CElementData.GetPVP3v3Template(data.Stage)
	if DataTemp ~= nil then	
		GUITools.SetGroupImg(self._PanelObject._ImgSan,DataTemp.StageType - 1)
		if data.Stage == 16 then 
			self._PanelObject._ImgLevel:SetActive(false)
			self._PanelObject._LabSanLevel:SetActive(true)
			GUI.SetText(self._PanelObject._LabSanLevel,tostring(data.Star))
		else
			GUITools.SetGroupImg(self._PanelObject._ImgLevel,DataTemp.StageLevel - 1)
			self._PanelObject._ImgLevel:SetActive(true)
			self._PanelObject._LabSanLevel:SetActive(false)
		end
		GUI.SetText(self._PanelObject._LabLevel, DataTemp.Name)
		local StarItem = self._GroupStars[DataTemp.CountUpLimit]
		if StarItem ~= nil then
			StarItem._GroupObj:SetActive(true)
			for i,v in ipairs(StarItem._start) do
				if not IsNil(v) and (i <= data.Star) then
					-- 点亮
					GUITools.SetGroupImg(v,1)
				end
			end
		end
		self._RewardDataList = GUITools.GetRewardList(DataTemp.SeasonRewardId,true)
		if self._RewardDataList == nil then return end
		for i ,data in ipairs(self._RewardDataList) do
			local frame_icon = nil
			if i == 1 then 
				frame_icon = self._PanelObject._ItemIcon3
			else
				frame_icon = self._PanelObject._ItemIcon4
			end
			if data.IsTokenMoney then
				IconTools.InitTokenMoneyIcon(frame_icon, data.Data.Id, data.Data.Count)
			else
				IconTools.InitItemIconNew(frame_icon, data.Data.Id, { [EItemIconTag.Number] = data.Data.Count })
			end
		end
	end		
end

--取消3v3匹配
local function Cancel3V3Mathcing(self)
	self:Cancel3V3Timer() 
	local protocol = (require "PB.net".C2SMatchReqCancel)()
	protocol.MatchType = EMatchType.EMatchType_Arena
	PBHelper.Send(protocol)
end

local function StartArena3V3Matching(self)
	local protocol = (require "PB.net".C2SMatching)()
	protocol.MatchType = EMatchType.EMatchType_Arena
	PBHelper.Send(protocol)
end

local function BanMatchTime3V3(self,endTime)
	GUITools.SetBtnGray(self._PanelObject._BtnCharge3V3,true)
	self._PanelObject._FrameMatchTime:SetActive(true)
	self._PanelObject._BtnCancelCharge :SetActive(false)
	GUI.SetText(self._PanelObject._LabMatchBanTip,string.format(StringTable.Get(20084),StringTable.Get(20063)))
	if self._BanMatchTimerID > 0 then
		_G.RemoveGlobalTimer(self._BanMatchTimerID)
		self._BanMatchTimerID = 0
	end 
	local timeStr = ""
	local callback = function()
		local showTime = endTime - GameUtil.GetServerTime()/1000
		timeStr = GUITools.FormatTimeFromSecondsToZero(false,showTime)
        GUI.SetText(self._PanelObject._LabChanceAndBanTime,string.format(StringTable.Get(20084),timeStr))
        if showTime <= 0 then 
            -- 消除计时器
	        GUITools.SetBtnGray(self._PanelObject._BtnCharge3V3,false)
    		GameUtil.SetButtonInteractable(self._PanelObject._BtnCharge3V3,true)

	        _G.RemoveGlobalTimer(self._BanMatchTimerID)
		    self._BanMatchTimerID = 0
		    game._CArenaMan._IsBanMatching3V3 = false
			self._PanelObject._FrameMatchTime:SetActive(false)
        end            
    end
    self._BanMatchTimerID = _G.AddGlobalTimer(1, false, callback)  	
end

def.method("table", "userdata").Show = function(self, linkInfo, root)
	self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
    self:InitPanel()
end

def.method().InitPanel = function (self)
	UpdateRoleInfo(self,self._PanelObject._FrameRoleInfo3V3)
	ShowGrade(self)
	self:UpdateFriendModel()
	local protocol = (require "PB.net".C2SMatchActivityStateReq)()
	protocol.MatchType = EMatchType.EMatchType_Arena 
	PBHelper.Send(protocol)
end

-- 从小地图进去控制3v3匹配按钮显示状态
def.method("boolean").Change3V3BtnChargeState = function (self,isOpenTime3V3)
	if isOpenTime3V3 == nil then return end
	if not isOpenTime3V3 then 
		-- 未开启状态直接关闭界面
		game._GUIMan:Close("CPanelMirrorArena")
	else
		if game._CArenaMan._IsMatching3V3 then 
			CPVPAutoMatch.Instance():Stop()
			self:ShowMatchingTime3V3(game._DungeonMan._3V3MatchingStartTime)
			return
		end
		if game._CArenaMan._IsBanMatching3V3 then 
			self._PanelObject._BtnCharge3V3:SetActive(true)
    		GameUtil.SetButtonInteractable(self._PanelObject._BtnCharge3V3,false)
    		BanMatchTime3V3(self,game._DungeonMan._3V3BanEndTime)
    	else
    		self._PanelObject._BtnCancelCharge:SetActive(false)
    		self._PanelObject._BtnCharge3V3:SetActive(true)
    		self._PanelObject._FrameSeasonTime:SetActive(true)
    		self._PanelObject._FrameMatchTime:SetActive(false)
    	    GameUtil.SetButtonInteractable(self._PanelObject._BtnCharge3V3,true)
    	end
	end
end 

--3v3匹配中时间显示
def.method("number").ShowMatchingTime3V3 = function(self,startTime)
	self._PanelObject._BtnCancelCharge :SetActive(true)
	self._PanelObject._BtnCharge3V3:SetActive(false)
	-- self._PanelObject._FrameSeasonTime:SetActive(false)
	self._PanelObject._FrameMatchTime:SetActive(true)

	if self._Matching_TimerID > 0 then
		_G.RemoveGlobalTimer(self._Matching_TimerID)
		self._Matching_TimerID = 0
	end	
	GUI.SetText(self._PanelObject._LabMatchBanTip,string.format(StringTable.Get(20086),StringTable.Get(20085)))
	local timeStr = ""
	self._Matching_Waiting_time = CSpecialIdMan.Get("Arena3V3MateTime")
	local showTime = 0
	local endTime = self._Matching_Waiting_time + startTime
	self._Matching_TimerID = _G.AddGlobalTimer(1, false, function()
		if not IsNil(self._PanelObject._LabTime) then
			showTime = GameUtil.GetServerTime()/1000 - startTime
			if GameUtil.GetServerTime()/1000 >= endTime then 
				self:Cancel3V3Timer()
				return 
			end
			timeStr = GUITools.FormatTimeFromSecondsToZero(false,showTime)
			GUI.SetText(self._PanelObject._LabTime, StringTable.Get(242))	
			GUI.SetText(self._PanelObject._LabChanceAndBanTime,string.format(StringTable.Get(20086), timeStr))
		end
	end)
end

-- 关闭3V3匹配倒计时
def.method().Cancel3V3Timer = function (self)
	if self._Matching_TimerID > 0 then
		_G.RemoveGlobalTimer(self._Matching_TimerID)
		self._Matching_TimerID = 0
	end
	self._PanelObject._FrameSeasonTime:SetActive(true)
	self._PanelObject._FrameMatchTime:SetActive(false)
	self._PanelObject._BtnCancelCharge:SetActive(false)
	self._PanelObject._BtnCharge3V3:SetActive(true)
	GUI.SetText(self._PanelObject._Lab_Btn_Charge3V3,StringTable.Get(20062))
end

def.method("string").Click = function(self, id)
	if id == "Btn_Charge3V3" then 
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Matching_Arena, 0)
		local hp = game._HostPlayer
		if not hp:InWorld() then
			game._GUIMan:ShowTipText(StringTable.Get(20075), false)
		return end
		if game._CArenaMan._IsMatchingBattle then 
			game._GUIMan: ShowTipText(StringTable.Get(20076),false)
			return
		end
		--处于杀戮模式
		if hp:IsMassacre() then game._GUIMan:ShowTipText(StringTable.Get(20079),false)  return end

		CQuestAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()
		hp:StopNaviCal()
		hp:StopAutoTrans()
		StartArena3V3Matching(self)
	elseif id == "Btn_CancelCharge3V3" then 
		Cancel3V3Mathcing(self)
	elseif id == "Btn_Rank" then
		game._GUIMan:Open("CPanelRanking", ERankId.PVP3v3)
	elseif id == "Btn_PlusChance"  then 
		TODO()
	elseif id == "Btn_ShowAward" then 
		game._GUIMan:Open("CPanelRewardShow",game._CArenaMan._3V3HostData.Stage)
	elseif  string.find(id, "Btn_ItemIcon") then 
		local index = tonumber(string.sub(id,-1)) - 2
		local data = self._RewardDataList[index]
		if not data.IsTokenMoney then
			CItemTipMan.ShowItemTips(data.Data.Id, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
		else
			local panelData = 
							{
								_MoneyID = data.Data.Id,
								_TipPos = TipPosition.FIX_POSITION,
								_TargetObj = nil, 
							} 
			CItemTipMan.ShowMoneyTips(panelData)
		end
	end
end

def.method().HideFriendModel = function (self)
	if self._PanelObject._FriendInfoModel == nil then return end
	self._PanelObject._FriendInfoModel:SetActive(false)
end

def.method().UpdateFriendModel = function (self)
	if not CPanelMirrorArena.Instance():IsShow() and game._CArenaMan._CurOpenArenaType ~= EnumDef.OpenArenaType.Open3V3 then return end
	if IsNil(self._PanelObject._FriendInfoModel) then return end
	if game._CArenaMan._FriendInfoData == nil then  
		self._PanelObject._FriendInfoModel:SetActive(false) 
		return 
	elseif #game._CArenaMan._FriendInfoData <= 1 then 
		self._PanelObject._FriendInfoModel:SetActive(false) 
		return 
	elseif #game._CArenaMan._FriendInfoData >= 2 then 
		self._PanelObject._FriendInfoModel:SetActive(true) 
		local modelLeft = self._PanelObject._FriendInfoModel:FindChild("Img_Role_1")
		local modelRight = self._PanelObject._FriendInfoModel:FindChild("Img_Role_3")
		local ModelParams = require "Object.ModelParams"
		if #game._CArenaMan._FriendInfoData == 2 then 
			modelLeft:SetActive(true)
			modelRight:SetActive(false)
			for i,v in ipairs(game._CArenaMan._FriendInfoData) do 
				if v.RoleId ~= game._HostPlayer._ID then 
	    			local params = ModelParams.new()
				    params:MakeParam(v.Exterior, v.ProfessionId)
				    if self._Model4ImgRender_Left ~= nil then
				    	self._Model4ImgRender_Left:Destroy()
				    end
				    self._Model4ImgRender_Left = CUIModel.new(params, modelLeft,EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)

                    self._Model4ImgRender_Left:AddLoadedCallback(function() 
                        self._Model4ImgRender_Left:SetModelParam(self._PanelObject._PrefabPath, v.ProfessionId)
                        end)
                 
				end
			end
		elseif #game._CArenaMan._FriendInfoData == 3 then 
			modelLeft:SetActive(true)
			modelRight:SetActive(true)
			if self._Model4ImgRender_Left ~= nil then
		    	self._Model4ImgRender_Left:Destroy()
		    	self._Model4ImgRender_Left = nil
		    end 
		    if self._Model4ImgRender_Right ~=nil then
				self._Model4ImgRender_Right:Destroy()
				self._Model4ImgRender_Right = nil
			end
			for i,v in ipairs(game._CArenaMan._FriendInfoData) do 
				if v.RoleId ~= game._HostPlayer._ID then
				    local params = ModelParams.new()
					params:MakeParam(v.Exterior, v.ProfessionId) 
					if self._Model4ImgRender_Left == nil then
						self._Model4ImgRender_Left = CUIModel.new(params, modelLeft, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)                       
                        self._Model4ImgRender_Left:AddLoadedCallback(function() 
                            self._Model4ImgRender_Left:SetModelParam(self._PanelObject._PrefabPath, v.ProfessionId)
                            end)

					elseif self._Model4ImgRender_Right == nil then
						self._Model4ImgRender_Right = CUIModel.new(params, modelRight, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)
                        self._Model4ImgRender_Right:AddLoadedCallback(function() 
                            self._Model4ImgRender_Right:SetModelParam(self._PanelObject._PrefabPath, v.ProfessionId)
                            end)
					end
				end
			end
		end
	end
end

def.method().Destroy = function (self)
	--匹配界面（进入匹配倒计时后关闭角斗场按钮产生的界面）todo 
	if self._Matching_TimerID > 0 then
		_G.RemoveGlobalTimer(self._Matching_TimerID)
		self._Matching_TimerID = 0
	end
	if self._BanMatchTimerID > 0 then
		_G.RemoveGlobalTimer(self._BanMatchTimerID)
		self._BanMatchTimerID = 0
	end
	if self._Model4ImgRender_Left then
		self._Model4ImgRender_Left:Destroy()
		self._Model4ImgRender_Left = nil
	end
	if self._Model4ImgRender_Right then
		self._Model4ImgRender_Right:Destroy()
		self._Model4ImgRender_Right = nil
	end
	instance = nil 

	self._Panel = nil
end

CPage3V3.Commit()
return CPage3V3