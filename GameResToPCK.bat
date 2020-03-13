set CUR_DIR=%~dp0
cd %CUR_DIR%

echo "Removing... [package]"
rd /s /q ".\BasePck\package"

call ".\Tools\PckMaker\MakePck.bat" "%CUR_DIR%GameRes" "%CUR_DIR%BasePck"
echo "BasePck make Finished..."