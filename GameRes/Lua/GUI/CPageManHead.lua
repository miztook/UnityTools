local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local NotifyPropEvent = require "Events.NotifyPropEvent"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CTeamMan = require "Team.CTeamMan"
local CFrameBuff = require "GUI.CFrameBuff"
local CElementData = require "Data.CElementData"
local MenuComponents = require "GUI.MenuComponents"
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality

local CPageManHead = Lplus.Class("CPageManHead")
local def = CPageManHead.define
local instance = nil
 
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = BlankTable
def.field(CEntity)._TargetEntiy = nil
def.field("number")._CheckTimerId = 0
def.field("table")._TargetLinkInfo = nil
def.field("boolean")._IsTargetHeadOpening = false
def.field("boolean")._IsMirrorPlayer = false
def.field("number")._DamageFxTimer = 0
def.field(CFrameBuff)._CFrameBuff = nil
def.field("boolean")._Inited = false

def.static("=>", CPageManHead).Instance = function()
	if instance == nil then
        instance = CPageManHead()
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
    self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
    self._TargetEntiy = targetEntiy --需要显示的目标

    self._Panel:SetActive(true)

    self:UpdateLevelInfo()
    self:UpdateHpInfo()
    self:UpdateEnergyInfo()
    self:UpdateNameInfo()
    self:UpdateCustomHead()
    -- self:HideTakeDamageUIFX()       --先移除之前的UI特效
    self._IsMirrorPlayer = not (self._TargetEntiy:GetObjectType() == OBJ_TYPE.ELSEPLAYER or self._TargetEntiy:GetObjectType() == OBJ_TYPE.HOSTPLAYER)
    if self._IsMirrorPlayer then
        self._PanelObject._ImgPKSet:SetActive(false)
    else
        self:UpdatePKMode()
        self._PanelObject._ImgPKSet:SetActive(true)
    end

    self:ListenToEvent()

    if targetLinkInfo ~= nil then
        self._TargetLinkInfo = targetLinkInfo   --目标的目标
        --开启目标的目标检查
        self:AddCheckTarget()
    end
    if self._CFrameBuff == nil then
        self._CFrameBuff = CFrameBuff.new(self._TargetEntiy, self._PanelObject,CFrameBuff._LayoutDirection.FromLeftToRight)
    end
    self._Inited = true
end

def.method().Hide = function(self)
    if self._Panel == nil then return end
    self:UnlistenToEvent()
    self._Panel:SetActive(false)
    self:ShowTarget(false)
    self:RemoveCheckTarget()
    -- self:HideTakeDamageUIFX()
    self._Panel = nil
    self._PanelObject = nil
    self._TargetEntiy = nil
    self._TargetLinkInfo = nil
    self._IsMirrorPlayer = false
    if self._CFrameBuff ~= nil then
        self._CFrameBuff:Destory()
        self._CFrameBuff = nil
    end
    self._Inited = false
end

--目标的目标显隐
def.method("boolean").ShowTarget = function(self, bIsShow)
    if self._IsTargetHeadOpening ~= bIsShow then
        self._TargetLinkInfo.Root:SetActive( bIsShow )
        self._IsTargetHeadOpening = bIsShow
    end
end

def.method().TickLogic = function(self)
    if self._TargetEntiy ~= nil then
        local targetId = self._TargetEntiy:GetCurrentTargetId()
        local object = game._CurWorld:FindObject(targetId)
        if object == nil or object._InfoData == nil then self:ShowTarget(false) return end
        --没目标时以上逻辑已返回 忽略

        self:ShowTarget(true)
        local info = self._TargetLinkInfo

        --名称
        local name = object._InfoData._Name
        GUI.SetText(info._Name, name)
        --头像
        if object:GetObjectType() == OBJ_TYPE.ELSEPLAYER or 
           object:GetObjectType() == OBJ_TYPE.HOSTPLAYER or
           object:GetObjectType() == OBJ_TYPE.PLAYERMIRROR then

            info._HeadIcon:SetActive(true)
            info._HeadIcon_Elite:SetActive(false)
            info._HeadIcon_Boss:SetActive(false)
            --设置头像
            TeraFuncs.SetEntityCustomImg(info._HeadIcon,
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
    --[[
        --蓝条
        local energy_type, cur_energy, max_energy = object:GetEnergy()
        info._MpIndicator.fillAmount = cur_energy / max_energy
    ]]
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
    end
end

local IsCurTarget = function(entityId)
    if instance ~= nil and instance._TargetEntiy ~= nil and instance._TargetEntiy._ID == entityId then
        return true
    end
    return false
end

local OnEntityPKModeChangeEvent = function(sender, event)
    if not IsCurTarget(event._EntityId) then return end
    if not instance._IsMirrorPlayer then
        instance:UpdatePKMode()
        instance:UpdateNameInfo()
    end
end

local OnEntityCustomImgChangeEvent = function(sender, event)
    if not IsCurTarget(event._EntityId) then return end
    instance:UpdateCustomHead()
end

local OnElsePlayerLevelChangeEvent = function(sender, event)
    if not IsCurTarget(event._EntityId) then return end
    instance:UpdateLevelInfo()
end

local OnEntityNameChangeEvent = function(sender, event)
    if not IsCurTarget(event._EntityId) then return end
    instance:UpdateNameInfo()
end

local OnEntityHPUpdateEvent = function(sender, event)
    if not IsCurTarget(event._EntityId) then return end
    instance:UpdateHpInfo()
end

local OnNotifyPropEvent = function(sender, event)
    if not IsCurTarget(event.ObjID) then return end

    instance:UpdateHpInfo()
    instance:UpdateEnergyInfo()
    -- if event.Type == "TakeDamage"then
    --     instance:ShowTakeDamageUIFX()
    -- end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler("EntityPKModeChangeEvent", OnEntityPKModeChangeEvent)
    CGame.EventManager:addHandler("EntityCustomImgChangeEvent", OnEntityCustomImgChangeEvent)
    CGame.EventManager:addHandler("ElsePlayerLevelChangeEvent", OnElsePlayerLevelChangeEvent)
    CGame.EventManager:addHandler("EntityNameChangeEvent", OnEntityNameChangeEvent)
    CGame.EventManager:addHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyPropEvent)  
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler("EntityPKModeChangeEvent", OnEntityPKModeChangeEvent)
    CGame.EventManager:removeHandler("EntityCustomImgChangeEvent", OnEntityCustomImgChangeEvent)
    CGame.EventManager:removeHandler("ElsePlayerLevelChangeEvent", OnElsePlayerLevelChangeEvent)
    CGame.EventManager:removeHandler("EntityNameChangeEvent", OnEntityNameChangeEvent)
    CGame.EventManager:removeHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyPropEvent)  
