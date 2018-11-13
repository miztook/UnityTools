#include "A3DGeometry.h"
#include "A3DMatrix.h"
#include "A3DFuncs.h"
#include "ATempMemBuffer.h"
#include "A3DMacros.h"

///////////////////////////////////////////////////////////////////////////
//
//	Define and Macro
//
///////////////////////////////////////////////////////////////////////////

#define ROTATE(a,i,j,k,l) g=a.m[i][j]; h=a.m[k][l]; a.m[i][j]=(float)(g-s*(h+g*tau)); a.m[k][l]=(float)(h+s*(g-h*tau));

///////////////////////////////////////////////////////////////////////////
//
//	Reference to External variables and functions
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Local Types and Variables and Global variables
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Local functions
//
///////////////////////////////////////////////////////////////////////////

static A3DMATRIX3 _GetConvarianceMatrix(const A3DVECTOR3* aVertPos, int nVertCount)
{
	int i;
	A3DMATRIX3 Cov;

	double S1[3];
	double S2[3][3];

	S1[0] = S1[1] = S1[2] = 0.0;
	S2[0][0] = S2[1][0] = S2[2][0] = 0.0;
	S2[0][1] = S2[1][1] = S2[2][1] = 0.0;
	S2[0][2] = S2[1][2] = S2[2][2] = 0.0;

	// get center of mass
	for (i = 0; i < nVertCount; i++)
	{
		S1[0] += aVertPos[i].x;
		S1[1] += aVertPos[i].y;
		S1[2] += aVertPos[i].z;

		S2[0][0] += aVertPos[i].x * aVertPos[i].x;
		S2[1][1] += aVertPos[i].y * aVertPos[i].y;
		S2[2][2] += aVertPos[i].z * aVertPos[i].z;
		S2[0][1] += aVertPos[i].x * aVertPos[i].y;
		S2[0][2] += aVertPos[i].x * aVertPos[i].z;
		S2[1][2] += aVertPos[i].y * aVertPos[i].z;
	}

	float n = (float)nVertCount;
	// now get covariances
	Cov.m[0][0] = (float)(S2[0][0] - S1[0] * S1[0] / n) / n;
	Cov.m[1][1] = (float)(S2[1][1] - S1[1] * S1[1] / n) / n;
	Cov.m[2][2] = (float)(S2[2][2] - S1[2] * S1[2] / n) / n;
	Cov.m[0][1] = (float)(S2[0][1] - S1[0] * S1[1] / n) / n;
	Cov.m[1][2] = (float)(S2[1][2] - S1[1] * S1[2] / n) / n;
	Cov.m[0][2] = (float)(S2[0][2] - S1[0] * S1[2] / n) / n;
	Cov.m[1][0] = Cov.m[0][1];
	Cov.m[2][0] = Cov.m[0][2];
	Cov.m[2][1] = Cov.m[1][2];

	return Cov;
}

