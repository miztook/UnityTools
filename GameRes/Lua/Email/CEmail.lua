local Lplus = require "Lplus"

local CEmail = Lplus.Class("CEmail")
local def = CEmail.define

def.field("number")._EmailID = 0
def.field("number")._Type = 0
def.field("boolean")._IsRead = false    --是否已读
def.field("boolean")._IsDraw = false	--是否已领取
def.field("number")._CreateTime = 0
def.field("string")._SenderName = ""
def.field("string")._Title = ""
def.field("string")._Content = ""
def.field("table")._RewardItem = nil  --奖励物品
def.field("table")._Reward = nil   --奖励金钱
def.field("number")._RewardId = 0 ;-- 奖励模板id
def.field("boolean")._IsHaveReward = false -- 是否为有附件的邮件
def.field("number")._Level = 0

def.static("=>",CEmail).new = function ()
	local obj = CEmail()
	return obj
end

CEmail.Commit()
return CEmail