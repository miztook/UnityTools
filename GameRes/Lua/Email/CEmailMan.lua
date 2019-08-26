local Lplus = require "Lplus"
local UserData = require "Data.UserData".Instance()

local CEmailMan = Lplus.Class("CEmailMan")
local CEmail = require "Email.CEmail"
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local EMAIL_TYPE_ENUM = require "PB.data".EmailType
local def = CEmailMan.define

def.field("table")._EmailList = BlankTable

local _instance = nil
def.static("=>", CEmailMan).Instance = function ()
    if _instance == nil then
        _instance = CEmailMan()
    end
    return _instance
end

--创建一个Email
def.method("=>",CEmail).NewEmail = function(self)
    return CEmail.new()
end

--				Client::Email Funcs
----------------------------------------------------------------------
def.method("table").EmailViewList = function(self, emailInfo)
    self._EmailList = {}
    -- warn(" EmailViewList #emailInfo == ", #emailInfo)
    for i= 1 , #emailInfo do         
        local email = self:NewEmail()
        local EInfo = emailInfo[i]
        local template_email = CElementData.GetTemplate("Email", EInfo.EmailType)
        if template_email ~= nil then
        --如果发件人信息和内容有一个是空的就从模板数据中查找
            if EInfo.TextParam.SenderName == ""
            or EInfo.TextParam.Title == ""
            or EInfo.TextParam.Content == "" then 
                local emailStr = ""    
                -- warn("lidaming   ----> EInfo.EmailType ==", EInfo.EmailType)
                --竞技场/公会走多条提示邮件
                if EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_Affirm then   --8、要塞资格确认邮件(成功/失败)
                    local param = EInfo.TextParam.FortressSelf                
                    if param.Rank ~= nil then  --自己公会                
                        if param.Success ~= false then                       
                            local selfStr = string.format(StringTable.Get(15006), param.Score)   --成功  
                            local otherStr = ""
                            if EInfo.TextParam.FortressOther ~= nil then --其他公会                     
                                for _,k in pairs(EInfo.TextParam.FortressOther) do 
                                    if k.Rank ~= nil and k.GuildName ~= nil and k.Score ~= nil then
                                        local str = string.format(StringTable.Get(15008), k.Rank, RichTextTools.GetGuildNameRichText(k.GuildName, false), k.Score)
                                        otherStr = otherStr .. str
                                    end
                                end                                
                            end
                            emailStr = selfStr .. otherStr
                        else 
                            local selfStr = string.format(StringTable.Get(15007), param.Score)     --失败
                            local otherStr = ""
                            if EInfo.TextParam.FortressOther ~= nil then --其他公会                     
                                for _,k in pairs(EInfo.TextParam.FortressOther) do 
                                    if k.Rank ~= nil and k.GuildName ~= nil and k.Score ~= nil then
                                        local str = string.format(StringTable.Get(15008), k.Rank, RichTextTools.GetGuildNameRichText(k.GuildName, false), k.Score)
                                        otherStr = otherStr .. str
                                    end
                                end
                            end
                            emailStr = selfStr .. otherStr
                        end  
                    
                    else
                        warn("Email Undeveloped content!!!")                             
                    end
                elseif  EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_Arena then   --4、竞技场邮件 
                    local param =  EInfo.TextParam.Arena
                    if param ~= nil then 
                        emailStr = string.format(template_email.Content,tostring(param.Rank))
                    end
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildMemberAdd then -- 20、工会成员加入邮件  
                    local GuildName =  EInfo.TextParam.GuildName
                    if GuildName ~= nil then 
                        emailStr = string.format(template_email.Content,RichTextTools.GetGuildNameRichText(GuildName, false))
                    end
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildLeaderChange then -- 23、会长转让邮件  
                    local OptRoleName =  EInfo.TextParam.OptRoleName
                    if OptRoleName ~= nil then 
                        emailStr = string.format(template_email.Content,RichTextTools.GetElsePlayerNameRichText(OptRoleName, false))
                    end
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildKickMember then  -- 24、踢出玩家邮件  先操作者名字，再公会名字
                    local GuildName =  EInfo.TextParam.GuildName
                    local OptRoleName =  EInfo.TextParam.OptRoleName
                    if GuildName ~= nil and OptRoleName ~= nil then 
                        emailStr = string.format(template_email.Content,RichTextTools.GetElsePlayerNameRichText(OptRoleName, false),RichTextTools.GetGuildNameRichText(GuildName, false))
                    end
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_MarketSellerReward or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_AuctionSellerReward then  -- 13、交易行卖家奖励邮件  or 15、拍卖行卖家奖励邮件
                    local ETextParam = EInfo.TextParam   
                    local strTime = os.date("%Y-%m-%d", ETextParam.OptTime)
                    local template = CElementData.GetItemTemplate(ETextParam.ItemTid)
                    if template == nil then
                        emailStr = string.format(template_email.Content,tostring(strTime),tostring(ETextParam.ItemTid),tostring(ETextParam.ItemNum),tostring(ETextParam.Price),tostring(ETextParam.Tax),tostring(ETextParam.Earn))
                    else
                        emailStr = string.format(template_email.Content,tostring(strTime),RichTextTools.GetItemNameRichText(ETextParam.ItemTid, 1,false),tostring(ETextParam.ItemNum),tostring(ETextParam.Price),tostring(ETextParam.Tax),tostring(ETextParam.Earn))
                    end

                    
                
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_AuctionBuyerReward or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_MarketBuyerReward then  -- 14、拍卖行买家奖励邮件  or  12、交易行买家奖励邮件   
                    local ETextParam = EInfo.TextParam 
                    local strTime = os.date("%Y-%m-%d", ETextParam.OptTime) 
                    local template = CElementData.GetItemTemplate(ETextParam.ItemTid)  
                    if template == nil then
                        emailStr = string.format(template_email.Content,tostring(strTime),tostring(ETextParam.ItemTid),tostring(ETextParam.ItemNum),tostring(ETextParam.Price))
                    else
                        emailStr = string.format(template_email.Content,tostring(strTime),RichTextTools.GetItemNameRichText(ETextParam.ItemTid, 1,false),tostring(ETextParam.ItemNum),tostring(ETextParam.Price))
                    end
                    
                
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_MarketBiddingFailed then  -- 27、拍卖行竞价失败邮件
                    local ETextParam = EInfo.TextParam   
                    local strTime = os.date("%Y-%m-%d", ETextParam.OptTime)         
                    local template = CElementData.GetItemTemplate(ETextParam.ItemTid)   
                    if template == nil then
                        emailStr = string.format(template_email.Content,tostring(strTime),tostring(ETextParam.Price),tostring(ETextParam.ItemTid))
                    else
                        emailStr = string.format(template_email.Content,tostring(strTime),tostring(ETextParam.Price),RichTextTools.GetItemNameRichText(ETextParam.ItemTid, 1,false))
                    end  
                
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_MarketShareMoney then  -- 28、公会分红邮件
                    local ETextParam = EInfo.TextParam          
                    local template = CElementData.GetItemTemplate(ETextParam.ItemTid)   
                    if template == nil then
                        emailStr = string.format(template_email.Content,RichTextTools.GetElsePlayerNameRichText(ETextParam.BuyerName,false),tostring(ETextParam.Price),tostring(ETextParam.ItemTid),tostring(ETextParam.Earn))
                    else
                        emailStr = string.format(template_email.Content,RichTextTools.GetElsePlayerNameRichText(ETextParam.BuyerName,false),tostring(ETextParam.Price),RichTextTools.GetItemNameRichText(ETextParam.ItemTid, 1,false),tostring(ETextParam.Earn))
                    end

                    -- EmailType_MarketShareMoney
                    -- BuyerName     Price  ItemTid Earn

                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildBFMatch then  -- 33、公会战场对阵信息
                    local ETextParam = EInfo.TextParam          
                    emailStr = string.format(template_email.Content,ETextParam.OptGuildName)

                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildBFSeason then  -- 44、公会战场赛季奖励
                    local ETextParam = EInfo.TextParam          
                    emailStr = string.format(template_email.Content, tostring(ETextParam.BFRankId))
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildLivenessRank then  -- 48、公会工资
                    local ETextParam = EInfo.TextParam          
                    emailStr = string.format(template_email.Content, ETextParam.GuildName, tostring(ETextParam.LivenessRank), GUITools.FormatMoney(ETextParam.GuildLevelDiamond))
                elseif EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_RefuseApply then  -- 58、拒绝申请
                    local ETextParam = EInfo.TextParam          
                    emailStr = string.format(template_email.Content, tostring(ETextParam.GuildName))
                else  -- 一条邮件提示
                    -- if EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_System  --1、系统
                    -- or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GuildAssign    --2、公会分配奖励
                    -- or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_GM   --3、GM邮件
                    -- or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_BagFull   --5、背包满补发道具邮件
                    -- or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_Activity   --6、活动邮件
                    -- or EInfo.EmailType == EMAIL_TYPE_ENUM.EmailType_YunYing    --7、运营邮件 
                    emailStr = template_email.Content 
                end
                email._SenderName = template_email.SenderName
                email._Title = template_email.Titile
                email._Content = emailStr
            else
                --显示服务器传过来的发件人信息和内容
                -- warn("Server to Client EmailInfo!!!")
                email._SenderName = EInfo.TextParam.SenderName
                email._Title = EInfo.TextParam.Title
                email._Content = EInfo.TextParam.Content
            end

            email._EmailID = EInfo.EmailID
            email._Type = EInfo.EmailType
            email._IsRead = EInfo.IsRead
            email._IsDraw = EInfo.IsDraw
            email._CreateTime = EInfo.CreateTime
            email._RewardItem = EInfo.ItemInstance
            email._Reward = EInfo.Reward   
            email._RewardId = EInfo.RewardId
            email._DurationSecond = EInfo.DurationSecond

            if EInfo.RewardLevel == 0 then
                email._Level = 1
            else
                email._Level = EInfo.RewardLevel
            end

            if #EInfo.Reward == 0 and #EInfo.ItemInstance == 0 and email._RewardId == 0  then 
                email._IsHaveReward = false
            else
                email._IsHaveReward = true
            end
            -- table.insert(self._EmailList, 1, email)
            self._EmailList[#self._EmailList + 1] = email
        end
    end
    self:OnEmailListData()
end

--邮件列表
def.method("=>","table").GetEmailList = function(self)
	return self._EmailList
end


--已读取的邮件ID
def.method("number").GetReadEmailID = function(self, emailId)
    for i = 1, #self._EmailList do
        local email = self._EmailList[i]
        if email._EmailID == emailId then
            email._IsRead = true            
        end
    end
    self:OnEmailListData()
end

--根据返回的邮件ID领取邮件奖励
def.method("number").GetEmailIDToDrawReward = function(self, emailId)
    for i = 1, #self._EmailList do
        local email = self._EmailList[i]
        if email._EmailID == emailId then
            email._IsDraw = true            
        end
    end
    local CPanelMail = require "GUI.CPanelMail"
    CPanelMail.Instance()._IsSelect = false
    CPanelMail.Instance()._SelectIndex = 0
    self:OnEmailListData()
end

--根据返回的邮件ID批量领取邮件奖励
def.method("table").GetEmailIDToBatchDrawReward = function(self, emailIds)
    for i = 1, #self._EmailList do
        local email = self._EmailList[i]   
        if email == nil then
            return
        end      
        for j = 1 ,#emailIds do 
            if email._EmailID == emailIds[j] then
                email._IsDraw = true
                email._IsRead = true        
            end
        end        
    end    
    self:OnEmailListData()
end

--根据返回的邮件ID删除邮件
def.method("number").GetEmailIDToRemove = function(self, emailId)
    for i = #self._EmailList, 1, -1 do
        local email = self._EmailList[i]
        if email == nil then
            self:OnEmailListData()
            return 
        end
        if email._EmailID == emailId then
            table.remove(self._EmailList,i)
            
        end
    end
    local CPanelMail = require "GUI.CPanelMail"
    CPanelMail.Instance()._IsSelect = false
    CPanelMail.Instance()._SelectIndex = 0
    self:OnEmailListData()
end

--根据返回的邮件ID批量删除邮件
def.method("table").GetEmailIDToBatchRemove = function(self, emailIds)
    if #self._EmailList == #emailIds then
        self._EmailList = {}
        self:OnEmailListData()
        return
    end
    for _,v in pairs(emailIds) do
        for i=#self._EmailList, 1, -1 do        
            if v == self._EmailList[i]._EmailID then
                table.remove(self._EmailList,i) 
            end
        end
    end
    local CPanelMail = require "GUI.CPanelMail"
    CPanelMail.Instance()._IsSelect = false
    CPanelMail.Instance()._SelectIndex = 0
    self:OnEmailListData()
end


--刷新邮件列表
def.method().OnEmailListData = function(self)
    local CPanelMail = require "GUI.CPanelMail"
    if CPanelMail.Instance():IsShow() then
        CPanelMail.Instance():OnEmailList()
    else
        game._GUIMan:Open("CPanelMail", nil)
    end
    --warn("=================>>>", self:OnEmailRedPoint())
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mail, self:OnEmailRedPoint())
end

--刷新邮件红点。
def.method("=>", "boolean").OnEmailRedPoint = function(self)
    local emailRedPoint = false
    if #self._EmailList > 0 then
        for _,k in ipairs(self._EmailList) do
            -- warn("lidaming idread = ", k._IsRead, k._IsHaveReward, "k._IsDraw ==", k._IsDraw)
            if k._IsRead == false then
                return true
            elseif k._IsRead == true then
                if k._IsHaveReward == true and k._IsDraw == false then
                    return true
                end
            end
        end
    end
    --warn("lidaming ------------->>> emailRedPoint ==", emailRedPoint)
    return emailRedPoint
end

-----------------------邮件的C2S消息-------------------------------

--初次登陆会提前请求一次邮件的列表
--S2CEmailViewList游戏开始的时候接收
def.method().OnC2SEmailInfo = function(self)
	local C2SEmailViewList = require "PB.net".C2SEmailViewList
    local protocol = C2SEmailViewList()
	PBHelper.Send(protocol)
end

--读邮件
def.method("number").OnC2SReadEmail = function(self,emailId)
	local C2SEmailRead = require "PB.net".C2SEmailRead
    local protocol = C2SEmailRead()
    protocol.EmailID = emailId
	PBHelper.Send(protocol)
end

--领取邮件奖励
def.method("number").OnC2SEmailDrawReward = function(self,emailId)
	local C2SEmailDrawReward = require "PB.net".C2SEmailDrawReward
    local protocol = C2SEmailDrawReward()
    protocol.EmailID = emailId
	PBHelper.Send(protocol)
end

--批量领取邮件奖励
def.method().OnC2SEmailBatchDrawReward = function(self)
	local C2SEmailBatchDrawReward = require "PB.net".C2SEmailBatchDrawReward
    local protocol = C2SEmailBatchDrawReward()
	PBHelper.Send(protocol)
end

--删除邮件
def.method("number").OnC2SEmailRemove = function(self,emailId)
	local C2SEmailRemove = require "PB.net".C2SEmailRemove
    local protocol = C2SEmailRemove()
    protocol.EmailID = emailId
	PBHelper.Send(protocol)
end

--批量删除邮件
def.method().OnC2SEmailBatchRemove = function(self)
	local C2SEmailBatchRemove = require "PB.net".C2SEmailBatchRemove
    local protocol = C2SEmailBatchRemove()
	PBHelper.Send(protocol)
end


-------------------------------------------------------------------

CEmailMan.Commit()
return CEmailMan