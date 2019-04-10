--[[ =============================
==	     主角异步操作 Task
================================]]

local Lplus = require "Lplus"
local Task = require "Utility.Task"
local AsyncTask = require "Utility.AsyncTask"
local CGame = require "Main.CGame"
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local CHostAsyncTask = Lplus.Class("CHostAsyncTask")
do
	local def = CHostAsyncTask.define
	
	--[[
		给Task增加切换用户限制
	]]
	def.static(Task, "=>", Task).AddChangeUserLimit = function (task)
		local GameLogicBreakEvent = require "Events.GameLogicBreakEvent"
		local function onLeaveGameLogicEvent (sender, event)
			if event.IsRoleChanged then
				task:cancel()
			end
		end
		
		CGame.EventManager:addHandler(GameLogicBreakEvent, onLeaveGameLogicEvent)
		
		task:continueWith(function (task)
			CGame.EventManager:removeHandler(GameLogicBreakEvent, onLeaveGameLogicEvent)
		end)
		return task
	end
	
	--[[
		移动到某物体附近
		param pos: 计算到此点距离
		param maxDistance: 无需移动的最大距离
		param stopDistance: 自动移动的停止距离
	]]
	def.static("table", "number", "number", "=>", Task).ApproachToEntityPos = function (pos, maxDistance, stopDistance)
		return CHostAsyncTask.AutoMoveToPosInCurrentScene(pos, maxDistance, stopDistance)
	end

	def.static("table", "number", "number", "=>", Task).AutoMoveToPosInCurrentScene = function (pos, maxDistance, stopDistance)
		local action = function (task, step)
			-- TODO: 根据具体实现逻辑进行修改完善
			if step == 1 then
				-- cancel skill
				return task:completeSub(CHostAsyncTask.StopFighting())
			elseif step == 2 then
				local hostX, hostZ = game._HostPlayer:GetPosXZ()
				local curDis = SqrDistanceH(hostX, hostZ, pos.x, pos.z)
				if curDis <= maxDistance * maxDistance then
					return "end"
				end
				
				return function (task, resumeEntry)
					--do return "end" end

					--寻路
					local host = game._HostPlayer

					local dir = host:GetPos() - pos
					dir.y = 0
					dir = dir:Normalize()
					pos = pos + dir*stopDistance
					
					--[[
					local FSMHostAutoMove = require "FSM.HostFSM.FSMHostAutoMove"
					local automove = FSMHostAutoMove.new(host, cmd.path, stopDistance, function () resumeEntry() end)
					local ret = host:ChangeState(automove)
					if not ret then
						warn("ChangeState to FSMHostAutoMove failed")
						task:cancel()
						resumeEntry()
					end
					]]

					-- 主动移动可打断
					local UserMoveEvent = require "Events.UserMoveEvent"
					local function onUserMove (sender, event)
						task:cancel()
						CGame.EventManager:removeHandler(UserMoveEvent, onUserMove)
					end
					CGame.EventManager:addHandler(UserMoveEvent, onUserMove)
				end
			else
				return "end"
			end
		end
		local cancel_callback = function () return "end" end
		
		local task = Task.createStepsEx(action, cancel_callback)

		return CHostAsyncTask.AddChangeUserLimit(task)
	end	

	def.static("=>", Task).StopFighting = function ()
		local task = Task.createOneStepEx(function (task)
			do return "end" end
			--[[
			local host = game._HostPlayer
			if host:IsInFightState() then
				return function (task, resumeEntry)
					host.SkillHdl:CancelSkill()
					host.SkillHdl.ActionAfterSkillCancel = function () resumeEntry() end
					host:LeaveFightState()
				end
			else
				return "end"
			end
			]]
		end, function () return "end" end)
		
		return CHostAsyncTask.AddChangeUserLimit(task)
	end

end
return CHostAsyncTask.Commit()

