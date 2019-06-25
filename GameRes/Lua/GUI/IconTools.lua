-- 通用图标工具
-- 2018/8/16

--[[
(1) ItemIcon
注意事项：
	必须使用 Prefabs/UITemplates/ItemIconNew
	不能修改 UITemplate 组件
	用不到的子节点需要删除
	额外的显示，不要放在进子节点，可以加在 ItemIconNew 同一级或上一级
使用示例：
	1、初始化并同时设置多个tag（不设置的默认禁用）
		IconTools.InitItemIconNew(frame_item_icon, itemId,
		{
			[EItemIconTag.Bind] = true,
			[EItemIconTag.Number] = 11,
			[EItemIconTag.StrengthLv] = 0,
			[EItemIconTag.Refine] = 15,
			[EItemIconTag.New] = false,
			[EItemIconTag.Equip] = true,
			[EItemIconTag.ArrowUp] = true,
			[EItemIconTag.CanUse] = false,
			[EItemIconTag.Enchant] = false,
			[EItemIconTag.ArrowDown] = false,
			[EItemIconTag.EquipLv] = 20,
			[EItemIconTag.Probability] = false,
			[EItemIconTag.Legend] = "陨石术",
			[EItemIconTag.Time] = false,
			[EItemIconTag.Grade] = 1,
			[EItemIconTag.Activated] = false,
		},
		EItemLimitCheck.AllCheck)
	2、初始化货币图标并设置数量
		IconTools.InitTokenMoneyIcon(frame_item_icon, moenyId, moenyNum)
	3、同时设置多个Tag，在 InitItemIcon 后调用
		IconTools.SetTags(frame_item_icon, 
		{
			[EItemIconTag.Number] = 0,
		})
	4、单独设置限制Tag
		IconTools.SetLimit(frame_item_icon, itemId, EItemLimitCheck.AllCheck)
	5、设置多个FrameIconTag（没有默认状态，显隐完全自己控制）
		local setting =
		{
			[EFrameIconTag.Empty] = false,
			[EFrameIconTag.EmptyEquip] = false,
			[EFrameIconTag.Add] = false,
			[EFrameIconTag.ItemIcon] = false,
			[EFrameIconTag.Get] = false,
			[EFrameIconTag.Check] = false,
			[EFrameIconTag.RedPoint] = false,
			[EFrameIconTag.Select] = false,
			[EFrameIconTag.Remove] = false,
		}
		IconTools.SetFrameIconTags(frame_item_icon, setting)

(2) MaterialIcon
注意事项：
	必须使用 Prefabs/UITemplates/MaterialIcon
	不能修改 UITemplate 组件
	额外的显示，不要放在进子节点，可以加在 MaterialIcon 同一级或上一级
使用示例：
	1、初始化并设置数量
		IconTools.InitMaterialIconNew(frame_material_icon, itemId, needNum)
	2、更新数量
		IconTools.SetMaterialNum(frame_material_icon, itemId, needNum)
--]]
---------------------------------------------------------------------------------

-- 物品图标的Tag功能枚举，对应的参数有类型检查
-- boolean 类型: true显示，false隐藏
-- number  类型: 根据功能逻辑设置显隐规则
-- string  类型: 非nil而且非空显示，否则隐藏
local ENUM_ITEM_ICON_TAG =
{
	Bind 		= 1,		-- 绑定 					boolean
	Number 		= 2,		-- 数量 					number
	StrengthLv 	= 3,		-- 强化等级 				number
	Refine 		= 4,		-- 精炼等级 				number
	New 		= 5,		-- 新物品 					boolean
	Equip 		= 6,		-- 已装备 					boolean
	ArrowUp		= 7,		-- 战力提升箭头 			boolean
	CanUse		= 8,		-- 可使用 					boolean
	Enchant 	= 9, 		-- 附魔 					boolean
	ArrowDown 	= 10, 		-- 战力下降箭头 			boolean
	EquipLv 	= 11, 		-- 装备等级 				number
	Probability = 12, 		-- 概率获得 				boolean
	Legend 		= 13, 		-- 传奇属性 				string
	Time 		= 14, 		-- 限时 					boolean
	Grade 		= 15, 		-- 评分 					number
	Activated 	= 16, 		-- 已激活 					boolean
}

