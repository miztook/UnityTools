local Lplus = require "Lplus"

local net = require "PB.net"


local GcCallbacks = require "Utility.GcCallbacks"

local pairs = pairs
local require = require
local type = type
local warn = warn
local error = error
local tostring = tostring
local _G = _G

local l_nameToInfo = {}		--name => {type=type, name=name, pb_class=pb_class, id=id}
local l_pbClassToInfo = {}		--pb_class => {type=type, name=name, pb_class=pb_class, id=id}

local function addPbInfo (type, name, pb_class, id)
	local info = {type=type, name=name, pb_class=pb_class, id=id}
	l_nameToInfo[name] = info
	l_pbClassToInfo[pb_class] = info
end

--local l_s2cIdToS2cClass = {}
local l_s2cIdToPbClass = {}
local l_c2sIdToPbClass = {}

-- 协议处理Map
local l_pbClassToHandler = {}

-- 注册 S2C 子类
local function registerS2C (name, id, pb_class)
	addPbInfo("S2C", name, pb_class, id)
	l_s2cIdToPbClass[id] = pb_class
end

-- 注册 C2S 子类
local function registerC2S (name, id, pb_class)
	addPbInfo("C2S", name, pb_class, id)
	l_c2sIdToPbClass[id] = pb_class
end

local  C2S_PROTOC_TYPE                 = net.C2S_PROTOC_TYPE
local  C2S_PROTOC_TYPE_ACHIEVE         = net.C2S_PROTOC_TYPE_ACHIEVE
local  C2S_PROTOC_TYPE_ARENA           = net.C2S_PROTOC_TYPE_ARENA
local  C2S_PROTOC_TYPE_BAG             = net.C2S_PROTOC_TYPE_BAG
local  C2S_PROTOC_TYPE_CHARM           = net.C2S_PROTOC_TYPE_CHARM
local  C2S_PROTOC_TYPE_COUNTGROUP      = net.C2S_PROTOC_TYPE_COUNTGROUP
local  C2S_PROTOC_TYPE_DAMAGESTATISTICS= net.C2S_PROTOC_TYPE_DAMAGESTATISTICS
local  C2S_PROTOC_TYPE_DEBUG           = net.C2S_PROTOC_TYPE_DEBUG
local  C2S_PROTOC_TYPE_DESIGNATION     = net.C2S_PROTOC_TYPE_DESIGNATION
local  C2S_PROTOC_TYPE_DRESS           = net.C2S_PROTOC_TYPE_DRESS
local  C2S_PROTOC_TYPE_EMAIL           = net.C2S_PROTOC_TYPE_EMAIL
local  C2S_PROTOC_TYPE_EQUIP           = net.C2S_PROTOC_TYPE_EQUIP
local  C2S_PROTOC_TYPE_EXPEDITION      = net.C2S_PROTOC_TYPE_EXPEDITION
local  C2S_PROTOC_TYPE_GUIDE           = net.C2S_PROTOC_TYPE_GUIDE
local  C2S_PROTOC_TYPE_INSTANCE        = net.C2S_PROTOC_TYPE_INSTANCE
local  C2S_PROTOC_TYPE_ITEM            = net.C2S_PROTOC_TYPE_ITEM
local  C2S_PROTOC_TYPE_JJC             = net.C2S_PROTOC_TYPE_JJC
local  C2S_PROTOC_TYPE_MANUAL          = net.C2S_PROTOC_TYPE_MANUAL
local  C2S_PROTOC_TYPE_MAP             = net.C2S_PROTOC_TYPE_MAP
local  C2S_PROTOC_TYPE_MARKET          = net.C2S_PROTOC_TYPE_MARKET
local  C2S_PROTOC_TYPE_NPCSALE         = net.C2S_PROTOC_TYPE_NPCSALE
local  C2S_PROTOC_TYPE_ELIMINATE       = net.C2S_PROTOC_TYPE_ELIMINATE
local  C2S_PROTOC_TYPE_GUILD           = net.C2S_PROTOC_TYPE_GUILD
local  C2S_PROTOC_TYPE_PET             = net.C2S_PROTOC_TYPE_PET
local  C2S_PROTOC_TYPE_PK              = net.C2S_PROTOC_TYPE_PK
local  C2S_PROTOC_TYPE_QUEST           = net.C2S_PROTOC_TYPE_QUEST
local  C2S_PROTOC_TYPE_RANK            = net.C2S_PROTOC_TYPE_RANK
local  C2S_PROTOC_TYPE_REDPOINT        = net.C2S_PROTOC_TYPE_REDPOINT
local  C2S_PROTOC_TYPE_REGIONRULE      = net.C2S_PROTOC_TYPE_REGIONRULE
local  C2S_PROTOC_TYPE_REPUTATION      = net.C2S_PROTOC_TYPE_REPUTATION
local  C2S_PROTOC_TYPE_REWARD          = net.C2S_PROTOC_TYPE_REWARD
local  C2S_PROTOC_TYPE_SCRIPT          = net.C2S_PROTOC_TYPE_SCRIPT
local  C2S_PROTOC_TYPE_SKILL           = net.C2S_PROTOC_TYPE_SKILL
local  C2S_PROTOC_TYPE_SOCIAL          = net.C2S_PROTOC_TYPE_SOCIAL
local  C2S_PROTOC_TYPE_STORAGEPACK     = net.C2S_PROTOC_TYPE_STORAGEPACK
local  C2S_PROTOC_TYPE_TEAM            = net.C2S_PROTOC_TYPE_TEAM
local  C2S_PROTOC_TYPE_WORLDBOSS       = net.C2S_PROTOC_TYPE_WORLDBOSS
local  C2S_PROTOC_TYPE_MARKET          = net.C2S_PROTOC_TYPE_MARKET
local  C2S_PROTOC_TYPE_TEAMROOM        = net.C2S_PROTOC_TYPE_TEAMROOM
local  C2S_PROTOC_TYPE_WING            = net.C2S_PROTOC_TYPE_WING
local  C2S_PROTOC_TYPE_CHAT            = net.C2S_PROTOC_TYPE_CHAT
local  C2S_PROTOC_TYPE_DAILYTASK       = net.C2S_PROTOC_TYPE_DAILYTASK
local  C2S_PROTOC_TYPE_ADVENTUREGUIDE  = net.C2S_PROTOC_TYPE_ADVENTUREGUIDE
local  C2S_PROTOC_TYPE_HOTTIME         = net.C2S_PROTOC_TYPE_HOTTIME
local  C2S_PROTOC_TYPE_ONLINEREWARD    = net.C2S_PROTOC_TYPE_ONLINEREWARD
local  C2S_PROTOC_TYPE_ELITEBOSS       = net.C2S_PROTOC_TYPE_ELITEBOSS
local  C2S_PROTOC_TYPE_MATCH           = net.C2S_PROTOC_TYPE_MATCH
local  C2S_PROTOC_TYPE_FESTIVAL 	   = net.C2S_PROTOC_TYPE_FESTIVAL