static void _GetEigenVectors(A3DMATRIX3* vout, A3DVECTOR3* dout, A3DMATRIX3 a)
{
	int n = 3;
	int j, iq, ip, i;
	double tresh, theta, tau, t, sm, s, h, g, c;
	int nrot;
	A3DVECTOR3 b;
	A3DVECTOR3 z;
	A3DMATRIX3 v;
	A3DVECTOR3 d;

	v = a3d_IdentityMatrix3();
	for (ip = 0; ip < n; ip++)
	{
		b.m[ip] = a.m[ip][ip];
		d.m[ip] = a.m[ip][ip];
		z.m[ip] = 0.0;
	}

	nrot = 0;

	for (i = 0; i < 50; i++)
	{
		sm = 0.0;
		for (ip = 0; ip < n; ip++) for (iq = ip + 1; iq < n; iq++) sm += fabs(a.m[ip][iq]);
		if (sm == 0.0)
		{
			v.Transpose();
			*vout = v;
			*dout = d;
			return;
		}

		if (i < 3) tresh = 0.2 * sm / (n*n);
		else tresh = 0.0;

		for (ip = 0; ip < n; ip++)
		{
			for (iq = ip + 1; iq < n; iq++)
			{
				g = 100.0*fabs(a.m[ip][iq]);
				if (i > 3 && fabs(d.m[ip]) + g == fabs(d.m[ip]) && fabs(d.m[iq]) + g == fabs(d.m[iq]))
					a.m[ip][iq] = 0.0;
				else if (fabs(a.m[ip][iq]) > tresh)
				{
					h = d.m[iq] - d.m[ip];
					if (fabs(h) + g == fabs(h))
						t = (a.m[ip][iq]) / h;
					else
					{
						theta = 0.5*h / (a.m[ip][iq]);
						t = 1.0 / (fabs(theta) + sqrt(1.0 + theta*theta));
						if (theta < 0.0) t = -t;
					}
					c = 1.0 / sqrt(1 + t*t);
					s = t*c;
					tau = s / (1.0 + c);
					h = t*a.m[ip][iq];
					z.m[ip] -= (float)h;
					z.m[iq] += (float)h;
					d.m[ip] -= (float)h;
					d.m[iq] += (float)h;
					a.m[ip][iq] = 0.0;
					for (j = 0; j < ip; j++) { ROTATE(a, j, ip, j, iq); }
					for (j = ip + 1; j < iq; j++) { ROTATE(a, ip, j, j, iq); }
					for (j = iq + 1; j < n; j++) { ROTATE(a, ip, j, iq, j); }
					for (j = 0; j < n; j++) { ROTATE(v, j, ip, j, iq); }
					nrot++;
				}
			}
		}
		for (ip = 0; ip < n; ip++)
		{
			b.m[ip] += z.m[ip];
			d.m[ip] = b.m[ip];
			z.m[ip] = 0.0;
		}
	}

	v.Transpose();
	*vout = v;
	*dout = d;
	return;
}

