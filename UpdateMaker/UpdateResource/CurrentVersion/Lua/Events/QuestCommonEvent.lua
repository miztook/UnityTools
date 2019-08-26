local Lplus = require 'Lplus'
local QuestCommonEvent = Lplus.Class('QuestCommonEvent')
local def = QuestCommonEvent.define

def.field("string")._Name = ""
def.field("dynamic")._Data = nil

QuestCommonEvent.Commit()
return QuestCommonEvent