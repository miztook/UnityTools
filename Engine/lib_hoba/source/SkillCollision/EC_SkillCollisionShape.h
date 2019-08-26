#ifndef _EC_SkillCollisionShape_H_
#define _EC_SkillCollisionShape_H_

#include "EC_SkillCollisionData.h"
#include "EC_SkillCollisionObject.h"
#include "A3DTypes.h"
#include "A3DVector.h"
#include "A3DFuncs.h"
#include "A3DQuaternion.h"

class CECSkillCollisionObject;
class CECSkillCollisionShape;

enum Enum_SkillCollisionShapeType : int
{
	SKILLCOLLISIONSHAPE_RECT,
	SKILLCOLLISIONSHAPE_FAN,
	SKILLCOLLISIONSHAPE_CYCLE,
	SKILLCOLLISIONSHAPE_NUM
};

enum Enum_SkillCollisionShapeDir : int
{
	SKILLCOLLISIONSHAPEDIR_DEFAULT,
	SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT,
	SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT,
	SKILLCOLLISIONSHAPEDIR_BACKTOFRONT,
	SKILLCOLLISIONSHAPEDIR_FRONTTOBACK,
	SKILLCOLLISIONSHAPEDIR_RANDOM,
	SKILLCOLLISIONSHAPEDIR_NUM
};

enum Enum_SkillCollisionHeightScope : int
{
	SKILLCOLLISIONHEIGHTSCOPE_LAND	= 0x01,
	SKILLCOLLISIONHEIGHTSCOPE_AIR	= 0x02,
	SKILLCOLLISIONHEIGHTSCOPE_ALL	= 0xFF
};

typedef struct _SKILLCOLLISIONSHAPE_RECT_PARAMS
{
	float	m_fLength;
	float	m_fWidth;
} SKILLCOLLISIONSHAPE_RECT_PARAMS, * PSKILLCOLLISIONSHAPE_RECT_PARAMS;

typedef struct _SKILLCOLLISIONSHAPE_FAN_PARAMS
{
	float	m_fRadius;
	float	m_fHalfRadian;
} SKILLCOLLISIONSHAPE_FAN_PARAMS, * PSKILLCOLLISIONSHAPE_FAN_PARAMS;

typedef struct _SKILLCOLLISIONSHAPE_CYCLE_PARAMS
{
	float	m_fRadius;
} SKILLCOLLISIONSHAPE_CYCLE_PARAMS, * PSKILLCOLLISIONSHAPE_CYCLE_PARAMS;

typedef struct _SKILLCOLLISIONSHAPE_PARAMS
{
	Enum_SkillCollisionShapeDir		m_eDir;
	Enum_SkillCollisionHeightScope	m_eHeightScope;
	union	
	{
		_SKILLCOLLISIONSHAPE_RECT_PARAMS	m_rect_params;
		_SKILLCOLLISIONSHAPE_FAN_PARAMS		m_fan_params;
		_SKILLCOLLISIONSHAPE_CYCLE_PARAMS	m_cycle_params;
	};
} SKILLCOLLISIONSHAPE_PARAMS, * PSKILLCOLLISIONSHAPE_PARAMS;

class CECSkillCollisionShape
{
public:

	explicit CECSkillCollisionShape(Enum_SkillCollisionShapeType eType, const _SKILLCOLLISIONSHAPE_PARAMS& c_params) : m_eType(eType)
		, m_eDir(c_params.m_eDir) {}
	virtual ~CECSkillCollisionShape() {}

	static CECSkillCollisionShape* Create( Enum_SkillCollisionShapeType eType, const _SKILLCOLLISIONSHAPE_PARAMS& c_params );
	static CECSkillCollisionShape* Create( const COLLISION_INST& c_ci );

	static Enum_SkillCollisionShapeType MakeParams(const COLLISION_INST& c_ci, _SKILLCOLLISIONSHAPE_PARAMS& c_params);

	Enum_SkillCollisionShapeType GetType() const { return m_eType; }
	Enum_SkillCollisionShapeDir GetDirEnum() const { return m_eDir; }

