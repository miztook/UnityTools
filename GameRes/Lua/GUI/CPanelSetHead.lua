
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local ECustomSet = require "PB.data".ECustomSet
local PBHelper = require "Network.PBHelper"

local CPanelSetHead = Lplus.Extend(CPanelBase, 'CPanelSetHead')
local def = CPanelSetHead.define
-- local NotifyPropEvent = require "Events.NotifyPropEvent"

def.field('userdata')._ImgHead = nil

local Currentfilepath = nil

local instance = nil
def.static('=>', CPanelSetHead).Instance = function ()
	if not instance then
        instance = CPanelSetHead()
        instance._PrefabPath = PATH.Panel_SetHead
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        -- instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._ImgHead = self:GetUIObject('Img_Head')
end

def.override("dynamic").OnData =function (self,data)  
    self:UpdateCustomImg()
end

def.override().OnHide = function (self)
    CPanelBase.OnHide(self)
	-- self:UnlistenToEvent()
    Currentfilepath = nil
end

-- local OnNotifyLevelEvent = function(sender, event)
-- 	if game._HostPlayer._ID ~= event.ObjID then return end
-- 	instance:UpdateCustomImg()
-- end

-- def.method().ListenToEvent = function(self)
-- 	CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyLevelEvent)	
-- end

-- def.method().UnlistenToEvent = function(self)
-- 	CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyLevelEvent)
-- end

-- 审核中：本地存在图片，显示自定义头像。本地不存在，显示默认头像
def.method().UpdateCustomImg = function(self)
    if not IsNil(self._Panel) then
        local hp = game._HostPlayer
        -- if hp._InfoData._CustomPicturePath == "" then
            -- if hp._InfoData._Gender == EnumDef.Gender.Female then
            --     GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.FemaleIconAtlasPath)
            -- else
            --     GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.MaleIconAtlasPath)
            -- end
        -- elseif hp._InfoData._CustomPicturePath ~= "" then	--获取自定义头像

        --     warn("lidaming --- > CPanelSetHead hp._InfoData._CustomPicturePath == ", hp._InfoData._CustomPicturePath)
        --     GUITools.SetHeadIconfromImageFile(self._ImgHead, hp._InfoData._CustomPicturePath)
        -- end
        warn("lidaming --- > CPanelSetHead hp._InfoData._CustomImgSet == ", hp._InfoData._CustomImgSet)
        if hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Defualt	--默认职业头像
        or hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Banned   -- 被ban
		or hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Failed then	--审核失败
            if hp._InfoData._Gender == EnumDef.Gender.Female then
                GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.FemaleIconAtlasPath)
            else
                GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.MaleIconAtlasPath)
            end
        elseif hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Success  --获取自定义头像
            or hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Review then	--审核中
            -- warn("lidaming : Review or HaveSet!!!")
            

            game:SetEntityCustomImg(self._ImgHead,hp._ID,hp._InfoData._CustomImgSet,hp._InfoData._Gender,hp._InfoData._Prof)
			-- --获取自定义头像
			-- local entityImgPath = ""
            -- -- GUITools.SetHeadIconfromImageFile(imgObj, entityImgPath)			

            -- -- error: 1、参数不匹配 2、没有用户 3、审核中 4、审核未通过 5、文件不存在 6、md5一致 7、被Ban
            -- local callback = function(strFileName ,retCode, error)	
            --     if retCode == 0 or retCode == 6 then
            --         entityImgPath = GameUtil.GetCustomPicDir().."/"..hp._ID
            --     else
            --         entityImgPath = ""
            --     end		
            --     if entityImgPath == "" then
            --         if hp._InfoData._Gender == EnumDef.Gender.Female then
            --             GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.FemaleIconAtlasPath)
            --         else
            --             GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.MaleIconAtlasPath)
            --         end
            --     else
            --         GUITools.SetHeadIconfromImageFile(self._ImgHead, entityImgPath)	
            --     end		
            -- end
            -- GameUtil.DownloadPicture(tostring(hp._ID), callback)			
		end
	end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Reset' then
        -- local iconPath = "Assets/Outputs/Interfaces/Image/Img_Logo.jpg"   --Assets\Outputs\Interfaces\Image Img_Logo
        --默认头像        
        local callback = function(val)
            if val then                                                     
                local hp = game._HostPlayer
                if hp._InfoData._CustomImgSet == ECustomSet.ECustomSet_Defualt then
                    game._GUIMan:ShowTipText(StringTable.Get(15052),false)
                    return
                end
                if hp ~= nil then
                    if hp._InfoData._Gender == EnumDef.Gender.Female then
                        GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.FemaleIconAtlasPath)
                    else
                        GUITools.SetHeadIcon(self._ImgHead, hp._ProfessionTemplate.MaleIconAtlasPath)
                    end
                end
                local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
                local msg = C2SCustomImgSet()
                msg.CustomImgSet = ECustomSet.ECustomSet_Defualt
                PBHelper.Send(msg)
                -- hp:SetCustomImg(ECustomSet.ECustomSet_Defualt)                           
            end
        end
        -- 恢复默认头像需要msgBox二次确认
        local title, msg, closeType = StringTable.GetMsg(28)
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
           
    elseif id == 'Btn_Back' then
        -- warn(" On Panel Close Head sprite name:", self._ImgHead.name)
        -- GUITools.DebugSpriteName(self._ImgHead)
        game._GUIMan:Close("CPanelSetHead")
    elseif id == 'Btn_Set' then
        --选择自定义头像        
        if GameUtil.HasPhotoPermission() then
            GameUtil.OpenPhoto()        
        else
            GameUtil.RequestPhotoPermission()
            if GameUtil.HasPhotoPermission() then
                GameUtil.OpenPhoto()        
            end
        end
    elseif id == "Btn_Photograph" then
        --选择打开相机拍照
        if GameUtil.HasCameraPermission() then
            GameUtil.OpenCamera()
        else
            GameUtil.RequestCameraPermission()
            if GameUtil.HasCameraPermission() then
                GameUtil.OpenCamera()
            end
        end
    end
end

def.method('string').SetIconPathFromFile = function(self, filepath)
    Currentfilepath = filepath
    warn("Currentfilepath == ", filepath)
    GUITools.SetHeadIconfromImageFile(self._ImgHead, Currentfilepath)
    local hp = game._HostPlayer
    if Currentfilepath == nil then return end 
    local callback = function(loadPicture , error , success)
        warn("loadPicture == ", loadPicture, "error == ", error)
        if success == true then
            -- local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
            -- local msg = C2SCustomImgSet()
            -- msg.CustomImgSet = ECustomSet.ECustomSet_Review
            -- -- warn("msg.CustomImgSet == ", msg.CustomImgSet)
            -- PBHelper.Send(msg)
            -- hp:SetCustomImg(ECustomSet.ECustomSet_Review)
            -- GUITools.SetHeadIconfromImageFile(self._ImgHead, loadPicture)	
            game._GUIMan:ShowTipText(StringTable.Get(15051),false)
        else
            game._GUIMan:ShowTipText(StringTable.Get(15050),false)
        end
    end
    GameUtil.UploadPicture(Currentfilepath, tostring(hp._ID), callback)     
end

CPanelSetHead.Commit()
return CPanelSetHead