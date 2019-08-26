local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local Template = require "PB.Template"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CFxObject = require "Fx.CFxObject"

local CBuff = Lplus.Class("CBuff")
local def = CBuff.define

def.field("number")._ID = 0
def.field(CEntity)._Host = nil
def.field("number")._OriginId = 0
def.field(CFxObject)._GfxObject = nil
def.field(CFxObject)._GfxObject2 = nil
def.field("number")._GfxId = 0
def.field("number")._GfxId2 = 0
def.field("boolean")._DisableIcon = true
def.field("table")._BuffEventTimers = BlankTable
def.field("table")._ActiveBuffEvents = BlankTable
def.field("table")._ActiveActorEvents = BlankTable
def.field("number")._Duration = -1
def.field("number")._EndTime = -1
def.field("number")._MaxDuration = -1

--不显示Icon时，不需要赋值
def.field("string")._Name = ""
def.field("string")._IconPath = ""
def.field("string")._Description = ""
def.field("number")._StateType = -1
def.field("number")._StateLevel = -1
def.field("boolean")._IsReleased = false

--存储 技能 & 被动技能 & 纹章 信息
def.field('table')._BuffInfo = nil

def.static(CEntity, "number", "number", "number", "table", "=>", CBuff).new = function (host, tid, duration, originId, info)
	local buff = CBuff()
    buff._Host = host
	buff:Init(tid, duration, originId, info)
	return buff
end

local function CreateEvent(entity, data)           
    if data == nil then return nil end

    local e = nil
    if data.ModelChangeColor._is_present_in_parent then     
        e = require "Skill.BuffEvent.CBuffModelChangeColor".new(entity, data)
    elseif data.Transform._is_present_in_parent then        
        e = require "Skill.BuffEvent.CBuffTransform".new(entity, data)     
    elseif data.ChangeSkillIcon._is_present_in_parent then      
        e = require "Skill.BuffEvent.CBuffChangeSkillIcon".new(entity, data)     
    elseif data.HideBodyPart._is_present_in_parent then 
        e = require "Skill.BuffEvent.CBuffHideBodyPart".new(entity, data)  
    elseif data.CameraEffect._is_present_in_parent then 
        e = require "Skill.BuffEvent.CBuffCameraEffect".new(entity, data)   
    elseif data.PostureSwitch._is_present_in_parent then    
        e = require "Skill.BuffEvent.CBuffPostureSwitch".new(entity, data)                 
    elseif data.CameraHeightOffset._is_present_in_parent then
        e = require "Skill.BuffEvent.CBuffCameraHeightOffset".new(entity, data)
    elseif data.Audio._is_present_in_parent then
        e = require "Skill.BuffEvent.CBuffAudio".new(entity, data)
    end
    return e
end

-- 角色上下线，效果要保持
local function CreateEnduringEvent(entity, data)           
    if data == nil then return nil end

    local e = nil
    if data.ChangeSkillIcon._is_present_in_parent then      
        e = require "Skill.BuffEvent.CBuffChangeSkillIcon".new(entity, data) 
    elseif data.Transform._is_present_in_parent then
        e = require "Skill.BuffEvent.CBuffTransform".new(entity, data)
    end
    return e
end

def.method("number", "number", "number", "table").Init = function(self, tid, duration, originId, info)
    local buffTemplate = CElementData.GetTemplate("State", tid)
    if buffTemplate ~= nil then
        self._ID = tid
        self._OriginId = originId                    --施法者ID
        self._GfxId = buffTemplate.ActorId
        self._GfxId2 = buffTemplate.ActorId2
        
        self._DisableIcon = buffTemplate.IsShowIcon  --显示icon        

        if duration ~= -1 then
            self._Duration = duration/1000
            self._EndTime = Time.time + self._Duration
            self._MaxDuration = buffTemplate.Duration/1000
        end

        if not self._DisableIcon then 
            self._Name = buffTemplate.Name
            self._IconPath = buffTemplate.IconPath
            self._Description = buffTemplate.Description
            self._StateType = buffTemplate.Type

            if buffTemplate.IsOverlay and buffTemplate.Priority > 0 then
                self._StateLevel = buffTemplate.Priority
            else
                self._StateLevel = 0
            end
        end 

        self._Host:AddLoadedCallback(function()
                self:Load()
            end)

        -- 处理事件
        local execution_units = buffTemplate.ExecutionUnits
        for _,v in ipairs(execution_units) do
            if v.Trigger.Timeline._is_present_in_parent then 
                local function callback()
                    local e = CreateEvent(self._Host, v.Event)
                    if e ~= nil then                                            
                        e:OnEvent()        
                        table.insert(self._ActiveBuffEvents, e) 
                    end
                end
                local timerId = _G.AddGlobalTimer(v.Trigger.Timeline.StartTime/1000, true, callback)
                table.insert(self._BuffEventTimers , timerId)
            end
        end
    end

    self._BuffInfo = info