	bool SetPosDir( const A3DVECTOR3& c_vPos, const A3DVECTOR3& c_vDir );
	const A3DVECTOR3& GetPos() const { return m_vPos; }
	const A3DVECTOR3& GetDir() const { return m_vDir; }

	float GetRatio() const { return m_fRatio; }
	void SetRatio( float fRatio ) { m_fRatio = fRatio; }

	float GetHeight() const { return m_fHeight; }
	void SetHeight( float fHeight ) { m_fHeight = fHeight; }

	virtual CECSkillCollisionShape* Clone() const = 0;
	virtual bool IsCollided( CECSkillCollisionObject* pObject ) const = 0;
	virtual A3DVECTOR3 GetCollideDir( const A3DVECTOR3& c_vPos ) const = 0;

	void CopyDataFrom(const CECSkillCollisionShape* pSrc);

protected:

	Enum_SkillCollisionShapeType	m_eType;
	Enum_SkillCollisionShapeDir		m_eDir;
	Enum_SkillCollisionHeightScope	m_eHeightScope;

	A3DVECTOR3	m_vPos;
	A3DVECTOR3	m_vDir;
	float		m_fRatio;
	float		m_fHeight;
};

// --------------------------------------------------------------------------------------------------------------------
// class CECSkillCollisionShapeRect
// ====================================================================================================================
class CECSkillCollisionShapeRect : public CECSkillCollisionShape
{
public:

	explicit CECSkillCollisionShapeRect(const _SKILLCOLLISIONSHAPE_PARAMS& c_params)
		: CECSkillCollisionShape(SKILLCOLLISIONSHAPE_RECT, c_params)
		, m_fLength(c_params.m_rect_params.m_fLength)
		, m_fWidth(c_params.m_rect_params.m_fWidth) {}
	virtual ~CECSkillCollisionShapeRect() {}

	virtual CECSkillCollisionShape* Clone() const;
	virtual bool IsCollided(CECSkillCollisionObject* pObject) const;
	virtual A3DVECTOR3 GetCollideDir(const A3DVECTOR3& c_vPos) const;

protected:

	bool GetCenterAndExt(A3DVECTOR3& vCenter, A3DVECTOR3& vExt) const;

public:
	float	m_fLength;
	float	m_fWidth;
};

// --------------------------------------------------------------------------------------------------------------------
// class CECSkillCollisionShapeFan
// ====================================================================================================================
class CECSkillCollisionShapeFan : public CECSkillCollisionShape
{
public:

	explicit CECSkillCollisionShapeFan(const _SKILLCOLLISIONSHAPE_PARAMS& c_params)
		: CECSkillCollisionShape(SKILLCOLLISIONSHAPE_FAN, c_params)
		, m_fRadius(c_params.m_fan_params.m_fRadius)
		, m_fHalfRadian(c_params.m_fan_params.m_fHalfRadian)
	{
	}

	virtual ~CECSkillCollisionShapeFan() {}

	virtual CECSkillCollisionShape* Clone() const;
	virtual bool IsCollided(CECSkillCollisionObject* pObject) const;
	virtual A3DVECTOR3 GetCollideDir(const A3DVECTOR3& c_vPos) const;

public:
	float	m_fRadius;
	float	m_fHalfRadian;
};

// --------------------------------------------------------------------------------------------------------------------
// class CECSkillCollisionShapeCycle
// ====================================================================================================================
class CECSkillCollisionShapeCycle : public CECSkillCollisionShape
{
public:

	explicit CECSkillCollisionShapeCycle(const _SKILLCOLLISIONSHAPE_PARAMS& c_params)
		: CECSkillCollisionShape(SKILLCOLLISIONSHAPE_CYCLE, c_params)
		, m_fRadius(c_params.m_cycle_params.m_fRadius)
	{
	}

	virtual ~CECSkillCollisionShapeCycle() {}

	virtual CECSkillCollisionShape* Clone() const;
	virtual bool IsCollided(CECSkillCollisionObject* pObject) const;
	virtual A3DVECTOR3 GetCollideDir(const A3DVECTOR3& c_vPos) const;

public:
	float	m_fRadius;
};

