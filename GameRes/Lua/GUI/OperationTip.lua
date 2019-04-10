local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"

--[[ 角色升级提示 ]]
local _ShowLvUpTip = function(lv, on_finish)
    local data =
    {
        Type = EnumDef.OperationTipsType.PlayerLevelUp,
        --Icon = _G.CommonAtlasDir .. "Icon/UserTips/Img_NewTipsIcon_LvUp.png",
        Text = tostring(lv),
        Desc = nil,
        Param = lv,
        OnFinish  = on_finish
    }

    game._GUIMan:Open("CPanelOperationTips", data)
end

--[[ 技能解锁提示 ]]
local _ShowGainNewSkillTip = function(skillId, on_finish)
    local iconImgPath = CElementSkill.GetSkillIconFullPath(skillId)
    local text = CElementSkill.GetSkillName(skillId)
    local desc = StringTable.Get(22801)
    local data =
    {
        Type = EnumDef.OperationTipsType.GainNewSkill,
        Icon = iconImgPath,
        Text = text,
        Desc = desc,
        Param = nil,
        OnFinish  = on_finish
    }

    game._GUIMan:Open("CPanelOperationTips", data)
end

--[[ 纹章使用提示 ]]
local _ShowRuneUseTip = function(runeId, on_finish)
    local rune = CElementData.GetTemplate("Rune", runeId)
    local fullPath = _G.CommonAtlasDir.."Icon/" .. rune.RuneIcon .. ".png"

    local data =
    {
        Type = EnumDef.OperationTipsType.RuneUse,
        Icon = fullPath,
        Text = rune.Name,
        Desc = nil,
        Param = nil,
        OnFinish  = on_finish
    }

    game._GUIMan:Open("CPanelOperationTips", data)
end

--[[ 纹章使用提示 ]]
local _ShowFuncUnlockTip = function(funcId, on_finish)
    local funData = CElementData.GetFunTemplate(funcId)
    if funData == nil or not funData.NeedPop or #funData.ConditionData.FunUnlockConditions == 0 then
        if on_finish ~= nil then on_finish() end
        return
    end
    
	-- 默认飞向右上角的位置
    local funBtnName = ""    -- Btn_F1
    if funData.FunType == 1 then
		if funData.AssociatedObject ~= nil then
			funBtnName = funData.AssociatedObject
		else
			warn("找不到对应的飞行目标：",funData.DisplayName)
		end	
	end
	local iconImgPath =  _G.CommonAtlasDir.."Icon/" .. funData.IconPath .. ".png"
    local text = StringTable.Get(19462)..funData.DisplayName
    local desc = StringTable.Get(22802)
	local data =
	    {
	        Type = EnumDef.OperationTipsType.FuncOpen,
	        Icon = iconImgPath,
	        Text = text,
	        Desc = desc,
	        Param = funBtnName,
	        OnFinish  = on_finish
	    }
	game._GUIMan:Open("CPanelOperationTips", data)
end

_G.OperationTip = 
{
	ShowLvUpTip = _ShowLvUpTip,
	ShowGainNewSkillTip = _ShowGainNewSkillTip,
	ShowRuneUseTip = _ShowRuneUseTip,
	ShowFuncUnlockTip = _ShowFuncUnlockTip,
}