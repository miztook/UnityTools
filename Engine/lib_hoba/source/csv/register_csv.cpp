#include "CsvWrapper.h"
#include "lua.hpp"
#include "lua_tinker.h"

extern "C"
{
#include "lua_export.h"
}

int csv_openlibs(lua_State* L)
{
	lua_tinker::class_add<CCsvWrapper>(L, "CCsvWrapper");
	lua_tinker::class_con<CCsvWrapper>(L, lua_tinker::constructor<CCsvWrapper>);

	bool (CCsvWrapper::*ptr1)(const char*) = &CCsvWrapper::LoadCSV;
	lua_tinker::class_def<CCsvWrapper>(L, "LoadCSV", ptr1);

	const char* (CCsvWrapper::*ptr2)(unsigned int, unsigned int) = &CCsvWrapper::GetValue;
	lua_tinker::class_def<CCsvWrapper>(L, "GetValue", ptr2);

	int (CCsvWrapper::*ptr3)(unsigned int, unsigned int) = &CCsvWrapper::GetInt;
	lua_tinker::class_def<CCsvWrapper>(L, "GetInt", ptr3);

	float (CCsvWrapper::*ptr4)(unsigned int, unsigned int) = &CCsvWrapper::GetFloat;
	lua_tinker::class_def<CCsvWrapper>(L, "GetFloat", ptr4);

	bool (CCsvWrapper::*ptr5)(const char*) = &CCsvWrapper::SaveCSV;
	lua_tinker::class_def<CCsvWrapper>(L, "SaveCSV", ptr5);

	return 1;
}

