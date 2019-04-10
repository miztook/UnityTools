local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CGuideMan = require "Guide.CGuideMan"

local CPanelGuideTrigger = Lplus.Extend(CPanelBase, "CPanelGuideTrigger")
local def = CPanelGuideTrigger.define

local instance = nil

def.field("number")._CurBigStep = -1 -- 当前教学ID(大步骤)
def.field("number")._CurSmallStep = 1 -- 当前步骤(小步骤)
def.field("userdata")._BlackBG = nil
def.field("userdata")._Btn_BG = nil
def.field("userdata")._Btn_Skip = nil
def.field("userdata")._BigStepRoot = nil
def.field("table")._SmallStepList = nil
def.field("table")._CurBigStepConfig = nil
def.field("number")._AnimationDelayTimeTimerID = 0
def.field("userdata")._HightLightBtn = nil
def.static("=>", CPanelGuideTrigger).Instance = function()
    if not instance then
        instance = CPanelGuideTrigger()
        instance._LoadAssetFromBundle = true
        instance._PrefabPath = PATH.Panel_GuideTrigger
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    if IsNil(self._Panel) then return end
    self._BlackBG = self:GetUIObject("BlackBG")
    self._Btn_BG = self:GetUIObject("Btn_BG")
    self._Btn_Skip = self:GetUIObject("Btn_Skip")
end

def.override("dynamic").OnData = function(self, data)
    if data == nil then 
        self:Close()
        return 
    end

    self._CurBigStep = data.Id
    self._CurSmallStep = 1
    self._CurBigStepConfig = data

    -- 当前大步骤
    print("self._CurBigStep=",self._CurBigStep)
    self._BigStepRoot = self:GetUIObject(string.format("Step_%d", self._CurBigStep))
    self._BigStepRoot:SetActive(true)

    -- 小步骤
    self._SmallStepList = { }
    for i = 1, #self._CurBigStepConfig.Steps do
        ----print("OnData", string.format("Step_%d_%d", self._CurBigStep, i))
        --self._SmallStepList[i] = self:GetUIObject(string.format("Step_%d_%d", self._CurBigStep, i))
        self._SmallStepList[i] = self._BigStepRoot:FindChild(tostring(i))
    end



    self:ShowCurSmallStep()

    --self:AddTimer()

    self:EffectAutoPos(self._HightLightBtn)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    --self:RemoveTimer()
    self:RemoveAutoTimer()
    if self._SmallStepList == nil then return end

    for i = 1, #self._SmallStepList do
        self._SmallStepList[i]:SetActive(false)
    end
    self._BigStepRoot:SetActive(false)

    -- if self._AnimationDelayTimeTimerID > 0 then
    --        _G.RemoveGlobalTimer(self._AnimationDelayTimeTimerID)
    --        self._AnimationDelayTimeTimerID = 0
    -- 	end
end

def.override().OnDestroy = function (self)
    self._BlackBG = nil
    self._Btn_BG = nil
    self._Btn_Skip = nil
    self._BigStepRoot = nil
    self._HightLightBtn = nil
    instance = nil
end

def.method().ShowStep = function(self)
    if not IsNil(self._Btn_BG) and #self._SmallStepList > 0 then
        self._SmallStepList[self._CurSmallStep]:SetActive(true)

        local maskTransform = self._SmallStepList[self._CurSmallStep]:FindChild("BlackMaskTransform")
        if self._CurBigStepConfig.Steps[self._CurSmallStep].IsHighLight ~= nil and self._CurBigStepConfig.Steps[self._CurSmallStep].IsHighLight then
            GameUtil.SetMaskTrs(true,self._BlackBG,maskTransform)
        else
            GameUtil.SetMaskTrs(false,self._BlackBG,maskTransform)
        end

        local effect = self._SmallStepList[self._CurSmallStep]:FindChild("Effect")
        if effect ~= nil then
            GameUtil.SetFxSorting(effect,self:GetSortingLayer(),self:GetSortingOrder() + GUIDE_FX_ORDER_EX,true)
            
            effect = effect:FindChild("Frame_Des")
            if effect ~= nil then
                --GameUtil.SetPanelSortingLayer(effect, self:GetSortingLayer())
                GameUtil.SetPanelSortingLayerOrder(effect, self:GetSortingLayer(), self:GetSortingOrder() + GUIDE_FX_ORDER_EX)
            end
        end
    end
end

