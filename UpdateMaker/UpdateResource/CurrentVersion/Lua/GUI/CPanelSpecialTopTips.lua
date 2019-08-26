local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelSpecialTopTips = Lplus.Extend(CPanelBase, 'CPanelSpecialTopTips')
local def = CPanelSpecialTopTips.define

--label显示文本
def.field("userdata")._TipsLabelObj = nil
def.field("userdata")._TipsLabel = nil 
def.field("userdata")._TipsLabelRect = nil
def.field("userdata")._ImgBg = nil

def.field("number")._ScreenWidth = 0
--def.field("number")._TimerID = 0 

local instance = nil
local tableTips = {}

--[[*************************************
           走马灯提示
                   ----by luee 2016.12.5
****************************************]]
def.static('=>', CPanelSpecialTopTips).Instance = function()
	if not instance then
		instance = CPanelSpecialTopTips()
        instance._PrefabPath = PATH.Panel_SpecialTopTips
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
	instance._ForbidESC = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._TipsLabelObj = self:GetUIObject("Lab_Message")

	local textType = ClassType.Text
	self._TipsLabel = self._TipsLabelObj:GetComponent(textType)

	local rectType = ClassType.RectTransform
	self._TipsLabelRect = self._TipsLabelObj: GetComponent(rectType)

  self._ImgBg = self:GetUIObject("Img_Bg")
  local BGRect = self._ImgBg: GetComponent(rectType)
	self._ScreenWidth = BGRect.rect.width
end

def.override("dynamic").OnData = function(self, data)
  	if (data == "") then 
  		if(#tableTips <= 0) then
			game._GUIMan:CloseByScript(self)	
  		end  
  		return 	 	
   	end

	--warn("SP tip count "..(#tableTips))

  	tableTips[#tableTips + 1] = data

  	if(#tableTips == 1) then
  		self:SetTips(tableTips[1])
  	end
end 

--def.method().ClearTimer = function(self)
--    if self._TimerID ~= 0 then
--      _G.RemoveGlobalTimer(self._TimerID)
--      self._TimerID = 0
--    end
--end

def.method("string").SetTips = function(self,tips)
	--warn("SetTips")

    local fTime = 0;
	GUITools.DoKill(self._TipsLabelObj)
	GUITools.DoKill(self._ImgBg)
    GUITools.DoAlpha(self._TipsLabelObj, 1, 0.1, nil)
    GUITools.DoAlpha(self._ImgBg, 1, 0.1, nil)
    self._TipsLabel.text = tips;
    local x = self._ScreenWidth + self._TipsLabel.preferredWidth / 2
    self._TipsLabelRect.anchoredPosition = Vector2.New(x,0);
    fTime = (self._ScreenWidth + self._TipsLabel.preferredWidth) / 108;
    local endPos = Vector3.New(-self._TipsLabel.preferredWidth / 2 - self._ScreenWidth / 2,self._TipsLabelObj.localPosition.y,0)
--    GUITools.DoLocalMove(self._TipsLabelObj,endPos ,fTime, nil,function()
-- 		table.remove(tableTips,1)

--        if (#tableTips > 0) then
--            self: SetTips(tableTips[1])
--        else
--           game._GUIMan:CloseByScript(self)
--           tableTips = {}
--        end
--    end)

--	self: ClearTimer()
--	local showTime = fTime - fTime / 10
--	self._TimerID =  _G.AddGlobalTimer(showTime, true, function()
--		GUITools.DoAlpha(self._ImgBg, 0.4, fTime /10, nil)
--		self._TimerID = 0
--	end)

	if fTime < 1 then fTime = 1 end
    GUITools.DoLocalMove(self._TipsLabelObj,endPos ,fTime, nil, nil)

	local mid_cb=function()
		GUITools.DoAlpha(self._ImgBg, 0.4, 0.5, nil)
    end
    self:AddEvt_LuaCB("SpTip", fTime - 0.5, mid_cb)

	local end_cb=function()
 		table.remove(tableTips,1)
        if (#tableTips > 0) then
            self: SetTips(tableTips[1])
        else
           game._GUIMan:CloseByScript(self)	
           --tableTips = {}
        end
    end
    self:AddEvt_LuaCB("SpTip", fTime + 0.2, end_cb)
end

def.override().OnHide = function(self)
    self:KillEvts("SpTip")
	--self: ClearTimer()
	tableTips = {}
end

def.override().OnDestroy = function(self)  
   self._TipsLabelObj = nil
   self._TipsLabel = nil
   self._TipsLabelRect = nil
   self._ImgBg = nil
end

CPanelSpecialTopTips.Commit()
return CPanelSpecialTopTips
