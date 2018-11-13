#ifndef _LUATABLE_H_
#define _LUATABLE_H_

#ifndef LUA_LIB
#define LUA_LIB
#endif

extern "C"
{
#include "lua.h"
#include "lauxlib.h"
#include "luaconf.h"
};

#include <string>

//#include "utf8.h"
//#include "utf16string.h"

class CLuaTable
{
	lua_State* L;

private:

	void PushValue(int v)
	{
		lua_pushinteger(L, v);
	}

	void PushValue(bool v)
	{
		lua_pushboolean(L, v);
	}

	void PushValue(unsigned int v)
	{
		lua_pushnumber(L, (double)v);
	}

	void PushValue(char const* v)
	{
		if (v)
		{
			std::string utf8Str(v);   // 此处需要测试！！！！！
			//utf8::unchecked::utf16to8(v, v + utf16_strlen(v), back_inserter(utf8Str));
			lua_pushlstring(L, utf8Str.c_str(), utf8Str.size());
		}
		else
			lua_pushstring(L, "");
	}

	void PushValue(char * v)
	{
		PushValue((char const*)v);
	}

	template <class T>
	void PushValue(T const& v)
	{
		v.CreateTable(L);
	}

	template <class T>
	void PushValue(const T* v)
	{
		if (v == 0)
		{
			lua_pushnil(L);
		}
		else
			PushValue(*v);
	}

public:

	CLuaTable(lua_State* L_)
	{
		L = L_;
	}

	template<class T>
	void SetValue(const char* k, T const& v)
	{
		PushValue(v);
		lua_setfield(L, -2, k);
	}

	template<class T>
	void SetArrayValue(const char* k, T const* v, int count)
	{
		lua_createtable(L, count, 0);

		for (int i = 0; i < count; i++)
		{
			PushValue(v[i]);
			lua_rawseti(L, -2, i + 1);
		}

		lua_setfield(L, -2, k);
	}
};

#define LUA_CREATE_TABLE(sz) lua_createtable(L, 0, sz); CLuaTable tb(L);
#define LUA_SET_VALUE(v) tb.SetValue(#v, v)
#define LUA_SET_VALUE2(key, value) tb.SetValue(key, value)
#define LUA_SET_ARRAY_VALUE(arr) tb.SetArrayValue(#arr, arr, sizeof(arr) / sizeof(arr[0]))

#endif
