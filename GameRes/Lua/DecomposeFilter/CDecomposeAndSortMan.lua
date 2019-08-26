
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelRoleInfo = require"GUI.CPanelRoleInfo"
local UserData = require "Data.UserData"

local CDecomposeAndSortMan = Lplus.Class("CDecomposeAndSortMan")
local def = CDecomposeAndSortMan.define

def.field("table")._CurSelectParts = BlankTable
def.field("table")._CurSelectQualitys = BlankTable
def.field("boolean")._IsTimerDecompose = false    --分解定时
def.field("boolean")._IsSelectAllParts = false
def.field("boolean")._IsSelectAllQualitys = false
def.field("boolean")._IsGetUserData = true

-- 排序
def.field("boolean")._IsDescending = true
def.field("number")._CurSortType = 0

def.final("=>", CDecomposeAndSortMan).new = function ()
	local obj = CDecomposeAndSortMan()
	return obj
end

def.method().Init = function(self) 
	if not self._IsGetUserData then return end
	self:GetDecomposeUserData()
	self:GetSortUserData()
end

-- 获取分解用户数据
def.method().GetDecomposeUserData = function(self) 
	local account = game._NetMan._UserName
    local data = nil
    local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.DecomposeFliter, account)  or {} 
    if accountInfo ~= nil then
        local serverInfo = accountInfo[game._NetMan._ServerName]
        if serverInfo ~= nil then
            data = serverInfo[game._HostPlayer._ID]
        end
    end
    if data ~= nil then 
	    self._CurSelectParts = data.Part
	    self._CurSelectQualitys = data.Quality
	    self._IsTimerDecompose = data.IsTimer
	    self._IsSelectAllQualitys = data.IsSlectAllQuality
	    self._IsSelectAllParts = data.IsSlectAllParts
	else
		self._CurSelectQualitys = {}
		self._CurSelectParts = {}
		self._IsTimerDecompose = false
		self._IsSelectAllParts = false
		self._IsSelectAllQualitys = false
	end
	self._IsGetUserData = false
	self:AddDecomposeTimer()
end

-- 获取排序用户数据
def.method().GetSortUserData = function(self) 
	local account = game._NetMan._UserName
    local data = nil
    local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.BagSort, account)  or {} 
    if accountInfo ~= nil then
        local serverInfo = accountInfo[game._NetMan._ServerName]
        if serverInfo ~= nil then
            data = serverInfo[game._HostPlayer._ID]
        end
    end
    if data ~= nil then 
    	self._CurSortType = data.CurSortType
    	self._IsDescending = data.IsDescending
    end
end

-- 保存排序数据
def.method("number","boolean").SaveSortData = function(self,sortType,isDescending)
	self._IsDescending = isDescending
	self._CurSortType = sortType
end
-- 保存分解数据
def.method("number").SavePartFilterData = function(self,index)
	table.insert(self._CurSelectParts,index)
end

def.method("number").SaveQualityFilterData = function(self,index)
	table.insert(self._CurSelectQualitys,index)
end

def.method().ClearCurRdoData = function(self)
	self._CurSelectQualitys = {}
	self._CurSelectParts = {}
end

def.method("boolean").SetAllQualityRdoState = function(self,state) 
	self._IsSelectAllQualitys = state
end

def.method("boolean").SetAllPartRdoState = function(self,state)
	self._IsSelectAllParts = state
end

def.method("boolean").SetDecomposeTimerState = function(self,state)
	self._IsTimerDecompose = state
end

def.method("=>","boolean").GetDecomposeTimerState = function(self)
	return self._IsTimerDecompose 
end

def.method("=>","table").GetQualityFilterData = function(self)
	return self._CurSelectQualitys
end

def.method("=>","table").GetPartFilterData = function(self)
	return self._CurSelectParts
end

def.method().AddDecomposeTimer = function(self)
	if not self._IsTimerDecompose then return end
	CPanelRoleInfo.Instance():AddDecomposeTimer()
end

def.method().SaveRecord = function(self)
	self:SaveFilterRecord()
	self:SaveSortRecord()
end

def.method().SaveFilterRecord = function(self)
	if game._HostPlayer == nil or game._HostPlayer._ID == 0 then return end
	local account = game._NetMan._UserName
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.DecomposeFliter, account)
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
    local data = {
    				Part = self._CurSelectParts,
    				Quality = self._CurSelectQualitys,
    				IsTimer = self._IsTimerDecompose,
    				IsSlectAllQuality = self._IsSelectAllQualitys,
    				IsSlectAllParts = self._IsSelectAllParts,
				}
    accountInfo[serverName][roleId] = data
    UserData.Instance():SetCfg(EnumDef.LocalFields.DecomposeFliter, account, accountInfo)
end

def.method().SaveSortRecord = function(self)
	if game._HostPlayer == nil or game._HostPlayer._ID == 0 then return end
	local account = game._NetMan._UserName
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.BagSort, account)
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
    local data = {
    				IsDescending = self._IsDescending,
    				CurSortType = self._CurSortType,
				}
    accountInfo[serverName][roleId] = data
    UserData.Instance():SetCfg(EnumDef.LocalFields.BagSort, account, accountInfo)
end

def.method().Cleanup = function(self)
	self._CurSelectQualitys = {}
	self._CurSelectParts = {}
	self._IsTimerDecompose = false
	self._IsSelectAllQualitys = false
	self._IsSelectAllParts = false	
	self._IsGetUserData = true
end

CDecomposeAndSortMan.Commit()
return CDecomposeAndSortMan