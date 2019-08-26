local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"

local function OnGuideList(sender, protocol)	
	--local GuideData = protocol.GuideData.GuideIdList
	game._CGuideMan:ChangeGuideData( protocol.GuideData )
end

PBHelper.AddHandler("S2CGuideList", OnGuideList)

-- 功能解锁更新
local function OnS2CGuideUpdate(sender, msg)
	local tid = msg.GuideId - 10000
	game._CFunctionMan:UpdateFunctionData(tid)
	local fun = CElementData.GetTemplate("Fun", tid)
	if fun ~= nil then
		game._CGameTipsQ:ShowUnlockFuncTip(tid)
		if fun.FunType == 1 then
			if not fun.NeedPop then
				if not IsNil(CPanelSystemEntrance.Instance()._Panel) then
					CPanelSystemEntrance.Instance():PlayOpenUIFx(tostring(fun.FunID))
				end
			end
		end
	end
end
PBHelper.AddHandler("S2CGuideUpdate", OnS2CGuideUpdate)

local function OnS2CFunctionForbid(sender, msg)
    if msg.FunctionId > 0 then
        game._CFunctionMan:ChangeForbidData(msg.FunctionId, msg.IsForbid)
    end
end
PBHelper.AddHandler("S2CFunctionForbid", OnS2CFunctionForbid)