local S2C_PROTOC_TYPE = net.S2C_PROTOC_TYPE
local S2C_PROTOC_TYPE_ACHIEVE = net.S2C_PROTOC_TYPE_ACHIEVE
local S2C_PROTOC_TYPE_ADVENTUREGUIDE = net.S2C_PROTOC_TYPE_ADVENTUREGUIDE
local S2C_PROTOC_TYPE_ARENA = net.S2C_PROTOC_TYPE_ARENA
local S2C_PROTOC_TYPE_BAG = net.S2C_PROTOC_TYPE_BAG
local S2C_PROTOC_TYPE_CHARM = net.S2C_PROTOC_TYPE_CHARM
local S2C_PROTOC_TYPE_CHAT = net.S2C_PROTOC_TYPE_CHAT
local S2C_PROTOC_TYPE_COUNT_GROUP = net.S2C_PROTOC_TYPE_COUNT_GROUP
local S2C_PROTOC_TYPE_DAMAGE_STATISTICS = net.S2C_PROTOC_TYPE_DAMAGE_STATISTICS
local S2C_PROTOC_TYPE_DEBUG = net.S2C_PROTOC_TYPE_DEBUG
local S2C_PROTOC_TYPE_DESIGNATION = net.S2C_PROTOC_TYPE_DESIGNATION
local S2C_PROTOC_TYPE_ELIMINATE = net.S2C_PROTOC_TYPE_ELIMINATE
local S2C_PROTOC_TYPE_DRESS = net.S2C_PROTOC_TYPE_DRESS
local S2C_PROTOC_TYPE_MAIL = net.S2C_PROTOC_TYPE_MAIL
local S2C_PROTOC_TYPE_EQUIP = net.S2C_PROTOC_TYPE_EQUIP
local S2C_PROTOC_TYPE_EXPEDITION = net.S2C_PROTOC_TYPE_EXPEDITION
local S2C_PROTOC_TYPE_GUIDE = net.S2C_PROTOC_TYPE_GUIDE
local S2C_PROTOC_TYPE_GUILD = net.S2C_PROTOC_TYPE_GUILD
local S2C_PROTOC_TYPE_HORSE = net.S2C_PROTOC_TYPE_HORSE
local S2C_PROTOC_TYPE_INSTANCE = net.S2C_PROTOC_TYPE_INSTANCE
local S2C_PROTOC_TYPE_ITEM = net.S2C_PROTOC_TYPE_ITEM
local S2C_PROTOC_TYPE_JJC = net.S2C_PROTOC_TYPE_JJC
local S2C_PROTOC_TYPE_MANUAL = net.S2C_PROTOC_TYPE_MANUAL
local S2C_PROTOC_TYPE_MAP = net.S2C_PROTOC_TYPE_MAP
local S2C_PROTOC_TYPE_MARKET = net.S2C_PROTOC_TYPE_MARKET
local S2C_PROTOC_TYPE_NPCSALE = net.S2C_PROTOC_TYPE_NPCSALE
local S2C_PROTOC_TYPE_PET = net.S2C_PROTOC_TYPE_PET
local S2C_PROTOC_TYPE_PK = net.S2C_PROTOC_TYPE_PK
local S2C_PROTOC_TYPE_QUEST = net.S2C_PROTOC_TYPE_QUEST
local S2C_PROTOC_TYPE_RANK = net.S2C_PROTOC_TYPE_RANK
local S2C_PROTOC_TYPE_REDPOINT = net.S2C_PROTOC_TYPE_REDPOINT
local S2C_PROTOC_TYPE_REGION_RULE = net.S2C_PROTOC_TYPE_REGION_RULE
local S2C_PROTOC_TYPE_REPUTATION = net.S2C_PROTOC_TYPE_REPUTATION
local S2C_PROTOC_TYPE_REward = net.S2C_PROTOC_TYPE_REward
local S2C_PROTOC_TYPE_SCRIPT = net.S2C_PROTOC_TYPE_SCRIPT
local S2C_PROTOC_TYPE_SKILL = net.S2C_PROTOC_TYPE_SKILL
local S2C_PROTOC_TYPE_SOCIAL = net.S2C_PROTOC_TYPE_SOCIAL
local S2C_PROTOC_TYPE_STORAGEPACK = net.S2C_PROTOC_TYPE_STORAGEPACK
local S2C_PROTOC_TYPE_TEAM = net.S2C_PROTOC_TYPE_TEAM
local S2C_PROTOC_TYPE_WING = net.S2C_PROTOC_TYPE_WING
local S2C_PROTOC_TYPE_WORLD_BOSS = net.S2C_PROTOC_TYPE_WORLD_BOSS
local S2C_PROTOC_TYPE_TEAM_ROOM = net.S2C_PROTOC_TYPE_TEAM_ROOM
local S2C_PROTOC_TYPE_TOWER = net.S2C_PROTOC_TYPE_TOWER
local S2C_PROTOC_TYPE_DAILYTASK = net.S2C_PROTOC_TYPE_DAILYTASK
local S2C_PROTOC_TYPE_HOTTIME = net.S2C_PROTOC_TYPE_HOTTIME
local S2C_PROTOC_TYPE_ONLINEREWARD = net.S2C_PROTOC_TYPE_ONLINEREWARD
local S2C_PROTOC_TYPE_ELITEBOSS = net.S2C_PROTOC_TYPE_ELITEBOSS
local S2C_PROTOC_TYPE_MATCH = net.S2C_PROTOC_TYPE_MATCH
local S2C_PROTOC_TYPE_FESTIVAL = net.S2C_PROTOC_TYPE_FESTIVAL


