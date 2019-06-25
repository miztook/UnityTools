-- 这里会写一些通用接口

-- 改变UI上面有非动态加载特效的层级，传的是特效gameobject和层级，这个层级要比当前panel高就行
GameUtil.SetUISfxLayer(go, layer)

-- 从game_text.lua获取字符串
StringTable.Get(id)

-- Tip提示
FlashTip(errorCodeConst, "tip", 3)

--上飘字提示
game._GUIMan: ShowTipText("Test",true)

--下飘字提示
game._GUIMan: ShowTipText("Test",false)

----带图标的提示
--game._GUIMan:ShowIconAndTextTip("IconPath","前缀XX","后缀XX")

--走马灯置顶提示
game._GUIMan:OpenSpecialTopTips("Test")

-- 系统错误码下飘字提示
game._GUIMan:ShowErrorTipText(ErrorCode)

--消耗钱币购买东西
CUseDiamondMan.Instance():BuyItemUseDiamond("PanelName",1061001,1,callBackOK,callBackCancel)
--消耗钱币开启功能
CUseDiamondMan.Instance():DirectlyUseDiamond("PanelName",2,10,testOKDiamond,testCanelDiamond)
--交易行,拍卖行等，有自己货币标准的购买
CUseDiamondMan.Instance():DirectlyUseDiamondBuyItem("Test",2,10000,testOKDiamond,testCanelDiamond,1061001,1)

--滚动提示
game._GUIMan:ShowMoveItemTextTips(40004,false,"X 1000_",true)

--滚动提示
game._GUIMan:ShowMoveTextTips("我就只是做个测试而已")

--错误码提示
game._GUIMan:ShowErrorCodeMsg(ErrorCode, nil)


-- 打印lua调用堆栈
warn(debug.traceback())

--传送到某一个地图
local CTransManage = require "Main.CTransManage"
CTransManage.Instance():TransByMapID(XXX)

--传送到某一个的地图的具体位置
CTransManage.Instance():TransByMapIDAndPos(XXX,XXX)

--===========================================================
-- 同一张地图从一个点走到另一个点
-----------------------------------------------------------
HostPlayer:Move( ... )    
-- Entity函数重载，就是走到一个点，无其他行为；推荐用在Entity相关类中
-- 不会出现自动寻路的标志
-- 没有上下马的检查判断

game:NavigatToPos( ... )  
-- 对HostPlayer自身外的系统提供HostPlayer移动接口，有地图是否加载完毕的判断
-- 不会出现自动寻路的标志
-- 没有上下马的检查判断

--CTransManage.Instance():StartMoveToPos(targetPos, cb, true) 废弃！！！
-- 自动寻路接口
-- 自动显示 自动寻路 的标志
-- 有是否需要上下马的检查判断

--===========================================================
-- C#获取 lua函数返回的一个表（数组型）
--[[
LuaDLL.lua_getglobal(L, "GetTable")
if (L.PCall(0, 1) == false)
{
    LuaDLL.lua_pop(L, 1)
    return
}
len = LuaDLL.lua_objlen(L, -1)
for (int i = 1; i <= len; i++)
{
    LuaDLL.lua_rawgeti(L, -1, i)
    int id = LuaDLL.lua_tonumber(L, -1);
	// TODO: use id to do something
	
    LuaDLL.lua_pop(wLua.L.L, 1)
}
LuaDLL.lua_pop(L, 1)
]]

-- clone的控件添加事件注册
GUITools.RegisterButtonEventHandler(panel_obj, btn_obj) 
GUITools.RegisterGTextEventHandler(panel_obj, gtext_obj)

--格式化float 保留两位，末位为0忽略
fixFloat(0.1999999999999)		--输出结果 加了个0.0000001 解决精度问题
fmtVal2Str(0.1999999999999)   	--输出为 0.2 的字符串
fixFloatStr(0.19999999)    		--输出为 0.2 的字符串
fixFloatStr(0.19999999, 3)		--输出为 0.20 的字符串

