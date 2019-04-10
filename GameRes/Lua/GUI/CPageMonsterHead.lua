local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local NotifyPropEvent = require "Events.NotifyPropEvent"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CElementData = require "Data.CElementData"
local CFrameBuff = require "GUI.CFrameBuff"
local CPanelBuffOrTalent = require"GUI.CPanelBuffOrTalent"
local CMutipleHpProgress = require "Main.CMutipleHpProgress"
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality

local CPageMonsterHead = Lplus.Class("CPageMonsterHead")
local def = CPageMonsterHead.define
local instance = nil

def.field("userdata")._Panel = nil

def.field("table")._PanelObjectRoot = BlankTable
def.field("table")._PanelObject = BlankTable
def.field(CEntity)._TargetEntiy = nil
def.field("boolean")._LeaveMonster = true
def.field("number")._CheckTimerId = 0
def.field("table")._TargetLinkInfo = nil
def.field("boolean")._IsTargetHeadOpening = false
def.field("number")._DamageFxTimer = 0
def.field("boolean")._Inited = false
def.field(CFrameBuff)._CFrameBuff = nil
def.field(CMutipleHpProgress)._CMutipleHpProgress = nil

def.static("=>", CPageMonsterHead).Instance = function()
	if instance == nil then
        instance = CPageMonsterHead()
	end
	return instance
end

def.method("=>", "boolean").IsShow = function(self)
    return self._Panel ~= nil
end

def.method("=>", "number").GetTargetEntityType = function(self)
    return self._TargetEntiy:GetObjectType()
end

def.method("table", "userdata", CEntity, "dynamic").Show = function(self, linkInfo, root, targetEntiy, targetLinkInfo)
    self._Panel = root                      --该分解的root 节点

    self._PanelObjectRoot = linkInfo
    self._TargetEntiy = targetEntiy         --需要显示的目标
    self._Panel:SetActive(true)
    self:InitFrameStyle()                   --设置血条样式
    -- 初始化Boss血条 
    self:InitMutipleProgress()

    self:UpdateLevelInfo()
    self:UpdateHpInfo()
    self:UpdateStaminaInfo()

    self:UpdateNameInfo()
    self:SetImageHead()
    self:UpdateSfx()                        --目标切换回来的时候，增加破绽特效
    -- self:HideTakeDamageUIFX()               --先移除之前的UI特效
    if targetLinkInfo ~= nil then
        self._TargetLinkInfo = targetLinkInfo   --目标的目标
        --开启目标的目标检查
        self:AddCheckTarget()
    end

    if self._CFrameBuff == nil then
        self._CFrameBuff = CFrameBuff.new(self._TargetEntiy, self._PanelObject,CFrameBuff._LayoutDirection.FromLeftToRight)
    end

    self:ListenToEvent()
    self._Inited = true
end

def.method().InitFrameStyle = function(self)
    local monsterQuality = self._TargetEntiy:GetMonsterQuality()
    if monsterQuality == EMonsterQuality.ELITE then
        -- 精英
        self._PanelObjectRoot.Frame_NormalHead.Root:SetActive( false )
        self._PanelObjectRoot.Frame_EliteHead.Root:SetActive( true )
        self._PanelObjectRoot.Frame_BosslHead.Root:SetActive( false )
        -- 设置根节点
        self._PanelObject = self._PanelObjectRoot.Frame_EliteHead
        self._PanelObject._Pozhan:SetActive(self._TargetEntiy._InfoData._MaxStamina > 0)
        -- 词缀
        self:SetAffixIcon()
    elseif monsterQuality == EMonsterQuality.LEADER or monsterQuality == EMonsterQuality.BEHEMOTH or monsterQuality == EMonsterQuality.ELITE_BOSS then
        -- Boss
        self._PanelObjectRoot.Frame_NormalHead.Root:SetActive( false )
        self._PanelObjectRoot.Frame_EliteHead.Root:SetActive( false )
        self._PanelObjectRoot.Frame_BosslHead.Root:SetActive( true )
        -- 设置根节点
        self._PanelObject = self._PanelObjectRoot.Frame_BosslHead
        self._PanelObject._Pozhan:SetActive(self._TargetEntiy ~= nil and 
                                            self._TargetEntiy._InfoData ~= nil and
                                            self._TargetEntiy._InfoData._MaxStamina > 0)
        -- 词缀
        self:SetAffixIcon()
    else
        -- 剩下的全是普通
        self._PanelObjectRoot.Frame_NormalHead.Root:SetActive( true )
        self._PanelObjectRoot.Frame_EliteHead.Root:SetActive( false )
        self._PanelObjectRoot.Frame_BosslHead.Root:SetActive( false )
        -- 设置根节点
        self._PanelObject = self._PanelObjectRoot.Frame_NormalHead
        
        self._PanelObject._HeadIcon:SetActive( self:GetTargetEntityType() == OBJ_TYPE.NPC )
    end