for MsgName, MsgType in pairs(net) do
	if type(MsgType) == "table" and MsgType.GetFieldDescriptor then	--是一个 protocol buffer 消息
		local field = MsgType.GetFieldDescriptor("type")
		if field then
			local theType = field.enum_type
			
			if theType == C2S_PROTOC_TYPE or
			 theType == C2S_PROTOC_TYPE_ACHIEVE or

				 theType == C2S_PROTOC_TYPE_ARENA or

				theType == C2S_PROTOC_TYPE_BAG or
				 theType == C2S_PROTOC_TYPE_CHARM or

				theType == C2S_PROTOC_TYPE_COUNTGROUP or
				 theType == C2S_PROTOC_TYPE_DAMAGESTATISTICS or

				theType == C2S_PROTOC_TYPE_DEBUG or
				 theType == C2S_PROTOC_TYPE_DESIGNATION or

				theType == C2S_PROTOC_TYPE_DRESS or
				 theType == C2S_PROTOC_TYPE_EMAIL or

				theType == C2S_PROTOC_TYPE_EQUIP or
				 theType == C2S_PROTOC_TYPE_EXPEDITION or

				theType == C2S_PROTOC_TYPE_GUIDE or
				 theType == C2S_PROTOC_TYPE_INSTANCE or

				theType == C2S_PROTOC_TYPE_ITEM or
				 theType == C2S_PROTOC_TYPE_JJC or
				 ---
				theType == C2S_PROTOC_TYPE_MANUAL or
				 theType == C2S_PROTOC_TYPE_MAP or

				theType == C2S_PROTOC_TYPE_MARKET or
				 theType == C2S_PROTOC_TYPE_NPCSALE or

				theType == C2S_PROTOC_TYPE_ELIMINATE or
				 theType == C2S_PROTOC_TYPE_GUILD or

				theType == C2S_PROTOC_TYPE_PET or
				 theType == C2S_PROTOC_TYPE_PK or

				theType == C2S_PROTOC_TYPE_QUEST or
				 theType == C2S_PROTOC_TYPE_RANK or
				 ---
				theType == C2S_PROTOC_TYPE_REDPOINT or
				 theType == C2S_PROTOC_TYPE_REGIONRULE or

				theType == C2S_PROTOC_TYPE_REPUTATION or
				 theType == C2S_PROTOC_TYPE_REWARD or

				theType == C2S_PROTOC_TYPE_SCRIPT or
				 theType == C2S_PROTOC_TYPE_SKILL or

				theType == C2S_PROTOC_TYPE_SOCIAL or
				 theType == C2S_PROTOC_TYPE_STORAGEPACK or

				theType == C2S_PROTOC_TYPE_TEAM or
				 theType == C2S_PROTOC_TYPE_WORLDBOSS or

				theType == C2S_PROTOC_TYPE_MARKET or
				 theType == C2S_PROTOC_TYPE_TEAMROOM or

				theType == C2S_PROTOC_TYPE_WING or
				 theType == C2S_PROTOC_TYPE_CHAT or
				 
				 theType == C2S_PROTOC_TYPE_DAILYTASK or
				 theType == C2S_PROTOC_TYPE_ADVENTUREGUIDE or
				 
				 theType == C2S_PROTOC_TYPE_HOTTIME or
				 theType == C2S_PROTOC_TYPE_ONLINEREWARD or

				 theType == C2S_PROTOC_TYPE_ELITEBOSS or
				 theType == C2S_PROTOC_TYPE_MATCH or
				 
				 theType == C2S_PROTOC_TYPE_FESTIVAL then

				local MsgID = _G.C2ID[MsgName] --or field.default_value
				if not MsgID then 
					warn("Fail to RegisterC2S! Name:", MsgName) 
				else
					registerC2S(MsgName, MsgID, MsgType)
				end
			elseif  theType == S2C_PROTOC_TYPE or 
					theType == S2C_PROTOC_TYPE_ACHIEVE or 
					theType == S2C_PROTOC_TYPE_ADVENTUREGUIDE or 
					theType == S2C_PROTOC_TYPE_ARENA or 
					theType == S2C_PROTOC_TYPE_BAG or 
					theType == S2C_PROTOC_TYPE_CHARM or 
					theType == S2C_PROTOC_TYPE_CHAT or 
					theType == S2C_PROTOC_TYPE_COUNT_GROUP or 
					theType == S2C_PROTOC_TYPE_DAMAGE_STATISTICS or 
					theType == S2C_PROTOC_TYPE_DEBUG or 
					theType == S2C_PROTOC_TYPE_DESIGNATION or 
					theType == S2C_PROTOC_TYPE_ELIMINATE or 
					theType == S2C_PROTOC_TYPE_DRESS or 
					theType == S2C_PROTOC_TYPE_MAIL or 
					theType == S2C_PROTOC_TYPE_EQUIP or 
					theType == S2C_PROTOC_TYPE_EXPEDITION or 
					theType == S2C_PROTOC_TYPE_GUIDE or 
					theType == S2C_PROTOC_TYPE_GUILD or 
					theType == S2C_PROTOC_TYPE_HORSE or 
					theType == S2C_PROTOC_TYPE_INSTANCE or 
					theType == S2C_PROTOC_TYPE_ITEM or 
					theType == S2C_PROTOC_TYPE_JJC or 
					theType == S2C_PROTOC_TYPE_MANUAL or 
					theType == S2C_PROTOC_TYPE_MAP or 
					theType == S2C_PROTOC_TYPE_MARKET or 
					theType == S2C_PROTOC_TYPE_NPCSALE or 
					theType == S2C_PROTOC_TYPE_PET or 
					theType == S2C_PROTOC_TYPE_PK or 
					theType == S2C_PROTOC_TYPE_QUEST or 
					theType == S2C_PROTOC_TYPE_RANK or 
					theType == S2C_PROTOC_TYPE_REDPOINT or 
					theType == S2C_PROTOC_TYPE_REGION_RULE or 
					theType == S2C_PROTOC_TYPE_REPUTATION or 
					theType == S2C_PROTOC_TYPE_REward or 
					theType == S2C_PROTOC_TYPE_SCRIPT or 
					theType == S2C_PROTOC_TYPE_SKILL or 
					theType == S2C_PROTOC_TYPE_SOCIAL or 
					theType == S2C_PROTOC_TYPE_STORAGEPACK or 
					theType == S2C_PROTOC_TYPE_TEAM or 
					theType == S2C_PROTOC_TYPE_WING or 
					theType == S2C_PROTOC_TYPE_WORLD_BOSS or 
					theType == S2C_PROTOC_TYPE_TEAM_ROOM or 
					theType == S2C_PROTOC_TYPE_TOWER or
					theType == S2C_PROTOC_TYPE_DAILYTASK or
					theType == S2C_PROTOC_TYPE_HOTTIME or
					theType == S2C_PROTOC_TYPE_ONLINEREWARD or
					theType == S2C_PROTOC_TYPE_ELITEBOSS or
					theType == S2C_PROTOC_TYPE_MATCH or
					theType == S2C_PROTOC_TYPE_FESTIVAL then 

				local MsgID = _G.S2ID[MsgName] --or field.default_value
				if not MsgID then 
					warn("Fail to RegisterS2C! Name:", MsgName)
				else
				 	registerS2C(MsgName, MsgID, MsgType)
				end
			else
				--warn("Fail to Register C2S or S2C: ", MsgName)
			end
		end
	end
