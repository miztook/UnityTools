set CWD=%~dp0
MSBuild "%CWD%\win_build\libhoba.sln" /t:Rebuild /p:ContinueOnError="ErrorAndStop" /p:Configuration=Debug /p:Platform=x64
MSBuild "%CWD%\win_build\libhoba.sln" /t:Rebuild /p:ContinueOnError="ErrorAndStop" /p:Configuration=Debug /p:Platform=Win32