-- 物品限制检查类型枚举
local ENUM_ITEM_LIMIT_CHECK_TYPE =
{
	Prof = 1,			-- 检查职业限制
	Level = 2,			-- 检查等级限制
	AllCheck = 99,		-- 依次检查所有限制
}

local ENUM_FRAME_ICON_TAG =
{
	Empty 		= 1,		-- 空槽 					boolean
	EmptyEquip 	= 2,		-- 装备空槽 				number
	Add 		= 3,		-- 添加物品 				boolean
	ItemIcon 	= 4,		-- 物品图标 				boolean
	Get 		= 5,		-- 已获取 				boolean
	Check 		= 6,		-- 已勾选 				boolean
	RedPoint 	= 7,		-- 红点 					boolean
	Select 		= 8,		-- 已选择 				boolean
	Remove 		= 9,		-- 移除 					boolean
}

local function _Log(logType, tag, isItemIcon, param1, param2)
	local tagName = ""
	local enum = isItemIcon and ENUM_ITEM_ICON_TAG or ENUM_FRAME_ICON_TAG
	for k, v in pairs(enum) do
		if tag == v then
			tagName = k
			break
		end
	end

	local prefix = isItemIcon and "[ItemIcon]" or "[FrameIcon]"
	if logType == 1 then
		warn(prefix .. tagName .. " tag param expect: " .. param1 .. ", got: " .. param2, debug.traceback())
	elseif logType == 2 then
		warn(prefix .. tagName .. " tag set failed, GameObject got nil", debug.traceback())
	end
end

-- 初始化图标，两种图标都需要
local function _InitItemIcon(obj, itemId)
	local CElementData = require "Data.CElementData"
	local itemTemplate = CElementData.GetItemTemplate(itemId)
	if itemTemplate == nil then return end

	local img_icon = GUITools.GetChild(obj, 3)
	if not IsNil(img_icon) then
		GUITools.SetItemIcon(img_icon, itemTemplate.IconAtlasPath)
	end
	local img_quality_bg = GUITools.GetChild(obj, 1)
	if not IsNil(img_quality_bg) then
		GUITools.SetGroupImg(img_quality_bg, itemTemplate.InitQuality)
	end
	local img_quality = GUITools.GetChild(obj, 2)
	if not IsNil(img_quality) then
		GUITools.SetGroupImg(img_quality, itemTemplate.InitQuality)
	end
end

local function _InitTokenMoneyIcon(obj, moenyId)
	local CElementData = require "Data.CElementData"
	local moneyTemplate = CElementData.GetMoneyTemplate(moenyId)
	if moneyTemplate == nil then return end

	local img_icon = GUITools.GetChild(obj, 3)
	if not IsNil(img_icon) then
		GUITools.SetItemIcon(img_icon, moneyTemplate.IconPath)
	end
	local img_quality_bg = GUITools.GetChild(obj, 1)
	if not IsNil(img_quality_bg) then
		GUITools.SetGroupImg(img_quality_bg, moneyTemplate.Quality)
	end
	local img_quality = GUITools.GetChild(obj, 2)
	if not IsNil(img_quality) then
		GUITools.SetGroupImg(img_quality, moneyTemplate.Quality)
	end
end

-- 检查Tag对应的参数类型
local function _CheckItemIconParam(tag, param)
	local pType = type(param)
	local destType = ""
	if tag == ENUM_ITEM_ICON_TAG.Bind then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.Number then
		destType = "number"
	elseif tag == ENUM_ITEM_ICON_TAG.StrengthLv then
		destType = "number"
	elseif tag == ENUM_ITEM_ICON_TAG.Refine then
		destType = "number"
	elseif tag == ENUM_ITEM_ICON_TAG.New then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.Equip then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowUp then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.CanUse then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.Enchant then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowDown then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.EquipLv then
		destType = "number"
	elseif tag == ENUM_ITEM_ICON_TAG.Probability then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.Legend then
		destType = "string"
	elseif tag == ENUM_ITEM_ICON_TAG.Time then
		destType = "boolean"
	elseif tag == ENUM_ITEM_ICON_TAG.Grade then
		destType = "number"
	elseif tag == ENUM_ITEM_ICON_TAG.Activated then
		destType = "boolean"
	else
		warn("Unknown ItemIcon tag:", tag, debug.traceback())
		return false
	end
	if pType ~= destType then
		_Log(1, tag, true, destType, pType)
		return false
	end
	return true
