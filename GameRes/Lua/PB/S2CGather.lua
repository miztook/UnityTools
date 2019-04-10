--
-- S2CGather
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"

--采集物通知
local function OnS2CGatherSuccess(sender, msg)
	local hp = game._HostPlayer
	if msg.HostID == hp._ID then
		hp:AddGatherNum(msg.MineTID,1)
		local mine_tmp = CElementData.GetMineTemplate(msg.MineTID)
		if mine_tmp and 
		   mine_tmp.IsShowGatherSuccessedSkill and
		   not hp:IsInCombatState() then
		   
			-- 技能打断影响 副本目标和服务器消息的配合
			if not CDungeonAutoMan.Instance():IsOn()  then
				local SkillDef = require "Skill.SkillDef"
				local succeedSkillId = SkillDef.GatherSuccessedSkills[hp._InfoData._Prof]
				hp:UseSkill(succeedSkillId)    
				hp._SkillHdl:RegisterCallback(false, function(ret)
        				hp:SetMineGatherId(0)
    				end)
			end
		-- 不用欢呼
		elseif mine_tmp then
			hp:SetMineGatherId(0)
		end
		game._CGuideMan:OnGatherFinish(msg.MineTID)		
	end

	local function UpdateFlag(mine)
		if mine._ID == msg.EntityID then
			mine:DoDisappearEffect(EnumDef.SightUpdateType.GatherDestory)
			mine:SetGatherFlag(msg.GatherFlag)
			mine:UpdateCanGatherGfx()
		end
	end
	game._CurWorld._MineObjectMan:ForEach(UpdateFlag)
end
PBHelper.AddHandler("S2CGatherSuccess", OnS2CGatherSuccess)