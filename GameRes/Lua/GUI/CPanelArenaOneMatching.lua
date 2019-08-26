local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CUIModel = require "GUI.CUIModel"
local CElementData = require "Data.CElementData"
local EJJC1x1State = require "PB.net".S2CJJC1x1State.EJJC1x1State

local CPanelArenaOneMatching = Lplus.Extend(CPanelBase, 'CPanelArenaOneMatching')
local def = CPanelArenaOneMatching.define

def.field("userdata")._FrameHostPlayer = nil 
def.field("userdata")._FrameEnemy = nil 
def.field(CUIModel)._Model4ImgRender1 = nil
def.field(CUIModel)._Model4ImgRender2 = nil
def.field("userdata")._ImgRole1 = nil 
def.field("userdata")._ImgRole2 = nil 
def.field("userdata")._ImgBg = nil 
def.field("table")._RivalData = nil 
def.field("number")._TimerID = 0

local instance = nil
def.static('=>', CPanelArenaOneMatching).Instance = function ()
	if not instance then
        instance = CPanelArenaOneMatching()
        instance._PrefabPath = PATH.UI_ArenaOneMatching
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end

-- 1V1初始化对手信息
local function InitRivalDataInfo(self,data)
    self._RivalData = {}
    local CreatureInfo = data.MirroInfo.MonsterInfo.CreatureInfo
    self._RivalData.FightScore = data.FightScore
    self._RivalData.Level = CreatureInfo.Level
    self._RivalData.Score = data.JJCScore
    self._RivalData.Rank = data.Rank 
    self._RivalData.Prof = data.MirroInfo.ProfessionId
    self._RivalData.OriginParam = data.MirroInfo.OriginParam 
    if self._RivalData.OriginParam < 0 then 
        local TextTemp = CElementData.GetTextTemplate(tonumber(CreatureInfo.Name))
        self._RivalData.Name = TextTemp.TextContent
    else
        self._RivalData.Name = CreatureInfo.Name
    end
    self._RivalData.ID = CreatureInfo.MovableInfo.EntityInfo.EntityId
    self._RivalData.Gender = Profession2Gender[self._RivalData.Prof]
    self._RivalData.CustomImgSet = data.MirroInfo.Exterior.CustomImgSet
    self._RivalData.CurrentHp = CreatureInfo.CurrentHp
    self._RivalData.MaxHp = CreatureInfo.MaxHp
    self._RivalData.MaxMana = CreatureInfo.MaxMana
    self._RivalData.CurrentMana = CreatureInfo.CurrentMana
end

local function ShowRoleInfo(self,obj,data)
    local labName = obj:FindChild("Lab_Name")   
    GUI.SetText(labName,data.Name)

    local labFightScore_Data = obj:FindChild("Lab_FightScore_Data")
    GUI.SetText(labFightScore_Data,GUITools.FormatNumber(data.FightScore))
    local labRank = obj:FindChild("Lab_Rank")
    local labPoint = obj:FindChild("Lab_Point")
    local labLevel = obj:FindChild("Lab_Level")
    GUI.SetText(labLevel,string.format(StringTable.Get(20053),data.Level))
    if data.Rank == 0 then 
        GUI.SetText(labRank,StringTable.Get(20103))
    else
        GUI.SetText(labRank,tostring(data.Rank))
    end
    GUI.SetText(labPoint,tostring(data.Score))
end

--1V1匹配中
local function OnMatching(self)
    ShowRoleInfo(self,self._FrameHostPlayer,game._CArenaMan._1V1HostData)
    self._Model4ImgRender1 = GUITools.CreateHostUIModel(self._ImgRole1, EnumDef.RenderLayer.UI,nil,EnumDef.UIModelShowType.NoWing)
    self._Model4ImgRender1:AddLoadedCallback(function() 
        self._Model4ImgRender1:SetModelParam(self._PrefabPath, game._HostPlayer._InfoData._Prof)
    end)

    do
        GameUtil.PlayUISfx(PATH.UIFX_JJC_BG_FX, self._ImgBg, self._ImgBg, -1)
    end
end

