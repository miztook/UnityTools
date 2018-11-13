#include "ATypes.h"
#include "ASys.h"

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

extern "C"
{
#include "lua_export.h"
}

#include <stdio.h>
#include <stdlib.h>

static auint64 checkUInt64(lua_State *L, int n)
{
	size_t len;
	const char* str = luaL_checklstring(L, n, &len);
	if (len != 8)
	{
		luaL_error(L, "bad uint64 string length (8 expected, got %d)", int(len));
		return 0;
	}

	return *(auint64*)str;
}

static void pushUInt64(lua_State *L, auint64 value)
{
	lua_pushlstring(L, (const char*)&value, 8);
}

static int LuaUInt64_Make(lua_State *L)
{
	unsigned high = (unsigned)(auint64)luaL_checknumber(L, 1);
	unsigned low = (unsigned)(auint64)luaL_checknumber(L, 2);
	
	auint64 value = (auint64(high) << 32) | low;
	pushUInt64(L, value);
	return 1;
}

static int LuaUInt64_FromString(lua_State *L)
{
	char const* str = luaL_checkstring(L, 1);
	
	auint64 value = auint64(ASys::AtoInt64(str));
	lua_pushlstring(L, (const char*)&value, 8);
	return 1;
}

static int LuaUInt64_And(lua_State *L)
{
	auint64 left = checkUInt64(L, 1);
	auint64 right = checkUInt64(L, 2);

	pushUInt64(L, left & right);
	return 1;
}

static int LuaUInt64_Or(lua_State *L)
{
	auint64 left = checkUInt64(L, 1);
	auint64 right = checkUInt64(L, 2);

	pushUInt64(L, left | right);
	return 1;
}

static int LuaUInt64_Xor(lua_State *L)
{
	auint64 left = checkUInt64(L, 1);
	auint64 right = checkUInt64(L, 2);

	pushUInt64(L, left ^ right);
	return 1;
}

static int LuaUInt64_FromDouble(lua_State *L)
{
	double value = luaL_checknumber(L, 1);

	pushUInt64(L, (auint64)value);
	return 1;
}

static int LuaUInt64_ToDouble(lua_State *L)
{
	auint64 value = checkUInt64(L, 1);

	lua_pushnumber(L, (double)value);
	return 1;
}

static int LuaUInt64_ToString(lua_State *L)
{
	auint64 value = checkUInt64(L, 1);

	char buffer[64];
	sprintf(buffer, "%llu", value);
	lua_pushstring(L, buffer);
	return 1;
}

static int LuaUInt64_GetHighAndLow(lua_State *L)
{
	auint64 value = checkUInt64(L, 1);

	unsigned int low = (unsigned int)value;
	unsigned int high = (unsigned int)(value >> 32);
	lua_pushnumber(L, (double)high);
	lua_pushnumber(L, (double)low);
	return 2;
}


static const struct luaL_Reg LuaUInt64_funcs[] = {
	{ "Make", LuaUInt64_Make },
	{ "FromString", LuaUInt64_FromString },
	{ "And", LuaUInt64_And },
	{ "Or", LuaUInt64_Or },
 	{ "Xor", LuaUInt64_Xor },
 	{ "FromDouble", LuaUInt64_FromDouble },
 	{ "ToDouble", LuaUInt64_ToDouble },
 	{ "ToString", LuaUInt64_ToString },
 	{ "GetHighAndLow", LuaUInt64_GetHighAndLow },
	{ 0, 0 }
};

extern "C"
{
	int luaopen_LuaUInt64(lua_State *L)
	{
		luaL_register(L, "LuaUInt64", LuaUInt64_funcs);
		return 1;
	}
};


