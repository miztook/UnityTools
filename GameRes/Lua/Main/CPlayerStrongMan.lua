--[[----------------------------------------------
         		 我要变强管理器
          				--- by luee 2018.4.17
--------------------------------------------------]]
local Lplus = require "Lplus"
local CPlayerStrongMan = Lplus.Class("CPlayerStrongMan")
local def = CPlayerStrongMan.define


local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CWingsMan = require "Wings.CWingsMan"
local CCharmMan = require "Charm.CCharmMan"
local CDressMan = require "Dress.CDressMan"
local CPanelStrong = require "GUI.CPanelStrong"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local EFightPropertiesType = require "PB.data".EFightPropertiesType
local CPetUtility = require "Pet.CPetUtility"
local CSkillUtil = require "Skill.CSkillUtil"
local UserData = require "Data.UserData"


def.field("table")._TableAllStrongData = nil --我要变强数据。将表格做整合
def.field("number")._ScoreC = 0
def.field("number")._ScoreB = 0
def.field("number")._ScoreA = 0
def.field("number")._ScoreS = 0
def.field("boolean")._IsNeedPlayerStrong = false --是否需要提示我要变强
def.field("boolean")._IsShowStrongPanel = true  --设置今天是否展示我要变强界面
def.field("boolean")._IsGetUserData = true    
def.field("number")._SetDateDay = 0            -- 设置日期天
def.field("number")._SetDateMonth = 0          -- 设置日期月



def.field("number")._DesignationFightScore = 0 	--称号战力
def.field("number")._ManualFightScore = 0 		--玩物志战力

def.static("=>", CPlayerStrongMan).new = function()
    local obj = CPlayerStrongMan()
    local CSpecialIdMan = require  "Data.CSpecialIdMan"
	obj._ScoreC = CSpecialIdMan.Get("PlayerSrongScoreC")
	obj._ScoreB = CSpecialIdMan.Get("PlayerSrongScoreB")
	obj._ScoreA = CSpecialIdMan.Get("PlayerSrongScoreA")
	obj._ScoreS = CSpecialIdMan.Get("PlayerSrongScoreS")
	return obj
end

def.method().Init = function(self)
	self._TableAllStrongData = {}
	if not self._IsGetUserData then return end
	self:GetShowStrongPanelUserData()
end

def.method("=>", "table").GetAllData = function(self)
	--固定数据，只请求一次
	if self._TableAllStrongData ~= nil and #self._TableAllStrongData > 0 then 
		return self._TableAllStrongData 
	end

	self:InitData()
	return self._TableAllStrongData
end

def.method().InitData = function(self)
	self._TableAllStrongData = {}
    local allData = CElementData.GetAllTid("PlayerStrong")
    for _,v in ipairs(allData) do
    	local iData = CElementData.GetTemplate("PlayerStrong",v)	
    	local index = #self._TableAllStrongData + 1
        self._TableAllStrongData[index] =
        {
        	_Data = iData,
        	_Cells = {}
	    }

	    local strCells = string.split(iData.CellID, "*")
	    if strCells ~= nil then
	    	for i, k in ipairs(strCells) do
            	local CellId = tonumber(k)
            	if CellId ~= nil then
               	 self._TableAllStrongData[index]._Cells[i] = CellId -- 将小类ID放到数组。做显示用
            	end
        	end
	    end
    end  
end

