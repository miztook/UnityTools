local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntityMan = require "Main.CEntityMan"
local CPlayerMan = require "Main.CPlayerMan"
local CNPCMan = require "Main.CNPCMan"
local CSubobjectMan = require "Main.CSubobjectMan"
local CObstacleMan = require "Main.CObstacleMan"
local CLootMan = require "Main.CLootMan"
local CMineMan = require "Main.CMineMan"
local CPetMan = require "Main.CPetMan"
local CEntity = require "Object.CEntity"
local MapBasicConfig = require "Data.MapBasicConfig"
local CWorld = Lplus.Class("CWorld")
local def = CWorld.define

def.field("userdata")._CurScene = nil
def.field("boolean")._IsReady = false
def.field(CPlayerMan)._PlayerMan = nil
def.field(CNPCMan)._NPCMan = nil
def.field(CSubobjectMan)._SubobjectMan = nil
def.field(CObstacleMan)._DynObjectMan = nil
def.field(CLootMan)._LootObjectMan = nil
def.field(CMineMan)._MineObjectMan = nil
def.field(CPetMan)._PetMan = nil
def.field("table")._OnLoadedCallbacks = nil
def.field("table")._WorldInfo = BlankTable
def.field("number")._UpdateTimer = 0
def.field("number")._UpdateStep = 0

def.final("=>", CWorld).new = function ()
	local obj = CWorld()

	obj._WorldInfo.SceneTid = 0
	obj._WorldInfo.MapId = 0

	obj._PlayerMan = CPlayerMan.new()
	obj._NPCMan = CNPCMan.new()
	obj._SubobjectMan = CSubobjectMan.new()
	obj._DynObjectMan = CObstacleMan.new()
	obj._LootObjectMan = CLootMan.new()
	obj._MineObjectMan = CMineMan.new()
	obj._PetMan = CPetMan.new()
	return obj
end

def.method("string", "function").Load = function (self, scene_resource_path, cb)
	self._IsReady = false
	--warn("Game World Begin Load...")
	GameUtil.AsyncLoad(scene_resource_path, function(mapres)
			if mapres ~= nil then
				--判断是否已经先删除，这时不是要加载的world
				local sceneTid = self._WorldInfo.SceneTid
				--local respath = _G.MapBasicInfoTable[sceneTid].AssetPath
				local respath = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid).AssetPath
				if scene_resource_path ~= respath then
					warn("World Should Not Load!!!!", sceneTid, respath, scene_resource_path)
					return
				end

				self._CurScene = Object.Instantiate(mapres)
				self:OnLoaded()
				if cb ~= nil then cb() end
			end
		end)
end

def.method().OnLoaded = function (self)
	self._IsReady = true
	
	GameUtil.OnWorldLoaded(self._CurScene)

	if self._OnLoadedCallbacks then
        for i,v in ipairs(self._OnLoadedCallbacks) do
            v(self)
        end
        self._OnLoadedCallbacks = nil
    end 

    self._UpdateStep = 0
	self._UpdateTimer = _G.AddGlobalTimer(0.3, false, function()
		if self._UpdateStep == 0 then
			self._PlayerMan:Update()
			self._UpdateStep = 1
		elseif self._UpdateStep == 1 then
			self._PetMan:Update()
			self._UpdateStep = 2
		else
			self._LootObjectMan:Update()
			self._UpdateStep = 0
		end
	end)
end

def.method("function").AddLoadedCallback = function (self, cb)
    if self._IsReady then
        cb(self)
    else
        if not self._OnLoadedCallbacks then
            self._OnLoadedCallbacks = {}
        end
        self._OnLoadedCallbacks[#self._OnLoadedCallbacks+1] = cb
    end
end

def.method("=>", "userdata").GetCurScene = function(self)
	return self._CurScene
end

def.method("number", "=>", CEntityMan).DispatchManager = function (self, id)

	local v = IDMan.GetEntityType(id)
	local EntityType = EnumDef.EntityType
	if v == EntityType.Role then
		return self._PlayerMan
	elseif v == EntityType.Monster or v == EntityType.Npc then
		return self._NPCMan
	elseif v == EntityType.SubObject then
		return self._SubobjectMan
	elseif v == EntityType.Obstacle then
		return self._DynObjectMan
	elseif v == EntityType.Loot then
		return self._LootObjectMan
	elseif v == EntityType.Mine then
		return self._MineObjectMan
	elseif v == EntityType.Pet then
		return self._PetMan
	end

	if id >= 0 then
		warn("CEntityMan DispatchManager: cant find manager ", id)
	end

	return nil
end

def.method("number", "=>", CEntity).FindObject = function (self, id)
	local mapId = self._WorldInfo.MapId
	if id == 0 or mapId == 0 or mapId ~= GameUtil.GetCurrentMapId() then return nil end
	if id == game._HostPlayer._ID then
		return game._HostPlayer
	end

	local man = self:DispatchManager(id)	
	if man ~= nil then
		return man:Get(id)
	end
	
	print("ERROR: cant find obj ", id)
	return nil
end

def.method("number", "=>", CEntity).FindObjectByShortID = function (self, id)
	if id <= 0 then return nil end
	return self:FindObject(id)
end

def.method("=>", "table").FindObjectsByIsHawkEye = function (self)
    local HawkEyeObjs = {}
	for _,v in pairs(self._NPCMan._ObjMap) do
		local IsHawkEye = false
		if v:IsMonster() then
			IsHawkEye = v._MonsterTemplate.IsHawkEye
		else
			IsHawkEye = v._NpcTemplate.IsHawkEye
		end
		if IsHawkEye then
			HawkEyeObjs[#HawkEyeObjs+1] = v:GetGameObject()
		end
	end
	for _,v in pairs(self._MineObjectMan._ObjMap) do
		if v._MineralTemplate.IsHawkEye then
			HawkEyeObjs[#HawkEyeObjs+1] = v:GetGameObject()
		end
	end

	print( "HawkEyeObjs",HawkEyeObjs)
	return HawkEyeObjs
end

def.method("=>", "table").GetCurMapInfo = function(self)
	local CElementData = require "Data.CElementData"
	local sceneTid = self._WorldInfo.SceneTid
    --local scene = _G.MapBasicInfoTable[sceneTid]
    local scene = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid)
    local info = {}
    if scene ~= nil then
    	info.MapTid = sceneTid
    	info.Name = scene.TextDisplayName
    else
    	info.MapTid = 0
    	info.Name = ""
 	end

 	return info
end

def.method("boolean", "boolean").Release = function (self, is_release_scene, is_2_release_root)
	self._PlayerMan:Release(is_2_release_root)
	self._NPCMan:Release(is_2_release_root)
	self._SubobjectMan:Release(is_2_release_root)
	self._DynObjectMan:Release(is_2_release_root)
	self._LootObjectMan:Release(is_2_release_root)
	self._MineObjectMan:Release(is_2_release_root)
	self._PetMan:Release(is_2_release_root)

	if is_release_scene then
		GameUtil.OnWorldRelease()

		Object.DestroyImmediate(self._CurScene)
		self._CurScene = nil

		self._IsReady = false
		self._OnLoadedCallbacks = nil

		_G.RemoveGlobalTimer(self._UpdateTimer)
		self._UpdateTimer = 0
	end
	
	game:CleanOnSceneChange()
	game:LuaGC()
	game:GC(true)
end

CWorld.Commit()
return CWorld