end

local SELF_INDEX = 99
local function _GetItemIconTagIndex(tag)
	local index, root_index = -1, -1
	if tag == ENUM_ITEM_ICON_TAG.Bind then
		index = 4
		root_index = 4
	elseif tag == ENUM_ITEM_ICON_TAG.Number then
		index = 5
		root_index = 5
	elseif tag == ENUM_ITEM_ICON_TAG.StrengthLv then
		index = 7
		root_index = 7
	elseif tag == ENUM_ITEM_ICON_TAG.Refine then
		index = 8
		root_index = 9
	elseif tag == ENUM_ITEM_ICON_TAG.New then
		index = 10
		root_index = 10
	elseif tag == ENUM_ITEM_ICON_TAG.Equip then
		index = 11
		root_index = 11
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowUp then
		index = 12
		root_index = 12
	elseif tag == ENUM_ITEM_ICON_TAG.CanUse then
		index = SELF_INDEX
		root_index = SELF_INDEX
	elseif tag == ENUM_ITEM_ICON_TAG.Enchant then
		index = 17
		root_index = 17
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowDown then
		index = 13
		root_index = 13
	elseif tag == ENUM_ITEM_ICON_TAG.EquipLv then
		index = 18
		root_index = 18
	elseif tag == ENUM_ITEM_ICON_TAG.Probability then
		index = 19
		root_index = 19
	elseif tag == ENUM_ITEM_ICON_TAG.Legend then
		index = 22
		root_index = 21
	elseif tag == ENUM_ITEM_ICON_TAG.Time then
		index = 23
		root_index = 23
	elseif tag == ENUM_ITEM_ICON_TAG.Grade then
		index = 25
		root_index = 24
	elseif tag == ENUM_ITEM_ICON_TAG.Activated then
		index = 26
		root_index = 26
	end
	if index < 0 or root_index < 0 then
		warn("GetItemIconTagIndex failed, Unknown ItemIcon tag:", tag, debug.traceback())
	end
	return index, root_index
end

local function _SetUpBoolean(obj, enable)
	GUITools.SetUIActive(obj, enable)
end

