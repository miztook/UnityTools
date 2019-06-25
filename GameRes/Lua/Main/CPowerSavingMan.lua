local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UserData = require "Data.UserData".Instance()
local CPowerSavingMan = Lplus.Class("CPowerSavingMan")
local def = CPowerSavingMan.define

def.static("=>", CPowerSavingMan).new = function()
	local obj = CPowerSavingMan()
	obj:LoadUserData()
	obj:CleanUp()
	return obj
end

-- Interval 1sec
-- TopCounts=30sec

def.field("boolean")._IsEnabled = true
def.field("number")._TimeCD = 0

def.field("boolean")._IsSleeping = false
def.field("boolean")._IsPlaying = false
def.field("boolean")._IsInCD = false
def.field("table")._DropItems = nil

def.field("number")._CurBgm = 0
def.field("number")._CurSfx = 0

-- local instance = nil

-- def.static("=>", CPowerSavingMan).Instance = function()
-- if instance == nil then
-- 	instance = CPowerSavingMan()
-- end
-- return instance
-- end

def.method("=>", "boolean").IsEnabled = function(self)
	return self._IsEnabled
end

def.method("boolean").Enable = function(self, is_enable)
	self._IsEnabled = is_enable
	self:UpdateCDState()
end

def.method().SaveToUserData = function(self)
	-- warn("SaveToUserData: ", debug.traceback())
	UserData:SetField(EnumDef.LocalFields.PowerSaving, self._IsEnabled)
	UserData:SetField(EnumDef.LocalFields.PowerSavingTime, self._TimeCD)
end

def.method().LoadUserData = function(self)
	local ev = UserData:GetField(EnumDef.LocalFields.PowerSaving)
	if ev == nil or type(ev) ~= "boolean" then
		self._IsEnabled = true
	else
		self._IsEnabled = ev
	end

	ev = UserData:GetField(EnumDef.LocalFields.PowerSavingTime)
	if ev == nil or type(ev) ~= "number" then
		self._IsEnabled = false
	else
		self:SetSleepingTime(ev)
	end

	-- warn("***LoadUserData: "..tostring(ev == nil or type(isClickGroundMove) ~= "boolean"))
end

def.method("number").SetSleepingTime = function(self, cd)
	self._TimeCD = cd
	GameUtil.SetSleepingCD(self._TimeCD)
end

def.method().StartPlaying = function(self)
	--warn("PowerSaving StartPlaying")

	self._IsPlaying = true
	self:UpdateCDState()
end

def.method().StopPlaying = function(self)
	--warn("PowerSaving StopPlaying")

	self._IsPlaying = false
	self:UpdateCDState()
end

def.method().BeginSleeping = function(self)
	if not self._IsSleeping then
		self._IsSleeping = true
		self._IsInCD = false
		--warn("PowerSaving BeginSleeping")

		-- mute sound
--	--	self._CurBgm = CSoundMan.Instance():GetBGMSysVolume()
--	--	self._CurSfx = CSoundMan.Instance():GetEffectSysVolume()
--	--	CSoundMan.Instance():SetBGMSysVolume(0)
--	--	CSoundMan.Instance():SetEffectSysVolume(0)
--		CSoundMan.Instance():SetSoundBGMVolume(0, true)
--		CSoundMan.Instance():SetSoundEffectVolume(0)
--		CSoundMan.Instance():SetSoundCutSceneVolume(0)
--		CSoundMan.Instance():SetSoundUIVolume(0)
		CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.PS, true)

		self._IsInCD = false
		GameUtil.EnterSleeping()

		game._GUIMan:Open("CPanelPowerSaving", nil)
	end
end

def.method().StopSleeping = function(self)
	-- un mute sound
--	CSoundMan.Instance():SetBGMSysVolume(self._CurBgm)
--	CSoundMan.Instance():SetEffectSysVolume(self._CurSfx)
	if self._IsSleeping then
		self._IsSleeping = false

--		CSoundMan.Instance():SetSoundBGMVolume(1, true)
--		CSoundMan.Instance():SetSoundEffectVolume(1)
--		CSoundMan.Instance():SetSoundCutSceneVolume(1)
--		CSoundMan.Instance():SetSoundUIVolume(1)
		CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.PS, false)

		GameUtil.LeaveSleeping()

		self:UpdateCDState()
		self:ShowRewards()
	end
end

def.method("=>", "boolean").IsSleeping = function(self)
	return self._IsSleeping
end

def.method().UpdateCDState = function(self)
	local is_on = false

	if self._IsEnabled then
		if self._IsPlaying and not self._IsSleeping then
			is_on = true
		end
	end

	if self._IsInCD ~= is_on then

		-- warn("self._IsInCD ~= is_on " .. tostring(is_on))

		self._IsInCD = is_on
		if self._IsInCD then
			GameUtil.StartSleepingCD()
		else
			GameUtil.StopSleepingCD()
		end
	end
end

def.method("number", "boolean", "number").AddDropItem = function(self, i_id, is_token, i_count)
	-- warn("AddDropItem " .. i_id .. " " .. i_count)
	local id = i_id * 2
	if is_token then
		id = id + 1
		-- encode money as odd number
	end

	local l_it = self._DropItems[id]
	if l_it == nil then
		l_it = { }
		l_it.Count = 0
		self._DropItems[id] = l_it
	end
	l_it.Count = l_it.Count + i_count
	l_it.Id = i_id

end

def.method().ShowRewards = function(self)
	-- local rewardList = GUITools.GetRewardList(data._RewardId, true)
	local msg = { }
	msg.Items = { }
	msg.Moneys = { }
	for i, v in pairs(self._DropItems) do
		if math.fmod(i, 2) == 1 then
			-- test key with odd number
			local count = #msg.Moneys + 1
			msg.Moneys[count] = { }
			msg.Moneys[count].MoneyId = v.Id
			msg.Moneys[count].Count = v.Count
		else
			local count = #msg.Items + 1
			msg.Items[count] = { }
			msg.Items[count].ItemId = v.Id
			msg.Items[count].Count = v.Count
		end
	end

	if #msg.Items > 0 or #msg.Moneys > 0 then
		local panelData = { }
		panelData =
		{
			IsFromRewardTemplate = false,
			ListItem = msg.Items,
			MoneyList = msg.Moneys,
		}
		game._GUIMan:Open("CPanelLottery", panelData)

		-- warn("CPanelLottery")
		self._DropItems = { }
	end
end

def.method().CleanUp = function(self)
	self:StopPlaying()

	GameUtil.ResetSleepingCD()

	self._IsSleeping = false
	self._IsPlaying = false
	self._IsInCD = false
	self._DropItems = { }
end

CPowerSavingMan.Commit()
return CPowerSavingMan
