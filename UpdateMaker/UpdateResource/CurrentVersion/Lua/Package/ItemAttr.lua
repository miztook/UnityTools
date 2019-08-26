local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local ItemAttr = Lplus.Class("ItemAttr")
local def = ItemAttr.define


def.static("number","=>","table").GetSuitAttrInfo = function(suitId)
        	
    local table = {}
		--获得套装属性 结构
		local suitElement = CElementData.GetSuitTemplate(suitId)

		for i,v in ipairs(suitElement.SuitProps) do
			local fightElement = CElementData.GetAttachedPropertyTemplate( v.PropID )
			table[i] = {}
			table[i].value = v.PropValue
			if v.PropType == EnumDef.ESuitPropType.EPropType_Value then
				table[i].des = string.format(v.Describe, fightElement.TextDisplayName, v.PropValue)
			elseif v.PropType == EnumDef.ESuitPropType.EPropType_Percent then
				table[i].des = string.format(v.Describe, fightElement.TextDisplayName, v.PropValue*100)
			elseif v.PropType == EnumDef.ESuitPropType.EPropType_PassiveID then
			        --获取被动技能   
		        local talentTemplate = CElementData.GetTalentTemplate( v.PropValue )
		        table[i].des = talentTemplate.TalentDescribtion
			end
		end
    return table
end



ItemAttr.Commit()
return ItemAttr