local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CloseTipsEvent = require "Events.CloseTipsEvent"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelHintBase = Lplus.Extend(CPanelBase, 'CPanelHintBase')
local def = CPanelHintBase.define

def.field("table")._ItemData = nil
def.field("boolean")._CallWithFuncs = false
def.field("table")._ValidComponents = nil
def.field("number")._PopFrom = 0
def.field("boolean")._IsShowDropButton = false
def.field("boolean")._IsHaveMoreButton = false
def.field("userdata")._DropButton = nil

local function SetButton(self,layButton)
    local count = #self._ValidComponents
    local totalNumber = 6
    local btnSpecial = layButton:FindChild("Btn_More")
    local DropButton = layButton:FindChild("Drop_Button")
    self._IsHaveMoreButton = false
    local BtnItem1 = layButton:FindChild("Btn_Item1")
    local BtnOne = layButton:FindChild("Btn_One")
    BtnOne:SetActive(false)
    if count == 1 then 
        BtnOne:SetActive(true)
        BtnItem1:SetActive(false)
        GUI.SetText(BtnOne:FindChild("Lab_ButtonName"),self._ValidComponents[1]:GetName())
        self._DropButton:SetActive(false)
        btnSpecial:SetActive(false)
        return
    elseif count == 2 then 
        BtnItem1:SetActive(true)
        GUI.SetText(BtnItem1:FindChild("Lab_ButtonName"),self._ValidComponents[1]:GetName())
        self._DropButton:SetActive(false)
        btnSpecial:SetActive(true)
        GUI.SetText(btnSpecial:FindChild("Lab_ButtonName"),self._ValidComponents[2]:GetName())
        return
    end

    self._IsHaveMoreButton = true
    btnSpecial:SetActive(true)
    for i = 1 ,totalNumber do 
        if i > count then
        	local btn = DropButton:FindChild("Btn_Item"..i) 
        	if btn ~= nil then 
            	btn:SetActive(false)
            end
        else
        	local item = nil 
        	if i == 1 then 
        		item = BtnItem1
        	else
                item =  DropButton:FindChild("Btn_Item"..i)
            end
            if item ~= nil then 
	            item:SetActive(true)
	            GUI.SetText(item:FindChild("Lab_ButtonName"),self._ValidComponents[i]:GetName())
	        end
        end
    end
end 

def.method("userdata").InitButtons = function(self,BtnsObj)
    if not self._CallWithFuncs then
        local comps = self._ItemData._Components
        if comps == nil or #comps == 0 or self._PopFrom == TipsPopFrom.OTHER_PANEL or  self._PopFrom == TipsPopFrom.OTHER_PALYER or self._PopFrom ==TipsPopFrom.ROLE_PACK_COMPARE_PANEL then
            BtnsObj:SetActive(false)
        else
            BtnsObj:SetActive(true)
            self._ValidComponents = {}
                -- warn("背包界面") 
            for i,v in ipairs(comps) do 
                if v:IsEnabled() then
                    self._ValidComponents[#self._ValidComponents+1] = v
                end
            end
            SetButton(self,BtnsObj)
        end
    else
        BtnsObj:SetActive(true)
        SetButton(self,BtnsObj)
    end
end 

def.method( "number","dynamic","userdata").ShowTime = function (self, time,isExpireTime,LabObj)
    local day = math.floor(time / 86400)
    local hour = math.floor(time % 86400 / 3600)
    local minute = math.floor((time % 86400 % 3600) / 60)
    local second = math.floor(time % 60)
    local text = ""
    if day > 0 then
        text = text..string.format(StringTable.Get(10670),day)
    end
    if hour > 0 then
        text = text..string.format(StringTable.Get(10671),hour)
    end
    if minute > 0 then
        text = text..string.format(StringTable.Get(10672),minute)
    end
    if second > 0 then 
        text = text..string.format(StringTable.Get(10673),second)
    end
    if isExpireTime == nil and self._ItemData:IsEquip() then 
        GUI.SetText(LabObj,text..StringTable.Get(10677))
        return
    elseif isExpireTime == nil and not self._ItemData:IsEquip() then
        GUI.SetText(LabObj,string.format(StringTable.Get(10692),text))
        return
    end
    if not isExpireTime then
        GUI.SetText(LabObj,string.format(StringTable.Get(10675),text))
    else
        GUI.SetText(LabObj,string.format(StringTable.Get(10676),text))
    end
end


def.override().OnHide = function(self)
    
    CPanelBase.OnHide(self)
	if self._ItemData ~= nil then
		self._ItemData._IsNewGot = false
	end
    game._GUIMan:Close("CPanelItemApproach")    
	local event = CloseTipsEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

CPanelHintBase.Commit()
return CPanelHintBase