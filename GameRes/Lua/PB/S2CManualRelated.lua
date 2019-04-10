local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CManualMan = require "Manual.CManualMan"
local CPanelUIManual = require "GUI.CPanelUIManual"

--初始化万物志异闻录数据
local function OnS2CManualDataSync(sender, protocol)
	game._CManualMan:OnS2CManualData( protocol.Datas.Mas )
    if CPanelUIManual.Instance():IsShow() then 
        CPanelUIManual.Instance()._CurPageClass:ShowData()
    end
	--game._GUIMan:Open("CPanelUIManual", nil)
end
PBHelper.AddHandler("S2CManualDataSync", OnS2CManualDataSync)

--领取奖励
local function OnS2CManualDraw(sender, protocol)
	game._CManualMan:OnS2CManualDraw(protocol)
end
PBHelper.AddHandler("S2CManualDraw", OnS2CManualDraw)

--万物志数据新增
local function OnS2CManualInc(sender, protocol)
	game._CManualMan:OnS2CManualInc( protocol.Datas )
end
PBHelper.AddHandler("S2CManualInc", OnS2CManualInc)

--万物志数据变更
local function OnS2CManualUpdate(sender, protocol)
	game._CManualMan:OnS2CManualUpdate( protocol.Datas )
end
PBHelper.AddHandler("S2CManualUpdate", OnS2CManualUpdate)

--万物志询问是否解锁
local function OnS2CManualIsEyesShow(sender, protocol)
	game._CManualMan:OnS2CManualIsEyesShow( protocol.Datas )
end
PBHelper.AddHandler("S2CManualIsEyesShow", OnS2CManualIsEyesShow)

