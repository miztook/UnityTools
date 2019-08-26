local Lplus = require "Lplus"
local CUIMan = Lplus.ForwardDeclare("CUIMan")
local template = require "PB.Template"
local CElementData = require "Data.CElementData"
local bit = require "bit"

local GUITools = Lplus.Class("GUITools")
local def = GUITools.define

--解析从C#穿过来的网页消息，返回一个table
local function parseWebViewMsg(msg)
    local msgs = {}
    local args = string.split(msg, ",")
    for i,v in ipairs(args) do
        if v ~= "" and v ~= nil then
            local kv = string.split(v, "#")
            if #kv ==2 then
                msgs[kv[1]] = kv[2]
            else
                warn("WebView msg parse error !!")
            end
        end
    end
    return msgs
end

--在请求WebView的URL之前设置head键值对。
local function addWebViewURLHeads(webview, data)
    if webview == nil then return end
    for key,value in pairs(data)do
        webview:SetHeaderField(key,value)
    end
end

local function setButtonEnable(obj,enable)
    --if not obj then return end
	GameUtil.EnableButton(obj, enable)
end

local function setItemByData(item_obj, item_data)
	if item_obj == nil then
		warn("the param 'item_obj' of function setItemByData in moduel 'GUITools' is nil.")
		return
	end
	if item_data == nil then
		warn("the param 'item_data' of function setItemByData in moduel 'GUITools' is nil.")
		return
	end

	if type(item_data) == "number" then

	elseif type(item_data) == "table" then

	else

	end

end


--此方法只是用于没有打图集的散图
local function setSprite(obj, path)
	if obj == nil then return end

	if path == nil or string.len(path) <= 4 then
		return
	end

	if not string.find(path, "Assets/Outputs/") then 
		warn("GUITools :: the 'path' of the sprite is illegal: ", path)
		return 
	end
	GameUtil.SetSprite(obj, path)
end

local function CleanSprite(obj)
	if IsNil(obj) then return end
	GameUtil.CleanSprite(obj)
end

--此方法适用于打在图集中的多个图片切换
local function setGroupImg(obj, param)
	if (param == nil) or (obj == nil) then return end
	GameUtil.SetGroupImg(obj,param)
end

local function makeBtnBgGray(obj, bGray)
	if IsNil(obj) then return end
	GameUtil.MakeImageGray(obj, bGray)
	local a = bGray and 0.7 or 1
	GameUtil.ChangeGraphicAlpha(obj, a)
end

local function setBtnExpress(obj, param)
    if (param == nil) or (obj == nil) then return end
	GameUtil.SetBtnExpress(obj,param)
end

local function setBtnGray(obj, param, dontA)
    if obj == nil or param == nil or type(param) ~= "boolean" then return end
    GameUtil.SetBtnExpress(obj,param)
    local uiTemplate = obj:GetComponent(ClassType.UITemplate)
    if uiTemplate ~= nil then
        local img_money = uiTemplate:GetControl(2)
        local img_bg = uiTemplate:GetControl(0)
        if img_bg ~= nil then
            if dontA then
                GameUtil.MakeImageGray(img_bg, param)
            else
                makeBtnBgGray(img_bg, param)
            end
        end
        if img_money ~= nil then
            makeBtnBgGray(img_money, param)
        end
    end
end

local function setBtnFlash(obj, param)
    if obj == nil or param == nil or type(param) ~= "boolean" then return end
    local img_fx = obj:FindChild("Img_Bg/Img_BtnFloatFx")
    if img_fx ~= nil then
        img_fx:SetActive(param)
    end
end

local function setNativeSize(obj)
	if obj == nil then return end
	GameUtil.SetNativeSize(obj)
end

local function setHeadIcon(obj, path)
	if path == nil or path == "" then
		warn("the head icon path is empty", debug.traceback())
		return
	end
	local assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
	GameUtil.SetSprite(obj, assetPath)
end

local function setIcon(obj, path)
	if path == nil or path == "" then
		warn("the icon path is empty", debug.traceback())
		return
	end
	local assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
	GameUtil.SetSprite(obj, assetPath)
end

local function setHeadIconfromImageFile(obj, filepath)
	GameUtil.SetHeadIconfromImageFile(obj, filepath)
end

local function setProfSymbolIcon(obj, path)
	if path == nil or path == "" then
		warn("the ProfSymbolIcon path is empty", debug.traceback())
		return
	end
	local assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
	GameUtil.SetSprite(obj, assetPath)
end

local function setMap(obj, path)
	if path == nil or path == "" then
		warn("the map path is empty", debug.traceback())
		return
	end
	GameUtil.SetSprite(obj, path)
