SET SELF_PATH=%~dp0

SET BaseVersion=1.0.1.0
SET NextVersion=1.0.1.1
SET JupDir=%SELF_PATH%JupGenerate

cd %SELF_PATH%../HobaPackToolsCommand/x64/Debug

HobaPackToolsCommand.exe %BaseVersion% %NextVersion%  %JupDir%

pause