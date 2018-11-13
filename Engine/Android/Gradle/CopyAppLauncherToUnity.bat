@SET SELF_PATH=%~dp0
@cd %SELF_PATH%

Xcopy ".\bin\applauncher.aar" "..\..\..\UnityProject\Assets\Plugins\Android\libs\" /Y /Q

Xcopy ".\AppLauncher\src\main\AndroidManifest.xml" "..\..\..\SDK\Kakao\AndroidManifest_NoKakao\" /Y /Q

@pause