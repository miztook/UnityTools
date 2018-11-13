@SET SELF_PATH=%~dp0
@cd %SELF_PATH%

Xcopy ".\AppLauncher\assets\GCloudVoice\config.json" "..\..\UnityProject\Assets\Plugins\Android\assets\GCloudVoice\" /Y /Q
Xcopy ".\AppLauncher\bin\applauncher.jar" "..\..\UnityProject\Assets\Plugins\Android\libs\" /Y /Q
rem Xcopy ".\AppLauncher\libs\armeabi\libGCloudVoice.so" "..\..\UnityProject\Assets\Plugins\Android\libs\armeabi\" /Y /Q
Xcopy ".\AppLauncher\libs\armeabi-v7a\libGCloudVoice.so" "..\..\UnityProject\Assets\Plugins\Android\libs\armeabi-v7a\" /Y /Q
Xcopy ".\AppLauncher\libs\x86\libGCloudVoice.so" "..\..\UnityProject\Assets\Plugins\Android\libs\x86\" /Y /Q
Xcopy ".\AppLauncher\libs\GCloudVoice.jar" "..\..\UnityProject\Assets\Plugins\Android\libs\" /Y /Q
Xcopy ".\AppLauncher\libs\android-support-v4.jar" "..\..\UnityProject\Assets\Plugins\Android\libs\" /Y /Q

Xcopy ".\AppLauncher\AndroidManifest.xml" "..\..\SDK\Kakao\AndroidManifest_NoKakao\" /Y /Q

@pause