local function _SetUpItemLimit(obj, itemId, limitType)
	local frame_limit = GUITools.GetChild(obj, 14)
	local lab_limit_level = GUITools.GetChild(obj, 15)
	local lab_limit_prof = GUITools.GetChild(obj, 16)
	if IsNil(frame_limit) or IsNil(lab_limit_level) or IsNil(lab_limit_prof) then
		warn("SetLimit failed, ItemIcon GameObject not using the sample", debug.traceback())
		return
	end

	local limitStr = "Unknown Limit"
	local bShow = true
	local showType = 0

	local CElementData = require "Data.CElementData"
	local itemTemplate = CElementData.GetItemTemplate(itemId)
	if itemTemplate ~= nil then
		-- 检查职业限制
		local function checkProfLimit()
			local str = "Unknown Limit"
			local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
			local ret = profMask ~= bit.band(itemTemplate.ProfessionLimitMask, profMask)
			if ret then
				local limitProf = -1
				if itemTemplate.ProfessionLimitMask == 1 then
					limitProf = EnumDef.Profession.Warrior
				elseif itemTemplate.ProfessionLimitMask == 2 then
					limitProf = EnumDef.Profession.Aileen
				elseif itemTemplate.ProfessionLimitMask == 4 then
					limitProf = EnumDef.Profession.Assassin
				elseif itemTemplate.ProfessionLimitMask == 8 then
					limitProf = EnumDef.Profession.Archer
				elseif itemTemplate.ProfessionLimitMask == 16 then
					limitProf = EnumDef.Profession.Lancer
				else
					warn("Profession limit more than one, wrong itemId:" .. itemId, debug.traceback())
				end
				if limitProf ~= -1 then
					str = StringTable.Get(10300 + limitProf - 1)
				end
			end
			return ret, str
		end

		-- 检查等级限制
		local function checkLevelLimit()
			local str = "Unknown Limit"
			local level = game._HostPlayer._InfoData._Level
			local ret = level < itemTemplate.MinLevelLimit
			if ret then
				str = string.format(StringTable.Get(10714), itemTemplate.MinLevelLimit)
			else
				ret = level > itemTemplate.MaxLevelLimit
				if ret then
					str = StringTable.Get(314)
				end
			end
			return ret, str
		end

		if limitType == ENUM_ITEM_LIMIT_CHECK_TYPE.Prof then
			-- 只检查职业限制
			bShow, limitStr = checkProfLimit()
			showType = 1
		elseif limitType == ENUM_ITEM_LIMIT_CHECK_TYPE.Level then
			-- 只检查等级限制
			bShow, limitStr = checkLevelLimit()
			showType = 2
		elseif limitType == ENUM_ITEM_LIMIT_CHECK_TYPE.AllCheck then
			-- 先检查职业限制，在检查等级限制
			bShow, limitStr = checkProfLimit()
			showType = 1
			if not bShow then
				bShow, limitStr = checkLevelLimit()
				showType = 2
			end
		else
			warn("Invalid limit type:", limitType, debug.traceback())
		end
	end

	GUITools.SetUIActive(frame_limit, bShow)
	if bShow then
		GUITools.SetUIActive(lab_limit_prof, showType == 1)
		GUITools.SetUIActive(lab_limit_level, showType ~= 1)
		if showType == 1 then
			GUI.SetText(lab_limit_prof, limitStr)
		else
			GUI.SetText(lab_limit_level, limitStr)
		end
	end
end

local function _GetItemIconTagGameObject(obj, tag, isComponent)
	local tagObj, rootObj = nil , nil
	if not IsNil(obj) then
		local index, root_index = _GetItemIconTagIndex(tag)
		if index >= 0 then
			if index == SELF_INDEX then
				if isComponent then
					tagObj = obj.gameObject
				else
					tagObj = obj
				end
			else
				if isComponent then
					tagObj = obj:GetControl(index)
				else
					tagObj = GUITools.GetChild(obj, index)
				end
			end
		end
		if root_index >= 0 then
			if root_index == index then
				rootObj = tagObj
			else
				if root_index == SELF_INDEX then
					if isComponent then
						rootObj = obj.gameObject
					else
						rootObj = obj
					end
				else
					if isComponent then
						rootObj = obj:GetControl(root_index)
					else
						rootObj = GUITools.GetChild(obj, root_index)
					end
				end
			end
		end
	end
	return tagObj, rootObj
end

