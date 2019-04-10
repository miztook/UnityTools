-- todo cache string table

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
-- local CPowerSavingMan = require "Main.CPowerSavingMan"
local CLoopQueue = require "Utility.CLoopQueue"
local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
local NotifyBagCapacityEvent = require "Events.NotifyBagCapacityEvent"
local CPanelPowerSaving = Lplus.Extend(CPanelBase, "CPanelPowerSaving")
local def = CPanelPowerSaving.define

def.field("userdata")._ListPops = nil
def.field("userdata")._ListItem = nil
def.field("userdata")._TxtClock = nil
def.field("userdata")._NodeBag = nil
def.field("userdata")._NodeBattery = nil
def.field("userdata")._NodeWifi = nil
-- bag icon
def.field("userdata")._BagBg = nil
def.field("userdata")._BagBg1 = nil
def.field("userdata")._BagCoolDown = nil
def.field("userdata")._BagCoolDown1 = nil
def.field("userdata")._BagCoolDownNum = nil
def.field("userdata")._BagCoolDownComp = nil
-- battery
def.field("userdata")._ImgBattery = nil
def.field("userdata")._ImgRechange = nil
def.field("userdata")._TxtBatteryLv = nil
def.field("userdata")._ImgBatteryComp = nil
-- wifi
def.field("userdata")._ImgNetWifi = nil
def.field("userdata")._ImgNetData = nil

-- timer
def.field("number")._RefreshTimer = 0
def.field("number")._RefreshIntv = 1
def.field("number")._PopsRefreshTimer = 0
def.field("number")._PopsRefreshIntv = 15

def.field("dynamic")._CurFXPath = nil

-- pop msg count limit
local Max_Pops = 8
-- def.field("table")._Pops = BlankTable
-- def.field("number")._PopsCount = 0
-- def.field("number")._PopsStart = Max_Pops

def.field("dynamic")._IsDay = nil

def.field(CLoopQueue)._Pops = nil
def.field("boolean")._IsBagDirty = true
def.field("number")._BatterySta = -999
def.field("number")._BatteryLv = -999
def.field("number")._WifiSta = -999

-- string cache
def.field("string")._TimeFormat = ""
def.field("string")._TimeTitleM = ""
def.field("string")._TimeTitleH = ""

local instance = nil
def.static("=>", CPanelPowerSaving).Instance = function()
	if instance == nil then
		instance = CPanelPowerSaving()
		instance._PrefabPath = PATH.UI_PowerSaving
		instance._PanelCloseType = EnumDef.PanelCloseType.None

		instance._DestroyOnHide = true
		instance:SetupSortingParam()
	end
	return instance
end

local function Sec2Time(time)
	local s = math.fmod(time, 60)
	time =(time - s) / 60
	local m = math.fmod(time, 60)
	time =(time - m) / 60

	return time, m, s
end

local function ShowTime(self, txt_time, sec)
	local msg = nil
	if sec >= 3600 then
		sec = sec / 3600
		if sec > 24 then sec = 24 end
		msg = string.format(self._TimeTitleH, sec)
		-- local h, m, s = Sec2Time(sec)
		-- msg = string.format(StringTable.Get(22852), h, m)
	else
		-- if sec >= 60 then
		msg = string.format(self._TimeTitleM, sec / 60)
		-- else
		-- msg = string.format(StringTable.Get(22850), sec)
	end
	GUI.SetText(txt_time, msg)
end

local function RemovePop(self, id)
	-- warn("RemovePop " .. id)

	if self._Pops == nil then return end

	-- table.remove(self._Pops, 1)
	self._Pops:Remove(id)
	-- self._ListPops:RemoveItem(id - 1, 1)
	-- self._PopsCount = self._PopsCount - 1
end

