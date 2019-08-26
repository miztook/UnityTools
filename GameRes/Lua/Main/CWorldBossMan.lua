--------------------------------------------
---------------世界Boss消息处理  by:lidaming
--------------------------------------------


local Lplus = require "Lplus"
local CWorldBossMan = Lplus.Class("CWorldBossMan")
local def = CWorldBossMan.define
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local OperatorType = require "PB.net".S2CWorldBossState.OperatorType
local MapBasicConfig = require "Data.MapBasicConfig"

def.field("table")._Table_WorldBoss = nil
def.field("table")._Table_EliteBoss = nil
def.field("table")._Table_WorldBossLineState = nil  -- 世界boss分线状态
def.field("number")._WorldBossDropCount = -1
def.field("boolean")._WorldBossRedPointmark = true

def.field("number")._WorldBossNextOpenTime = -1

def.static("=>", CWorldBossMan).new = function()
    local obj = CWorldBossMan()
	return obj
end

local BossState =
{
    DEFAULT = 0, -- 默认
	OPEN 	= 1, -- 开启
    CLOSE	= 2, -- 关闭
    DEATH	= 3, -- Boss死亡
}

local function sort_func_by_sortindex(a, b)
    if a._LineId ~= b._LineId then
        -- 根据解锁等级从小到大
        return a._LineId < b._LineId
    end
    return a._BossTID < b._BossTID
end

