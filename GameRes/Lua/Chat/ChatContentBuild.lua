local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ChatManager = Lplus.ForwardDeclare("ChatManager")

local ChatContentBuild = Lplus.Class("ChatContentBuild")
local def = ChatContentBuild.define


--玩家自己发送的实例化FrameMeChat
def.static("table","=>","string").BuildHostPlayerMsg = function(msg)
	local channel = msg.Channel

    local StrRichMsg = ""
    if (channel == CHAT_CHANNEL_ENUM.ChatChannelCurrent or
			channel == CHAT_CHANNEL_ENUM.ChatChannelWorld or
			channel == CHAT_CHANNEL_ENUM.ChatChannelTeam or
			channel == CHAT_CHANNEL_ENUM.ChatChannelGuild) then

        --role_name
		local strContent = msg.PlayerName
       
        if msg.Result == SendStatus.Success then --发送成功的
            local strsend = msg.StrMsg            
            StrRichMsg = strContent .. strsend
        else
        	warn("发送消息失败")
        end
    elseif channel == CHAT_CHANNEL_ENUM.ChatChannelSystem then
        --系统消息
        StrRichMsg = msg.StrRichMsg   
        -- warn("system message") 
    end
	local content = channel ..StrRichMsg  --频道名字 + 玩家名字 + 聊天内容 
	return content
end
--其他玩家的实例化FramePlayerChat
def.static("table","=>","string").BuildElsePlayerMsg = function(msg)
	local PLayerchannel = msg.Channel

    local StrRichMsg = ""
    if (PLayerchannel == CHAT_CHANNEL_ENUM.ChatChannelCurrent or
			PLayerchannel == CHAT_CHANNEL_ENUM.ChatChannelWorld or
			PLayerchannel == CHAT_CHANNEL_ENUM.ChatChannelTeam or
			PLayerchannel == CHAT_CHANNEL_ENUM.ChatChannelGuild) then

        --role_name

        local strContent = msg.PlayerName
        StrRichMsg = strContent .. msg.StrMsg

    elseif PLayerchannel == CHAT_CHANNEL_ENUM.ChatChannelSystem then
        StrRichMsg = msg.StrRichMsg
        -- warn("system message") 
    end
	local content = PLayerchannel .. StrRichMsg
	return content
end

def.static("table","=>","string").BuildOneMsg = function(msg)
	if msg.RoleId == game._HostPlayer._ID then --是玩家自己发的
		return ChatContentBuild.BuildHostPlayerMsg(msg)
	else
		return ChatContentBuild.BuildElsePlayerMsg(msg)
	end
end

def.static("table","=>","string").BuildSmallPanelMsg = function(msg)
    local channel = msg.Channel

    --role_name
    local playerChatName = msg.PlayerName
    local StrRichMsg = ""
    if msg.Result ~= SendStatus.Success then --未发送成功的
        local strsend = msg.StrMsg
        --print("small_content",strsend)
    end

    local strContent = playerChatName .. StrRichMsg
    local content = channel .. strContent
    return content
end

def.static("number","=>","string").GenChannelText = function(channel)
    local data = Data.Channel[channel]
    local channelname = data.channelname
    local channelcolor = data.channelcolor
    return string.format("[%s]%s[-]",channelcolor,channelname)
end



ChatContentBuild.Commit()
return ChatContentBuild
