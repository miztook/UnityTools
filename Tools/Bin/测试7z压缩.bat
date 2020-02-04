SET SELF_PATH=%~dp0

SET FileDirToCompress=%SELF_PATH%AssetBundles
SET FileDirCompressed=%SELF_PATH%Compress
SET FileDirUncompressed=%SELF_PATH%Uncompressed
SET Options="-t7z -mx0 -mtm=off -mtr=off"
SET Recompress=1
SET ReportFile=Report-LZMA2.csv

%SELF_PATH%../HobaPackToolsCommand/x64/Debug/Test7z.exe %FileDirToCompress% %FileDirCompressed% %FileDirUncompressed% %Options% %Recompress% %ReportFile%

pause