inline bool CECSkillCollisionShapeRect::GetCenterAndExt(A3DVECTOR3& vCenter, A3DVECTOR3& vExt) const
{
	static const float sc_fBoxHalfHeight = 0.01f;

	A3DVECTOR3 vRight = CrossProduct(A3DVECTOR3::UnitY(), m_vDir);
	vRight.Normalize();
	A3DVECTOR3 vLeft = -vRight;

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
	{
		vCenter = m_vPos + m_vDir * m_fLength / 2 + vLeft * (1 - m_fRatio) * m_fWidth / 2;
		vExt = A3DVECTOR3(m_fRatio * m_fWidth / 2, sc_fBoxHalfHeight, m_fLength / 2);
	}
	break;
	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
	{
		vCenter = m_vPos + m_vDir * m_fLength / 2 + vRight * (1 - m_fRatio) * m_fWidth / 2;
		vExt = A3DVECTOR3(m_fRatio * m_fWidth / 2, sc_fBoxHalfHeight, m_fLength / 2);
	}
	break;
	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
	{
		vCenter = m_vPos + m_vDir * m_fRatio * m_fLength / 2;
		vExt = A3DVECTOR3(m_fWidth / 2, sc_fBoxHalfHeight, m_fRatio * m_fLength / 2);
	}
	break;
	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
	{
		vCenter = m_vPos + m_vDir * (1 - m_fRatio / 2) * m_fLength;
		vExt = A3DVECTOR3(m_fWidth / 2, sc_fBoxHalfHeight, m_fRatio * m_fLength / 2);
	}
	break;
	default:
		ASSERT(0);
		return false;
	}
	vCenter.y += m_fHeight;
	return true;
}

inline CECSkillCollisionShape* CECSkillCollisionShapeRect::Clone() const
{
	_SKILLCOLLISIONSHAPE_PARAMS params;
	params.m_eDir = m_eDir;
	params.m_rect_params.m_fLength = m_fLength;
	params.m_rect_params.m_fWidth = m_fWidth;

	CECSkillCollisionShapeRect* pRect = new CECSkillCollisionShapeRect(params);
	pRect->CopyDataFrom(this);
	return pRect;
}

inline void CECSkillCollisionShape::CopyDataFrom(const CECSkillCollisionShape* pSrc)
{
	m_vPos = pSrc->GetPos();
	m_vDir = pSrc->GetDir();
	m_fRatio = pSrc->GetRatio();
	m_fHeight = pSrc->GetHeight();
}

inline bool CECSkillCollisionShapeRect::IsCollided(CECSkillCollisionObject* pObject) const
{
	if (!pObject)
		return false;

	A3DVECTOR3 vCenter;
	A3DVECTOR3 vExt;
	if (!GetCenterAndExt(vCenter, vExt))
		return false;

	A3DMATRIX4 matRectTrans = a3d_TransformMatrix(m_vDir, A3DVECTOR3::UnitY(), vCenter);
	A3DMATRIX4 matInvTrans = a3d_InverseTM(matRectTrans);

	A3DVECTOR3 vPosInRectSpace = matInvTrans * pObject->GetPosForSC();

	switch (pObject->GetTypeForSC())
	{
	case SKILLCOLLISIONOBJECT_CYCLE:
	{
		CECSkillCollisionObjectCycle* pCycle = static_cast<CECSkillCollisionObjectCycle*>(pObject);

		if (fabs(vPosInRectSpace.x) - pCycle->GetRadiusForSC() > vExt.x ||
			fabs(vPosInRectSpace.z) - pCycle->GetRadiusForSC() > vExt.z)
			return false;
	}
	return true;
	default:
		ASSERT(0);
		return false;
	}
}

inline A3DVECTOR3 CECSkillCollisionShapeRect::GetCollideDir(const A3DVECTOR3& c_vPos) const
{
	A3DVECTOR3 vDir(0);

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
		return Normalize(CrossProduct(A3DVECTOR3::UnitY(), m_vDir));

	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
		return Normalize(CrossProduct(m_vDir, A3DVECTOR3::UnitY()));

	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
		return m_vDir;

	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
		return -m_vDir;

	default:
		ASSERT(0);
		return vDir;
	}
}

