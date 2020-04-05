--
-- S2CDialogueEvent
--

local PBHelper = require "Network.PBHelper"

local function OnDialogueEvent(sender, msg)
	local reward_data = 
	{	
		dialogue_id = msg.DialogueId,
		is_local = msg.DialogueEventId == 0,
	}		
	game._GUIMan:Open("CPanelDialogue",reward_data)
end

PBHelper.AddHandler("S2CDialogueEvent", OnDialogueEvent)