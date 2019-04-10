--
-- S2CBookRead
--

local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CBookRead(sender,protocol)
--warn("=============OnS2CBookRead=============")
	if protocol.BookId ~= nil and protocol.BookId > 0 then
		local CElementData = require "Data.CElementData"
		local bookTemplate = CElementData.GetTemplate("Letter", protocol.BookId)

		if bookTemplate == nil then return end

		local info = {}
		info.Title = bookTemplate.Title
		info.Content = bookTemplate.Content
		info.Interval = bookTemplate.DurationSeconds
		info.writter = bookTemplate.Writter

		game._GUIMan: Open("CPanelBook", info)
	end
end
PBHelper.AddHandler("S2CBookRead", OnS2CBookRead)