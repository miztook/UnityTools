local PBHelper = require "Network.PBHelper"
local function OnS2CWeatherChange(sender, protocol)
    GameUtil.ChangeSceneWeather(protocol.weatherId)
end
PBHelper.AddHandler("S2CWeatherChange", OnS2CWeatherChange)