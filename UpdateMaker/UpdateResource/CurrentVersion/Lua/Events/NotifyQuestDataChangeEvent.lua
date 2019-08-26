local Lplus = require "Lplus"

local NotifyQuestDataChangeEvent = Lplus.Class("NotifyQuestDataChangeEvent")
local def = NotifyQuestDataChangeEvent.define

def.field("number")._QuestId = 0

NotifyQuestDataChangeEvent.Commit()
return NotifyQuestDataChangeEvent