--==================================================
--交互式组件使用
--==================================================
local comps = {
    --根据不同逻辑insert到这个table里
    MenuComponents.InviteMemberComponent.new(targetEntiy._ID),
    MenuComponents.AddFriendComponent.new(targetEntiy._ID),
    MenuComponents.SeePlayerInfoComponent.new(targetEntiy._ID),
}
--通用交互式组件，参数（#1按钮组件列表，#2停靠的目标，#3停靠的方位）
MenuList.Show(comps, alignTarget, EnumDef.AlignType.Bottom)


--===========================================================
-- 次数组购买接口，参数（当前剩余次数，次数组ID）
-----------------------------------------------------------
game._CCountGroupMan:BuyCountGroup(CurNum,CountGroupTid)

local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
        -- 更新对应界面信息
        warn("CountGroupUpdateEvent event._CountGroupTid ==", event._CountGroupTid)
	end
end
CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)


--===========================================================
-- 自定义头像接口
-----------------------------------------------------------
-- 1、Image 2、roleId 3、CustomImgSet 4、Gender 5、Profession
game: SetEntityCustomImg(imgObj , 
                         roleId ,
                         customImgSet , 
                         gender , 
                         profession)

local function OnNotifyPropEvent(sender, event)
    if event.Type == "CustomImg" then
		-- 更新对应界面自定义头像
    end
end
CGame.EventManager:addHandler("NotifyPropEvent", OnNotifyPropEvent)
CGame.EventManager:removeHandler("NotifyPropEvent", OnNotifyPropEvent)

-----------------------------------------------------------------

-- 通用货币栏
local CFrameCurrency = require "GUI.CFrameCurrency"
def.field(CFrameCurrency)._Frame_Money = nil
-- OnCreate : 第三个参数是对应的显示类型、需要在ClientDef里添加MoneyStyleType 。MoneyType是货币种类需要与MoneyStyleType类型对应
self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)

-- OnClick:
if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
	return
end

-- OnDestory : 
if self._Frame_Money ~= nil then
  self._Frame_Money:Destroy()
  self._Frame_Money = nil
end
-----------------------------------------------------------------
-- 通用按钮
local CCommonBtn = require "GUI.CCommonBtn"
def.field(CCommonBtn)._CommonBtn = nil
-- OnData : btn_GO 是通用按钮的预设， setting里面第一个用来设置按钮上的文字，如果有金币图标后面两个也需要传，没有不用传
local setting = {
    [EnumDef.CommonBtnParam.BtnTip] = "1111",
    [EnumDef.CommonBtnParam.MoneyID] = 1,
    [EnumDef.CommonBtnParam.MoneyCost] = 222   
}
self._CommonBtn = CCommonBtn.new(btn_GO ,setting)

-- OnClick:
if self._CommonBtn ~= nil and self._CommonBtn:OnClick(id) then
	self:DoSomeThing()
end

-- OnDestory : 
if self._CommonBtn ~= nil then
  self._CommonBtn:Destroy()
  self._CommonBtn = nil
end

-- 额外方法：

self._CommonBtn:MakeGray(true)          -- 是否置灰
self._CommonBtn:SetActive(true)         -- 是否显示
self._CommonBtn:ShowFlashFx(true)       -- 是否闪光

-- GUITools里面提供的方法：
-- GUITools里面提供设置置灰和闪光的接口（用在List里面的item上的button）
	GUITools.SetBtnGray(obj, true/false)		-- 置灰
	GUITools.SetBtnFlash(obj, true/false)		-- 闪光

-----------------------------------------------------------------
-- 通用输入框
--1）在OnData() 里面初始化：
local onCountChange= function(count)
	-- 更新界面等操作
end
	self._ComoonInput = CCommonNumInput.new(input_GO, onCountChange,min,max)
--2）在OnClick(id)里面调用点击：
	if self. _ComoonInput:OnClick(id)  then
		return
	else
  end
--3）在OnDestory()函数里面销毁：
	self. _ComoonInput:Destroy()
	self._ComoonInput = nil
-----------------------------------------------------------------
