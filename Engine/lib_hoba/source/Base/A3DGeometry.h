#ifndef _A3DGEOMETRY_H_
#define _A3DGEOMETRY_H_

#include "ATypes.h"
#include "A3DVector.h"

///////////////////////////////////////////////////////////////////////////
//
//	Define and Macro
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Types and Global variables
//
///////////////////////////////////////////////////////////////////////////

class A3DOBB;

///////////////////////////////////////////////////////////////////////////
//
//	Declare of Global functions
//
///////////////////////////////////////////////////////////////////////////

/*	Create a indexed sphere mesh. This function build a sphere mesh whose center locates at
	vPos and has radius specified by fRadius. Sphere's segments are specified by iRow (>= 3)
	and iCol (>= 3). The final mesh will have below vertex number and index number
	vertex number: (2 + (iRow-1) * iCol)
	index number: ((iRow-1) * iCol * 6)
	*/
bool a3d_CreateIndexedSphere(const A3DVECTOR3& vPos, float fRadius, int iRow, int iCol,
	A3DVECTOR3* aVerts, int iMaxVertNum, unsigned short* aIndices, int iMaxIdxNum);

/*	Create a indexed taper mesh. This function build a taper mesh whose top locates at
	vPos and vDir specified it's height axis.
	The final mesh will have below vertex number and index number

	if (bHasBottom == true)
	{
	vertex number: (iNumSeg + 1)
	index number: iNumSeg * 3 + (iNumSeg - 2) * 3
	}
	else
	{
	vertex number: (iNumSeg + 1)
	index number: iNumSeg * 3
	}

	vDir: normalized direction from top position to center of bottom
	fHeight: distance between taper top and bottom plane
	fRadius: radius of bottom circle
	iNumSeg: segment of bottom circle, >= 3
	bHasBottom: true, has bottom cap; false, don't has bottom cap
	*/
bool a3d_CreateIndexedTaper(const A3DVECTOR3& vPos, const A3DVECTOR3& vDir,
	float fRadius, float fHeight, int iNumSeg, bool bHasBottom,
	A3DVECTOR3* aVerts, int iMaxVertNum, unsigned short* aIndices, int iMaxIdxNum);

//	Create a indexed box that has 8 vertices and 36 indices
//	vExtent: half border length
bool a3d_CreateIndexedBox(const A3DVECTOR3& vPos, const A3DVECTOR3& vX,
	const A3DVECTOR3& vY, const A3DVECTOR3& vZ, const A3DVECTOR3& vExtent,
	A3DVECTOR3* aVerts, unsigned short* aIndices);

///////////////////////////////////////////////////////////////////////////
//
//	Class A3DAABB
//
///////////////////////////////////////////////////////////////////////////

//	Axis-Aligned Bounding Box
class A3DAABB
{
public:		//	Constructors and Destructors

	A3DAABB()  { Clear(); }

	A3DAABB(const A3DAABB& aabb) :
		Center(aabb.Center),
		Extents(aabb.Extents),
		Mins(aabb.Mins),
		Maxs(aabb.Maxs) {}

	A3DAABB(const A3DVECTOR3& vMins, const A3DVECTOR3& vMaxs) :
		Mins(vMins),
		Maxs(vMaxs),
		Center((vMins + vMaxs) * 0.5f)
	{
		Extents = vMaxs - Center;
	}

public:		//	Attributes

	A3DVECTOR3	Center;
	A3DVECTOR3	Extents;
	A3DVECTOR3	Mins;
	A3DVECTOR3	Maxs;

public:		//	Operations

	static A3DAABB& UnitBox() { static A3DAABB m(A3DVECTOR3(-1.0f, -1.0f, -1.0f), A3DVECTOR3(1.0f, 1.0f, 1.0f));  return m; }

	//	Clear aabb
	void Clear()
	{
		Mins.Set(999999.0f, 999999.0f, 999999.0f);
		Maxs.Set(-999999.0f, -999999.0f, -999999.0f);
	}

	//	Add a vertex to aabb
	void AddVertex(const A3DVECTOR3& v);

	//	Build AABB from obb
	void Build(const A3DOBB& obb);
	//	Merge two aabb
	void Merge(const A3DAABB& subAABB);

	//	Compute Mins and Maxs
	void CompleteMinsMaxs()
	{
		Mins = Center - Extents;
		Maxs = Center + Extents;
	}

