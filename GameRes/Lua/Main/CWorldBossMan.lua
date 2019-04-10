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

def.field("table")._Table_WorldBoss = BlankTable
def.field("table")._Table_EliteBoss = BlankTable
def.field("number")._WorldBossDropCount = -1
def.field("boolean")._WorldBossRedPointmark = true

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

--加载所有世界boss数据
def.method().LoadAllWorldBossData = function(self)
	local allWorldBoss = GameUtil.GetAllTid("WorldBossConfig")
    self._Table_WorldBoss = {}
    for _,v in pairs(allWorldBoss) do
        if v > 0 then
            local WorldBossData = CElementData.GetTemplate("WorldBossConfig", v)      
            if WorldBossData ~= nil then
                self._Table_WorldBoss[#self._Table_WorldBoss + 1] =
                {
                    _Data = WorldBossData,--模板数据
                    _BossID = 0,
                    _Reason = BossState.DEFAULT,
                    _OpenTime = "", --开启时间                    
                    _CloseTime = "", --关闭时间
                    _Isopen = false, --Boss是否开启
                    _IsDeath = true, --Boss是否死亡
                    _GuildName = "",
                    _RoleName = "",
                }				
            else
                warn("世界Boss数据错误ID："..v)
            end	
        end
    end

    local allEliteBoss = GameUtil.GetAllTid("EliteBossConfig")
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

--------------------------S2C-----------------------------

--更新世界Boss数据
def.method("table").ChangeWorldBossState = function(self, msg)
	if msg == nil then return end
	for _,v in pairs(self._Table_WorldBoss) do
		for _,k in pairs(msg.data) do
			if v._Data.Id == k.ActivityId then   
                -- warn("!!!!!!!!!!!!!!!S2CChangeWorldBossState k.BossTId == ", k.BossTId)             
                v._BossID = k.BossTId
				v._OpenTime = k.OpenTime	
                v._CloseTime = k.CloseTime
                v._IsDeath = k.IsDeath
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

                    if v._GuildName == "" or v._GuildName == nil then
                        local strName =  RichTextTools.GetElsePlayerNameRichText(v._RoleName,false)
                        game._GUIMan:OpenSpecialTopTips(string.format(StringTable.Get(21013), v._Data.Name, strName, msg.LastShotEntityName))
                    else
                        -- 13015 公会
                        local strName =  RichTextTools.GetGuildNameRichText(v._GuildName,false)
                        local GuildName = strName.. StringTable.Get(13015)
                        -- warn(string.format(StringTable.Get(21010), GuildName, v._Data.Name))
                        game._GUIMan:OpenSpecialTopTips(string.format(StringTable.Get(21013), v._Data.Name, GuildName, msg.LastShotEntityName))
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
                -- warn("S2CEliteBossMapStateInfo k.BossTId == ", k.BossTid, k.IsDeath)             
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
------------------------------------------------------

--获取所有世界Boss
def.method("=>","table").GetAllWorldBossContents = function(self)
    -- warn("getallworldboss   self._Table_WorldBoss == ", #self._Table_WorldBoss)
	return self._Table_WorldBoss
end

--通过bossID获取对应boss状态
def.method("number","=>","table").GetWorldBossByID = function(self, nID)
    for _,v in pairs(self._Table_WorldBoss) do
        -- warn("vvvvvvvvvvvvvvvvvvvvvv._BossID ===>>>", v._BossID)
		if v._Data.WorldBossTid == nID then
            return v 
        end
	end
	return nil
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


CWorldBossMan.Commit()
return CWorldBossMan