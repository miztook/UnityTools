#include "lua_export.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include <string.h>

HAPI lua_State* HOBA_lua_tothread(lua_State *L, int idx)
{
	return lua_tothread(L, idx);
}

HAPI void HOBA_lua_xmove(lua_State *from, lua_State *to, int n)
{
	lua_xmove(from, to, n);
}

HAPI int HOBA_lua_yield(lua_State *L, int nresults)
{
	return lua_yield(L, nresults);
}

HAPI lua_State* HOBA_lua_newthread(lua_State *L)
{
	return lua_newthread(L);
}

HAPI int HOBA_lua_resume(lua_State *L, int nargs)
{
	return lua_resume(L, nargs);
}

HAPI int HOBA_lua_status(lua_State *L)
{
	return lua_status(L);
}

HAPI int HOBA_lua_pushthread(lua_State *L)
{
	return lua_pushthread(L);
}

HAPI int HOBA_lua_gc(lua_State *L, int what, int data)
{
	return lua_gc(L, what, data);
}

HAPI const char* HOBA_lua_typename(lua_State *L, int t)
{
	return lua_typename(L, t);
}

HAPI int HOBA_luaL_error(lua_State *L, const char *fmt, ...)
{
	va_list argp;
	va_start(argp, fmt);
	luaL_where(L, 1);
	lua_pushvfstring(L, fmt, argp);
	va_end(argp);
	lua_concat(L, 2);
	return lua_error(L);
}

HAPI const char* HOBA_luaL_gsub(lua_State *L, const char *s, const char *p, const char *r)
{
	return luaL_gsub(L, s, p, r);
}

HAPI void HOBA_lua_getfenv(lua_State *L, int idx)
{
	lua_getfenv(L, idx);
}

HAPI int HOBA_lua_isuserdata(lua_State *L, int idx)
{
	return lua_isuserdata(L, idx);
}

HAPI int HOBA_lua_lessthan(lua_State *L, int index1, int index2)
{
	return lua_lessthan(L, index1, index2);
}

HAPI int HOBA_lua_rawequal(lua_State *L, int index1, int index2)
{
	return lua_rawequal(L, index1, index2);
}

HAPI int HOBA_lua_setfenv(lua_State *L, int idx)
{
	return lua_setfenv(L, idx);
}

HAPI void HOBA_lua_setfield(lua_State *L, int idx, const char *k)
{
	lua_setfield(L, idx, k);
}

HAPI int HOBA_luaL_callmeta(lua_State *L, int obj, const char *event)
{
	return luaL_callmeta(L, obj, event);
}

HAPI lua_State* HOBA_luaL_newstate(void)
{
	return luaL_newstate();
}

HAPI void HOBA_lua_close(lua_State *L)
{
	lua_close(L);
}

HAPI void HOBA_luaL_openlibs(lua_State *L)
{
	luaL_openlibs(L);
}

HAPI int HOBA_lua_objlen(lua_State *L, int idx)
{
	return (int)lua_objlen(L, idx);
}

HAPI int HOBA_luaL_loadstring(lua_State *L, const char *s)
{
	return luaL_loadstring(L, s);
}

HAPI void HOBA_lua_createtable(lua_State *L, int narray, int nrec)
{
	lua_createtable(L, narray, nrec);
}

HAPI void HOBA_lua_settop(lua_State *L, int idx)
{
	lua_settop(L, idx);
}

HAPI void HOBA_lua_insert(lua_State *L, int idx)
{
	lua_insert(L, idx);
}

HAPI void HOBA_lua_remove(lua_State *L, int idx)
{
	lua_remove(L, idx);
}

HAPI void HOBA_lua_gettable(lua_State *L, int idx)
{
	lua_gettable(L, idx);
}

HAPI void HOBA_lua_rawget(lua_State *L, int idx)
{
	lua_rawget(L, idx);
}

HAPI void HOBA_lua_settable(lua_State *L, int idx)
{
	lua_settable(L, idx);
}

