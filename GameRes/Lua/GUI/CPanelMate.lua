local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local EMatchType = require "PB.net".EMatchType

local CPanelMate = Lplus.Extend(CPanelBase, "CPanelMate")
local def = CPanelMate.define

def.field("userdata")._Frame3V3 = nil 
def.field("userdata")._FrameBattle = nil
def.field("number")._RoomID = 0      

--3V3
def.field("number")._ReadTime = 0 	 
def.field("number")._LabTimerID = 0
def.field("number")._EndTime = 0     
def.field("table")._FriendList = nil 
def.field("table")._EnemyList = nil  
def.field("userdata")._LabTime = nil 
def.field("userdata")._ImgBtnYes3V3 = nil 
def.field("userdata")._FrameBtn3V3 = nil 
def.field("userdata")._Lab_Tips = nil 
def.field("userdata")._BldSlider = nil 
def.field("table")._FriendMemUI = nil 
def.field("table")._EnemyMemUI = nil

def.field("number")._CurArenaType = 0

--Battle
def.field("number")._RoleCount = 0 
def.field("userdata")._LabNumber = nil 
def.field("number")._BattleMateTimeSpecialId = 588
def.field("userdata")._FrameBtnBattle = nil 
def.field("number")._CurBattleConfirmNumber = 0

local instance = nil
def.static("=>", CPanelMate).Instance = function()
	if not instance then
		instance = CPanelMate()
		instance._PrefabPath = PATH.UI_Mate
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	--友方头像
	self._FriendMemUI = {}
	for i = 1,3 do
		self._FriendMemUI[i] = 
		{  
			_HeadImg = self:GetUIObject("Img_Head"..(i - 1)),
			_ReadyImg = self:GetUIObject("Img_ready"..(i - 1)),
			_BoardImg = self: GetUIObject("Img_Board"..(i - 1)),
			_LabLv = self:GetUIObject("Lab_Lv"..(i - 1)),
			_LabJob = self:GetUIObject("Lab_Job"..(i - 1)),
			_LabName = self:GetUIObject("Lab_Name"..(i - 1))
		}
	end
	
	
	self._EnemyMemUI = {}
	--敌方头像
	for i = 1,3 do
		self._EnemyMemUI[i] = 
		{
			_HeadImg = self:GetUIObject("Img_Head"..(i + 2 )),
			_ReadyImg = self:GetUIObject("Img_ready"..(i + 2)),
			_BoardImg = self: GetUIObject("Img_Board"..(i + 2)),
			_LabLv = self:GetUIObject("Lab_Lv"..(i + 2)),
			_LabJob = self:GetUIObject("Lab_Job"..(i + 2)),
			_LabName = self:GetUIObject("Lab_Name"..(i + 2)),
		}
	end
	self._LabTime = self:GetUIObject("Lab_Time")
	self._ImgBtnYes3V3 = self:GetUIObject("Img_BtnYes") 
	self._FrameBtn3V3 = self:GetUIObject("Frame_Btn")
	self._Lab_Tips = self:GetUIObject("Lab_Tps") 
	self._Frame3V3 = self:GetUIObject("Frame_3V3")   
	self._FrameBattle = self:GetUIObject("Frame_Battle")  
	self._LabNumber = self:GetUIObject("Lab_Number")   
	-- self._BldSlider = self:GetUIObject("Bld_Slider"):GetComponent(ClassType.Slider)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
	self._FrameBtnBattle = self:GetUIObject("Frame_BtnBattle")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
end

-----------------------------------私有接口-------------------------------------------------------------
--根据ID获取显示的类型和索引
local function GetIdexByPlayerID(nPlayerID)
	if  instance._FriendList ~= nil then
		for i,v in pairs(instance._FriendList) do 
			if v ~= nil and v.RoleID == nPlayerID then return 0, i end	
		end		
	end
	
	if instance._EnemyList ~= nil then
		for i,v in pairs(instance._EnemyList) do
			if v ~= nil and v.RoleID == nPlayerID then return 1, i end
		end
	end	

	return nil,nil
end

--准备UI设置
local function OnReady(nPlayerID,isReady)
	local nType, idex = GetIdexByPlayerID(nPlayerID)
	if nType == nil then
		FlashTip("玩家ID错误："..nPlayerID,"tip",3)	
	return end 
	local isGray = not isReady
	if nType == 0 then --友方		
		if instance._FriendMemUI[idex] ~= nil  then
			GameUtil.MakeImageGray(instance._FriendMemUI[idex]._HeadImg,isGray)
			-- instance._FriendMemUI[idex]._ReadyImg: SetActive(isReady)
		end
	else 
		if instance._EnemyMemUI[idex] ~= nil  then
			GameUtil.MakeImageGray(instance._EnemyMemUI[idex]._HeadImg,isGray)
			-- instance._EnemyMemUI[idex]._ReadyImg: SetActive(isReady)
		end
	end
