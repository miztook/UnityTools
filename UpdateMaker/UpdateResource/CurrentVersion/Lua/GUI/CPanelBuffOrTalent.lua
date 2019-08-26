local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local BuffChangeEvent = require "Events.BuffChangeEvent"
local EStateType = require "PB.Template".State.StateType
local CPanelBase = require 'GUI.CPanelBase'

local CPanelBuffOrTalent = Lplus.Extend(CPanelBase, 'CPanelBuffOrTalent')
local def = CPanelBuffOrTalent.define
 
def.field(CEntity)._TargetEntity = nil
def.field('userdata')._Img_BuffBG = nil
def.field('userdata')._List_Buff = nil
def.field('table')._BuffStates = BlankTable
def.field("number")._TickInterval = 0.5
def.field("number")._AlignType = 5 --EnumDef.AlignType.Center
def.field("boolean")._IsShowTalent = false
def.field("table")._AffixList = nil
def.field("number")._TimeId = 0


local instance = nil
def.static('=>', CPanelBuffOrTalent).Instance = function ()
	if not instance then
        instance = CPanelBuffOrTalent()
        instance._PrefabPath = PATH.UI_Buff
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true

        instance:SetupSortingParam()

	end
	return instance
end

def.override().OnCreate = function(self)
    self._Img_BuffBG = self._Panel:FindChild('Img_BuffBG')
    local GNewList = ClassType.GNewList
    self._List_Buff = self:GetUIObject("List_Buff"):GetComponent(GNewList)
end

local function UpdateBuffStatesInfo(sender, event)
    if not instance or not instance:IsShow() then return end
    if instance._TargetEntity == nil or event._EntityID ~= instance._TargetEntity._ID then return end

    local realBuffList = {}
    for i, buff in ipairs( instance._TargetEntity._BuffStates ) do
        if buff._DisableIcon == false then
            table.insert(realBuffList, buff)
        end
    end

    instance._BuffStates = realBuffList
    instance:UpdateBuffStates()
end


local function resetViewPortPos(alignedObj, targetObj)
    local alignedTrans = alignedObj:GetComponent(ClassType.RectTransform)
    local targetTrans = targetObj:GetComponent(ClassType.RectTransform)
    local offsetX = 0
    local offsetY = 0

    offsetX = alignedTrans.rect.width / 2
    offsetY = - alignedTrans.rect.height + 15

    GameUtil.AlignUiElementWithOther(alignedObj, targetObj, offsetX, offsetY)
end

