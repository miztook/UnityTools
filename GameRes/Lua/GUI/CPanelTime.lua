local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelTime = Lplus.Extend(CPanelBase, "CPanelTime")
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local def = CPanelTime.define

local instance = nil
def.static("=>", CPanelTime).Instance = function()
	if not instance then
		instance = CPanelTime()
		instance._PrefabPath = PATH.Panel_Time
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- def.override("dynamic").OnData = function(self, data)
-- 	GameUtil.PlayUISfx(PATH.UIFx_TimerStartFx,self._Panel,self._Panel,-1)
-- end
 

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	CPanelBase.OnDOTComplete(self,go_name,dot_id)
	if go_name == "Img_Start" and dot_id == "Start" then 
		GameUtil.PlayUISfx(PATH.UIFx_TimerStartFx,self._Panel,self._Panel,-1)
	elseif go_name == "Img_Start" and dot_id == "End" then 
		if game._HostPlayer:In1V1Fight() then 
			CAutoFightMan.Instance():Start()
			CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
		end
		game._GUIMan:CloseByScript(self)
	end
end

CPanelTime.Commit()
return CPanelTime