local function _SetItemIconTagGameObject(tagObj, rootObj, tag, param)
	if not _CheckItemIconParam(tag, param) then return end

	if IsNil(tagObj) or IsNil(rootObj) then
		_Log(2, tag, true)
		return
	end

	if tag == ENUM_ITEM_ICON_TAG.Bind then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_ITEM_ICON_TAG.Number then
		local bShow = param > 1 -- 数量大于1才显示
		GUITools.SetUIActive(tagObj, bShow)
		if bShow then
			GUI.SetText(tagObj, GUITools.FormatNumber(param))
		end
	elseif tag == ENUM_ITEM_ICON_TAG.StrengthLv then
		local bShow = param > 0
		tagObj:SetActive(bShow)
		if bShow then
			GUI.SetText(tagObj, "+" .. param)
		end
	elseif tag == ENUM_ITEM_ICON_TAG.Refine then
		local bShow = param > 0
		rootObj:SetActive(bShow)
		if bShow then
			GUI.SetText(tagObj, tostring(param))
		end
	elseif tag == ENUM_ITEM_ICON_TAG.New then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_ITEM_ICON_TAG.Equip then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowUp then
		tagObj:SetActive(param)
	elseif tag == ENUM_ITEM_ICON_TAG.CanUse then
		-- 特殊处理
		local alpha = param and 1 or 0.5
		GameUtil.SetCanvasGroupAlpha(tagObj, alpha)
	elseif tag == ENUM_ITEM_ICON_TAG.Enchant then
		tagObj:SetActive(param)
	elseif tag == ENUM_ITEM_ICON_TAG.ArrowDown then
		tagObj:SetActive(param)
	elseif tag == ENUM_ITEM_ICON_TAG.EquipLv then
		GUITools.SetUIActive(tagObj, param > 0)
		if param > 0 then
			GUI.SetText(tagObj, "<color=#F5B755>Lv.</color>" .. param)
		end
	elseif tag == ENUM_ITEM_ICON_TAG.Probability then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_ITEM_ICON_TAG.Legend then
		local bShow = not IsNilOrEmptyString(param)
		GUITools.SetUIActive(rootObj, bShow)
		if bShow then
			GUI.SetText(tagObj, param)
		end
	elseif tag == ENUM_ITEM_ICON_TAG.Time then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_ITEM_ICON_TAG.Grade then
		local bShow = param >= 0
		rootObj:SetActive(bShow)
		if bShow then
			GUITools.SetGroupImg(tagObj, param)
		end
	elseif tag == ENUM_ITEM_ICON_TAG.Activated then
		_SetUpBoolean(tagObj, param)
	end
end

-- 数量不足时，图标置灰，隐藏品质框，显示加号
-- 所需数量大于1时，显示所需数量
local function _SetMaterialNum(obj, itemId, needNum)
	local uiTemplate = obj:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then
		warn("MaterialIcon GameObject not using the sample", debug.traceback())
		return
	end

	local packageNum = game._HostPlayer._Package._NormalPack:GetItemCount(itemId)
	local isMaterialEnough = needNum <= packageNum -- 材料是否足够

	local lab_need = uiTemplate:GetControl(4)
	if not IsNil(lab_need) then
		local packageNumStr = GUITools.FormatNumber(packageNum)
		if not isMaterialEnough then
			packageNumStr = RichTextTools.GetUnavailableColorText(packageNumStr)
		else
			packageNumStr = RichTextTools.GetAvailableColorText(packageNumStr)
		end
		local numStr = packageNumStr
		if needNum >= 1 then
			numStr = packageNumStr .. "/" .. GUITools.FormatNumber(needNum)
		end
		GUI.SetText(lab_need, numStr)
	end

	-- local img_icon = uiTemplate:GetControl(3)
	-- if not IsNil(img_icon) then
	-- 	GameUtil.MakeImageGray(img_icon, not isMaterialEnough)
	-- end

	local img_add = uiTemplate:GetControl(5)
	if not IsNil(img_add) then
	 	-- GUITools.SetUIActive(img_add, not isMaterialEnough)
	 	GUITools.SetUIActive(img_add, false)
	end

	-- local img_quality_bg = uiTemplate:GetControl(1)
	-- if not IsNil(img_quality_bg) then
	-- 	GameUtil.MakeImageGray(img_quality_bg, not isMaterialEnough)
	-- end
	-- local img_quality = uiTemplate:GetControl(2)
	-- if not IsNil(img_quality) then
	-- 	GameUtil.MakeImageGray(img_quality, not isMaterialEnough)
	-- end
end

local function _CheckFrameIconParam(tag, param)
	local pType = type(param)
	local destType = ""
	if tag == ENUM_FRAME_ICON_TAG.Empty then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.EmptyEquip then
		destType = "number"
	elseif tag == ENUM_FRAME_ICON_TAG.Add then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.ItemIcon then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.Get then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.Check then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.RedPoint then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.Select then
		destType = "boolean"
	elseif tag == ENUM_FRAME_ICON_TAG.Remove then
		destType = "boolean"
	else
		warn("Unknown FrameIcon tag:", tag, debug.traceback())
		return false
	end
	if pType ~= destType then
		_Log(1, tag, false, destType, pType)
		return false
	end
	return true
