local Lplus = require "Lplus"
local QuestObjectiveCompleteEvent = Lplus.Class("QuestObjectiveCompleteEvent")
local def = QuestObjectiveCompleteEvent.define

def.field("table")._Data = nil

QuestObjectiveCompleteEvent.Commit()
return QuestObjectiveCompleteEvent