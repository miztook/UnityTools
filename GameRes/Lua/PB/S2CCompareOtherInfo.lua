--
--S2CCompareOtherInfo 养成对比  2018/08/15  lidaming
--
local PBHelper = require "Network.PBHelper"

-- 获取养成对比信息
local function OnS2CCompareOtherInfo(sender, msg)
	--warn("----OnS2CCompareOtherInfo---", msg.OtherRoleId)
	-- print_r(msg.adventrueGuideDatas)
	game._GUIMan:Open("CPanelUIPlayerStrongCompare", msg)
end
PBHelper.AddHandler("S2CCompareOtherInfo", OnS2CCompareOtherInfo)


-- 战力更新
local function OnS2CFightScoreUpdate(sender, msg)
	--warn("----OnS2CFightScoreUpdate---", msg.FightScoreType)
	if msg.FightScoreType ~= nil then
		game._PlayerStrongMan:ChangeFightScore(msg)
	end	
end
PBHelper.AddHandler("S2CFightScoreUpdate", OnS2CFightScoreUpdate)
