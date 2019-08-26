local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CTransUtility = require "Transfer.CTransUtility"
local CTransStrategyBase = require "Transfer.CTransStrategyBase"

local CRightNowTrans = Lplus.Extend(CTransStrategyBase, "CRightNowTrans")
local def = CRightNowTrans.define

def.field('userdata')._AnimationTransPrefab  = nil                      -- 传送动画预设
def.field('userdata')._AnimationTransClip = nil                         -- 传送动画
def.field("number")._AnimationTimerID = 0                               -- 动画时间
def.field("number")._PortalID = 0                                       -- 传送门ID
def.field("number")._TransType = 0                                      -- 传送类型
def.field("table")._LandedRotation = nil                                -- 传送结束之后应该设置的朝向
def.field("number")._FinalMapID = -1
def.field("number")._LastSkillCastTime = 0                              -- 上次执行传送的时间戳

def.static("number", "dynamic", "dynamic", "=>", CRightNowTrans).new = function(transType, rotation, finalMapID)
    local obj = CRightNowTrans()
    obj._TransType = transType
    obj._LandedRotation = rotation
    obj._FinalMapID = finalMapID
    return obj
end

def.method("number", "table", "number").ReSetData = function(self, transType, rot, finalMapID)
    self._TransType = transType
    self._LandedRotation = rot
    self._FinalMapID = finalMapID
end

def.override().StartTransLogic = function(self)
	if game._RegionLimit._LimitLeave then
        self._IsTransOver = true
		game._GUIMan:ShowTipText(StringTable.Get(12014), false)
		return
	end

    self._IsTransOver = false
    game._GUIMan:Close("CPanelMap")
    
    local CQuestAutoMan = require"Quest.CQuestAutoMan"
    local CAutoFightMan = require "AutoFight.CAutoFightMan"

    CAutoFightMan.Instance():Pause(_G.PauseMask.WorldMapTrans)
    CQuestAutoMan.Instance():Pause(_G.PauseMask.WorldMapTrans)

    local host = game._HostPlayer
	local hostskillhdl = host._SkillHdl
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local skill_id = CSpecialIdMan.Get("WorldMapTranform")
	hostskillhdl:CastSkill(skill_id, false)		
	hostskillhdl:RegisterCallback(false, function(ret)
        CAutoFightMan.Instance():Restart(_G.PauseMask.WorldMapTrans)
        CQuestAutoMan.Instance():Restart(_G.PauseMask.WorldMapTrans)
        if not ret then return end
        if self._TransType == EnumDef.ETransType.TransToWorldMap then
		    local C2SWorldMapTrans = require "PB.net".C2SWorldMapTrans
		    local msg = C2SWorldMapTrans()
		    msg.MapID = self._MapID
		    local PBHelper = require "Network.PBHelper"
		    PBHelper.Send(msg)
        elseif self._TransType == EnumDef.ETransType.TransToPortal then
            local C2SNpcTrans = require "PB.net".C2SNpcTrans
		    local msg = C2SNpcTrans()
		    msg.TransID = self._MapID
		    local PBHelper = require "Network.PBHelper"
		    PBHelper.Send(msg)
        elseif self._TransType == EnumDef.ETransType.TransToInstance then
            game._DungeonMan:TryEnterDungeon(self._MapID)
        end
    end)
end

def.override().BrokenTrans = function(self)
    if not game._HostPlayer:GetTransPortalState() then return end
    --print("传送打断", debug.traceback())
	if self._AnimationTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._AnimationTimerID)
		self._AnimationTimerID = 0
	end
    game._HostPlayer:SetTransPortalState(false)
    self._IsTransOver = true
end

def.method("number").SetTransPortalID = function(self, portalID)
    self._PortalID = portalID
end

def.method("number").SetTransType = function(self, transType)
    self._TransType = transType
end

def.method("table").SetLandedRotation = function(self, rot)
    self._LandedRotation = rot
end

--往服务器发送传送门的协议
def.method("number").C2STransToPortal = function(self, ntransID)
	local protocol = (require "PB.net".C2SNpcTrans)()
   	protocol.TransID = ntransID
   		 
   	local PBHelper = require "Network.PBHelper"
   	PBHelper.Send(protocol)
end

def.override().ContinueTrans = function(self)
    local hp = game._HostPlayer
    
    if self._FinalMapID > 0 then
        hp: SetTransPortalState(false)
        CTransStrategyBase.RaiseEvent(self, self._FinalMapID, self._FinalPosition)
        self._TransMan:StartMoveByMapIDAndPos(self._FinalMapID, self._FinalPosition, nil, self._TransMan:IsSearchNpc(), self._TransMan._IsIgnoreConnected)
        self._FinalMapID = -1
        return
    end

    if self._TransType == EnumDef.ETransType.TransToWorldMap and self._MapID ~= game._CurWorld._WorldInfo.SceneTid then
        --print("self._MapID, game._CurWorld._WorldInfo.SceneTid ", self._MapID, game._CurWorld._WorldInfo.SceneTid )
        hp: SetTransPortalState(false)
        CTransStrategyBase.RaiseEvent(self, self._MapID, self._FinalPosition)
        self._TransMan:StartMoveByMapIDAndPos(self._MapID, self._FinalPosition, nil, self._TransMan:IsSearchNpc(), self._TransMan._IsIgnoreConnected)
        return
    end
    self._TargetPosition = self._FinalPosition

    if self._FinalPosition ~= nil then
        local function callback()
            if self._CallBack ~= nil then 
                self._CallBack()
                self._CallBack = nil
            end
            self:BrokenTrans()
        end
        local is_search_npc = self._TransMan:IsSearchNpc()

	    hp:HaveTransOffset(is_search_npc)
        hp:SetAutoPathFlag(true)  
        if hp:CheckAutoHorse(self._TargetPosition) then 
		    hp:NavMountHorseLogic(self._TargetPosition)
        end
        CTransStrategyBase.RaiseEvent(self, self._MapID, self._FinalPosition)
        TeraFuncs.NavigatToPos(self._FinalPosition, 0, callback, nil)
    end
end

def.override().Release = function(self)
    self._AnimationTransPrefab = nil
    self._AnimationTransClip = nil
    self._AnimationTimerID = 0
    self._LastSkillCastTime = 0
    self._PortalID = 0
    CTransStrategyBase.Release(self)
end

CRightNowTrans.Commit()
return CRightNowTrans