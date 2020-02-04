#ifndef _SKILLCOLLISION_EXPORT_H_
#define _SKILLCOLLISION_EXPORT_H_

#include "baseDef.h"

class CECSkillCollisionShape;

HAPI CECSkillCollisionShape* SC_CreateShape(int objType, float radius, float length, float angle, float pos[3], float dir[3]);
HAPI void SC_DestroyShape(CECSkillCollisionShape* shape);
HAPI bool SC_IsCollideWithShape(CECSkillCollisionShape* shape, float pos[3], float radius);

#endif