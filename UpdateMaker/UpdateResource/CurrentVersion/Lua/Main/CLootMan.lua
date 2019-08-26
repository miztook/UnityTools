local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CLoot = require "Object.CLoot"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local SLootType = require "PB.net".LOOT_TYPE
local PackageChangeEvent = require "Events.PackageChangeEvent"
local C2SPickUpLoot = require "PB.net".C2SPickUpLoot
local CElementData = require "Data.CElementData"
local net = require "PB.net"
local CLootMan = Lplus.Extend(CEntityMan, "CLootMan")
local def = CLootMan.define

def.field("userdata")._LootObjectsRoot = nil
def.field("number")._TimerId = 0
def.field("boolean")._IsShownAlert = false
def.field("function")._OnPackageChange = nil
def.field("number")._PickupRadius = 4 --Default Value

def.final("=>", CLootMan).new = function ()
	local obj = CLootMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_LOOTOBJECT)
	obj._LootObjectsRoot = GameObject.New("LootObjects")
	return obj
end

def.override("number").Init = function (self, type)
	CEntityMan.Init(self, type)

	local dataPickupRadius = CSpecialIdMan.Get("LootPickupRadius")
	if dataPickupRadius > 0 then
		self._PickupRadius = dataPickupRadius
	else
		--print("Check CSpecialIdMan [LootPickupRadius]")
	end

	self:RemoveCheckTimer()
	self._TimerId = _G.AddGlobalTimer(1, false, function()
		self:AutoPickUpCheck()
	end)

	local OnPackageChangeEvent = function(sender, event)
		if event.PackageType == net.BAGTYPE.BACKPACK then
			self._IsShownAlert = false
		end
	end

	self._OnPackageChange = OnPackageChangeEvent
	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)	
end

def.method("table", "number", "=>", CLoot).CreateLootObject = function (self, info, enterType)
	local id = info.EntityInfo.EntityId
	if self._ObjMap[id] ~= nil then
		warn("Can not create the same LootObject", id)
		return self._ObjMap[id]
	end
	
	local loot = CLoot.new()
	loot:Init(info)

    loot:AddLoadedCallback(function(p)
		if p._GameObject ~= nil then
			p._GameObject.parent = self._LootObjectsRoot
		end
	end)
	loot:Load(enterType)
	self._ObjMap[id] = loot
	return loot
end

def.method().RemoveCheckTimer = function (self)
	if self._TimerId ~= 0 then
		_G.RemoveGlobalTimer(self._TimerId)
		self._TimerId = 0
	end
end

local protocol = nil
local CheckProtocol = function()
    if protocol == nil then
		protocol = C2SPickUpLoot()
	end
end

def.method().AutoPickUpCheck = function (self)
    local hp = game._HostPlayer
	if hp == nil then return end
    protocol = nil
	
	for k,v in pairs(self._ObjMap) do
        if v ~= nil and v:CanPickUp(self._PickupRadius) then
			if v._LootType == SLootType.Gold then
                CheckProtocol()
			    table.insert(protocol.lootEntityIds, k)
			elseif v._LootType == SLootType.Item then
		        if hp:HasEnoughSpace(v._ItemTid, v._IsBand, 1) then
                    CheckProtocol()
			        table.insert(protocol.lootEntityIds, k)
		        elseif self._IsShownAlert == false then
			        self:ShakeLoots()
			        FlashTip(StringTable.Get(256), "tip", 1)
			        self._IsShownAlert = true
		        end
			else
				warn("Unknown loot type! Please check!")
			end
			if protocol ~= nil and #protocol.lootEntityIds > 400 then
				SendProtocol(protocol)
                protocol = nil
			end
		end
	end
	if protocol ~= nil and #protocol.lootEntityIds > 0 then
		SendProtocol(protocol)
	end
end

def.method().ShakeLoots = function (self)
	for k,v in pairs(self._ObjMap) do
		if v ~= nil and v:CanPickUp(self._PickupRadius) then
			if v._LootType ~= SLootType.Gold then
				v:ShakeLoot()
			end
		end
	end
end

def.method("number").OnLootPickUp = function (self, id)
	local obj = self._ObjMap[id]

	if obj == nil then
		--print("ShowPickupGfx obj == nil", debug.traceback())
		return
	end

    obj:PickUp()
    self._ObjMap[id] = nil
end

def.override("boolean").Release = function (self, is_2_release_root)
	CEntityMan.Release(self, is_2_release_root)
	if is_2_release_root then
		self:RemoveCheckTimer()

		CGame.EventManager:removeHandler(PackageChangeEvent, self._OnPackageChange)
		self._OnPackageChange = nil

		Object.Destroy(self._LootObjectsRoot)
		self._LootObjectsRoot = nil
	end
end

CLootMan.Commit()
return CLootMan