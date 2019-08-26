local Lplus = require "Lplus"
local QuestDataOkEvent = Lplus.Class("QuestDataOkEvent")
local def = QuestDataOkEvent.define

def.field("table")._Data = nil

QuestDataOkEvent.Commit()
return QuestDataOkEvent