#include "hobaTest.h"
#include "fileImageTest.h"
#include <string.h>
#include <crtdbg.h>
#include <Windows.h>

#pragma comment(lib, "hoba.lib")

int main()
{
#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	char curDir[MAX_PATH];
	GetCurrentDirectoryA(MAX_PATH, curDir);
	printf("current directory: %s\n\n", curDir);

	char tmpDir[MAX_PATH];
	sprintf(tmpDir, "%s/tmp", curDir);

	char libDir[MAX_PATH];
	sprintf(libDir, "%s/Library/Caches/updateres", curDir);

	HOBA_Init(curDir, curDir, libDir, tmpDir);

	lua_State* L = HOBA_luaL_newstate();

	HOBA_luaL_openlibs(L);

	unsigned int now = GetTickCount();

	//test
	//FileImageTest();

	luaL_dofile(L, "./TestFile/Math.lua");

	unsigned int delta = GetTickCount() - now;

	//printf("time: %u\n", delta);

	HOBA_lua_close(L);

	int memKB;
	HOBA_Release(&memKB);

	getchar();
	return 0;
}


int luaL_dofile(lua_State* L, const char* filename)
{
	int result = luaL_loadfile(L, filename);
	if (result == 0)
	{
		result = lua_pcall(L, 0, -1, 0);
	}
	
	if (result != 0)
		printf("run lua file %s failed, error: %s\n", filename, HOBA_lua_tolstring(L, -1, NULL));
	//else
	//	printf("run lua file %s succeed. \n", filename);

	return result;
}

int luaL_loadfile(lua_State *L, const char *filename)
{
	return HOBA_luaL_loadfile(L, filename);
}

int lua_pcall(lua_State *L, int nargs, int nresults, int errfunc)
{
	return HOBA_lua_pcall(L, nargs, nresults, errfunc);
}
