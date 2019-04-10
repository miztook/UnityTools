local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CDress = require "Dress.CDress"
local CDressUtility = require "Dress.CDressUtility"
local CPlayer = require "Object.CPlayer"
local CElementData = require "Data.CElementData"
local EWearType = require "PB.net".eWearType			--时装穿脱类型
local EUpdateType = require "PB.net".eUpdateType 		--时装更新类型
local EDressType = require "PB.Template".Dress.eDressType
local Util = require "Utility.Util"
local bit = require "bit"

local CDressMan = Lplus.Class("CDressMan")
local def = CDressMan.define

def.field("table")._LocalDressInfo = BlankTable			--本地同步后维护的list
def.field("boolean")._InitDressList = false				--是否同步数据

def.field("table")._AllDressList = BlankTable			--所有时装信息，预处理存储
def.field("boolean")._HasPreload = false				--是否已预处理数据

local instance = nil
def.static('=>', CDressMan).Instance = function()
	if not instance then
        instance = CDressMan()
	end
	return instance
end

----------------------------------------------------------------------
--							Client::Dress Funcs
----------------------------------------------------------------------
local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

-- @param updateType 更新类型 0:列表初始化 1:添加时装 2:时装过期 3:时装分解 4:时装穿戴或卸下 5:时装染色
local function RefreshPanel(updateType)
	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if CPanelUIExterior.Instance():IsShow() then
		warn("CDressMan::RefreshPanel() ", updateType)
		CPanelUIExterior.Instance():UpdateDressList(updateType)
	end
end

--增加时装操作
local function AddDress(self, dressInfo)
	local dressData = CDress.new(dressInfo)
	if dressData then
		table.insert(self._LocalDressInfo, dressData)
		if self:IsWeared( dressData._ID ) then
			dressData._IsWeared = true
		end
	end
end

--删除时装操作
local function RemoveDress(self, dressInfo)
	local dressInfoList = self._LocalDressInfo
	if #dressInfoList > 0 then
		local findIndex = 0
		for i=1,#dressInfoList do
			if dressInfoList[i]._ID == dressInfo.InsId then
				findIndex = i
				break
			end
		end

		if findIndex > 0 then
			table.remove(dressInfoList, findIndex)
		end
	end
end

-- 更新时装染色信息
local function UpdateDressDyeInfo(dressData, dyeId1, dyeId2)
	-- 修改时装的染色信息
	local isSucceeded = false
	if dyeId1 > -1 and dressData._Colors[1] ~= nil then
		-- 部位一
		dressData._Colors[1] = dyeId1
		isSucceeded = true
	end
	if dyeId2 > - 1 and dressData._Colors[2] ~= nil then
		-- 部位二
		dressData._Colors[2] = dyeId2
		isSucceeded = true
	end
	return isSucceeded
end

-- 清空数据
def.method().Clear = function(self)
	self._LocalDressInfo = {}
	self._InitDressList = false
	self._AllDressList = {}
	self._HasPreload = false
end

--预处理所有时装，存到列表中缓存
def.method().PreloadAllDress = function(self)
	if self._HasPreload then return end

	self._AllDressList = {
		Weapon = {},
		Helmet = {},
		Armor = {},
	}
	local function InsertDressList(dressInfo)
		if dressInfo._DressSlot == EDressType.Weapon then
			table.insert(self._AllDressList.Weapon, dressInfo)
		elseif dressInfo._DressSlot == EDressType.Hat or dressInfo._DressSlot == EDressType.Headdress then
			-- 帽子或头饰
			table.insert(self._AllDressList.Helmet, dressInfo)
		elseif dressInfo._DressSlot == EDressType.Armor then
			table.insert(self._AllDressList.Armor, dressInfo)
		end
	end

	local allTids = GameUtil.GetAllTid("Dress")
	local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
	for i=1, #allTids do
		local dressTid = allTids[i]
		local dressInfo = CDress.CreateVirtual(dressTid)
		if dressInfo ~= nil and dressInfo._Template.TimeLimit == 0 and profMask == bit.band(dressInfo._Template.Profession, profMask) then
			InsertDressList(dressInfo)
		end
	end
	self._HasPreload = true
