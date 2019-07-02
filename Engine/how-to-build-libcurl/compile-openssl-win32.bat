set CUR_DIR=%~dp0
cd %CUR_DIR%
cd .\openssl-1.1.0c
perl Configure VC-WIN32  shared no-asm no-shared --prefix="%CUR_DIR%win32-release" --openssldir="%CUR_DIR%win32-release/ssl"
nmake
nmake test
nmake install
nmake clean