end

def.method().Hide = function(self)
    if self._Panel == nil then return end

    self:UnlistenToEvent()
    if not self._LeaveMonster and self._PanelObject._Pozhan ~= nil then   -- Hide 界面时，如果正在播放特效，就停止
        self:ActivePozhanGfx(false)
    end
    self:Reset()
    self._Panel:SetActive(false)
    self:ShowTarget(false)
    self:RemoveCheckTarget()
    -- self:HideTakeDamageUIFX()
    self._Panel = nil
    self._PanelObject = nil
    self._TargetEntiy = nil
    self._TargetLinkInfo = nil
    self._LeaveMonster = true
    if self._CFrameBuff ~= nil then
        self._CFrameBuff:Destory()
        self._CFrameBuff = nil
    end
    if CPanelBuffOrTalent.Instance():IsShow() then 
        game._GUIMan:Close("CPanelBuffOrTalent")
    end

    if self._CMutipleHpProgress ~= nil then
        self._CMutipleHpProgress:Release()
        self._CMutipleHpProgress = nil
    end

    self._Inited = false
end

def.method().UpdateSfx = function(self)
    if self._PanelObject._Pozhan == nil then return end

    --如果怪物是破绽状态
    if self._TargetEntiy:HasState(tonumber(CElementData.GetSpecialIdTemplate(93).Value)) then
        self:ActivePozhanGfx(true)
        self._LeaveMonster = false
    else
        self:ActivePozhanGfx(false)
        self._LeaveMonster = true
    end
end

def.method("boolean").ActivePozhanGfx = function(self, bActive)
    local monsterQuality = self._TargetEntiy:GetMonsterQuality()
    local gfx = (monsterQuality == EMonsterQuality.LEADER or
                 monsterQuality == EMonsterQuality.BEHEMOTH or
                 monsterQuality == EMonsterQuality.ELITE_BOSS) and PATH.UI_guaowupozhan_boss or PATH.UI_guaowupozhan

    if bActive then
        GameUtil.PlayUISfx(gfx, self._PanelObject._Pozhan, self._Panel, -1)
    else
        GameUtil.StopUISfx(gfx, self._PanelObject._Pozhan)
    end
end

--目标的目标显隐
def.method("boolean").ShowTarget = function(self, bIsShow)
    if self._IsTargetHeadOpening ~= bIsShow then
        self._TargetLinkInfo.Root:SetActive( bIsShow )
        self._IsTargetHeadOpening = bIsShow
    end
end

