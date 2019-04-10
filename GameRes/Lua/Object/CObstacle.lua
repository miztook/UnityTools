local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CModel = require "Object.CModel"

local CObstacle = Lplus.Extend(CEntity, "CObstacle")
local def = CObstacle.define

def.field("number")._TID = 0
def.field("number")._Length = 0


def.static("=>", CObstacle).new = function ()
	local obj = CObstacle()
	return obj
end

def.override("table").Init = function (self, obstacle_info)
	local entity_info = obstacle_info.EntityInfo
	CEntity.Init(self, entity_info)
	self._TID = obstacle_info.ObstacleTid
	self._Length = obstacle_info.Length
end

def.method().Load = function (self)
	local CElementData = require "Data.CElementData"
	local template = CElementData.GetObstacleTemplate(self._TID)
	if template ~= nil then
		local m = CModel.new()
		m._ModelFxPriority = self:GetModelCfxPriority()
		local on_model_loaded = function(ret)
			if ret then
				if self._IsReleased then
					m:Destroy()
				else
					self._Model = m
					self._GameObject = m._GameObject
					self._GameObject.name = self._GameObject.name .. "-" .. tostring(self._ID)
					GameUtil.SetLayerRecursively( self._GameObject, EnumDef.RenderLayer.Blockable)

					self._IsReady = true
					self:OnModelLoaded()				
					
					if self._InitPos then
						self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
						self._GameObject.position = self._InitPos
					end
					
					if self._InitDir then
						self._GameObject.forward = self._InitDir
					end
					--长宽以Map为准					
					GameUtil.ResizeCollider(self._GameObject, self._Length, template.Height, template.Width)
				end
			else
				warn("Failed to load model with path = " .. template.ModelAssetPath)
			end
		end
		local model_path = template.ModelAssetPath 
		m:Load(model_path, on_model_loaded)
	else
		warn("can not find Obstacle template data with id", self._TID)
	end
end

def.method().UpdateHeight = function (self)
	if self._InitPos and self._GameObject then
		self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
		self._GameObject.position = self._InitPos
	end
end

def.override().Release = function (self)  
    self._OnLoadedCallbacks = nil
    self._IsReleased = true

    if self._TopPate ~= nil then 
        self._TopPate:Release() 
    end

    GameUtil.DisableCollider(self._GameObject)
    
    self._GameObject = nil
    local ecm = self._Model
	if ecm ~= nil then
		ecm:Destroy()
		self._Model = nil
	end
    self._IsReady = false
end

CObstacle.Commit()
return CObstacle