inline static bool _IsFanCollidedWithObject(const A3DVECTOR3& c_vPos, const A3DVECTOR3& c_vDir, float fRadius, float fHalfRadian, CECSkillCollisionObject* pObject)
{
	if (!pObject)
		return false;

	A3DVECTOR3 vDelta = pObject->GetPosForSC() - c_vPos;
	vDelta.y = 0;
	float fDistance = vDelta.Normalize();

	switch (pObject->GetTypeForSC())
	{
	case SKILLCOLLISIONOBJECT_CYCLE:
	{
		CECSkillCollisionObjectCycle* pCycle = static_cast<CECSkillCollisionObjectCycle*>(pObject);

		float fSideLen = sqrt(fDistance * fDistance - pCycle->GetRadiusForSC() * pCycle->GetRadiusForSC());
		if (DotProduct(vDelta, c_vDir) < cos(fHalfRadian) * fSideLen / fDistance - sin(fHalfRadian) * pCycle->GetRadiusForSC() / fDistance)
			return false;
		if (fDistance > fRadius + pCycle->GetRadiusForSC())
			return false;
	}
	return true;
	default:
		ASSERT(0);
		return false;
	}
}

inline CECSkillCollisionShape* CECSkillCollisionShapeFan::Clone() const
{
	_SKILLCOLLISIONSHAPE_PARAMS params;
	params.m_eDir = m_eDir;
	params.m_fan_params.m_fRadius = m_fRadius;
	params.m_fan_params.m_fHalfRadian = m_fHalfRadian;

	CECSkillCollisionShapeFan* pFan = new CECSkillCollisionShapeFan(params);
	pFan->CopyDataFrom(this);
	return pFan;
}

inline bool CECSkillCollisionShapeFan::IsCollided(CECSkillCollisionObject* pObject) const
{
	if (!pObject)
		return false;

	A3DVECTOR3 vDir = m_vDir;
	float fRadius = m_fRadius;
	float fHalfRadian = m_fHalfRadian;

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
	{
		A3DQUATERNION qRot(A3DVECTOR3::UnitY(), -m_fHalfRadian * (1 - m_fRatio));
		qRot.Normalize();
		vDir = qRot * vDir;
		fHalfRadian *= m_fRatio;
	}
	return _IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
	{
		A3DQUATERNION qRot(A3DVECTOR3::UnitY(), m_fHalfRadian * (1 - m_fRatio));
		qRot.Normalize();
		vDir = qRot * vDir;
		fHalfRadian *= m_fRatio;
	}
	return _IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
		fRadius *= m_fRatio;
		return _IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
	{
		if (!_IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject))
			return false;
		fRadius *= m_fRatio;
	}
	return !_IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	default:
		ASSERT(0);
		return false;
	}
}

inline A3DVECTOR3 CECSkillCollisionShapeFan::GetCollideDir(const A3DVECTOR3& c_vPos) const
{
	A3DVECTOR3 vDir(0);

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
	{
		A3DQUATERNION qRotL(A3DVECTOR3::UnitY(), -m_fHalfRadian * (1 - m_fRatio));
		qRotL.Normalize();
		vDir = qRotL * m_vDir;
		float fHalfRadian = m_fHalfRadian * m_fRatio;

		A3DQUATERNION qRotR(A3DVECTOR3::UnitY(), fHalfRadian);
		qRotR.Normalize();
		vDir = qRotR * vDir;
	}
	return Normalize(CrossProduct(A3DVECTOR3::UnitY(), vDir));

	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
	{
		A3DQUATERNION qRotR(A3DVECTOR3::UnitY(), m_fHalfRadian * (1 - m_fRatio));
		qRotR.Normalize();
		vDir = qRotR * m_vDir;
		float fHalfRadian = m_fHalfRadian * m_fRatio;

		A3DQUATERNION qRotL(A3DVECTOR3::UnitY(), -fHalfRadian);
		qRotL.Normalize();
		vDir = qRotL * vDir;
	}
	return Normalize(CrossProduct(vDir, A3DVECTOR3::UnitY()));

	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
		return Normalize(c_vPos - m_vPos);

	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
		return Normalize(m_vPos - c_vPos);

	default:
		ASSERT(0);
		return vDir;
	}
}