end

local function setSkillIcon(obj, path)
	--if not string.find(path, "Skill/") then return end
	if obj == nil or  path == nil then return end
	local assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
	setSprite(obj, assetPath)
end

local function setItemIcon(obj, path)
	if obj == nil or  path == nil then return end

	local assetPath = ""
	if path ~= "" then
		if not string.find(path, "/") then path = "Item/" .. path end
		assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
	end
	--setSprite(obj, assetPath)
	-- 此处改成同步加载，满足数据填错时，能显示问号 added by lijian
	GameUtil.SetItemIcon(obj, assetPath)
end

local function setTokenMoneyIcon(obj, id)
	if obj == nil or id == 0 then return end

	local CTokenMoneyMan = require "Data.CTokenMoneyMan"
	local path = CTokenMoneyMan.Instance():GetIconPath(id)
	setItemIcon(obj, path)
end

local function setGuildIcon(obj, path)
	if obj == nil then return end
	if not string.find(path, "Guild/") then return end
	local assetPath = _G.CommonAtlasDir.."Icon/" .. path .. ".png"
    --print("assetPath ", assetPath)
	setSprite(obj, assetPath)
end

local function setTokenItem(item, tokenId, tokenCount)
	local img_item_icon = item:FindChild("Icon/Img_ItemIcon") or item:FindChild("Img_ItemIcon")
	local itemTemplate = CElementData.GetMoneyTemplate(tokenId)
	if itemTemplate == nil then return end
	if img_item_icon ~= nil then
		local CTokenMoneyMan = require "Data.CTokenMoneyMan"
		local path = itemTemplate.IconPath
		GUITools.SetItemIcon(img_item_icon, path)
	end

	local lab_number = item:FindChild("Lab_Number")
	if lab_number ~= nil then
		if tokenCount > 0 then
			lab_number:SetActive(true)
			lab_number:GetComponent(ClassType.Text).text = GUITools.FormatMoney(tokenCount)
		else
			lab_number:SetActive(false)
		end
	end

	local img_quality = item:FindChild("Icon/Img_Quality") or item:FindChild("Img_Quality")
	if not IsNil(img_quality) then
		img_quality:SetActive(true)
		setGroupImg(img_quality, itemTemplate.Quality)
	end
    local img_lock = item:FindChild("Img_Lock")
	if not IsNil(img_lock) then
   		img_lock:SetActive(false)
  	end
end

local function setHostModel(imgObj, renderLayer, cb, showType)
	local CUIModel = require "GUI.CUIModel"
	local hp = game._HostPlayer
	local params = hp:GetModelParams()
	params._IsWeaponInHand = false
	if showType == nil then
		showType = EnumDef.UIModelShowType.All
	end
	local model = CUIModel.new(params, imgObj, showType, renderLayer, cb)
	return model
end

local function updateHostModel(uiModel)
	if uiModel == nil then return end
	local hp = game._HostPlayer	
	local params = hp:GetModelParams()
	params._IsWeaponInHand = false
	params._GUID = "[UI]" .. hp:GetCurWeaponGUID() -- 测试用
	uiModel:Update(params)
end

local function setImageProgress(imgObj, value)
	imgObj.fillAmount = value
end

--格式化时间Begin
local formats = {601, 602, 603, 604, 0 };		--"%d天", "%d小时", "%d分", "%d秒"
local bIsSec = {false, false, false, true, false };
local function formatTimeSpanFromSecondsAndDecimal(timespanSec, msFraction)

	local values = {math.floor(timespanSec / 86400), math.floor(timespanSec % 86400 / 3600), math.floor(timespanSec % 3600 / 60), math.floor(timespanSec % 60), 0 }	--%d天%d小时%d分%d秒0
	local format_fsec = 605	--"%.1f秒"

	for i=1, #values do
		local valueOne = values[i]
		local valueTwo = values[i+1]
		local formatOne = formats[i]
		local formatTwo = formats[i+1]

		if valueOne > 0 or i+2 > #values then
			if valueTwo == 0 then
				if bIsSec[i] and msFraction ~= 0 then		--只有秒时才显示小数
					return StringTable.Get(format_fsec):format(valueOne + msFraction/1000.0)
				else
					return StringTable.Get(formatOne):format(valueOne)
				end
			else
				return StringTable.Get(formatOne):format(valueOne)	--"%d分"
					.. StringTable.Get(formatTwo):format(valueTwo)	--"%d秒"
			end
		end
	end

	error("should not be here")
end
local function formatTimeSpanFromSeconds(timespanSec)
	return formatTimeSpanFromSecondsAndDecimal(timespanSec, 0)
