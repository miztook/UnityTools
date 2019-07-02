set CUR_DIR=%~dp0
cd %CUR_DIR%
cd .\curl-curl-7_51_0\winbuild
nmake /f Makefile.vc mode=static VC=14 MACHINE=x64 WITH_SSL=static DEBUG=no ENABLE_SSPI=no ENABLE_IDN=no ENABLE_WINSSL=no WITH_DEVEL=../../deps64 RTLIBCFG=static