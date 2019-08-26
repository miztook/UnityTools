local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CFrameBuff = require "GUI.CFrameBuff"
local CElementData = require "Data.CElementData"
local ETableStateType = require 'PB.net'.TableState.eTableStateType
local EStateType = require "PB.Template".State.StateType
local BuffChangeEvent = require "Events.BuffChangeEvent"
local CEntity = require "Object.CEntity"
local CPanelArenaLoading = require "GUI.CPanelArenaLoading"
local NotifyPropEvent = require "Events.NotifyPropEvent"
local CPage1V1 = require"GUI.CPage1V1"
local EDungeonType = require"PB.data".EDungeonType

local CPanelPVPHead = Lplus.Extend(CPanelBase, 'CPanelPVPHead')
local def = CPanelPVPHead.define

def.field("userdata")._Frame3V3 = nil 
def.field("userdata")._Frame1V1AndBattle = nil 
def.field("userdata")._LabTime1V1And3V3 = nil
def.field("userdata")._LabBattleTime = nil 
def.field("userdata")._LabGameName = nil 
def.field("userdata")._Frame1V1And3V3Time = nil 
def.field("userdata")._FrameBattleTime = nil 
def.field("table")._FrameRed = nil 
def.field("table")._FrameBlue = nil
def.field("userdata")._FrameHost = nil 
def.field("userdata")._FrameEnemy = nil 
def.field("table")._3V3PlayerData = nil 
def.field("number")._CurOpenArenaType = 0
def.field("number")._TimerId = 0
def.field("boolean")._IsRedHostPlayer = false
def.field("table")._TargetObj = nil 
def.field("table")._1V1RivalData = nil 
def.field("table")._ListBuffGroup1V1Host = nil 
def.field("table")._ListBuffGroup1V1Enemy = nil
def.field("number")._3V3MaxBuff = 3
def.field("number")._1V1MaxBuff = 6 
def.field(CFrameBuff)._CFrameBuffHost = nil
def.field(CFrameBuff)._CFrameBuffEnemy = nil
def.field("number")._EndTime = 0 
def.field(CEntity)._1V1EnemyEntity = nil
def.field("table")._RedDataList = nil 
def.field("table")._BlueDataList = nil 
def.field(CEntity)._BattleCurEnemy = nil 

--阵营类型
local CampType =                              
{
    RedType = 1,
    BlueType = 2,
}

