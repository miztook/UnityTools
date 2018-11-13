#ifndef _LUA_EXPORT_H_
#define _LUA_EXPORT_H_

#include "baseDef.h"
#include "lua.h"
#include <stdbool.h>

//export functions register c to lua

HAPI int luaopen_pb(lua_State *L);			//pb.c

HAPI int luaopen_bit(lua_State *L);			//bit.c

HAPI int luaopen_lfs(lua_State *L);			//lfs.c

HAPI int tolua_openlibs(lua_State* L);			//luawrap.c

HAPI int tinyxml_openlibs(lua_State* L);		//register_tinyxml.cpp

HAPI int csv_openlibs(lua_State* L);			//register_csv.cpp

HAPI int luaopen_profiler(lua_State *L);			//profiler.cpp

HAPI int luaopen_LuaUInt64(lua_State *L);		//LuaUInt64

HAPI int luaopen_SkillCollision(lua_State *L);				//LuaSkillCollision.cpp

HAPI int luaopen_cbinary(lua_State* L);			//BinaryReadWrite.cpp

HAPI int luaopen_socket_core(lua_State *L);	  //luasocket.c

HAPI int luaopen_mime_core(lua_State *L);		//mime.c

HAPI int luaopen_snapshot(lua_State *L);	 //snapshot.c


//lua export, wrapper for luaXXX functions

HAPI lua_State* HOBA_lua_tothread(lua_State *L, int idx);

HAPI void HOBA_lua_xmove(lua_State *from, lua_State *to, int n);

HAPI int HOBA_lua_yield(lua_State *L, int nresults);
												 
HAPI lua_State* HOBA_lua_newthread(lua_State *L);

HAPI int HOBA_lua_resume(lua_State *L, int nargs);

HAPI int  HOBA_lua_status(lua_State *L);

HAPI int HOBA_lua_pushthread(lua_State *L);

HAPI int HOBA_lua_gc(lua_State *L, int what, int data);

HAPI const char* HOBA_lua_typename(lua_State *L, int t);

HAPI int HOBA_luaL_error(lua_State *L, const char *fmt, ...);

HAPI const char* HOBA_luaL_gsub(lua_State *L, const char *s, const char *p, const char *r);

HAPI void HOBA_lua_getfenv(lua_State *L, int idx);

HAPI int HOBA_lua_isuserdata(lua_State *L, int idx);

HAPI int HOBA_lua_lessthan(lua_State *L, int index1, int index2);

HAPI int HOBA_lua_rawequal(lua_State *L, int index1, int index2);

HAPI int HOBA_lua_setfenv(lua_State *L, int idx);

HAPI void HOBA_lua_setfield(lua_State *L, int idx, const char *k);

HAPI int HOBA_luaL_callmeta(lua_State *L, int obj, const char *event);

HAPI lua_State* HOBA_luaL_newstate(void);

HAPI void HOBA_lua_close(lua_State *L);

HAPI void HOBA_luaL_openlibs(lua_State *L);

HAPI int HOBA_lua_objlen(lua_State *L, int idx);

HAPI int HOBA_luaL_loadstring(lua_State *L, const char *s);

HAPI void HOBA_lua_createtable(lua_State *L, int narray, int nrec);

HAPI void HOBA_lua_settop(lua_State *L, int idx);

HAPI void HOBA_lua_insert(lua_State *L, int idx);

HAPI void HOBA_lua_remove(lua_State *L, int idx);

HAPI void HOBA_lua_gettable(lua_State *L, int idx);

HAPI void HOBA_lua_rawget(lua_State *L, int idx);

HAPI void HOBA_lua_settable(lua_State *L, int idx);

HAPI void HOBA_lua_rawset(lua_State *L, int idx);

HAPI int HOBA_lua_setmetatable(lua_State *L, int objindex);

HAPI int HOBA_lua_getmetatable(lua_State *L, int objindex);

HAPI int HOBA_lua_equal(lua_State *L, int index1, int index2);

HAPI void HOBA_lua_pushvalue(lua_State *L, int idx);

HAPI void HOBA_lua_replace(lua_State *L, int idx);

HAPI int HOBA_lua_gettop(lua_State *L);

HAPI int HOBA_lua_type(lua_State *L, int idx);

HAPI int HOBA_lua_isnumber(lua_State *L, int idx);

HAPI int HOBA_luaL_ref(lua_State *L, int t);

HAPI void HOBA_lua_rawgeti(lua_State *L, int idx, int n);

HAPI void HOBA_lua_rawseti(lua_State *L, int idx, int n);

HAPI void* HOBA_lua_newuserdata(lua_State *L, int size);

