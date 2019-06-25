--
--S2CAdventrueGuide 冒险指南  2018.3.21  lidaming
--
local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

-- 暂时不处理冒险指南对应协议。因为是否开启只判断等级相关。


--上线获取冒险指南所有数据
local function OnS2CAdventrueGuideGetData(sender, msg)
	--warn("----OnS2CAdventrueGuideGetData---", #msg.adventureGuideDatas, #msg.adventureGuideCount, msg.totalLiveness)
	if game._HostPlayer ~= nil then	
		game._CCalendarMan:UpdateCalendarDataState(msg, true)
	end
end
PBHelper.AddHandler("S2CAdventrueGuideGetData", OnS2CAdventrueGuideGetData)

--冒险指南数据更新
local function OnS2CAdventureGuideUpdate(sender,msg)    
	--warn("----OnS2CAdventureGuideUpdate--", #msg.adventureGuideDatas, #msg.adventureGuideCount, msg.totalLiveness)
	if game._HostPlayer ~= nil then	
		game._CCalendarMan:UpdateCalendarDataState(msg, false)
	end

	if msg.adventureGuideDatas ~= nil and #msg.adventureGuideDatas > 0 then
		local isCloseDungeonIntroduction = false
		for _,k in pairs(msg.adventureGuideDatas) do
			--warn("lidaming ---->>>  S2CAdventureGuideUpdate ==>>>", k.TId)
			if k.TId ~= nil then
				local adventureGuideData = game._CCalendarMan:GetCalendarDataByID(k.TId)
				
				if k.isActivity then
					
					if adventureGuideData ~= nil and adventureGuideData._Data.IsNotify ~= "False" then
						-- 活动快捷提示判断是否有公会
						if adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDefend
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDungeon
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildBattle
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildQuest
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.RewardQuest
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildConvoy
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.ReputationQuest
						or adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildTreasure then
							if not game._GuildMan:IsHostInGuild() then
								game._GUIMan:ShowTipText(StringTable.Get(12031), false)
							return end
						end

						local PlayInfo = game._CCalendarMan:GetPlayInfoByActivityID(k.TId)
                        local GuildBattleSpecialCheck = function()
                            if adventureGuideData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildBattle and game._IsHideGuildBattle then
                                return false
                            end
                            return true
                        end
						if PlayInfo ~= nil and game._DungeonMan:DungeonIsOpen(PlayInfo.playId) and GuildBattleSpecialCheck() then
							local cb = function(val)
								if val == false then return end
								game._CCalendarMan:OpenPlayByActivityInfo(adventureGuideData)
							end
							local NotifyComponents = require "GUI.NotifyComponents"
							local notify = NotifyComponents.TimeLimitActivityNotify.new(adventureGuideData._Data.Name, cb)
							MsgNotify.Add(notify)

							local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
							local event = NotifyPowerSavingEvent()
							event.Type = "Activity"
							event.Param1 = notify._ActivityName
							CGame.EventManager:raiseEvent(nil, event)
						end
					end
				else
					-- 活动关闭
					if not isCloseDungeonIntroduction and adventureGuideData ~= nil then
						local dungeonTid = game._DungeonMan:GetDungeonID()
						if dungeonTid > 0 then
							for _, data in ipairs(adventureGuideData._Data.Play) do
								if dungeonTid == data.playId then
									isCloseDungeonIntroduction = true
									break
								end
							end
						end
					end
				end
			end
		end

		if isCloseDungeonIntroduction then
			-- 处于副本中，且关闭的活动玩法与副本对应
			-- 关闭副本介绍弹窗及小地图上的弹窗按钮
			game._GUIMan:Close("CPanelUIDungeonIntroduction")
			local CPanelMinimap = require "GUI.CPanelMinimap"
			if CPanelMinimap and CPanelMinimap.Instance():IsShow() then
				CPanelMinimap.Instance():EnableDungeonIntroductionBtn(false)
			end
			-- 关闭副本通用进度条
			local CPanelMainChat = require "GUI.CPanelMainChat"
			CPanelMainChat.Instance():HideDungeonCommonBar()
		end
	end
end
PBHelper.AddHandler("S2CAdventureGuideUpdate", OnS2CAdventureGuideUpdate)