inline static bool _IsCycleNearObject(const A3DVECTOR3& c_vCenter, float fRadius, CECSkillCollisionObject* pObject)
{
	if (!pObject)
		return false;

	switch (pObject->GetTypeForSC())
	{
	case SKILLCOLLISIONOBJECT_CYCLE:
	{
		CECSkillCollisionObjectCycle* pCycle = static_cast<CECSkillCollisionObjectCycle*>(pObject);

		if ((pObject->GetPosForSC() - c_vCenter).MagnitudeH() > fRadius + pCycle->GetRadiusForSC())
			return false;
	}
	return true;
	default:
		ASSERT(0);
		return false;
	}
}

inline CECSkillCollisionShape* CECSkillCollisionShapeCycle::Clone() const
{
	_SKILLCOLLISIONSHAPE_PARAMS params;
	params.m_eDir = m_eDir;
	params.m_cycle_params.m_fRadius = m_fRadius;

	CECSkillCollisionShapeCycle* pCycle = new CECSkillCollisionShapeCycle(params);
	pCycle->CopyDataFrom(this);
	return pCycle;
}

inline bool CECSkillCollisionShapeCycle::IsCollided(CECSkillCollisionObject* pObject) const
{
	if (!pObject)
		return false;

	A3DVECTOR3 vDir = m_vDir;
	float fRadius = m_fRadius;
	float fHalfRadian = A3D_PI;

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
	{
		fHalfRadian = A3D_PI * m_fRatio;
		vDir = A3DVECTOR3(sin(-fHalfRadian) * fRadius, 0, cos(-fHalfRadian) * fRadius);
	}
	return _IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
	{
		fHalfRadian = A3D_PI * m_fRatio;
		vDir = A3DVECTOR3(sin(fHalfRadian) * fRadius, 0, cos(fHalfRadian) * fRadius);
	}
	return _IsFanCollidedWithObject(m_vPos, vDir, fRadius, fHalfRadian, pObject);

	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
		fRadius *= m_fRatio;
		return _IsCycleNearObject(m_vPos, fRadius, pObject);

	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
	{
		if (!_IsCycleNearObject(m_vPos, fRadius, pObject))
			return false;
		fRadius *= m_fRatio;
	}
	return !_IsCycleNearObject(m_vPos, fRadius, pObject);

	default:
		ASSERT(0);
		return false;
	}
	return true;
}

inline A3DVECTOR3 CECSkillCollisionShapeCycle::GetCollideDir(const A3DVECTOR3& c_vPos) const
{
	A3DVECTOR3 vDir(0);

	switch (m_eDir)
	{
	case SKILLCOLLISIONSHAPEDIR_LEFTTORIGHT:
	{
		float fRadian = A3D_2PI * m_fRatio;
		vDir = A3DVECTOR3(sin(-fRadian) * m_fRadius, 0, cos(-fRadian) * m_fRadius);
	}
	return Normalize(CrossProduct(A3DVECTOR3::UnitY(), vDir));

	case SKILLCOLLISIONSHAPEDIR_RIGHTTOLEFT:
	{
		float fRadian = A3D_2PI * m_fRatio;
		vDir = A3DVECTOR3(sin(fRadian) * m_fRadius, 0, cos(fRadian) * m_fRadius);
	}
	return Normalize(CrossProduct(vDir, A3DVECTOR3::UnitY()));

	case SKILLCOLLISIONSHAPEDIR_DEFAULT:
	case SKILLCOLLISIONSHAPEDIR_BACKTOFRONT:
		return Normalize(c_vPos - m_vPos);

	case SKILLCOLLISIONSHAPEDIR_FRONTTOBACK:
		return Normalize(m_vPos - c_vPos);

	default:
		ASSERT(0);
		return vDir;
	}
}

// --------------------------------------------------------------------------------------------------------------------
// class CECSkillCollisionShape
// ====================================================================================================================
inline CECSkillCollisionShape* CECSkillCollisionShape::Create(Enum_SkillCollisionShapeType eType, const _SKILLCOLLISIONSHAPE_PARAMS& c_params)
{
	switch (eType)
	{
	case SKILLCOLLISIONSHAPE_RECT:
		return new CECSkillCollisionShapeRect(c_params);

	case SKILLCOLLISIONSHAPE_FAN:
		return new CECSkillCollisionShapeFan(c_params);

	case SKILLCOLLISIONSHAPE_CYCLE:
		return new CECSkillCollisionShapeCycle(c_params);

	default:
		ASSERT(0);
		return 0;
	}
}

