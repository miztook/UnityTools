#ifndef _LUA_UTILITY_H_
#define _LUA_UTILITY_H_

struct lua_State;

enum LuaTypes
{
	LUA_TNONE = -1,
	LUA_TNIL = 0,
	LUA_TLIGHTUSERDATA = 2,
	LUA_TNUMBER = 3,
	LUA_TSTRING = 4,
	LUA_TBOOLEAN = 1,
	LUA_TTABLE = 5,
	LUA_TFUNCTION = 6,
	LUA_TUSERDATA = 7,
	LUA_TTHREAD = 8,
};

bool     Lua_IsNumber(lua_State *L, int idx);
bool     Lua_IsString(lua_State *L, int idx);
bool     Lua_IsCFunction(lua_State *L, int idx);
bool     Lua_IsUserData(lua_State *L, int idx);
int     Lua_Type(lua_State *L, int idx);
const char* Lua_TypeName(lua_State *L, int tp);

int		Lua_GetNumArgs(lua_State* L);
int		Lua_GetNumResults(lua_State* L, int idx);

#endif