def.method("number","=>","number").GetCellFightScore = function(self,Id)
	local CWingsMan = require "Wings.CWingsMan"
	local CCharmMan = require "Charm.CCharmMan"
	if Id == 1 then --当前装备基础战力（基础 + 精炼）
		local equipLevel = 0
		for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do			
			if v ~= nil and v._Tid ~= 0 then 
				local equipedFight = CScoreCalcMan.Instance():CalcEquipFightScore(game._HostPlayer._InfoData._Prof, v, false)
				equipLevel = equipLevel + equipedFight[EnumDef.EquipFightScoreType.Base] + equipedFight[EnumDef.EquipFightScoreType.Refine]
			end
		end
		
		return equipLevel
	elseif Id == 2 then--装备强化
		local equipInforce = 0
		for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do			
			if v ~= nil and v._Tid ~= 0 then 
				equipInforce = equipInforce + v:GetInforceLevel()
			end
		end	
		-- local equipedFight = CScoreCalcMan.Instance():CalcEquipFightScore(game._HostPlayer._InfoData._Prof, game._HostPlayer._Package._EquipPack._ItemSet, false)
		
		return equipInforce
	elseif Id == 3 then--重铸
		local equipRecast = 0
		for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do			
			if v ~= nil and v._Tid ~= 0 then 
				local equipedFight = CScoreCalcMan.Instance():CalcEquipFightScore(game._HostPlayer._InfoData._Prof, v, false)
				equipRecast = equipRecast + equipedFight[EnumDef.EquipFightScoreType.Recast]
			end
		end	
		-- local equipedFight = CScoreCalcMan.Instance():CalcEquipFightScore(game._HostPlayer._InfoData._Prof, game._HostPlayer._Package._EquipPack._ItemSet, false)
		return equipRecast
	elseif Id == 4 then--技能等级增加战斗力
		return CScoreCalcMan.Instance():CalcAllSkillScore()
	elseif Id == 5 then--技能文章
		return CScoreCalcMan.Instance():CalcSkillRuneScore()
	elseif Id == 6 then--部位精通
		return CSkillUtil.GetMasteryLevel()	
	elseif Id == 7 then--宠物等级：当前出战及助战宠物的平均等级
		local info = CPetUtility.GetAvgInfo()
		return info.AvgLevel
	elseif Id == 8 then--出战宠物技能加成
		return CScoreCalcMan.Instance():GetFightPetSkillFightScore()
	elseif Id == 9 then--铭符等级
		return CCharmMan.Instance():CalculateAllSmallCharmCombatValue()
	elseif Id == 10 then--神符等级
		return CCharmMan.Instance():CalculateAllBigCharmCombatValue()
	elseif Id == 11 then--翅膀数量
		return CWingsMan.Instance():GetAllWingsFightScore()
	elseif Id == 12 then--天赋技能
		return CWingsMan.Instance():GetTalentFightScore()
	elseif Id == 13 then--公会技能
		return game._HostPlayer._Guild:GetGuildSkillScore()
	elseif Id == 14 then--实装评分
		return CDressMan.Instance():GetCurCharmScore()
	elseif Id == 15 then 
		return self:GetFightScoreByPropertiesType(EFightPropertiesType.Manuals)
	elseif Id == 16 then--宠物吞噬
		local info = CPetUtility.GetAvgInfo()
		return info.AvgAptitude
	elseif Id == 17 then--宠物升星
		local info = CPetUtility.GetAvgInfo()
		return info.AvgStar
	elseif Id == 18 then 
		return self:GetFightScoreByPropertiesType(EFightPropertiesType.Design)
	else
		return 0
	end
end

--获得所有装备的战斗力加成
def.method("=>","number").GetAllEquipFightScore = function(self)
	local AllEquipFightScore = 0
	for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do			
		if v ~= nil and v._Tid ~= 0 then 
			local equipedFight = v:GetFightScore()
			AllEquipFightScore = AllEquipFightScore + equipedFight 
		end
	end	
	
	return AllEquipFightScore
	-- return CScoreCalcMan.Instance():GetHostplayerWholeEquipFightScore()
end

--获得所有翅膀的战斗力数据
def.method("=>","number").GetAllWingFightScore = function(self)
	return CWingsMan.Instance():GetAllWingsFightScore() + CWingsMan.Instance():GetTalentFightScore()
end

--技能加成的战斗力
def.method("=>","number").GetAllSkillFightScore = function(self)
	return CScoreCalcMan.Instance():CalcAllSkillScore() + CScoreCalcMan.Instance():GetSkillMasteryScore() + CScoreCalcMan.Instance():CalcSkillRuneScore()
end

--宠物加成的战斗力
def.method("=>","number").GetCurPetAddFightScore = function(self)
   return CScoreCalcMan.Instance():GetWholePetFightScore()  --  + CScoreCalcMan.Instance():GetFightPetSkillFightScore()
