extern "C"
{
#include "lua_export.h"
}

#include "AAssist.h"

HAPI void setup_luastate(lua_State* L)
{
	a_SetLuaState(L);
}

HAPI void clear_luastate()
{
	a_SetLuaState(NULL);
}
