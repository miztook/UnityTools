local Lplus = require "Lplus"

local CObjectInfo = Lplus.Class("CObjectInfo")
do
	local def = CObjectInfo.define

	def.field("string")._Name = "Object"
	def.field("number")._Level = 0
	def.field("number")._FactionId = 0

	def.field("number")._MaxHp = 0                      -- 生命上限
	def.field("number")._CurrentHp = 0
	def.field("number")._MaxStamina = 0                 -- 耐力上限
	def.field("number")._CurrentStamina = 0
	def.field("number")._CurShield = 0	                -- 护盾值

	def.field("number")._MoveSpeed = 0                  -- 移动速度
	
	def.field("number")._PkMode = 0                     -- PK模式
	def.field("number")._EvilNum = 0                    -- 罪恶值
	def.field("number")._GloryLevel = 0                 -- 荣耀等级

	def.field("number")._CustomImgSet = 0               -- 是否是自定义头像
	def.field("boolean")._IsCustomImgAudit = false      -- 自定义头像是否在审核中。
	def.field("number")._WorldChatCount = 0             -- 世界频道剩余发言次数
	-- def.field("boolean")._CanBeSelect = true
	-- def.field("boolean")._CanBeAttack = true

	--CPlayerInfo, CPlayerMirrorInfo
	def.field("number")._Prof = 0
	def.field("number")._Gender = 0
	def.field("table")._FightProperty = function() return setmetatable({}, {__index=function() return {0,0} end}) end
	def.field("number")._HorseId = 0
	def.field("string")._TitleName = ""
	def.field("number")._ParagonLevel = 0
	def.field("number")._GuildConvoyFlag = 0

	--CHostPlayerInfo
	def.field("number")._Exp = 0
	def.field("number")._ParagonExp = 0
	def.field("number")._Arena3V3Stage = 0              -- 角斗场段位 
    def.field("number")._Arena3V3Star = 0               -- 角斗场星级
	def.field("number")._ArenaJJCScore = 0              -- 竞技场积分
    def.field("number")._EliminateScore = 0             -- 无畏战场积分
	def.field("table")._RoleResources = nil
    --CNPCInfo
    def.field("number")._TID = 0
	def.field("table")._AffixIds = BlankTable

	--Monster 属于哪个玩家的怪
	def.field("string")._OwnerName = ""
	def.field("number")._CreaterId = 0

	def.field("number")._DesignationId = 0				-- 称号ID
	CObjectInfo.Commit()
end

local CPlayerInfo = Lplus.Extend(CObjectInfo, "CPlayerInfo")
do
    local def = CPlayerInfo.define

	--def.field("table")._TitleList = function() return{} end
	--def.field("table")._Achievement = function() return{} end
	--def.field("table")._Reputations = function() return{} end
	--def.field("table")._SuitInfo = function() return {} end --套装信息 --{quality_suit_id品阶套装,star_suit_id炼星套装}

	CPlayerInfo.Commit()
end

local CHostPlayerInfo = Lplus.Extend(CPlayerInfo, "CHostPlayerInfo")
do
    local def = CHostPlayerInfo.define
	def.field("table")._GatherInfos = BlankTable
	CHostPlayerInfo.Commit()
end


local CNPCInfo = Lplus.Extend(CObjectInfo, "CNPCInfo")
do
    local def = CNPCInfo.define
	
	CNPCInfo.Commit()
end

local CPlayerMirrorInfo = Lplus.Extend(CNPCInfo, "CPlayerMirrorInfo")
do
    local def = CPlayerMirrorInfo.define
	
	CPlayerMirrorInfo.Commit()
end

return
{
	CObjectInfo = CObjectInfo,
	CPlayerInfo = CPlayerInfo,
	CHostPlayerInfo = CHostPlayerInfo,
	CNPCInfo = CNPCInfo,
	CPlayerMirrorInfo = CPlayerMirrorInfo,
}
