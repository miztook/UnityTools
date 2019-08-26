local bit = require "bit"

local mask = bit.band(0x40004000,  bit.bnot(32))
print("mask = " .. mask)