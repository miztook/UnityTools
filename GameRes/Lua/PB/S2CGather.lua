--
-- S2CGather
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CQuestAutoMan = require"Quest.CQuestAutoMan"

--采集物通知
local function OnS2CGatherSuccess(sender, msg)
	local hp = game._HostPlayer
	if msg.HostID == hp._ID then
		if hp._CurTarget ~= nil and hp._CurTarget._ID == msg.EntityID then
			hp:UpdateTargetInfo(nil, false)
		end

		hp:AddGatherNum(msg.MineTID, 1)
		local mineTemp = CElementData.GetMineTemplate(msg.MineTID)
		if mineTemp ~= nil then
			local ignoreSuccessedSkill = not mineTemp.IsShowGatherSuccessedSkill 
										or hp:IsInCombatState() 
										or CDungeonAutoMan.Instance():IsOn() 
										or CQuestAutoMan.Instance():IsOn()

			if not ignoreSuccessedSkill then
				local SkillDef = require "Skill.SkillDef"
				local succeedSkillId = SkillDef.GatherSuccessedSkills[hp._InfoData._Prof]
				hp:UseSkill(succeedSkillId)    
				hp._SkillHdl:RegisterCallback(false, function(ret)
	    				hp:SetMineGatherId(0)
					end)
			else
				hp:SetMineGatherId(0)
			end
			game._CGuideMan:OnGatherFinish(msg.MineTID)	
		end	
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