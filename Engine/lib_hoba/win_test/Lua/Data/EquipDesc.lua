local desc_data = dofile (_G.ConfigsDir.."equip_mask.lua")

local Lplus = require "Lplus"

local EquipDesc = Lplus.Class("EquipDesc")
do
	local def = EquipDesc.define
	
	--[[
		取得物品装备部位，
		参数mask:物品的equip_mask
	]]
	def.static("number","number", "=>", "string").GetDescData = function (id,index)
--~ 		print("GetDescData id",id,"index",index)
		if id == 0 then
			return desc_data.equip_mask[index]
		elseif id == 1 then
			return desc_data.prop_mask[index]
		else 
			return ""
		end
	end
	--[[
		取得附加属性描述
		参数index:索引
		参数value:值
	]]
	def.static("number","number","=>","string").GetAttrDesc = function (index,value)
		local addon = desc_data.addon
		if not addon[index] then
			return ("[type:%d,rand:%d]"):format(index,value)
		end
		local ret
		if addon[index].valueString then
			ret = addon[index].valueString(value)
		else
			local fmt = addon[index].value
			ret = string.format(fmt,value)
		end
		--local fmt = addon[index].value
		local name = addon[index].name
		--local ret = string.format(fmt,value)
		local tmp = string.sub(ret,2)
		tmp = tonumber(tmp)
		local back = ""
		if tmp == nil then
			tmp = string.sub(ret,2,-2)
			tmp = tonumber(tmp)
			back = string.sub(ret,-1)
		end
		if tmp ~= nil then
			ret = string.sub(ret,1,1)..tmp..back
		end
		return name..ret
	end

	def.static("number", "number", "number", "=>","string").GetAttrDescByProf = function (index, value, prof)
		local addon = desc_data.addon
		if not addon[index] then
			warn("can't not GetAttrDescByProf for type:"..index)
			return ("[type:%d,rand:%d]"):format(index, value)
		end
		local fmt = addon[index].value
		local profname = addon[index].profname
		if not profname then
			return EquipDesc.GetAttrDesc(index, value)
		end
		local name = profname[prof]
		local ret = string.format(fmt,value)
		local tmp = string.sub(ret,2)
		tmp = tonumber(tmp)
		local back = ""
		if tmp == nil then
			tmp = string.sub(ret,2,-2)
			tmp = tonumber(tmp)
			back = string.sub(ret,-1)
		end
		if tmp ~= nil then
			ret = string.sub(ret,1,1)..tmp..back
		end
		return name..ret
	end

	def.static("number","=>","string").GetAttrName = function (index)
		local addon = desc_data.addon
		if not addon[index] then 
			warn("can't not GetAttrName for type:"..index)
			return ("[type:%d]"):format(index)
		end
		return addon[index].name
	end

	def.static("number","number","=>","string").GetAttrValue = function (index,value)
		local addon = desc_data.addon
		if not addon[index] then 
			warn("can't not GetAttrValue for type:"..index)
			return "" 
		end
		local ret
		if addon[index].valueString then
			ret = addon[index].valueString(value)
		else
			local fmt = addon[index].value
			ret = string.format(fmt,value)
		end
		--local fmt = addon[index].value
		--local ret = string.format(fmt,value)
		local tmp = string.sub(ret,2)
		tmp = tonumber(tmp)
		local back = ""
		if tmp == nil then
			tmp = string.sub(ret,2,-2)
			tmp = tonumber(tmp)
			back = string.sub(ret,-1)
		end
		if tmp ~= nil then
			ret = string.sub(ret,1,1)..tmp..back
		end	
		return ret
	end

	local orderMap = nil

	def.static("number", "=>", "number").GetAttrOrder = function(attrType)
		if not orderMap then
		local Attribute_Order = desc_data.Attribute_Order
			orderMap = {}
			for k, v in pairs(Attribute_Order) do
				table.insert(orderMap, v, k)
			end
		end
		if not orderMap[attrType] then 
			warn("can't not GetAttrOrder for type:"..attrType)
			return 0
		end
		return orderMap[attrType]
	end
	--[[
		计算战斗力用
	]]
	def.static("number","number","=>","number").GetFightBase = function (index,value)
		local addon = desc_data.addon
		if not addon[index] then
			warn("can't not GetFightBase for type:"..index)
			return 0
		end
		local fight = addon[index].fight
		fight = fight * value
		return fight
	end

	def.static("number","number","number","=>","number").GetFightBaseByProf = function (index,value,prof)
		local addon = desc_data.addon
		if not addon[index] then
			warn("can't not GetFightBase for type:"..index)
			return 0
		end
		local fight = addon[index].mainelementary[prof]
		return fight * value
	end

	--[[
		取得宝石附加属性描述
		参数index:索引
		参数value:值
	]]
	def.static("number","number","=>","string").GetGemAttrDesc = function (index, value)
		local addon = desc_data.addon
		local fmt = addon[index].value
		local name = addon[index].name
		local ret = string.format(fmt,value)
		local tmp = string.sub(ret,2)
		tmp = tonumber(tmp)
		local back = ""
		if tmp == nil then
			tmp = string.sub(ret,2,-2)
			tmp = tonumber(tmp)
			back = string.sub(ret,-1)
		end
		if tmp ~= nil then
			ret = string.sub(ret,1,1)..tmp..back
		end	
		return name..ret
	end
	--[[
		取得显示的颜色
	]]
	def.static("number","=>","string").GetTextColor = function (index)
		local tmp = desc_data.color[index]
		if not tmp then return "[FFFFFF]" end
		return tmp
	end
	
	--[[
		取得显示的品阶名
	]]
	def.static("number","=>","string").GetQualityName = function (index)
		local tmp = desc_data.quality[index]
		if not tmp then return "该装备没有品阶" end
		return tmp
	end

	--[[
		取得显示的前缀名
	]]
	def.static("number","=>","string").GetTextPrefix = function (index)
		local tmp = desc_data.Prefix[index]
		if not tmp then return "" end
		return tmp
	end
	
	--[[
		取得显示的装备等级名
	]]
	def.static("number","=>","string").GetLevelName = function (index)
		local tmp = desc_data.level[index]
		if not tmp then return "该装备没有等级" end
		return tmp
	end
	
	--[[
		取得称号附加属性描述
		参数index:索引
		参数value:值
	]]
	def.static("number", "number", "=>", "string").GetTitleAttrDesc = function (index, value)
		local addon = desc_data.addon
		local fmt = addon[index].value
		local name = addon[index].name
		local ret = string.format(fmt,value)		
		return name..ret
	end

	-- 通用的属性显示函数，GetTitleAttrDesc对于千分数处理有问题
	def.static("number", "number", "=>", "string").GetGenericAttrDesc = function (index, value)
		local addon = desc_data.addon
		local name = addon[index].name
		local ret
		if addon[index].valueString then
			ret = addon[index].valueString(value)
		else
			local fmt = addon[index].value
			ret = string.format(fmt,value)
		end
		return name..ret
	end

	def.static("=>", "table").GetAttributeOrder= function ()
		return desc_data.Attribute_Order
	end
end
return EquipDesc.Commit()
