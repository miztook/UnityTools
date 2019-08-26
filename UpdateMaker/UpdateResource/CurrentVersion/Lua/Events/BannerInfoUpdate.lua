local Lplus = require "Lplus"
local BannerInfoUpdate = Lplus.Class("BannerInfoUpdate")
local def = BannerInfoUpdate.define

def.field("number")._BannerID = 0
def.field("boolean")._IsOpen = true

BannerInfoUpdate.Commit()
return BannerInfoUpdate