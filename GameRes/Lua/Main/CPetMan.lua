local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CPet = require "Object.CPet"
local CElementData = require "Data.CElementData"

local CPetMan = Lplus.Extend(CEntityMan, "CPetMan")
local def = CPetMan.define

def.field("userdata")._PetsRoot = nil
def.field("number")._UpdateInterval = 0

local instance_self = nil

def.final("=>", CPetMan).new = function ()
	instance_self = CPetMan()
	instance_self:Init(CEntityMan.MAN_ENUM.MAN_PETOBJECT)
	instance_self._PetsRoot = GameObject.New("Pets")
	return instance_self
end

def.method("table", "=>", "boolean").IsPetCreateble = function(self, msg_pet)
	if msg_pet == nil then
		warn("the pet message is nil.")
		return false
	end
	local id = msg_pet.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	if self:Get(id) ~= nil then
		--warn("There is another Pet with the same id, id = ", id)
		return false
	end
	local pet_template = CElementData.GetTemplate("Pet", msg_pet.PetTid)
	if pet_template == nil then
		warn("OnPetEnterMap PetTemplate = nil", msg_pet.PetTid)
		return false
	end
	return true
end

def.method("table", "=>", CPet).CreatePetObject = function (self, info)
	if self:IsPetCreateble(info) then
		local pet = nil
		local entity_id = info.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
		pet = CPet.new()
		pet:Init(info)
		pet:AddLoadedCallback(function(p)
				if p._GameObject ~= nil then
					p._GameObject.parent = self._PetsRoot
				end
			end)
		pet:Load( EnumDef.SightUpdateType.Unknown ) 	--宠物没有效果，暂时写死默认值
		self._ObjMap[entity_id] = pet
		return pet
	end
	return nil
end

def.method("number", "=>", CPet).GetByTid = function (self, tid)
	for k,v in pairs(self._ObjMap) do
		if v:GetTemplateId() == tid then
			return v
		end
	end

	return nil
end

-- 宠物的显隐与所属玩家一致
def.override().Update = function (self)
	do return end
	local world = game._CurWorld
	for k,v in pairs(self._ObjMap) do
		local owner = world:FindObject(v:GetOwnerId())
		v:EnableCullingVisible(owner ~= nil and owner:IsCullingVisible())
	end
end

def.override().UpdateAllHeight = function (self)
    local objs = self._ObjMap

    for _,v in pairs(objs) do
        if not v:IsReleased() then
             v:SetHeightOffset()
        end
    end
end

def.override("boolean").Release = function (self, is_2_release_root)
	CEntityMan.Release(self, is_2_release_root)
	if is_2_release_root then
		Object.DestroyImmediate(self._PetsRoot)
		self._PetsRoot = nil
	end
end

CPetMan.Commit()

return CPetMan