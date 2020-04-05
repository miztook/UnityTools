local PBHelper = require "Network.PBHelper"

local function OnGuideList(sender, protocol)	
	local GuideData = protocol.GuideData.GuideIdList
	game._CGuideMan:ChangeGuideData( GuideData )
end

PBHelper.AddHandler("S2CGuideList", OnGuideList)