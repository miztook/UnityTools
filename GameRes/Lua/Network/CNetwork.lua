local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"

local CNetwork = Lplus.Class("CNetwork")
local def = CNetwork.define

def.field("userdata")._GameSession = nil
def.field("number")._ConnectStatus = 0
def.field("string")._IP = ""
def.field("number")._Port = 0
def.field("string")._RedirectIP = ""
def.field("number")._RedirectPort = 0
def.field("string")._ServerName = ""
def.field("string")._UserName = ""
def.field("string")._Password = ""
def.field("string")._AccountSaltPasswordMd5 = ""
def.field("number")._ConnectTimerId = 0
def.field("boolean")._Paused = false

local CONNECT_STATUS =
{
	OFFLINE = 0,      -- 离线
	ONLINE = 1,       -- 在线
}

--最大连接次数
local Max_Connect_Time = 15
--local max_proto_per_frame = 60
--local simple_proto_process_threshold = 30

def.static("=>", CNetwork).new = function ()
	local obj = CNetwork()	
	obj._ConnectStatus = CONNECT_STATUS.OFFLINE
	return obj
end

def.method().Init = function (self)
	self._GameSession = CGameSession.Instance()
end

def.method("string", "=>", "boolean").IsValidIpAddress = function (self, ip)
	return self._GameSession:IsValidIpAddress(ip)
end

def.method("string", "number", "string", "string", "string").Connect = function (self, ip, port, servername, username, password)
	if self._GameSession:IsConnected() or self._GameSession:IsConnecting() then	
		return
	end

	--添加计时器
	self:AddConnectTimer()
	self._IP = ip
	self._Port = port
	self._ServerName = servername
	self._UserName = username
	self._Password = password
	local salt = GlobalDefinition.AuthSalt
	self._AccountSaltPasswordMd5 = GameUtil.MD5ComputeHash(username .. salt .. password)
	self._GameSession:ConnectToServer(ip, port, username, password)

	self._RedirectIP = ""
	self._RedirectPort = 0

	local ipStr = string.format("%s:%d", ip, port)
	warn("Connect to gateway ", ipStr)
end

def.method("string").RedirectGate = function (self, addr)
	--warn("CNetwork:RedirectGate", self._GameSession:IsConnected(), self._GameSession:IsConnecting())
	--if self._GameSession:IsConnected() or self._GameSession:IsConnecting() then	
	--	return
	--end

	local strList = string.split(addr, ":")
	local ip = strList[1]
	local port = tonumber(strList[2])

	if ip == self._IP and port == self._Port then -- 当前网关即为最佳网关，就可以往下走
		self._ConnectStatus = CONNECT_STATUS.ONLINE
		warn("Direct Connect to", addr)

		self._RedirectIP = ""
		self._RedirectPort = 0

	elseif ip == "0.0.0.0" then -- "0.0.0.0"本地服默认配置，需要继续往下走
		self._ConnectStatus = CONNECT_STATUS.ONLINE
		warn("Redirect Connect to", addr)

		self._RedirectIP = ""
		self._RedirectPort = 0
		
	elseif ip == self._RedirectIP and port == self._RedirectPort then -- 重定向ip:port与客户端请求ip:port一致，表示重定向成功，就可以往下走
		self._ConnectStatus = CONNECT_STATUS.ONLINE
		warn("Redirect Connect to", addr)

		self._RedirectIP = ""
		self._RedirectPort = 0

	else -- 继续重定向
		self._RedirectIP = ip
		self._RedirectPort = port

		if self._GameSession:IsConnected() or self._GameSession:IsConnecting() then	
			self:Close()
		end

		warn("RedirectGate to", addr)

		self._GameSession:ConnectToServer(ip, port, self._UserName, self._Password)
	end 
end

def.method().AddConnectTimer = function(self)
	local connetTime = 0
	local canOpenCircle = true
	local callback = function()
		if canOpenCircle then
			local loginPanel = require "GUI.CPanelLogin".Instance()
			local loadingPanel = require "GUI.CPanelLoading".Instance()
			if not loginPanel:IsShow() and not loadingPanel:IsShow() then
				if self._ConnectStatus ~= CONNECT_STATUS.ONLINE and self._GameSession:IsConnecting() or self._GameSession:IsConnected() then
					game._GUIMan:ShowCircle(StringTable.Get(14002), true)
					canOpenCircle = false
				end
			end
		end
		if canOpenCircle then
			self:RemoveConnectTimer()
		end
		connetTime = connetTime + 1
		if connetTime >= Max_Connect_Time then
			self:RemoveConnectTimer()
			if not self._GameSession:IsConnected() then
				OnConnectionEvent(EVENT.CONNECT_FAILED)
			end
		end
	end
	if self._ConnectTimerId == 0 then
		self._ConnectTimerId = _G.AddGlobalTimer(1, false, callback)
	end
end

def.method().RemoveConnectTimer = function(self)
	if self._ConnectTimerId ~= 0 then
		_G.RemoveGlobalTimer(self._ConnectTimerId)
		self._ConnectTimerId = 0
	end
end

