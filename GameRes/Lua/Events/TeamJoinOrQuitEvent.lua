local Lplus = require "Lplus"
local TeamJoinOrQuitEvent = Lplus.Class("TeamJoinOrQuitEvent")
local def = TeamJoinOrQuitEvent.define

def.field("boolean")._InTeam = false

TeamJoinOrQuitEvent.Commit()
return TeamJoinOrQuitEvent