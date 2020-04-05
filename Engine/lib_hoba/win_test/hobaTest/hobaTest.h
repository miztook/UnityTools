#pragma once

extern "C"
{
#include "hoba_export.h"
#include "lua_export.h"
}

struct lua_State;

#include <stdio.h>

int luaL_dofile(lua_State* L, const char* filename);

extern "C"
{
	int luaL_loadfile(lua_State *L, const char *filename);

	int lua_pcall(lua_State *L, int nargs, int nresults, int errfunc);
}
