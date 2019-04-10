--
-- CPanelUIArrayLine   分线UI。  lidaming 2018/07/16
--
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyPropEvent = require "Events.NotifyPropEvent"
local EPkMode = require "PB.data".EPkMode
local CEntity = require "Object.CEntity"
local CPageManHead = require "GUI.CPageManHead"
local CPageMonsterHead = require "GUI.CPageMonsterHead"
local CFrameBuff = require "GUI.CFrameBuff"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"

local CPanelUIArrayLine = Lplus.Extend(CPanelBase, "CPanelUIArrayLine")
local def = CPanelUIArrayLine.define
local instance = nil

def.field("userdata")._Btn_Sure = nil
def.field("userdata")._Frame_Line = nil
def.field("userdata")._List_MenuType = nil

def.field("number")._CurSelectLine = 0

def.static("=>", CPanelUIArrayLine).Instance = function ()
	if not instance then
        instance = CPanelUIArrayLine()
        instance._PrefabPath = PATH.UI_ArrayLine
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

local function sort_func(value1,value2)
    return value1.LineId < value2.LineId
end

def.override().OnCreate = function(self)
	self._Btn_Sure = self:GetUIObject("Btn_Sure")
	self._Frame_Line = self:GetUIObject("Frame_Line")
	self._List_MenuType = self:GetUIObject('List_MenuType'):GetComponent(ClassType.GNewList)
	self._Btn_Sure:SetActive(true)	
end

def.override("dynamic").OnData =function (self,data)
	if not IsNil(self._Panel) then
		self:UpdateArrayLineInfo()
	end
end

def.method().UpdateArrayLineInfo = function(self)
	local curWorldInfo = game._CurWorld._WorldInfo
	-- GUI.SetText(self._Lab_Line , ("Line_"..curWorldInfo.CurMapLineId))
	-- warn("==========================>>> SetItemCount == ", #curWorldInfo.ValidLineIds)
	self._CurSelectLine = curWorldInfo.CurMapLineId
	table.sort(curWorldInfo.ValidLineIds , sort_func)
	self._List_MenuType:SetItemCount(#curWorldInfo.ValidLineIds)   
	self._List_MenuType:SetSelection(curWorldInfo.CurMapLineId - 1)
end

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)	
	-- warn("----------------------->>>"..id)
	-- local hp = game._HostPlayer
	if id == "Btn_Sure" then
		-- self:OnArrayLineList()
		local curWorldInfo = game._CurWorld._WorldInfo
		if self._CurSelectLine == 0 then warn("self._CurSelectLine == nil") return end
		if self._CurSelectLine == curWorldInfo.CurMapLineId then
			game._GUIMan:ShowTipText(StringTable.Get(12027), false)
		end
		local C2SMapLineChange = require "PB.net".C2SMapLineChange
		local protocol = C2SMapLineChange()
		protocol.MapLine = self._CurSelectLine
		local PBHelper = require "Network.PBHelper"
		PBHelper.Send(protocol)
		game._GUIMan:CloseByScript(self)
	elseif id == 'Btn_Back' then
		game._GUIMan:CloseByScript(self)
	end
end


def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
	if id == 'List_MenuType' then
		local curWorldInfo = game._CurWorld._WorldInfo
		local Img_Select = GUITools.GetChild(item, 1)
		local Lab_LineName = GUITools.GetChild(item, 3)
		local Img_Head = GUITools.GetChild(item, 4)
		local Lab_LineState = GUITools.GetChild(item, 5)
		local IsShowHead = false
		local curState = nil
		Img_Select:SetActive(false)
		if curWorldInfo.ValidLineIds[index + 1].LineId == curWorldInfo.CurMapLineId then
			IsShowHead = true				
		end
		curState = curWorldInfo.ValidLineIds[index + 1].Pressure
		if curState ~= nil then			
			local stateStr = nil
			if curState == EnumDef.ValidLineState.Idel then
				stateStr = StringTable.Get(12023)
			elseif curState == EnumDef.ValidLineState.Free then
				stateStr = StringTable.Get(12024)
			elseif curState == EnumDef.ValidLineState.Busy then
				stateStr = StringTable.Get(12025)
			elseif curState == EnumDef.ValidLineState.Full then
				stateStr = StringTable.Get(12026)
			end
			-- warn("lidaming --arrayline-->>> curState ==", curState , "StateStr == ", stateStr)
			if stateStr == nil then warn("state == nil !!!!!!!!!!!!!!") stateStr = StringTable.Get(12023) end
			GUI.SetText(Lab_LineName , string.format(StringTable.Get(12022), curWorldInfo.ValidLineIds[index + 1].LineId))
			GUI.SetText(Lab_LineState , stateStr)
		end
		Img_Head:SetActive(IsShowHead)		
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
	if id == 'List_MenuType' then
		-- self:OnArrayLineList()
		local curWorldInfo = game._CurWorld._WorldInfo
		-- 战斗状态不可切换分线
		if game._HostPlayer:IsInServerCombatState() then
            game._GUIMan:ShowTipText(StringTable.Get(19415), false)
		else	
			self._List_MenuType:SetSelection(index)	
			self._CurSelectLine = curWorldInfo.ValidLineIds[index + 1].LineId
			-- if curWorldInfo.ValidLineIds[index + 1].LineId ~= curWorldInfo.CurMapLineId then
			warn("lidaming  selectLineIdS --->>>", index, curWorldInfo.ValidLineIds[index + 1].LineId)					
			-- end
        end		
    end
end

def.override().OnHide = function (self)
	CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
	--instance = nil
	self._CurSelectLine = 0
	self._Btn_Sure = nil
	self._Frame_Line = nil
	self._List_MenuType = nil
end

CPanelUIArrayLine.Commit()
return CPanelUIArrayLine