HAPI void* HOBA_lua_touserdata(lua_State *L, int idx);

HAPI void HOBA_luaL_unref(lua_State *L, int t, int ref);

HAPI int HOBA_lua_isstring(lua_State *L, int idx);

HAPI int HOBA_lua_iscfunction(lua_State *L, int idx);

HAPI void HOBA_lua_pushnil(lua_State *L);

HAPI void HOBA_lua_call(lua_State *L, int nargs, int nresults);

HAPI int HOBA_lua_pcall(lua_State *L, int nargs, int nresults, int errfunc);

HAPI lua_CFunction HOBA_lua_tocfunction(lua_State *L, int idx);

HAPI double HOBA_lua_tonumber(lua_State *L, int idx);

HAPI int HOBA_lua_toboolean(lua_State *L, int idx);

HAPI const char* HOBA_lua_tolstring(lua_State *L, int idx, int *len);

HAPI void HOBA_lua_atpanic(lua_State *L, lua_CFunction panicf);

HAPI void HOBA_lua_pushnumber(lua_State *L, double n);

HAPI void HOBA_lua_pushinteger(lua_State *L, int n);

HAPI void HOBA_lua_pushboolean(lua_State *L, int b);

HAPI void HOBA_lua_pushlstring(lua_State *L, const char *s, int len);

HAPI void HOBA_lua_pushstring(lua_State *L, const char *s);

HAPI int HOBA_luaL_newmetatable(lua_State *L, const char *tname);

HAPI void HOBA_lua_getfield(lua_State *L, int idx, const char *k);

HAPI void* HOBA_luaL_checkudata(lua_State *L, int ud, const char *tname);

HAPI int HOBA_luaL_getmetafield(lua_State *L, int obj, const char *event);

HAPI int HOBA_lua_load(lua_State *L, lua_Reader reader, void *data, const char *chunkname);

HAPI  int HOBA_luaL_loadbuffer(lua_State *L, const char *buff, int size, const char *name);

HAPI int HOBA_luaL_loadfile(lua_State *L, const char *filename);

HAPI int HOBA_lua_error(lua_State *L);

HAPI int HOBA_lua_checkstack(lua_State *L, int size);

HAPI int HOBA_lua_next(lua_State *L, int idx);

HAPI void HOBA_lua_pushlightuserdata(lua_State *L, void *p);

HAPI void HOBA_luaL_where(lua_State* L, int level);

HAPI void HOBA_lua_pushcclosure(lua_State *L, lua_CFunction fn, int n);

HAPI const char* HOBA_lua_getupvalue(lua_State *L, int funcindex, int n);

HAPI const char *HOBA_lua_setupvalue(lua_State *L, int funcindex, int n);

HAPI int HOBA_luaL_typerror(lua_State *L, int narg, const char *tname);

HAPI int HOBA_luaL_argerror(lua_State *L, int narg, const char *extramsg);

//lua_wrap.c

HAPI int luaL_checkmetatable(lua_State *L, int index);

HAPI int luanet_tonetobject(lua_State *L, int index);

HAPI void luanet_newudata(lua_State *L, int val);

HAPI int luanet_rawnetobj(lua_State *L, int index);

HAPI int luanet_checkudata(lua_State *L, int index, const char *meta);

HAPI void* luanet_gettag();

HAPI void tolua_getfloat2(lua_State* L, int ref, int pos, float* x, float* y);

HAPI void tolua_getfloat3(lua_State* L, int ref, int pos, float* x, float* y, float* z);

HAPI void tolua_getfloat4(lua_State* L, int ref, int pos, float* x, float* y, float* z, float* w);

HAPI void tolua_getfloat6(lua_State* L, int ref, int pos, float* x, float* y, float* z, float* x1, float* y1, float* z1);

HAPI void tolua_pushfloat2(lua_State* L, int ref, float x, float y);

HAPI void tolua_pushfloat3(lua_State* L, int ref, float x, float y, float z);

HAPI void tolua_pushfloat4(lua_State* L, int ref, float x, float y, float z, float w);

HAPI bool tolua_pushudata(lua_State* L, int reference, int index);

HAPI bool tolua_pushnewudata(lua_State* L, int metaRef, int weakTableRef, int index);

HAPI void tolua_setindex(lua_State* L);

HAPI void tolua_setnewindex(lua_State* L);

HAPI void setup_luastate(lua_State* L);

HAPI void clear_luastate();

HAPI bool HOBA_Unity_Lua_PCall(lua_State *L, int nArgs, int nResults, int registryIndex, int errofFuncRef);
HAPI const char* HOBA_Unity_Lua_Call(lua_State *L, int nArgs, int registryIndex, int errofFuncRef);

#endif