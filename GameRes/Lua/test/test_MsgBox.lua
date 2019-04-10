-- test case
local bit = require "bit"

print("show a msgbox")
local on_disconect = function (retval)
	warn("点击确定按钮重新登陆", retval)
end

--MsgBox.CloseAll()

MsgBox.ShowMsgBox("与服务器连接已断开0000","断线提示", 0, MsgBoxType.MBBT_OKCANCEL,on_disconect)
MsgBox.ShowMsgBox("与服务器连接已断开1111","断线提示", 0, MsgBoxType.MBBT_YES,on_disconect)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢1","坑爹啊", 0, MsgBoxType.MBBT_YESNO, on_disconect, nil, nil, MsgBoxPriority.Disconnect)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢2","坑爹啊", 0, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_TIMEYES),on_disconect,3,nil,MsgBoxPriority.Disconnect)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢3","坑爹啊", 0, MsgBoxType.MBBT_OK,on_disconect,nil,nil,MsgBoxPriority.Guide)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢4","坑爹啊", 0, MsgBoxType.MBBT_NONE,on_disconect,5,function() warn("倒计时超时！！") end)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢5","坑爹啊", 0, MsgBoxType.MBBT_NONE,on_disconect)
MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢6","坑爹啊", 0, MsgBoxType.MBBT_OK,on_disconect,nil,nil,MsgBoxPriority.Normal)
MsgBox.ShowMsgBox("确定花费100[e]E_2[-]购买", "购买次数", 0, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_SPEC),on_disconect,nil,nil,nil,"今日可购买次数：6/9")
MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", 0, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_NOTSHOW),on_disconect,nil,nil,MsgBoxPriority.Normal,nil,"CPanelCharm_0")
MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", 0, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_NOTSHOW),nil,nil,nil,MsgBoxPriority.Guide,nil,"CPanelCharm_1")
MsgBox.ShowMsgBox("勾选不再显示，以后再次有相同操作会直接以确定的形式处理", "不再显示提示", 0, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_NOTSHOW),nil,nil,nil,MsgBoxPriority.Disconnect,nil,"CPanelCharm_2")
    
--MsgBox.CloseAll()

local on_failed = function (retval)
	MsgBox.ShowMsgBox("与服务器连接已断开0000","断线提示", 0, MsgBoxType.MBBT_OKCANCEL,on_disconect)
	MsgBox.ShowMsgBox("与服务器连接已断开1111","断线提示", 0, MsgBoxType.MBBT_OKCANCEL,on_disconect)
	MsgBox.CloseAll()
	MsgBox.ShowMsgBox("算了，我放弃了1！！","坑爹啊", 0, MsgBoxType.MBBT_NO)
	MsgBox.ShowMsgBox("算了，我放弃了2！！","坑爹啊", 0, MsgBoxType.MBBT_OK, function() warn("OK!!!!") end)
	MsgBox.ShowMsgBox("算了，我放弃了3！！","坑爹啊", 0, MsgBoxType.MBBT_OK, function() warn "test end" end)
end

MsgBox.ShowMsgBox("与服务器连接已断开，咋又断了呢7","坑爹啊", 0, MsgBoxType.MBBT_OKCANCEL,on_failed)