
-- tip 弹出类型以及位置
_G.TipsPopFrom = 
{
    ROLE_PANEL = 1,        --自己的角色面板
    BACK_PACK_PANEL  = 2,  --自己的背包界面
    OTHER_PANEL = 3,		-- 虚拟tip信息
    OTHER_PALYER = 4,      --查看其它角色界面
    Equip_Process = 5,     -- 装备加工背包界面
    CHAT_PANEL    = 6,	   -- 聊天界面
    WithoutButton = 7      -- 没有按钮但是显示详细信息


}
-- tip的适配方式更改该枚举值无效
_G.TipPosition = 
{
	FIX_POSITION = 1,
	DEFAULT_POSITION = 2,
}

local gCurTipPanel = nil
local TargetObj = nil 
local tipPosition = 0
local ItemObj = nil 
--背包名字
local PackName = 
{
	PACKBACK_ITEM = 1,
	PACKBACK_EQUIP = 2,
	PACKBACK_ITEM_WITH_CERTAIN_FUNCS = 3,
	OTHER_PANEL = 4,
	CHAT_PANEL = 5,
    CHARM_ITEM = 6,
}
--tips位置


--背包中的物品
local function _PackbackItemTip(itemCellData, popFrom)
	local param = 
	{
		itemCellData = itemCellData, 
		withFuncs = false,
		params = popFrom,
	}
	gCurTipPanel = game._GUIMan:Open("CPanelItemHint",param)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

--背包/角色身上的装备
local function _PackbackEquipTip(itemCellData,popFrom)
	local param = 
	{
		itemCellData = itemCellData, 
		withFuncs = false,
		popFrom = popFrom,
	}
	gCurTipPanel = game._GUIMan:Open("CPanelEquipHint",param)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

local function _PackCharmItemTip(itemCellData, itemEquipData, comps)
    local param = 
	{
		itemCellData = itemCellData,
        itemEquipData = itemEquipData,
		withFuncs = true,
		params = comps,
	}
	gCurTipPanel = game._GUIMan:Open("CPanelCharmItemHint",param)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

local function _PackbackItemTipWithCertainFunc(itemCellData, comps)
	local param = 
	{
		itemCellData = itemCellData, 
		withFuncs = true,
		params = comps,
	}
	gCurTipPanel = game._GUIMan:Open("CPanelCharmItemHint",param)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

--Note:没有做参数检查，因此在调用时候需要匹配上面的方法
local function _PopupTipEx(_type)
	if _type == PackName.PACKBACK_ITEM then
		return function(itemCellData, popFrom,pos,obj,itemObj)
			if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end
			if pos ~= nil then 
				tipPosition = pos
			end
			if obj~= nil  then 
				TargetObj = obj
			end
			if itemObj ~= nil then 
				ItemObj = itemObj
			end
			_PackbackItemTip(itemCellData, popFrom)
		end
	elseif _type == PackName.PACKBACK_EQUIP then
		return function(itemCellData,popFrom,pos,obj,itemObj)
			if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end

			if pos ~= nil then 
				tipPosition = pos
			end
			if obj~= nil  then 
				TargetObj = obj
			end
			if itemObj ~= nil then 
				ItemObj = itemObj
			end
			_PackbackEquipTip(itemCellData, popFrom)		
		end
    elseif _type == PackName.CHARM_ITEM then
        return function(itemCellData, itemEquipData, comps, pos, obj, itemObj)
            if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end

			if pos ~= nil then 
				tipPosition = pos
			end
			if obj~= nil  then 
				TargetObj = obj
			end
			if itemObj ~= nil then 
				ItemObj = itemObj
			end
            local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
			local item = CIvtrItem.CreateVirtualItem(itemCellData)
            local equipItem = CIvtrItem.CreateVirtualItem(itemEquipData)
            _PackCharmItemTip(item, equipItem, comps)
        end
	elseif _type == PackName.PACKBACK_ITEM_WITH_CERTAIN_FUNCS then
		return function(itemCellData, params,pos,obj,itemObj)
			if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end
			if pos ~= nil then 
				tipPosition = pos
			end
			if obj ~= nil  then 
				TargetObj = obj
			end
			if itemObj ~= nil then 
				ItemObj = itemObj
			end
			_PackbackItemTipWithCertainFunc(itemCellData, params)
		end
	elseif _type == PackName.OTHER_PANEL then
		return function(itemCellData,popFrom,obj,pos)
			if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end
			if pos ~= nil then 
				tipPosition = pos
			end
			if obj~= nil  then 
				TargetObj = obj
			end
			local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
			local item = CIvtrItem.CreateVirtualItem(itemCellData)
			if item:IsEquip() then
				_PackbackEquipTip(item, popFrom)
			else	
				_PackbackItemTip(item, popFrom)
			end
			
		end
	elseif _type == PackName.CHAT_PANEL then 
		return function(itemDB, popFrom,pos,obj,itemObj)
			if gCurTipPanel and gCurTipPanel:IsShow() then
				gCurTipPanel:Hide()
				gCurTipPanel = nil
			end
			if pos ~= nil then 
				tipPosition = pos
			end
			if obj ~= nil  then 
				TargetObj = obj
			end
			if itemObj ~= nil then 
				ItemObj = itemObj
			end
			local CElementData = require "Data.CElementData"
			local itemTemplate = CElementData.GetItemTemplate(itemDB.Tid)
			if itemTemplate == nil then warn("item Template id ",itemDB.Tid," is nil ") return end
			local CIvtrItems = require "Package.CIvtrItems"
            local class = CIvtrItems.ItemTypeToClass[itemTemplate.ItemType]
            local itemData = nil 
            if class ~= nil then
                itemData = class.new(itemDB)
            else
                itemData = CIvtrItems.CIvtrUnknown.new(itemDB)
            end
			if itemData:IsEquip() then
				_PackbackEquipTip(itemData, popFrom)
			else	
				_PackbackItemTip(itemData, popFrom)
			end
		end
	end
