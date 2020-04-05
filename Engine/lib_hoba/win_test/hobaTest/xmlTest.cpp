#include "xmlTest.h"
#include "lua_export.h"

void LoadCsv(lua_State* L)
{
	csv_openlibs(L);
	luaL_dofile(L, "../../SampleCsv.lua");
}

void LoadXml(lua_State* L)
{
	tinyxml_openlibs(L);
	luaL_dofile(L, "../../SampleTinyXml.lua");
}