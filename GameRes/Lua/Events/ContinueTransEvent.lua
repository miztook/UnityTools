local Lplus = require "Lplus"
local ContinueTransEvent = Lplus.Class("ContinueTransEvent")
local def = ContinueTransEvent.define

def.field("number")._MapID = 0
def.field("table")._TargetPos = BlankTable

ContinueTransEvent.Commit()
return ContinueTransEvent