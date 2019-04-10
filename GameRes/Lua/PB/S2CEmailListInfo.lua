--
-- S2CEmailListInfo
--

local PBHelper = require "Network.PBHelper"
--邮件列表
local CEmailMan = require "Email.CEmailMan"
local ServerMessageBase = require "PB.data".ServerMessageBase

local ServerMessageEmail = require "PB.data".ServerMessageEmail

--根据返回的code进行不同的提示
local function OnEmailResCode(code)
	if code == ServerMessageEmail.EmailTimeOut then
		game._GUIMan: ShowTipText(StringTable.Get(15002),false)
	elseif code == ServerMessageEmail.EmailNotFindEmail then
		game._GUIMan: ShowTipText(StringTable.Get(15003),false)
	elseif code == ServerMessageEmail.EmailNotHaveReward then
		game._GUIMan: ShowTipText(StringTable.Get(15004),false)
	elseif code == ServerMessageBase.BagFull then
		game._GUIMan: ShowTipText(StringTable.Get(15005),false)
	else
		warn("msg.returnCode == ", code)
	end
end

--初始显示邮件列表
local function OnS2CEmailViewList(sender, msg)
	-- warn("S2CEmailViewList  msg.ResCode ==",  msg.ResCode)
	if msg.ResCode == 0 then
		-- if #msg.EmailInfos == 0 then return end 
		CEmailMan.Instance():EmailViewList(msg.EmailInfos)
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end	
end
PBHelper.AddHandler("S2CEmailViewList", OnS2CEmailViewList)

--读取邮件
local function OnS2CEmailRead(sender, msg)
	if msg.ResCode == 0 then
		if msg.EmailID == 0 then return end 
		CEmailMan.Instance():GetReadEmailID(msg.EmailID)
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end		
end
PBHelper.AddHandler("S2CEmailRead", OnS2CEmailRead)

--领取邮件奖励
local function OnS2CEmailDrawReward(sender, msg)
	if msg.ResCode == 0 then
		if msg.EmailID == 0 then return end 
		CEmailMan.Instance():GetEmailIDToDrawReward(msg.EmailID)	
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end	
	
end
PBHelper.AddHandler("S2CEmailDrawReward", OnS2CEmailDrawReward)

--批量领取邮件奖励
local function OnS2CEmailBatchDrawReward(sender, msg)
	if msg.ResCode == 0 then
		if #msg.EmailID == 0 then return end 
		CEmailMan.Instance():GetEmailIDToBatchDrawReward(msg.EmailID)	
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end			
end
PBHelper.AddHandler("S2CEmailBatchDrawReward", OnS2CEmailBatchDrawReward)


--删除邮件
local function OnS2CEmailRemove(sender, msg)
	if msg.ResCode == 0 then
		if msg.EmailID == 0 then return end 
		CEmailMan.Instance():GetEmailIDToRemove(msg.EmailID)
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Mail_Destory, 0)
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end			
end
PBHelper.AddHandler("S2CEmailRemove", OnS2CEmailRemove)


--批量删除邮件
local function OnS2CEmailBatchRemove(sender, msg)
	if msg.ResCode == 0 then
		game._GUIMan: ShowTipText(StringTable.Get(30346),false)
		if #msg.EmailID == 0 then return end 
		CEmailMan.Instance():GetEmailIDToBatchRemove(msg.EmailID)
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Mail_Destory, 0)
	else
		-- OnEmailResCode(msg.ResCode)
		game._GUIMan:ShowErrorCodeMsg(msg.ResCode, nil)
		return
	end	
		
end
PBHelper.AddHandler("S2CEmailBatchRemove", OnS2CEmailBatchRemove)
