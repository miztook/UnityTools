SET SELF_PATH=%~dp0

SET JupDir=%SELF_PATH%JupGenerate
SET OutDir=%SELF_PATH%Unpack

cd %SELF_PATH%../HobaPackToolsCommand/x64/Debug

JupUnpackToDir.exe %JupDir% %OutDir%

pause