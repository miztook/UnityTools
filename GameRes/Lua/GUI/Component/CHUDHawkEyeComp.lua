-- CHUDHawkEyeComp

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

local CHUDHawkEyeComp = Lplus.Class("CHUDHawkEyeComp")
local def = CHUDHawkEyeComp.define

-- 父Panel类
def.field("table")._Parent = nil

-- UI对象缓存
def.field("userdata")._ChkEye = nil
def.field("userdata")._LabCD = nil
def.field("userdata")._LabEmpty = nil
def.field("userdata")._ImgEmpty = nil
def.field("userdata")._ImgOpen = nil
def.field("userdata")._ImgClose = nil
def.field("userdata")._Lab_TimeTips = nil          

-- 数据成员
local HawkEyeState =
{
    Open = 1,
    Close = 2,
    Active = 3,
    Deactive = 4,

    None = 100,
}
def.field("number")._CurHawkEyeState = HawkEyeState.None
def.field("number")._EyeBtnState = 0
def.field("number")._RecoverTime = 0
def.field("number")._EmptyCount = 0

local MaxCount = 0
local CDTime = 0

def.static("table", "=>", CHUDHawkEyeComp).new = function(root)
    local obj = CHUDHawkEyeComp()
    obj._Parent = root
    obj:Init()
    return obj 
end

def.method().Init = function(self)
    self._ChkEye = self._Parent:GetUIObject('Chk_Eye')
    self._ChkEye:SetActive(false) 
    self._LabCD = self._Parent:GetUIObject('Lab_CD0')
    self._LabEmpty = self._Parent:GetUIObject('Lab_Empty0')
    self._ImgEmpty = self._Parent:GetUIObject('Img_Empty0')
    self._Lab_TimeTips = self._Parent:GetUIObject('Lab_TimeTips')
    self._Lab_TimeTips:SetActive(false) 
    self._ImgOpen = self._Parent:GetUIObject('Img_Open')
    self._ImgClose = self._Parent:GetUIObject('Img_Close')

    MaxCount = tonumber(CElementData.GetSpecialIdTemplate(148).Value) 
    --鹰眼持续时间 秒
    CDTime = tonumber(CElementData.GetSpecialIdTemplate(149).Value) 
    
    game._HostPlayer:JudgeIsUseHawEye(true)
end

def.method("table").HawkEyeOpen = function (self, params)
    self._ChkEye:SetActive(true)     --按钮显示
    self._LabCD:SetActive(false)     --倒计时不显示
    self._LabEmpty:SetActive(true)   --可使用次数显示
    self._ImgEmpty:SetActive(true)

    if params ~= nil then
        self._EmptyCount = params.remainCount
        self._RecoverTime = params.recoverTime

        if self._EmptyCount >= 0 then
        	GUI.SetText(self._LabEmpty,tostring(self._EmptyCount))
        else
        	self._LabEmpty:SetActive(false)
        	self._ImgEmpty:SetActive(false)
        end

        if self._EyeBtnState ~= params.status then
            GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_01, self._ChkEye)
	        GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_02, self._ChkEye)
	        GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_03, self._ChkEye)
	    end

        if params.status == 1 then
        	GUI.SetAlpha(self._ChkEye,125)
        	GameUtil.PlayUISfx(PATH.UIFX_EYEHAW_kaiqi_01, self._ChkEye, self._ChkEye, -1, 20 , -1)
        elseif params.status == 2 then
        	GUI.SetAlpha(self._ChkEye,200)
        	GameUtil.PlayUISfx(PATH.UIFX_EYEHAW_kaiqi_02, self._ChkEye, self._ChkEye, -1, 20 , -1)
        else
          	GUI.SetAlpha(self._ChkEye,255)
          	GameUtil.PlayUISfx(PATH.UIFX_EYEHAW_kaiqi_03, self._ChkEye, self._ChkEye, -1, 20 , -1)
        end

        
        GUITools.SetGroupImg(self._ChkEye, params.hawkeyeType)

        self._EyeBtnState = params.status
        local guideMan = game._CGuideMan
        guideMan:GuidePlay(guideMan._CurGuideID, EnumDef.EGuideBehaviourID.HawEye, params.status)
        guideMan:GuideTrigger(EnumDef.EGuideBehaviourID.HawEye, params.status)	
        guideMan:HaweyeGuide(true, params.status)
    else
        warn("HawkEyeOpen params error")
        self:HawkEyeClose()
        return
    end

    self._CurHawkEyeState = HawkEyeState.Open
end

def.method().HawkEyeClose = function (self)
	self._ChkEye:SetActive(false)
    GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_01, self._ChkEye)
    GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_02, self._ChkEye)
    GameUtil.StopUISfx(PATH.UIFX_EYEHAW_kaiqi_03, self._ChkEye)
    game._CGuideMan:HaweyeGuide(false,0)
    self._CurHawkEyeState = HawkEyeState.Close
end

--鹰眼使用后回调 服务器允许后执行
def.method("number").HawkEyeActive = function(self, useTime)
	--如果是无限次的 没有 倒计时和计数
	if self._EmptyCount == -1 then
		GameUtil.RemoveCooldownComponent(self._ImgClose,self._LabCD)
	else
	    self._EmptyCount = game._HostPlayer._HawkEyeCount
	    if not IsNil(self._LabEmpty) then
	        GUI.SetText(self._LabEmpty,tostring(self._EmptyCount))
	    end
	    self._LabCD:SetActive(true)

	    if useTime > 0 then
	    	GameUtil.AddCooldownComponent(self._ImgClose, 0, (CDTime-useTime)*1000, self._LabCD, function () end, false)
	    else
	    	GameUtil.AddCooldownComponent(self._ImgClose, 0, CDTime*1000, self._LabCD, function () end, false)
	    end
	end

    self._ImgOpen:SetActive(false)
    self._ImgClose:SetActive(true)
    self._CurHawkEyeState = HawkEyeState.Active
end

def.method().HawkEyeDeactive = function(self)
	self._ImgOpen:SetActive(true)
    self._ImgClose:SetActive(false)
    self._LabCD:SetActive(false)
    self._CurHawkEyeState = HawkEyeState.Deactive
end

def.method().OnClick = function(self)
--[[print("11111111111111111111",self._CurHawkEyeState)
    if self._CurHawkEyeState ~= HawkEyeState.Open then
        return
    end--]]

	if self._EyeBtnState == 1 then
		game._GUIMan:ShowTipText(StringTable.Get(12015), false) 
	elseif self._EyeBtnState == 2 then
		game._GUIMan:ShowTipText(StringTable.Get(12016), false) 
	else
        game._HostPlayer:SendHawkeyeUseOrStop(self._EmptyCount)
    end
end

def.method().Clear = function (self)
	self._EyeBtnState = 0
	self._RecoverTime = 0
	self._EmptyCount = 0
    self._CurHawkEyeState = HawkEyeState.None
end

def.method().Release = function (self)
    self._Parent = nil
	self._ChkEye = nil
	self._LabCD = nil
	self._LabEmpty = nil
	self._ImgEmpty = nil
	self._ImgOpen = nil
	self._ImgClose = nil
	self._Lab_TimeTips = nil 
end

CHUDHawkEyeComp.Commit()
return CHUDHawkEyeComp