local Lplus = require "Lplus"
local QuestSubChangeEvent = Lplus.Class("QuestSubChangeEvent")
local def = QuestSubChangeEvent.define

def.field("table")._Data = nil

QuestSubChangeEvent.Commit()
return QuestSubChangeEvent