	//	Compute Center and Extents
	void CompleteCenterExts()
	{
		Center = (Mins + Maxs) * 0.5f;
		Extents = Maxs - Center;
	}

	//	Check whether a point is in this aabb
	bool IsPointIn(const A3DVECTOR3& v) const
	{
		if (v.x > Maxs.x || v.x < Mins.x ||
			v.y > Maxs.y || v.y < Mins.y ||
			v.z > Maxs.z || v.z < Mins.z)
			return false;

		return true;
	}

	//	Check whether another aabb is in this aabb
	bool IsAABBIn(const A3DAABB& aabb) const;

	//	Build AABB from vertices
	void Build(const A3DVECTOR3* aVertPos, int iNumVert);
	//	Get vertices of aabb
	void GetVertices(A3DVECTOR3* aVertPos, unsigned short* aIndices, bool bWire) const;

	bool IsValid() const { return Mins.x <= Maxs.x && Mins.y <= Maxs.y && Mins.z <= Maxs.z; }

	static const A3DAABB& Invalid() { static A3DAABB m; return m; }

	float GetRadius() const { return (Extents.x + Extents.y + Extents.z) * 0.333f; }

	float GetRadiusH() const { return (Extents.x + Extents.z) * 0.5f; }

	bool IntersectsWithLine(const A3DVECTOR3& vStart, const A3DVECTOR3& vEnd) const;
};

///////////////////////////////////////////////////////////////////////////
//
//	Class A3DOBB
//
///////////////////////////////////////////////////////////////////////////

//	Oriented Bounding Box
class A3DOBB
{
public:		//	Constructors and Destructors

	A3DOBB() { Clear(); }
	A3DOBB(const A3DOBB& obb) :
		Center(obb.Center),
		XAxis(obb.XAxis),
		YAxis(obb.YAxis),
		ZAxis(obb.ZAxis),
		ExtX(obb.ExtX),
		ExtY(obb.ExtY),
		ExtZ(obb.ExtZ),
		Extents(obb.Extents) {}

public:		//	Attributes

	A3DVECTOR3	Center;
	A3DVECTOR3	XAxis;
	A3DVECTOR3	YAxis;
	A3DVECTOR3	ZAxis;
	A3DVECTOR3	ExtX;
	A3DVECTOR3	ExtY;
	A3DVECTOR3	ExtZ;
	A3DVECTOR3	Extents;

public:		//	Operations

	//	Check whether a point is in this aabb
	bool IsPointIn(const A3DVECTOR3& v) const;

	//	Compute ExtX, ExtY, ExtZ
	void CompleteExtAxis()
	{
		ExtX = XAxis * Extents.x;
		ExtY = YAxis * Extents.y;
		ExtZ = ZAxis * Extents.z;
	}

	//	Clear obb
	void Clear();

	//	Build obb from two obbs
	void Build(const A3DOBB& obb1, const A3DOBB& obb2);
	//	Build obb from vertices
	void Build(const A3DVECTOR3* aVertPos, int nVertCount);
	//	Build obb from aabb
	void Build(const A3DAABB& aabb);
	//	Get vertices of obb
	void GetVertices(A3DVECTOR3* aVertPos, unsigned short* aIndices, bool bWire) const;
};

//	Plane with sign
class A3DPLANE
{
public:		//	Types

	//	Plane type
	enum
	{
		TYPE_BAD = -1,	//	Bad plane
		TYPE_PX = 0,	//	Positive x axis
		TYPE_PY = 1,	//	Positive y axis
		TYPE_PZ = 2,	//	Positive z axis
		TYPE_NX = 3,	//	Negative x axis
		TYPE_NY = 4,	//	Negative y axis
		TYPE_NZ = 5,	//	Negative z axis
		TYPE_MAJORX = 6,	//	Major axis is x
		TYPE_MAJORY = 7,	//	Major axis is y
		TYPE_MAJORZ = 8,	//	Major axis is z
		TYPE_UNKNOWN = 9,	//	unknown
	};

	//	Plane sign flag
	enum
	{
		SIGN_P = 0,	//	Positive
		SIGN_NX = 1,	//	x axis is negative
		SIGN_NY = 2,	//	y axis is negative
		SIGN_NZ = 4,	//	z axis is negative
	};

public:		//	Constructors and Destructors