end

--神符培养加成战斗力
def.method("=>","number").GetCharmFightScore = function(self)
	--[[local fightScore =  CCharmMan.Instance():GetBigCharmCombatValue() + CCharmMan.Instance():GetSmallCharmCombatValue() + game._HostPlayer._Guild:GetGuildSkillScore()
	return fightScore]]
	return CCharmMan.Instance():CalculateAllBigCharmCombatValue() + CCharmMan.Instance():CalculateAllSmallCharmCombatValue()
end

--其他战斗力 (公会技能 + 时装评分)
def.method("=>","number").GetOtherFightScore = function(self)
	local fightScore = game._HostPlayer._Guild:GetGuildSkillScore()
	return fightScore
end

def.method("number","number","=>","number").GetImgScoreGroupID = function(self, curFight, basicFight)
--	local maxRatio = self._ScoreS / self._ScoreA
--	local ratio = curFight / basicFight * self._ScoreA
--	ratio = math.ceil(ratio)
--	-- warn("ratio "..ratio)\
--	if ratio > self._ScoreS then
--		return 3
--	elseif ratio > self._ScoreA then
--		return 2
--	elseif  ratio > self._ScoreB then
--		return 1
--	else
--		return 0
--	end
    local ratio_value = basicFight/self._ScoreA
    if curFight > ratio_value * self._ScoreS then
        return 3
    elseif curFight > ratio_value * self._ScoreA then
        return 2
    elseif curFight > ratio_value * self._ScoreB then
        return 1
    else
        return 0
    end
end

def.method("number","=>","number").GetFightScoreByType = function(self, nType)
	if nType == 1 then
		return self:GetAllEquipFightScore()
	elseif nType == 2 then
		return self:GetAllSkillFightScore()
	elseif nType == 3 then
		return self:GetCurPetAddFightScore()
	elseif nType == 4 then
		return self:GetCharmFightScore()
	elseif nType == 5 then
		return self:GetAllWingFightScore()
	elseif nType == 6 then
		return self:GetOtherFightScore()
	else
		return 0
	end
end

