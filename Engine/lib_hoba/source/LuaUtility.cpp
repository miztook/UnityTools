#include "LuaUtility.h"

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

bool Lua_IsNumber(lua_State *L, int idx)
{
	return lua_isnumber(L, idx) != 0;
}

bool Lua_IsString(lua_State *L, int idx)
{
	return lua_isstring(L, idx) != 0;
}

bool Lua_IsCFunction(lua_State *L, int idx)
{
	return lua_iscfunction(L, idx) != 0;
}

bool Lua_IsUserData(lua_State *L, int idx)
{
	return lua_isuserdata(L, idx) != 0;
}

int Lua_Type(lua_State *L, int idx)
{
	return lua_type(L, idx);
}

const char* Lua_TypeName(lua_State *L, int tp)
{
	return lua_typename(L, tp);
}

int Lua_GetNumArgs(lua_State* L)
{
	int n = lua_gettop(L);
	return n;
}

int Lua_GetNumResults(lua_State* L, int idx)
{
	int n = lua_gettop(L);
	return n - idx + 1;
}