end

local PBHelper = Lplus.Class("PBHelper")
do
	local def = PBHelper.define
	
	local function requireCmdInfoByName (cmdName)
		local info = l_nameToInfo[cmdName]
		if info == nil then
			if HotFixFlag then
				return
			end
			error("bad protocol buffers command name: " .. tostring(cmdName))
		end
		return info.type, info.pb_class, info.id
	end
	
	--[[
		取得协议定义类
		param cmdName: 协议名
		return: 协议定义类
	]]
	def.static("string", "=>", "table").GetCmdClass = function (cmdName)
		local info = l_nameToInfo[cmdName]
		if info then
			return info.pb_class
		else
			return nil
		end
	end
	
	--[[
		创建出空的 protocol bufffers 消息
		param cmdName: 协议名
		return: 空的 protocol bufffers 消息。如果协议未找到，返回 nil
	]]
	def.static("string", "=>", "table").NewCmd = function (cmdName)
		local info = l_nameToInfo[cmdName]
		if info then
			return info.pb_class()
		else
			return nil
		end
	end
	
	--[[
		开始监听用 protocol buffers 定义的协议
		param cmdName: 协议名
		param handler: 收到协议的回调函数，其接口为:
			function onCmd (sender, msg)
				其中 sender 为发送者，msg 为 protocol buffers 消息
	]]
	def.static("string", "function").AddHandler = function (cmdName, handler)
		local type, pb_class, id = requireCmdInfoByName(cmdName)

		if type == "S2C" then
			l_pbClassToHandler[id] = handler
		else
			if HotFixFlag then
				return
			end
			error(("bad protocol type to receive, got type: %s, name: %s"):format(type, cmdName))
		end
	end
	
	--[[
		开始监听用 protocol buffers 定义的协议，并自动停止监听
		param cmdName: 协议名
		param handler: 收到协议的回调函数，其接口为:
			function onCmd (sender, msg)
				其中 sender 为发送者，msg 为 protocol buffers 消息
		param cleaner: 用于自动停止监听的 GcCallbacks 对象
	]]
	def.static("string", "function", GcCallbacks).AddHandlerWithCleaner = function (cmdName, handler, cleaner)
		PBHelper.AddHandler(cmdName, handler)
		cleaner:add(function ()
			PBHelper.RemoveHandler(cmdName, handler)
		end)
	end	

	--[[
		停止监听用 protocol buffers 定义的协议
		param cmdName: 协议名
		param handler: AddHandler 传入的回调函数
	]]
	def.static("string", "function").RemoveHandler = function (cmdName, handler)
		local type, pb_class, id = requireCmdInfoByName(cmdName)
		
		if type == "S2C" then
			local realHandler = l_pbClassToHandler[id]
			if realHandler then
				l_pbClassToHandler[id] = nil
			end
		else
			error(("bad protocol type to receive, got type: %s, name: %s"):format(type, cmdName))
		end
	end

	def.static("number", "string").OnReceiveProtocolData = function (protocolId, proto)
		_G._TotalRecvProtoCount = _G._TotalRecvProtoCount + 1
		local pb_class = l_s2cIdToPbClass[protocolId]

		if _G.logs2c and protocolId ~= net.S2C_PROTOC_TYPE.SPT_PING and protocolId ~= net.S2C_PROTOC_TYPE.SPT_SYNC_TIME then
			local info = l_pbClassToInfo[pb_class]
			if info ~= nil then warn("s2c recv: ", protocolId, info.name) else warn("s2c recv: ", protocolId, "unknown") end
		end
		 
		if pb_class ~= nil then
			local msg = pb_class()
			if proto ~= nil and string.len(proto) > 0 then
				msg:ParseFromString(proto)
			end
			--handle
			local realHandler = l_pbClassToHandler[protocolId]
			if realHandler then
				realHandler(pb_class, msg)
			end
		else
			warn(("unhandled protocol #%d"):format(protocolId))
		end
	end

	def.static("number", "string", "=>", "table").ParseProtocol = function (protocolId, proto)
		local pb_class = l_s2cIdToPbClass[protocolId]
		if pb_class ~= nil then
			local msg = pb_class()
			if proto ~= nil and string.len(proto) > 0 then
				msg:ParseFromString(proto)
				return msg
			else
				return nil
			end
		else
			return nil
		end
	end

	--[[
		发送一个用 Protocol buffers 定义的协议
		param msg: Protocol buffers 消息
	]]
	def.static("table").Send = function (msg)
		_G._TotalSendProtoCount = _G._TotalSendProtoCount + 1
		local pb_class = msg:GetMessage()
		local info = l_pbClassToInfo[pb_class]
		local type, id = info.type, info.id

		if _G.logc2s and id ~= net.C2S_PROTOC_TYPE.CPT_PING and id ~= net.C2S_PROTOC_TYPE.CPT_ROLE_MOVE then
			warn("c2s send: ", id, info.name)
		end

		GameUtil.SendProtocol(id, msg:SerializeToString())
		--print( "MLMLSendMsg", msg )
	end
end

return PBHelper.Commit()

