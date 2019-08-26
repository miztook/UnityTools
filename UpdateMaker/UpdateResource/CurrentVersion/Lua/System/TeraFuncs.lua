local CElementData = require "Data.CElementData"
local CPath = require "Path.CPath"

--获取当前Entiy自定义头像  1、Image 2、roleId 3、CustomImgSet 4、Gender 5、Profession 6、
local function setEntityCustomImg(imgObj, roleId, customImgSet, gender, profession)
	if roleId ~= nil then
		--[[
		local ECustomSet = require "PB.data".ECustomSet	
			
		if customImgSet == ECustomSet.ECustomSet_Success then	--获取自定义头像
			-- warn("lidaming : Review or HaveSet!!!")
			--获取自定义头像
			local entityImgPath = ""
			
			-- error: 1、参数不匹配 2、没有用户 3、审核中 4、审核未通过 5、文件不存在 6、md5一致 7、被Ban
			local callback = function(strFileName ,retCode, error)	
				if IsNil(imgObj) then return end
                if retCode == 0 or retCode == 6 then
                    entityImgPath = GameUtil.GetCustomPicDir().."/"..roleId
                else
                    entityImgPath = ""
                end		
                if entityImgPath == "" then
                    local professionTemplate = CElementData.GetProfessionTemplate(profession)   
					if professionTemplate == nil then
						warn("自定义头像模板错误：profession:_",profession)
					return end      
					
					if gender == EnumDef.Gender.Female then
						GUITools.SetHeadIcon(imgObj, professionTemplate.FemaleIconAtlasPath)
					else
						GUITools.SetHeadIcon(imgObj, professionTemplate.MaleIconAtlasPath)
					end
                else
                    GUITools.SetHeadIconfromImageFile(imgObj, entityImgPath)	
                end		
            end
			GameUtil.DownloadPicture(tostring(roleId), callback)
		else
			]]
		-- 只要不是检测成功，全部显示默认头像
		-- 	if customImgSet == ECustomSet.ECustomSet_Defualt 	--默认职业头像
		-- or customImgSet == ECustomSet.ECustomSet_Review then	--审核中
			local professionTemplate = CElementData.GetProfessionTemplate(profession)   
			if professionTemplate == nil then
				warn("自定义头像模板错误：profession:_",profession)
			return end      
			
			if gender == EnumDef.Gender.Female then
				GUITools.SetHeadIcon(imgObj, professionTemplate.FemaleIconAtlasPath)
			else
				GUITools.SetHeadIcon(imgObj, professionTemplate.MaleIconAtlasPath)
			end
		-- end
	end	    
end

local function navigatToPos(destPos, distOffset, onArrive, onFail)
	local game = game
	if not game:IsWorldReady() or game._HostPlayer == nil then 
		if onFail ~= nil then onFail() end
		return 
	end
	
	local hp = game._HostPlayer
	if not hp:CanMove() then
		if onFail ~= nil then onFail() end
		game._GUIMan:ShowTipText(StringTable.Get(600), false)
		return
	end

    hp._NavTargetPos = destPos

    local function OnReach()
	    hp:StopNaviCal()
	    hp:SetAutoPathFlag(false)
	    hp._NavTargetPos = nil
	    CPath.Instance():HideTargetFxAndDistance()
	    if onArrive ~= nil then onArrive() end
	end

	local function OnNotReach()
	   hp:StopNaviCal()
	    hp:SetAutoPathFlag(false)
	    hp._NavTargetPos = nil
	    CPath.Instance():HideTargetFxAndDistance()
	    if onFail ~= nil then onFail() end
	end

    hp:MoveAndDonotCareCollision(destPos, distOffset, OnReach, OnNotReach)
    CPath.Instance():ShowPath(destPos)
end

local function sendFlashMsg(msg, bUp)
	if bUp == nil then bUp = false end
	game._GUIMan:ShowTipText(msg, bUp)
end

_G.TeraFuncs =
{
	SetEntityCustomImg = setEntityCustomImg,
	NavigatToPos = navigatToPos,
	SendFlashMsg = sendFlashMsg,
}