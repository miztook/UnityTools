local Lplus = require "Lplus"
local CharmOptionEvent = Lplus.Class("CharmOptionEvent")
local def = CharmOptionEvent.define

def.field("number")._FieldID = -1
def.field("string")._Option = ""       --(1."PutOn", 2."PutOff", 3."Unlock", 4. "Change")
def.field("number")._CharmID = -1
def.field("number")._OldCharmID = -1
def.field("boolean")._IsSuccess = false
def.field("table")._ItemUpdateInfo = BlankTable
def.field("table")._Fields = nil

CharmOptionEvent.Commit()
return CharmOptionEvent