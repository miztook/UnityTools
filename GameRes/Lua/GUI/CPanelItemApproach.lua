
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local EParmType = require "PB.Template".ItemApproach.EParmType
local CTeamMan = require "Team.CTeamMan"
local CTransManage = require "Main.CTransManage"
local CSpecialIdMan = require  "Data.CSpecialIdMan"
local PBHelper = require "Network.PBHelper"
local CPanelUIExterior = require "GUI.CPanelUIExterior"
local CExteriorMan  = require "Main.CExteriorMan"

local CPanelItemApproach = Lplus.Extend(CPanelBase, 'CPanelItemApproach')
local def = CPanelItemApproach.define

local NavType = 
{
	NPC = 0 ,
	Region = 1,
}
def.const("table")._NavType = NavType 
def.field("table")._ListApproachID = nil 
def.field("userdata")._ListMenu = nil
def.field("userdata")._FramePosition = nil 
def.field("string")._ClosePanelName = "" 
def.field("boolean")._IsFromTip = false
def.field("table")._TipPanel = nil
def.field("number")._ItemId = 0 

local instance = nil
def.static('=>', CPanelItemApproach).Instance = function ()
	if not instance then
        instance = CPanelItemApproach()
        instance._PrefabPath = PATH.UI_ItemApproach
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local function GetApproachListData (self,stringId)
    --local strApproach = "1*2*3*4*5"
	local listID = string.split(stringId, "*")
	if listID == nil then return end	
	self._ListApproachID = {}
	for _,v in ipairs(listID) do
		local Tid = tonumber(v)
		if Tid ~= nil then
			self._ListApproachID[#self._ListApproachID + 1] = Tid
		end
	end
end 

def.override().OnCreate = function(self)
	self._ListMenu = self:GetUIObject("List_Approach"):GetComponent(ClassType.GNewList)
	self._FramePosition = self:GetUIObject("Frame_Position")
end

-- panelData =
-- {
-- 	ApproachIDs,
-- 	ParentObj, 需要做适配
--  IsFromTip ,-- 是否是从tip 点开的
--  TipPanel  ，tip面板
--  ItemId ,  -- 物品id
-- }
-- 关于关闭方式暂时不删除(以防有变)
def.override("dynamic").OnData = function(self, data)
	if data == nil then return end
	if data.IsFromTip == nil then 
		self._IsFromTip = false
	else
		self._IsFromTip = data.IsFromTip
	end
	self._ItemId = 0
	if data.ItemId ~= nil and data.ItemId > 0 then 
		self._ItemId = data.ItemId
	end
	-- if data.TipPanel ~= nil then 
	-- 	self._TipPanel = data.TipPanel 
	-- 	self._TipPanel._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
	-- end
	if data.ParentObj ~= nil then 
		GameUtil.SetApproachPanelPosition(data.ParentObj, self._FramePosition) 
	end

	local strApproach = data.ApproachIDs
	if strApproach == nil and self._ItemId > 0 then 
		local itemTemp = CElementData.GetItemTemplate(self._ItemId)
		strApproach = itemTemp.ApproachID
	end
	if strApproach == nil or strApproach == "" then warn("ApproachID is nil ,itemId is "..self._ItemId) return end
    GetApproachListData(self,strApproach)
	if #self._ListApproachID <= 0 then 
		game._GUIMan:CloseByScript(self)
	return end
	self._ListMenu:SetItemCount(#self._ListApproachID)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
	local itemData =  CElementData.GetItemApproach(self._ListApproachID[index + 1])
	if itemData == nil or itemData.Id == nil then return end

	local  icon =  GUITools.GetChild(item, 0)
	if not IsNil(icon) then
		GUITools.SetIcon(icon, itemData.IconPath)
	end

	local labName =  GUITools.GetChild(item, 1)
	if not IsNil(labName) then
		GUI.SetText(labName, itemData.DisplayName)
	end

	local btn = GUITools.GetChild(item, 2)
	if not IsNil(btn) then
		btn:SetActive(itemData.ClickType ~= EParmType.None)
	end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
	self:CheckApproach(index)
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    self:CheckApproach(index)
end

--查看来源
def.method("number").CheckApproach = function(self, index)
	local  approachItem = CElementData.GetItemApproach(self._ListApproachID[index + 1])
	if approachItem == nil or approachItem.Id == nil or approachItem.ClickType == 0 or approachItem.FunID == nil then return end

	local player = game._HostPlayer
	if player:IsDead()  then
		game._GUIMan:ShowTipText(StringTable.Get(30103), false)
		return
	end

	--JJC的时候 点击提示 
	if player: In1V1Fight() or player: In3V3Fight() or player: InEliminateFight() then 
		game._GUIMan:ShowTipText(StringTable.Get(30100), false)
		return 
	end
	-- 未解锁提示
	if not game._CFunctionMan:IsUnlockByFunTid(approachItem.FunID) then
		-- game._GUIMan:ShowTipText(StringTable.Get(30108), false)
    	game._CGuideMan:OnShowTipByFunUnlockConditions(0, approachItem.FunID)
	return end
	--打开界面
	if approachItem.ClickType == EParmType.OpenUI then
		CExteriorMan.Instance():Quit()
		if not self._IsFromTip then 
			game._GUIMan:CloseByScript(self)
		else
			CItemTipMan.CloseCurrentTips() 
		end
		game._AcheivementMan:DrumpToRightPanel(approachItem.Id,self._ItemId)
	return end

    if self:CanMove(tonumber(approachItem.ClickValue1), approachItem.Id) then
         --寻找NPC
	    if approachItem.ClickType == EParmType.FindNpc then
		    self: Move(0, tonumber(approachItem.ClickValue1), tonumber(approachItem.ClickValue2), approachItem.Id)
	    return end

	    --到达区域
	    if approachItem.ClickType == EParmType.FindRegion then
		    self: Move(1, tonumber(approachItem.ClickValue1), tonumber(approachItem.ClickValue2), approachItem.Id)
	    return end

    end
	
	--使用物品
	if approachItem.ClickType == EParmType.UseItem then
		local itemTid = tonumber(approachItem.ClickValue1)
		local item  =  game._HostPlayer._Package._NormalPack:GetItem(itemTid)
		local itemData = CElementData.GetItemTemplate(itemTid)
		if item == nil then			
			local strTips = string.format(StringTable.Get(30101),itemData.TextDisplayName)
			game._GUIMan:ShowTipText(strTips, false)
		else
			local callback = function(val)
    			if val then 
    				item:Use()
    				if not self._IsFromTip then 
						game._GUIMan:CloseByScript(self)
					else
						CItemTipMan.CloseCurrentTips() 
					end
    			end
    		end
    		local itemName = "<color=#" .. EnumDef.Quality2ColorHexStr[itemData.InitQuality] ..">" .. itemData.TextDisplayName.."</color>"
    		local title, strMsg, closeType = StringTable.GetMsg(7)
			local msg = string.format(strMsg, itemName)
    		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)  		
		end
	return end
end

def.method("number","number", "=>", "boolean").CanMove = function(self, nMap, apprID)
    local player = game._HostPlayer
	if player :IsDead()  then
		game._GUIMan:ShowTipText(StringTable.Get(30103), false)
		return false
	end

	--公会需要特殊操作
    if nMap ==  CSpecialIdMan.Get("GuildMapID") then
    	if not game._GuildMan:IsHostInGuild() then
    		game._GUIMan:ShowTipText(StringTable.Get(21501), false)
    		return false
   		end
    end

    return true
end

--寻路 类型 0- NPC  1-区域  TID
def.method("number","number","number","number").Move = function(self, nType, nMap, nTargetID, nTid)
    local player = game._HostPlayer
	--副本中要提示
	if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then 
		local callback = function(val)
			if val then 
				--CTransManage.Instance():SetApproachTrans(nTid)
	            self:ItemApproachTrans(nTid)
				game._DungeonMan:TryExitDungeon()
				if not self._IsFromTip then 
					game._GUIMan:CloseByScript(self)
				else
					CItemTipMan.CloseCurrentTips() 
				end
				game._GUIMan:CloseSubPanelLayer()
	   			game._GUIMan:ShowTipText(StringTable.Get(30104), false)	
			end
		end
		local title,message = "",""
        local closeType = 0
		if game._HostPlayer:InImmediate() then
            title, message, closeType = StringTable.GetMsg(97)
        elseif game._HostPlayer:InPharse() then
			title, message, closeType = StringTable.GetMsg(82)
		elseif game._HostPlayer:InDungeon() then 
			title, message, closeType = StringTable.GetMsg(17)
		end
		MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
		return
	end

	local function CloseAuto()
		local CQuestAutoMan = require"Quest.CQuestAutoMan"
		local CAutoFightMan = require "ObjHdl.CAutoFightMan"
		local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
		CQuestAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()	
		CDungeonAutoMan.Instance():Stop()
	end

	if nType == NavType.NPC then
		CloseAuto()
		CTransManage.Instance():TransToSpecificEntity(nMap,"Npc", nTargetID, nil, true)
    elseif nType == NavType.Region then
    	CloseAuto()
    	CTransManage.Instance():TransToRegionIsNeedBroken(nMap, nTargetID,false,nil,true)	
   	end  

	if not self._IsFromTip then 
		game._GUIMan:CloseByScript(self)
	else
		CItemTipMan.CloseCurrentTips() 
	end
	game._GUIMan:CloseSubPanelLayer()
   	game._GUIMan:ShowTipText(StringTable.Get(30104), false)	
end

def.method("number").ItemApproachTrans = function(self, nTid)
    if nTid <= 0 then return end

	local itemData = CElementData.GetItemApproach(nTid)
	if itemData == nil or itemData.Id == nil then return end

	if itemData.ClickType == EParmType.FindNpc then
		--(mapId he entityTid)
    	CTransManage.Instance():TransToSpecificEntity(tonumber(itemData.ClickValue1),"Npc", tonumber(itemData.ClickValue2), nil, true)
    elseif itemData.ClickType == EParmType.FindRegion then
    	-- mapId 和regionID
    	CTransManage.Instance():TransToRegionIsNeedBroken(tonumber(itemData.ClickValue1), tonumber(itemData.ClickValue2),false,nil,true)		
    end  
end

def.override().OnDestroy = function(self)
	-- if self._TipPanel ~= nil then 
	-- 	self._TipPanel._PanelCloseType = EnumDef.PanelCloseType.Tip
	-- end
	instance = nil 
end

CPanelItemApproach.Commit()
return CPanelItemApproach