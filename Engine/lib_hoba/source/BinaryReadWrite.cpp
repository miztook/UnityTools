#include "ATypes.h"
#include "ASys.h"
#include <memory.h>

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

extern "C"
{
#include "lua_export.h"
}


template<class T>
inline T _lua_read(const void* ptr, int offset)
{
	T d;
	memcpy(&d, (const char*)ptr + offset, sizeof(d));
	return d;
}

template<class T>
inline int lua_read(lua_State *L)
{
	const void* ptr = lua_touserdata(L, 1);
	int offset = lua_tointeger(L, 2);
	T v = _lua_read<T>(ptr, offset);
	lua_pushnumber(L, (lua_Number)v);
	return 1;
}

static int lua_ReadInt32(lua_State *L)
{
	return lua_read<int>(L);
}

static int lua_ReadUInt32(lua_State *L)
{
	return lua_read<unsigned int>(L);
}

static int lua_ReadInt16(lua_State *L)
{
	return lua_read<short>(L);
}

static int lua_ReadUInt16(lua_State *L)
{
	return lua_read<unsigned short>(L);
}

static int lua_ReadByte(lua_State *L)
{
	return lua_read<unsigned char>(L);
}

static int lua_ReadSByte(lua_State *L)
{
	return lua_read<char>(L);
}

static int lua_ReadDouble(lua_State *L)
{
	return lua_read<double>(L);
}

static int lua_ReadSingle(lua_State *L)
{
	return lua_read<float>(L);
}

static int lua_ReadString(lua_State *L)
{
	const void* ptr = lua_touserdata(L, 1);
	int offset = lua_tointeger(L, 2);
	const char* str = ((const char*)ptr + offset);
	lua_pushlstring(L, str, strlen(str));
	return 1;
}

static int lua_AddPtr(lua_State *L)
{
	void* ptr = lua_touserdata(L, 1);
	int offset = lua_tointeger(L, 2);
	char* p = (char*)ptr + offset;
	lua_pushlightuserdata(L, (void*)p);
	return 1;
}

static const struct luaL_Reg cbinary_funcs[] = {
	{ "ReadInt32",	lua_ReadInt32 },
	{ "ReadUInt32",	lua_ReadUInt32 },
	{ "ReadInt16",	lua_ReadInt16 },
	{ "ReadUInt16",	lua_ReadUInt16 },
	{ "ReadByte",	lua_ReadByte },
	{ "ReadSByte",	lua_ReadSByte },
	{ "ReadDouble",	lua_ReadDouble },
	{ "ReadSingle",	lua_ReadSingle },
	{ "ReadString",	lua_ReadString },
	{ "AddPtr",	lua_AddPtr },
	{ NULL, NULL }
};

extern "C"
{
	int luaopen_cbinary(lua_State *L)
	{
		luaL_register(L, "cbinary", cbinary_funcs);
		return 1;
	}
};
