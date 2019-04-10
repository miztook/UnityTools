local Lplus = require "Lplus"
local QuestCompleteEvent = Lplus.Class("QuestCompleteEvent")
local def = QuestCompleteEvent.define

def.field("table")._Data = nil

QuestCompleteEvent.Commit()
return QuestCompleteEvent