HAPI void HOBA_lua_rawset(lua_State *L, int idx)
{
	lua_rawset(L, idx);
}

HAPI int HOBA_lua_setmetatable(lua_State *L, int objindex)
{
	return lua_setmetatable(L, objindex);
}

HAPI int HOBA_lua_getmetatable(lua_State *L, int objindex)
{
	return lua_getmetatable(L, objindex);
}

HAPI int HOBA_lua_equal(lua_State *L, int index1, int index2)
{
	return lua_equal(L, index1, index2);
}

HAPI void HOBA_lua_pushvalue(lua_State *L, int idx)
{
	lua_pushvalue(L, idx);
}

HAPI void HOBA_lua_replace(lua_State *L, int idx)
{
	lua_replace(L, idx);
}

HAPI int HOBA_lua_gettop(lua_State *L)
{
	return lua_gettop(L);
}

HAPI int HOBA_lua_type(lua_State *L, int idx)
{
	return lua_type(L, idx);
}

HAPI int HOBA_lua_isnumber(lua_State *L, int idx)
{
	return lua_isnumber(L, idx);
}

HAPI int HOBA_luaL_ref(lua_State *L, int t)
{
	return luaL_ref(L, t);
}

HAPI void HOBA_lua_rawgeti(lua_State *L, int idx, int n)
{
	lua_rawgeti(L, idx, n);
}

HAPI void HOBA_lua_rawseti(lua_State *L, int idx, int n)
{
	lua_rawseti(L, idx, n);
}

HAPI void* HOBA_lua_newuserdata(lua_State *L, int size)
{
	return lua_newuserdata(L, (size_t)size);
}

HAPI void* HOBA_lua_touserdata(lua_State *L, int idx)
{
	return lua_touserdata(L, idx);
}

HAPI void HOBA_luaL_unref(lua_State *L, int t, int ref)
{
	luaL_unref(L, t, ref);
}

HAPI int HOBA_lua_isstring(lua_State *L, int idx)
{
	return lua_isstring(L, idx);
}

HAPI int HOBA_lua_iscfunction(lua_State *L, int idx)
{
	return lua_iscfunction(L, idx);
}

HAPI void HOBA_lua_pushnil(lua_State *L)
{
	lua_pushnil(L);
}

HAPI void HOBA_lua_call(lua_State *L, int nargs, int nresults)
{
	lua_call(L, nargs, nresults);
}

HAPI int HOBA_lua_pcall(lua_State *L, int nargs, int nresults, int errfunc)
{
	return lua_pcall(L, nargs, nresults, errfunc);
}

HAPI lua_CFunction HOBA_lua_tocfunction(lua_State *L, int idx)
{
	return lua_tocfunction(L, idx);
}

HAPI double HOBA_lua_tonumber(lua_State *L, int idx)
{
	return lua_tonumber(L, idx);
}

HAPI int HOBA_lua_toboolean(lua_State *L, int idx)
{
	return lua_toboolean(L, idx);
}

HAPI const char* HOBA_lua_tolstring(lua_State *L, int idx, int *len)
{
	size_t l;
	const char* ret = lua_tolstring(L, idx, &l);
	if (len)
		*len = (int)l;
	return ret;
}

HAPI void HOBA_lua_atpanic(lua_State *L, lua_CFunction panicf)
{
	lua_atpanic(L, panicf);
}

HAPI void HOBA_lua_pushnumber(lua_State *L, double n)
{
	lua_pushnumber(L, n);
}

HAPI void HOBA_lua_pushinteger(lua_State *L, int n)
{
	lua_pushinteger(L, n);
}

HAPI void HOBA_lua_pushboolean(lua_State *L, int b)
{
	lua_pushboolean(L, b);
}

HAPI void HOBA_lua_pushlstring(lua_State *L, const char *s, int len)
{
	lua_pushlstring(L, s, (size_t)len);
}

HAPI void HOBA_lua_pushstring(lua_State *L, const char *s)
{
	lua_pushstring(L, s);
}

HAPI int HOBA_luaL_newmetatable(lua_State *L, const char *tname)
{
	return luaL_newmetatable(L, tname);
}