//	return an OBB extracing from the vertices;
static A3DMATRIX3 _GetOBBOrientation(const A3DVECTOR3* aVertPos, int nVertCount)
{
	A3DMATRIX3 Cov;

	if (nVertCount <= 0)
		return a3d_IdentityMatrix3();

	Cov = _GetConvarianceMatrix(aVertPos, nVertCount);

	// now get eigenvectors
	A3DMATRIX3 Evecs;
	A3DVECTOR3 Evals;
	_GetEigenVectors(&Evecs, &Evals, Cov);

	return Evecs;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement A3DAABB
//
///////////////////////////////////////////////////////////////////////////

//	Add a vertex to aabb
void A3DAABB::AddVertex(const A3DVECTOR3& v)
{
	for (int i = 0; i < 3; i++)
	{
		if (v.m[i] < Mins.m[i])
			Mins.m[i] = v.m[i];

		if (v.m[i] > Maxs.m[i])
			Maxs.m[i] = v.m[i];
	}
}

//	Expand aabb
void A3DAABB::Build(const A3DOBB& obb)
{
	Clear();
	a3d_ExpandAABB(Mins, Maxs, obb);
	CompleteCenterExts();
}

//	Expand aabb
void A3DAABB::Merge(const A3DAABB& subAABB)
{
	Mins = a3d_VecMin(Mins, subAABB.Mins);
	Maxs = a3d_VecMax(Maxs, subAABB.Maxs);
	CompleteCenterExts();
}

//	Check whether another aabb is in this aabb
bool A3DAABB::IsAABBIn(const A3DAABB& aabb) const
{
	A3DVECTOR3 vDelta = aabb.Center - Center;

	vDelta.x = (float)fabs(vDelta.x);
	if (vDelta.x + aabb.Extents.x > Extents.x)
		return false;

	vDelta.y = (float)fabs(vDelta.y);
	if (vDelta.y + aabb.Extents.y > Extents.y)
		return false;

	vDelta.z = (float)fabs(vDelta.z);
	if (vDelta.z + aabb.Extents.z > Extents.z)
		return false;

	return true;
}

//	Build AABB from vertices
void A3DAABB::Build(const A3DVECTOR3* aVertPos, int iNumVert)
{
	Clear();

	if (iNumVert <= 0)
		return;

	for (int i = 0; i < iNumVert; i++)
	{
		Maxs = a3d_VecMax(Maxs, aVertPos[i]);
		Mins = a3d_VecMin(Mins, aVertPos[i]);
	}

	CompleteCenterExts();
}

//	Get vertices of aabb
void A3DAABB::GetVertices(A3DVECTOR3* aVertPos, unsigned short* aIndices, bool bWire) const
{
	A3DOBB obb;

	obb.Center = Center;
	obb.Extents = Extents;
	obb.XAxis.Set(1.0f, 0.0f, 0.0f);
	obb.YAxis.Set(0.0f, 1.0f, 0.0f);
	obb.ZAxis.Set(0.0f, 0.0f, 1.0f);
	obb.CompleteExtAxis();

	obb.GetVertices(aVertPos, aIndices, bWire);
}

bool A3DAABB::IntersectsWithLine(const A3DVECTOR3& vStart, const A3DVECTOR3& vEnd) const
{
	if (!IsValid())
		return false;

	A3DVECTOR3 vLineMiddle = (vStart + vEnd) * 0.5f;
	A3DVECTOR3 vLineVect = vEnd - vStart;
	float fHalfLength = vLineVect.Magnitude() * 0.5f;

	const A3DVECTOR3 e = (Maxs - Mins) * 0.5f;
	const A3DVECTOR3 t = (Mins + e) - vLineMiddle;
	float r;
	const A3DVECTOR3 n = Normalize(vLineVect);

	if ((fabs(t.x) > e.x + fHalfLength * fabs(n.x)) ||
		(fabs(t.y) > e.y + fHalfLength * fabs(n.y)) ||
		(fabs(t.z) > e.z + fHalfLength * fabs(n.z)))
		return false;

	r = e.y * (float)fabs(vLineVect.z) + e.z * (float)fabs(vLineVect.y);
	if (fabs(t.y*vLineVect.z - t.z*vLineVect.y) > r)
		return false;

	r = e.x * (float)fabs(vLineVect.z) + e.z * (float)fabs(vLineVect.x);
	if (fabs(t.z*vLineVect.x - t.x*vLineVect.z) > r)
		return false;

	r = e.x * (float)fabs(vLineVect.y) + e.y * (float)fabs(vLineVect.x);
	if (fabs(t.x*vLineVect.y - t.y*vLineVect.x) > r)
		return false;

	return true;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement A3DOBB
//
///////////////////////////////////////////////////////////////////////////

//	Check whether a point is in this obb
bool A3DOBB::IsPointIn(const A3DVECTOR3& v) const
{
	A3DVECTOR3 vd = v - Center;

	//	Transfrom point to obb space
	float d = DotProduct(XAxis, vd);
	if (d < -Extents.x || d > Extents.x)
		return false;

	d = DotProduct(YAxis, vd);
	if (d < -Extents.y || d > Extents.y)
		return false;

	d = DotProduct(ZAxis, vd);
	if (d < -Extents.z || d > Extents.z)
		return false;

	return true;
}

//	Clear obb
void A3DOBB::Clear()
{
	memset(this, 0, sizeof(A3DOBB));
}

//	Build obb from two obbs
void A3DOBB::Build(const A3DOBB& obb1, const A3DOBB& obb2)
{
	Clear();

	A3DVECTOR3 aVertPos[16];
	obb1.GetVertices(&aVertPos[0], NULL, true);
	obb2.GetVertices(&aVertPos[8], NULL, true);

	A3DMATRIX3 matTransform = _GetOBBOrientation(aVertPos, 16);
	//	For matTransform is orthogonal, so the inverse matrix is just rotate it;
	matTransform.Transpose();

	A3DVECTOR3 vecMin = aVertPos[0] * matTransform;
	A3DVECTOR3 vecMax = vecMin;

	for (int i = 1; i < 16; i++)
	{
		A3DVECTOR3 vecThis = aVertPos[i] * matTransform;

		vecMax = a3d_VecMax(vecMax, vecThis);
		vecMin = a3d_VecMin(vecMin, vecThis);
	}

	matTransform.Transpose();

	A3DVECTOR3 row0 = matTransform.GetRow(0);
	A3DVECTOR3 row1 = matTransform.GetRow(1);
	A3DVECTOR3 row2 = matTransform.GetRow(2);

	Center = 0.5f * (vecMax + vecMin) * matTransform;
	XAxis = Normalize(row0);
	YAxis = Normalize(row1);
	ZAxis = Normalize(row2);
	Extents = 0.5f * (vecMax - vecMin);

	CompleteExtAxis();
}

//	Build obb from vertices
void A3DOBB::Build(const A3DVECTOR3* aVertPos, int nVertCount)
{
	Clear();

	if (nVertCount <= 0)
		return;

	A3DMATRIX3 matTransform = _GetOBBOrientation(aVertPos, nVertCount);

	//	For matTransform is orthogonal, so the inverse matrix is just rotate it;
	matTransform.Transpose();

	A3DVECTOR3 vecMax = A3DVECTOR3(aVertPos[0].x, aVertPos[0].y, aVertPos[0].z) * matTransform;
	A3DVECTOR3 vecMin = vecMax;

	for (int i = 1; i < nVertCount; i++)
	{
		A3DVECTOR3 vecThis = A3DVECTOR3(aVertPos[i].x, aVertPos[i].y, aVertPos[i].z) * matTransform;

		vecMax = a3d_VecMax(vecMax, vecThis);
		vecMin = a3d_VecMin(vecMin, vecThis);
	}

	matTransform.Transpose();

	A3DVECTOR3 row0 = matTransform.GetRow(0);
	A3DVECTOR3 row1 = matTransform.GetRow(1);
	A3DVECTOR3 row2 = matTransform.GetRow(2);

	Center = 0.5f * (vecMax + vecMin) * matTransform;
	XAxis = Normalize(row0);
	YAxis = Normalize(row1);
	ZAxis = Normalize(row2);
	Extents = 0.5f * (vecMax - vecMin);

	CompleteExtAxis();
}

//	Build obb from aabb
void A3DOBB::Build(const A3DAABB& aabb)
{
	Center = aabb.Center;
	XAxis = A3DVECTOR3::UnitX();
	YAxis = A3DVECTOR3::UnitY();
	ZAxis = A3DVECTOR3::UnitZ();
	Extents = aabb.Extents;

	CompleteExtAxis();
}

//	Get vertices of obb
void A3DOBB::GetVertices(A3DVECTOR3* aVertPos, unsigned short* aIndices, bool bWire) const
{
	static unsigned short indexTriangle[] =
	{
		0, 1, 3, 3, 1, 2,
		2, 1, 6, 6, 1, 5,
		5, 1, 4, 4, 1, 0,
		0, 3, 4, 4, 3, 7,
		3, 2, 7, 7, 2, 6,
		7, 6, 4, 4, 6, 5
	};

	static unsigned short indexWire[] =
	{
		0, 1, 1, 2, 2, 3, 3, 0,
		0, 4, 1, 5, 2, 6, 3, 7,
		4, 5, 5, 6, 6, 7, 7, 4
	};

	if (aVertPos)
	{
		//	Up 4 vertex;
		//	Left Up corner;
		aVertPos[0] = Center - ExtX + ExtY + ExtZ;
		//	right up corner;
		aVertPos[1] = aVertPos[0] + 2.0f * ExtX;
		//	right bottom corner;
		aVertPos[2] = aVertPos[1] - 2.0f * ExtZ;
		//	left bottom corner;
		aVertPos[3] = aVertPos[2] - 2.0f * ExtX;

		//	Down 4 vertex;
		//	Left up corner;
		aVertPos[4] = Center - ExtX - ExtY + ExtZ;
		//	right up corner;
		aVertPos[5] = aVertPos[4] + 2.0f * ExtX;
		//	right bottom corner;
		aVertPos[6] = aVertPos[5] - 2.0f * ExtZ;
		//	left bottom corner;
		aVertPos[7] = aVertPos[6] - 2.0f * ExtX;
	}

	if (aIndices)
	{
		if (bWire)
			memcpy(aIndices, indexWire, sizeof(unsigned short) * 24);
		else
			memcpy(aIndices, indexTriangle, sizeof(unsigned short) * 36);
	}
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement A3DPLANE
//
///////////////////////////////////////////////////////////////////////////

//	Create plane from 3 points
bool A3DPLANE::CreatePlane(const A3DVECTOR3& v1, const A3DVECTOR3& v2, const A3DVECTOR3& v3)
{
	A3DVECTOR3 d1 = v2 - v1;
	A3DVECTOR3 d2 = v3 - v1;

	vNormal = CrossProduct(d1, d2);
	vNormal.Normalize();
	fDist = DotProduct(vNormal, v1);

	return true;
}

bool A3DPLANE::GetIntersectionWithLine(const A3DVECTOR3& vStart, const A3DVECTOR3& vEnd, A3DVECTOR3& outIntersection)
{
	float t2 = DotProduct(vNormal, (vEnd - vStart));
	if (t2 == 0)
		return false;

	float t = -(DotProduct(vNormal, vStart) + fDist) / t2;
	outIntersection = vStart + (vEnd - vStart) * t;
	return true;
}

//	Make plane type
void A3DPLANE::MakeType()
{
	if (vNormal.x == 1.0f)
		byType = TYPE_PX;
	else if (vNormal.x == -1.0f)
		byType = TYPE_NX;
	else if (vNormal.y == 1.0f)
		byType = TYPE_PY;
	else if (vNormal.y == -1.0f)
		byType = TYPE_NY;
	else if (vNormal.z == 1.0f)
		byType = TYPE_PZ;
	else if (vNormal.z == -1.0f)
		byType = TYPE_NZ;
	else
	{
		byType = TYPE_MAJORX;

		//	Get normal's major axis
		float fTemp, fMax = (float)fabs(vNormal.x);

		fTemp = (float)fabs(vNormal.y);
		if (fMax < fTemp)
		{
			fMax = fTemp;
			byType = TYPE_MAJORY;
		}

		if (fMax < (float)fabs(vNormal.z))
			byType = TYPE_MAJORZ;
	}
}

//	Make plane sign-bits
void A3DPLANE::MakeSignBits()
{
	bySignBits = 0;

	if (vNormal.x < 0.0f)
		bySignBits |= SIGN_NX;

	if (vNormal.y < 0.0f)
		bySignBits |= SIGN_NY;

	if (vNormal.z < 0.0f)
		bySignBits |= SIGN_NZ;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement A3DCAPSULE
//
///////////////////////////////////////////////////////////////////////////

//	Check whether a point is in this capsule
bool A3DCAPSULE::IsPointIn(const A3DVECTOR3& vPos)
{
	A3DVECTOR3 vDelta = vPos - vCenter;

	//	The capped cylinder Is a sphere ?
	if (fHalfLen == 0.0f)
	{
		if (DotProduct(vDelta, vDelta) <= fRadius * fRadius)
			return true;

		return false;
	}

	float fpx = (float)fabs(DotProduct(vDelta, vAxisX));
	if (fpx > fRadius)
		return false;

	float fpz = (float)fabs(DotProduct(vDelta, vAxisZ));
	if (fpz > fRadius)
		return false;

	if (fpx * fpx + fpz * fpz > fRadius * fRadius)
		return false;

	float fpy = DotProduct(vDelta, vAxisY);
	if (fabs(fpy) < fHalfLen)
		return true;

	if (fpy > 0.0f)
		vDelta = vPos - (vCenter + vAxisY * fHalfLen);
	else
		vDelta = vPos - (vCenter - vAxisY * fHalfLen);

	if (DotProduct(vDelta, vDelta) <= fRadius * fRadius)
		return true;

	return false;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement A3DCYLINDER
//
///////////////////////////////////////////////////////////////////////////

//	Check whether a point is in this cylinder
bool A3DCYLINDER::IsPointIn(const A3DVECTOR3& vPos)
{
	A3DVECTOR3 vDelta = vPos - vCenter;

	float fpx = (float)fabs(DotProduct(vDelta, vAxisX));
	if (fpx > fRadius)
		return false;

	float fpz = (float)fabs(DotProduct(vDelta, vAxisZ));
	if (fpz > fRadius)
		return false;

	if (fpx * fpx + fpz * fpz > fRadius * fRadius)
		return false;

	float fpy = DotProduct(vDelta, vAxisY);
	if (fabs(fpy) > fHalfLen)
		return false;

	return true;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement global functions
//
///////////////////////////////////////////////////////////////////////////

//	Create a indexed sphere mesh
bool a3d_CreateIndexedSphere(const A3DVECTOR3& vPos, float fRadius, int iRow, int iCol,
	A3DVECTOR3* aVerts, int iMaxVertNum, unsigned short* aIndices, int iMaxIdxNum)
{
	a_ClampFloor(iRow, 3);
	a_ClampFloor(iCol, 3);

	int iNumVert = 2 + (iRow - 1) * iCol;
	if (iNumVert > iMaxVertNum)
	{
		ASSERT(iNumVert <= iMaxVertNum);
		return false;
	}

	int iNumIndex = (iRow - 1) * iCol * 6;
	if (iNumIndex > iMaxIdxNum)
	{
		ASSERT(iNumIndex <= iMaxIdxNum);
		return false;
	}

	float fRowAngle = A3D_PI / iRow;
	float fColAngle = A3D_2PI / iCol;
	int i, j;

	//	Pre-calculate cos and sin value
	ATempMemBuffer tempBuf1(sizeof(float) * iCol);
	ATempMemBuffer tempBuf2(sizeof(float) * iCol);
	float* aCos = (float*)tempBuf1.GetBuffer();
	float* aSin = (float*)tempBuf2.GetBuffer();

	for (i = 0; i < iCol; i++)
	{
		float fAngle = fColAngle * i;
		aCos[i] = cosf(fAngle);
		aSin[i] = sinf(fAngle);
	}

	A3DVECTOR3* pv = aVerts;

	//	Top center vertex
	pv->Set(vPos.x, vPos.y + fRadius, vPos.z);
	pv++;

	//	Body vertices
	for (i = 1; i < iRow; i++)
	{
		float fAngle = A3D_PI * 0.5f - i * fRowAngle;
		float y = fRadius * sinf(fAngle);
		float fProject = (float)fabs(fRadius * cosf(fAngle));

		for (j = 0; j < iCol; j++)
		{
			float x = fProject * aCos[j];
			float z = fProject * aSin[j];

			pv->Set(vPos.x + x, vPos.y + y, vPos.z + z);
			pv++;
		}
	}

	//	Bottom center vertex
	pv->Set(vPos.x, vPos.y - fRadius, vPos.z);
	pv++;

	int iVertStart = 0;
	unsigned short* pi = aIndices;

	//	Top cap indices
	for (i = 0; i < iCol; i++)
	{
		int iBaseIdx = iVertStart + 1;
		j = (i + 1) % iCol;

		*pi++ = (unsigned short)iVertStart;
		*pi++ = (unsigned short)(iBaseIdx + j);
		*pi++ = (unsigned short)(iBaseIdx + i);
	}

	//	Body indices
	int i1 = iVertStart + 1;
	int i2 = iVertStart + 1 + iCol;

	for (i = 0; i < iRow - 2; i++)
	{
		for (j = 0; j < iCol; j++)
		{
			int k = (j + 1) % iCol;

			*pi++ = (unsigned short)(i1 + j);
			*pi++ = (unsigned short)(i1 + k);
			*pi++ = (unsigned short)(i2 + k);

			*pi++ = (unsigned short)(i1 + j);
			*pi++ = (unsigned short)(i2 + k);
			*pi++ = (unsigned short)(i2 + j);
		}

		i1 += iCol;
		i2 += iCol;
	}

	//	Bottom cap indices
	for (i = 0; i < iCol; i++)
	{
		int iLastIdx = iNumVert - 1;
		int iBaseIdx = iLastIdx - iCol;
		j = (i + 1) % iCol;

		*pi++ = (unsigned short)(iBaseIdx + i);
		*pi++ = (unsigned short)(iBaseIdx + j);
		*pi++ = (unsigned short)(iLastIdx);
	}

	ASSERT(iNumVert == pv - aVerts);
	ASSERT(iNumIndex == pi - aIndices);

	return true;
}

//	Create a indexed taper mesh
bool a3d_CreateIndexedTaper(const A3DVECTOR3& vPos, const A3DVECTOR3& vDir,
	float fRadius, float fHeight, int iNumSeg, bool bHasBottom,
	A3DVECTOR3* aVerts, int iMaxVertNum, unsigned short* aIndices, int iMaxIdxNum)
{
	a_ClampFloor(iNumSeg, 3);

	int iNumVert = iNumSeg + 1;
	if (iNumVert > iMaxVertNum)
	{
		ASSERT(iNumVert <= iMaxVertNum);
		return false;
	}

	int iNumIndex = iNumSeg * 3;
	if (bHasBottom)
		iNumIndex += (iNumSeg - 2) * 3;

	if (iNumIndex > iMaxIdxNum)
	{
		ASSERT(iNumIndex <= iMaxIdxNum);
		return false;
	}

	//	Calculate x and y axis of taper, vDir is treated as z axis
	A3DVECTOR3 vX, vY;

	if (1.0f - fabs(vDir.y) < 0.0001f)
		vX = A3DVECTOR3(1, 0, 0);//A3DVECTOR3::vAxisX;
	else
		vX = a3d_Normalize(CrossProduct(A3DVECTOR3(0, 1, 0)/*A3DVECTOR3::vAxisY*/, vDir));

	vY = a3d_Normalize(CrossProduct(vDir, vX));

	int i;
	A3DVECTOR3* pv = aVerts;

	//	Top vertex
	pv->Set(vPos.x, vPos.y, vPos.z);
	pv++;

	A3DVECTOR3 p1 = vPos + vDir * fHeight;

	float fDelta = 360.0f / iNumSeg;
	float fDegree = 0.0f;

	//	Bottom vertices
	for (i = 0; i < iNumSeg; i++)
	{
		float fRad = DEG2RAD(fDegree);
		fDegree += fDelta;

		A3DVECTOR3 vt = vX * (float)cosf(fRad) + vY * (float)sinf(fRad);
		vt *= fRadius;

		pv->Set(p1.x + vt.x, p1.y + vt.y, p1.z + vt.z);
		pv++;
	}

	unsigned short* pi = aIndices;

	//	Bottom bottom cap indices
	if (bHasBottom)
	{
		for (i = 2; i < iNumSeg; i++)
		{
			*pi++ = 1;
			*pi++ = 1 + i - 1;
			*pi++ = 1 + i;
		}
	}

	//	Build sides indices
	for (i = 0; i < iNumSeg; i++)
	{
		int j = (i + 1) % iNumSeg;
		*pi++ = 0;
		*pi++ = 1 + j;
		*pi++ = 1 + i;
	}

	ASSERT(iNumVert == pv - aVerts);
	ASSERT(iNumIndex == pi - aIndices);

	return true;
}

//	Create a indexed box that has 8 vertices and 36 indices
//	vExtent: half border length
bool a3d_CreateIndexedBox(const A3DVECTOR3& vPos, const A3DVECTOR3& vX,
	const A3DVECTOR3& vY, const A3DVECTOR3& vZ, const A3DVECTOR3& vExtent,
	A3DVECTOR3* aVerts, unsigned short* aIndices)
{
	//	Indices for flat box
	static const unsigned short aSrcIndices[36] =
	{
		0, 1, 2, 0, 2, 3,
		1, 5, 6, 1, 6, 2,
		2, 6, 7, 2, 7, 3,
		3, 7, 4, 3, 4, 0,
		4, 5, 1, 4, 1, 0,
		5, 7, 6, 5, 4, 7,
	};

	memcpy(aIndices, aSrcIndices, 36 * sizeof(unsigned short));

	float fx2 = vExtent.x * 2.0f;
	float fy2 = vExtent.y * 2.0f;
	float fz2 = vExtent.z * 2.0f;

	aVerts[0] = vPos + vZ * vExtent.z + vY * vExtent.y - vX * vExtent.x;
	aVerts[1] = aVerts[0] + vX * fx2;
	aVerts[2] = aVerts[1] - vZ * fz2;
	aVerts[3] = aVerts[0] - vZ * fz2;
	aVerts[4] = aVerts[0] - vY * fy2;
	aVerts[5] = aVerts[4] + vX * fx2;
	aVerts[6] = aVerts[5] - vZ * fz2;
	aVerts[7] = aVerts[4] - vZ * fz2;

	return true;
}