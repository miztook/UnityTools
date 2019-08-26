local CNotificationMan = require "Main.CNotificationMan"
local MsgNotify = {}
do
    MsgNotify.DisappearTime = 10

    MsgNotify.Add = function(notify)
        CNotificationMan.Instance():Add(notify)
    end

    MsgNotify.Remove = function(notifyType)
        CNotificationMan.Instance():Remove(notifyType)
    end

    MsgNotify.Front = function()
        return CNotificationMan.Instance():Front()
    end

    MsgNotify.PopUp = function()
        return CNotificationMan.Instance():PopUp()
    end

    MsgNotify.NotifyUI = function()
        CNotificationMan.Instance():NotifyUI()
    end

    MsgNotify.Cleanup = function()
        CNotificationMan.Instance():Cleanup()
    end

    MsgNotify.ShowNormalNotify = function(title, des, callback)
        if type(title) ~= "string" or type(des) ~= "string" or type(callback) ~= "function" then
            warn("error!!! MsgNotify.ShowNormalNotify  param type error")
            return
        end
        CNotificationMan.Instance():ShowNormalNotify(title, des, callback)
    end
end

_G.MsgNotify = MsgNotify
