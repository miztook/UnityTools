--=============================================ShowMsgBox========================================================
--[[说明：要显示一个MsgBox,直接调用MsgBox.ShowMsgBox / ShowMsgBoxEx
@param:hwnd, 响应的接受者
@param:msg, 显示的文本
@param:title, 显示的标题（暂时没用到，直接nil就行）
@param:msgType, MsgBox的类型，是MsgBoxType里面的数值，可以是组合,这里默认MBBT_OKCANCEL,两个按钮都显示
	模仿MFC的Box，可以显示MsgBox的不同的图标，此处的MBT_INFO,MBT_OK和MBT_WARN目前没有使用
	eg: MBBT_OK: 显示确定按钮
		MBBT_CACCEL：显示取消按钮
		MBBT_CHECKBOX：显示一个CheckBox，目前没有使用，当需要功能不再提醒的时候可以加入次标志
        MBT_OVERTIME：超时类型，此标识会使MsgBox在ttl(生命周期)结束时候不关闭自己，同时确定和取消按钮的返回类型是超时
		可以组合使用 nType = MBBT_OK | MBBT_CHECKBOX
@param:callback,回调函数，确定和取消按钮的响应事件
	note: function (self,retval)
	@param:self,调用ShowMsgBox时候传入的第一个参数，为一个table类型
	@retval:返回值，为MBRT_OK ,MBRT_CANCEL中的一个
@param:ttl,窗口存在生命周期,单位秒,默认一直存在，ttl结束时候，默认自动关闭窗口，若加入了MBT_OVERTIME标识，则结束后处于超时状态
@param:timercallback,定时器响应
@param:priority,优先级，比如disconnect优先级的话需要优先显示
@param:spectip,特殊提示，MessageBox的第二行显示内容
@param:opencall,box成功打开后做的回调（废弃）

使用方法:
1. MsgBox.ShowMsgBox()
2. MsgBox.ShowMsgBox("消息框内容")
3. MsgBox.ShowMsgBox("消息框内容",nil, MsgBoxType.MBBT_OK)
4. MsgBox.ShowMsgBox("消息框内容","消息框标题", MsgBoxType.MBBT_OKCANCEL,callback)
5. MsgBox.ShowMsgBox("消息框内容",nil, MsgBoxType.MBBT_OKCANCEL,nil,300)
6. MsgBox.ShowMsgBoxEx(sender, "消息框内容")
7. MsgBox.ShowMsgBox("消息框内容","消息框标题", MsgBoxType.MBBT_NONE,callback,nil,nil,nil,6,9)
	local setting = {
        [MsgBoxAddParam.SpecialStr] = specTip,
    }
8. MsgBox.ShowMsgBox("消息框内容","购买次数", MsgBoxType.MBBT_YESNO,callback,nil,nil,nil,setting)
9. MsgBox.ShowMsgBox("消息框内容","消息框标题", bit.bor(MsgBoxType.MBBT_YESNO, MsgBoxType.MBT_TIMEYES),callback,10)
--普通的不再显示msgBox
	local setting = {
        [MsgBoxAddParam.NotShowTag] = "CPanelCharm_0,
    }
10.MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", MsgBoxType.MBBT_OKCANCEL,on_disconect,nil,nil,MsgBoxPriority.Normal,setting)
--位于请求界面之下的不再显示MsgBox
11.MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", MsgBoxType.MBBT_OKCANCEL,nil,nil,nil,MsgBoxPriority.Guide,nil,setting)
--最高层级的不再显示msgBox
12.MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", MsgBoxType.MBBT_OKCANCEL,nil,nil,nil,MsgBoxPriority.Disconnect,nil,setting)
--显示消耗物品的msgbox
    local setting = {
        [MsgBoxAddParam.CostItemID] = 24000,
        [MsgBoxAddParam.CostItemCount] = 2,
    }
13.MsgBox.ShowMsgBox("消息框内容","购买次数", MsgBoxType.MBBT_YESNO,callback,nil,nil,nil,setting)
--显示消耗货币的msgbox
    local setting = {
        [MsgBoxAddParam.CostMoneyID] = 24000,
        [MsgBoxAddParam.CostMoneyCount] = 2555,
    }
14. MsgBox.ShowMsgBox("消息框内容","购买次数", MsgBoxType.MBBT_YESNO,callback,nil,nil,nil,setting)
一、**在game_text里面配置的MsgBox使用方法：**
	local title, msg, closeType = StringTable.GetMsg(4)
    MsgBox.ShowMsgBox(strMsg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil,nil,MsgBoxPriority.Noranl, 等等（除了第一个参数增加的，其他和msgbox参数一样）)
二、**在数据编辑器里面配置的MsgBox使用方法：**
	MsgBox.ShowSystemMsgBox(errorID(SystemNotify的tid), message(""), title(""), MsgBoxType.MBBT_OK, 等等) message和title可以为“”，如果为空是会使用配置表里面的数据，如果不为空使用传入的参数。

注意:
1. 当前的 timercallback 返回值都是 false
]]
--=============================================ShowQuickBuyBox========================================================
--[[ ShowQuickBuyBox说明：用来消耗货币的时候的条件判断和弹窗处理
@param:costMoneyID      需要花费的MoneyID
@param:moneyCost        需要花费的总数量
@param:cb               玩家点击确认或者取消的回调函数，回调函数需要一个val参数
@param:externCondition  外部条件集合

使用方法：
    local limit = {
        [EQuickBuyLimit.RoleLevel] = 40,
        [EQuickBuyLimit.AdventureLevel] = 3,
        [EQuickBuyLimit.FunID] = 15,
         ......
    }
    MsgBox.ShowQuickBuyBox(CostMoneyId, CostMoneyCount, callback, limit)
    如果最后一个参数 limit 不传或者传nil，默认不会判断外部条件，直接走快速购买逻辑
]]