def.method().TickLogic = function(self)
    if self._TargetEntiy == nil then
        self:RemoveCheckTarget()
        return
    end

    if self._TargetEntiy._CurrentTargetId > 0 then
        local object = game._CurWorld:FindObject(self._TargetEntiy._CurrentTargetId)
        if object == nil then self:ShowTarget(false) return end
        --没目标时以上逻辑已返回 忽略

        self:ShowTarget(true)
        local info = self._TargetLinkInfo

        --名称
        local name = object._InfoData._Name
        GUI.SetText(info._Name, name)

        --self:UpdateAffixPos()
        --头像
        if object:GetObjectType() == OBJ_TYPE.ELSEPLAYER or
           object:GetObjectType() == OBJ_TYPE.HOSTPLAYER or
           object:GetObjectType() == OBJ_TYPE.PLAYERMIRROR then

            info._HeadIcon:SetActive(true)
            info._HeadIcon_Elite:SetActive(false)
            info._HeadIcon_Boss:SetActive(false)
            --设置头像
            game: SetEntityCustomImg(info._HeadIcon,
                                     object._ID,
                                     object._InfoData._CustomImgSet,
                                     object._InfoData._Gender,
                                     object._InfoData._Prof)
        elseif object:GetObjectType() == OBJ_TYPE.NPC or object:GetObjectType() == OBJ_TYPE.MONSTER then
            local monsterQuality = object:GetMonsterQuality()
            if monsterQuality == EMonsterQuality.ELITE then
                -- 精英
                info._HeadIcon:SetActive(false)
                info._HeadIcon_Elite:SetActive(true)
                info._HeadIcon_Boss:SetActive(false)
            elseif monsterQuality == EMonsterQuality.LEADER or monsterQuality == EMonsterQuality.BEHEMOTH then
                -- Boss
                info._HeadIcon:SetActive(false)
                info._HeadIcon_Elite:SetActive(false)
                info._HeadIcon_Boss:SetActive(true)
            else
                -- 剩下的全是普通
                info._HeadIcon:SetActive(true)
                info._HeadIcon_Elite:SetActive(false)
                info._HeadIcon_Boss:SetActive(false)
                GUITools.SetHeadIcon(info._HeadIcon, object:GetReputationIconPath() )
            end 
        end

        --等级
        GUI.SetText( info._Level, tostring(object._InfoData._Level) )

        local info_data = object._InfoData
        local num = info_data._CurrentHp / info_data._MaxHp
        if info._HpIndicator then
            info._HpIndicator:SetValue(num)
        end
        --血条
        if info._HpText then
            num =  num * 100
            if num > 0 and num < 1 then 
                num = 1
            end
            num = math.clamp(num, 0, 100)
            GUI.SetText(info._HpText, tostring(math.floor(num)) .. "%" )
        end
    else
        self:ShowTarget(false)
    end
end

def.method().AddCheckTarget = function(self)
    self:RemoveCheckTarget()

    local function tick()
        self:TickLogic()
    end
    self._CheckTimerId = _G.AddGlobalTimer(1, false, tick)
end

def.method().RemoveCheckTarget = function(self)
    if self._CheckTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._CheckTimerId)
        self._CheckTimerId = 0
    end
end     

--怪物词缀
def.method().SetAffixIcon = function(self)
    local info = self._PanelObject

    if info._AffixGroupMax ~= nil then
        local affixList = self._TargetEntiy:GetAffix()
        local affixCount = #affixList
        info._AffixGroupMax:SetActive(affixCount > 0)

        if affixCount > 0 then
            local affixGroup = info._AffixMax
            for i=1, #affixGroup do
                local obj = affixGroup[i]
                local affix = affixList[i]
                local bShow = i <= affixCount

                obj:SetActive(bShow)
                obj.parent:SetActive(bShow)
                
                if bShow then
                    GUI.SetText(obj, affix.Name)
                end
            end
        end
    end
end

def.method().UpdateAffixPos = function(self)
    local stamina = self._TargetEntiy:GetCurrentStamina()
    if stamina == 0 then
        
    else
        local info = self._PanelObject
        
    end
end

-- 点击词缀
def.method().OnClickHeadIconShowAffixDes = function(self)
    local info = self._PanelObject
    local affixList = self._TargetEntiy:GetAffix()
    local affixCount = #affixList

    if affixCount > 0 then
        game._GUIMan:Open("CPanelBuffOrTalent",
        {
            Target=nil, Obj=info._HeadIcon,
            AlignType=EnumDef.AlignType.PanelBuff,
            IsShowTalent=true,AffixList=affixList
        })
    end
end

def.method().SetImageHead = function(self)
    local info = self._PanelObject
    -- GUITools.SetHeadIcon(info._HeadIcon, self._TargetEntiy:GetReputationIconPath() )

    --按照怪物品级，设置头像框
    if self._TargetEntiy:GetObjectType() == OBJ_TYPE.NPC then
        GUITools.SetGroupImg(info._ImgHeadBroad, 0)
    elseif self._TargetEntiy:GetObjectType() == OBJ_TYPE.MONSTER then
        local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
        local monsterQuality = self._TargetEntiy:GetMonsterQuality()
        GUITools.SetGroupImg(info._ImgHeadBroad, monsterQuality)
    end
end