def.override("dynamic").OnData = function(self,data)
    self._IsShowTalent = data.IsShowTalent
    if not data.IsShowTalent then
        self._TargetEntity = data.Target

        local realBuffList = {}
        for i, buff in ipairs( self._TargetEntity._BuffStates ) do
            if buff._DisableIcon == false then
                table.insert(realBuffList, buff)
            end
        end

        self._BuffStates = realBuffList
        self._AlignType = data.AlignType

        local Img_BG = self._Panel:FindChild("Img_BuffBG")
        local scrollView = self:GetUIObject("ScrollView_Buff")
        GUITools.SetRelativePosition(data.Obj, Img_BG, self._AlignType)
        GUITools.SetRelativePosition(data.Obj, scrollView, self._AlignType)
        self:ResizeBG()
        self:UpdateBuffStates()
        
        self:AddTimer()

        CGame.EventManager:addHandler(BuffChangeEvent, UpdateBuffStatesInfo)
    else
        -- 显示词缀的被动技能信息
        self._AffixList = data.AffixList 
        self._AlignType = data.AlignType
        local Img_BG = self._Panel:FindChild("Img_BuffBG")
        local scrollView = self:GetUIObject("ScrollView_Buff")

        resetViewPortPos(data.Obj, Img_BG)
        resetViewPortPos(data.Obj, scrollView)
        self:ResizeBG()
        self._List_Buff:SetItemCount(#self._AffixList)
    end
end

def.method().AddTimer = function (self)
    self._TimeId = game._HostPlayer:AddTimer(self._TickInterval, false ,function()
        self:Tick()
    end)
end
def.method().RemoveTimer = function(self)
    if self._TimeId ~= 0 then
        game._HostPlayer:RemoveTimer(self._TimeId)
        self._TimeId = 0
    end
end

def.method().ResizeBG = function(self)
    local Img_BG = self._Panel:FindChild("Img_BuffBG")
    local viewPortRect = self:GetUIObject("ViewPort")
    local scrollRect = viewPortRect.parent
    local item = self:GetUIObject("item")
    local height = item:GetComponent(ClassType.RectTransform).rect.height
    local count = 0
    if not self._IsShowTalent then
        count = #self._BuffStates
    else
        count = #self._AffixList
    end
    if count > 0 then
        if count * height >= 281 then 
            GUITools.UIResize(Img_BG, 0, 299, self._AlignType)
            GUITools.UIResize(viewPortRect, 0, 281, self._AlignType)
            GUITools.UIResize(scrollRect, 0, 281, self._AlignType)
            return
        else
            height = height * count
            GUITools.UIResize(Img_BG, 0, height+18, self._AlignType)
            GUITools.UIResize(viewPortRect, 0, height, self._AlignType)
            GUITools.UIResize(scrollRect, 0, height, self._AlignType)
        end
    else
        game._GUIMan:CloseByScript(self)
    end
end

def.method().UpdateBuffStates = function (self)
    if #self._BuffStates > 0 then
        self:ResizeBG()
        self._List_Buff:SetItemCount(#self._BuffStates)
    else
        game._GUIMan:CloseByScript(self)
    end
end

def.method().Tick = function(self)
    self:UpdateBuffStates()
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Buff' then
        local Img_Icon = item:FindChild('Img_Icon')
        local TextType = ClassType.Text
        local Lab_Number = item:FindChild('Img_Icon/Lab_Number')
        local Lab_Name = item:FindChild('Lab_Name')
        local Lab_Time = item:FindChild('Lab_Time')
        local Lab_Tips = item:FindChild('Lab_Tips')
        local Img_UpOrDown = item:FindChild("Img_Icon/Img_UpOrDown")

        --去掉最后一个item的线
        if not self._IsShowTalent then
            if index == 0 then
                item:FindChild("Img_Line"):SetActive(false)
            else
                item:FindChild("Img_Line"):SetActive(true)
            end
        else
            if index+1 == #self._AffixList then
                item:FindChild("Img_Line"):SetActive(false)
            else
                item:FindChild("Img_Line"):SetActive(true)
            end
        end

        if not self._IsShowTalent then
            local idx = index + 1
            local buffCount = #self._BuffStates
            local buff = self._BuffStates[buffCount - index]

            if buff == nil then return end

            GUITools.SetIcon(Img_Icon, buff._IconPath)
            GUI.SetText(Lab_Name, buff._Name)
            GUI.SetText(Lab_Tips, buff:GetDesc())

            local bUpFlag = (buff._StateType == EStateType.Buff or buff._StateType == EStateType.DeBuff)
            Img_UpOrDown:SetActive(bUpFlag)
            if bUpFlag then
                GUITools.SetGroupImg(Img_UpOrDown, buff._StateType == EStateType.Buff and 1 or 0)
            end

            if buff._StateLevel > 0 then
                GUI.SetText(Lab_Number, tostring(buff._StateLevel))
            else
                Lab_Number:SetActive(false)
            end

            local strTime = ""
            if buff._EndTime == -1 then
                strTime = StringTable.Get(1007)            
            else
                local lastDuration = buff._EndTime-Time.time
                
                if lastDuration > 0 then
                    strTime = GUITools.FormatTimeSpanFromSeconds(lastDuration)
                else
                    table.remove(self._BuffStates, idx)
                    self:ResizeBG()
                    self:UpdateBuffStates()
                    return
                end
            end

            GUI.SetText(Lab_Time, strTime)
        else
            GUITools.SetIcon(Img_Icon, self._AffixList[index + 1].TalentData.Icon)
            GUI.SetText(Lab_Name,self._AffixList[index + 1].TalentData.Name)
            GUI.SetText(Lab_Tips,self._AffixList[index + 1].TalentData.TalentDescribtion)
            Lab_Time:SetActive(false)
            Lab_Number:SetActive(false)
            Img_UpOrDown:SetActive(false)
        end
    end
end

def.override().OnDestroy = function(self)
    if not self._IsShowTalent then
        self:RemoveTimer()
        CGame.EventManager:removeHandler(BuffChangeEvent, UpdateBuffStatesInfo)
        self._BuffStates = {}
    else
        self._AffixList = nil
    end
    self._TargetEntity = nil
    instance = nil 
end

CPanelBuffOrTalent.Commit()
return CPanelBuffOrTalent