local bit = require "bit"

--MsgBox界面类型
_G.MsgBoxType = 
{
	--可能涉及到的图标类型
	MBT_INFO            = bit.lshift(1,0),
	MBT_OK              = bit.lshift(1,1),
	MBT_WARN            = bit.lshift(1,2),
	MBT_AUTOCLOSE       = bit.lshift(1,3),  --失去焦点时关闭

	--可能涉及到的按钮类型
	MBBT_OK             = bit.lshift(1,4),
	MBBT_CANCEL         = bit.lshift(1,5),
	MBBT_CHECKBOX       = bit.lshift(1,6),	--可能涉及到的选择框 (如:不再提示)
	MBBT_OKCANCEL       = bit.bor(bit.lshift(1,4),bit.lshift(1,5)), --默认显示两个按钮

	MBT_OVERTIME        = bit.lshift(1,7), --超时类型

	MBBT_YES            = bit.lshift(1,8),
	MBBT_NO             = bit.lshift(1,9),
	MBBT_YESNO          = bit.bor(bit.lshift(1,8),bit.lshift(1,9)),
	MBBT_NONE			= bit.lshift(1,10), -- 没有按钮，点击任何关闭

	MBT_SPEC			= bit.lshift(1,11), -- 显示特殊信息

	-- 两者为 或 的关系
	MBT_TIMEYES			= bit.lshift(1,12), -- 时间到自动选是（真）
	MBT_TIMENO			= bit.lshift(1,13), -- 时间到自动选否（假）
    MBT_NOCLOSEBTN		= bit.lshift(1,14),	-- 关闭按钮
}


--返回值类型
_G.MsgBoxRet = 
{
	MBRT_CANCEL    = 0,
	MBRT_OK        = 1,
	MBRT_OKCHECKED = 2,
	MBRT_OVERTIME  = 3,
}

--MsgBox的优先级,值越大越先显示
_G.MsgBoxPriority = 
{
	None = 0,
	Normal = 1,      --正常
	Guide = 2,       --引导
	Quit = 3,       -- QuitGame
	Disconnect = 100,  --断线提示优先级最高
}

