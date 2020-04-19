SET SELF_PATH=%~dp0

SET StartVer=1.0.1.32
SET EndVer=1.0.1.33
SET JupDir=./JupGenerate
SET OutDir=./OBB
SET VersionCode=10000010
SET PackageName=com.kakaogames.tera

%SELF_PATH%../HobaPackToolsCommand/x64/Debug/OBBPacker.exe %StartVer% %EndVer% %JupDir% %OutDir% %VersionCode% %PackageName%

pause