-- 设置多血条情况
def.method().InitMutipleProgress = function(self)
    local info = self._PanelObject
    local bShow = self._TargetEntiy:HasMutipleProgress()

    if bShow then
        info._Lab_MutipleProgressCount:SetActive( true )
        local maxCount = self._TargetEntiy:GetProgressCountMax()
        local hpMax = self._TargetEntiy._InfoData._MaxHp
        local hp = self._TargetEntiy._InfoData._MaxHp
        local shield = self._TargetEntiy._InfoData._CurShield

        self._CMutipleHpProgress = CMutipleHpProgress.Instance()
        self._CMutipleHpProgress:Init(info._GBloodGameObject, hpMax, maxCount)
        self._CMutipleHpProgress:SetHp(hp, shield)
    else
        self._PanelObject._HpIndicator:SetLineStyle(1)
    end
end

local OnEntityNameChangeEvent = function(sender, event)
    if instance == nil then return end
    if not instance._TargetEntiy or instance._TargetEntiy._ID ~= event._EntityId then return end
    instance:UpdateNameInfo()
end

local OnEntityHPUpdateEvent = function(sender, event)
    if instance == nil then return end
    if not instance._TargetEntiy or instance._TargetEntiy._ID ~= event._EntityId then return end
    instance:UpdateHpInfo()
end

local OnNotifyPropEvent = function(sender, event)
    if instance == nil then return end
    if not instance._TargetEntiy or instance._TargetEntiy._ID ~= event.ObjID then return end

    -- instance:UpdateLevelInfo()
    instance:UpdateHpInfo()
    instance:UpdateStaminaInfo()
    -- if event.Type == "TakeDamage"then
    --     instance:ShowTakeDamageUIFX()
    -- end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler("EntityNameChangeEvent", OnEntityNameChangeEvent)
    CGame.EventManager:addHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyPropEvent)
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler("EntityNameChangeEvent", OnEntityNameChangeEvent)
    CGame.EventManager:removeHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyPropEvent)
end

def.method( "boolean", "number", "number").TriggerPoZhanState = function(self, isBeginning , triggerStateId, MonsterID)
    if not self:IsShow() or 
       not self._TargetEntiy or
       self._TargetEntiy._ID ~= MonsterID or
       self._PanelObject._Pozhan == nil then
       return
    end
    local info = self._PanelObject
    local dest_state_id = tonumber(CElementData.GetSpecialIdTemplate(93).Value)
    if dest_state_id ~= triggerStateId then return end

    -- info._Pozhan:SetActive(isBeginning)
    if isBeginning then  -- 进入破绽状态，并且耐力值等于0
        self:ActivePozhanGfx(true)
        self._LeaveMonster = false
    else
        self:ActivePozhanGfx(false)
        self._LeaveMonster = true
    end
end

--更新耐力值
def.method().UpdateStaminaInfo = function(self)
    local info = self._PanelObject
    if info._AffixGroupMax == nil or info._Pozhan == nil then return end
    
    local stamina = self._TargetEntiy:GetCurrentStamina()
    local maxStamina = self._TargetEntiy._InfoData._MaxStamina

    if self._TargetEntiy._InfoData._MaxStamina > 0 then
        info._Pozhan:GetComponent(ClassType.Image).fillAmount = stamina / self._TargetEntiy._InfoData._MaxStamina
    end
end

def.method().UpdateLevelInfo = function(self)
    if not IsNil(self._Panel) then
        local showLevel = 0
        -- 0:显示原来的等级。1:显示为显示等级。-1:显示为？
        if self._TargetEntiy:GetObjectType()== OBJ_TYPE.MONSTER then
            local monsterData = CElementData.GetMonsterTemplate(self._TargetEntiy:GetTemplateId())
            showLevel = monsterData.ShowLevel
        elseif self._TargetEntiy:GetObjectType()== OBJ_TYPE.NPC then
            local npcData = CElementData.GetNpcTemplate(self._TargetEntiy:GetTemplateId())
            showLevel = npcData.ShowLevel
        end
        if showLevel == 0 then        
            GUI.SetText( self._PanelObject._Level, tostring(self._TargetEntiy._InfoData._Level))
        elseif showLevel == -1 then
            GUI.SetText( self._PanelObject._Level, "?")
        else
            GUI.SetText( self._PanelObject._Level, tostring(showLevel))
        end
    end
end

