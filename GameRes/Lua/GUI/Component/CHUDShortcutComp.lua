-- CHUDShortcutComp

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementSkill = require "Data.CElementSkill"
local CEntity = require "Object.CEntity"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CQuestAutoMan = require"Quest.CQuestAutoMan"

local CHUDShortcutComp = Lplus.Class("CHUDShortcutComp")
local def = CHUDShortcutComp.define

-- 父Panel类
def.field("table")._Parent = nil

-- UI对象缓存
def.field("userdata")._BtnTalk = nil          
def.field("userdata")._ImgGNews = nil          

-- 数据成员
def.field("number")._CurTalkType = 0   --目前的快捷方式 标识
def.field(CEntity)._CurTalkTarget = nil

local SqrDistanceH_XZ = Vector3.SqrDistanceH_XZ

def.static("table", "=>", CHUDShortcutComp).new = function(root)
    local obj = CHUDShortcutComp()
    obj._Parent = root
    obj:Init()
    return obj 
end

def.method().Init = function(self)
    self._BtnTalk = self._Parent:GetUIObject('Btn_Talk')
    self._BtnTalk:SetActive(false)   
    self._ImgGNews = self._Parent:GetUIObject('ImgG_News')
end

def.method("number", CEntity).Show = function (self, scType, target)
    self._BtnTalk:SetActive(true)

    if scType == EnumDef.EShortCutEventType.DialogStart then               
        GUITools.SetIcon(self._ImgGNews, PATH.ICON_DIALOG)                
    elseif scType == EnumDef.EShortCutEventType.GatherStart then
        local mine = target
        if mine ~= nil and mine._MineralTemplate ~= nil and mine._MineralTemplate.SkillId > 0 then
            local skillTemp = CElementSkill.Get(mine._MineralTemplate.SkillId) 
            if skillTemp ~= nil then                
                GUITools.SetIcon(self._ImgGNews, skillTemp.IconName)
            end
            local guildMan = game._CGuideMan
            guildMan:GuidePlay(guildMan._CurGuideID, EnumDef.EGuideBehaviourID.Gather, mine:GetTemplateId())
            guildMan:GatherGuide(true)
        end
    elseif scType == EnumDef.EShortCutEventType.RescueStart then -- 救援技能
        local CSpecialIdMan = require  "Data.CSpecialIdMan"
        local  skill_id = CSpecialIdMan.Get("ResurrentSkillId")
        GUITools.SetIcon(self._ImgGNews, CElementSkill.Get(skill_id).IconName)
    end

    self._CurTalkType = scType
    self._CurTalkTarget = target
end

def.method("number", CEntity).Hide = function (self, scType, target)
    if self._CurTalkTarget == nil then
        return
    end

     -- 如果设定了取消的标识 并且 和设定目前标识一致
     -- 不设置则走默认逻辑 设置了必须一致
    if target ~= nil and target ~= self._CurTalkTarget then
       return
    end

    --if scType == EnumDef.EShortCutEventType.DialogEnd then
        self._BtnTalk:SetActive(false)
        self._CurTalkType = 0
        self._CurTalkTarget = nil

        game._CGuideMan:GatherGuide(false)
    --end
end

local function NavigateToTarget(target)
    if not target then return end

    local function onReach()
        CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
        if target:IsDead() then return end
        target:OnClick()
    end

    local hp = game._HostPlayer
    local targetX, targetZ = target:GetPosXZ()
    local hostX, hostZ = hp:GetPosXZ()

    local offset = _G.NAV_OFFSET + target:GetRadius()
    local distance = SqrDistanceH_XZ(targetX, targetZ, hostX, hostZ)

    if distance <= offset * offset then
        onReach()
    else
        CAutoFightMan.Instance():Pause(_G.PauseMask.ManualControl)
        local dest = target:GetPos()
        local function onFail()
            CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
        end
        game:NavigatToPos(dest, offset, onReach, onFail)            
    end
end

def.method().OnClick = function (self)
    local hp = game._HostPlayer
    if hp:IsDead() then return end
    
    -- 主动跟NPC对话或者对玩家救援，停止自动化
    if self._CurTalkType ~= EnumDef.EShortCutEventType.GatherStart then
        hp:StopAutoFollow()
        CDungeonAutoMan.Instance():Stop()
        CQuestAutoMan.Instance():Stop() 
    end

    local curTarget = self._CurTalkTarget 
    if curTarget ~= nil and not curTarget:IsReleased() then
        NavigateToTarget(curTarget)
        -- self._CurTalkTarget = nil
    end

    -- self._CurTalkType = 0
end

def.method().Clear = function (self)
    self._CurTalkTarget = nil 
    self._CurTalkType = 0   --目前的快捷方式 标识
end

def.method().Release = function (self)
    self._BtnTalk = nil
    self._ImgGNews = nil
    self._Parent = nil
end

CHUDShortcutComp.Commit()
return CHUDShortcutComp