--MsgBox的额外显示条件
_G.MsgBoxAddParam = 
{
    SpecialStr = 1,         -- 特殊字（比如：今日可购买次数xx/xx）
    NotShowTag = 2,         -- 不再显示的tag标识（比如“CPanelCharm_01”,用来记录用）
    CostItemID = 3,         -- 花费的物品ID
    CostItemCount = 4,      -- 花费的物品数量
    CostMoneyID = 5,        -- 花费的货币ID
    CostMoneyCount = 6,     -- 花费的货币的数量
    GainMoneyID = 7,        -- 获得的货币ID
    GainMoneyCount = 8,     -- 获得的货币数量
    GainItemID = 9,         -- 获得的物品ID
    GainItemCount = 10,     -- 获得的物品数量
}

-- 快速购买弹窗外部条件
_G.EQuickBuyLimit = 
{
    AdventureLevel      = 1,    -- 冒险生涯等级
    ReputationType      = 2,    -- 声望类型
    ReputationLevel     = 3,    -- 声望等级
    RoleLevel           = 4,    -- 角色等级
    FunID               = 5,    -- 功能解锁ID
    CurBuyCount         = 6,    -- 当前购买次数
    MaxBuyCount         = 7,    -- 购买次数上限
    MatID               = 8,    -- 消耗材料
    MatNeedCount        = 9,    -- 消耗材料数量
    PetBagBuyCount      = 10,   -- 要购买的宠物背包格子数
    PetBagMaxSlotCount  = 11,   -- 宠物背包上限
    BagBuyCount         = 12,   -- 要购买的主句背包数量
    BagMaxSlotCount     = 13,   -- 主角背包上限
    LuckRefMaxCount     = 14,   -- 运势最大刷新次数
}

local _MsgBoxEx = function (hwnd,lpszText,lpszCaption,nType,callback,ttl,timercallback,priority,setting)
	if lpszText == nil then lpszText = "" end
	if lpszCaption == nil or lpszCaption == "" then lpszCaption = "MsgBox" end
	if not nType then nType = MsgBoxType.MBBT_OKCANCEL end
	if not ttl then ttl = 0 end
	if not priority then priority = 1 end
	local boxMan = require "GUI.CMsgBoxMan"
	boxMan.Instance():ShowMsgBox(hwnd,lpszText,lpszCaption,nType,callback,ttl,timercallback,priority,setting)
end

local _MsgBox = function (lpszText,lpszCaption,closeType,nType,callback,ttl,timercallback,priority,setting)
    local op_type = closeType == 0 and nType or bit.bor(nType, MsgBoxType.MBT_NOCLOSEBTN)
	_MsgBoxEx(nil,lpszText,lpszCaption,op_type,callback,ttl,timercallback,priority,setting)
end

--local _MsgBoxByID = function(msgID, lpszText, lpszCaption, nType, callback, ttl, timercallback, priority, lpszSpecText, notShowTag)
--	local title, str, close_type = StringTable.GetMsg(msgID)
--	local op_type = close_type == 0 and nType or bit.bor(nType, MsgBoxType.MBT_NOCLOSEBTN)
--	_MsgBoxEx(nil,lpszText,lpszCaption,op_type,callback, ttl, timercallback, priority, lpszSpecText, notShowTag)	
--end

local _MsgBoxSystem = function(sysTid, lpszText, lpszCaption, nType, callback, ttl, timercallback, priority, setting)
	if not sysTid then sysTid = 0 end
	if lpszText == nil then lpszText = "" end
	if lpszCaption == nil then lpszCaption = "" end
	if not nType then nType = MsgBoxType.MBBT_OKCANCEL end
	if not ttl then ttl = 0 end
	if not priority then priority = 1 end
	local boxMan = require "GUI.CMsgBoxMan"
	boxMan.Instance():ShowSystemMsgBox(sysTid, nil, lpszText,lpszCaption, nType, callback, ttl, timercallback, priority, setting)
