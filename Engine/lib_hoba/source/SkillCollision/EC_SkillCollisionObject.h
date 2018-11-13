#ifndef _EC_SkillCollisionObject_H_
#define _EC_SkillCollisionObject_H_

#include "ATypes.h"
#include "A3DVector.h"

class CECSkillCollisionObject;

enum Enum_SkillCollisionObjectType
{
	SKILLCOLLISIONOBJECT_CYCLE,
	SKILLCOLLISIONOBJECT_NUM
};

class CECSkillCollisionObject
{
public:
	explicit CECSkillCollisionObject(Enum_SkillCollisionObjectType eType, const A3DVECTOR3& pos, const A3DVECTOR3& dir) : m_eType(eType), m_pos(pos)
	{
		m_dir = dir;
		m_dir.Normalize();
	}

	virtual ~CECSkillCollisionObject() {}

	Enum_SkillCollisionObjectType GetTypeForSC() const { return m_eType; }

	A3DVECTOR3 GetPosForSC() const { return m_pos; }
	A3DVECTOR3 GetDirForSC() const { return m_dir; }

protected:

	Enum_SkillCollisionObjectType	m_eType;
	A3DVECTOR3 m_pos;
	A3DVECTOR3 m_dir;
};

class CECSkillCollisionObjectCycle : public CECSkillCollisionObject
{
public:
	CECSkillCollisionObjectCycle(A3DVECTOR3 pos, float radius) : CECSkillCollisionObject(SKILLCOLLISIONOBJECT_CYCLE, pos, A3DVECTOR3(1, 0, 0)), m_fRadius(radius)
	{}

	virtual ~CECSkillCollisionObjectCycle() {}

	void SetRadiusForSC( float fRadius ) { m_fRadius = fRadius; }
	float GetRadiusForSC() const { return m_fRadius; }

protected:

	float	m_fRadius;
};

#endif