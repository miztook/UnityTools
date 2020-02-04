@SET SELF_PATH=%~dp0
@cd %SELF_PATH%

@REM Xcopy ".\Plugins\x86\hoba.dll" "..\..\..\M1Art\M1\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.dll" "..\..\..\M1Art\M1\Assets\Plugins\x86_64\"  /R /Y /Q
@REM Xcopy ".\Plugins\x86\hoba.pdb" "..\..\..\M1Art\M1\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.pdb" "..\..\..\M1Art\M1\Assets\Plugins\x86_64\"  /R /Y /Q

Xcopy ".\Plugins\Android\armeabi\libhoba.so" "..\..\..\M1Art\M1\Assets\Plugins\Android\libs\armeabi\"  /R /Y /Q
Xcopy ".\Plugins\Android\armeabi-v7a\libhoba.so" "..\..\..\M1Art\M1\Assets\Plugins\Android\libs\armeabi-v7a\"  /R /Y /Q
Xcopy ".\Plugins\Android\x86\libhoba.so" "..\..\..\M1Art\M1\Assets\Plugins\Android\libs\x86\"  /R /Y /Q
@REM Xcopy ".\Plugins\Android\arm64-v8a\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\arm64-v8a\"  /R /Y /Q

@REM Xcopy ".\Plugins\x86\hoba.dll" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.dll" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\x86_64\"  /R /Y /Q
@REM Xcopy ".\Plugins\x86\hoba.pdb" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\x86\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.pdb" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\x86_64\"  /R /Y /Q

Xcopy ".\Plugins\Android\armeabi\libhoba.so" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\Android\libs\armeabi\"  /R /Y /Q
Xcopy ".\Plugins\Android\armeabi-v7a\libhoba.so" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\Android\libs\armeabi-v7a\"  /R /Y /Q
Xcopy ".\Plugins\Android\x86\libhoba.so" "..\..\..\M1Res4Build\TERAMobile\Assets\Plugins\Android\libs\x86\"  /R /Y /Q
@REM Xcopy ".\Plugins\Android\arm64-v8a\libhoba.so" "..\..\UnityProject\Assets\Plugins\Android\libs\arm64-v8a\"  /R /Y /Q

@pause