local instance = nil
def.static('=>', CPanelPVPHead).Instance = function ()
	if instance == nil  then
        instance = CPanelPVPHead()
        instance._PrefabPath = PATH.UI_PVPHead
        instance._DestroyOnHide = true
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._Frame3V3 = self:GetUIObject("Frame_3V3")
    self._Frame1V1AndBattle = self:GetUIObject("Frame_1V1")
    self._LabTime1V1And3V3 = self:GetUIObject("Lab_Time")
    self._FrameHost = self:GetUIObject("Frame_HostPlayer")
    self._FrameEnemy = self:GetUIObject("Frame_Enemy")
    self._FrameBattleTime = self:GetUIObject("Frame_BattleTime")
    self._Frame1V1And3V3Time = self:GetUIObject("Frame_Time")
    self._LabGameName = self:GetUIObject("Lab_GameName")
    self._LabBattleTime = self:GetUIObject("Lab_BattleTime")
    self._LabGameName = self:GetUIObject("Lab_GameName")
    self._FrameRed = {}
    for i= 1,3 do
        local FrameHead = self:GetUIObject("Frame_Head"..i)
        FrameHead:SetActive(false)
        self._FrameRed[#self._FrameRed + 1] = 
        {
            _RoleID = 0,
            _FrameHead =  FrameHead,
            _ImgHead = self: GetUIObject("Img_Head"..i),
            _ImgTarget = self:GetUIObject("Img_Target"..i),
            _ImgHpProgress = self:GetUIObject("Img_Progress"..i),
            _LabName = self:GetUIObject("Lab_Name"..i),
            _BtnBuff = self:GetUIObject("Btn_Buff"..i),
            _ListBuff = self:GetUIObject("List_Buff"..i),
            _BtnPlayer = self:GetUIObject("Btn_Player"..i),
            _ImgLeave = self:GetUIObject("Img_NotOnLine"..i),

            _ImgDead = self:GetUIObject("Img_Dead"..i),
            _BuffItemById = {},
            _PositionList = {},
            _LastBuffID = 0,
        }
    end
    self._FrameBlue = {}
    for i = 4,6  do
        local FrameHead = self:GetUIObject("Frame_Head"..i)
        FrameHead:SetActive(false)
        self._FrameBlue[#self._FrameBlue + 1] = 
        {
            _RoleID = 0,
            _FrameHead = self:GetUIObject("Frame_Head"..i),
            _ImgHead = self: GetUIObject("Img_Head"..i),
            _ImgTarget = self:GetUIObject("Img_Target"..i),
            _ImgHpProgress = self:GetUIObject("Img_Progress"..i),
            _LabName = self:GetUIObject("Lab_Name"..i),
            _ListBuff = self:GetUIObject("List_Buff"..i),
            _BtnBuff = self:GetUIObject("Btn_Buff"..i),
            _BtnPlayer = self:GetUIObject("Btn_Player"..i),
            _ImgLeave = self:GetUIObject("Img_NotOnLine"..i),
            _ImgDead = self:GetUIObject("Img_Dead"..i),
            _BuffItemById = {},
            _PositionList = {},
            _LastBuffID = 0,
        }
    end

    self._ListBuffGroup1V1Host = {}
    self._ListBuffGroup1V1Host._ListBuffGroup = {}
    for i=1, self._1V1MaxBuff do
        local obj = self:GetUIObject('item'..i-1)

        self._ListBuffGroup1V1Host._ListBuffGroup[i] = obj
        obj:SetActive(false)
    end

    self._ListBuffGroup1V1Enemy = {}
    self._ListBuffGroup1V1Enemy._ListBuffGroup = {} 
    for i=1, self._1V1MaxBuff do
        local obj = self:GetUIObject('item1'..i-1)

        self._ListBuffGroup1V1Enemy._ListBuffGroup[i] = obj
        obj:SetActive(false)
    end
end   

local function OnEntityHPUpdateEvent(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateProInfo(event._EntityId)
    end
end

local function OnNotifyProEvent(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateProInfo(event.ObjID)
    end
end

local function OnBuffChangeEvent(sender, event)
    if instance._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 and instance:IsShow() then 
        instance:Update3V3Buff(event._EntityID,event._BuffID,event._IsAdd)
    end
end

-- data 为打开类型
def.override("dynamic").OnData = function(self, data)
    self._IsRedHostPlayer = false
    self._CurOpenArenaType = data.DungeonType 
    self:ListenToEvent()
    if self._CurOpenArenaType == EDungeonType.Type_Arena then
        self._Frame1V1AndBattle:SetActive(false)
        self._Frame3V3:SetActive(true)
        self._FrameBattleTime:SetActive(false)
        self._Frame1V1And3V3Time:SetActive(true)
        self._3V3PlayerData = data.Infos
        for i = 1 ,3 do
            self._FrameRed[i]._ImgTarget:SetActive(false)
            self._FrameRed[i]._ImgLeave:SetActive(false)
            self._FrameRed[i]._ImgDead:SetActive(false)
        end
        for i = 1 ,3 do
            self._FrameBlue[i]._ImgTarget:SetActive(false)
            self._FrameBlue[i]._ImgLeave:SetActive(false)
            self._FrameBlue[i]._ImgDead:SetActive(false)
        end
        self:Init3V3PlayerData()
        self._EndTime = game._DungeonMan:GetInstanceEndTime()
        self:AddTimer(self._LabTime1V1And3V3)
    elseif self._CurOpenArenaType == EDungeonType.Type_JJC  then 
        self._Frame3V3:SetActive(false)
        self._Frame1V1AndBattle:SetActive(true)
        self._FrameBattleTime:SetActive(false)
        self._Frame1V1And3V3Time:SetActive(true)
        for i,v in ipairs(data.Infos) do 
            if v.RoleId ~= game._HostPlayer._ID then
                self._1V1RivalData = v 
            end
        end
        self:Init1V1PlayerData()
        self._EndTime = game._DungeonMan:GetInstanceEndTime()
        self:AddTimer(self._LabTime1V1And3V3)
    elseif self._CurOpenArenaType == EDungeonType.Type_Eliminate then 
        self._Frame3V3:SetActive(false)
        self._Frame1V1AndBattle:SetActive(true)
        self._FrameBattleTime:SetActive(true)
        self._Frame1V1And3V3Time:SetActive(false)
        if data.TableInfo.State == ETableStateType.Normal then 
            GUI.SetText(self._LabGameName,StringTable.Get(27005))
        elseif data.TableInfo.State == ETableStateType.Finals then 
            GUI.SetText(self._LabGameName,StringTable.Get(27006))
        end 
        self:InitBattlePlayerData()
        self._EndTime = data.TableInfo.ExpiredTime 
        self:AddTimer(self._LabBattleTime)
    end
end

def.override("string").OnClick = function(self,id)
    CPanelBase.OnClick(self,id)
    if self._CurOpenArenaType == EDungeonType.Type_Arena then
        self:Click3V3(id)
    else
        self:Click1V1OrBattle(id)
    end
end

def.method("string").Click3V3 = function (self,id)
    if string.find(id,"Btn_Buff")then
        local roleId = tonumber(string.sub(id,9,-1))
        local bIsRed = false
        local Btn_Obj = nil 
        for i,v in ipairs(self._FrameBlue) do 
            if v._RoleID == roleId then 
                Btn_Obj = v._BtnBuff
                bIsRed = false
                break
            end
        end
        if Btn_Obj == nil then 
            for i,v in ipairs(self._FrameRed) do 
                if v._RoleID == roleId then 
                    Btn_Obj = v._BtnBuff
                    bIsRed = true
                    break
                end
            end
        end

        local entity = game._CurWorld:FindObject(roleId)
        if entity == nil then return end
        if entity:HasAnyState() and not IsNil(Btn_Obj) then
            game._GUIMan:Open("CPanelBuffOrTalent",
            { 
                Target = entity, Obj = Btn_Obj, 
                AlignType = bIsRed and EnumDef.AlignType.PVPLeft or EnumDef.AlignType.PVPRight,
                IsShowTalent = false,
            })
        end
    elseif string.find(id,"Btn_Player") then 
        local roleId = tonumber(string.sub(id,11,-1))
        local entity = game._CurWorld:FindObject(roleId)
        if entity == nil then return end
        if not entity:IsDead() then
            game._HostPlayer:UpdateTargetInfo(entity, true)
        end
    end
end

def.method("string").Click1V1OrBattle = function (self,id)
    if id == "Btn_BuffHost" then 
        local Btn_Obj = self:GetUIObject("Btn_BuffHost")
        if game._HostPlayer:HasAnyState() and not IsNil(Btn_Obj) then
            game._GUIMan:Open("CPanelBuffOrTalent",
            { 
                Target = game._HostPlayer, Obj = Btn_Obj, 
                AlignType = EnumDef.AlignType.PVP1V1Left,
                IsShowTalent = false,
            })
        end
    elseif id == "Btn_BuffEnemy"then 
        local EnemyEntity = nil 
        if self._CurOpenArenaType == EDungeonType.Type_Eliminate then 
            EnemyEntity = self._BattleCurEnemy 
        else
            EnemyEntity = self._1V1EnemyEntity 
        end
        local Btn_Obj = self:GetUIObject("Btn_BuffEnemy")
        if EnemyEntity :HasAnyState() and not IsNil(Btn_Obj) then
            game._GUIMan:Open("CPanelBuffOrTalent",
            { 
                Target = EnemyEntity, Obj = Btn_Obj, 
                AlignType = EnumDef.AlignType.PVP1V1Right,
                IsShowTalent = false,
            })
        end
    end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyProEvent)
    if self._CurOpenArenaType == EDungeonType.Type_Arena then 
        CGame.EventManager:addHandler(BuffChangeEvent, OnBuffChangeEvent)
    end
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler("EntityHPUpdateEvent", OnEntityHPUpdateEvent)
    CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyProEvent)
    if self._CurOpenArenaType == EDungeonType.Type_Arena then 
        CGame.EventManager:removeHandler(BuffChangeEvent, OnBuffChangeEvent)
    end
end

local function SetPlayerShow(nType,index,PlayerInfo)
    if PlayerInfo == nil then warn(" PlayerInfo  is nil ") return end
    local uiItem = nil
    if nType == 2 then
        uiItem = instance._FrameBlue[index]
    else
        uiItem = instance._FrameRed[index]
    end

    uiItem._FrameHead:SetActive(true)
    uiItem._RoleID = PlayerInfo.RoleId
    TeraFuncs.SetEntityCustomImg(uiItem._ImgHead,PlayerInfo.RoleId,PlayerInfo.CustomImgSet,Profession2Gender[PlayerInfo.Profession],PlayerInfo.Profession)
    local hostId = game._HostPlayer._ID
    local ColorName = "<color=#FFFFFFFF>" ..PlayerInfo.Name.."</color>" 
    if hostId == PlayerInfo.RoleId then
        ColorName =  "<color=#ECBE33FF>" .. PlayerInfo.Name .."</color>" 
    end
    GUI.SetText(uiItem._LabName,ColorName)
    local entity = game._CurWorld:FindObject(PlayerInfo.EntityId)
    if entity == nil then
        uiItem._ImgLeave:SetActive(true)
        GameUtil.SetButtonInteractable(uiItem._BtnPlayer, false)
        uiItem._ListBuff:SetActive(false)
        return 
    end
    uiItem._ImgLeave:SetActive(false)
    GameUtil.SetButtonInteractable(uiItem._BtnPlayer, true)
    uiItem._ImgHpProgress:GetComponent(ClassType.Image).fillAmount = entity._InfoData._CurrentHp / entity._InfoData._MaxHp
    uiItem._BtnBuff.name = "Btn_Buff"..PlayerInfo.EntityId
    uiItem._BtnPlayer.name = "Btn_Player"..PlayerInfo.EntityId

    instance:Init3V3BuffState(uiItem,entity)
end 

local function InitHostShowInfo(self)
    local hp = game._HostPlayer._InfoData
    GUI.SetText(self:GetUIObject("Lab_HostName"),hp._Name)
    GUI.SetText(self:GetUIObject("Lab_LvHosPlayer"),string.format(StringTable.Get(21508),hp._Level))
    TeraFuncs.SetEntityCustomImg(self:GetUIObject("Img_HeadHosPlayer"),game._HostPlayer._ID,hp._CustomImgSet,hp._Gender,hp._Prof)
    local HpHost = self:GetUIObject('Bld_HPHostPlayer'):GetComponent(ClassType.GBlood)
    local MpHost = self:GetUIObject('Prg_FillRectHostPlayer'):GetComponent(ClassType.Image)
    local value1 = hp._CurrentHp / hp._MaxHp
    HpHost:SetValue(value1)
    local energy_type, cur_energy, max_energy = game._HostPlayer:GetEnergy()
    MpHost.fillAmount = cur_energy / max_energy
    GUI.SetText(self:GetUIObject("Lab_HPHostPlayer"),string.format(StringTable.Get(20061),hp._CurrentHp,hp._MaxHp))
    if self._CFrameBuffHost == nil then
        self._CFrameBuffHost = CFrameBuff.new(game._HostPlayer, self._ListBuffGroup1V1Host,CFrameBuff._LayoutDirection.FromLeftToRight)
    else
        self._CFrameBuffHost:InitBuffState()
    end
end

local function Init1V1EnemyShowInfo(self,data)
    if data.RoleId < 0 then 
        local TextTemp = CElementData.GetTextTemplate(tonumber(data.Name))
        GUI.SetText(self:GetUIObject("Lab_EnemyName"),TextTemp.TextContent)
    else
        GUI.SetText(self:GetUIObject("Lab_EnemyName"),data.Name)
    end
    GUI.SetText(self:GetUIObject("Lab_LvEnemy"),string.format(StringTable.Get(21508),data.Level))
    TeraFuncs.SetEntityCustomImg(self:GetUIObject("Img_HeadEnemy"),data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
    local HpEnemy = self:GetUIObject("Bld_HPEnemy"):GetComponent(ClassType.GBlood)
    local value2 = data.CurrentHp / data.MaxHp
    HpEnemy:SetValue(value2)
    GUI.SetText(self:GetUIObject("Lab_HPEnemy"),string.format(StringTable.Get(20061),data.CurrentHp ,data.MaxHp))
    game._HostPlayer:TryLockTarget(data.EntityId)
    local entity = game._CurWorld:FindObject(data.EntityId)
    self._1V1EnemyEntity = entity
    if entity == nil then warn("EnemyEntity is nil") return end
    if self._CFrameBuffEnemy == nil then
        self._CFrameBuffEnemy = CFrameBuff.new(entity, self._ListBuffGroup1V1Enemy,CFrameBuff._LayoutDirection.FromRightToLeft)
    else
        self._CFrameBuffHost:InitBuffState()
    end
end

local function InitBattleEnemyShowInfo(self,data)
    local info = data._InfoData
    GUI.SetText(self:GetUIObject("Lab_EnemyName"),info._Name)
    GUI.SetText(self:GetUIObject("Lab_LvEnemy"),string.format(StringTable.Get(21508),info._Level))
    TeraFuncs.SetEntityCustomImg(self:GetUIObject("Img_HeadEnemy"),data._ID,info._CustomImgSet,info._Gender,info._Prof)
    local HpEnemy = self:GetUIObject("Bld_HPEnemy"):GetComponent(ClassType.GBlood)
    local value2 = info._CurrentHp / info._MaxHp
    HpEnemy:SetValue(value2)
    GUI.SetText(self:GetUIObject("Lab_HPEnemy"),string.format(StringTable.Get(20061),info._CurrentHp ,info._MaxHp))
    if self._CFrameBuffEnemy == nil then
        self._CFrameBuffEnemy = CFrameBuff.new(data, self._ListBuffGroup1V1Enemy,CFrameBuff._LayoutDirection.FromRightToLeft)
    else
        self._CFrameBuffHost:InitBuffState()
    end
end

def.method().Init3V3PlayerData = function (self)
    self._RedDataList = {}
    self._BlueDataList = {}
    for i,v in ipairs(self._3V3PlayerData) do
        if v.Camp == CampType.RedType  then 
            self._RedDataList[#self._RedDataList + 1] = v
        elseif v.Camp == CampType.BlueType then 
            self._BlueDataList[#self._BlueDataList + 1] = v
        end
    end
    for i,v in ipairs(self._RedDataList) do
        if v ~= nil then
            SetPlayerShow(v.Camp,i,v)   
            if v.RoleId == game._HostPlayer._ID then 
                self._IsRedHostPlayer = true
            end  
        end
    end

    for i,v in ipairs(self._BlueDataList) do
        if v ~= nil then            
            SetPlayerShow(v.Camp,i,v) 
            if v.RoleId == game._HostPlayer._ID then 
                self._IsRedHostPlayer = false
            end     
        end 
    end

    -- 隐藏队友选中目标按钮
    local FriendFrameObj = self._FrameBlue
    if self._IsRedHostPlayer then 
        FriendFrameObj = self._FrameRed
    end
    for i,v in ipairs(FriendFrameObj) do
        if v ~= nil then            
           v._BtnPlayer:SetActive(false)
        end 
    end
end

def.method().Init1V1PlayerData = function (self)   
    InitHostShowInfo(self)
    Init1V1EnemyShowInfo(self,self._1V1RivalData)
end

def.method().InitBattlePlayerData = function (self)
    InitHostShowInfo(self)
    self._BattleCurEnemy = game._HostPlayer:GetCurrentTarget()
    if self._BattleCurEnemy == nil then 
        self._FrameEnemy:SetActive(false)
    else
        self._FrameEnemy:SetActive(true)
        InitBattleEnemyShowInfo(self,self._BattleCurEnemy)
    end
end

--队员断线重连后 收到的该队员信息 更新显示
def.method("table").UpdatePlayerData = function(self,data)
    for i,player in ipairs(data) do
        if self._CurOpenArenaType == EDungeonType.Type_JJC then 
            self:UpdatePlayerHpAndMp(player.RoleId)
        else
            local teamData = nil 
            if player.Camp == CampType.RedType then 
                teamData = self._RedDataList 
            elseif player.Camp == CampType.BlueType then
                teamData = self._BlueDataList 
            end
            for j,v in ipairs(teamData) do
                if player.RoleId == v.RoleId then 
                    SetPlayerShow(v.Camp,j,player) 
                end 
            end
        end
    end
end

-----------------------------属性信息更新-----------------------------
def.method("number").UpdateProInfo = function (self,roleId)
    if self._CurOpenArenaType == EDungeonType.Type_Arena then
        self:Update3V3PlayerHp(roleId)
    else
        self:UpdatePlayerHpAndMp(roleId)
    end
end

def.method("number").Update3V3PlayerHp = function (self,roleId) 
    for i,v in ipairs(self._FrameRed) do
        if v._RoleID == roleId then 
            local entity = game._CurWorld:FindObject(v._RoleID)
            if entity == nil then warn("roleId 红队 ==             ",roleId) return end
            v._ImgHpProgress :GetComponent(ClassType.Image).fillAmount = entity._InfoData._CurrentHp/entity._InfoData._MaxHp
            if entity:IsDead() or entity._InfoData._CurrentHp == 0 then 
                if self._TargetObj ~= nil and self._TargetObj._RoleID == roleId then
                    v._ImgTarget:SetActive(false)        
                    GameUtil.StopUISfx(PATH.UIFx_3V3Target,self._TargetObj._FrameHead)
                end
                v._ImgDead:SetActive(true)
                v._ListBuff:SetActive(false)
                local fxObjParent = v._ImgDead:FindChild("Img_Dead")
                GameUtil.PlayUISfx(PATH.UIFx_3V3Dead, fxObjParent, fxObjParent, -1)
            end
        return end
    end
    for i,v in ipairs(self._FrameBlue) do
        if v._RoleID == roleId then 
            local entity = game._CurWorld:FindObject(v._RoleID)
            if entity == nil then warn("roleId 蓝队 ===================  ",roleId) return end
            v._ImgHpProgress :GetComponent(ClassType.Image).fillAmount = entity._InfoData._CurrentHp/entity._InfoData._MaxHp
            if entity:IsDead() or entity._InfoData._CurrentHp == 0 then 
                if self._TargetObj ~= nil and self._TargetObj._RoleID == roleId then        
                    GameUtil.StopUISfx(PATH.UIFx_3V3Target,self._TargetObj._FrameHead)
                end
                local fxObjParent = v._ImgDead:FindChild("Img_Dead")
                v._ImgDead:SetActive(true)
                v._ListBuff:SetActive(false)
                GameUtil.PlayUISfx(PATH.UIFx_3V3Dead, fxObjParent, fxObjParent, -1)
            end
        return end
    end
end

-- 无畏战场和1v1属性更新
def.method("number").UpdatePlayerHpAndMp = function (self,roleId)
    if game._HostPlayer._ID == roleId then 
        local HpHost = self:GetUIObject('Bld_HPHostPlayer'):GetComponent(ClassType.GBlood)
        local MpHost = self:GetUIObject('Prg_FillRectHostPlayer'):GetComponent(ClassType.Image)
        local value1 = game._HostPlayer._InfoData._CurrentHp /game._HostPlayer._InfoData._MaxHp
        HpHost:SetValue(value1)
        local energy_type, cur_energy, max_energy = game._HostPlayer:GetEnergy()
        MpHost.fillAmount = cur_energy / max_energy
        GUI.SetText(self:GetUIObject("Lab_HPHostPlayer"),string.format(StringTable.Get(20061),game._HostPlayer._InfoData._CurrentHp,game._HostPlayer._InfoData._MaxHp))
    elseif self._CurOpenArenaType == EDungeonType.Type_JJC and  roleId > 0 then 
        local HpEnemy = self:GetUIObject("Bld_HPEnemy"):GetComponent(ClassType.GBlood)
        local MpEnemy = self:GetUIObject("Prg_FillRectEnemy"):GetComponent(ClassType.Image)
        local entity = game._CurWorld:FindObject(roleId)
        if entity ~= nil then
            local value2 = entity._InfoData._CurrentHp / entity._InfoData._MaxHp
            HpEnemy:SetValue(value2)
            local energy_type, cur_energy, max_energy = entity:GetEnergy()
            MpEnemy.fillAmount = cur_energy / max_energy
            GUI.SetText(self:GetUIObject("Lab_HPEnemy"),string.format(StringTable.Get(20061),entity._InfoData._CurrentHp,entity._InfoData._MaxHp))
        end
    elseif self._CurOpenArenaType == EDungeonType.Type_Eliminate and self._BattleCurEnemy~= nil and roleId == self._BattleCurEnemy._ID then 
         local HpEnemy = self:GetUIObject("Bld_HPEnemy"):GetComponent(ClassType.GBlood)
        local MpEnemy = self:GetUIObject("Prg_FillRectEnemy"):GetComponent(ClassType.Image)
        local value2 = self._BattleCurEnemy._InfoData._CurrentHp / self._BattleCurEnemy._InfoData._MaxHp
        HpEnemy:SetValue(value2)
        local energy_type, cur_energy, max_energy = self._BattleCurEnemy:GetEnergy()
        MpEnemy.fillAmount = cur_energy / max_energy
        GUI.SetText(self:GetUIObject("Lab_HPEnemy"),string.format(StringTable.Get(20061),self._BattleCurEnemy._InfoData._CurrentHp,self._BattleCurEnemy._InfoData._MaxHp))
    end
end

-- 3v3 更新在线状态
def.method("number").Update3V3MemberOffline = function(self,entityId)
    for i,v in ipairs(self._FrameRed) do
        if v._RoleID == entityId then 
            v._ImgLeave:SetActive(true)
            GameUtil.SetButtonInteractable(v._BtnPlayer, false)
        return end
    end
    for i,v in ipairs(self._FrameBlue) do
        if v._RoleID == entityId then 
            v._ImgLeave:SetActive(true)
            GameUtil.SetButtonInteractable(v._BtnPlayer, false)
        return end
    end
end

def.method('userdata').AddTimer = function (self,labTime)
    if self._TimerId ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end
    local time = ""
    local doTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    local callback = function()
        local nowTime = math.round((self._EndTime - GameUtil.GetServerTime())/1000)
        if nowTime >= 0 then 
            time = GUITools.FormatTimeFromSecondsToZero(false,nowTime)
            GUI.SetText(labTime,time)
            if nowTime <= 30 then 
                if self._CurOpenArenaType == EDungeonType.Type_Eliminate then 
                    doTweenPlayer:Restart("31")
                    doTweenPlayer:Restart("32")
                else
                    doTweenPlayer:Restart("21")
                    doTweenPlayer:Restart("22")
                end
            end
        elseif nowTime < 0 then 
            _G.RemoveGlobalTimer(self._TimerId)
            self._TimerId = 0
        end
    end
    self._TimerId = _G.AddGlobalTimer(1, false, callback)  
end

def.method("number").Update3V3HostPlayerTarget = function (self,targetId)

    if self._TargetObj ~= nil then 
        if self._TargetObj._RoleID ~= targetId then 
            GameUtil.StopUISfx(PATH.UIFx_3V3Target,self._TargetObj._FrameHead)
            self._TargetObj._ImgTarget:SetActive(false)
        else 
            return
        end
    end
    
    local targetFrameObj = self._FrameBlue
    if not self._IsRedHostPlayer then 
        targetFrameObj = self._FrameRed
    end

    for i,v in ipairs(targetFrameObj) do 
        if v._RoleID == targetId then 
            self._TargetObj = v 
            self._TargetObj._ImgTarget:SetActive(true)
            GameUtil.PlayUISfx(PATH.UIFx_3V3Target,v._FrameHead,v._FrameHead,-1)
            return
        end
    end
    self._TargetObj = nil 
end

def.method("table",CEntity).Init3V3BuffState = function(self,PlayerObj,entity)
    if PlayerObj == nil or entity == nil then 
        return 
    end

    local info = PlayerObj._ListBuff
    self:Clear(info)
    local curBuffList = entity:GetTopShowStates(3)
    local curBuffCnt = #curBuffList

    for i=1, self._3V3MaxBuff do
        local item = info:FindChild("item"..i-1)
        if IsNil(item) then warn("don't find this item" ..i-1 ) return end
        table.insert(PlayerObj._PositionList, item.localPosition)
        local bShow = curBuffCnt >= i
        if bShow then
            self:UpdateBuffinfo(PlayerObj,entity,curBuffList[i]._ID,true)
        end
    end
end

--无畏战场更换敌人
def.method(CEntity).ChangeBattleEnemy = function (self,target)
    self._BattleCurEnemy = target
    if target == nil or not target:CanBeSelected() or not target:IsPlayerType() then 
        self._FrameEnemy:SetActive(false)
    return end
    self._FrameEnemy:SetActive(true)
    InitBattleEnemyShowInfo(self,self._BattleCurEnemy)
end

def.method("table", CEntity,"number","boolean").UpdateBuffinfo = function(self, PlayerObj,entity,buffID, bIsAdd)
    if PlayerObj == nil or entity == nil then 
        return 
    end

    local curBuffList = entity:GetTopShowStates(3)
    local buffItem = self:GetBuffItem(PlayerObj,buffID)
    if buffItem ~= nil then
        if bIsAdd then
            --增加
            buffItem.Obj:SetActive(true)
            PlayerObj._BuffItemById[buffID] = buffItem
            local index = 1
            for i,v in pairs(curBuffList) do
                local buffInfo = PlayerObj._BuffItemById[v._ID]
                if buffInfo ~= nil then
                    buffInfo.Obj.localPosition = PlayerObj._PositionList[index]
                    index = index + 1
                    if v._ID == buffID then
                        GUITools.SetBuffIcon(buffInfo.Obj, v)
                        local bUpFlag = (v._StateType == EStateType.Buff or v._StateType == EStateType.DeBuff)
                        buffInfo.Img_UpOrDown:SetActive(bUpFlag)
                        if bUpFlag then
                            GUITools.SetGroupImg(buffInfo.Img_UpOrDown, v._StateType == EStateType.Buff and 1 or 0)
                        end
                        if v._StateLevel > 0 then
                            buffInfo.LabLv:SetActive(true)
                            GUI.SetText(buffInfo.LabLv, tostring(v._StateLevel))
                        else
                           buffInfo.LabLv:SetActive(false)
                        end
                    end
                    if i == 3 then 
                       PlayerObj._LastBuffID = v._ID 
                    end
                end
            end
        else
            --删除
            local index = 1
            buffItem.Obj:SetActive(false)
            PlayerObj._BuffItemById[buffID] = nil
            for i,v in pairs(curBuffList) do
                local buffInfo = PlayerObj._BuffItemById[v._ID]
                if buffInfo == nil then
                    buffInfo = self:GetBuffItem(PlayerObj,v._ID)
                    PlayerObj._BuffItemById[v._ID] = buffInfo
                    buffInfo.Obj:SetActive(true)
                    GUITools.SetBuffIcon(buffInfo.Obj, v)
                    local bUpFlag = (v._StateType == EStateType.Buff or v._StateType == EStateType.DeBuff)
                    buffInfo.Img_UpOrDown:SetActive(bUpFlag)
                    if bUpFlag then
                        GUITools.SetGroupImg(buffInfo.Img_UpOrDown, v._StateType == EStateType.Buff and 1 or 0)
                    end
                    if v._StateLevel > 0 then
                        buffInfo.LabLv:SetActive(true)
                        GUI.SetText(buffInfo.LabLv, tostring(v._StateLevel))
                    else
                       buffInfo.LabLv:SetActive(false)
                    end
                end
                buffInfo.Obj.localPosition = PlayerObj._PositionList[index]
                if i == 3 then 
                   PlayerObj._LastBuffID = v._ID 
                end
                index = index + 1
            end
        end
    end
end

def.method("table" ,"number","=>", "table").GetBuffItem = function(self,playerObj, buffId)
    if playerObj._BuffItemById[buffId] == nil then
        for i=1, self._3V3MaxBuff do
            local item = playerObj._ListBuff:FindChild("item"..i-1)
            if IsNil(item) then warn("don't find this item" ..i-1 ) return nil end
            if item.activeSelf == false then
                local buffItem = {}
                buffItem.Obj = item
                buffItem.Img_UpOrDown = buffItem.Obj:FindChild("Img_UpOrDown")
                buffItem.IsShow = true
                buffItem.LabLv =  buffItem.Obj:FindChild("Lab_Num")
                return buffItem
            end
        end
        playerObj._BuffItemById[buffId] = playerObj._BuffItemById[playerObj._LastBuffID]
        playerObj._BuffItemById[playerObj._LastBuffID] = nil
    end
    return playerObj._BuffItemById[buffId]
end

def.method("number","number","boolean").Update3V3Buff = function (self,entityId,buffId,isAdd)
    local playerObj = nil 
    local entity = nil 
    for i,v in ipairs(self._FrameRed) do 
        if v._RoleID == entityId then 
            playerObj = v
            entity = game._CurWorld:FindObject(entityId)
            break
        end
    end
    if playerObj == nil then 
        for i,v in ipairs(self._FrameBlue) do 
            if v._RoleID == entityId then 
                playerObj = v
                entity = game._CurWorld:FindObject(entityId)
                break      
            end
        end
    end
    self:UpdateBuffinfo(playerObj,entity,buffId,isAdd)
end

def.method("userdata").Clear = function(self,playerObj)
    if playerObj == nil then return end
    for i=1, self._3V3MaxBuff do
        local item = playerObj:FindChild("item"..i-1)
        if IsNil(item) then warn("don't find this item" ..i-1 ) return end
        item:SetActive(false)
    end
end

def.override().OnHide = function(self)
    self:UnlistenToEvent()
    for i,v in ipairs(self._FrameBlue) do 
        self:Clear(v._ListBuff)
    end
    for i,v in ipairs(self._FrameRed) do 
        self:Clear(v._ListBuff)
    end
    if self._CFrameBuffHost ~= nil then
        self._CFrameBuffHost:Destory()
        self._CFrameBuffHost = nil
    end

    if self._CFrameBuffEnemy ~= nil then
        self._CFrameBuffEnemy:Destory()
        self._CFrameBuffEnemy = nil
    end
    if self._TimerId ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end

    self._TargetObj = nil 

    self._RedDataList = nil 
    self._BlueDataList = nil 
    self._1V1EnemyEntity = nil 
end

def.override().OnDestroy = function(self)
    self:UnlistenToEvent()
    for i,v in ipairs(self._FrameBlue) do 
        self:Clear(v._ListBuff)
    end
    for i,v in ipairs(self._FrameRed) do 
        self:Clear(v._ListBuff)
    end

    if self._TimerId ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end

    self._FrameRed = nil
    self._FrameBlue = nil

    self._RedDataList = nil 
    self._BlueDataList = nil 
    self._ListBuffGroup1V1Enemy = nil 
    self._ListBuffGroup1V1Enemy = nil 

    if self._CFrameBuffHost ~= nil then
        self._CFrameBuffHost:Destory()
        self._CFrameBuffHost = nil
    end

    if self._CFrameBuffEnemy ~= nil then
        self._CFrameBuffEnemy:Destory()
        self._CFrameBuffEnemy = nil
    end

    self._Frame3V3 = nil
    self._Frame1V1AndBattle = nil
    self._LabTime1V1And3V3 = nil
    self._FrameHost = nil
    self._FrameEnemy = nil
    instance = nil 

end


CPanelPVPHead.Commit()
return CPanelPVPHead