end

local function _GetFrameIconTagIndex(tag)
	local index = -1
	if tag == ENUM_FRAME_ICON_TAG.Empty then
		index = 0
	elseif tag == ENUM_FRAME_ICON_TAG.EmptyEquip then
		index = 1
	elseif tag == ENUM_FRAME_ICON_TAG.Add then
		index = 2
	elseif tag == ENUM_FRAME_ICON_TAG.ItemIcon then
		index = 3
	elseif tag == ENUM_FRAME_ICON_TAG.Get then
		index = 4
	elseif tag == ENUM_FRAME_ICON_TAG.Check then
		index = 5
	elseif tag == ENUM_FRAME_ICON_TAG.RedPoint then
		index = 6
	elseif tag == ENUM_FRAME_ICON_TAG.Select then
		index = 7
	elseif tag == ENUM_FRAME_ICON_TAG.Remove then
		index = 8
	end
	if index < 0 then
		warn("GetFrameIconTagIndex failed, Unknown ItemIcon tag:", tag, debug.traceback())
	end
	return index
end

local function _GetFrameIconTagGameObject(obj, tag)
	local tagObj = nil
	if not IsNil(obj) then
		local index = _GetFrameIconTagIndex(tag)
		if index >= 0 then
			tagObj = GUITools.GetChild(obj, index)
		end
	end
	return tagObj
end

local function _SetFrameIconTagGameObject(tagObj, tag, param)
	if not _CheckFrameIconParam(tag, param) then return end

	if IsNil(tagObj) then
		_Log(2, tag, false)
		return
	end

	if tag == ENUM_FRAME_ICON_TAG.Empty then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.EmptyEquip then
		GUITools.SetUIActive(tagObj, param >= 0)
		if param >= 0 then
			local img_empty_equip = GUITools.GetChild(tagObj, 1)
			if not IsNil(img_empty_equip) then
				GUITools.SetGroupImg(img_empty_equip, param)
			end
		end
	elseif tag == ENUM_FRAME_ICON_TAG.Add then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.ItemIcon then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.Get then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.Check then
		GUITools.SetUIActive(tagObj, param)
		if param then
			local do_tween_player = tagObj:GetComponent(ClassType.DOTweenPlayer)
			if do_tween_player ~= nil then
				do_tween_player:Restart("Check")
			end
		end
	elseif tag == ENUM_FRAME_ICON_TAG.RedPoint then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.Select then
		_SetUpBoolean(tagObj, param)
	elseif tag == ENUM_FRAME_ICON_TAG.Remove then
		_SetUpBoolean(tagObj, param)
	end
end
------------------------------------------------------------------------------

