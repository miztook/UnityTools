SET SELF_PATH=%~dp0

SET StartVer=1.100.7.0
SET EndVer=1.100.7.32
SET JupDir=./JupGenerate
SET OutDir=./OBB
SET VersionCode=11000071
SET PackageName=com.kakaogames.tera

%SELF_PATH%../HobaPackToolsCommand/x64/Debug/OBBPacker.exe %StartVer% %EndVer% %JupDir% %OutDir% %VersionCode% %PackageName%

pause