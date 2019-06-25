local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CMallMan = require "Mall.CMallMan"


--处理服务器发送过来的tabs数据
local function OnS2CMallTabsData(sender, protocol)
    --print("页签数据回来", protocol)
    CMallMan.Instance():HandleTabsData(protocol)
end
PBHelper.AddHandler("S2CStoreSetUpRes", OnS2CMallTabsData)

--处理小页签点击后传过来的数据
local function OnS2CMallSmallTabData(sender, protocol)
    --print("小页签数据回来了", protocol)
    CMallMan.Instance():HandleSmallTypeData(protocol)
end
PBHelper.AddHandler("S2CStoreDataRes", OnS2CMallSmallTabData)

--处理商城的角色操作信息
local function OnS2CMallRoleInfo(sender, protocol)
    --print("角色数据回来了", protocol)
    CMallMan.Instance():HandleMallRoleInfo(protocol)
end
PBHelper.AddHandler("S2CStoreSyncInfo", OnS2CMallRoleInfo)

--处理商城购买物品信息
local function OnS2CMallBuyItemData(sender, protocol)
    --print("月卡购买返回消息", protocol)
    CMallMan.Instance():HandleBuyItemReply(protocol)
end
PBHelper.AddHandler("S2CStoreBuyRes", OnS2CMallBuyItemData)

--处理商城刷新
local function OnS2CMallRefresh(sender, protocol)
    CMallMan.Instance():HandleRefreshReply(protocol)
end
PBHelper.AddHandler("S2CStoreMysticalRefreshRes", OnS2CMallRefresh)

--处理商品刷新
local function OnS2CStoreGoodsRefresh(sender, protocol)
    CMallMan.Instance():HandleGoodsRefreshReply(protocol)
end
PBHelper.AddHandler("S2CStoreGoodsRefresh", OnS2CStoreGoodsRefresh)

--处理基金可领取消息（服务器-》客户单 单向）
local function OnS2CMallFundCanRewardInc(sender, protocol)
    CMallMan.Instance():HandleFundCanRewardInc(protocol)
end
PBHelper.AddHandler("S2CFundCanRewardInc",OnS2CMallFundCanRewardInc)

--处理基金领取消息
local function OnS2CMallFundGetReward(sender, protocol)
    CMallMan.Instance():HandleFundGetRewardReply(protocol)
end
PBHelper.AddHandler("S2CFundGetReward", OnS2CMallFundGetReward)

-- 处理月卡领取消息
local function OnS2CMallMonthlyCardGetReward(sender, protocol)
    CMallMan.Instance():HandleMonthlyCardGetRewardReply(protocol)
end
PBHelper.AddHandler("S2CMonthlyGetReward", OnS2CMallMonthlyCardGetReward)

-- 快速兑换回复消息
local function OnS2CQuickStoreBuyReq(sender, protocol)
    CMallMan.Instance():HandleQuickStoreBuyReq(protocol)
end
PBHelper.AddHandler("S2CQuickStoreBuyRes", OnS2CQuickStoreBuyReq)

-- Banner上线的时候消息
local function OnS2CBannerInfo(sender, protocol)
    CMallMan.Instance():HandleBannerInfoData(protocol)
end
PBHelper.AddHandler("S2CBannerInfo", OnS2CBannerInfo)

-- Banner更新消息
local function OnS2CBannerUpdate(sender, protocol)
    CMallMan.Instance():HandleBannerUpdate(protocol)
end
PBHelper.AddHandler("S2CBannerUpdate", OnS2CBannerUpdate)