-- （新版）初始化道具图标并设置多个Tag功能
-- @param setting
--        key   EItemIconTag
--        value 对应类型参数
--        例如 { [EItemIconTag.Bind] = false, ... }
local function initItemIconNew(obj, itemId, setting, limitType)
	if IsNil(obj) or itemId < 0 then return end

	local item_icon_index = _GetFrameIconTagIndex(ENUM_FRAME_ICON_TAG.ItemIcon)
	local itemObj = GUITools.GetChild(obj, item_icon_index)
	if IsNil(itemObj) then
		warn("InitItemIcon failed, Frame_ItemIcon got nil", debug.traceback())
		return
	end

	local uiTemplate = itemObj:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then
		warn("InitItemIcon Frame_ItemIcon GameObject not using the sample", debug.traceback())
		return
	end

	_InitItemIcon(itemObj, itemId)
	local temp = {} -- 记录设置过的Tag
	if type(setting) == "table" then
		for tag, param in pairs(setting) do
			local tagObj, rootObj = _GetItemIconTagGameObject(uiTemplate, tag, true)
			_SetItemIconTagGameObject(tagObj, rootObj, tag, param)

			temp[tag] = true
		end
	end

	-- 隐藏其他没有设置的TAG
	for _, tag in pairs(ENUM_ITEM_ICON_TAG) do
		if temp[tag] == nil and tag ~= ENUM_ITEM_ICON_TAG.CanUse then
			local _, rootObj = _GetItemIconTagGameObject(uiTemplate, tag, true)
			if not IsNil(rootObj) then
				if tag == ENUM_ITEM_ICON_TAG.StrengthLv or
				   tag == ENUM_ITEM_ICON_TAG.Refine or
				   tag == ENUM_ITEM_ICON_TAG.ArrowUp or
				   tag == ENUM_ITEM_ICON_TAG.ArrowDown or
				   tag == ENUM_ITEM_ICON_TAG.Enchant or
				   tag == ENUM_ITEM_ICON_TAG.Grade then
					rootObj:SetActive(false)
				else
					GUITools.SetUIActive(rootObj, false)
				end
			end
		end
	end

	if type(limitType) == "number" and limitType > 0 then
		_SetUpItemLimit(itemObj, itemId, limitType)
	else
		-- 隐藏限制
		local frame_limit = uiTemplate:GetControl(14)
		if not IsNil(frame_limit) then
			GUITools.SetUIActive(frame_limit, false)
		end
	end
end

-- 初始化货币图标并设置数量
local function initTokenMoneyIcon(obj, moenyId, num)
	if IsNil(obj) or moenyId < 0 then return end

	local item_icon_index = _GetFrameIconTagIndex(ENUM_FRAME_ICON_TAG.ItemIcon)
	local itemObj = GUITools.GetChild(obj, item_icon_index)
	if IsNil(itemObj) then
		warn("InitTokenMoneyIcon failed, Frame_ItemIcon got nil", debug.traceback())
		return
	end

	local uiTemplate = itemObj:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then
		warn("InitTokenMoneyIcon Frame_ItemIcon GameObject not using the sample", debug.traceback())
		return
	end

	_InitTokenMoneyIcon(itemObj, moenyId)
	local isHideNum = true
	if type(num) == "number" and num > 1 then
		isHideNum = false
		local num_index = _GetItemIconTagIndex(ENUM_ITEM_ICON_TAG.Number)
		local lab_num = GUITools.GetChild(itemObj, num_index)
		if not IsNil(lab_num) then
			GUITools.SetUIActive(lab_num, true)
			GUI.SetText(lab_num, GUITools.FormatMoney(num))
		end
	end
	-- 隐藏其他的TAG
	for _, tag in pairs(ENUM_ITEM_ICON_TAG) do
		if (tag ~= ENUM_ITEM_ICON_TAG.Number or isHideNum) and
			tag ~= ENUM_ITEM_ICON_TAG.CanUse then
			local _, rootObj = _GetItemIconTagGameObject(uiTemplate, tag, true)
			if not IsNil(rootObj) then
				if tag == ENUM_ITEM_ICON_TAG.StrengthLv or
				   tag == ENUM_ITEM_ICON_TAG.Refine or
				   tag == ENUM_ITEM_ICON_TAG.ArrowUp or
				   tag == ENUM_ITEM_ICON_TAG.ArrowDown or
				   tag == ENUM_ITEM_ICON_TAG.Enchant or
				   tag == ENUM_ITEM_ICON_TAG.Grade then
					rootObj:SetActive(false)
				else
					GUITools.SetUIActive(rootObj, false)
				end
			end
		end
	end
	-- 隐藏限制
	local frame_limit = uiTemplate:GetControl(14)
	if not IsNil(frame_limit) then
		GUITools.SetUIActive(frame_limit, false)
	end
end

--[[
-- 设置道具图标的单个Tag功能
-- @param tag    EItemIconTag
-- @param param  对应类型参数
local function setSingleTag(obj, tag, param)
	if IsNil(obj) then return end

	local tagObj, rootObj = _GetItemIconTagGameObject(obj, tag, false)
	_SetItemIconTagGameObject(tagObj, rootObj, tag, param)
end
--]]

