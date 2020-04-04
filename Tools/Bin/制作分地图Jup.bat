SET SELF_PATH=%~dp0

SET Platform=Windows
SET BaseVersion=0.0.0.0
SET BasePath=%SELF_PATH%../../GameRes
SET JupDir=%SELF_PATH%MapJupGenerate

cd %SELF_PATH%../HobaPackToolsCommand/x64/Debug

MapPackTools.exe %Platform% %BaseVersion% %BasePath%  %JupDir%

pause