def.method().UpdateHpInfo = function(self)
    if not IsNil(self._Panel) then
        local info_data = self._TargetEntiy._InfoData

        if self._TargetEntiy:HasMutipleProgress() and self._CMutipleHpProgress then
            self._CMutipleHpProgress:SetHp(info_data._CurrentHp, info_data._CurShield)
        else
            local info = self._PanelObject
            if info_data._CurShield > 0 then
                local allRatio = (info_data._CurrentHp+info_data._CurShield) / info_data._MaxHp

                if info._HpIndicator then
                    if allRatio < 1 then
                        -- 和小于总血量
                        local hpRatio = info_data._CurrentHp / info_data._MaxHp
                        if self._Inited then
                            info._HpIndicator:SetValue(hpRatio)
                        else
                            info._HpIndicator:SetValueImmediately(hpRatio)
                        end
                        -- 更新护盾值
                        info._HpIndicator:SetGuardValue(allRatio)
                    else
                        -- 和大于总血量
                        local hpRatio = 1 - (info_data._CurShield / (info_data._CurrentHp + info_data._CurShield) )
                        if self._Inited then
                            info._HpIndicator:SetValue(hpRatio)
                        else
                            info._HpIndicator:SetValueImmediately(hpRatio)
                        end
                        -- 更新护盾值
                        info._HpIndicator:SetGuardValue(1)
                    end
                end
            else
                local num = info_data._CurrentHp / info_data._MaxHp
                if info._HpIndicator then
                    -- 更新护盾值
                    info._HpIndicator:SetGuardValue(0)

                    if self._Inited then
                        info._HpIndicator:SetValue(num)
                    else
                        info._HpIndicator:SetValueImmediately(num)
                    end
                end
            end

            -- 更新百分比，只有血量参与计算
            if info._HpText then
                local hpRatio = info_data._CurrentHp / info_data._MaxHp
                hpRatio =  hpRatio * 100
                if hpRatio > 0 and hpRatio < 1 then 
                    hpRatio = 1
                end
                hpRatio = math.clamp(hpRatio, 0, 100)
                GUI.SetText(info._HpText, tostring(math.floor(hpRatio)) .. "%" )
            end
        end
    end 
end

def.method().UpdateEnergyInfo = function(self)
    if not IsNil(self._Panel) then
        local info = self._PanelObject
        local energy_type, cur_energy, max_energy = self._TargetEntiy:GetEnergy()

        info._MpIndicator.fillAmount = cur_energy / max_energy
    end
end

def.method().UpdateNameInfo = function(self)
    if self._TargetEntiy ~= nil then
        local info = self._PanelObject
        local name = self._TargetEntiy._InfoData._Name
        GUI.SetText(info._Name, name)
    end
end

def.method().UpdatePKMode = function(self)
    if not IsNil(self._Panel) then
        local info = self._PanelObject
        GUITools.SetGroupImg(info._ImgPKSet, self._TargetEntiy:GetPkMode() - 1)
    end
end

-- def.method().ShowTakeDamageUIFX = function(self)
--     local info = self._PanelObject
--     -- info._HpDamageUIFx:SetActive(true)
--     local anim = info._HpDamageUIFx:GetComponent(ClassType.DOTweenAnimation)
--     if anim ~= nil then
--         anim:DORestart(false)
--     end
--     local function callback()
--         if anim == nil then return end
--         anim:DOPause()
--         info._HpDamageUIFx:SetActive(false)
--         self._DamageFxTimer = 0
--     end
--     self._DamageFxTimer = _G.AddGlobalTimer(0.5, true, callback)
-- end

-- def.method().HideTakeDamageUIFX = function(self)
--     if self._DamageFxTimer ~= 0 then
--         _G.RemoveGlobalTimer(self._DamageFxTimer)
--         self._DamageFxTimer = 0
--         local info = self._PanelObject
--         local anim = info._HpDamageUIFx:GetComponent(ClassType.DOTweenAnimation)
--         anim:DOPause()
--         info._HpDamageUIFx:SetActive(false)
--     end
-- end

def.method().Reset = function(self)
    local info = self._PanelObject
    if info._HpIndicator then
        info._HpIndicator:SetValue(1)
    end
end

def.method('string').Click = function(self, id)
    local info = self._PanelObject
    if string.find(id, "Btn_BuffMonster") then
        if self._TargetEntiy:HasAnyState() and info._BtnBuff then
            game._GUIMan:Open("CPanelBuffOrTalent", { Target=self._TargetEntiy, Obj=info._BtnBuff, AlignType=EnumDef.AlignType.PanelBuff,IsShowTalent=false})
        end
    end
end

CPageMonsterHead.Commit()
return CPageMonsterHead