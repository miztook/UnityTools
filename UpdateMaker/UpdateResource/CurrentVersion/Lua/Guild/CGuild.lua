local Lplus = require "Lplus"
local CGuild = Lplus.Class("CGuild")
local CGuildIconInfo = require "Guild.CGuildIconInfo"
local CGuildLimit = require "Guild.CGuildLimit"
local CGuildBuilding = require "Guild.CGuildBuilding"
local CElementData = require "Data.CElementData"
local def = CGuild.define

-- 公会ID
def.field("number")._GuildID = 0
-- 公会名字
def.field("string")._GuildName = ""
-- 公会状态
def.field("number")._GuildState = 0
-- 会长名字
def.field("string")._LeaderName = ""
-- 会长等级
def.field("number")._LeaderLevel = 0
-- 会长ID
def.field("number")._LeaderID = 0
-- 成员数量
def.field("number")._MemberNum = 0
-- 当前等级最大成员数
def.field("number")._MaxMemberNum = 0
-- 公会图标
def.field(CGuildIconInfo)._GuildIconInfo = nil
-- 公会等级
def.field("number")._GuildLevel = 0
-- 加入条件
def.field(CGuildLimit)._AddLimit = nil
-- 创建时间
def.field("number")._CreateTime = 0
-- 公会公告
def.field("string")._Announce = ""
-- 公会资金
def.field("number")._Fund = 0
-- 公会能源
def.field("number")._Energy = 0
-- 公会经验
def.field("number")._Exp = 0
-- 公会每日资金
def.field("number")._DayFund = 0
-- 公会每日能源
def.field("number")._DayEnergy = 0
-- 公会每日经验
def.field("number")._DayExp = 0
-- 公会要塞列表
def.field("table")._FortressList = BlankTable
-- 公会积分
def.field("number")._RewardPoints = 0
-- 公会周活跃
def.field("number")._GuildLiveness = 0
-- 活跃度排名
def.field("number")._LivenessRank = 0
-- 是否需要审批
def.field("boolean")._NeedAgree = true
-- 公会已拥有旗帜
def.field("table")._IconList = BlankTable
-- 公会成员列表(全部成员)
def.field("table")._MemberList = BlankTable
-- 公会成员(仅存Id)
def.field("table")._MemberID = BlankTable
-- 公会在线成员
def.field("table")._OnlineMemberID = BlankTable
-- 公会建筑列表
def.field("table")._BuildingList = BlankTable
-- 公会当前等级对应模板Id
def.field("number")._GuildModuleID = 0
-- 公会是否满级
def.field("boolean")._IsMaxLevel = true
-- 这里的数据初始是通过S2CRoleGuildInfo进行同步的
-- 申请公会ID列表
def.field("table")._ApplyList = BlankTable
-- 已经捐献次数
def.field("number")._DonateNum = 0
-- 已经帮助次数
def.field("number")._HelpNum = 0
-- 离开公会时间
def.field("number")._LeaveTime = 0
-- 已领取异界之门奖励
def.field("table")._ExpeditionRewardList = BlankTable
-- 公会贡献
def.field("number")._Contribute = 0
-- 公会荣誉
def.field("number")._GuildHonour = 0
-- 公会战场胜利场次
def.field("number")._GuildBFWinCount = 0
-- 公会战场积分
def.field("number")._GuildBFRank = 0
-- 积分奖励列表
def.field("table")._PointsList = BlankTable
-- 公会最大捐献次数
def.field("number")._MaxDonateNum = 0
-- 月光庭院最大帮助次数
def.field("number")._MaxHelpNum = 0
-- 公会副会长人数
def.field("number")._ViceNum = 0
-- 公会精英人数
def.field("number")._EliteNum = 0
-- 公会技能
def.field("table")._GuildSkill = BlankTable
-- 是否可升级(shit red point)
def.field("boolean")._LevelUp = false
-- 是否展示公会工资界面
def.field("boolean")._ShowSalary = false

