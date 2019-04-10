
--[[*************************************
重要功能开启
----by luee 2016.12.14
****************************************]]

local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"
local CPanelOperationTips = Lplus.Extend(CPanelBase, "CPanelOperationTips")
local def = CPanelOperationTips.define

local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"

def.field('userdata')._Obj_Icon = nil-- 功能图标
def.field('userdata')._ObjTipContent = nil-- 功能描述
def.field('userdata')._ObjTipDesc = nil
def.field('userdata')._TweenPlayer = nil -- TweenPlayer
def.field('userdata')._FlyPrefab = nil -- 飞行特效
def.field('userdata')._FlyEndPlayer = nil -- 消失特效
def.field("userdata")._FrameLevelUp = nil --升级面板
def.field("userdata")._FrameOperation = nil --功能面板
def.field("userdata")._LevelUpBg = nil --升级底板
def.field("userdata")._LevelUpBg1 = nil --升级底板1
def.field("userdata")._LevelUpBg2 = nil --升级底板2
def.field("userdata")._LabLevel = nil --升级label
def.field("userdata")._LabLevelFx = nil --升级labelFx
def.field('userdata')._TweenPlayerLVUP = nil -- TweenPlayer

def.field('boolean')._IsMoveTip = false
def.field("number")._OpenTimerID = 0 --开启动画Timer

def.field('table')._OperationTipQueue = BlankTable
--def.field('table')._IconDefaultPos = nil

local instance = nil
def.static('=>', CPanelOperationTips).Instance = function()
    if not instance then
        instance = CPanelOperationTips()
        instance._PrefabPath = PATH.Panel_OperationTips
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._Obj_Icon = self:GetUIObject('Img_Icon')
    --self._IconDefaultPos = self._Obj_Icon.position
    self._ObjTipContent = self:GetUIObject('Lab_TipsContent')
    self._ObjTipDesc = self:GetUIObject('Lab_Tips')
    self._FrameLevelUp = self:GetUIObject('LevelUpFrame')
    self._FrameOperation = self:GetUIObject('OperationFrame')
    self._TweenPlayer = self._FrameOperation:GetComponent(ClassType.DOTweenPlayer)
    self._LevelUpBg = self:GetUIObject("BG1")
    self._LevelUpBg1 = self:GetUIObject("BG2")
    self._LevelUpBg2 = self:GetUIObject("BG3")
    self._LabLevel = self:GetUIObject("Lab_level")
    self._LabLevelFx = self:GetUIObject("Lab_level_Fx")
    self._TweenPlayerLVUP = self._FrameLevelUp:GetComponent(ClassType.DOTweenPlayer)
end

--[[
   data的结构：
   Icon: 图标
   Type: 功能类型(排序标准)
   Text: 文本
   Index(readyonly 用作条件相同的排序标准。内部自动生成)
]]
def.override("dynamic").OnData = function(self, data)
    if data == nil and #self._OperationTipQueue <= 0 then
        self:Close()
        return
    end

    if data == nil then return end

    data.Index = #self._OperationTipQueue
    self._OperationTipQueue[#self._OperationTipQueue + 1] = data
    
    self:PopupOneTip()
end

def.method().PopupOneTip = function(self) 
    if #self._OperationTipQueue < 1 then return end

    local data = self._OperationTipQueue[1]
    -- 移动弹出框
    if self._FlyPrefab ~= nil then
        self._FlyPrefab: SetActive(false)
     end

    if self._FlyEndPlayer ~= nil then
        self._FlyEndPlayer: SetActive(false)
     end

    self._OnTipFinishCB = data.OnFinish

    --升级frame 拆分单独显示
    if data.Type == EnumDef.OperationTipsType.PlayerLevelUp then
        if self._FrameOperation ~= nil then
            self._FrameOperation: SetActive(false)
        end

        if self._FrameLevelUp ~= nil then
            self._FrameLevelUp: SetActive(true)
        end
--        GUITools.DoAlpha(self._LevelUpBg, 1, 0.1, nil) 
--        GUITools.DoAlpha(self._LevelUpBg1, 1, 0.1, nil) 
--        GUITools.DoAlpha(self._LevelUpBg2, 1, 0.1, nil)
--        GUITools.DoAlpha(self._LabLevel, 1, 0.1, nil)

        self:PlayLevelUp(data)
    else
        if self._FrameOperation ~= nil then
            self._FrameOperation:SetActive(true)
        end

        if self._FrameLevelUp ~= nil then
            self._FrameLevelUp:SetActive(false)
        end

        --特效
        GameUtil.PlayUISfx(PATH.UIFX_OperationTips_BG, self._Panel, self._Panel, -1, 20, -1)
        GameUtil.PlayUISfx(PATH.UIFX_OperationTips, self._Panel, self._Panel, -1, 20, 1)
        self._TweenPlayer:Restart("0")
        if data.Type == EnumDef.OperationTipsType.FuncOpen then
            self:PlayMoveTips(data)
        else
            -- 正常弹出框提示
            self:PlayNormalTips(data)
        end
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Msg_Unlock, 0)
    end  
