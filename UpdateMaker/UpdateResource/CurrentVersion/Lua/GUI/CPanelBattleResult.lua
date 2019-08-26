
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelBattleMiddle = require "GUI.CPanelBattleMiddle"
local CPanelBattleResult = Lplus.Extend(CPanelBase, 'CPanelBattleResult')
local def = CPanelBattleResult.define
 
def.field("userdata")._LabTime = nil 
def.field("userdata")._FrameA = nil 
def.field("userdata")._FrameB = nil 
def.field("userdata")._LabTitle = nil 
def.field("table")._Data = nil 
def.field("number")._EndTimerID = 0

local instance = nil
def.static('=>', CPanelBattleResult).Instance = function ()
	if not instance then
        instance = CPanelBattleResult()
        instance._PrefabPath = PATH.UI_BattleResult
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
	self._LabTime = self:GetUIObject("Lab_Time")
	self._FrameA = self:GetUIObject("Frame_A")
	self._FrameB = self:GetUIObject("Frame_B")
	self._LabTitle = self:GetUIObject("Lab_Text")
end

def.override("dynamic").OnData = function(self, data)
	self:InitRank(self._FrameA,data.ListA)
	self:InitRank(self._FrameB,data.ListB)
	self._Data = data
	if not self._Data.IsOut then 
		GameUtil.PlayUISfx(PATH.UIFx_BattlePromotionTitle,self._LabTitle,self._LabTitle,-1)
		GUI.SetText(self._LabTitle,StringTable.Get(27014))
	else
		GUI.SetText(self._LabTitle,StringTable.Get(27015))
	end
	self:AddTimer(data.LeftTime,data.IsOut)
end

def.method("userdata","table").InitRank = function (self,parentObj,listData)
	if listData == nil then
		warn("listData is nil when call InitRank")
		return
	end
	
	for i,v in ipairs(listData) do 
		local item = parentObj:FindChild("Item"..i)

		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHigh = uiTemplate:GetControl(0)
		local labName = uiTemplate:GetControl(2)
		local labScore = uiTemplate:GetControl(4)
		if v.RoleId == game._HostPlayer._ID then 
			GUITools.SetUIActive(imgHigh, true)
		else
			GUITools.SetUIActive(imgHigh, false)
		end
		GUI.SetText(labName,v.Name)
		GUI.SetText(labScore,tostring(v.Score))
		if i <= 3 then 
			local fxObj = uiTemplate:GetControl(3)
			GameUtil.PlayUISfx(PATH.UIFx_BattlePromotionItem,fxObj,fxObj,-1)
		end
	end
end

def.method("number","boolean").AddTimer = function(self, time,isOut)
    if self._EndTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._EndTimerID)
        self._EndTimerID = 0
    end
    local endTime = GameUtil.GetServerTime()/1000 + time
    local function callback()
        time = math.floor(endTime - GameUtil.GetServerTime()/1000)
        if time <= 0 then
        	_G.RemoveGlobalTimer(self._EndTimerID)
        	self._EndTimerID = 0
            game._GUIMan:CloseByScript(self)
        return end
        local second = time % 60
		if not isOut then
    		GUI.SetText(self._LabTime,string.format(StringTable.Get(27012),second))
    	else
    		GUI.SetText(self._LabTime,string.format(StringTable.Get(27013),second))
        end
    end
    self._EndTimerID = _G.AddGlobalTimer(1, false, callback)
end


def.override().OnDestroy = function(self)
	if not self._Data.IsOut  then 
		CPanelBattleMiddle.Instance():InitFinalRankData(self._Data.RoleList)
	else
		local function callback()
			game._GUIMan:Open("CPanelDungeonEnd", self._Data.EndData)
		end
		game._GUIMan:SetMainUIMoveToHide(true,callback)
	end
	if self._EndTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._EndTimerID)
        self._EndTimerID = 0
    end
	self._LabTime = nil 
	self._FrameA = nil 
	self._FrameB = nil 
	self._LabTitle = nil 
end

CPanelBattleResult.Commit()
return CPanelBattleResult