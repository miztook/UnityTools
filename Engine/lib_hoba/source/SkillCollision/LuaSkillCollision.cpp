#include "lua.hpp"

extern "C"
{
#include "lua_export.h"
}

#include "EC_SkillCollisionObject.h"
#include "EC_SkillCollisionShape.h"
#include "EC_SkillCollisionData.h"

static A3DVECTOR3 checkVector3(lua_State *L, int index)
{
	luaL_checktype(L, index, LUA_TTABLE);

	lua_getfield(L, index, "x");
	float x = float(luaL_checknumber(L, -1));
	lua_pop(L, 1);

	lua_getfield(L, index, "y");
	float y = float(luaL_checknumber(L, -1));
	lua_pop(L, 1);

	lua_getfield(L, index, "z");
	float z = float(luaL_checknumber(L, -1));
	lua_pop(L, 1);

	return A3DVECTOR3(x, y, z);
}

static int IsCollided(lua_State *L)
{
	void* ppShape = luaL_checkudata(L, 1, "*SkillCollision.Shape");
	CECSkillCollisionShape* pShape = *(CECSkillCollisionShape**)ppShape;
	
	A3DVECTOR3 pos = checkVector3(L, 2);
	float radius = float(luaL_checknumber(L, 3));
	
	CECSkillCollisionObjectCycle obj(pos, radius);
	lua_pushboolean(L, pShape->IsCollided(&obj));
	return 1;
}

static int IsCollidedXYZ(lua_State *L)
{
	void* ppShape = luaL_checkudata(L, 1, "*SkillCollision.Shape");
	CECSkillCollisionShape* pShape = *(CECSkillCollisionShape**)ppShape;

	float posX = float(luaL_checknumber(L, 2));
	float posY = float(luaL_checknumber(L, 3));
	float posZ = float(luaL_checknumber(L, 4));

	A3DVECTOR3 pos(posX, posY, posZ);
	float radius = float(luaL_checknumber(L, 5));

	CECSkillCollisionObjectCycle obj(pos, radius);
	lua_pushboolean(L, pShape->IsCollided(&obj));
	return 1;
}

static int Shape_gc(lua_State *L)
{
	void* ppShape = luaL_checkudata(L, 1, "*SkillCollision.Shape");
	CECSkillCollisionShape* pShape = *(CECSkillCollisionShape**)ppShape;
	delete pShape;
	return 0;
}

static const struct luaL_Reg Shape_methods[] = {
	{ "IsCollided", IsCollided },
	{ "IsCollidedXYZ", IsCollidedXYZ },
	{ 0, 0 }
};

static void NewShapeMetaTable(lua_State *L)
{
	int isNew = luaL_newmetatable(L, "*SkillCollision.Shape");
	if (isNew)
	{
		lua_newtable(L);
		luaL_register(L, NULL, Shape_methods);
		lua_setfield(L, -2, "__index");

		lua_pushcfunction(L, &Shape_gc);
		lua_setfield(L, -2, "__gc");
	}
}

static int CreateShape(lua_State *L)
{
	COLLISION_INST ci = {};
	ci.perform_data.target_affect_obj = luaL_checkinteger(L, 1);
	ci.perform_data.target_affect_radius = float(luaL_checknumber(L, 2));
	ci.perform_data.target_affect_lenght = float(luaL_checknumber(L, 3));
	ci.perform_data.target_affect_angle = float(luaL_checknumber(L, 4));
	ci.perform_data.direction = 0;

	A3DVECTOR3 pos = checkVector3(L, 5);
	A3DVECTOR3 dir = checkVector3(L, 6);

	CECSkillCollisionShape* pShape = CECSkillCollisionShape::Create(ci);
	pShape->SetPosDir(pos, dir);
	pShape->SetRatio(1.0f);
	pShape->SetHeight(0.0f);

	void* ppShape = lua_newuserdata(L, sizeof(pShape));
	*(CECSkillCollisionShape**)ppShape = pShape;

	NewShapeMetaTable(L);
	lua_setmetatable(L, -2);
	return 1;
}

