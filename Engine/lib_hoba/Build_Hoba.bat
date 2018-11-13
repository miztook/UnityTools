set CWD=%~dp0
MSBuild "%CWD%\win_build\libhoba.sln" /p:ContinueOnError="ErrorAndStop" /p:Configuration=Release /p:Platform=x64
MSBuild "%CWD%\win_build\libhoba.sln" /p:ContinueOnError="ErrorAndStop" /p:Configuration=Release /p:Platform=Win32