-- 设置道具图标的多个Tag功能
-- @param setting
--        key   EItemIconTag
--        value 对应类型参数
--        例如 { [EItemIconTag.Bind] = false, ... }
local function setTags(obj, setting)
	if IsNil(obj) then return end
	
	local item_icon_index = _GetFrameIconTagIndex(ENUM_FRAME_ICON_TAG.ItemIcon)
	local itemObj = GUITools.GetChild(obj, item_icon_index)
	if IsNil(itemObj) then
		warn("SetTags failed, Frame_ItemIcon got nil", debug.traceback())
		return
	end

	local uiTemplate = itemObj:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then
		warn("SetTags Frame_ItemIcon not using the sample", debug.traceback())
		return
	end

	if type(setting) == "table" then
		for tag, param in pairs(setting) do
			local tagObj, rootObj = _GetItemIconTagGameObject(uiTemplate, tag, true)
			_SetItemIconTagGameObject(tagObj, rootObj, tag, param)
		end
	end
end

-- 更新道具图标的限制状态
-- @param limitType EItemLimitCheck
local function setLimit(obj, itemId, limitType)
	if IsNil(obj) or itemId < 0 then return end

	_SetUpItemLimit(obj, itemId, limitType)
end

-- （新版）更新道具图标的限制状态
-- @param limitType EItemLimitCheck
local function setLimitNew(obj, itemId, limitType)
	if IsNil(obj) or itemId < 0 then return end

	local item_icon_index = _GetFrameIconTagIndex(ENUM_FRAME_ICON_TAG.ItemIcon)
	local itemObj = GUITools.GetChild(obj, item_icon_index)
	if IsNil(itemObj) then
		warn("SetLimitNew failed, Frame_ItemIcon got nil", debug.traceback())
		return
	end
	_SetUpItemLimit(itemObj, itemId, limitType)
end

-- （新版）初始化材料图标
local function initMaterialIconNew(obj, itemId, needNum)
	if IsNil(obj) or itemId <= 0 then return end

	_InitItemIcon(obj, itemId)
	_SetMaterialNum(obj, itemId, needNum)
end

-- 设置材料图标数量
local function setMaterialNum(obj, itemId, needNum)
	if IsNil(obj) or itemId <= 0 then return end

	_SetMaterialNum(obj, itemId, needNum)
end

-- 设置图标的多个Tag功能
-- @param setting
--        key   EFrameIconTag
--        value 对应类型参数
--        例如 { [EFrameIconTag.Get] = false, ... }
local function setFrameIconTags(obj, setting)
	if IsNil(obj) then return end

	if type(setting) == "table" then
		for tag, param in pairs(setting) do
			local tagObj = _GetFrameIconTagGameObject(obj, tag)
			_SetFrameIconTagGameObject(tagObj, tag, param)
		end
	end
end

_G.IconTools =
{
	InitItemIconNew = initItemIconNew,					-- （新版）初始化道具图标并设置多个Tag功能
	InitTokenMoneyIcon = initTokenMoneyIcon,			-- 初始化货币图标并设置数量
	-- SetSingleTag = setSingleTag,						-- 设置道具图标的单个Tag功能（废弃，请使用多个Tag设置）
	SetTags = setTags,									-- 设置道具图标的多个Tag功能
	SetLimit = setLimit,								-- 更新道具图标的限制状态
	SetLimitNew = setLimitNew,							-- （新版）更新道具图标的限制状态
	InitMaterialIconNew = initMaterialIconNew,				-- （新版）初始化材料图标
	SetMaterialNum = setMaterialNum,					-- 设置材料图标数量
	SetFrameIconTags = setFrameIconTags,				-- 设置图标的多个Tag功能
}
_G.EItemIconTag = ENUM_ITEM_ICON_TAG					-- 物品图标的Tag功能枚举
_G.EItemLimitCheck = ENUM_ITEM_LIMIT_CHECK_TYPE 		-- 物品限制检查类型枚举
_G.EFrameIconTag = ENUM_FRAME_ICON_TAG 					-- 图标的Tag功能枚举