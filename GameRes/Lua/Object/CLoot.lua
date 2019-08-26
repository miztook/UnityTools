local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CModel = require "Object.CModel"
local CEntityMan = require "Main.CEntityMan"
local SLootType = require "PB.net".LOOT_TYPE
local CElementData = require "Data.CElementData"
local CTokenMoneyMan = require "Data.CTokenMoneyMan"
local C2SPickUpLoot = require "PB.net".C2SPickUpLoot
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFxObject = require "Fx.CFxObject"

local CLoot = Lplus.Extend(CEntity, "CLoot")
local def = CLoot.define
local ani = 
{
	[0] = "etc_wupindiaoluo1",
	[1] = "etc_wupinchandou1"
}

def.field("number")._LootType = 0
def.field("number")._OwnerId = 0
def.field("number")._DeadCreatureEntityId = 0
def.field("number")._TickInterval = 1
def.field("boolean")._CanPickup = false
def.field("boolean")._IsProcessing = false
def.field("number")._ItemTid = 0
def.field("number")._MoneyId = 0
def.field("number")._MoneyAmount = 0
def.field("number")._Quality = 0
def.field("boolean")._IsBand = true
def.field(CFxObject)._ItemGfx = nil
def.field(CFxObject)._ExplodedGfx = nil
def.field("boolean")._IsClickPickup = false
def.field("number")._EnterType = 0   -- Unknown = 0,    -- 未知
def.field("number")._PickUpTimer = 0

def.static("=>", CLoot).new = function ()
	local obj = CLoot()
	return obj
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.LOOT
end

def.override("table").Init = function (self, loot_info)
	--warn("111", debug.traceback())
	local entity_info = loot_info.EntityInfo
	CEntity.Init(self, entity_info)

	self._OwnerId = loot_info.OwnerId
	self._DeadCreatureEntityId = loot_info.DeadCreatureEntityId
	self._LootType = loot_info.LootType

	if SLootType.Gold == self._LootType then
		self._MoneyId = loot_info.Money.ResourceType
		self._MoneyAmount = loot_info.Money.Value
	elseif SLootType.Item == self._LootType then
		self._ItemTid = loot_info.ItemTid
		self._IsBand = loot_info.IsBind
	else
		warn("UnKnown loot type, need check = ", self._LootType)
	end
end

def.method("number").Load = function (self, enterType)
	self._EnterType = enterType

	if self._LootType == SLootType.Item then
		self:LoadItem()
	elseif self._LootType == SLootType.Gold then
		if self._MoneyAmount > 0 then
			local assetPath = CTokenMoneyMan.Instance():GetCoinModelPathId(self._MoneyAmount)
			self:LoadMoney(assetPath)
		end
	else
		warn("UnKnown loot type! need check = ", self._LootType)
	end
end

def.method().LoadItem = function (self)
	local template = CElementData.GetItemTemplate(self._ItemTid)
	if template ~= nil then
		-- 策划需求：模型不再走模板配置，统一为Model_Gold_5，解决掉落特效杂乱表现问题  -- added by Jerry
		local item_asset_path = PATH.Model_Gold_5 --template.LootModelAssetPath
		--if item_asset_path == nil or item_asset_path == "" then
		--	 item_asset_path = PATH.Model_Gold_5
		--end
		local m = CModel.new()
		m._ModelFxPriority = self:GetModelCfxPriority()
		self._Model = m
		self._Quality = template.InitQuality

		local on_model_loaded = function(ret)
				if ret then
					if self._IsReleased then
						m:Destroy()
					else
						self:InitLootModel()
					end
				else
					warn("Failed to load model with path = " .. item_asset_path)
				end
			end

		m:Load(item_asset_path, on_model_loaded)
	end
end

def.method("string").LoadMoney = function(self, assetPath)
	if assetPath == "" then
		warn("Loot money model is nil")
		return
	end

	local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
	self._Model = m

	local on_model_loaded = function(ret)
		if ret then
			if self._IsReleased then
				m:Destroy()
			else
				self:InitLootModel()
			end
		else
			warn("Failed to load money model")
		end
	end
	m:Load(assetPath, on_model_loaded)
end

 local function FlyParabolic(self,pos,dest,cb)
	local motor = self._GameObject:SmartAddComponent(ClassType.CParabolicMotor)
	motor:SetParams(0, 0)
	motor:Fly(pos, dest, 0.8, 0.01, function(g, timeout) 
		if cb then cb(g) end
		--Object.Destroy(motor)   -- 如果callback不能调到，组件将无法删除, model会复用
	end)
end