--添加倒计时（临时）
local function AddGlobalTimer(self)
    local CPanelTracker = require "GUI.CPanelTracker"
    CPanelTracker.Instance():ResetDungeonShow()
    local timer_id = 0
    local time = 0
    local callback = function()
        time = time + 1
        if time == 5 then
            CPanelTracker.Instance():OpenDungeonUI(true)
            _G.RemoveGlobalTimer(timer_id)
            timer_id = 0
            game._DungeonMan:SetDungeonID(game._DungeonMan:Get1v1WorldTID())
            if self:IsShow() then 
                game._GUIMan:CloseByScript(self)
                game._GUIMan:Close("CPanelMirrorArena")
            end
        end
    end
    timer_id = _G.AddGlobalTimer(1, false, callback)
end

--添加倒计时（当无法接受到服务器返回匹配消息后直接关闭界面 没有成功进入1v1）
local function AddClosePanelTimer(self)
    local time = 0
    self._TimerID = 0
    local callback = function()
        time = time + 1
        if time == 8 then
            _G.RemoveGlobalTimer(self._TimerID)
            self._TimerID = 0
            if self:IsShow() then 
                game._GUIMan:CloseByScript(self)
            end
        end
    end
    self._TimerID = _G.AddGlobalTimer(1, false, callback)
end 

--1V1匹配成功
local function OnSuccess(self, data)
    self._FrameEnemy:SetActive(true)
    InitRivalDataInfo(self,data)
    ShowRoleInfo(self,self._FrameEnemy,self._RivalData)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena1V1Match, 0)  

    local ModelParams = require "Object.ModelParams"
    local params = ModelParams.new()
    params:MakeParam(data.MirroInfo.Exterior, data.MirroInfo.ProfessionId)
    if self._Model4ImgRender2~= nil then
        self._Model4ImgRender2:Destroy()
    end 
    self._Model4ImgRender2 = CUIModel.new(params, self._ImgRole2, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)
    
    self._Model4ImgRender2:AddLoadedCallback(function()
            self._Model4ImgRender2:SetModelParam(self._PrefabPath, data.MirroInfo.ProfessionId)
            self._ImgRole2:SetActive(true)
        end)
    AddGlobalTimer(self)
    do  --添加UI特效
        GameUtil.PlayUISfx(PATH.UIFX_JJC_VS_FX, self._FrameEnemy, self._FrameEnemy, -1)
    end
end

--1V1匹配失败返回到主界面
local function OnFailed(self)
   game._GUIMan:CloseByScript(self)
   game._CArenaMan:SendC2SOpenOne()
end

def.override().OnCreate = function(self)
    self._FrameHostPlayer = self:GetUIObject("Frame_HostPlayer")
	self._FrameEnemy = self:GetUIObject("Frame_Enemy")
    self._ImgRole1 = self:GetUIObject("Img_Role_1")
    self._ImgRole2 = self:GetUIObject("Img_Role_2")
    self._ImgBg = self:GetUIObject("Img_Bg")
end

def.override("dynamic").OnData = function(self,data)
    self._FrameEnemy:SetActive(false)
    OnMatching(self)
    AddClosePanelTimer(self)
end

def.method("table").UpdateState = function(self,data)
    if not self:IsShow() then return end
    if self._TimerID > 0 then 
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0
    end
    if data.State == EJJC1x1State.Success then
        OnSuccess(self,data)
    elseif data.State == EJJC1x1State.Failed then
        OnFailed(self)
    end 
end

def.override().OnDestroy = function(self)
    if self._Model4ImgRender1 then
        self._Model4ImgRender1:Destroy()
        self._Model4ImgRender1 = nil
    end
    if self._Model4ImgRender2 then
        self._Model4ImgRender2:Destroy()
        self._Model4ImgRender2 = nil
    end
    if self._TimerID > 0 then 
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0
    end
    instance = nil 

    self._FrameHostPlayer = nil
    self._FrameEnemy = nil
    self._ImgRole1 = nil
    self._ImgRole2 = nil
    self._ImgBg = nil
end

CPanelArenaOneMatching.Commit()
return CPanelArenaOneMatching