def.method().ShowCurSmallStep = function(self)
    if not IsNil(self._Btn_BG) then
        self._Btn_BG:SetActive(self._CurBigStepConfig.Steps[self._CurSmallStep].IsClickLimit)
        self._BlackBG:SetActive(self._CurBigStepConfig.Steps[self._CurSmallStep].IsShowBlackBG)

        -- 特效位置校正
        local rc = self._Btn_Skip:GetComponent(ClassType.RectTransform)
        if self._CurBigStepConfig.Steps[self._CurSmallStep].IsSkip == nil then
            self._Btn_Skip:SetActive(false)
        elseif self._CurBigStepConfig.Steps[self._CurSmallStep].IsSkip == 1 then
            self._Btn_Skip:SetActive(true)
            rc.anchorMin = Vector2.New(1,1)
            rc.anchorMax = Vector2.New(1,1)
            rc.pivot = Vector2.New(1,1)
            rc.anchoredPosition = Vector2.New(-50,-10)
        elseif self._CurBigStepConfig.Steps[self._CurSmallStep].IsSkip == 2 then
            self._Btn_Skip:SetActive(true)
            rc.anchorMin = Vector2.New(1,0)
            rc.anchorMax = Vector2.New(1,0)
            rc.pivot = Vector2.New(1,0)
            rc.anchoredPosition = Vector2.New(-50,10)
        end

        local function ShowStepCallBack()
            CGuideMan.UpdateGuideSortingLayerOrder(self)
            self:ShowStep()
        end

        -- 需要动画延迟
        if self._CurBigStepConfig.Steps[self._CurSmallStep].IsAnimationDelay ~= nil and self._CurBigStepConfig.Steps[self._CurSmallStep].IsAnimationDelay then
            self._CurBigStepConfig.Steps[self._CurSmallStep].ShowDelayCallBack = ShowStepCallBack
        else
            local isShow = true
            local panelName = self._CurBigStepConfig.Steps[self._CurSmallStep].ShowUIPanelName

            -- 有界面配置 但是没有显示 不立刻显示教学
            if panelName ~= nil and panelName ~= "" then
                local panel_script = require("GUI." .. panelName).Instance()
                if panel_script == nil or not panel_script:IsShow() then
                    isShow = false
                end
            end

            if isShow then
                ShowStepCallBack()
            end
        end

        CGuideMan.UpdateGuideSortingLayerOrder(self)

    --    ------print("self._CurSmallStep=",self._CurSmallStep)

        if self._CurBigStepConfig.Steps[self._CurSmallStep].InitCallBack ~= nil then
            self._CurBigStepConfig.Steps[self._CurSmallStep].InitCallBack()
        end
    end
end

def.method().HideCurSmallStep = function(self)
    if not IsNil(self._Btn_BG) and #self._SmallStepList > 0 then
        self._Btn_BG:SetActive(false)
        self._BlackBG:SetActive(false)
        self._Btn_Skip:SetActive( false )
        self._SmallStepList[self._CurSmallStep]:SetActive(false)
    end
end

def.method().Finish = function(self)

end

def.method().ShowNextSmallStep = function(self)
    if not IsNil(self._SmallStepList[self._CurSmallStep]) and #self._SmallStepList > 0 then
        self._SmallStepList[self._CurSmallStep]:SetActive(false)
        self._CurSmallStep = self._CurSmallStep + 1
        -- --print("self._CurSmallStep==============",self._CurBigStep,self._CurSmallStep)
        if self._CurSmallStep > #self._CurBigStepConfig.Steps then
            self:Finish()
        else
            self:ShowCurSmallStep()
        end
    end
end

def.override("string").OnClick = function(self, id)
    if id == "Btn_Skip" then
        game._CGuideMan:JumpCurGuide()
    else
        if self._CurBigStepConfig.Steps[self._CurSmallStep].NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickBlackBG then
            local GuideEvent = require "Events.GuideEvent"
            local event = GuideEvent()
            event._Type = EnumDef.EGuideType.Trigger_Start
            event._ID = self._CurBigStep
            event._BehaviourID = EnumDef.EGuideBehaviourID.OnClickBlackBG
            CGame.EventManager:raiseEvent(nil, event)
        end
    end
end

def.field("number")._TimerId = 0
def.method().AddTimer = function(self)
    self._TimerId = _G.AddGlobalTimer(0.17, false, function()
        if self._CurBigStepConfig.Steps[self._CurSmallStep].NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickBG then
            if GameUtil.HasTouchOne() then
                local GuideEvent = require "Events.GuideEvent"
                local event = GuideEvent()
                event._Type = EnumDef.EGuideType.Trigger_Start
                event._ID = self._CurBigStep
                event._BehaviourID = EnumDef.EGuideBehaviourID.OnClickBG
                CGame.EventManager:raiseEvent(nil, event)
            end
        end

    end )
end

def.method().RemoveTimer = function(self)
    if self._TimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end
end

def.field("number")._AutoTimerId = 0
--[[def.method().AddAutoTimer = function(self)
    self._AutoTimerId = _G.AddGlobalTimer(0.2, true, function()
            self:EffectAutoPos(self._HightLightBtn)
    end )
end--]]
def.method().RemoveAutoTimer = function(self)
    if self._AutoTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._AutoTimerId)
        self._AutoTimerId = 0
    end
end

def.method("userdata").EffectAutoPos = function(self, btn)
--print("EffectAutoPos1111",btn)
    if btn == nil or self._CurBigStepConfig == nil then
        return
    end