static int CreateShapeXYZ(lua_State *L)
{
	COLLISION_INST ci = {};
	ci.perform_data.target_affect_obj = luaL_checkinteger(L, 1);
	ci.perform_data.target_affect_radius = float(luaL_checknumber(L, 2));
	ci.perform_data.target_affect_lenght = float(luaL_checknumber(L, 3));
	ci.perform_data.target_affect_angle = float(luaL_checknumber(L, 4));
	ci.perform_data.direction = 0;

	float posX = float(luaL_checknumber(L, 5));
	float posY = float(luaL_checknumber(L, 6));
	float posZ = float(luaL_checknumber(L, 7));

	float dirX = float(luaL_checknumber(L, 8));
	float dirY = float(luaL_checknumber(L, 9));
	float dirZ = float(luaL_checknumber(L, 10));

	A3DVECTOR3 pos(posX, posY, posZ);
	A3DVECTOR3 dir(dirX, dirY, dirZ);

	CECSkillCollisionShape* pShape = CECSkillCollisionShape::Create(ci);
	pShape->SetPosDir(pos, dir);
	pShape->SetRatio(1.0f);
	pShape->SetHeight(0.0f);

	void* ppShape = lua_newuserdata(L, sizeof(pShape));
	*(CECSkillCollisionShape**)ppShape = pShape;

	NewShapeMetaTable(L);
	lua_setmetatable(L, -2);
	return 1;
}

static int IsShapeCollidedXYZ(lua_State *L)
{
	COLLISION_INST ci = {};
	ci.perform_data.target_affect_obj = luaL_checkinteger(L, 1);
	ci.perform_data.target_affect_radius = float(luaL_checknumber(L, 2));
	ci.perform_data.target_affect_lenght = float(luaL_checknumber(L, 3));
	ci.perform_data.target_affect_angle = float(luaL_checknumber(L, 4));
	ci.perform_data.direction = 0;

	float posX = float(luaL_checknumber(L, 5));
	float posY = float(luaL_checknumber(L, 6));
	float posZ = float(luaL_checknumber(L, 7));

	float dirX = float(luaL_checknumber(L, 8));
	float dirY = float(luaL_checknumber(L, 9));
	float dirZ = float(luaL_checknumber(L, 10));

	float target_posX = float(luaL_checknumber(L, 11));
	float target_posY = float(luaL_checknumber(L, 12));
	float target_posZ = float(luaL_checknumber(L, 13));
	float target_radius = float(luaL_checknumber(L, 14));

	A3DVECTOR3 pos(posX, posY, posZ);
	A3DVECTOR3 dir(dirX, dirY, dirZ);
	A3DVECTOR3 target_pos(target_posX, target_posY, target_posZ);

	_SKILLCOLLISIONSHAPE_PARAMS c_params;
	Enum_SkillCollisionShapeType eType = CECSkillCollisionShape::MakeParams(ci, c_params);
	CECSkillCollisionObjectCycle obj(target_pos, target_radius);

	if (eType == SKILLCOLLISIONSHAPE_RECT)
	{
		CECSkillCollisionShapeRect shape(c_params);
		shape.SetPosDir(pos, dir);
		shape.SetRatio(1.0f);
		shape.SetHeight(0.0f);
		lua_pushboolean(L, shape.IsCollided(&obj));
	}
	else if (eType == SKILLCOLLISIONSHAPE_FAN)
	{
		CECSkillCollisionShapeFan shape(c_params);
		shape.SetPosDir(pos, dir);
		shape.SetRatio(1.0f);
		shape.SetHeight(0.0f);
		lua_pushboolean(L, shape.IsCollided(&obj));
	}
	else if (eType == SKILLCOLLISIONSHAPE_CYCLE)
	{
		CECSkillCollisionShapeCycle shape(c_params);
		shape.SetPosDir(pos, dir);
		shape.SetRatio(1.0f);
		shape.SetHeight(0.0f);
		lua_pushboolean(L, shape.IsCollided(&obj));
	}
	else
	{
		lua_pushboolean(L, false);
	}
	return 1;
}

static const struct luaL_Reg SkillCollision_funcs[] = {
	{ "CreateShape", CreateShape },
	{ "CreateShapeXYZ", CreateShapeXYZ },
	{ "IsShapeCollidedXYZ", IsShapeCollidedXYZ },
	{ 0, 0 }
};

extern "C"
{
	int luaopen_SkillCollision(lua_State *L)
	{
		luaL_register(L, "SkillCollision", SkillCollision_funcs);
		return 1;
	}
};

