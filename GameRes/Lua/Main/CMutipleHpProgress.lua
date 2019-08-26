local Lplus = require "Lplus"
local CMutipleHpProgress = Lplus.Class("CMutipleHpProgress")

local def = CMutipleHpProgress.define
local instance = nil

def.field("userdata")._GameObject = nil					-- 血条控件
def.field("dynamic")._Indicator = nil					-- GBlood控件
def.field("userdata")._Lab_MutiProgressCount = nil		-- 血条个数
def.field("userdata")._Lab_HP = nil						-- 血条数字

def.field("number")._HpMax = 0							-- 血量上限
def.field("number")._CellCountMax = 0					-- 血条上限
def.field("number")._CellHpMax = 0						-- 单条血量上限 (单条血量上限 = HpMax / CountMax)

def.field("number")._CurCellCount = 0 					-- 血量总条数 （有规则计算 或 取到对应血条总数）
def.field("number")._CurHp = 0							-- 血量总和
def.field("number")._CurCellHp = 0						-- 当前血条的血量

def.static("=>", CMutipleHpProgress).Instance = function()
	if not instance then
		instance = CMutipleHpProgress()
	end
	return instance
end

-- 初始化 血条控件
def.method("userdata", "number", "number").Init = function(self, gameObject, hpMax, cellCountMax)
	if gameObject == nil or hpMax * cellCountMax == 0 then return end

	self:Reset()

	self._GameObject = gameObject
	self._Indicator = self._GameObject:GetComponent(ClassType.GBlood)
	self._Lab_MutiProgressCount = self._GameObject:FindChild("Lab_MutiProgressCount")
	self._Lab_HP = self._GameObject:FindChild("Lab_HP")

	self._HpMax = hpMax
	self._CellCountMax = cellCountMax

	-- 计算单个血条-最大血量上限
	self._CellHpMax = math.ceil(self._HpMax / self._CellCountMax)
	-- 设置数量
	self:SetCellCount(self._CellCountMax, true)

	-- warn("单个血条-最大血量上限 = ", self._CellHpMax)
	-- warn("HpMax = ", self._HpMax)
	-- warn("血条数量 = ", self._CellCountMax)
end

def.method("number", "=>", "table").CalcMutipleProcessInfo = function(self, hp)
	local result = {}
	result.Old = {}
	result.New = {}

	do
		-- 上次血量
		local info = result.Old
		info.Hp = self._CurHp
		info.CellCount = math.ceil(info.Hp / self._CellHpMax)
		info.CellHp = info.Hp - (info.CellCount - 1) * self._CellHpMax   --info.Hp % self._CellHpMax
	end

	do
		-- 当前血量
		local info = result.New
		info.Hp = hp
		info.CellCount = math.ceil(info.Hp / self._CellHpMax)
		info.CellHp = info.Hp - math.max(0, info.CellCount - 1) * self._CellHpMax
		-- warn("Hp = ", info.Hp)
		-- warn("CellHp = ", info.CellHp)
		-- warn("CellCount = ", info.CellCount)
		-- warn("AAAAAAAAA ", info.Hp, self._CellHpMax)
	end

	result.Increase = result.New.Hp - result.Old.Hp
	result.AcrossCellCount = math.abs(result.Old.CellCount - result.New.CellCount)

	return result
end

def.method("number", "number").SetHp = function(self, hp, shieldVal)
	-- 计算当前显示用的数据模块
	local hpInfo = self:CalcMutipleProcessInfo(hp)
	-- 死亡 / 复活 两种立即设置
	local immediately = (hpInfo.Old.Hp == 0) or (hpInfo.New.Hp == 0)

	do
		-- 设置当前属性
		local info = hpInfo.New
		self._CurHp = info.Hp
		self._CurCellHp = info.CellHp
	end

	do
		-- 血条数目变化
		if hpInfo.AcrossCellCount > 0 then
			self._Indicator:SetValueImmediately(1)
			self:SetCellCount(hpInfo.New.CellCount, false)
		end
	end

	do
		-- 单血条比例
		if shieldVal > 0 then
			local allRatio = (self._CurCellHp + shieldVal) / self._CellHpMax
			if allRatio < 1 then
				-- 和小于总血量
                local hpRatio = self._CurCellHp / self._CellHpMax
                self._Indicator:SetValue(hpRatio)
				-- 更新护盾值
                self._Indicator:SetGuardValue(allRatio)
			else
				-- 和大于总血量
                -- local hpRatio = 1 - (shieldVal / self._CellHpMax)
                local hpRatio = 1 - (shieldVal / (self._CurCellHp + shieldVal) )
                self._Indicator:SetValue(hpRatio)
				-- 更新护盾值
                self._Indicator:SetGuardValue(1)
			end
		else
			-- 更新护盾值
			self._Indicator:SetGuardValue(0)
			local hpRatio = self._CurCellHp / self._CellHpMax
			-- warn("hpRatio : ", hpRatio, self._CurCellHp, self._CellHpMax)
			self._Indicator:SetValue(hpRatio)
		end
	end

	do
		-- 总血量比值
    	local allRatio = self._CurHp / self._HpMax
        allRatio =  allRatio * 100
        if allRatio > 0 and allRatio < 1 then 
            allRatio = 1
        end
        allRatio = math.clamp(allRatio, 0, 100)
        GUI.SetText(self._Lab_HP, tostring(math.floor(allRatio)) .. "%" )
	end

	if immediately then
		
	else
		-- DoTween
	end
end

-- 设置血条个数 可能会添加特效，在此处添加合适
def.method("number", "boolean").SetCellCount = function(self, count, immediately)
	if self._CurCellCount == count then return end

	self._CurCellCount = count
	self._Indicator:SetLineStyle(self._CurCellCount)

	self._Lab_MutiProgressCount:SetActive(self._CurCellCount > 1)
	if self._CurCellCount > 1 then
		local str = string.format(StringTable.Get(31399), self._CurCellCount)
		-- 更新 数据
		GUI.SetText(self._Lab_MutiProgressCount , str)
	end

	if immediately then
		
	else
		-- 播放 特效
	end
end


-- 初始化 血条控件
def.method().Reset = function(self)
	self._HpMax = 0							-- 血量上限
	self._CellCountMax = 0					-- 血条上限
	self._CellHpMax = 0						-- 单条血量上限 (单条血量上限 = HpMax / CountMax)
	self._CurCellCount = 0 					-- 血量总条数 （有规则计算 或 取到对应血条总数）
	self._CurHp = 0							-- 血量总和
	self._CurCellHp = 0						-- 当前血条的血量
end

def.method().Release = function(self)
	self:Reset()
	instance = nil
end

CMutipleHpProgress.Commit()
return CMutipleHpProgress