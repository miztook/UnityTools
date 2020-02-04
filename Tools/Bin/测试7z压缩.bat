SET SELF_PATH=%~dp0

SET FileDirToCompress=%SELF_PATH%Unpack
SET FileDirCompressed=%SELF_PATH%Compress
SET FileDirUncompressed=%SELF_PATH%Uncompressed
SET Options="-mx0"
SET Recompress=1
SET ReportFile=Report-mx0.csv

%SELF_PATH%../HobaPackToolsCommand/x64/Debug/Test7z.exe %FileDirToCompress% %FileDirCompressed% %FileDirUncompressed% %Options% %Recompress% %ReportFile%

pause