	A3DPLANE() { fDist = 0.0f; byType = 0; bySignBits = 0; }
	A3DPLANE(const A3DPLANE& p) { vNormal = p.vNormal; fDist = p.fDist; byType = p.byType; bySignBits = p.bySignBits; }
	A3DPLANE(const A3DVECTOR3& n, float d) : vNormal(n) { fDist = d; byType = TYPE_UNKNOWN; bySignBits = SIGN_P; }

public:
	bool operator==(const A3DPLANE& other) const
	{
		if (this == &other) return true;

		return vNormal == other.vNormal && fDist == other.fDist && byType == other.byType && bySignBits == other.bySignBits;
	}

	bool operator!=(const A3DPLANE& other) const
	{
		if (this == &other) return false;

		return vNormal != other.vNormal || fDist != other.fDist || byType != other.byType || bySignBits != other.bySignBits;
	}

	A3DPLANE& operator=(const A3DPLANE& other)
	{
		if (this != &other)
		{
			vNormal = other.vNormal;
			fDist = other.fDist;
			byType = other.byType;
			bySignBits = other.bySignBits;
		}
		return *this;
	}

public:		//	Attributes
	A3DVECTOR3	vNormal;		//	Normal
	float		fDist;			//	d parameter
	unsigned char	byType;			//	Type of plane
	unsigned char	bySignBits;		//	Sign flags

public:		//	Operations

	//	Make plane type
	void MakeType();
	//	Make plane sign-bits
	void MakeSignBits();
	//	Make plane type and sign-bites
	void MakeTypeAndSignBits()
	{
		MakeType();
		MakeSignBits();
	}

	//	Create plane from 3 points
	bool CreatePlane(const A3DVECTOR3& v1, const A3DVECTOR3& v2, const A3DVECTOR3& v3);

	bool GetIntersectionWithLine(const A3DVECTOR3& vStart, const A3DVECTOR3& vEnd, A3DVECTOR3& outIntersection);
};

///////////////////////////////////////////////////////////////////////////
//
//	class A3DCAPSULE
//
///////////////////////////////////////////////////////////////////////////

//	Capsule
class A3DCAPSULE
{
public:		//	Constructors and Destructors

	A3DCAPSULE() { fHalfLen = 0.0f; fRadius = 0.0f; }
	A3DCAPSULE(const A3DCAPSULE& src) :
		vCenter(src.vCenter),
		vAxisX(src.vAxisX),
		vAxisY(src.vAxisY),
		vAxisZ(src.vAxisZ)
	{
		fHalfLen = src.fHalfLen;
		fRadius = src.fRadius;
	}

public:		//	Attributes

	A3DVECTOR3	vCenter;
	A3DVECTOR3	vAxisX;
	A3DVECTOR3	vAxisY;
	A3DVECTOR3	vAxisZ;
	float		fHalfLen;		//	Half length (on Y axis)
	float		fRadius;		//	Radius

public:		//	Operations

	//	Check whether a point is in this capsule
	bool IsPointIn(const A3DVECTOR3& vPos);
};

///////////////////////////////////////////////////////////////////////////
//
//	class A3DCYLINDER
//
///////////////////////////////////////////////////////////////////////////

//	Cylinder
class A3DCYLINDER
{
public:		//	Constructors and Destructors

	A3DCYLINDER() { fHalfLen = 0.0f; fRadius = 0.0f; }
	A3DCYLINDER(const A3DCYLINDER& src) :
		vCenter(src.vCenter),
		vAxisX(src.vAxisX),
		vAxisY(src.vAxisY),
		vAxisZ(src.vAxisZ)
	{
		fHalfLen = src.fHalfLen;
		fRadius = src.fRadius;
	}

public:		//	Attributes

	A3DVECTOR3	vCenter;
	A3DVECTOR3	vAxisX;
	A3DVECTOR3	vAxisY;
	A3DVECTOR3	vAxisZ;
	float		fHalfLen;		//	Half length (on Y axis)
	float		fRadius;		//	Radius

public:		//	Operations

	//	Check whether a point is in this cylinder
	bool IsPointIn(const A3DVECTOR3& vPos);
};

///////////////////////////////////////////////////////////////////////////
//
//	Inline functions
//
///////////////////////////////////////////////////////////////////////////

#endif	//	_A3DGEOMETRY_H_