end

--头像设置
local function InitPlayerShow(nType,idex,iData)	
	if iData == nil then
		FlashTip("玩家数据错误!!","tip",3)	
	return end 
	
	if nType == 0 then --友方
		local FriendUIdata = instance._FriendMemUI[idex] 
		if FriendUIdata ~= nil and not IsNil(FriendUIdata._HeadImg) then
			--warn("??????"..iData.RoleID.."//"..iData.CustomImgSet.."//"..iData.Gender.."//"..iData.Profession)			
			game: SetEntityCustomImg(FriendUIdata._HeadImg,iData.RoleID,iData.CustomImgSet,iData.Gender,iData.Profession)

			GUI.SetText(FriendUIdata._LabLv,string.format(StringTable.Get(21508),iData.Level))
			GUI.SetText(FriendUIdata._LabJob, tostring(StringTable.Get(10300 + iData.Profession - 1)))
			local ColorName = "<color=#FFFFFFFF>" ..iData.Name .."</color>" 
			if iData.RoleID ==  game._HostPlayer._ID then
				-- GUITools.SetGroupImg(FriendUIdata._BoardImg, 0)
				ColorName =  "<color=#ECBE33FF>" .. iData.Name .."</color>" 
			end
			GUI.SetText(FriendUIdata._LabName,ColorName)

			GameUtil.MakeImageGray(FriendUIdata._HeadImg,true)
		end
	else 
		local EnemyUIdata = instance._EnemyMemUI[idex]
		if EnemyUIdata ~= nil and not IsNil(EnemyUIdata._HeadImg) then
			--warn("??????"..iData.RoleID.."//"..iData.CustomImgSet.."//"..iData.Gender.."//"..iData.Profession)
			game: SetEntityCustomImg(EnemyUIdata._HeadImg,iData.RoleID,iData.CustomImgSet,iData.Gender,iData.Profession)
			GUI.SetText(EnemyUIdata._LabLv,string.format(StringTable.Get(21508),iData.Level))
			GUI.SetText(EnemyUIdata._LabJob, tostring(StringTable.Get(10300 +iData.Profession - 1)))
			local ColorName = "<color=#FFFFFFFF>" ..iData.Name .."</color>"
			if iData.RoleID ==  game._HostPlayer._ID then
				ColorName =  "<color=#ECBE33FF>" .. iData.Name .."</color>" 
			end
			GUI.SetText(EnemyUIdata._LabName,ColorName)
			GameUtil.MakeImageGray(EnemyUIdata._HeadImg,true)
		end
	end
end

--取消匹配
local function CancelReady(self)
	game._GUIMan:Close("CPanelMate")
	local protocol = (require "PB.net".C2SMatchEnterConfirm)()
	local MatchType = 0
	if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 then 
		MatchType = EMatchType.EMatchType_Arena
	elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle then 
		MatchType = EMatchType.EMatchType_Eliminate
	end

	if protocol ~= nil then
		protocol.RoomId = instance._RoomID
		protocol.MatchType = MatchType
		protocol.Confirm = false
		PBHelper.Send(protocol)
	end
end

--准备确认
local function ConfigReady(self)
	local protocol = nil
	local protocol = (require "PB.net".C2SMatchEnterConfirm)()
	local MatchType = 0
	if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 then 
		MatchType = EMatchType.EMatchType_Arena
		protocol.Confirm = true
	elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle then 
		MatchType = EMatchType.EMatchType_Eliminate
		protocol.Confirm = false
	end
	protocol.MatchType = MatchType
	protocol.RoomId = instance._RoomID
	PBHelper.Send(protocol)
end

local function BattleOnReady(self)
	-- self._CurBattleConfirmNumber = self._CurBattleConfirmNumber + 1
	-- GUI.SetText(self._LabNumber,string.format(StringTable.Get(26004),self._CurBattleConfirmNumber,self._RoleCount))
end

-----------------------------------------外部接口------------------------------------------------
def.override("dynamic").OnData = function(self, data)
	self._CurArenaType = data.CurArenaType
	if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 then
		self:Init3V3Mate(data.Info)
	elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle then 
		self:InitBattleMate(data.Info)
	end
end

