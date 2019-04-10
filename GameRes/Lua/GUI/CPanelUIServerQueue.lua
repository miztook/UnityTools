-- 服务器排队界面
-- 2018.12.25

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIServerQueue = Lplus.Extend(CPanelBase, "CPanelUIServerQueue")
local def = CPanelUIServerQueue.define

def.field("userdata")._Frame_Queue = nil
def.field("userdata")._Lab_QueueInfo = nil
def.field("userdata")._Lab_WaitTime = nil
def.field("userdata")._Frame_OverLoad = nil

def.field("number")._SecondsPerPerson = 0 -- 服务器排队单人的预计时间（秒）
def.field("string")._Account = ""
def.field("string")._Password = ""

local COLOR_BULE_HEX = "<color=#3FD7E5>%s</color>" -- 浅蓝色
local MAX_QUEUE_PERSON = 9999 -- 显示的最大排队人数
local MAX_QUEUE_MINUTE = 60  -- 显示的最大预计时间

local instance = nil
def.static("=>",CPanelUIServerQueue).Instance = function ()
	if not instance then
		instance = CPanelUIServerQueue()
		instance._PrefabPath = PATH.UI_ServerQueue
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Frame_Queue = self:GetUIObject("Frame_Queue")
	self._Lab_QueueInfo = self:GetUIObject("Lab_QueueInfo")
	self._Lab_WaitTime = self:GetUIObject("Lab_WaitTime")
	self._Frame_OverLoad = self:GetUIObject("Frame_OverLoad")

	self._SecondsPerPerson = CSpecialIdMan.Get("ServerQueueSecondsPerPerson")
end

-- @param data 结构
--        Type 1:服务器排队 2:服务器爆满
--        CurNum 当前排队位置
--        TotalNum 排队总人数
--        Account 账号
--        Password 密码
def.override("dynamic").OnData = function(self, data)
	local isShowQueue = true
	if data ~= nil then
		if data.Type == 2 then
			isShowQueue = false
			if type(data.Account) == "string" then
				self._Account = data.Account
			end
			if type(data.Password) == "string" then
				self._Password = data.Password
			end
		end
	end
	GUITools.SetUIActive(self._Frame_Queue, isShowQueue)
	GUITools.SetUIActive(self._Frame_OverLoad, not isShowQueue)

	if isShowQueue then
		local curNum, totalNum = -1, -1
		if data ~= nil then
			if type(data.CurNum) == "number" then
				curNum = data.CurNum
			end
			if type(data.TotalNum) == "number" then
				totalNum = data.TotalNum
			end
		end
		self:UpdateQueueShow(curNum, totalNum)
	end
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Cancel" then
		game._GUIMan:CloseByScript(self)
		game:ResetConnection()
	elseif id == "Btn_ChangeServer" then
		game._GUIMan:Open("CPanelServerSelect", { account = self._Account, password = self._Password })
		game._GUIMan:CloseByScript(self)
	end
end

def.method("number", "number").UpdateQueueShow = function (self, curNum, totalNum)
	-- 等待信息
	local curNumStr = string.format(COLOR_BULE_HEX, GUITools.FormatNumber(curNum, false))
	local totalNumStr = GUITools.FormatNumber(totalNum, false)
	if totalNum > MAX_QUEUE_PERSON then
		totalNumStr = string.format(COLOR_BULE_HEX, totalNumStr .. "+")
	else
		totalNumStr = string.format(COLOR_BULE_HEX, totalNumStr)
	end
	local infoStr = string.format(StringTable.Get(32200), curNumStr, totalNumStr)
	GUI.SetText(self._Lab_QueueInfo, infoStr)
	-- 预计等待时间
	local waitMin = math.ceil((curNum * self._SecondsPerPerson) / 60) -- 单位：分
	local waitMinStr =  GUITools.FormatNumber(waitMin, false)
	if waitMin > MAX_QUEUE_MINUTE then
		waitMinStr = string.format(COLOR_BULE_HEX, waitMinStr .. "+")
	else
		waitMinStr = string.format(COLOR_BULE_HEX, waitMinStr)
	end
	waitMinStr = waitMinStr .. " " .. StringTable.Get(1001)
	GUI.SetText(self._Lab_WaitTime, waitMinStr)
end

def.override().OnDestroy = function(self)
	self._Frame_Queue = nil
	self._Lab_QueueInfo = nil
	self._Lab_WaitTime = nil
	self._Frame_OverLoad = nil
end

CPanelUIServerQueue.Commit()
return CPanelUIServerQueue