end

def.method().UpdateEnduringEvent = function(self)
    local buffTemplate = CElementData.GetTemplate("State", self._ID)
    if buffTemplate ~= nil then
        local execution_units = buffTemplate.ExecutionUnits
        for _,v in ipairs(execution_units) do
            if v.Trigger.Timeline._is_present_in_parent then 
                local e = CreateEnduringEvent(self._Host, v.Event)
                if e ~= nil then e:OnEvent() end
            end
        end
    end
end

def.method("=>","string").GetDesc = function(self)
    local desc = self._Description
    if self._BuffInfo ~= nil then 
        local DynamicText = require "Utility.DynamicText"
        desc = DynamicText.ParseBuffStateDescText(self._Description, self._BuffInfo) 
    end
    return desc
end

def.method().Load = function(self)
    if self._Host == nil or self._Host:IsReleased() or self._IsReleased or not self._Host:IsCullingVisible() then return end

    local actor_template = CElementData.GetActorTemplate(self._GfxId)
    if actor_template == nil then return end

    local BirthPlaceType = Template.ExecutionUnit.ExecutionUnitEvent.EventGenerateActor.BirthPlaceType
    local CSkillActorMan = require "Skill.CSkillActorMan"
    
    local param = {} 
    param.BelongedCreature = self._Host
    param.BirthPlace = BirthPlaceType.Self   
    param.BirthPlaceParam = ""
    self._GfxObject = CSkillActorMan.Instance():GenStateActor(actor_template, param, self)

    if self._GfxId2 > 0 then
        local actor_template2 = CElementData.GetActorTemplate(self._GfxId2)
        if actor_template2 == nil then return end

        local param2 = {} 
        param2.BelongedCreature = self._Host
        param2.BirthPlace = BirthPlaceType.Self   
        param2.BirthPlaceParam = ""                
        self._GfxObject2 = CSkillActorMan.Instance():GenStateActor(actor_template2, param2, self)
    end
end

def.method("dynamic").RegistActiveEvent = function (self, event)
    if not event then return end
    self._ActiveActorEvents[#self._ActiveActorEvents + 1] = event
end

def.method("=>", "boolean").IsIconShown = function(self)
    return not self._DisableIcon
end

-- 是否是变身Buff
def.method("=>", "boolean").IsTransform = function (self)
    local buffTemplate = CElementData.GetTemplate("State", self._ID)
    if buffTemplate ~= nil then
        local execution_units = buffTemplate.ExecutionUnits
        for _,v in ipairs(execution_units) do
            if v.Trigger.Timeline._is_present_in_parent then
                if v.Event.Transform._is_present_in_parent then
                    return true
                end
            end
        end
    end
    return false
end

def.method().OnEnd = function(self)
    for _,v in ipairs(self._ActiveBuffEvents) do 
        v:OnBuffEnd()
    end
    self._ActiveBuffEvents = {}
end

def.method().Release = function(self)
    self._IsReleased = true

    if self._GfxObject ~= nil then
        self._GfxObject:Stop()
        self._GfxObject = nil 
    end

    if self._GfxObject2 ~= nil then
        self._GfxObject2:Stop()
        self._GfxObject2 = nil 
    end

    self._ActiveBuffEvents = {}
    
    for _,v in ipairs(self._BuffEventTimers) do 
        _G.RemoveGlobalTimer(v)
    end
    self._BuffEventTimers = {}

    for _,v in ipairs(self._ActiveActorEvents) do 
        v:OnRelease()
    end
    self._ActiveActorEvents = {}
    self._BuffInfo = nil

    self._Host = nil
end

CBuff.Commit()
return CBuff