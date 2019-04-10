local Lplus = require "Lplus"

_G.SendStatus = 
{
	Success = 0, --
	Sending = 1,
	Failure = -1,
}

_G.ReadStatus = 
{
    NotRead = 0,
    Read = 1,
}


local CMsg = Lplus.Class("CMsg")
do
	local def = CMsg.define
	def.field("number").RoleId = 0 --消息发送者
	def.field("string").PlayerName = ""
	def.field("number").Prof = 0
	def.field("number").Gender = 0
	def.field("number").Level = 0
	def.field("number").UniqueMsgID = 0
	def.field("number").UniqueHpMsgID = 0 --发送时候的id
	def.field("boolean").IsSendMsg = true
	def.field("number").TimeStamp = 0 --消息发送时间
	def.field("number").Channel = 0
	def.field("number").MsgType = 0
	def.field("table").ChatLink = BlankTable   --ChatLink协议结构
	def.field("number").LinkType = 0
	def.field("dynamic").LinkParam1 = nil
	def.field("dynamic").LinkParam2 = nil
	def.field("number").ItemBgIndex = 0   --背包中对应服务器的index
	def.field("number").ItemBgType = 0     --背包的类型
	def.field("table").ItemInfo = BlankTable   --物品信息
	def.field("string").StrMsg = ""   --显示的聊天内容
	def.field("string").Voice = ""	  --显示的语音内容
	def.field("number").VoiceLength = 0		--显示的语音长度
	def.field("string").StrRichMsg = ""
	def.field("string").StrRecvMsg = ""
	def.field("number").MsgIndex = 0
    def.field("number").Status = ReadStatus.NotRead
    def.field("number").Result = SendStatus.Success -- 0:正常消息，1：发送中，-1：发送失败
	-- 队伍链接需要参数 目标id，需要战力，需要等级
	def.field("number").Link_TargetId = 0
	def.field("number").Link_FighatScore = 0
	def.field("number").Link_Level = 0
	-- 地图链接 需要参数  地图ID  坐标点
	def.field("number").Link_MapId = 0
	def.field("dynamic").Link_PathPos = 0

	local _nextId = 1
	local function nextRecvID()
		local r = _nextId
		_nextId = _nextId + 1
		return r
	end

	local _sendID = 1
	local function nextSendID()
		local r = _sendID
		_sendID = _sendID + 1
		return r
	end

	local function resetUniqueID()
		_nextId = 1
        _sendID = 1
	end

	local function newRecvMsg()
		local obj = CMsg()
		obj.UniqueMsgID = nextRecvID()
		obj.IsSendMsg = false
		return obj
	end
	
	local function newSendMsg()
		local obj = CMsg()
		obj.UniqueHpMsgID = nextSendID()
		obj.IsSendMsg = true
		return obj
	end

	def.const("function").ResetUniqueID  = resetUniqueID
	def.const("function").NewRecvMsg  = newRecvMsg
	def.const("function").NewSendMsg  = newSendMsg

end


CMsg.Commit()
return CMsg