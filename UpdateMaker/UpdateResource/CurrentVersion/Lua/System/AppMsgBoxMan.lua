-- App弹窗提醒

local AppMsgTimerId = 0	

-- App弹窗接口 param1:TriggerTag param2:ID 
local function startWork(triggerTag, conditionId)
	local appMsgBoxTable = _G.AppMsgBoxTable
	if appMsgBoxTable == nil then return end	

	local game = _G.game
	local account = game._NetMan._UserName
	local UserData = require "Data.UserData".Instance()
	local accountInfo = UserData:GetCfg(EnumDef.LocalFields.AppMsgBox, account)
	if accountInfo == nil then accountInfo = {} end
	local serverName = game._NetMan._ServerName
	if accountInfo[serverName] == nil then accountInfo[serverName] = {} end

	local roleId = game._HostPlayer._ID
	if accountInfo[serverName][roleId] == nil then accountInfo[serverName][roleId] = {} end

	local appMsgBoxOpenTime = accountInfo[serverName][roleId].AppMsgBoxOpenTime
	-- 屏蔽商店评分功能   lidaming
	for i,v in pairs(appMsgBoxTable) do
		if v.TriggerConditions == triggerTag then
			local qualificationTable = {}
			string.gsub(v.Qualification, '[^*]+', function(w) table.insert(qualificationTable, w) end )

			for _,k in pairs(qualificationTable) do
				if tonumber(k) == conditionId then
					local curOSTime = os.time()
					if appMsgBoxOpenTime == nil or appMsgBoxOpenTime <= 0 or (curOSTime - appMsgBoxOpenTime) > (tonumber(v.DayDelay) * 86400) then
						if AppMsgTimerId > 0 then
							_G.RemoveGlobalTimer(AppMsgTimerId)
							AppMsgTimerId = 0
						end
						AppMsgTimerId = _G.AddGlobalTimer(tonumber(v.SecondDelay), true, function()
								local param = {}
								param.TriggerTag = triggerTag	
								param.ConditionId = conditionId
								param.AppMsgBoxCfg = v
								game._GUIMan:Open("CPanelUIAppMsgBox", param)
								warn("lidaming Open CPanelUIAppMsgBox !!!", triggerTag, conditionId, debug.traceback())								
								accountInfo[serverName][roleId].AppMsgBoxOpenTime = curOSTime
								UserData:SetCfg(EnumDef.LocalFields.AppMsgBox, account, accountInfo)

								AppMsgTimerId = 0
							end)		
					end
                end
            end
		end
	end
end

local function stopWork()
	if AppMsgTimerId > 0 then
		_G.RemoveGlobalTimer(AppMsgTimerId)
		AppMsgTimerId = 0 
	end
end

_G.AppMsgBox =
{
	StartWork = startWork,
	StopWork = stopWork,
}