end

def.method("table").PlayLevelUp = function(self, data)
--    local function CallBack()
--        self:CloseTip()
--    end

--    local function SetImgVisible(isShow)
--        if not IsNil(self._LevelUpBg2) then
--            self._LevelUpBg2:SetActive(isShow)
--        end

--        if not IsNil(self._LabLevel) then
--            self._LabLevel:SetActive(not isShow)
--        end 
--    end

--    local function ShowImg()
--        SetImgVisible(false)
--        GUITools.DoAlpha(self._LabLevel, 0.4, 1.5, nil) 
--        GUITools.DoAlpha(self._LevelUpBg, 0.3, 1.5, CallBack) 
--        GUITools.DoAlpha(self._LevelUpBg1, 0.3, 1.5, nil) 

--    end

    GameUtil.PlayUISfx(PATH.UIFX_OperationTips_LVUP, self._Panel, self._Panel, 2, 20, 1)

    if self._LabLevel ~= nil then
        GUI.SetText(self._LabLevel, data.Text) 
    end

    if self._LabLevelFx ~= nil then
        GUI.SetText(self._LabLevelFx, data.Text) 
    end    

    self._TweenPlayerLVUP:Restart("1")

    --SetImgVisible(true)
    --GUITools.DoAlpha(self._LevelUpBg2, 0.2, 1.5, ShowImg)
end

def.method("table").PlayNormalTips = function(self, data)
    self._IsMoveTip = false

    GUITools.SetSprite(self._Obj_Icon, data.Icon) 

    if self._ObjTipContent ~= nil then
        GUI.SetText(self._ObjTipContent, data.Text)
    end

    if self._ObjTipDesc ~= nil then
        if data.Desc ~= nil then
            self._ObjTipDesc:SetActive(true)
            GUI.SetText(self._ObjTipDesc, data.Desc)
        else
            self._ObjTipDesc:SetActive(false)
        end
    end

    --self._Obj_Icon.position = self._IconDefaultPos
end

def.method("table").PlayMoveTips = function(self, data)
    self._IsMoveTip = true
    
     GUITools.SetSprite(self._Obj_Icon, data.Icon)
    
    if self._ObjTipContent ~= nil then
        GUI.SetText(self._ObjTipContent, data.Text)
    end

    if self._ObjTipDesc ~= nil then
        if data.Desc ~= nil then
            self._ObjTipDesc:SetActive(true)
            GUI.SetText(self._ObjTipDesc, data.Desc)
        else
            self._ObjTipDesc:SetActive(false)
        end
    end

    --self._Obj_Icon.position = self._IconDefaultPos
end

def.method().ClearTimerID = function(self)
    if self._OpenTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._OpenTimerID)
        self._OpenTimerID = 0
    end
