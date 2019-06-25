#include "CLplusChecker.h"
#include "function.h"
#include "stringext.h"

std::string g_BuiltInTypes[] =
{
	"table",
	"FUNCTION",
	"dynamic",
	"number",
	"boolean",
	"userdata",
	"string",
	"function",
	"Object",
};

std::string g_ValidDefine[] =
{
	"field",
	"method",
	"virtual",
	"override",
	"static",
	"final",
	"const",
};

std::string g_ErrorToken[] =
{
	"PB.Data",
	"PB.Net",
};

std::tuple<std::string, int> g_MethodParams[] =
{
	{ "Get", 0 },
	{ "Play", 0 },
	{ "Tick", 2 },
	{ "ChangeState", 4 },
	{ "ConnectToServer", 4 },
	{ "OnS2CKeyExchange", 2 },
	{ "PlayAnimation", 6 },
	{ "Open", 1 },
	{ "SetCount", 1 },
	{ "SetLookAtParam", 2 },
	{ "SelectItem", 1 },
	{ "SelectItem", 2 },
	{ "PlaySequence", 2 },
	{ "Restart", 1 },
	{ "AddEvt_PlayFx", 8 },
};

std::tuple<std::string, int> g_StaticMethodParams[] =
{
	{ "New", 1 },
	{ "New", 2 },
	{ "New", 3 },
	{ "New", 4 },
	{ "AddGlobalTimer", 3 },
	{ "AddObjectComponent", 5 },
	{ "GetHangPoint", 2 },
	{ "OnTemplateLanguageChanged", 0 },
	{ "SetRealTimeShadowLevel", 1 },
};

