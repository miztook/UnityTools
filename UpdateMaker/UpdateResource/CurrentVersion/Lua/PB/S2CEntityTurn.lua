--
-- S2CEntityTurn
--

local PBHelper = require "Network.PBHelper"

local _turnDir = Vector3.zero
local _origDir = Vector3.zero
local _hostDir = Vector3.zero
local function OnEntityTurn( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		entity:AddLoadedCallback(function() 
						_turnDir.x = msg.TurnToOrientation.x
						_turnDir.y = msg.TurnToOrientation.y
						_turnDir.z = msg.TurnToOrientation.z

						_origDir.x = msg.CurOrientation.x
						_origDir.y = msg.CurOrientation.y
						_origDir.z = msg.CurOrientation.z

						local entity_forward = entity:GetGameObject().forward
						_hostDir.x = entity_forward.x
						_hostDir.y = entity_forward.y
						_hostDir.z = entity_forward.z

						if msg.Speed ~= nil and msg.Speed > 0 then
							if msg.durationMilliSeconds > 0 then
								local angle1 = math.acos(Vector3.Dot(_turnDir:Normalize(), _origDir:Normalize())) *( 180 / 3.14)
								local angle2 = math.acos(Vector3.Dot(_turnDir:Normalize(), _hostDir:Normalize())) *( 180 / 3.14)
								local speed_fix = (angle2 / angle1) * (angle1 * 1000/ msg.durationMilliSeconds)
								entity:TurnToDir(_turnDir, speed_fix)
							-- 服务器有几率会出现 msg.durationMilliSeconds == 0 && msg.Speed > 0 的异常情况
							else
								entity:SetDir(_turnDir)
							end
						else
							if msg.AngularVelocity > 0 then
								entity:ChangeDirContinued(_turnDir, msg.AngularVelocity)
							else
								entity:SetDir(_turnDir)
							end							
						end	                
		            end)
	end
end

PBHelper.AddHandler("S2CEntityTurn",OnEntityTurn)