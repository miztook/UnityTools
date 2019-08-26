local Lplus = require "Lplus"
local QuestGiveUpEvent = Lplus.Class("QuestGiveUpEvent")
local def = QuestGiveUpEvent.define

def.field("table")._Data = nil

QuestGiveUpEvent.Commit()
return QuestGiveUpEvent