std::tuple<std::string, std::vector<int>> g_SpecialMethodParams[] =
{
	{ "CGMan.PlayCG", { 4 } },
	{ "CGMan.StopCG", { 0 } },

	{ "GUI.SetText",{ 2 } },
	{ "GUI.SetGroupToggleOn",{ 2 } },
	{ "GUI.SetArtFontText",{ 2 } },
	{ "GUI.SetTextAndChangeLayout",{ 3 } },
	{ "GUI.SetImageAndChangeLayout",{ 3 } },
	{ "GUI.SetTextColor",{ 2 } },
	{ "GUI.SetAlpha",{ 2 } },
	{ "GUI.GetChildFromTemplate",{ 2 } },
	{ "GUI.SetDropDownOption",{ 2 } },
	{ "GUI.SetDropDownOption2",{ 3 } },
	{ "GUI.SetTextAlignment",{ 2 } },
	{ "GUI.SetRectTransformStretch",{ 1 } },

	{ "TimerUtil.AddTimer",{ 4, 5 } },
	{ "TimerUtil.AddGlobalTimer",{ 3, 4 } },
	{ "TimerUtil.AddGlobalLateTimer",{ 3, 4 } },
	{ "TimerUtil.RemoveTimer",{ 2 } },
	{ "TimerUtil.RemoveGlobalTimer",{ 1 } },
	{ "TimerUtil.ResetTimer",{ 2 } },
	{ "TimerUtil.ResetGlobalTimer",{ 1 } },

	//GameUtil_Camera
	{ "GameUtil.SetCameraParams",{ 1, 4, 5, 6 } },
	{ "GameUtil.SetCameraParamsEX",{ 4 } },
	{ "GameUtil.SetGameCamHeightOffsetInterval",{ 3 } },
	{ "GameUtil.SetGameCamOwnDestDistOffset",{ 2 } },
	{ "GameUtil.SetGameCamDefaultDestDistOffset",{ 1 } },
	{ "GameUtil.SetGameCamDestDistOffset",{ 2 } },
	{ "GameUtil.SetDestDistOffsetAndDestPitchDeg",{ 4 } },
	{ "GameUtil.SetSkillActCamMode",{ 6 } },
	{ "GameUtil.SetGameCamCtrlParams",{ 2 } },
	{ "GameUtil.GetGameCamCurDistOffset",{ 0 } },
	{ "GameUtil.SetGameCamCtrlParams",{ 2 } },
	{ "GameUtil.AddOrSubForTest",{ 2 } },
	{ "GameUtil.SetExteriorDebugParams",{ 4 } },
	{ "GameUtil.SetExteriorCamHeightOffset",{ 1 } },
	{ "GameUtil.SetGameCamCtrlMode",{ 5 } },
	{ "GameUtil.SetTransToPortal",{ 1 } },
	{ "GameUtil.SetProDefaultSpeed",{ 1 } },
	{ "GameUtil.SetCamToDefault",{ 4 } },
	{ "GameUtil.QuickRecoverCamToDest",{ 2 } },
	{ "GameUtil.SetCamLockState",{ 1, 2 } },
	{ "GameUtil.SetCameraGreyOrNot",{ 1 } },
	{ "GameUtil.OpenUIWithEffect",{ 1 } },
	{ "GameUtil.CameraLookAtNpc",{ 1 } },
	{ "GameUtil.SetGameCam2DHeightOffset",{ 1 } },
	{ "GameUtil.ReadNearCameraProfConfig",{ 1 } },
	{ "GameUtil.SetNearCamProfCfg",{ 1 } },
	{ "GameUtil.SetNearCamRollSensitivity",{ 1 } },
	{ "GameUtil.EnableNearCamLookIK",{ 1 } },
	{ "GameUtil.GetGameCamDirXZ",{ 0 } },
	{ "GameUtil.StartBossCamMove",{ 1 } },

	//GameUtil.Common
	{ "GameUtil.FindChild",{ 2 } },
	{ "GameUtil.SetCurLayerVisible",{ 2 } },
	{ "GameUtil.SetLayerRecursively",{ 2 } },
	{ "GameUtil.GetMapHeight",{ 1 } },
	{ "GameUtil.GetModelHeight",{ 1, 2 } },
	{ "GameUtil.IsBlockedByObstacle",{ 2 } },
	{ "GameUtil.IsValidPosition",{ 1 } },
	{ "GameUtil.GetNearestValidPosition",{ 2 } },
	{ "GameUtil.IsValidPositionXZ",{ 2 } },
	{ "GameUtil.GenHmacMd5",{ 4 } },
	{ "GameUtil.MD5ComputeHash",{ 1 } },
	{ "GameUtil.HMACMD5ComputeHash",{ 2 } },
	{ "GameUtil.ComputeRNGCryptoNonce",{ 1 } },
	{ "GameUtil.EnableRotate",{ 1, 2 } },
	{ "GameUtil.DoMove",{ 6 } },
	{ "GameUtil.DoLocalMove",{ 5 } },
	{ "GameUtil.DoLocalRotateQuaternion",{ 5 } },
	{ "GameUtil.DoLoopRotate",{ 3 } },
	{ "GameUtil.DoScale",{ 5 } },
	{ "GameUtil.DoAlpha",{ 4 } },
	{ "GameUtil.DoKill",{ 1 } },
	{ "GameUtil.ChangeSceneWeather",{ 1 } },
	{ "GameUtil.ChangeSceneWeatherByMemory",{ 1 } },
	{ "GameUtil.OnHostPlayerPosChange",{ 2 } },
	{ "GameUtil.GetStringLength",{ 1 } },
	{ "GameUtil.SetStringLength",{ 2 } },
	{ "GameUtil.DoScaleFrom",{ 5 } },
	{ "GameUtil.IsGameObjectInCamera",{ 2 } },
	{ "GameUtil.SubUnicodeString",{ 2, 3 } },
	{ "GameUtil.GetUnicodeStrLength",{ 1 } },
	{ "GameUtil.CheckName_ContainMainWord",{ 1 } },
	{ "GameUtil.CheckName_IsValidWord",{ 1 } },
	{ "GameUtil.GetScenePath",{ 1 } },
	{ "GameUtil.ShowAlertView",{ 2 } },
	{ "GameUtil.RegisterLocalNotificationMessage",{ 5 } },

	//GameUtil.Debug

	//GameUtil.Effect
	{ "GameUtil.AddCameraOrScreenEffect",{ 5, 7, 9 } },
	{ "GameUtil.StopSkillScreenEffect",{ 1, 2, 3 } },
	{ "GameUtil.EnableSpecialVisionEffect",{ 1 } },
	{ "GameUtil.StartScreenFade",{ 3 } },
	{ "GameUtil.ClearScreenFadeEffect",{ 0 } },
	{ "GameUtil.SetSceneEffect",{ 1 } },
	{ "GameUtil.CaptureScreen",{ 0 } },
	{ "GameUtil.SaveScreenShot",{ 0 } },
	{ "GameUtil.AbandonScreenShot",{ 0 } },

	//GameUtil.Entity
	{ "GameUtil.AddObjectComponent",{ 5 } },
	{ "GameUtil.ChangeAttach",{ 3 } },
	{ "GameUtil.ChangePartMesMakeBtnBgGrayh",{ 3 } },
	{ "GameUtil.GetHangPoint",{ 2 } },
	{ "GameUtil.ResizeCollider",{ 4 } },
	{ "GameUtil.DisableCollider",{ 1 } },
	{ "GameUtil.RotateByAngle",{ 2 } },
	{ "GameUtil.AddObjectEffect",{ 2,3,6,7,8 } },
	{ "GameUtil.EnableHostPosSyncWhenMove",{ 1 } },
	{ "GameUtil.AddMoveBehavior",{ 5,6,8,9 } },
	{ "GameUtil.SetMoveBehaviorSpeed",{ 2 } },
	{ "GameUtil.AddJoyStickMoveBehavior",{ 3 } },
	{ "GameUtil.AddFollowBehavior",{ 7 } },
	{ "GameUtil.AddTurnBehavior",{ 6 } },
	{ "GameUtil.AddDashBehavior",{ 5,7 } },
	{ "GameUtil.AddAdsorbBehavior",{ 4 } },
	{ "GameUtil.RemoveBehavior",{ 2 } },
	{ "GameUtil.HasBehavior",{ 2 } },
	{ "GameUtil.ChangeOutward",{ 3,4 } },
	{ "GameUtil.ChangeHairColor",{ 4 } },
	{ "GameUtil.ChangeSkinColor",{ 4 } },
	{ "GameUtil.EnableGroundNormal",{ 2 } },
	{ "GameUtil.SetGameObjectYOffset",{ 2 } },
	{ "GameUtil.EnablePhysicsCollision",{ 3 } },
	{ "GameUtil.OnEntityModelChanged",{ 1 } },
	{ "GameUtil.ChangeDressColor",{ 4,5 } },
	{ "GameUtil.ChangeDressEmbroidery",{ 2 } },
	{ "GameUtil.EnableLockWingYZRotation",{ 3 } },
	{ "GameUtil.EnableAnimationBulletTime",{ 3 } },
	{ "GameUtil.SetEntityColliderRadius",{ 2 } },
	{ "GameUtil.EnableDressUnderSfx",{ 2 } },
	{ "GameUtil.EnableOutwardPart",{ 3 } },

	//GameUtil.Logic
	{ "GameUtil.AddFootStepTouch",{ 1 } },
	{ "GameUtil.RemoveFootStepTouch",{ 1 } },
	{ "GameUtil.PlayBackgroundMusic",{ 1, 2 } },
	{ "GameUtil.PlayEnvironmentMusic",{ 1, 2 } },
	{ "GameUtil.Play3DAudio",{ 3 } },
	{ "GameUtil.PlayAttached3DAudio",{ 3 } },
	{ "GameUtil.Stop3DAudio",{ 2 } },
	{ "GameUtil.Stop2DAudio",{ 2 } },
	{ "GameUtil.Play3DVoice",{ 3 } },
	{ "GameUtil.Play3DShout",{ 3 } },
	{ "GameUtil.Play2DAudio",{ 2 } },
	{ "GameUtil.Play2DHeartBeat",{ 2 } },
	{ "GameUtil.EnableBackgroundMusic",{ 1 } },
	{ "GameUtil.SetSoundBGMVolume",{ 2 } },
	{ "GameUtil.SetBGMSysVolume",{ 1 } },
	{ "GameUtil.SetSoundLanguage",{ 1 } },
	{ "GameUtil.SetSoundEffectVolume",{ 1 } },
	{ "GameUtil.SetEffectSysVolume",{ 1 } },
	{ "GameUtil.SetCutSceneVolume",{ 1 } },
	{ "GameUtil.SetCutSceneSysVolume",{ 1 } },
	{ "GameUtil.EnableEffectAudio",{ 1 } },
	{ "GameUtil.SetHealthVolume",{ 1 } },
	{ "GameUtil.SetPostProcessLevel",{ 1 } },
	{ "GameUtil.SetShadowLevel",{ 1 } },
	{ "GameUtil.SetCharacterLevel",{ 1 } },
	{ "GameUtil.SetSceneDetailLevel",{ 1 } },
	{ "GameUtil.SetFxLevel",{ 1 } },
	{ "GameUtil.EnableDOF",{ 1 } },
	{ "GameUtil.EnableWaterReflection",{ 1 } },
	{ "GameUtil.EnablePostProcessFog",{ 1 } },
	{ "GameUtil.EnableWeatherEffect",{ 1 } },
	{ "GameUtil.EnableDetailFootStepSound",{ 1 } },
	{ "GameUtil.SetFPSLimit",{ 1 } },
	{ "GameUtil.SetSimpleBloomHDParams",{ 2 } },
	{ "GameUtil.EnableLightShadow",{ 2 } },
	{ "GameUtil.EnableBloomHD",{ 2 } },
	{ "GameUtil.FixCameraSetting",{ 1 } },
	{ "GameUtil.EnableCastShadows",{ 2 } },
	{ "GameUtil.SetActiveFxMaxCount",{ 1 } },
	{ "GameUtil.OnHostPlayerCreate",{ 1 } },
	{ "GameUtil.OnWorldLoaded",{ 1 } },
	{ "GameUtil.OnLoadingShow",{ 1 } },
	{ "GameUtil.PlayCG",{ 4 } },
	{ "GameUtil.ReplayCG",{ 1 } },
	{ "GameUtil.GetAllTeamMember",{ 1 } },
	{ "GameUtil.SendProtocol",{ 2 } },
	{ "GameUtil.PlayVideo",{ 2, 4 } },
	{ "GameUtil.SetTemplatePath",{ 3 } },
	{ "GameUtil.SetBaseDataManagerPath",{ 2 } },
	{ "GameUtil.PreloadTemplateData",{ 1 } },
	{ "GameUtil.GetTemplateData",{ 2 } },
	{ "GameUtil.GetAllTid",{ 1 } },
	{ "GameUtil.CanNavigateToXYZ",{ 7, 8, 9 } },
	{ "GameUtil.GetPointInPath",{ 1 } },
	{ "GameUtil.GetAllPointsInNavMesh",{ 5 } },
	{ "GameUtil.GetNavDistOfTwoPoint",{ 2, 4 } },
	{ "GameUtil.IsCollideWithBlockable",{ 2 } },
	{ "GameUtil.PathFindingIsConnected",{ 2 } },
	{ "GameUtil.PathFindingIsConnectedWithPoint",{ 2 } },
	{ "GameUtil.PathFindingCanNavigateTo",{ 2, 3 } },
	{ "GameUtil.PathFindingCanNavigateToXYZ",{ 6, 7 } },
	{ "GameUtil.FindFirstConnectedPoint",{ 2 } },
	{ "GameUtil.EnableBackUICamera",{ 1 } },
	{ "GameUtil.GetChargeDistance",{ 3 } },
	{ "GameUtil.SetLayoutElementPreferredSize",{ 3 } },
	
	//GameUtil.Res
	{ "GameUtil.AsyncLoad",{ 2 } },
	{ "GameUtil.RequestFx",{ 2, 3 } },
	{ "GameUtil.PreloadFxAsset",{ 1 } },
	{ "GameUtil.SetFxScale",{ 2 } },
	{ "GameUtil.SetMineObjectScale",{ 2 } },
	{ "GameUtil.BluntAttachedFxs",{ 3 } },
	{ "GameUtil.RequestUncachedFx",{ 1, 2 } },
	{ "GameUtil.RequestArcFx",{ 3, 4 } },
	{ "GameUtil.LoadSceneBlocks",{ 3 } },
	{ "GameUtil.FetchResFromCache",{ 1 } },
	{ "GameUtil.AddResToCache",{ 2 } },
	{ "GameUtil.RecycleEntityBaseRes",{ 1 } },
	{ "GameUtil.PlayEarlyWarningGfx",{ 6 } },
	{ "GameUtil.StopGfx",{ 2 } },
	{ "GameUtil.ChangeGfxPlaySpeed",{ 2 } },
	{ "GameUtil.SetEmojiSprite",{ 2 } },
	{ "GameUtil.InputEmoji",{ 2 } },

	//GameUtil.System

	{ "GameUtil.WritePersistentConfig",{ 1 } },
	{ "GameUtil.GC",{ 1 } },
	{ "GameUtil.OpenUrl",{ 1 } },
	{ "GameUtil.CopyTextToClipboard",{ 1 } },
	{ "GameUtil.SetServerTimeGap",{ 1 } },
	{ "GameUtil.CopyTextToClipboard",{ 1 } },
	{ "GameUtil.UploadPicture",{ 3 } },
	{ "GameUtil.DownloadPicture",{ 2 } },
	{ "GameUtil.IsCustomPicFileExist",{ 1 } },
	{ "GameUtil.GetUserLanguagePostfix",{ 1 } },
	{ "GameUtil.SetServerOpenTime",{ 2 } },
	{ "GameUtil.ReportUserId",{ 1 } },
	{ "GameUtil.ReportRoleInfo",{ 1 } },

	//GameUtil.UI

	{ "GameUtil.ShakeUIScreen",{ 5 } },
	{ "GameUtil.DoSlider",{ 5 } },
	{ "GameUtil.DoKillSlider",{ 1 } },
	{ "GameUtil.ShowHUDText",{ 3 } },
	{ "GameUtil.SetButtonInteractable",{ 2 } },
	{ "GameUtil.SetImageColor",{ 2 } },
	{ "GameUtil.SetTextColor",{ 2 } },
	{ "GameUtil.GetPanelUIObjectByID",{ 2 } },
	{ "GameUtil.AddCooldownComponent",{ 6 } },
	{ "GameUtil.RemoveCooldownComponent",{ 2 } },
	{ "GameUtil.SetCircleProgress",{ 2 } },
	{ "GameUtil.GetJoystickAxis",{ 1 } },
	{ "GameUtil.ContinueLogoMaskFade",{ 0 } },
	{ "GameUtil.SetSprite",{ 2 } },
	{ "GameUtil.SetSpriteFromResources",{ 2 } },
	{ "GameUtil.CleanSprite",{ 1 } },
	{ "GameUtil.SetItemIcon",{ 2 } },
	{ "GameUtil.SetSpriteFromImageFile",{ 2 } },
	{ "GameUtil.MakeImageGray",{ 2, 3 } },
	{ "GameUtil.ChangeGraphicAlpha",{ 2 } },
	{ "GameUtil.GetMainCameraPosition",{ 1 } },
	{ "GameUtil.IsPlayingUISfx",{ 3 } },
	{ "GameUtil.PlayUISfx",{ 4, 5, 6, 7 } },
	{ "GameUtil.PlayUISfxClipped",{ 4, 8 } },
	{ "GameUtil.StopUISfx",{ 2, 3 } },
	{ "GameUtil.SetUISfxLayer",{ 2 } },
	{ "GameUtil.EnableButton",{ 2 } },
	{ "GameUtil.SetPanelSortingLayerOrder",{ 3 } },
	{ "GameUtil.MovePanelSortingOrder",{ 2 } },
	{ "GameUtil.GetPanelSortingOrder",{ 1 } },
	{ "GameUtil.SetFxSorting",{ 4 } },
	{ "GameUtil.Num2SortingLayerID",{ 1 } },
	{ "GameUtil.HidePanel",{ 2 } },
	{ "GameUtil.SetRenderTexture",{ 3 } },
	{ "GameUtil.SetGroupImg",{ 2 } },
	{ "GameUtil.SetBtnExpress",{ 2 } },
	{ "GameUtil.SetNativeSize",{ 1 } },
	{ "GameUtil.SetMaskTrs",{ 4 } },
	{ "GameUtil.RegisterUIEventHandler",{ 3, 4 } },
	{ "GameUtil.GetScreenPosToTargetPos",{ 1 } },
	{ "GameUtil.ChangeGradientBtmColor",{ 2 } },
	{ "GameUtil.PlaySequenceFrame",{ 2 } },
	{ "GameUtil.StopSequenceFrame",{ 1 } },
	{ "GameUtil.AdjustDropdownRect",{ 2 } },
	{ "GameUtil.SetDropdownValue",{ 2 } },
	{ "GameUtil.SetTipsPosition",{ 2 } },
	{ "GameUtil.SetApproachPanelPosition",{ 2 } },
	{ "GameUtil.SetGiftItemPosition",{ 2 } },
	{ "GameUtil.GetTipLayoutHeight",{ 1 } },
	{ "GameUtil.SetOutlineColor",{ 2 } },
	{ "GameUtil.SetActiveOutline",{ 2 } },
	{ "GameUtil.GetPreferredHeight",{ 1 } },
	{ "GameUtil.SetTextAlignment",{ 2 } },
	{ "GameUtil.OpenOrCloseLoginLogo",{ 1 } },
	{ "GameUtil.SetUIAllowDrag",{ 1 } },
	{ "GameUtil.AlignUiElementWithOther",{ 4 } },
	{ "GameUtil.WorldPositionToCanvas",{ 1 } },
	{ "GameUtil.SetupWorldCanvas",{ 1, 2 } },
	{ "GameUtil.SetScrollPositionZero",{ 1 } },
	{ "GameUtil.SetScrollEnabled",{ 2 } },
	{ "GameUtil.SetupUISorting",{ 3 } },
	{ "GameUtil.SetAllTogglesOff",{ 1 } },
	{ "GameUtil.GetRootCanvasPosAndSize",{ 1 } },
	{ "GameUtil.RegisterTip",{ 1 } },
	{ "GameUtil.UnregisterTip",{ 1 } },
	{ "GameUtil.GetCurrentVersion",{ 0 } },
	{ "GameUtil.EnableBlockCanvas",{ 1 } },
	{ "GameUtil.ShowScreenShot",{ 1 } },
	{ "GameUtil.EnableReversedRaycast",{ 1 } },
	{ "GameUtil.SetCanvasGroupAlpha",{ 2 } },
	{ "GameUtil.SetIgnoreLayout",{ 2 } },
	{ "GameUtil.ShowScreenShot",{ 1 } },
};

