SET SELF_PATH=%~dp0

SET BaseVersion=8.14.0
SET NextVersion=8.14.1
SET JupDir=%SELF_PATH%JupGenerate

cd %SELF_PATH%../HobaPackToolsCommand/x64/Debug

HobaPackToolsCommand.exe %BaseVersion% %NextVersion%  %JupDir%

pause