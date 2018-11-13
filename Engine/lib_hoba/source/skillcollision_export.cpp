extern "C"
{
#include "skillcollision_export.h"
}

#include "EC_SkillCollisionObject.h"
#include "EC_SkillCollisionShape.h"
#include "EC_SkillCollisionData.h"

HAPI CECSkillCollisionShape* SC_CreateShape(int objType, float radius, float length, float angle, float pos[3], float dir[3])
{
	COLLISION_INST ci = {0};
	ci.perform_data.target_affect_obj = objType;
	ci.perform_data.target_affect_radius = radius;
	ci.perform_data.target_affect_lenght = length;
	ci.perform_data.target_affect_angle = angle;
	ci.perform_data.direction = 0;

	A3DVECTOR3 vPos(pos[0], pos[1], pos[2]);
	A3DVECTOR3 vDir(dir[0], dir[1], dir[2]);

	CECSkillCollisionShape* pShape = CECSkillCollisionShape::Create(ci);
	pShape->SetPosDir(vPos, vDir);
	pShape->SetRatio(1.0f);
	pShape->SetHeight(0.0f);

	return pShape;
}

HAPI void SC_DestroyShape(CECSkillCollisionShape* shape)
{
	delete shape;
}

HAPI bool SC_IsCollideWithShape(CECSkillCollisionShape* shape, float pos[3], float radius)
{
	A3DVECTOR3 vPos(pos[0], pos[1], pos[2]);
	CECSkillCollisionObjectCycle obj(vPos, radius);
	return shape->IsCollided(&obj);
}