std::tuple<std::string, std::string> g_szClassInvalidToken[] =
{
	{ "game.",	"CGame" },
	{ "game._AccountInfo",	"CAccountInfo" },
	{ "game._CurWorld",	"CWorld" },
	{ "game._GUIMan",		"CUIMan" },
	{ "game._NetMan",	"CNetwork" },
	{ "game._GuildMan",	"CGuildMan" },
	{ "game._DungeonMan",	"CDungeonMan" },
	{ "game._AcheivementMan",	"AchievementMan" },
	{ "game._DesignationMan",	"DesignationMan" },
	{ "game._CWorldBossMan",	"CWorldBossMan" },
	{ "game._CFunctionMan",	"CFunctionMan" },
	{ "game._CGuideMan",	"CGuideMan" },
	{ "game._CManualMan",	"CManualMan" },
	{ "game._CReputationMan",	"CReputationMan" },
	{ "game._CAuctionUtil",	"CAuctionUtil" },
	{ "game._AdventureGuideMan",	"AdventureGuideMan" },
	{ "game._CamLockTarget",	"CEntity" },
	{ "game._RegionLimit",	"CRegionLimit" },
	{ "game._HostPlayer",		"CHostPlayer" },
};

std::tuple<std::string, std::string> g_GlobalClass[] =
{
	{ "game.EventManager", "CEventManager" },
	{ "game._AccountInfo", "CAccountInfo" },
	{ "game._CurWorld", "CWorld" },
	{ "game._GUIMan", "CUIMan" },
	{ "game._NetMan", "CNetwork" },
	{ "game._GuildMan", "CGuildMan" },
	{ "game._DungeonMan", "CDungeonMan" },
	{ "game._AcheivementMan", "AchievementMan" },
	{ "game._DesignationMan", "DesignationMan" },
	{ "game._CWorldBossMan", "CWorldBossMan" },
	{ "game._CFunctionMan", "CFunctionMan" },
	{ "game._CGuideMan", "CGuideMan" },
	{ "game._CGameTipsQ", "CGameTipsQueue" },
	{ "game._CManualMan", "CManualMan" },
	{ "game._CFriendMan", "CFriendMan" },
	{ "game._CArenaMan", "CArenaMan" },
	{ "game._CDecomposeAndSortMan", "CDecomposeAndSortMan" },
	{ "game._CReputationMan", "CReputationMan" },
	{ "game._CAuctionUtil", "CAuctionUtil" },
	{ "game._AdventureGuideMan", "AdventureGuideMan" },
	{ "game._PlayerStrongMan", "CPlayerStrongMan" },
	{ "game._CCalendarMan", "CCalendarMan" },
	{ "game._CWelfareMan", "CWelfareMan" },
	{ "game._CamLockTarget", "CEntity" },
	{ "game._RegionLimit", "CRegionLimit" },

	{ "game._CurWorld._PlayerMan", "CPlayerMan" },
	{ "game._CurWorld._NPCMan", "CNPCMan" },
	{ "game._CurWorld._SubobjectMan", "CSubobjectMan" },
	{ "game._CurWorld._DynObjectMan", "CObstacleMan" },
	{ "game._CurWorld._LootObjectMan", "CLootMan" },
	{ "game._CurWorld._MineObjectMan", "CMineMan" },
	{ "game._CurWorld._PetMan", "CPetMan" },
	{ "game._GUIMan._UIManCore", "CUIManCore" },
	{ "game._CGuideMan._CurGuideTrigger", "Guide" },

	{ "CFxMan.Instance()", "CFxMan" },
	{ "CQuest.Instance()", "CQuest" },
	//{ "CTeamMan.Instance()", "CTeamMan" },
};


