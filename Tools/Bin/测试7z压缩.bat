SET SELF_PATH=%~dp0

SET FileDirToCompress=%SELF_PATH%AssetBundles
SET FileDirCompressed=%SELF_PATH%Compress_LZMA2
SET FileDirUncompressed=%SELF_PATH%Uncompressed
SET Options="-t7z -m0=LZMA2 -mx=5 -myx=0 -mtm=off -mtr=off"
SET Recompress=1
SET ReportFile=Report-LZMA2.csv

%SELF_PATH%../HobaPackToolsCommand/x64/Debug/Test7z.exe %FileDirToCompress% %FileDirCompressed% %FileDirUncompressed% %Options% %Recompress% %ReportFile%

pause