end

--[[    第一个参数类型为以下结构
        local rewardTable = {
            {
                ID = costMoneyID,
                Count = moneyCost,
                IsMoney = is_money
            }, 。。。
        }
]]
local _QuickBuyTable = function(rewardTable, cb)
    local is_all_right = true
    for i,v in ipairs(rewardTable) do
        if v.IsMoney == nil or v.ID == nil or v.Count == nil then
            warn("快速兑换参数不对")
            return
        end
        local have_count = 0
        if v.IsMoney then
            have_count = game._HostPlayer:GetMoneyCountByType(v.ID)
        else
            have_count = game._HostPlayer._Package._NormalPack:GetItemCount(v.ID)
        end
        if have_count < v.Count then
            is_all_right = false
        end
    end
    if is_all_right then
        if cb ~= nil then
            cb(true)
        end
    else
        local data = {targetRewardTable = rewardTable, callback = cb}
        game._GUIMan:Open("CPanelQuickBuy", data)
    end
end

local _QuickBuyBox = function(costMoneyID, moneyCost, cb, externCondition, isMoney)
    local is_money = (isMoney == nil and true or isMoney)
    local CMallUtility = require "Mall.CMallUtility"
    if CMallUtility.CheckQuickBuyExternalCondition(externCondition) then
        local have_count = 0
        if is_money then
            have_count = game._HostPlayer:GetMoneyCountByType(costMoneyID)
        else
            have_count = game._HostPlayer._Package._NormalPack:GetItemCount(costMoneyID)
        end
        if have_count >= moneyCost then
            if cb ~= nil then
                cb(true)
            end
        else
            local quick_buy_temp = CMallUtility.GetQuickBuyTemp(costMoneyID, is_money)
            if quick_buy_temp == nil then
                local CElementData = require "Data.CElementData"
                if is_money then
                    local money_temp = CElementData.GetMoneyTemplate(costMoneyID)
                    game._GUIMan:ShowTipText(string.format(StringTable.Get(268), money_temp.TextDisplayName), true)
                else
                    game._GUIMan:ShowTipText(string.format(StringTable.Get(268), RichTextTools.GetItemNameRichText(costMoneyID, 1, false)), true)
                end
            else
                local rewardTable = {
                    {
                        ID = costMoneyID,
                        Count = moneyCost,
                        IsMoney = is_money
                    },
                }
                local data = {targetRewardTable = rewardTable, callback = cb}
                game._GUIMan:Open("CPanelQuickBuy", data)
            end
        end
    end
end

local _IsShow = function ()
	local boxMan = require "GUI.CMsgBoxMan"
	return (boxMan.Instance():GetMsgListCount() > 0)
end

local _CloseAll = function ()
	local boxMan = require "GUI.CMsgBoxMan"
	boxMan.Instance():RemoveAll()
end

local _CloseAllExceptDisconnect = function()
    local boxMan = require "GUI.CMsgBoxMan"
    boxMan.Instance():RemoveAllExceptDisconnect()
end

local _RemoveAllBoxes = function()
    local boxMan = require "GUI.CMsgBoxMan"
	boxMan.Instance():RemoveAllBoxes()
end


local MsgBox = 
{
	ShowMsgBox = _MsgBox,
	--ShowMsgBoxEx = _MsgBoxEx,
--	ShowMsgBoxByID = _MsgBoxByID,
	ShowSystemMsgBox = _MsgBoxSystem,
    ShowQuickBuyBox = _QuickBuyBox,
    ShowQuickMultBuyBox = _QuickBuyTable,
	IsShow = _IsShow,
	CloseAll = _CloseAll,
    CloseAllExceptDisconnect = _CloseAllExceptDisconnect,
    RemoveAllBoxes = _RemoveAllBoxes,
}

_G.MsgBox = MsgBox