inline CECSkillCollisionShape* CECSkillCollisionShape::Create(const COLLISION_INST& c_ci)
{
	_SKILLCOLLISIONSHAPE_PARAMS params;

	Enum_SkillCollisionShapeDir eDir = static_cast<Enum_SkillCollisionShapeDir>(c_ci.perform_data.direction);
	if (eDir == SKILLCOLLISIONSHAPEDIR_RANDOM)
	{
		int iRand = a_Random(0, SKILLCOLLISIONSHAPEDIR_RANDOM - 1);
		eDir = static_cast<Enum_SkillCollisionShapeDir>(iRand);
	}
	params.m_eDir = eDir;
	params.m_eHeightScope = SKILLCOLLISIONHEIGHTSCOPE_LAND;

	Enum_SkillCollisionShapeType eType = static_cast<Enum_SkillCollisionShapeType>(c_ci.perform_data.target_affect_obj);
	switch (eType)
	{
	case SKILLCOLLISIONSHAPE_RECT:
	{
		params.m_rect_params.m_fWidth = c_ci.perform_data.target_affect_radius;
		params.m_rect_params.m_fLength = c_ci.perform_data.target_affect_lenght;
	}
	break;
	case SKILLCOLLISIONSHAPE_FAN:
	{
		params.m_fan_params.m_fRadius = c_ci.perform_data.target_affect_radius;
		params.m_fan_params.m_fHalfRadian = DEG2RAD(c_ci.perform_data.target_affect_angle);
	}
	break;
	case SKILLCOLLISIONSHAPE_CYCLE:
	{
		params.m_cycle_params.m_fRadius = c_ci.perform_data.target_affect_radius;
	}
	break;
	default:
		ASSERT(0);
		return NULL;
	}
	return Create(eType, params);
}

inline Enum_SkillCollisionShapeType CECSkillCollisionShape::MakeParams(const COLLISION_INST& c_ci, _SKILLCOLLISIONSHAPE_PARAMS& params)
{
	Enum_SkillCollisionShapeDir eDir = static_cast<Enum_SkillCollisionShapeDir>(c_ci.perform_data.direction);
	if (eDir == SKILLCOLLISIONSHAPEDIR_RANDOM)
	{
		int iRand = a_Random(0, SKILLCOLLISIONSHAPEDIR_RANDOM - 1);
		eDir = static_cast<Enum_SkillCollisionShapeDir>(iRand);
	}
	params.m_eDir = eDir;
	params.m_eHeightScope = SKILLCOLLISIONHEIGHTSCOPE_LAND;

	Enum_SkillCollisionShapeType eType = static_cast<Enum_SkillCollisionShapeType>(c_ci.perform_data.target_affect_obj);
	switch (eType)
	{
	case SKILLCOLLISIONSHAPE_RECT:
	{
		params.m_rect_params.m_fWidth = c_ci.perform_data.target_affect_radius;
		params.m_rect_params.m_fLength = c_ci.perform_data.target_affect_lenght;
	}
	break;
	case SKILLCOLLISIONSHAPE_FAN:
	{
		params.m_fan_params.m_fRadius = c_ci.perform_data.target_affect_radius;
		params.m_fan_params.m_fHalfRadian = DEG2RAD(c_ci.perform_data.target_affect_angle);
	}
	break;
	case SKILLCOLLISIONSHAPE_CYCLE:
	{
		params.m_cycle_params.m_fRadius = c_ci.perform_data.target_affect_radius;
	}
	break;
	default:
		ASSERT(0);
	}

	return eType;
}

inline bool CECSkillCollisionShape::SetPosDir(const A3DVECTOR3& c_vPos, const A3DVECTOR3& c_vDir)
{
	m_vPos = c_vPos;
	m_vDir = c_vDir;
	m_vDir.Normalize();

	return true;
}

#endif