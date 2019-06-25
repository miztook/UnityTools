--[[

Method Param:

    【sender】            使用者当前节点的 instance, 一般使用self即可
    【curItemList】       需要展现的列表数据List
    【initItemFunc】      列表初始化回调函数 var(sender,item,data)
    【OnSelectItem】      列表选中回调函数   var(sender,item,data)
    【showTipType】       tips弹出类型
    【conditionFunc】     Drop的回调函数 var(index) return( curItemList ) 下拉页签回调函数
    【conditions】        Drop过滤器筛选标签

]]

-- 有待添加
_G.ShowTipType = 
{
    ShowPackbackTip = 1,
    ShowItemTip = 2,
    ShowPetTip = 3,
    None = 0,
}
local _ItemListManPanel = function (sender,curItemList,initItemFunc,selectItemCall,showTipType,conditionFunc,allConditionList,approachMaterialType)
	local data = {}

    data.Sender = sender
	data.CurItemList = curItemList
    data.InitItemFunc = initItemFunc
    data.SelectItemCall = selectItemCall
    data.ShowTipType = showTipType
    data.ConditionFunc = conditionFunc
    data.AllConditionList = allConditionList
    data.ApproachMaterialType = approachMaterialType

	game._GUIMan:Open("CPanelItemList",data)
end

local ItemListMan = 
{
	ShowItemListManPanel = _ItemListManPanel,
}
_G.ItemListMan = ItemListMan