def.method().ReConnect = function (self)
	--warn(debug.traceback())
	if self._GameSession:IsConnected() or self._GameSession:IsConnecting() then
		return
	end
	local ip = self._IP
	local port = self._Port
	local username = self._UserName
	local password = self._Password
	--local salt = GlobalDefinition.AuthSalt
	--self._AccountSaltPasswordMd5 = GameUtil.MD5ComputeHash(username .. salt .. password)
	self._GameSession:ConnectToServer(ip, port, username, password)
end

-- SPT_ENTITY_MOVE  = 10531;
-- SPT_ENTITY_NOTIFY_ATTRS  = 10533;
-- SPT_ENTITY_BE_JUDGED = 10522

-- SPT_ENTITY_PERFORM_SKILL = 43501
-- SPT_ENTITY_BASE_STATE  = 10519;

local function IsSpecialProtocol(id)
	return id == 10531 or id == 10533 or id == 10522
end

local function SpecialProcess(id, msg)
	if id == 10531 then -- 缓存的移动协议可以直接设置位置
		local entity = game._CurWorld:FindObject(msg.EntityId) 
		if entity ~= nil then
			local speed = msg.MoveSpeed
			local cur_pos = Vector3.New(msg.CurrentPosition.x, msg.CurrentPosition.y, msg.CurrentPosition.z)
			local cur_ori = Vector3.New(msg.CurrentOrientation.x, msg.CurrentOrientation.y, msg.CurrentOrientation.z)
			--local movedir = Vector3.New(msg.MoveDirection.x, msg.MoveDirection.y, msg.MoveDirection.z)
			local dstPos = Vector3.New(msg.DstPosition.x, msg.DstPosition.y, msg.DstPosition.z)
			entity:SetMoveSpeed(speed) 
			--entity:SetPos(cur_pos)
			entity:SetDir(cur_ori)
			--entity:Move(dstPos, 0, nil, nil)
			entity:SetPos(dstPos)
			--warn(Time.frameCount, msg.EntityId, msg.MoveType)
		end
	end
end

local fOnReceiveProtocolData = PBHelper.OnReceiveProtocolData
local fParseProtocol = PBHelper.ParseProtocol

local function SimpleProcess(id, buffer)
	if not IsSpecialProtocol(id) then return false end

	local msg = fParseProtocol(id, buffer)

	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity == nil then return true end

	if id == 10531 then 
		local curStepDestPos = Vector3.New(msg.CurrentPosition.x, msg.CurrentPosition.y, msg.CurrentPosition.z)
		local finalDstPos = Vector3.New(msg.DstPosition.x, msg.DstPosition.y, msg.DstPosition.z)
		entity:OnMove_Simple(curStepDestPos, nil, msg.MoveType, nil, msg.MoveSpeed, msg.IsDestPosition, finalDstPos)
		return true
	elseif id == 10533 then
		entity:UpdateFightProperty_Simple(msg.CreatureAttrs, msg.IsNotifyFightScore)
		return true
	elseif id == 10522 then
		local attacker = game._CurWorld:FindObject(msg.OriginId)
		if not entity:IsHostPlayer() and (attacker == nil or not attacker:IsHostPlayer()) then
			local controlledInfo = msg.ControlledInfo
			if controlledInfo ~= nil and controlledInfo.ControlType ~= 0 and entity._HitEffectInfo ~= nil then
				entity:InterruptSkill(false)
				entity:StopMovementLogic()

				local hiteffect = entity._HitEffectInfo
				local hit_params = {controlledInfo.Param1, controlledInfo.Param2, controlledInfo.Param3}
				hiteffect:ChangeEffect(attacker, controlledInfo.ControlType, hit_params, controlledInfo.MovedDest)
			end
			
			if attacker ~= nil and attacker._SkillHdl._ClientCalcVictims and attacker._SkillHdl._ClientCalcVictims[msg.PerformId] then
				attacker._SkillHdl._ClientCalcVictims[msg.PerformId] = nil
			end

			if msg.HpDamage > 0 then
				entity:OnHPChange_Simple(-msg.HpDamage, -1)
			end
			return true
		end
	end

	return false
end

def.method("number", "string", "boolean", "boolean").ProcessProtocol = function(self, id, buffer, isSpecial, isSimple)
	if isSpecial and IsSpecialProtocol(id) then
		local msg = fParseProtocol(id, buffer)
		SpecialProcess(id, msg)
	else
		if not isSimple or not SimpleProcess(id, buffer) then
			fOnReceiveProtocolData(id, buffer)
		end
	end
end

def.method("boolean").SetProtocolPaused = function(self, isPaused)
	self._Paused = isPaused
	self._GameSession.IsProcessingPaused = isPaused
end

def.method("=>", "number").GetCurZoneId = function (self)
	local zoneId = 0
	local serverList = GameUtil.GetServerList(false)
	if serverList ~= nil then
		for _, info in ipairs(serverList) do
			if info.ip == self._IP and info.port == self._Port and info.name == self._ServerName then
				zoneId = info.zoneId
				break
			end
		end
	end
	return zoneId
end

def.method().Close = function (self)
    self:RemoveConnectTimer()
	self:OnClose()
end

def.method().OnClose = function (self)
	self._ConnectStatus = CONNECT_STATUS.OFFLINE
	self._GameSession:Close()
end

def.method().Release = function (self)	
end

CNetwork.Commit()

return CNetwork