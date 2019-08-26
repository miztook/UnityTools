@SET SELF_PATH=%~dp0
@cd %SELF_PATH%

Xcopy ".\Plugins\x86\hoba.dll" "..\..\UnityProject\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.dll" "..\..\UnityProject\Assets\Plugins\x86_64\"  /R /Y /Q
Xcopy ".\Plugins\x86\hoba.pdb" "..\..\UnityProject\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.pdb" "..\..\UnityProject\Assets\Plugins\x86_64\"  /R /Y /Q

@REM Xcopy ".\Plugins\Android\armeabi\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\armeabi\"  /R /Y /Q
Xcopy ".\Plugins\Android\armeabi-v7a\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\armeabi-v7a\"  /R /Y /Q
Xcopy ".\Plugins\Android\x86\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\x86\"  /R /Y /Q
Xcopy ".\Plugins\Android\arm64-v8a\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\arm64-v8a\"  /R /Y /Q

@REM Xcopy ".\dependency\libcurl\Android\armeabi-v7a\*.a" "..\..\UnityProject\Assets\Plugins\Android\libs\armeabi-v7a\"  /R /Y /Q
@REM Xcopy ".\dependency\libcurl\Android\arm64-v8a\*.a" "..\..\UnityProject\Assets\Plugins\Android\libs\arm64-v8a\"  /R /Y /Q

Xcopy ".\dependency\libcurl\iOS\universal\*.a" "..\..\UnityProject\Assets\Plugins\iOS\"  /R /Y /Q

@pause