-- 公会红点数据
def.field("table")._RedPoint = BlankTable

def.static("=>", CGuild).new = function()
	local obj = CGuild()
	obj._GuildIconInfo = CGuildIconInfo.new()
	obj._AddLimit = CGuildLimit.new()
	obj._MaxDonateNum = CSpecialIdMan.Get("GuildMaxDonateNum")
	local countGroupTid = CSpecialIdMan.Get("GuildPrayMaxHelp")
	obj._MaxHelpNum = CElementData.GetTemplate("CountGroup", countGroupTid).MaxCount

	obj:OnInitGuildBuildings()

	return obj
end

-- 获取剩余捐献次数
def.method("=>", "number").GetDonateNum = function(self)
	return self._MaxDonateNum - self._DonateNum
end

-- 获取剩余帮助次数
def.method("=>", "number").GetHelpNum = function(self)
	return self._MaxHelpNum - self._HelpNum
end

-- 获取公会技能战斗力
def.method("=>", "number").GetGuildSkillScore = function(self)
	if self._GuildSkill._SkillData == nil then
		--warn("This player do not have a guild")
		return 0
	end
	local CScoreCalcMan = require "Data.CScoreCalcMan"
	local score = 0
	local prof = game._HostPlayer._InfoData._Prof
	for i, v in ipairs(self._GuildSkill._SkillData) do
		score = score + CScoreCalcMan.Instance():CalcTalentSkillScore(prof, v.SkillId, v.SkillLevel)
	end

	return score
end

-- 初始化公会建筑信息(用于解锁显示)
def.method().OnInitGuildBuildings = function(self)
	self._BuildingList = {}
	local allTid = CElementData.GetAllTid("GuildBuildLevel")
	for i, v in ipairs(allTid) do
		local guildBuild = CElementData.GetTemplate("GuildBuildLevel", v)
		if guildBuild.BuildLevel == 1 then
			local buildType = guildBuild.BuildType
			local building = CGuildBuilding.new()
			building._Lock = true
			building._BuildingType = buildType
			building._BuildingLevel = 1
			building._BuildingName = self:GetBuildingNameByType(buildType)
			building._IsMaxLevel = false
			building._BuildingModuleID = v
			building._GuildLevel = guildBuild.GuildLevel

			self._BuildingList[buildType] = building
		end
	end
end

-- 根据建筑类型获取建筑描述
def.method("number", "=>", "string").GetBuildingNameByType = function(self, buildingType)
	local name = ""
	if buildingType == 0 then
		name = StringTable.Get(838)
	elseif buildingType == 1 then
		name = StringTable.Get(839)
	elseif buildingType == 2 then
		name = StringTable.Get(840)
	elseif buildingType == 3 then
		name = StringTable.Get(841)
	elseif buildingType == 4 then
		name = StringTable.Get(842)
	elseif buildingType == 5 then
		name = StringTable.Get(843)
	else
		warn("new buildingType----", buildingType)
	end
	return name
end

--重置公会
def.method().ResetGuild = function(self)
	self._GuildID = 0
	self._GuildName = ""
	self._GuildState = 0
	self._LeaderName = ""
	self._LeaderLevel = 0
	self._LeaderID = 0
	self._MemberNum = 0
	self._MaxMemberNum = 0
	self._GuildIconInfo:ResetGuildIconInfo()
	self._GuildLevel = 0
	self._AddLimit:ResetGuildLimit()
	self._CreateTime = 0
	self._Announce = ""
	self._Fund = 0
	self._Energy = 0
	self._Exp = 0
	self._MemberList = {}
	self._FortressList = {}
	self._MemberID = {}
	self._OnlineMemberID = {}
	self._RewardPoints = 0
	self._GuildLiveness = 0
	self._LivenessRank = 0
	self._NeedAgree = true
	self._IconList = {}
	self._ViceNum = 0
	self._EliteNum = 0
	self._GuildSkill = {}
	self._LevelUp = false
end

CGuild.Commit()
return CGuild