def.method("table").Init3V3Mate = function (self,data)
	self._FrameBattle:SetActive(false)
	self._Frame3V3:SetActive(true)
	self._FrameBtn3V3:SetActive(true)
	self._Lab_Tips:SetActive(false)
	self._EndTime = data.DeadLine
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena3v3Match, 0)  
	if data.IsConfirmed ~= nil and data.IsConfirmed then 
		self._FrameBtn3V3:SetActive(false)
		self._Lab_Tips:SetActive(true)
		GUI.SetText(self._Lab_Tips,StringTable.Get(26001))
	end

	-- 添加特效
	local imgTime = self:GetUIObject("Img_Time")
	GameUtil.PlayUISfx(PATH.UIFx_PVP2_MateFx,imgTime,imgTime,-1)

	local READY_TIME =  CSpecialIdMan.Get("Arena3V3ConfigTime")

	self._ReadTime = READY_TIME
	local startTime = 0
	local endTime = READY_TIME + GameUtil.GetServerTime()/1000
	
	if self._LabTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._LabTimerID)
		self._LabTimerID = 0
	end
	local callback2 = function ()
		startTime = math.floor( endTime - GameUtil.GetServerTime()/1000)
		self._ReadTime = endTime - GameUtil.GetServerTime()/1000 - 0.1
		if startTime < 0 then		 	
		 	_G.RemoveGlobalTimer(self._LabTimerID)
			self._LabTimerID = 0
			startTime = 0
			game._GUIMan:CloseByScript(self)
		end	
		GUI.SetText(self._LabTime,tostring(startTime))
	end
	self._LabTimerID = _G.AddGlobalTimer(0.1002, false, callback2)
	self._FriendList = {}
	self._EnemyList = {}
	for i,v in ipairs(data.BlackList) do
		self._FriendList[#self._FriendList + 1] = v
	end
	for i,v in ipairs(data.RedList) do
		self._EnemyList[#self._EnemyList + 1] = v
	end

	--设置友方头像
	for i,v in ipairs(self._FriendList) do
		InitPlayerShow(0,i,v)
		--warn("_FriendList__",v.RoleID)
	end

	--设置敌方头像
	for i,v in ipairs(self._EnemyList) do
		InitPlayerShow(1,i,v)
		--warn("_Enemey__",v.RoleID)
	end

	self._RoomID  = data.RoomId
end

def.method("table").InitBattleMate = function (self,data)
	self._FrameBattle:SetActive(true)
	self._Frame3V3:SetActive(false)
	self._RoomID = data.RoomId
	self._RoleCount = data.RoleCount 
	self._CurBattleConfirmNumber = 0
	if data.IsConfirmed ~= nil and data.IsConfirmed then 
		-- self._FrameBtnBattle:SetActive(false)
		-- self._Lab_Tips:SetActive(true)
		-- GUI.SetText(self._Lab_Tips,StringTable.Get(26002))
		self._CurBattleConfirmNumber = data.ConfirmCount
	end
	-- GUI.SetText(self._LabNumber,string.format(StringTable.Get(26004),self._CurBattleConfirmNumber,self._RoleCount))

	local READY_TIME = tonumber(CElementData.GetSpecialIdTemplate(self._BattleMateTimeSpecialId).Value)
	local startTime = 0
	local endTime = READY_TIME + GameUtil.GetServerTime()/1000
	
	if self._LabTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._LabTimerID)
		self._LabTimerID = 0
	end
	local callback3 = function ()
		startTime = math.floor( endTime - GameUtil.GetServerTime()/1000)
		self._ReadTime = endTime - GameUtil.GetServerTime()/1000 - 0.1
		if startTime < 0 then		 	
		 	_G.RemoveGlobalTimer(self._LabTimerID)
			self._LabTimerID = 0
			startTime = 0
			game._GUIMan:CloseByScript(self)
		end	
		GUI.SetText(self._LabTime,tostring(startTime))
	end
	self._LabTimerID = _G.AddGlobalTimer(1, false, callback3)
end

--Button
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		CancelReady(self)
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_No3V3" or id == "Btn_NoBattle"then
		CancelReady(self)
	elseif id == "Btn_Yes3V3" then
		self._FrameBtn3V3:SetActive(false)
		self._Lab_Tips:SetActive(true)
		GUI.SetText(self._Lab_Tips,StringTable.Get(26001))
		ConfigReady(self)
	elseif id == "Btn_NoBattle" then 
		self._FrameBtnBattle:SetActive(false)
		self._Lab_Tips:SetActive(true)
		GUI.SetText(self._Lab_Tips,StringTable.Get(26002))
		ConfigReady(self)
		game._GUIMan:CloseByScript(self)
	end
end

def.method("number","boolean").OnS2CConfigReady = function(self,nPlayerID,isConfig)
	if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 then
		OnReady(nPlayerID, isConfig)
	elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle then 
		BattleOnReady(self)
	end
end


def.override().OnDestroy = function(self)
	
	if self._LabTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._LabTimerID)
		self._LabTimerID = 0
	end

	self._Frame3V3 = nil
	self._FrameBattle = nil
	self._LabTime = nil
	self._ImgBtnYes3V3 = nil
	self._FrameBtn3V3 = nil
	self._Lab_Tips = nil
	self._BldSlider = nil
	self._LabNumber = nil
	self._FrameBtnBattle = nil
end

CPanelMate.Commit()
return CPanelMate