--加载所有世界boss数据
def.method().Init = function(self)
    if self._Table_WorldBoss ~= nil then return end
     
	local allWorldBoss = CElementData.GetAllTid("WorldBossConfig")
    self._Table_WorldBoss = {}
    self._Table_WorldBossLineState = {}
    for _,v in pairs(allWorldBoss) do
        if v > 0 then
            local WorldBossData = CElementData.GetTemplate("WorldBossConfig", v)      
            if WorldBossData ~= nil then
                self._Table_WorldBoss[#self._Table_WorldBoss + 1] =
                {
                    _Data = WorldBossData,--模板数据
                    _BossID = 0,
                    _Reason = BossState.DEFAULT,
                    _OpenTime = 0, --开启时间                    
                    _CloseTime = 0, --关闭时间
                    _NextOpenTime = 0, --开启时间 
                    _Isopen = false, --Boss是否开启
                    _IsDeath = true, --Boss是否死亡
                    _GuildName = "",
                    _RoleName = "",
                    _LineId = 0,
                }
            else
                warn("世界Boss数据错误ID："..v)
            end	
        end
    end

    local allEliteBoss = CElementData.GetAllTid("EliteBossConfig")
    self._Table_EliteBoss = {}
    for _,v in pairs(allEliteBoss) do
        if v > 0 then
            local EliteBossData = CElementData.GetTemplate("EliteBossConfig", v)      
            if EliteBossData ~= nil then
                self._Table_EliteBoss[#self._Table_EliteBoss + 1] =
                {
                    _Data = EliteBossData,--模板数据
                    _BossID = 0,
                    _BossLeftDropCount = 0, --Boss掉落次数
                    _IsDeath = true, --Boss是否死亡
                }				
            else
                warn("世界Boss数据错误ID："..v)
            end	
        end
    end
end

------------------C2S----------------------------
-- 请求精英Boss剩余击杀奖励信息
def.method().SendC2SEliteBossKillStateInfo = function(self)
	local C2SEliteBossKillStateInfo = require "PB.net".C2SEliteBossKillStateInfo
	local protocol = C2SEliteBossKillStateInfo()
	PBHelper.Send(protocol)
end

-- 请求精英Boss地图状态信息
def.method("boolean", "number").SendC2SEliteBossMapStateInfo = function(self, IsCurMap, MapTid)
	local C2SEliteBossMapStateInfo = require "PB.net".C2SEliteBossMapStateInfo
	local protocol = C2SEliteBossMapStateInfo()
    protocol.IsCurrentMap = IsCurMap
    protocol.MapTid = MapTid
	PBHelper.Send(protocol)
end

-- 请求世界Boss下次开启时间
def.method().SendC2SWorldBossNextOpenTime = function(self)
	local C2SScriptNextOpenTime = require "PB.net".C2SScriptNextOpenTime
    local protocol = C2SScriptNextOpenTime()
    local ScriptId = tonumber(CElementData.GetTemplate("SpecialId", 423).Value)
    protocol.ScriptId = ScriptId
	PBHelper.Send(protocol)
end

--------------------------S2C-----------------------------

--更新世界Boss数据
def.method("table").ChangeWorldBossState = function(self, msg)
    if msg == nil then return end

    for _,k in pairs(msg.data) do
        if k.BossTId ~= nil and k.LineId ~= nil then
            if #self._Table_WorldBossLineState <= 0 then
                self._Table_WorldBossLineState[#self._Table_WorldBossLineState + 1] = 
                {
                    _BossTID = k.BossTId,
                    _LineId = k.LineId,
                    _IsDeath = k.IsDeath,
                }
            else
                local isAdd = true
                for _,LineBossState in pairs(self._Table_WorldBossLineState) do
                    if LineBossState._BossTID == k.BossTId and LineBossState._LineId == k.LineId then
                        LineBossState._IsDeath = k.IsDeath
                        isAdd = false
                    end
                end
                if isAdd then
                    self._Table_WorldBossLineState[#self._Table_WorldBossLineState + 1] = 
                    {
                        _BossTID = k.BossTId,
                        _LineId = k.LineId,
                        _IsDeath = k.IsDeath,
                    }
                end
            end
        end
    end


	for _,v in pairs(self._Table_WorldBoss) do
		for _,k in pairs(msg.data) do
            if v._Data.Id == k.ActivityId then
				v._OpenTime = k.OpenTime	
                v._CloseTime = k.CloseTime
                v._NextOpenTime = k.NextOpenTime
                v._Reason = msg.OptType
                v._GuildName = msg.GuildName	
                v._RoleName = msg.RoleName	
				if v._Reason == OperatorType.Open then
                    v._Isopen = true 
                elseif v._Reason == OperatorType.Close then
                    v._Isopen = false
                elseif v._Reason == OperatorType.Death then     
                    -- v._Isopen = false
                    -- warn("ChangeWorldBossState WorldBoss Death !!!")
                    --%s被%s讨伐成功
                    local ChatMsg = ""
                    if v._GuildName == "" or v._GuildName == nil then
                        local strName =  RichTextTools.GetElsePlayerNameRichText(v._RoleName,false)
                        local lastShotEntity = msg.LastShotEntityName
                        if lastShotEntity == nil then
                            lastShotEntity = strName
                        end
                        ChatMsg = string.format(StringTable.Get(21013), tostring(k.LineId), v._Data.Name, strName, lastShotEntity)
                        
                    else
                        -- 13015 公会
                        local strName =  RichTextTools.GetGuildNameRichText(v._GuildName,false)
                        local GuildName = strName.. StringTable.Get(13015)
                        -- warn(string.format(StringTable.Get(21010), GuildName, v._Data.Name))
                        local lastShotEntity = msg.LastShotEntityName
                        if lastShotEntity == nil then
                            lastShotEntity = GuildName
                        end
                        ChatMsg = string.format(StringTable.Get(21013), tostring(k.LineId), v._Data.Name, GuildName, msg.LastShotEntityName)
                    end

                    if ChatMsg ~= "" then
                        game._GUIMan:OpenSpecialTopTips(ChatMsg)

                        local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
                        local ChatManager = require "Chat.ChatManager"
                        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, ChatMsg, false, 0, nil,nil)
                    end
                elseif v._Reason == OperatorType.Init then
                    if k.IsDeath == true then
                        v._Isopen = false
                    else
                        v._Isopen = true
                    end
                end     
			end
		end
    end

    table.sort(self._Table_WorldBossLineState, sort_func_by_sortindex)

    for _,v in pairs(self._Table_WorldBoss) do
        v._IsDeath = true
        for _,k in pairs(self._Table_WorldBossLineState) do
            if v._Data.WorldBossTid == k._BossTID then
                v._BossID = k._BossTID
                v._IsDeath = k._IsDeath and v._IsDeath
                if not k._IsDeath then
                    v._LineId = k._LineId
                end
            end
        end
    end

    self:UpdateBossRedPoint()
end

def.method("table").SetWorldBossPersonalLeftDropCount = function(self, msg)
    if msg == nil then return end
    --warn("GetWorldBossDropCount   self._WorldBossDropCount == ", msg.WorldBossDropCountInfoList[1].LeftDropCount)
    self._WorldBossDropCount = msg.WorldBossDropCountInfoList[1].LeftDropCount
end

def.method("table").ChangeEliteBossKillState = function(self, msg)
    if msg == nil then return end
    for _,v in pairs(self._Table_EliteBoss) do
		for _,k in pairs(msg.EliteBossInfoList) do
			if v._Data.EliteBossTid == k.BossTid then   
                -- warn("S2CEliteBossKillStateInfo k.BossTId == ", k.BossTid, k.BossLeftDropCount)             
                v._BossID = k.BossTid
				v._BossLeftDropCount = k.BossLeftDropCount                
			end
        end
    end
    self:UpdateBossRedPoint()
end

def.method("table").ChangeEliteBossMapState = function(self, msg)
    if msg == nil then return end
    for _,v in pairs(self._Table_EliteBoss) do
		for _,k in pairs(msg.EliteBossInfoList) do
			if v._Data.EliteBossTid == k.BossTid then            
                v._BossID = k.BossTid
				v._IsDeath = k.IsDeath                
			end
        end
    end

    local CPanelMap = require "GUI.CPanelMap".Instance()
    if CPanelMap and CPanelMap:IsShow() then
        CPanelMap:UpdateMapBossState()
    end
end

def.method("number").ChangeWorldBossNextOpenTime = function(self, msg)
    if msg == nil then return end
    self._WorldBossNextOpenTime = msg
end
------------------------------------------------------

--获取所有世界Boss
def.method("=>","table").GetAllWorldBossContents = function(self)
    -- warn("getallworldboss   self._Table_WorldBoss == ", #self._Table_WorldBoss)
	return self._Table_WorldBoss
end

--通过bossID, 和当前线路获取对应boss状态
def.method("number","number","=>", "boolean", "table").GetWorldBossByID = function(self, lineID, nID)
    for _,v in pairs(self._Table_WorldBoss) do
        if v._BossID == nID then
            return true, v._Data
        end
    end
	return false, nil
end

--通过bossID, 和当前线路获取对应boss状态
def.method("number","number","=>", "boolean").GetWorldBossByLineAndID = function(self, lineID, nID)
    for _,v in pairs(self._Table_WorldBossLineState) do
        if v._LineId == lineID and v._BossTID == nID then
            return v._IsDeath
        end
	end
	return true
end

--通过bossID, 和当前线路获取对应boss活着的线路
def.method("number","number","=>", "number").GetLineByCurLineAndID = function(self, lineID, nID)
    for _,v in pairs(self._Table_WorldBossLineState) do
        if v._LineId ~= lineID and v._BossTID == nID and not v._IsDeath then
            return v._LineId
        end
	end
	return 0
end

--获取世界Boss是否有开启
def.method("=>","boolean").GetWorldBossOpen = function(self)
    -- warn("getallworldboss   self._Table_WorldBoss == ", #self._Table_WorldBoss)
    for _,v in pairs(self._Table_WorldBoss) do
		if v._Isopen == true then
            return true
        end
	end
	return false
end

--获取所有精英Boss
def.method("=>","table").GetAllEliteBossContents = function(self)
    -- warn("GetAllEliteBossContents   self._Table_EliteBoss == ", #self._Table_EliteBoss)
	return self._Table_EliteBoss
end

--通过精英BossID获取对应boss状态
def.method("number","=>","table").GetEliteBossByID = function(self, nID)
    for _,v in pairs(self._Table_EliteBoss) do
		if v._Data.EliteBossTid == nID then
            return v 
        end
	end
	return nil
end

def.method("=>","number").GetWorldBossDropCount = function(self)
    -- warn("GetWorldBossDropCount   self._WorldBossDropCount == ", self._WorldBossDropCount)
	return self._WorldBossDropCount
end

def.method("=>","number").GetWorldBossNextOpenTime = function(self)
    -- warn("GetWorldBossDropCount   self._WorldBossDropCount == ", self._WorldBossDropCount)
	return self._WorldBossNextOpenTime
end

-- 获取精英boss红点状态
def.method("=>", "boolean").GetEliteBossRedPointState = function(self)
    for _,v in pairs(self._Table_EliteBoss) do
        if v._BossLeftDropCount == 0 then
            return false
        end
    end
    return true
end

-- 获取世界boss红点状态
def.method("=>", "boolean").GetWorldBossRedPointState = function(self)
    local worldBossFuncTid = 94 -- 世界Boss教学功能TID
    if not game._CFunctionMan:IsUnlockByFunTid(worldBossFuncTid) then
        return false
    end

    local ActivityOpen = false
    for _,v in pairs(self._Table_WorldBoss) do
        if v._Isopen == true then
            ActivityOpen = true
            break
        end
    end
    if ActivityOpen and self._WorldBossDropCount == 1 then
        return true
    end
    return false
end

-- 刷新主界面boss红点
def.method().UpdateBossRedPoint = function(self)    
    local state = false
    if self:GetWorldBossRedPointState() and self._WorldBossRedPointmark then
        state = true
    else
        state = false
    end
    local mainBossRedPoint = false
    if state or self:GetEliteBossRedPointState() then
        mainBossRedPoint = true
    end
    local CPanelUIBuffEnter = require "GUI.CPanelUIBuffEnter".Instance()
    if CPanelUIBuffEnter:IsShow() then
        local img_RedPoint = CPanelUIBuffEnter:GetUIObject("Frame_ToolBar"):FindChild("Btn_WorldBoss/Img_Icon/Img_RedPoint")
        if img_RedPoint == nil then return end
        img_RedPoint:SetActive(mainBossRedPoint)
    end
  
end

def.method().Cleanup = function(self)
    self._Table_WorldBoss = nil
    self._Table_EliteBoss = nil
    self._WorldBossDropCount = -1
    self._WorldBossRedPointmark = true
    self._WorldBossNextOpenTime = -1
end

CWorldBossMan.Commit()
return CWorldBossMan