def.method().InitLootModel = function (self)
	local m = self._Model
	self._GameObject = m._GameObject
	GameUtil.SetLayerRecursively( self._GameObject, EnumDef.RenderLayer.Clickable)

	if not IsNil(self._GameObject) then
        self._Shadow = self._GameObject:FindChild("Shadow")
    end

	self:AddObjectComponent(false, 0.4)
	self:OnModelLoaded()				

	self._GameObject.rotation = Quaternion.identity

	local destPos = self._InitPos
	local monster = game._CurWorld:FindObject(self._DeadCreatureEntityId)
	local function cb()
		self._DeadCreatureEntityId = 0
		if self._IsReleased then return end

		if self._Quality > 0 and self._Quality < 7 then
			--local gfx_path = PATH[string.format("Etc_Item_Quality_%d", self._Quality)]
			-- 暂时不分品质，因为特效资源不足 -- added by Jerry
            local gfx_path = PATH["Etc_Item_FlyQuality_1"]
            local parent = (self._Shadow and self:GetGameObject():GetChild(1)) or self:GetGameObject():GetChild(0) or self:GetGameObject()
			self._ItemGfx = CFxMan.Instance():PlayAsChild(gfx_path, parent, Vector3.zero + Vector3.New(0, 0.12, 0), Quaternion.identity, -1, true, -1, EnumDef.CFxPriority.Always)
		else
			--warn("UnKnown quality = " .. self._Quality)
		end
	end

	-- 需要
	if monster ~= nil and self._EnterType == EnumDef.SightUpdateType.NewBorn then
		local mosterPos = monster:GetPos()
		if mosterPos ~= nil then
			self._InitPos = mosterPos
			self._GameObject.position = mosterPos

			if self._LootType == SLootType.Item then
				self:PlayAnimation(ani[0], 0, false, 0, 1)
			end
			
			FlyParabolic(self, mosterPos, destPos, cb)
		end
	else
		cb()
	end

	self:SetCanPickup(true, 1.5)
end

def.method().ShakeLoot = function (self)
	self:PlayAnimation(ani[1], 0, false, 0, 1)
end

def.method().ShowPickupGfx = function (self)
	local destTrans = game._HostPlayer:GetBipSpine()
	if destTrans == nil then return end

	--local strPath = PATH[string.format("Gfx_Pick_Gold_%d", self._Quality)]
    local strPath = PATH["Etc_Item_FlyQuality_1"]
	local distance = Vector3.DistanceH(self:GetPos(), destTrans.position)
	local lifetime = distance / 5
    local fly_fx = nil
	local function cb()
		if fly_fx ~= nil then
			fly_fx:Stop()
            fly_fx = nil
		end

        if IsNil(destTrans) then return end
        local gfx_path = PATH.Etc_Item_FlyToPlayerExploded
        self._ExplodedGfx = CFxMan.Instance():PlayAsChild(gfx_path, destTrans, Vector3.zero, Quaternion.identity, 1, false, 1, EnumDef.CFxPriority.Always)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_LootFlyToPlayerExplode, 0)
	end
	fly_fx = CFxMan.Instance():FlyMutantBezierCurve(strPath, self:GetPos(), destTrans, 5, lifetime, EnumDef.CFxPriority.Always, cb)
end

def.method("=>", "number").GetDistToHost = function (self)
	local fDistToHost = Vector3.DistanceH(game._HostPlayer:GetPos(), self:GetPos())
	return fDistToHost
end

def.method("=>", "number").GetSqrDistToHost = function (self)
	local x1, z1 = game._HostPlayer:GetPosXZ()
	local x2, z2 = self:GetPosXZ()
	local fDistSqrToHost = SqrDistanceH(x1, z1, x2, z2)
	return fDistSqrToHost
end

def.method("boolean", "number").SetCanPickup = function (self, bCanPickup, delaySeconds)
	self:AddTimer(delaySeconds, true ,function()
	        self._CanPickup = bCanPickup
	    end)
end

def.method("number", "=>", "boolean").CanPickUp = function(self, radius)
	if self:GetSqrDistToHost() >= radius * radius then return false end    --优化
	if self._OwnerId > 0 and self._OwnerId ~= game._HostPlayer._ID then return false end
	if self._IsProcessing then return false end
	if not self._CanPickup then return false end
	
	return true
end

def.method("=>", "boolean").IsClickPickup = function (self)
	return self._IsClickPickup
end

def.method().PickUp = function(self)
    self._IsProcessing = true
	self._FadeOutWhenLeave = false
	self:ShowPickupGfx()
	self:Release()
end

def.override().OnClick = function (self)
	CEntity.OnClick(self)

	if self._LootType == SLootType.Gold or self._IsProcessing then
		return
	end

    if game._HostPlayer:HasEnoughSpace(self._ItemTid, self._IsBand, 1) then
    	self._IsClickPickup = true
        self:SendPickupSingleMsg()
	else
		self:ShakeLoot()
		FlashTip(StringTable.Get(256), "tip", 1)
	end

end

def.override("=>", "boolean").CanBeSelected = function(self)
    return true
end

def.override("=>", "table").GetPos = function (self)
    return CEntity.GetPos(self) + Vector3.New(0, 0.12, 0)
end

def.method().SendPickupSingleMsg = function(self)
	local protocol = C2SPickUpLoot()
	table.insert(protocol.lootEntityIds, self._ID)
	SendProtocol(protocol)
end

def.override().Release = function (self) 
	if self._IsReleased then return end

	if self._ItemGfx ~= nil then
		self._ItemGfx:Stop()
		self._ItemGfx = nil
	end

	if self._ExplodedGfx ~= nil then
		self._ExplodedGfx:Stop()
		self._ExplodedGfx = nil
	end

    if self._PickUpTimer ~= 0 then
        _G.RemoveGlobalTimer(self._PickUpTimer)
        self._PickUpTimer = 0
    end

	self._IsClickPickup = false
	CEntity.Release(self)
end

CLoot.Commit()
return CLoot