local function AddPop(self, msg)
	-- warn("AddPop " .. msg)

	if self._Pops == nil then return end

	local pop = nil

	if self._Pops:Count() >= Max_Pops then
		pop = self._Pops:GetAt(self._Pops:Count())
		RemovePop(self, self._Pops:Count())
	else
		pop = { }
	end

	pop.time = 0
	pop.msg = msg

	-- table.insert(self._Pops, pop)

	-- self._ListPops:AddItem(0, 1)

	if pop.Object == nil then
		pop.Object = GameObject.Instantiate(self._ListItem)
		pop.Object:SetParent(self._ListPops, false)
	end

	local g = pop.Object
	if g ~= nil then
		local txt_txt = g:GetComponent(ClassType.UITemplate):GetControl(0)
		local txt_time = g:GetComponent(ClassType.UITemplate):GetControl(1)

		ShowTime(self, txt_time, pop.time)
		GUI.SetText(txt_txt, pop.msg)

		pop.Object:SetAsFirstSibling()
	end

	self._Pops:EnQueue(pop)

	-- warn("self._Pops:Count() "..self._Pops:Count())

end

local OnNotifyPopEvent = function(sender, event)
	-- warn("OnNotifyPopEvent")

	if instance ~= nil and instance:IsShow() then
		local str_msg = ""
		-- Dead, BagFull, LevelUp, TeamInv, Activity,Dungeon
		if event.Type == "Dead" then
			str_msg = StringTable.Get(22861)
			AddPop(instance, str_msg)
		elseif event.Type == "BagFull" then
			str_msg = StringTable.Get(22862)
			AddPop(instance, str_msg)
		elseif event.Type == "TeamInv" then
			-- s2cTeam 555
--			if event.Param2 or event.Param2 == "" then
--				event.Param2=StringTable.Get(8076)
--			end
			str_msg = string.format(StringTable.Get(22863), event.Param1)
			AddPop(instance, str_msg)
		elseif event.Type == "Activity" then
			-- str_msg = StringTable.Get(22864)
			str_msg = string.format(StringTable.Get(22864), event.Param1)
			AddPop(instance, str_msg)
		elseif event.Type == "Dungeon" then
			-- str_msg = StringTable.Get(22865)
			str_msg = string.format(StringTable.Get(22865), event.Param1)
			AddPop(instance, str_msg)
		end
		-- warn("Notify Pop Event " .. str_msg)
	end
end