end

def.method("=>", "table").GetAllDressList = function(self)
	return self._AllDressList
end

def.method("=>", "table", "boolean").GetDressDBInfoList = function(self)
	return self._LocalDressInfo, self._InitDressList
end

def.method("number", "=>", "table").GetDressInfo = function(self, dressId)
	local info = nil

	if self._InitDressList then
		if #self._LocalDressInfo > 0 then
			for i=1, #self._LocalDressInfo do
				if self._LocalDressInfo[i]._ID == dressId then
					info = self._LocalDressInfo[i]
					break
				end
			end
		end
	else
		local hp = game._HostPlayer
		for _,v in pairs( hp:GetCurDressInfos() ) do
			if v._ID == dressId then
				info = v
				break
			end
		end
	end

	return info
end

def.method(CPlayer, "number", "=>", "table").GetElsePlayerDressInfo = function(self, player, dressId)
	local info = nil

	for _,v in pairs( player:GetCurDressInfos() ) do
		if v._ID == dressId then
			info = v
			break
		end
	end

	return info
end

-- 获取当前总魅力值
def.method("=>", "number").GetCurCharmScore = function(self)
	local score = 0
	for _, dressInfo in ipairs(self._LocalDressInfo) do
		if dressInfo._ID > 0 and dressInfo._TimeLimit <= 0 then
			score = score + dressInfo._Template.Score
		end
	end
	return score
end

--是否穿在身上
def.method("number", "=>", "boolean").IsWeared = function(self, dressId)
	local bRet = false
	local hp = game._HostPlayer

	for _,info in pairs(hp:GetCurDressInfos()) do
		if info._ID == dressId then
			bRet = true
			break
		end
	end

	return bRet
end

-- 根据部位获取当前穿戴的时装实例Id
def.method("number", "=>", "number").GetCurDressIdBySlot = function (self, dressSlot)
	local part = Util.GetDressPartBySlot(dressSlot)
	local dressInfo = game._HostPlayer:GetCurDressInfoByPart(part)
	if dressInfo ~= nil then
		return dressInfo._ID
	else
		return 0
	end
end

-- 获取当前时装加成的战力
def.method("=>", "number").GetCurFightScore = function (self)
	local scoreList = CDressUtility.GetChramScoreList() -- 魅力值列表
	local curCharm = self:GetCurCharmScore() -- 当前魅力值
	local propList = {}
	for _, data in ipairs(scoreList) do
		if data.Score > curCharm then break end
		for _, attriData in ipairs(data.AttriList) do
			local temp =
			{
				ID = attriData.Id,
				Value = attriData.Value
			}
			propList[#propList+1] = temp
		end
	end

	local CScoreCalcMan = require "Data.CScoreCalcMan"
	return CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, propList)
end

----------------------------------------------------------------------
--							处理服务器推送
----------------------------------------------------------------------

