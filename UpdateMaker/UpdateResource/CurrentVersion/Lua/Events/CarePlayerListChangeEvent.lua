local Lplus = require "Lplus"

local CarePlayerListChangeEvent = Lplus.Class("CarePlayerListChangeEvent")
local def = CarePlayerListChangeEvent.define

--def.field("table")._NewCareList = BlankTable


CarePlayerListChangeEvent.Commit()
return CarePlayerListChangeEvent