set CUR_DIR=%~dp0
cd %CUR_DIR%
cd .\openssl-1.1.0c
perl Configure VC-WIN64A  shared no-asm no-shared --prefix="%CUR_DIR%win64-release" --openssldir="%CUR_DIR%win64-release/ssl"
nmake
nmake test
nmake install
nmake clean
