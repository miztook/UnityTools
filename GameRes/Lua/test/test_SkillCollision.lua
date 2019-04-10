
local SkillCollision = require "SkillCollision"


local pos = Vector3.New(12, 39, 100)
local dir = Vector3.New(1, 0, 0)

-- 六个参数依次为：target_affect_obj   碰撞类型
				-- target_affect_radius  碰撞半径 （对于矩形就是宽度）
				-- target_affect_lenght  碰撞长度
				-- target_affect_angle  扇形半张角
				-- pos 
				-- dir
-- 0: rect, 2*5
local rect = SkillCollision.CreateShape(0, 1, 5, 0, pos, dir)
assert(rect:IsCollided(pos, 0.001))
assert(rect:IsCollided(pos + dir * 5, 0.001))
assert(not rect:IsCollided(pos + dir * 5.1, 0.001))
assert(not rect:IsCollided(pos - dir, 0.001))
assert(rect:IsCollided(pos + Vector3.New(0, 0, 0.5), 0.001))
assert(not rect:IsCollided(pos + Vector3.New(0, 0, 0.51), 0.001))

-- 1: sector
local fan = SkillCollision.CreateShape(1, 5, 0, 45, pos, dir)
assert(fan:IsCollided(pos, 0.001))
assert(fan:IsCollided(pos + dir * 5, 0.001))
assert(not fan:IsCollided(pos + dir * 5.1, 0.001))
assert(not fan:IsCollided(pos - dir, 0.001))
assert(fan:IsCollided(pos + Vector3.New(1, 0, 1), 0.001))
assert(not fan:IsCollided(pos + Vector3.New(1, 0, 1.1), 0.001))

-- 2: circle
local circle = SkillCollision.CreateShape(2, 5, 0, 0, pos, dir)
assert(circle:IsCollided(pos, 0.001))
assert(circle:IsCollided(pos + dir * 5, 0.001))
assert(not circle:IsCollided(pos + dir * 5.1, 0.001))

warn("test success")