--重置时装
def.method("table").InitDressInfo = function(self, infoList)
	-- warn("InitDressInfo Count = ", #infoList)
	self._LocalDressInfo = {}
	for _,info in ipairs( infoList ) do
		AddDress(self, info)
	end

	self._InitDressList = true
	RefreshPanel(0)
end

--更新时装
def.method("table", "number").UpdateDressInfo = function(self, dressInfo, updateType)
	local template = CElementData.GetTemplate("Dress", dressInfo.Tid)
	if template == nil then
		error("UpdateDressInfo failed, wrong dress tid:" .. tostring(dressInfo.Tid))
		return
	end

	local _, bInit = self:GetDressDBInfoList()
	if bInit == false then
		-- warn("Dress List has not inited, please S2CDressDataSync first")
		return
	end

	if updateType == EUpdateType.Remove then
		-- 时装到期
		RemoveDress(self, dressInfo)
		local namStr = RichTextTools.GetQualityText(template.ShowName, template.Quality)
		SendFlashMsg(string.format(StringTable.Get(20709), namStr), false)
		RefreshPanel(2)
	elseif updateType == EUpdateType.Decompose then
		-- 时装分解
		RemoveDress(self, dressInfo)
		SendFlashMsg(StringTable.Get(20710), false)
		RefreshPanel(3)
	elseif updateType == EUpdateType.Add then
		-- 获得时装
		AddDress(self, dressInfo)

		-- 保存红点显示状态
		local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
		if exteriorMap == nil then
			exteriorMap = {}
		end
		local key = "Dress"
		if exteriorMap[key] == nil then
			exteriorMap[key] = {}
		end
		local slot = template.Slot
		if exteriorMap[key][slot] == nil then
			exteriorMap[key][slot] = {}
		end

		exteriorMap[key][slot][dressInfo.InsId] = true
		CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Exterior, exteriorMap)
		-- 更新系统菜单红点
		-- CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, true)

		RefreshPanel(1)
	end
end

--时装染色
def.method("table").OnHostPlayerDressTint = function(self, dressInfo)
	if dressInfo == nil then return end

	local isSucceeded = false
	if self._InitDressList then
		local manData = self:GetDressInfo(dressInfo.InsId) -- 管理器的数据
		if manData == nil then
			warn("Invalid tint dress, cant find dress with intance Id:" .. dressInfo.InsId)
			return
		end
		isSucceeded = UpdateDressDyeInfo(manData, dressInfo.DeId1, dressInfo.DeId2)
	end

	local hp = game._HostPlayer
	for _, dressData in pairs(hp:GetCurDressInfos()) do
		if dressData._ID == dressInfo.InsId then
			isSucceeded = UpdateDressDyeInfo(dressData, dressInfo.DeId1, dressInfo.DeId2)
			if isSucceeded then
				hp:UpdateDressColors(dressData._DressSlot, dressData._Colors)
			end
			break
		end
	end

	if isSucceeded then
		-- 染色成功
		SendFlashMsg(StringTable.Get(20705), false)
		RefreshPanel(5)
	end
end

--视野范围内其他玩家，时装染色
def.method(CPlayer, "table").OnElsePlayerDressTint = function(self, player, dressInfo)
	--warn("ProcessDressInfo...")
	if player == nil or dressInfo == nil then return end

	local targetDress = self:GetElsePlayerDressInfo(player, dressInfo.InsId)
	if targetDress == nil then
		warn("Invalid tint dress on else player, cant find dress with intance Id:" .. dressInfo.InsId)
		return
	end

	local isSucceeded = UpdateDressDyeInfo(targetDress, dressInfo.DeId1, dressInfo.DeId2)
	if isSucceeded then
		-- 染色成功
		player:UpdateDressColors(targetDress._DressSlot, targetDress._Colors)
	end
end

--穿戴
def.method("table").OnHostPlayerPutOnMsg = function(self, dressInfo)
	if dressInfo == nil then return end

	local data = CDress.new(dressInfo)
	if data == nil then return end

	local hp = game._HostPlayer
	if self._InitDressList then
		-- 已经初始化
		local localData = self:GetDressInfo(dressInfo.InsId)
		if localData ~= nil then
			-- 修改本地信息
			localData._IsWeared = true
		else
			warn("Invalid put on dress, cant find dress with intance Id:", dressInfo.InsId)
			return
		end

		-- 处理已穿戴的信息
		local part = Util.GetDressPartBySlot(data._DressSlot)
		local curInfo = hp:GetCurDressInfoByPart(part)
		if curInfo ~= nil then
			local manData = self:GetDressInfo(curInfo._ID) -- 管理器的本地数据
			manData._IsWeared = false
		end
	end

	--然后穿上的新时装
	data._IsWeared = true
	-- 1.数据 2.是否是服务器数据 3.是否是穿的动作
	hp:SetCurDressInfo(data, true)

	RefreshPanel(4)
