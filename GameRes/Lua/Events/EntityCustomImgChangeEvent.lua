local Lplus = require "Lplus"
local EntityCustomImgChangeEvent = Lplus.Class("EntityCustomImgChangeEvent")
local def = EntityCustomImgChangeEvent.define

def.field("number")._EntityId = 0

EntityCustomImgChangeEvent.Commit()
return EntityCustomImgChangeEvent