end

def.method().UpdateLevelInfo = function(self)
    if not IsNil(self._Panel) then
        GUI.SetText( self._PanelObject._Level, tostring(self._TargetEntiy._InfoData._Level) )
    end
end

def.method().UpdateHpInfo = function(self)
    if not IsNil(self._Panel) then
        local info = self._PanelObject
        local info_data = self._TargetEntiy._InfoData

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

def.method().UpdateEnergyInfo = function(self)
    if not IsNil(self._Panel) then
        local info = self._PanelObject
        local energy_type, cur_energy, max_energy = self._TargetEntiy:GetEnergy()

        -- warn("cur_energy / max_energy", cur_energy, max_energy, cur_energy / max_energy)

        info._MpIndicator.fillAmount = cur_energy / max_energy
    end
end

def.method().UpdateNameInfo = function(self)
    if self._TargetEntiy ~= nil then
        local info = self._PanelObject
        local name = self._TargetEntiy:GetEntityColorName()
        GUI.SetText(info._Name, name)
    end
end

def.method().UpdatePKMode = function(self)
    if not IsNil(self._Panel) then
        local info = self._PanelObject
        GUITools.SetGroupImg(info._ImgPKSet, self._TargetEntiy:GetPkMode() - 1)
    end
end

def.method().UpdateCustomHead = function(self)
    if not IsNil(self._Panel) then
        --设置头像
        local info = self._PanelObject

        TeraFuncs.SetEntityCustomImg(info._HeadIcon,
                                 self._TargetEntiy._ID,
                                 self._TargetEntiy._InfoData._CustomImgSet,
                                 self._TargetEntiy._InfoData._Gender,
                                 self._TargetEntiy._InfoData._Prof)
    end
end

-- def.method().ShowTakeDamageUIFX = function(self)
--     local info = self._PanelObject
--     info._HpDamageUIFx:SetActive(true)
--     local anim = info._HpDamageUIFx:GetComponent(ClassType.DOTweenAnimation)
--     if anim ~= nil then
--         anim:DORestart(false)
--     end
--     local function callback()
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

def.method('string').Click = function(self, id)
    local info = self._PanelObject

    if id == "Btn_BuffMan" then
        if self._TargetEntiy:HasAnyState() and info._BtnBuff then
            game._GUIMan:Open("CPanelBuffOrTalent",
            { 
                Target=self._TargetEntiy, Obj=info._BtnBuff, 
                AlignType=EnumDef.AlignType.PanelBuff,
                IsShowTalent = false,
            })
        end
    elseif id == "Btn_SelectHeadMan" then

        if self._TargetEntiy:GetObjectType() == OBJ_TYPE.PLAYERMIRROR then
            return
        end

        local hp = game._HostPlayer
        local myTeamId = hp._TeamId

        local comps = {
            MenuComponents.SeePlayerInfoComponent.new(self._TargetEntiy._ID),
            MenuComponents.ChatComponent.new(self._TargetEntiy._ID),
            MenuComponents.CombatCompareComponent.new(self._TargetEntiy._ID),
            MenuComponents.AddFriendComponent.new(self._TargetEntiy._ID),
            MenuComponents.InviteMemberComponent.new(self._TargetEntiy._ID, myTeamId, self._TargetEntiy._TeamId),
            MenuComponents.ApplyInTeamComponent.new(self._TargetEntiy._ID, myTeamId, self._TargetEntiy._TeamId),
            MenuComponents.AddBlackListComponent.new(self._TargetEntiy._ID),
        }
        MenuList.Show(comps, info._HeadIcon, EnumDef.AlignType.Bottom)
    end
end

CPageManHead.Commit()
return CPageManHead