end

local function _CloseCurrentTips()
	if gCurTipPanel ~= nil then
		gCurTipPanel:Hide()
	end
	gCurTipPanel = nil
	TargetObj = nil
	tipPosition = nil
	ItemObj = nil 
end

---- 背包的对比tip 和单个tip 弹出位置不同 所以 增加一个偏移量
--local function _InitTipPosition(tipObj,offsetX)
--	if tipPosition == nil or TargetObj == nil then return end
--	if tipPosition == TipPosition.FIX_POSITION then
--		GameUtil.SetTipsPosition(TargetObj,tipObj,false)
--	elseif tipPosition == TipPosition.DEFAULT_POSITION then 	
--		local root = game._GUIMan:GetPanelRoot(tipObj)
-- 		local tipPanel = root:FindChild("Frame_FixedPosition")
--		local x = TargetObj.localPosition.x + offsetX
--		tipPanel.localPosition = Vector2.New(x,TargetObj.localPosition.y)
--	end
--end

-- 背包的对比tip 和单个tip 弹出位置不同 所以 增加一个偏移量(tip 的适配方式更改此方法暂时弃用)
local function _InitTipPosition(tipFixedRoot, tipObj, offsetX)
	if tipPosition == nil or TargetObj == nil or (type(TargetObj) == "userdata" and TargetObj:Equals(nil)) then return end
	if tipPosition == TipPosition.FIX_POSITION then
		GameUtil.SetTipsPosition(TargetObj, tipObj) 
	elseif tipPosition == TipPosition.DEFAULT_POSITION then
        if not IsNil(tipFixedRoot) then
		    local x = TargetObj.localPosition.x + offsetX
		    tipFixedRoot.localPosition = Vector2.New(x, TargetObj.localPosition.y)
        else
			warn("InitTipPosition: tipFixedRoot is nil! ")
		end
	end
end

local function _CreatMoneyTips (panelData)
	gCurTipPanel = game._GUIMan:Open("CPanelMoneyHint",panelData)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

local function _CreatPetTips (panelData)
	gCurTipPanel = game._GUIMan:Open("CPanelPetHint",panelData)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

local function _CreatPetSkillTips (panelData)
	gCurTipPanel = game._GUIMan:Open("CPanelPetSkillHint",panelData)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
end

_G.CItemTipMan = 
{
	--奇次点击弹出Tip,偶次点击关闭Tip
	ShowPackbackItemTip = _PopupTipEx(PackName.PACKBACK_ITEM),   --背包中物品的tips
	ShowPackbackEquipTip = _PopupTipEx(PackName.PACKBACK_EQUIP),
	ShowItemTips       = _PopupTipEx(PackName.OTHER_PANEL),
    ShowCharmItemTips  = _PopupTipEx(PackName.CHARM_ITEM),
	ShowChatItemTips   = _PopupTipEx(PackName.CHAT_PANEL),       -- 聊天中的Item（装备和物品）
	ShowItemTipWithCertainFunc = _PopupTipEx(PackName.PACKBACK_ITEM_WITH_CERTAIN_FUNCS),
	ShowMoneyTips = _CreatMoneyTips,
	ShowPetTips = _CreatPetTips,
	ShowPetSkillTips = _CreatPetSkillTips,

	InitTipPosition = _InitTipPosition,
	CloseCurrentTips   = _CloseCurrentTips,
}

return CItemTipMan