end
-- 格式化时间 00:00:00
local function formatTimeFromSecondsToZero(isShowHour,startTime)
	local hour = math.floor(startTime / 3600)
	local minute = math.floor((startTime % 3600) / 60)
	local second = math.floor(startTime % 60) 
	
	if minute < 10 then 
		minute = '0'..minute
	end
	if second < 10 then 
		second = "0"..second
	end
	if not isShowHour then 	
		return minute..":"..second
	else 
		if hour < 10 then 
			hour = "0"..hour
		end
		return hour..":"..minute..":"..second
	end
	-- body
end 
-- 格式化时间将格式yy/MM/DD HH:mm:ss 转化为秒
local function formatTimeFromGmtToSeconds(timeStr)
	local value1 = string.split(timeStr," ")
	local ymd = string.split(value1[1],'/')
	local hms = string.split(value1[2],":")

	local seconds = os.time({
		year = tonumber(ymd[1]),
		month = tonumber(ymd[2]),
		day = tonumber(ymd[3]),
		hour = tonumber(hms[1]),
		min = tonumber(hms[2]),
		sec = tonumber(hms[3]),
		isdst = false,
	})	
	return seconds 
	-- body
end
--格式化时间End

--格式化金钱
local function ReParseFormatNum(number)
	local index = 1
	local num = number
	local tmp = {}
	while num > 0 do
		table.insert(tmp, index, math.floor(num % 1000))
		num = math.floor(num / 1000)
		index = index + 1
    end

    local ret = ""
    local step = ""
    if tmp then
    	local lenth = #tmp
		for i = #tmp, 1, -1 do
			if i < lenth and lenth > 1 then
				step = tmp[i]
				if string.len(step) < 3 then
					for j = 1, (3 - string.len(tmp[i])) do 
						step = "0"..step
					end
				end
				ret = ret ..","..step
			else
				ret = ret ..tmp[i]
			end		
		end	
	end

    return ret
end

local function formatMoney(number)
	if number == nil then
		warn("the formatMoney Number is nil! ", debug.traceback())
		number = 0
	end
	local num = number
	if num >= 1000000 then	
		num = ReParseFormatNum(tonumber(fixFloor(num / 1000000, 1)))  .."M"
	else 
		num = ReParseFormatNum(number)
	end
	if num == "" then
		num = "0"
	end
	return tostring(num)
end