HAPI void HOBA_lua_getfield(lua_State *L, int idx, const char *k)
{
	lua_getfield(L, idx, k);
}

HAPI void* HOBA_luaL_checkudata(lua_State *L, int ud, const char *tname)
{
	return luaL_checkudata(L, ud, tname);
}

HAPI int HOBA_luaL_getmetafield(lua_State *L, int obj, const char *event)
{
	return luaL_getmetafield(L, obj, event);
}

HAPI int HOBA_lua_load(lua_State *L, lua_Reader reader, void *data, const char *chunkname)
{
	return lua_load(L, reader, data, chunkname);
}

HAPI int HOBA_luaL_loadbuffer(lua_State *L, const char *buff, int size, const char *name)
{
	return luaL_loadbuffer(L, buff, (size_t)size, name);
}

HAPI int HOBA_luaL_loadfile(lua_State *L, const char *filename)
{
	return luaL_loadfile(L, filename);
}

HAPI int HOBA_lua_error(lua_State *L)
{
	return lua_error(L);
}

HAPI int HOBA_lua_checkstack(lua_State *L, int size)
{
	return lua_checkstack(L, size);
}

HAPI int HOBA_lua_next(lua_State *L, int idx)
{
	return lua_next(L, idx);
}

HAPI void HOBA_lua_pushlightuserdata(lua_State *L, void *p)
{
	lua_pushlightuserdata(L, p);
}

HAPI void* HOBA_luanet_gettag()
{
	return luanet_gettag();
}

HAPI void HOBA_luaL_where(lua_State* L, int level)
{
	luaL_where(L, level);
}

HAPI void HOBA_lua_pushcclosure(lua_State *L, lua_CFunction fn, int n)
{
	lua_pushcclosure(L, fn, n);
}

HAPI const char* HOBA_lua_getupvalue(lua_State *L, int funcindex, int n)
{
	return lua_getupvalue(L, funcindex, n);
}

HAPI const char * HOBA_lua_setupvalue(lua_State *L, int funcindex, int n)
{
	return lua_setupvalue(L, funcindex, n);
}

HAPI int HOBA_luaL_typerror(lua_State *L, int narg, const char *tname)
{
	return luaL_typerror(L, narg, tname);
}

HAPI int HOBA_luaL_argerror(lua_State *L, int narg, const char *extramsg)
{
	return luaL_argerror(L, narg, extramsg);
}

HAPI bool HOBA_Unity_Lua_PCall(lua_State *L, int nArgs, int nResults, int registryIndex, int errofFuncRef)
{
	int oldTop = lua_gettop(L) - nArgs - 1;
	lua_rawgeti(L, registryIndex, errofFuncRef);
	lua_insert(L, oldTop + 1);
	if (lua_pcall(L, nArgs, nResults, oldTop + 1) == 0)
	{
		lua_remove(L, oldTop + 1);	//pop errorFunc
		return true;
	}
	else
	{
		lua_remove(L, oldTop + 1);	//pop errorFunc
		return false;
	}
}

char g_UnityErrorString[512];
HAPI const char* HOBA_Unity_Lua_Call(lua_State *L, int nArgs, int registryIndex, int errofFuncRef)
{
	int oldTop = lua_gettop(L) - nArgs - 1;
	lua_rawgeti(L, registryIndex, errofFuncRef);
	lua_insert(L, oldTop + 1);
	if (lua_pcall(L, nArgs, 0, oldTop + 1) == 0)
	{
		lua_remove(L, oldTop + 1);	//pop errorFunc

		return NULL;
	}
	else
	{
		lua_remove(L, oldTop + 1);	//pop errorFunc
		const char* err = lua_tostring(L, -1);
		if (err)
		{
			size_t len = strlen(err);
			if (len > 511)
				len = 511;
			strncpy(g_UnityErrorString, err, len);
			g_UnityErrorString[len] = '\0';
		}
		lua_pop(L, 1);

		return g_UnityErrorString;
	}
}

