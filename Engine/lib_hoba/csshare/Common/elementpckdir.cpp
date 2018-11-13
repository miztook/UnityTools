#include "elementpckdir.h"

// 打包目录
const char * g_szPckDir[4][2] =
{
	//"assetbundles", "package/assetbundles",
	"configs", "package/configs",
	"data", "package/data",
	"lua", "package/lua",
	"maps", "package/maps",
	//"audio", "package/audio",
};

// 不打包目录
const char * g_szNoPckDir[4][2] =
{
	// element files
	"bin", "s",							// s means file must be in the sep files list
	"logs", "",
	"userdata", "",
	".", "",
};

// 独立资源
const char * g_szSepFiles[13] =
{
	"game.exe",
	"ReportBugs.exe",
	"server.lua",
	"dbghelp.dll",
	"elementskill.dll",
	"ftdriver.dll",
	"ifc22.dll",
	"unicows.dll",
	"zlibwapi.dll",
	"fmodex.dll",
	"D3DCompiler_43.dll",
	"D3DX9_43.dll",
	"gt_updater.exe",
};