std::tuple<std::string, int> g_SpecialMethodReturns[] =
{
	{ ":GetPosXYZ(", 3 },
	{ ":GetPosXZ(", 2 },
	{ ":GetDirXYZ(", 3 },
	{ ":GetDirXZ(", 2 },
	{ ":PositionXYZ(", 3 },
	{ ":PositionXZ(", 2 },
	{ ":ForwardXYZ(", 3 },
	{ ":ForwardXZ(", 2 },
	{ "GetNearPortalAndAssociatedPosByMap(", 2 },
	{ "CheckDiamond(", 2},
};

void CLplusChecker::InitData()
{
	for (const auto& e : g_szClassInvalidToken)
	{
		m_ClassInvalidTokenMap[std::get<1>(e)] = std::get<0>(e);
	}

	for (const auto& e : g_BuiltInTypes)
	{
		m_BuiltInTypeList.push_back(e);
	}

	for (const auto& e : g_ValidDefine)
	{
		m_ValidDefineList.push_back(e);
	}

	for (const auto& e : g_ErrorToken)
	{
		m_errorTokens.push_back(e);
	}

	for (const auto& e : g_SpecialMethodParams)
	{
		const auto& key = std::get<0>(e);
		const auto& val = std::get<1>(e);
		m_SpecialMethodParamMap[key] = val;
	}

	for (const auto& e : g_GlobalClass)
	{
		m_GlobalClassList.push_back(e);
	}

	for (const auto& e : g_MethodParams)
	{
		m_MethodParamList.push_back(e);
	}

	for (const auto& e : g_StaticMethodParams)
	{
		m_StaticMethodParamList.push_back(e);
	}

	for (const auto& e : g_szClassInvalidToken)
	{
		m_ClassInvalidTokenList.push_back(e);
	}

	for (const auto& e : g_SpecialMethodReturns)
	{
		m_SpecialMethodReturnList.push_back(e);
	}
}