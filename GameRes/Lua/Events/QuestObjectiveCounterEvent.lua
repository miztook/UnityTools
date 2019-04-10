local Lplus = require "Lplus"
local QuestObjectiveCounterEvent = Lplus.Class("QuestObjectiveCounterEvent")
local def = QuestObjectiveCounterEvent.define

def.field("table")._Data = nil

QuestObjectiveCounterEvent.Commit()
return QuestObjectiveCounterEvent