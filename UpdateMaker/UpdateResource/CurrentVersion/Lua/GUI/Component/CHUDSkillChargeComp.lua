-- CHUDSkillChargeComp

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementSkill = require "Data.CElementSkill"

local CHUDSkillChargeComp = Lplus.Class("CHUDSkillChargeComp")
local def = CHUDSkillChargeComp.define

-- 父Panel类
def.field("table")._Parent = nil

-- UI对象缓存
def.field("userdata")._SkillBarLast = nil
def.field("userdata")._SkillCirleBar = nil
def.field("userdata")._SkillStickBar = nil
def.field("userdata")._SKillCircleName = nil
def.field("userdata")._SKillStickName = nil
def.field("userdata")._ImgSkillBarFilled = nil          
def.field("userdata")._BtnTalk = nil  
def.field("userdata")._Panel = nil  

-- 数据成员
def.field("number")._UpdateTimer = 0
def.field("number")._GfxTimer = 0
def.field("number")._ChargeStartTime = 0
def.field("number")._MaxChargeTime = 0

def.static("table", "=>", CHUDSkillChargeComp).new = function(root)
    local obj = CHUDSkillChargeComp()
    obj._Parent = root
    obj:Init()
    return obj 
end

def.method().Init = function(self)
    self._SkillBarLast = self._Parent:GetUIObject("Skill_Last") 
    self._SkillCirleBar = self._Parent:GetUIObject("CircleCoolDown")    
    self._SkillStickBar = self._Parent:GetUIObject("Sld_CastBar")
    self._SKillCircleName = self._Parent:GetUIObject("SKillName_C")
    self._SKillStickName = self._Parent:GetUIObject("Skill_Name")
    self._ImgSkillBarFilled = self._Parent:GetUIObject("Img_Handle")
    self._BtnTalk = self._Parent:GetUIObject('Btn_Talk')
    self._Panel = self._Parent._Panel
end

local function SetSliderValue(self, value, skill_id)    
    local _, bar_type = CElementSkill.NeedShowLoadingBar(skill_id)
    if bar_type == EnumDef.SkillLoadingBarType.Stick then
        local sfxSlider = self._SkillStickBar:GetComponent(ClassType.Slider)
        sfxSlider.value = value
    elseif bar_type == EnumDef.SkillLoadingBarType.Circle then
        local imgAmout = self._SkillCirleBar:GetComponent(ClassType.Image)
        imgAmout.fillAmount = value
    end

    -- 20171020 因为特效与当前UI效果不一致，暂时关闭 added by lijian 
    if value >= 0.99 and bar_type == EnumDef.SkillLoadingBarType.Stick then
        GameUtil.PlayUISfx(PATH.UIFX_SkillBarFilled, self._ImgSkillBarFilled, self._Panel, 0.5)
    end
end

def.method("number", "boolean", "number", "number").Update = function(self, skill_id, is_starting, begin_time, max_time)
    local hp = game._HostPlayer
    if is_starting then
        if self._UpdateTimer ~= 0 then
            warn("charging is going on, and cannot restart it")
            return
        end
        -- 前一段采集的特效没播 清掉不播了 直接开启新的采集
        if self._GfxTimer ~= 0 then
            hp:RemoveTimer(self._GfxTimer)
            self._GfxTimer = 0
        end

        if skill_id and skill_id > 0 then
            self:ShowActingBar(skill_id, true)
            GUI.SetText(self._SkillBarLast, "")
        end

        SetSliderValue(self, 0, skill_id)
        self._MaxChargeTime = max_time
        self._ChargeStartTime = begin_time
        self._UpdateTimer = hp:AddTimer(0.05, false, function()
            local value = (Time.time - self._ChargeStartTime)/self._MaxChargeTime
            SetSliderValue(self, value, skill_id)
            if value >= 1 then
                hp:RemoveTimer(self._UpdateTimer)
                self._UpdateTimer = 0
            end
        end)
    else        
        hp:RemoveTimer(self._UpdateTimer)
        self._UpdateTimer = 0
        if Time.time - self._ChargeStartTime >= self._MaxChargeTime then
            SetSliderValue(self, 1, skill_id)                   -- 一出的时候保证满进度
            
            local _, bar_type = CElementSkill.NeedShowLoadingBar(skill_id)
            if bar_type == EnumDef.SkillLoadingBarType.Circle then
                GameUtil.PlayUISfx(PATH.UI_caijijieshu, self._BtnTalk, self._Panel, -1)
            end

            self._GfxTimer = hp:AddTimer(0.3, true, function()      
                    self:ShowActingBar(skill_id, false)
                    self._GfxTimer = 0
                end)
        else
            self:ShowActingBar(skill_id, false)
        end
        self._SkillBarLast:SetActive(false)
    end
end

def.method('number', "boolean").ShowActingBar = function(self, skill_id, shown) 
    local skillTemp = CElementSkill.Get(skill_id)   
    if skillTemp == nil then
        self._SkillStickBar:SetActive(false)
        self._SkillCirleBar:SetActive(false)
        self._SKillStickName:SetActive(false)
        self._SKillCircleName:SetActive(false)
        return
    end

    local _, barType = CElementSkill.NeedShowLoadingBar(skill_id)
    self._SkillStickBar:SetActive(shown and barType == EnumDef.SkillLoadingBarType.Stick)
    self._SkillCirleBar:SetActive(shown and barType == EnumDef.SkillLoadingBarType.Circle)

    if barType == EnumDef.SkillLoadingBarType.Stick then
        self._SKillStickName:SetActive(shown)
        self._SKillCircleName:SetActive(false)
        if shown then
            GUI.SetText(self._SKillStickName, skillTemp.Name)
        end
    elseif barType == EnumDef.SkillLoadingBarType.Circle then
        self._SKillStickName:SetActive(false)
        self._SKillCircleName:SetActive(shown)
        if shown then
            GUI.SetText(self._SKillCircleName, skillTemp.Name)
        end
    end
end

def.method().Clear = function (self)
    local hp = game._HostPlayer
    if hp then
        if self._UpdateTimer > 0 then
            hp:RemoveTimer(self._UpdateTimer)
            self._UpdateTimer = 0
        end

        if self._GfxTimer > 0 then
            hp:RemoveTimer(self._GfxTimer)
            self._GfxTimer = 0
        end
    end 
    self._ChargeStartTime = 0
    self._MaxChargeTime = 0
end

def.method().Release = function (self)
    self._Parent = nil

    self._SkillBarLast = nil
    self._SkillCirleBar = nil
    self._SkillStickBar = nil
    self._SKillCircleName = nil
    self._SKillStickName = nil
    self._ImgSkillBarFilled = nil 
    self._BtnTalk = nil 
    self._Panel = nil
end

CHUDSkillChargeComp.Commit()
return CHUDSkillChargeComp