end

--DOTTween CallBack here
def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	--特例 不掉 CPanelBase.OnDOTComplete(self,go_name,dot_id)

    if dot_id == "1" then
        self:CloseTip()
    elseif dot_id == "0" then
        if self._IsMoveTip and #self._OperationTipQueue >= 1  and self._OperationTipQueue[1].Param ~= "" then
            local data =  self._OperationTipQueue[1]

            local sysyemPanel = CPanelSystemEntrance.Instance()
            local destPos = Vector3.zero
            if sysyemPanel._Panel ~= nil and data.Param ~= nil then
                destPos = sysyemPanel:GetBtnObjectby(data.Param)
            end
            GameUtil.PlayUISfx(PATH.UIFX_OPERATION_FLY, self._Obj_Icon, self._Panel, -1,20,1,function(go)
                if go == nil then return end
                self._FlyPrefab = go
                self._FlyPrefab: SetActive(true)
                --go.position = self._IconDefaultPos
                GUITools.DoMove(go, destPos, 0.5, nil, 0.25, function ()
                    GameUtil.PlayUISfx(PATH.UIFX_OPERATION_END, go, go, -1, 20, 1, function(goEnd)
                       if goEnd == nil then return end
                        self._FlyEndPlayer = goEnd
                        self._FlyEndPlayer:SetActive(true)
                        self:ClearTimerID()
                        self._OpenTimerID =  _G.AddGlobalTimer(0.5, true, function()
                            if not IsNil(sysyemPanel._Panel) then
                                CPanelSystemEntrance.Instance():PlayOpenUIFx(data.Param)
                            end
                            self:CloseTip()
                            self._OpenTimerID = 0
                        end) 
                    end)            
                end)
            end)  
        else
            self:CloseTip()
        end
    end
end

def.method().CloseTip = function(self)
    self._FlyEndPlayer = nil
    
    table.remove(self._OperationTipQueue, 1)
    if #self._OperationTipQueue > 0 then
        -- 以下为方便调试，一键升级后，只提示最高级
        local maxLv = 0
        for i = #self._OperationTipQueue, 1, -1 do
            local v = self._OperationTipQueue[i]
            if v.Type == EnumDef.OperationTipsType.PlayerLevelUp then
                if v.Param > maxLv then
                    maxLv = v.Param
                end
            end
        end

        for i = #self._OperationTipQueue, 1, -1 do
            local v = self._OperationTipQueue[i]
            if v.Type == EnumDef.OperationTipsType.PlayerLevelUp and v.Param < maxLv then
                table.remove(self._OperationTipQueue, i)
            end
        end

        table.sort(self._OperationTipQueue, function(a, b)
        -- 按Id从小到大
            if a.Type < b.Type then
                return true
            elseif a.Type > b.Type then
                return false
            else
                return a.Index < b.Index
            end
        end )

        self:PopupOneTip()
    else

        --self:DoTipFinishCB()
        self:Close()
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:DoTipFinishCB()
end

def.override().OnDestroy = function(self)
    self._OperationTipQueue = {}
    self._FlyPrefab = nil
    self._FlyEndPlayer = nil

    self._FrameLevelUp = nil
    self._FrameOperation = nil
    self._LevelUpBg = nil
    self._LevelUpBg1 = nil
    self._LevelUpBg2 = nil
    self._Obj_Icon = nil
    self._ObjTipContent = nil
    self._LabLevel = nil
    self._TweenPlayer = nil
    self:ClearTimerID()
end

def.override("=>", "boolean").IsCountAsUI = function(self)
    return false
end

--Tip Queue
def.field("function")._OnTipFinishCB = nil

def.method().DoTipFinishCB = function(self)
    if self._OnTipFinishCB ~= nil then
        self._OnTipFinishCB()
        self._OnTipFinishCB = nil
    end
end

CPanelOperationTips.Commit()
return CPanelOperationTips