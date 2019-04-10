local Lplus = require "Lplus"

local GuildEvent = Lplus.Class("GuildEvent")
local def = GuildEvent.define

def.field("string")._Type = ""
def.field("number")._Param = -1

GuildEvent.Commit()
return GuildEvent
