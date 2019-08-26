local Lplus = require "Lplus"
local QuestReceiveEvent = Lplus.Class("QuestReceiveEvent")
local def = QuestReceiveEvent.define

def.field("table")._Data = nil

QuestReceiveEvent.Commit()
return QuestReceiveEvent