--通过我要变强数值ID。获取具体推荐基础值
def.method("number","=>","number").GetBasicValueByValueID = function(self, ValueId)
	local basicData = CElementData.GetTemplate("PlayerStrongValue", ValueId)
	if basicData == nil then 
		warn("GetBasicValueByValueID:找不到我要变强ID："..ValueId.."推荐值")
		return 1 
	end--因为有百分比除法。所以默认1

	local idex = math.clamp(game._HostPlayer._InfoData._Level,1, #basicData.ValueDatas)
	return basicData.ValueDatas[idex].Value
end

def.method("number", "=>", "number").GetSValueByValueID = function(self, valueID)
    local basicData = CElementData.GetTemplate("PlayerStrongValue", valueID)
	if basicData == nil then 
		warn("GetBasicValueByValueID:找不到我要变强ID："..valueID.."推荐值")
		return 1 
	end
    local add_value = self._ScoreS/self._ScoreA
	local idex = math.clamp(game._HostPlayer._InfoData._Level,1, #basicData.ValueDatas)
	return math.ceil(basicData.ValueDatas[idex].Value * add_value)
end

--设置我要变强提示状态
def.method("boolean").SetNeedPlayerStrong = function(self, isNeed)
	self._IsNeedPlayerStrong = isNeed
end

local function CheckSetTime(self,Day,Month)
	local nowTime = GameUtil.GetServerTime()/1000
	local timeTable = os.date("*t",nowTime)
    local day,month = 0,0
    for i,v in pairs(timeTable) do
    	if i == "day" then 
    		day = v
    	elseif i == "month" then 
    		month = v
    	end
    end
    if day == Day and month == Month then
    	return true
		-- self._IsShowStrongPanel = data.IsShowPlayerStrongPanel
	else
		return false
		-- self._IsShowStrongPanel = true
	end
end

local function GetSetTime(self)
	local nowTime = GameUtil.GetServerTime()/1000
    local timeTable = os.date("*t",nowTime)
    local day,month = 0,0
    for i,v in pairs(timeTable) do
    	if i == "day" then 
    		day = v
    	elseif i == "month" then 
    		month = v
    	end
    end
    return day,month
end

def.method("boolean").SetShowPlayerStrongPanel = function(self, isShow)
	self._IsShowStrongPanel = isShow
	self._SetDateDay,self._SetDateMonth = GetSetTime(self)
end

def.method("=>","boolean").GetShowPlayerStrongPanelState = function (self)
	local isEqual = CheckSetTime(self,self._SetDateDay,self._SetDateMonth)
	if not isEqual then 
		self._IsShowStrongPanel = true
		return self._IsShowStrongPanel
	end
	return self._IsShowStrongPanel
end

--是否需要提示我要变强
def.method().CheckShowPlayerStrong = function(self)
	local isEqual = CheckSetTime(self,self._SetDateDay,self._SetDateMonth)
	if not isEqual then 
		self._IsShowStrongPanel = true
	end
	if self._IsNeedPlayerStrong and self._IsShowStrongPanel then
		self._IsNeedPlayerStrong = false
		game._GUIMan:Open("CPanelStrong",{ PageType = CPanelStrong.PageType.GETSTRONG})
	end
end

-- 获取我要变强用户数据
def.method().GetShowStrongPanelUserData = function (self)
	local account = game._NetMan._UserName
    local data = nil
    local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.IsShowPlayerStrongPanel, account)  or {} 
    if accountInfo ~= nil then
        local serverInfo = accountInfo[game._NetMan._ServerName]
        if serverInfo ~= nil then
            data = serverInfo[game._HostPlayer._ID]
        end
    end
    if data ~= nil then 
    	self._SetDateDay,self._SetDateMonth = data.Day ,data.Month
    	local isEqual = CheckSetTime(self,self._SetDateDay,self._SetDateMonth)
		if not isEqual then 
			self._IsShowStrongPanel = true
		else
			self._IsShowStrongPanel = data.IsShowPlayerStrongPanel
		end
    end
	self._IsGetUserData = false
	-- body
end

def.method().SaveRecord = function (self)
	if game._HostPlayer == nil or game._HostPlayer._ID == 0 then return end
	local account = game._NetMan._UserName
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.IsShowPlayerStrongPanel, account)
    if accountInfo == nil then
        accountInfo = {}
    end
    local serverName = game._NetMan._ServerName
    if accountInfo[serverName] == nil then
        accountInfo[serverName] = {}
    end
    local roleId = game._HostPlayer._ID
    if accountInfo[serverName][roleId] == nil then
        accountInfo[serverName][roleId] = {}
    end
    local day, month = GetSetTime(self)
    local data = {
    				IsShowPlayerStrongPanel = self._IsShowStrongPanel,
    				Day = day ,
    				Month = month,
				}
    accountInfo[serverName][roleId] = data
    UserData.Instance():SetCfg(EnumDef.LocalFields.IsShowPlayerStrongPanel, account, accountInfo)
end

local EFightPropertiesType = require "PB.data".EFightPropertiesType
--战力更新
def.method("table").ChangeFightScore = function(self, msg)
	if msg.FightScoreType == EFightPropertiesType.Design then
		self._DesignationFightScore = msg.Value
	elseif msg.FightScoreType == EFightPropertiesType.Manuals then
		self._ManualFightScore = msg.Value
	end
end

-- 根据类型获得战力
def.method("number","=>","number").GetFightScoreByPropertiesType = function(self, PropertiesType)
	if PropertiesType == EFightPropertiesType.Design then
		return self._DesignationFightScore
	elseif PropertiesType == EFightPropertiesType.Manuals then
		return self._ManualFightScore
	end
end

def.method().Cleanup = function(self)
	self._TableAllStrongData = nil
	self._IsNeedPlayerStrong = false
	self._DesignationFightScore = 0
	self._ManualFightScore = 0
	self._IsGetUserData = true
	self._SetDateDay = 0
	self._SetDateMonth = 0 
end

CPlayerStrongMan.Commit()   
return CPlayerStrongMan