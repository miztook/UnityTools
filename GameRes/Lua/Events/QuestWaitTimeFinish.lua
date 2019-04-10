local Lplus = require "Lplus"

local QuestWaitTimeFinish = Lplus.Class("QuestWaitTimeFinish")
local def = QuestWaitTimeFinish.define

def.field("number")._QuestId = 0

QuestWaitTimeFinish.Commit()
return QuestWaitTimeFinish
