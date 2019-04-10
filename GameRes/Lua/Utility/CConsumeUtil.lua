local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CConsumeUtil = Lplus.Class("CConsumeUtil")

local def = CConsumeUtil.define
--[[	
	结构定义
	needMaterials = 
	{
		[1] = 
		{
			ID = 0,
			Count = 0,
		},
		[2] =
		{
			ID = 0,
			Count = 0,
		},
	}
]]

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

--消耗通用函数  
def.static("number", "number", "table", "string", "function", "function").ConsumeTodo = function(moneyId, moneyNeed, needMaterials, orignPanel, callbackSuccess, callbackFail)
	local hp = game._HostPlayer
	local pack = hp._Package._NormalPack

	--最后的回调函数
	local function DoFinalCallbackSuccess()
		if callbackSuccess then callbackSuccess() end
	end
	local function DoFinalCallbackFail()
		if callbackFail then callbackFail() end
	end

	--货币相关处理
	local function DoCost()
		local moneyHave = hp:GetMoneyCountByType(moneyId)
		if moneyHave < moneyNeed then
			warn("货币不够")
			SendFlashMsg(StringTable.Get(260), false) 
			do return end

			--货币不够
			CUseDiamondMan.Instance():DirectlyUseDiamond(orignPanel, moneyId, moneyNeed - moneyHave, DoFinalCallbackSuccess, DoFinalCallbackFail)
		else
			DoFinalCallbackSuccess()
		end
	end

	--材料相关处理
	local function DoMaterial()
		local successCnt = 0
		local needCnt = #needMaterials
		local bNeedBreak = false

		local function BuySuccess()
			successCnt = successCnt + 1
		end
		local function BuyFail()
			bNeedBreak = true
		end

		for i, material in ipairs( needMaterials ) do
			local materialHave = pack:GetItemCount(material.ID)
			if materialHave < material.Count then
				warn("材料不够")
				SendFlashMsg(StringTable.Get(10901), false)
				do return end
				
				CUseDiamondMan.Instance():BuyItemUseDiamond(orignPanel, material.ID, material.Count - materialHave, BuySuccess, BuyFail)
			else
				BuySuccess()
			end

			if bNeedBreak then break end
		end

		if successCnt == needCnt then
			DoCost()
		end
	end

	--材料先开始
	DoMaterial()
end

CConsumeUtil.Commit()
return CConsumeUtil