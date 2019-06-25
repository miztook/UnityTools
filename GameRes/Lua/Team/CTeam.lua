local Lplus = require "Lplus"
local CTeamMember = require "Team.CTeamMember"

local CTeam = Lplus.Class("CTeam")
local def = CTeam.define

def.field("number")._ID = 0
def.field("number")._TargetId = 0          --房间目标ID
def.field("table")._MemberList = BlankTable
def.field("string")._TeamNotice = ""
def.field("number")._TeamLeaderId = 0
def.field("string")._TeamLeaderName = ""
def.field("string")._TeamName = ""
def.field("number")._MemberMax = 5
def.field("number")._Competitiveness = 0 	--Sum TeamMembers._Fight
def.field("boolean")._AutoApprove = false
def.field("number")._FollowState = -1 		--EnumDef.FollowState.None
def.field("number")._FollowIndex = 0		--组队排序时的顺序，间距偏移量计算用
def.field("boolean")._IsBountyMode = false  --是否是赏金模式
--def.field("boolean")._IsAutoMatch = false    --是否支持自动匹配
def.field("number")._TeamMode = 0       -- 队伍类型，是普通队伍还是团队（data中的 enum TeamMode ）
def.field("table")._Setting = nil
def.field("boolean")._IsFirstInit = true

def.static("=>", CTeam).new = function ()
	local obj = CTeam()
	obj._MemberList = {}
	return obj
end

--是否在队伍中
def.method("=>", "boolean").InTeam = function(self)
	return self._ID > 0
end

-- 设置 队员最大上限
def.method("number").SetMemberMax = function(self, count)
	self._MemberMax = count
end

-- 获取 队员最大上限
def.method("=>", "number").GetMemberMax = function(self)
	return self._MemberMax
end

def.method().Reset = function (self)
	self._ID = 0
	self._TargetId = 0          --房间目标ID
	self._MemberList = {}
	self._TeamNotice = ""
	self._TeamLeaderId = 0
	self._TeamLeaderName = ""
    self._TeamName = ""
	self._MemberMax = 5
	self._Competitiveness = 0 	--Sum TeamMembers._Fight
	self._AutoApprove = false
	self._FollowState = -1 		--EnumDef.FollowState.None
	self._FollowIndex = 0		--组队排序时的顺序，间距偏移量计算用
	self._IsBountyMode = false  --是否是赏金模式
--	self._IsAutoMatch = false    --是否支持自动匹配
	self._Setting = nil
	self._IsFirstInit = true
end

CTeam.Commit()
return CTeam