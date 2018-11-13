#ifndef _A3DCOLLISION_H_
#define _A3DCOLLISION_H_

#include "A3DTypes.h"
#include "A3DGeometry.h"

bool CLS_RayToAABB3(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, const A3DVECTOR3& vMins, const A3DVECTOR3& vMaxs, A3DVECTOR3& vPoint, float* pfFraction, A3DVECTOR3& vNormal);
bool CLS_RayToAABB2(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, float vMins[2], float vMaxs[2], A3DVECTOR3& vPoint);
bool CLS_RayToOBB3(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, const A3DOBB& OBB, A3DVECTOR3& vPoint, float* pfFraction, A3DVECTOR3& vNormal);
bool CLS_RayToTriangle(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, const A3DVECTOR3& v0,
	const A3DVECTOR3& v1, const A3DVECTOR3& v2, A3DVECTOR3& vPoint, bool b2Sides, float* pfFraction = NULL);
bool CLS_RayToPlane(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, const A3DVECTOR3& vPlaneNormal, float fDist, bool b2Sides, A3DVECTOR3& vHitPos, float* pfFraction);
bool CLS_OBBToQuadrangle(const A3DOBB& OBB, const A3DVECTOR3& ov0, const A3DVECTOR3& ov1, const A3DVECTOR3& ov2,
	const A3DVECTOR3& ov3, const A3DVECTOR3& vNormal, float* pfFraction);
int CLS_AABBToPlane(const A3DVECTOR3& vStart, const A3DVECTOR3& vEnd, const A3DVECTOR3& vExts, const A3DPLANE& Plane, float* pfFraction);

int CLS_PlaneAABBOverlap(const A3DVECTOR3& vNormal, float fDist, const A3DVECTOR3& vOrigin, const A3DVECTOR3& vExtents);
int CLS_PlaneAABBOverlap(const A3DPLANE& Plane, const A3DVECTOR3& _vMins, const A3DVECTOR3& _vMaxs);
int CLS_PlaneSphereOverlap(const A3DPLANE& Plane, const A3DVECTOR3& vCenter, float fRadius);
bool CLS_TriangleAABBOverlap(const A3DVECTOR3& _v0, const A3DVECTOR3& _v1, const A3DVECTOR3& _v2, const A3DPLANE& Plane, const A3DAABB& AABB);
bool CLS_AABBAABBOverlap(const A3DVECTOR3& vCenter1, const A3DVECTOR3& vExt1, const A3DVECTOR3& vCenter2, const A3DVECTOR3& vExt2);
bool CLS_RaySphereOverlap(const A3DVECTOR3& vStart, const A3DVECTOR3& vDelta, const A3DVECTOR3& vOrigin, float fRadius);
bool CLS_OBBOBBOverlap(const A3DOBB& obb1, const A3DOBB& obb2);
bool CLS_OBBOBBOverlap(const A3DVECTOR3& vExt1, const A3DVECTOR3& vExt2, const A3DMATRIX4& mat);
bool CLS_AABBOBBOverlap(const A3DVECTOR3& vCenter, const A3DVECTOR3& vExts, const A3DOBB& obb);
bool CLS_AABBSphereOverlap(const A3DAABB& aabb, const A3DVECTOR3& vCenter, float fRadius);
bool CLS_OBBSphereOverlap(const A3DOBB& obb, const A3DVECTOR3& vCenter, float fRadius);

inline int CLS_PlaneSphereOverlap(A3DVECTOR3& vNormal, float fDist, A3DVECTOR3& vCenter, float fRadius)
{
	float fDelta = DotProduct(vCenter, vNormal) - fDist;

	if (fDelta > fRadius)
		return 1;
	else if (fDelta < -fRadius)
		return -1;
	else
		return 0;
}

/*	AABB-OBB overlap test using the separating axis theorem.

	Return true if boxes overlap.

	aabb: aabb's information
	obb: obb's inforamtion
	*/
inline bool CLS_AABBOBBOverlap(const A3DAABB& aabb, const A3DOBB& obb)
{
	return CLS_AABBOBBOverlap(aabb.Center, aabb.Extents, obb);
}

#endif	//	_A3DCOLLISION_H_
