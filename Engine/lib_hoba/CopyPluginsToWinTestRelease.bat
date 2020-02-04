@SET SELF_PATH=%~dp0
@cd %SELF_PATH%

Xcopy ".\Plugins\x86\hoba.dll" ".\win_test\Win32\Release\" /R /Y /Q
Xcopy ".\Plugins\x86_64\hoba.dll" ".\win_test\x64\Release\"  /R /Y /Q

@pause