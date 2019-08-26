local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local MapBasicConfig = require "Data.MapBasicConfig" 
local PBHelper = require "Network.PBHelper"
local CQuest = require "Quest.CQuest"

local CHawkeyeEffectMan = Lplus.Class("CHawkeyeEffectMan")
local def = CHawkeyeEffectMan.define

def.field("boolean")._IsHawkEyeEnable = false --是否鹰眼可以使用
def.field("boolean")._IsHawkEyeState = false --是否鹰眼开启
def.field("boolean")._IsHawkEyeEffectIsOver = true --是否鹰眼过度效果是否结束
def.field("number")._HawkEyeCount = 0
def.field("table")._TableHawkEyeTargetPos = nil

local instance = nil
def.static("=>", CHawkeyeEffectMan).Instance = function ()
	if instance == nil then
		instance = CHawkeyeEffectMan()
	end	
	return instance
end

def.method("boolean","number").EnableHawkeyeState = function (self,isEnable,time)
    if self._IsHawkEyeState == isEnable then
    	return 
    end
    if isEnable then
		self._HawkEyeCount = self._HawkEyeCount - 1
	    self._IsHawkEyeState = true
	    self._IsHawkEyeEffectIsOver = true

		game:PlayHawkeyeEffect()

		--效果更改
		local CVisualEffectMan = require "Effects.CVisualEffectMan"
		CVisualEffectMan.EnableHawkeyeEffect(true)

		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Eyes, 0)
		EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeActive,{useTime = time})
	else
		if self._IsHawkEyeState then
		    self._IsHawkEyeState = false
		    self._IsHawkEyeEffectIsOver = true
		    --效果更改
		    local CVisualEffectMan = require "Effects.CVisualEffectMan"  
			CVisualEffectMan.EnableHawkeyeEffect(false)   

			EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeDeactive,nil)
		end
	end
end

def.method("number", "table").UpdateHawkeyeInfo = function (self, remainCount, regions)
	self._HawkEyeCount = remainCount

	self._TableHawkEyeTargetPos = {}
	local mapId = game._CurWorld._WorldInfo.SceneTid
	local regionInfo = MapBasicConfig.GetMapBasicConfigBySceneID(mapId).Region
	for k,v in ipairs(regions) do
		if v.regionId and v.regionId > 0 and regionInfo[2] ~= nil and regionInfo[2][v.regionId] ~= nil and v.hawkeyeType ~= 0 then
			self._TableHawkEyeTargetPos[v.regionId] = { pos=Vector3.New(v.posx,0,v.posz), hawkeyeType=v.hawkeyeType, status=v.status }
		end
	end
end

def.method("number").RemoveHawkeyeRegion = function (self,regionId)
	if self._TableHawkEyeTargetPos ~= nil then
		self._TableHawkEyeTargetPos[regionId] = nil
	end
end

def.method().UpdateHawkeye = function (self)
	if self._IsHawkEyeEnable then
		local protocol = (require "PB.net".C2SHawkeyeInfo)()
		PBHelper.Send(protocol)
	else
		EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeClose,nil)
	end	
end

local function IsQuestOk(questId)
	if questId <= 0 then return true end

	return CQuest.Instance():IsQuestInProgress(questId) 
		or CQuest.Instance():IsQuestReady(questId) 
		or CQuest.Instance():IsQuestInProgressBySubID(questId) 
		or CQuest.Instance():IsQuestReadyBySubID(questId) 
end

--参数为是否变更区域判断 还是任务更新原地判断
def.method('boolean').JudgeIsUseHawEye = function (self,isChangeRegion)
	--如果不是区域变更询问，是任务变更询问，并且鹰眼按钮正在开启。则跳出。由玩家手动关闭
	if not isChangeRegion and self._IsHawkEyeEnable then
		return
	end

	local game = game
	local world = game._CurWorld

	local mapTid = world._WorldInfo.MapTid
	local map = CElementData.GetMapTemplate(mapTid)
	--如果地图不是鹰眼地图 则不允许使用
	if map.IsCanHawkeye == nil or not map.IsCanHawkeye then
		self._IsHawkEyeEnable = false
		self:UpdateHawkeye()
		return
	end

	local sceneId = world._WorldInfo.SceneTid
	local scene = MapBasicConfig.GetMapBasicConfigBySceneID(sceneId)
	if scene == nil then
		warn("Can not find scene data with id ==", sceneId, debug.traceback())
		return
	end

	--判断万武志是否开启（开启条件之一）
	local function Hawkeye_callback(isEnable)
		self._IsHawkEyeEnable = isEnable
		self:UpdateHawkeye()
	end

	local regions = scene.Region
	local currentRegionIds = game._HostPlayer._CurrentRegionIds
	--如果区域是鹰眼区域 则允许使用
	for i,v in ipairs(currentRegionIds) do
		for j,w in pairs(regions) do
			for k, x in pairs(w) do
				if v == k then
					local noQuestLimit = (x.QuestID == nil)
					local isQuestOk = false
					if not noQuestLimit then
						for i,v in ipairs(x.QuestID) do
							isQuestOk = IsQuestOk(v)
							if isQuestOk == true then
								break
							end
						end
					end

					if x.IsCanHawkeye ~= nil and x.IsCanHawkeye and (noQuestLimit or isQuestOk) then
						local ids = x.ManualID
						--如果没有配置解锁条件
						if x.ids == nil then
							Hawkeye_callback(true)
							return
						else
							game._CManualMan:SendC2SManualIsEyesShow(ids, Hawkeye_callback)
							return
						end
					end
				end
			end
		end
	end

    --没有鹰眼区域 不允许使用
	self._IsHawkEyeEnable = false
	self:UpdateHawkeye()
end

def.method("number").SendHawkeyeUseOrStop = function (self,count)
    if not self._IsHawkEyeEffectIsOver then
    	return 
    end
    if self._IsHawkEyeState then 
        local protocol = (require "PB.net".C2SHawkeyeState)()
        protocol.enable = false --逻辑相反 非鹰眼模式 点击开启
        
        PBHelper.Send(protocol)
    else
        if count > 0 or count == -1 then  --客户端判定 是否有空余次数 或者 为-1 是无限次数
            local protocol = (require "PB.net".C2SHawkeyeState)()
            protocol.enable = true --逻辑相反 非鹰眼模式 点击开启
            PBHelper.Send(protocol)
        end
    end
end

def.method("=>", "number").GetRemainCount = function (self)
	return self._HawkEyeCount
end

def.method("=>", "table").GetRegions = function (self)
	return self._TableHawkEyeTargetPos
end

def.method().Cleanup = function(self)
	self._IsHawkEyeEnable = false
	self._IsHawkEyeState = false
	self._IsHawkEyeEffectIsOver = true 
	self._HawkEyeCount = 0
	self._TableHawkEyeTargetPos = nil
end

CHawkeyeEffectMan.Commit()
return CHawkeyeEffectMan