end

--脱下
def.method("number").OnHostPlayerTakeOffMsg = function(self, dressId)
	local takeOffData = self:GetDressInfo(dressId)
	if takeOffData == nil then return end

	takeOffData._IsWeared = false
	game._HostPlayer:SetCurDressInfo(takeOffData, false)

	-- 更新页面的装备Icon显示
	RefreshPanel(4)
end

--视野内其他玩家 穿戴
def.method(CPlayer, "table").OnElsePlayerPutOnMsg = function(self, player, dressDBInfo)
	local data = CDress.new(dressDBInfo)
	if data == nil then return end

	player:SetCurDressInfo(data, true)
end

--视野内其他玩家 脱下
def.method(CPlayer, "number").OnElsePlayerTakeOffMsg = function(self, player, dressId)
	local takeOffData = self:GetElsePlayerDressInfo(player, dressId)
	if takeOffData == nil then return end

	player:SetCurDressInfo(takeOffData, false)
end

----------------------------------------------------------------------
--							C2S::S2CDress Funcs
----------------------------------------------------------------------

--请求角色时装数据
def.method().RequestDressDataSync = function(self)
	if self._InitDressList then return end
	
	local C2SDressDataSync = require "PB.net".C2SDressDataSync
	local protocol = C2SDressDataSync()
	SendProtocol(protocol)
end

--穿戴
def.method("number").PutOn = function(self, dressId)
	local C2SDressWear = require "PB.net".C2SDressWear
	local protocol = C2SDressWear()
	protocol.WearType = EWearType.PutOn
	protocol.InsId = dressId
	SendProtocol(protocol)
end

--脱下
def.method("number").TakeOff = function(self, dressId)
	local C2SDressWear = require "PB.net".C2SDressWear
	local protocol = C2SDressWear()
	protocol.WearType = EWearType.TakeOff
	protocol.InsId = dressId
	SendProtocol(protocol)
end

--删除
def.method("number").RemoveDress = function(self, dressId)
	local C2SDressRemove = require "PB.net".C2SDressRemove
	local protocol = C2SDressRemove()
	protocol.InsId = dressId
	SendProtocol(protocol)
end

--染色
-- @param dressId 时装实例Id
-- @param dyeId1 部位一的染色Id
-- @param dyeId2 部位二的染色Id
def.method("number", "number", "number").DyeDress = function(self, dressId, dyeId1, dyeId2)
	local C2SDressDye = require "PB.net".C2SDressDye
	local protocol = C2SDressDye()
	protocol.InsId = dressId
	protocol.DeId1 = dyeId1
	protocol.DeId2 = dyeId2
	SendProtocol(protocol)
end

-- --刺绣
-- def.method("number", "number").EmbroideryDress = function(self, dressId, embroideryId)
-- 	local C2SDressDyeAndEmbroidery = require "PB.net".C2SDressDyeAndEmbroidery

-- 	local protocol = C2SDressDyeAndEmbroidery()
-- 	protocol.InsId = dressId
-- 	protocol.DeType = EDEType.Embroidery
-- 	protocol.DeId = embroideryId

-- 	SendProtocol(protocol)
-- end

--是否显示时装
def.method("boolean").C2SShowDress = function(self, bShow)
-- warn("bShow ==  ",bShow)
	local C2SDressFirstShow = require "PB.net".C2SDressFirstShow
	local protocol = C2SDressFirstShow()
	protocol.IsFirst = bShow

	SendProtocol(protocol)
end

-- 时装分解
-- @param insId 时装实例ID
def.method("number").C2SDecomposeDress = function(self, insId)
	local C2SDressDecomposeReq = require "PB.net".C2SDressDecomposeReq
	local protocol = C2SDressDecomposeReq()
	protocol.InsId = insId
	SendProtocol(protocol)
end

CDressMan.Commit()
return CDressMan