-- 数字，是否是金币（需要转换成M,B）, 十进制最大位数
local function formatNumber(number, isMoney, maxDigit)
    if type(number) ~= "number" then
        warn("error !!! formatNumber 第一个参数类型不匹配 ")
        return ""
    end
    if isMoney then
        return formatMoney(number)
    else
		local b_neg =false

		if number < 0 then
			b_neg=true

			number=-number
		end

        local dot = number % 1          -- 单单是%1的话会有精度损失（0.26 -> 0.2599999498）
        if dot > 0 then
            local num_str = tostring(math.floor(number))
            local start_i, end_i = string.find(num_str, tostring(math.floor(number)))
            dot = tonumber(string.sub(num_str, end_i + 1, -1))
        end
        local a = math.floor(number)
        if a <= 999 then
            return tostring(number)
        end
        if maxDigit and #(tostring(a)) > maxDigit then
            a = math.pow(10, maxDigit) - 1
        end
        local b = 0
        local info = {}
        local result = ""
        while a > 999 do
            b = a % 1000
            a = math.floor(a / 1000)
            info[#info + 1] = b
        end
        if a >= 1 then
            info[#info + 1] = a
        end
        for i = #info, 1 , -1 do
            local info_str = tostring(info[i])
            local str = ""
            if #info_str < 3 and i ~= #info then
                for i = 1,(3-#info_str) do
                    info_str = "0"..info_str
                end
                str = info_str .. ","
            else
                str = info[i] .. ","
            end
            result = result .. str
        end
        result = string.sub(result, 1, #result - 1)
        if dot > 0 then
            result = result .. string.sub(tostring(dot), 2, -1)        
        end

		if b_neg then
			result="-"..result
		end

		return result
    end
end

local function utfstrlen(str)
    local len = #str
    local left = len
    local cnt = 0
    local arr = {0,0xc0,0xe0,0xf0,0xf8,0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then left = left - i; break; end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

local function subUTF8String(str, start, len)
    local firstResult = ""
    local strResult = ""
    local maxLen = string.len(str)
    start = start - 1
    local preSite = 1

    if start > 0 then
        for i = 1,maxLen do
            local s_dropping = string.byte(str, i)
            if not s_dropping then
                local s_str = string.sub(str, preSite, i - 1)
                preSite = i + 1
                break
            end
            if s_dropping < 128 or (i + 1 - preSite) == 3 then
                local s_str = string.sub(str, preSite, i)
                preSite = i + 1
                firstResult = firstResult..s_str
                local curLen = utfstrlen(firstResult)
                if (curLen == start) then
                    break
                end
            end
        end
    end
    preSite = string.len(firstResult) + 1
    local startC = preSite
    for i = startC, maxLen do
        local s_dropping = string.byte(str, i)
        if not s_dropping then
            local s_str = string.sub(str, preSite, i-1)
            preSite = i
            strResult = strResult..s_str
            return strResult
        end
        if s_dropping < 128 or (i+1-preSite)==3 then
            local s_str = string.sub(str, preSite, i)
            preSite = i + 1
            strResult = strResult..s_str
            local curLen = utfstrlen(strResult)
            if(curLen == len) then
                return strResult
            end
        end
    end
    return strResult
end

-- 保留小数点后面位数（不四舍五入的）
local function formatPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum
    end
    n = n or 0
    n = math.floor(n)
    if n < 0 then
        n = 0
    end
    local nDecimal = 10 ^ n
    local nTemp = math.floor(nNum * nDecimal)
    local nRet = nTemp / nDecimal
    return nRet
end

--根据一行高度尺寸 修改Text布局 
local function SetTextAlignmentByLineHeight(obj, height)
	local tmpHeight = obj:GetComponent(ClassType.Text).preferredHeight
	local line = tmpHeight / height
    if line > 1 then
        GUI.SetTextAlignment(obj, EnumDef.TextAlignment.MiddleLeft)
    else
    	GUI.SetTextAlignment(obj, EnumDef.TextAlignment.MiddleCenter)
    end
end

--修改UI尺寸
local function getUiSize(obj)
	local fixedSizeDelta = obj:GetComponent(ClassType.RectTransform).sizeDelta

	local size = {}
	size.Width = fixedSizeDelta.x
	size.Height = fixedSizeDelta.y

	return size
end

--修改UI尺寸
local function uiResize(obj, width, height)
	local fixedSizeDelta = obj:GetComponent(ClassType.RectTransform).sizeDelta
    if width > 0 then
        fixedSizeDelta.x = width
    end
    if height > 0 then
        fixedSizeDelta.y = height
    end
    obj:GetComponent(ClassType.RectTransform).sizeDelta = fixedSizeDelta
end

--修改UI和父物体一样大
local function uiSetRectTransformStretch(obj)
    if obj then
        GUI.SetRectTransformStretch(obj)
    end
end

--修改UI相对位置
local function setRelativePosition(alignedObj, targetObj, alignType)
    local alignedTrans = alignedObj:GetComponent(ClassType.RectTransform)
    local targetTrans = targetObj:GetComponent(ClassType.RectTransform)
    local offsetX = 0
    local offsetY = 0

    if alignType == EnumDef.AlignType.Left then
        offsetX = alignedTrans.rect.width / 2 + targetTrans.rect.width / 2
        offsetY = alignedTrans.rect.height / 2
    elseif alignType == EnumDef.AlignType.Right then
        offsetX = alignedTrans.rect.width / 2 + targetTrans.rect.width / 2
        offsetY = alignedTrans.rect.height / 2
    elseif alignType == EnumDef.AlignType.Top then
        offsetY = targetTrans.rect.height / 2--alignedTrans.rect.height/2 + 
    elseif alignType == EnumDef.AlignType.Bottom then
        offsetY = alignedTrans.rect.height / 2  + targetTrans.rect.height / 2
	elseif alignType == EnumDef.AlignType.PVPLeft then		
		offsetX = targetTrans.rect.width / 3
        offsetY = - alignedTrans.rect.height+15
    elseif alignType == EnumDef.AlignType.PVPRight then		
		offsetX = - targetTrans.rect.width / 3
        offsetY = - alignedTrans.rect.height+15
	elseif alignType == EnumDef.AlignType.PVP1V1Left then
		offsetX = targetTrans.rect.width / 2
        offsetY = - alignedTrans.rect.height - 15
    elseif alignType == EnumDef.AlignType.PVP1V1Right then		
		offsetX = - targetTrans.rect.width / 2
        offsetY = - alignedTrans.rect.height - 15
    elseif alignType == EnumDef.AlignType.PanelBuff then		
		-- offsetX = alignedTrans.rect.width / 3
		offsetX = targetTrans.rect.width - alignedTrans.rect.width
        offsetY = - alignedTrans.rect.height - 15
    else --EnumDef.AlignType.Center
        offsetX = alignedTrans.rect.width / 2
        offsetY = alignedTrans.rect.height / 4
    end

    GameUtil.AlignUiElementWithOther(alignedObj, targetObj, offsetX, offsetY)
end

--DoTween functions
local function doMove( obj, endPosition, interval, easeType,fDelay, callback )
	local curType = EnumDef.Ease.Linear
	if easeType ~= nil then
		curType = easeType
	end

	GameUtil.DoMove(obj, endPosition, interval, curType,fDelay, callback)
end

local function doLocalMove( obj, endPosition, interval, easeType, callback )
	local curType = EnumDef.Ease.Linear
	if easeType ~= nil then
		curType = easeType
	end

	GameUtil.DoLocalMove(obj, endPosition, interval, curType, callback)
end

local function doKill( obj )
	GameUtil.DoKill(obj)
end

local function doSlider( obj, fillVal, interval, easeType, callback )
	local curType = EnumDef.Ease.Linear
	if easeType ~= nil then
		curType = easeType
	end

	GameUtil.DoSlider(obj, fillVal, interval, curType, callback)
end

local function doKillSlider( obj)
	GameUtil.DoKillSlider(obj)
end

local function doLocalRotateQuaternion(obj, endRotation, interval, easeType, callback )
	local curType = EnumDef.Ease.Linear
	if easeType ~= nil then
		curType = easeType
	end

	GameUtil.DoLocalRotateQuaternion(obj, endRotation, interval, curType, callback)
end 

local function doAlpha( obj, endValue, interval, callback )
	GameUtil.DoAlpha(obj, endValue, interval, callback)
end

local function doScale( obj, endScale, interval, callback )
	GameUtil.DoScale(obj, endScale, interval, EnumDef.Ease.Linear, callback)
end

local function doChangeGradientBtnColor(obj,btmColor)
	if IsNil(obj) then 
		warn("doChangeGradientBtnColor: error,obj is nil")
	return end
	GameUtil.ChangeGradientBtmColor(obj,btmColor)
end

local function getNodeChain(menuNode)
    local chain = {}
    while not IsNil(menuNode) do
        local index = menuNode.Index
        if index >= 0 then
            chain[#chain+1] = index
        end
        menuNode = menuNode:GetParentNode()
    end
    return chain
end
--奖励模板
local function getRewardList(reward, IsAddMoney)
	local temp = nil
	if type(reward) == "number" then
		temp = CElementData.GetRewardTemplate(reward)
	end

	if temp == nil then
		warn("the reward template data is nil.")
		return {}
	end
	local rewards = {}
	-- 货币是否加入奖励列表
	if IsAddMoney then
		local MaxMoneyTypeCount = 4
		for i=1, MaxMoneyTypeCount do
			if temp["MoneyId"..i] > 0 and temp["MoneyNum"..i] ~= "" then
				-- 根据当前等级奖励货币数量。   2018/09/10   lidaming
				local MoneyNumInfo = {}  
				local MoneyCount = nil
				string.gsub(temp["MoneyNum"..i], '[^*]+', function(w) table.insert(MoneyNumInfo, w) end )
				if #MoneyNumInfo > 1 then
					for level,v in pairs(MoneyNumInfo) do						
						if game._HostPlayer._InfoData._Level == level then							
							MoneyCount = v                                    
						end                        
					end
				else
					MoneyCount = MoneyNumInfo[1]
				end
				rewards[#rewards+1] = 
				{	
					IsTokenMoney = true,
					Data = 
					{
						Id = temp["MoneyId"..i], 
						Count = tonumber(MoneyCount)
					},
				}
			end
		end
		--声望经验枚举值ID，对应EResourceType
		local reputationExpType = 14
		local reputationCount =  #temp.ReputationRelated.RewardReputations
		for i = 1,reputationCount do
			rewards[#rewards+1] = 
			{
				IsTokenMoney = true,
				Data = 
				{
					Id = reputationExpType,
					Count = temp.ReputationRelated.RewardReputations[i].Exp,
				},
			}			
		end 
	end

	local count = #temp.ItemRelated.RewardItems
	for i = 1, count do
		rewards[#rewards+1] = 
		{
			IsTokenMoney = false,
			Data = temp.ItemRelated.RewardItems[i],
		}
	end
-- 奖励面板显示添加职业区分
-- id = 1 战士 2 祭司 3 刺客 4 弓箭手
    local rws = 
    {
        temp.WarriorRelated,
        temp.PreistRelated,
        temp.AssassinRelated,
		temp.ArcherRelated,
		temp.LancerRelated,
    }
    local professionRewardItems = rws[game._HostPlayer._ProfessionTemplate.Id]
    if professionRewardItems and professionRewardItems._is_present_in_parent then
    	count = #professionRewardItems.RewardItems
    	--warn("count2",count)
    	for i = 1, count do
    		rewards[#rewards+1] = 
			{
				IsTokenMoney = false,
				Data = professionRewardItems.RewardItems[i]
			}
		end
    end     
	return rewards
end

--根据等级获取对应奖励列表
local function getRewardListByLevel(reward, IsAddMoney, level)
	local temp = nil
	if type(reward) == "number" then
		temp = CElementData.GetRewardTemplate(reward)
	else
		temp = reward
	end

	if temp == nil then
		warn("the reward template data is nil.")
		return
	end
	local rewards = {}
	-- 货币是否加入奖励列表
	if IsAddMoney then
		local MaxMoneyTypeCount = 4
		for i=1, MaxMoneyTypeCount do
			if temp["MoneyId"..i] > 0 and temp["MoneyNum"..i] ~= "" then
				-- 根据传入等级奖励货币数量。   2018/09/10   lidaming
				local MoneyNumInfo = {}  
				local MoneyCount = nil
				string.gsub(temp["MoneyNum"..i], '[^*]+', function(w) table.insert(MoneyNumInfo, w) end )
				if #MoneyNumInfo > 1 then
					for l,v in pairs(MoneyNumInfo) do						
						if level == l then							
							MoneyCount = v                                    
						end                        
					end
				else
					MoneyCount = MoneyNumInfo[1]
				end
				rewards[#rewards+1] = 
				{	
					IsTokenMoney = true,
					Data = 
					{
						Id = temp["MoneyId"..i], 
						Count = tonumber(MoneyCount)
					},
				}
			end
		end
	end

	local count = #temp.ItemRelated.RewardItems
	for i = 1, count do
		rewards[#rewards+1] = 
		{
			IsTokenMoney = false,
			Data = temp.ItemRelated.RewardItems[i],
		}
	end
-- 奖励面板显示添加职业区分
-- id = 1 战士 2 祭司 3 刺客 4 弓箭手
    local rws = 
    {
        temp.WarriorRelated,
        temp.PreistRelated,
        temp.AssassinRelated,
		temp.ArcherRelated,
		temp.LancerRelated,
    }
    local professionRewardItems = rws[game._HostPlayer._ProfessionTemplate.Id]
    if professionRewardItems and professionRewardItems._is_present_in_parent then
    	count = #professionRewardItems.RewardItems
    	--warn("count2",count)
    	for i = 1, count do
    		rewards[#rewards+1] = 
			{
				IsTokenMoney = false,
				Data = professionRewardItems.RewardItems[i]
			}
		end
    end     
	return rewards
end


-- 掉落模板
local function getDropLibraryItemList(dropLibrary)
	local EDropItemType = template.DropLibrary.EDropItemType
	local temp = nil
	if type(dropLibrary) == "number" then
		temp = CElementData.GetTemplate("DropLibrary",dropLibrary)
	else
		temp = dropLibrary
	end

	if temp == nil then
		warn("the dropLibrary template data is nil.")
		return
	end
	local ItemList = {}
	for i,v in ipairs(temp.DropItems.DropItems) do
		if v.ItemType == EDropItemType.ITEM then 
			ItemList[#ItemList+1] = v
		elseif v.ItemType == EDropItemType.DROPGROUP then 
			local listData = getDropLibraryItemList(v.ItemId)
			for j,w in ipairs(listData) do
				ItemList[#ItemList+1] = w
			end
		end
	end
	return ItemList

end



local function getChild(obj, index)
	if IsNil(obj) then return nil end
	return GUI.GetChildFromTemplate(obj, index)
end

local function registerButtonEventHandler(panel_obj, btn_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, btn_obj, ClassType.Button, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, btn_obj, ClassType.Button)
    end
end

local function registerToggleEventHandler(panel_obj, btn_obj, recursion)
    if recursion then
        GameUtil.RegisterUIEventHandler(panel_obj, btn_obj, ClassType.Toggle, recursion)
    else
        GameUtil.RegisterUIEventHandler(panel_obj, btn_obj, ClassType.Toggle)
    end
end

local function registerGTextEventHandler(panel_obj, gtext_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, gtext_obj, ClassType.GText, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, gtext_obj, ClassType.GText)
    end
end

local function registerImageModelEventHandler(panel_obj, im_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, im_obj, ClassType.GImageModel, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, im_obj, ClassType.GImageModel)
    end
end

local function registerSliderEventHandler(panel_obj, sld_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.Slider, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.Slider)
    end
end

local function registerGScaleScrollEventHandler(panel_obj, sld_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.GScaleScroll, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.GScaleScroll)
    end
end

local function registerGWebViewEventHandler(panel_obj, webView_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, webView_obj, ClassType.GWebView, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, webView_obj, ClassType.GWebView)
    end
end

local function registerGNewListOrLoopEventHandler(panel_obj, list_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, list_obj, ClassType.GNewListBase, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, list_obj, ClassType.GNewListBase)
    end
end

local function registerGBloodEventHandler(panel_obj, sld_obj, recursion)
    if recursion then
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.GBlood, recursion)
    else
    	GameUtil.RegisterUIEventHandler(panel_obj, sld_obj, ClassType.GBlood)
    end
end

local function changeDressEmbroidery(obj, path)
	--warn("GUITools.ChangeDressEmbroidery")
	GameUtil.ChangeDressEmbroidery(obj, path)
end

local function setUIActive(obj, bShow)
	if IsNil(obj) then
		warn("GUITools.SetUIActive : obj is nil !", debug.traceback() )
		return
	end

	if bShow then
		obj.localScale = Vector3.one
	else
		obj.localScale = Vector3.zero
	end
end

local function setBuffIcon(item, buff)
	if buff == nil then return end

    local Img_Icon = item:FindChild('Img_Buff')
    local Lab_Num = item:FindChild('Lab_Num')
    local Img_Mask = item:FindChild("Img_Mask")
    local Img_MaskBG = item:FindChild("Img_MaskBG")

    setIcon(Img_Icon, buff._IconPath)

    Lab_Num:SetActive(buff._StateLevel > 0)
	if buff._StateLevel > 0 then
        GUI.SetText(Lab_Num, tostring(buff._StateLevel))
    end

    item:SetActive(true)
    local bShow = (buff._Duration ~= -1)
    Img_Mask:SetActive(bShow)
    Img_MaskBG:SetActive(bShow)
    if bShow then
    	local maxTime = buff._MaxDuration*1000
    	local elapsedTime = maxTime-(buff._EndTime-Time.time)*1000

    	GameUtil.AddCooldownComponent(Img_Mask, elapsedTime, maxTime, nil, function() end, true)
        GameUtil.AddCooldownComponent(Img_MaskBG, elapsedTime, maxTime, nil, function() end, true)
    end
end

local function setDropdownValue(obj, index)
	if IsNil(obj) then return end
	GameUtil.SetDropdownValue(obj, index)
end

local function setPointImageReverseY(obj, reverse)
	local color = nil
	if reverse then
		obj.localScale = Vector3.New(1,-1,1)
		color = Color.New(1,0,0)
	else
		obj.localScale = Vector3.one
		color = Color.New(0,1,0)
	end
	GameUtil.SetImageColor(obj, color)
end

local function setupDropdownTemplate(panel, dropTemplate)
	if dropTemplate == nil then return end

    local id = GameUtil.Num2SortingLayerID(panel._Layer)
    GameUtil.SetPanelSortingLayerOrder(dropTemplate, id, 30000)
end

local function setTabListOpenTypeImg(item, type)
	setGroupImg(item:FindChild("Img_Arrow"), type)
end

local function setEngraveIcon(img, value)
	if img == nil then return end

	local iconIndex
	if value == nil then
        --没刻印
        iconIndex = EnumDef.EngraveIconType.Empty
    else
        if value == 0 then
            --刻印失败
            iconIndex = EnumDef.EngraveIconType.Failed
        else
            --刻印成功
            iconIndex = EnumDef.EngraveIconType.Succeed
        end
    end

	GUITools.SetGroupImg(img, iconIndex)
end

local function getEmojiByType(emojiType)
	if emojiType < 0 then return "" end
	local result = string.format("[e]%d[-]", emojiType)
	return result
end

local function getTextSize(obj)
	if obj and obj:GetComponent(ClassType.Text) then
		local text = obj:GetComponent(ClassType.Text)
		return text.fontSize
	end
	return nil
end

local function formatRichTextSize(size, text)
	return string.format(StringTable.Get(19072), size, text)
end

-- 特效缩放
local function scaleChildFXObj(goParent, scale)
    local go = goParent:FindChild("FXObj");
    go.localScale = Vector3.New(scale,scale,scale)
end

local function showCommonTip(title, des, obj)
    local data = {}
    data._Title = title or ""
    data._Des = des or ""
    data._Obj = obj
    game._GUIMan:Open("CPanelUICommonTip", data)
end

def.const("function").setButtonEnable 		= setButtonEnable
def.const("function").SetSprite           	= setSprite
def.const("function").CleanSprite           = CleanSprite
def.const("function").SetIcon 				= setIcon
def.const("function").SetHeadIcon         	= setHeadIcon
def.const("function").SetHeadIconfromImageFile         	= setHeadIconfromImageFile
def.const("function").SetProfSymbolIcon		= setProfSymbolIcon
def.const("function").SetMap              	= setMap
def.const("function").SetSkillIcon        	= setSkillIcon
def.const("function").SetItemIcon         	= setItemIcon
def.const("function").SetTokenMoneyIcon		= setTokenMoneyIcon
def.const("function").SetGuildIcon 			= setGuildIcon
def.const("function").CreateHostUIModel     = setHostModel
def.const("function").HostUIModelUpdate     = updateHostModel

def.const("function").SetGroupImg			= setGroupImg
def.const("function").MakeBtnBgGray 		= makeBtnBgGray
def.const("function").SetBtnExpressGray     = setBtnExpress
def.const("function").SetBtnGray            = setBtnGray
def.const("function").SetBtnFlash           = setBtnFlash
def.const("function").SetNativeSize			= setNativeSize

def.const("function").SetImageProgress		= setImageProgress
def.const("function").SetBuffIcon			= setBuffIcon
def.const("function").UIResize				= uiResize
def.const("function").UISetRectTransformStretch      = uiSetRectTransformStretch
def.const("function").GetUiSize				= getUiSize
def.const("function").SetRelativePosition	= setRelativePosition
def.const("function").DoMove 				= doMove
def.const("function").DoLocalMove 			= doLocalMove
def.const("function").DoScale 				= doScale
def.const("function").DoAlpha               = doAlpha
def.const("function").DoKill                    = doKill
def.const("function").DoLocalRotateQuaternion 		= doLocalRotateQuaternion
def.const("function").DoSlider 				= doSlider
def.const("function").DoKillSlider 				= doKillSlider

def.const("function").FormatMoney 			= formatMoney
def.const("function").FormatPreciseDecimal 			= formatPreciseDecimal
def.const("function").FormatNumber          = formatNumber
def.const("function").SubUTF8String         = subUTF8String
def.const("function").UTFstrlen             = utfstrlen
def.const("function").SetTextAlignmentByLineHeight 			= SetTextAlignmentByLineHeight
def.const("function").FormatTimeSpanFromSeconds = formatTimeSpanFromSeconds
def.const("function").FormatTimeSpanFromSecondsAndDecimal = formatTimeSpanFromSecondsAndDecimal
def.const("function").FormatTimeFromGmtToSeconds = formatTimeFromGmtToSeconds
def.const("function").GetNodeChain 			= getNodeChain
def.const("function").GetRewardList			= getRewardList
def.const("function").GetRewardListByLevel	= getRewardListByLevel
def.const("function").SetTokenItem			= setTokenItem
def.const("function").GetChild				= getChild
--def.const("function").RegisterUIEventHandler = registerUIEventHandler
def.const("function").RegisterButtonEventHandler = registerButtonEventHandler
def.const("function").RegisterToggleEventHandler = registerToggleEventHandler
def.const("function").RegisterGTextEventHandler	= registerGTextEventHandler
def.const("function").RegisterImageModelEventHandler = registerImageModelEventHandler
def.const("function").RegisterSliderEventHandler = registerSliderEventHandler
def.const("function").RegisterGScaleScrollEventHandler = registerGScaleScrollEventHandler
def.const("function").RegisterGWebViewEventHandler = registerGWebViewEventHandler
def.const("function").RegisterGNewListOrLoopEventHandler = registerGNewListOrLoopEventHandler
def.const("function").ChangeDressEmbroidery	= changeDressEmbroidery
def.const("function").SetUIActive 			= setUIActive
def.const("function").FormatTimeFromSecondsToZero = formatTimeFromSecondsToZero
def.const("function").SetDropdownValue		= setDropdownValue
def.const("function").ChangeGradientBtmColor = doChangeGradientBtnColor
def.const("function").SetPointImageReverseY = setPointImageReverseY
def.const("function").SetupDropdownTemplate = setupDropdownTemplate
def.const("function").SetTabListOpenTypeImg = setTabListOpenTypeImg
def.const("function").GetDropLibraryItemList = getDropLibraryItemList
def.const("function").SetEngraveIcon = setEngraveIcon
def.const("function").GetEmojiByType = getEmojiByType
def.const("function").GetTextSize = getTextSize
def.const("function").FormatRichTextSize = formatRichTextSize
def.const("function").ScaleChildFXObj = scaleChildFXObj
def.const("function").ShowCommonTip = showCommonTip

def.const("function").ParseWebViewMsg = parseWebViewMsg
def.const("function").AddWebViewURLHeads = addWebViewURLHeads
GUITools.Commit()
return GUITools