--print("EffectAutoPos2222")
    if self._CurBigStepConfig.Steps[self._CurSmallStep].AutoShowElement == nil then
        return
    end
--print("EffectAutoPos3333")
    local target = nil
    if self._CurBigStepConfig.Steps[self._CurSmallStep].AutoShowElement ~= "" then
        target = btn:FindChild(self._CurBigStepConfig.Steps[self._CurSmallStep].AutoShowElement)
    else
        target = btn
    end
    
    if target == nil then
        return
    end
--print("EffectAutoPos4444",btn.name)

    local function EffectAutoPos()
        local node = self._SmallStepList[self._CurSmallStep]
        if node == nil then
            print("self._CurSmallStep is nil!!!!!!!!!",self._CurSmallStep)
            return
        end
        print("self._CurSmallStep is ",self._CurBigStep,self._CurSmallStep)
        local effect = node:FindChild("Effect")
        if effect ~= nil then
            --更正 锚点为中心，把特效描述放入特效父节点
            --Frame_Des:SetParent(effect,true)
            --Frame_Des.localPosition = Vector3.Zero

            --例子特效修正
            -- local element = effect:FindChild("ui_xinshou_yuan")
            -- element.localPosition = Vector3.Zero

            -- 特效位置校正
            local rc = effect:GetComponent(ClassType.RectTransform)
            local rcTarget = target:GetComponent(ClassType.RectTransform)

            rc.anchorMin = rcTarget.anchorMin
            rc.anchorMax = rcTarget.anchorMax
            rc.sizeDelta = rcTarget.sizeDelta
            rc.pivot = rcTarget.pivot
            effect.position = target.position

            local element = effect:FindChild("ui_xinshou_yuan")
            if element ~= nil then
                --element.localScale = Vector3.New(rcTarget.sizeDelta.x / 50,rcTarget.sizeDelta.y / 50,1) 
                local max = 0
                if rcTarget.sizeDelta.x > rcTarget.sizeDelta.y then
                    max = rcTarget.sizeDelta.x
                else
                    max = rcTarget.sizeDelta.y
                end
                element.localScale = Vector3.New(max / 50,max / 50,1) 
                if self._CurBigStepConfig.Steps[self._CurSmallStep].EffectScale ~= nil then
                    element.localScale = element.localScale * self._CurBigStepConfig.Steps[self._CurSmallStep].EffectScale
                end
            end

            element = effect:FindChild("ui_xinshou_juxing")
            if element ~= nil then
                element.localScale = Vector3.New(rcTarget.sizeDelta.x / 50,rcTarget.sizeDelta.y / 50,1) 
                if self._CurBigStepConfig.Steps[self._CurSmallStep].EffectScale ~= nil then
                    element.localScale = element.localScale * self._CurBigStepConfig.Steps[self._CurSmallStep].EffectScale
                end
            end

--[[            --根据缩放 排列位置
            local Frame_Des = effect:FindChild("Frame_Des")
            if Frame_Des ~= nil then
                local DesRc = Frame_Des:GetComponent(ClassType.RectTransform)
                if DesRc.anchoredPosition.y == 1  then
                    DesRc.anchoredPosition = Vector2.New(0, rcTarget.sizeDelta.y/2)
                elseif DesRc.anchoredPosition.y == -1 then
                    DesRc.anchoredPosition = Vector2.New(0, -rcTarget.sizeDelta.y/2)
                end
            end--]]

            --根据缩放 排列位置
            local Frame_Des = effect:FindChild("Frame_Des")
            if Frame_Des ~= nil then
                local DesRc = Frame_Des:GetComponent(ClassType.RectTransform)

                local x = 0
                local y = 0
                if DesRc.anchoredPosition.x == 1  then
                    x = rcTarget.sizeDelta.y/4
                elseif DesRc.anchoredPosition.x == -1 then
                    x = -rcTarget.sizeDelta.y/4
                end
                if DesRc.anchoredPosition.y == 1  then
                    y = rcTarget.sizeDelta.y/4
                elseif DesRc.anchoredPosition.y == -1 then
                    y = -rcTarget.sizeDelta.y/4
                end

                DesRc.anchoredPosition = Vector2.New(x, y)
            end
        end
    end

    if self._CurBigStepConfig.Steps[self._CurSmallStep].IsAutoEffectDelay ~= nil and self._CurBigStepConfig.Steps[self._CurSmallStep].IsAutoEffectDelay then
        self._AutoTimerId = _G.AddGlobalTimer(0.1, true, function()
                EffectAutoPos()
        end )
    else
        EffectAutoPos()
    end
end

--
def.method("=>","boolean").IsClickLimit = function(self)
    if not IsNil(self._Btn_BG) then
        return self._Btn_BG.activeSelf
    end
    return false 
end

CPanelGuideTrigger.Commit()
return CPanelGuideTrigger