local OnNotifyBagCapacity = function(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance._IsBagDirty = true
	end
end

-- bag icon
def.method("userdata", "userdata", "userdata", "userdata", "userdata", "userdata").ShowBagCapacity = function(self, BagBg, BagBg1, BagCoolDown, BagCoolDown1, BagCoolDownNum, BagCoolDownCom)

	if game._HostPlayer == nil then
		error("PowerSaving err")
		return
	end

	local bag_pct = #game._HostPlayer._Package._NormalPack._ItemSet / game._HostPlayer._Package._NormalPack._EffectSize

	if bag_pct >= 1 then

		-- local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
		local event = NotifyPowerSavingEvent()
		event.Type = "BagFull"
		-- CGame.EventManager:raiseEvent(nil, event)
		OnNotifyPopEvent(nil, event)

		BagBg:SetActive(false)
		BagBg1:SetActive(true)
		BagCoolDown:SetActive(false)
		BagCoolDown1:SetActive(true)
		GameUtil.PlayUISfx(PATH.UIFx_zhujiemian_beibaoman, BagBg, BagBg, -1)
	else
		BagBg:SetActive(true)
		BagBg1:SetActive(false)
		BagCoolDown:SetActive(true)
		BagCoolDown1:SetActive(false)
		GameUtil.StopUISfx(PATH.UIFx_zhujiemian_beibaoman, BagBg)
	end
	GUI.SetText(BagCoolDownNum, math.floor(bag_pct * 100) .. "%")
	if BagCoolDownCom then
		BagCoolDownCom.fillAmount =(bag_pct * 80 + 10) / 100
	end
end

-- battery icon
def.method("userdata", "userdata", "number").ShowBatteryState = function(self, imgBattery, imgRechange, bat_sta)
	if bat_sta == EnumDef.BatteryStatus.Charging then
		imgRechange:SetActive(true)
		GUITools.SetGroupImg(imgBattery, 1)
	else
		imgRechange:SetActive(false)
		GUITools.SetGroupImg(imgBattery, 0)
	end
end

def.method("userdata", "userdata", "number").ShowBatteryLv = function(self, BatteryLv, imgBatteryCom, bat_pct)
	--GUI.SetText(BatteryLv, math.floor(bat_pct * 100) .. "%")
	imgBatteryCom.fillAmount = bat_pct
end

-- wifi icon
def.method("userdata", "userdata").ShowWifiState = function(self, imgWifi, imgData)
	local w_lv = game:GetNetworkStatus()
	local imgNetwork = nil
	if w_lv == EnumDef.NetworkStatus.DataNetwork then
		imgData:SetActive(true)
		imgWifi:SetActive(false)
		imgNetwork = imgData
	elseif w_lv == EnumDef.NetworkStatus.LocalNetwork then
		imgData:SetActive(false)
		imgWifi:SetActive(true)
		imgNetwork = imgWifi
	elseif w_lv == EnumDef.NetworkStatus.NotReachable then
		imgData:SetActive(false)
		imgWifi:SetActive(false)
		return
	end
	if imgNetwork == nil then return end
	local ping = game:GetPing()
	if ping <= 100 then
		local color = Color.New(92 / 255, 190 / 255, 55 / 255, 1)
		GUITools.SetGroupImg(imgNetwork, 2)
		GameUtil.SetImageColor(imgNetwork, color)
	elseif ping > 100 and ping <= 200 then
		local color = Color.New(211 / 255, 144 / 255, 84 / 255, 1)
		GUITools.SetGroupImg(imgNetwork, 1)
		GameUtil.SetImageColor(imgNetwork, color)
	else
		local color = Color.New(274 / 255, 0 / 255, 0 / 255, 0)
		GUITools.SetGroupImg(imgNetwork, 0)
		GameUtil.SetImageColor(imgNetwork, color)
	end
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end

	self._ListPops = self:GetUIObject("List_Pops")
	-- :GetComponent(ClassType.GNewListLoop)
	self._ListItem = self:GetUIObject("Pop_Item")
	self._TxtClock = self:GetUIObject("Lab_Clock")
	self._NodeBag = self:GetUIObject("Node_Bag")
	self._NodeBattery = self:GetUIObject("Node_Battery")
	self._NodeWifi = self:GetUIObject("Node_Wifi")

	local uiTemplate = nil
	uiTemplate = self._NodeBag:GetComponent(ClassType.UITemplate)
	self._BagBg = uiTemplate:GetControl(0)
	self._BagBg1 = uiTemplate:GetControl(1)
	self._BagCoolDown = uiTemplate:GetControl(2)
	self._BagCoolDown1 = uiTemplate:GetControl(3)
	self._BagCoolDownNum = uiTemplate:GetControl(4)
	self._BagCoolDownComp = self._BagCoolDown:GetComponent(ClassType.Image)

	uiTemplate = self._NodeBattery:GetComponent(ClassType.UITemplate)
	self._ImgBattery = uiTemplate:GetControl(1)
	self._ImgRechange = uiTemplate:GetControl(2)
	self._TxtBatteryLv = uiTemplate:GetControl(3)
	self._ImgBatteryComp = self._ImgBattery:GetComponent(ClassType.Image)

	uiTemplate = self._NodeWifi:GetComponent(ClassType.UITemplate)
	self._ImgNetWifi = uiTemplate:GetControl(0)
	self._ImgNetData = uiTemplate:GetControl(1)

	self._Pops = CLoopQueue.new()
	self._Pops:Init(Max_Pops)

	self._TimeFormat = StringTable.Get(22853)
	self._TimeTitleM = StringTable.Get(22851)
	self._TimeTitleH = StringTable.Get(22852)
end

def.override("dynamic").OnData = function(self, data)
	CPanelBase.OnData(self, data)
	CGame.EventManager:addHandler(NotifyPowerSavingEvent, OnNotifyPopEvent)
	CGame.EventManager:addHandler(NotifyBagCapacityEvent, OnNotifyBagCapacity)

	-- self._ListPops:SetItemCount(0)
	self:OnRefresh()

	if self._RefreshTimer == 0 then
		local callback = function()
			-- warn("Timer update")
			self:OnRefresh()
		end
		self._RefreshTimer = _G.AddGlobalTimer(self._RefreshIntv, false, callback)
	end
	-- warn("OnData")
end

-- local debug_sign = 0
-- refresh time
def.method().OnRefresh = function(self)

	-- warn("OnRefresh")

	-- -- debug
	-- local it = 5
	-- debug_sign = debug_sign + 1
	-- debug_sign = math.fmod(debug_sign, 5 * it)
	-- -- local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
	-- local event = NotifyPowerSavingEvent()

	-- if (debug_sign == 0) then
	-- 	event.Type = "Dead"
	-- 	CGame.EventManager:raiseEvent(nil, event)
	-- elseif debug_sign == 1 * it then
	-- 	event.Type = "BagFull"
	-- 	CGame.EventManager:raiseEvent(nil, event)
	-- elseif debug_sign == 2 * it then
	-- 	event.Type = "TeamInv"
	-- 	event.Param1 = "aaa"
	-- 	event.Param2 = "bbb"
	-- 	CGame.EventManager:raiseEvent(nil, event)
	-- elseif debug_sign == 3 * it then
	-- 	event.Type = "Activity"
	-- 	event.Param1 = "aaa"
	-- 	CGame.EventManager:raiseEvent(nil, event)
	-- elseif debug_sign == 4 * it then
	-- 	event.Type = "Dungeon"
	-- 	event.Param1 = "aaa"
	-- 	CGame.EventManager:raiseEvent(nil, event)
	-- end

	-- Update Clock
	local sec = GameUtil.GetCurrentSecondTime()
	local h, m, s = Sec2Time(sec)
	local is_day = h >= 6 and h < 18
	if is_day ~= self._IsDay then
		self._IsDay = is_day
		self:SetUIColor(is_day)
	end
	GUI.SetText(self._TxtClock, string.format(self._TimeFormat, h, m))

	if self._IsBagDirty then
		self:ShowBagCapacity(self._BagBg, self._BagBg1, self._BagCoolDown, self._BagCoolDown1, self._BagCoolDownNum, self._BagCoolDownComp)
		self._IsBagDirty = false
	end

	local tmp_v = 0
	tmp_v = game:GetBatteryStatus()
	if self._BatterySta ~= tmp_v then
		self._BatterySta = tmp_v
		self:ShowBatteryState(self._ImgBattery, self._ImgRechange, self._BatterySta)
	end
	tmp_v = game:GetBatteryLevel()
	if tmp_v < 0 then tmp_v = 0 end
	if self._BatteryLv ~= tmp_v then
		self._BatteryLv = tmp_v
		self:ShowBatteryLv(self._TxtBatteryLv, self._ImgBatteryComp, self._BatteryLv)
	end

	-- tmp_v = game:GetNetworkStatus() -1
	-- --warn("GetNetworkStatus  "..tmp_v)
	-- if self._WifiSta ~= tmp_v then
	-- 	self._WifiSta = tmp_v
	self:ShowWifiState(self._ImgNetWifi, self._ImgNetData)
	-- end

	-- update pops time
	self._PopsRefreshTimer = self._PopsRefreshTimer + self._RefreshIntv
	if self._PopsRefreshTimer >= self._PopsRefreshIntv then
		if self._Pops ~= nil then
			local pop_count = self._Pops:Count()
			if pop_count > 0 then
				for i = 1, pop_count do
					local pop = self._Pops:GetAt(i)
					if pop ~= nil then
						pop.time = pop.time + self._PopsRefreshTimer
						-- local g = self._ListPops:GetItem(i - 1)
						local g = pop.Object
						if g ~= nil then
							local txt_time = g:GetComponent(ClassType.UITemplate):GetControl(1)
							ShowTime(self, txt_time, pop.time)
						end
					end
				end
				-- self._ListPops:Repaint()
			end
		end
		self._PopsRefreshTimer = 0
	end

end

def.override("boolean").OnVisibleChange = function(self, is_show)
	-- game._GUIMan:HideMainCamera(is_show)
	game._GUIMan:BlockMainCamera(self, is_show)
end

def.override().OnHide = function(self)
	CPanelBase.OnHide(self)
	CGame.EventManager:removeHandler(NotifyPowerSavingEvent, OnNotifyPopEvent)
	CGame.EventManager:removeHandler(NotifyBagCapacityEvent, OnNotifyBagCapacity)

	if self._RefreshTimer ~= 0 then
		_G.RemoveGlobalTimer(self._RefreshTimer)
		self._RefreshTimer = 0
	end

	self._Pops = nil
	self._IsDay = true

	game._CPowerSavingMan:StopSleeping()
end

def.override().OnDestroy = function(self)
	instance = nil
end

def.override("string").OnButtonSlide = function(self, id)
	if id == "Btn_Slide" then
		self:Close()
	end
end

def.method("boolean").SetUIColor = function(self, time)
	local c1
	local c2
	local bg_id

	--warn("SetUIColor "..tostring(time))
	local img_bg = self:GetUIObject("Img_BG")

	if self._CurFXPath ~= nil then
		GameUtil.StopUISfx(self._CurFXPath, img_bg)
	end

	if time == false then
		c1 = Color.New(1, 1, 1, 0.4)
		c2 = Color.New(169 / 255, 190 / 255, 222 / 255, 1)
		bg_id = 0
		self._CurFXPath = PATH.UI_PowerSaving_Sfx_Night
	else
		c1 = Color.New(1, 1, 1, 1)
		c2 = Color.New(211 / 255, 178 / 255, 157 / 255, 1)
		bg_id = 1
		self._CurFXPath = PATH.UI_PowerSaving_Sfx_Day
	end

	GUITools.SetGroupImg(img_bg, bg_id)
	--warn("self._CurFXPath "..self._CurFXPath)
	GameUtil.PlayUISfx(self._CurFXPath, img_bg, img_bg, -1)
	GUI.SetTextColor(self:GetUIObject("Lab_Slide"), c1)

	if self._Pops ~= nil then
		local pop_count = self._Pops:Count()
		if pop_count > 0 then
			for i = 1, pop_count do
				local pop = self._Pops:GetAt(i)
				if pop ~= nil then
					local g = pop.Object
					if g ~= nil then
						local txt_info = g:GetComponent(ClassType.UITemplate):GetControl(0)
						GUI.SetTextColor(txt_info, c2)
					end
				end
			end
		end
	end
end


-- def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
-- local index = index + 1
-- if id == "List_Pops" then
-- 	local txt_txt = item:GetComponent(ClassType.UITemplate):GetControl(0)
-- 	local txt_time = item:GetComponent(ClassType.UITemplate):GetControl(1)

-- 	local data = self._Pops:GetAt(index)

-- 	ShowTime(self, txt_time, data.time)
-- 	GUI.SetText(txt_txt, data.msg)
-- end
-- end

-- def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
-- local index = index + 1
-- if id == "List_Pops" then
-- 	if id_btn == "Btn_Close" then

-- 		RemovePop(self, index)
-- 	end
-- end
-- end

CPanelPowerSaving.Commit()
return CPanelPowerSaving