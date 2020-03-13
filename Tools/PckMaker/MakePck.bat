@echo off

set GameResDir=%1%
set OutputDir=%2%

SET SELF_PATH=%~dp0
SET TMP_PATH=%SELF_PATH%tmp

echo "prepare pck..."

cd %GameResDir%
%SELF_PATH%\ElementUIPck.exe %TMP_PATH% %OutputDir% 1

rd /s /q %TMP_PATH%

echo "MakePck Success!"

