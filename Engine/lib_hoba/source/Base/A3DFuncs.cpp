#include "A3DFuncs.h"
#include "ASys.h"
#include "AAssist.h"
#include "A3DMacros.h"
#include <stdlib.h>

static bool _KeepOrthogonal(A3DMATRIX4 mat)
{
	float vDot;
	float vNormal;
	float error = 1e-5f;

	A3DVECTOR3 x = A3DVECTOR3(mat._11, mat._12, mat._13);
	A3DVECTOR3 y = A3DVECTOR3(mat._21, mat._22, mat._23);
	A3DVECTOR3 z = A3DVECTOR3(mat._31, mat._32, mat._33);

	vNormal = x.Magnitude();
	if (fabs(fabs(vNormal) - 1.0f) > error)
		return false;

	vNormal = y.Magnitude();
	if (fabs(fabs(vNormal) - 1.0f) > error)
		return false;

	vNormal = y.Magnitude();
	if (fabs(fabs(vNormal) - 1.0f) > error)
		return false;

	vDot = DotProduct(x, y);
	if (fabs(vDot) > error)
		return false;

	vDot = DotProduct(y, z);
	if (fabs(vDot) > error)
		return false;

	vDot = DotProduct(x, z);
	if (fabs(vDot) > error)
		return false;

	vDot = DotProduct(CrossProduct(x, y), z);
	if (fabs(fabs(vDot) - 1.0f) > error)
		return false;

	return true;
}

//	Inverse sqrt using Newton approximation
float a3d_InvSqrt(float v)
{
	float vhalf = 0.5f * v;
	int i = *(int*)&v;
	i = 0x5f3759df - (i >> 1);
	v = *(float*)&i;
	v = v * (1.5f - vhalf * v * v);
	return v;
}

// Return min/max vector composed with min/max component of the input 2 vector
A3DVECTOR3 a3d_VecMin(const A3DVECTOR3& v1, const A3DVECTOR3& v2)
{
	return A3DVECTOR3(min2(v1.x, v2.x), min2(v1.y, v2.y), min2(v1.z, v2.z));
}

A3DVECTOR3 a3d_VecMax(const A3DVECTOR3& v1, const A3DVECTOR3& v2)
{
	return A3DVECTOR3(max2(v1.x, v2.x), max2(v1.y, v2.y), max2(v1.z, v2.z));
}

//	Convert a vector from view coordinates to world coordinates
A3DVECTOR3 a3d_ViewToWorld(const A3DVECTOR3& vIn, A3DMATRIX4& matView)
{
	A3DVECTOR3 vOut;
	vOut.x = vIn.x * matView._11 + vIn.y * matView._12 + vIn.z * matView._13;
	vOut.y = vIn.x * matView._21 + vIn.y * matView._22 + vIn.z * matView._23;
	vOut.z = vIn.x * matView._31 + vIn.y * matView._32 + vIn.z * matView._33;
	return vOut;
}

A3DMATRIX3 a3d_IdentityMatrix3()
{
	A3DMATRIX3 result;
	memset(&result, 0, sizeof(result));
	result._11 = result._22 = result._33 = 1.0f;
	return result;
}

A3DMATRIX4 a3d_IdentityMatrix()
{
	A3DMATRIX4 result;
	memset(&result, 0, sizeof(result));
	result._11 = result._22 = result._33 = result._44 = 1.0f;
	return result;
}

A3DMATRIX4 a3d_ZeroMatrix()
{
	A3DMATRIX4 result;
	memset(&result, 0, sizeof(result));
	return result;
}

A3DMATRIX4 a3d_ViewMatrix(const A3DVECTOR3& from, const A3DVECTOR3& dir,
	const A3DVECTOR3& vecUp, float roll)
{
	A3DMATRIX4 view = a3d_IdentityMatrix();
	A3DVECTOR3 up, right, view_dir;

	view_dir = Normalize(dir);
	right = CrossProduct(vecUp, dir);
	right = Normalize(right);
	up = CrossProduct(dir, right);
	up = Normalize(up);

	view.m[0][0] = right.x;
	view.m[1][0] = right.y;
	view.m[2][0] = right.z;
	view.m[0][1] = up.x;
	view.m[1][1] = up.y;
	view.m[2][1] = up.z;
	view.m[0][2] = view_dir.x;
	view.m[1][2] = view_dir.y;
	view.m[2][2] = view_dir.z;

	view.m[3][0] = -DotProduct(right, from);
	view.m[3][1] = -DotProduct(up, from);
	view.m[3][2] = -DotProduct(view_dir, from);

	// Set roll
	if (roll != 0.0f)
		view = a3d_RotateZ(-roll) * view;

	return view;
}

A3DMATRIX4 a3d_LookAtMatrix(const A3DVECTOR3& vEye, const A3DVECTOR3& vAt, const A3DVECTOR3& vUp, float roll)
{
	A3DMATRIX4 m;
	//D3DXMatrixLookAtLH((D3DXMATRIX*)&mat, (D3DXVECTOR3*)&from, (D3DXVECTOR3*)&to, (D3DXVECTOR3*)&vecUp);
	//From Angelica 4
	A3DVECTOR3 vZAxis = (vAt - vEye).Normalize();
	A3DVECTOR3 vXAxis = CrossProduct(vUp, vZAxis).Normalize();
	A3DVECTOR3 vYAxis = CrossProduct(vZAxis, vXAxis);
	m._11 = vXAxis.x; m._12 = vYAxis.x; m._13 = vZAxis.x; m._14 = 0.0f;
	m._21 = vXAxis.y; m._22 = vYAxis.y; m._23 = vZAxis.y; m._24 = 0.0f;
	m._31 = vXAxis.z; m._32 = vYAxis.z; m._33 = vZAxis.z; m._34 = 0.0f;
	m._41 = -DotProduct(vXAxis, vEye);
	m._42 = -DotProduct(vYAxis, vEye);
	m._43 = -DotProduct(vZAxis, vEye);
	m._44 = 1.0f;

	//	Set roll
	if (roll != 0.0f)
		m = a3d_RotateZ(-roll) * m;

	return m;
}

A3DMATRIX4 a3d_Transpose(const A3DMATRIX4& tm)
{
	A3DMATRIX4 matT;
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 4; j++)
			matT.m[i][j] = tm.m[j][i];
	}

	return matT;
}

void a3d_Transpose(const A3DMATRIX4& matIn, A3DMATRIX4* pmatOut)
{
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 4; j++)
			pmatOut->m[i][j] = matIn.m[j][i];
	}
}

static float _Det(float a11, float a12, float a13,
	float a21, float a22, float a23,
	float a31, float a32, float a33)
{
	return a11 * a22 * a33 + a21 * a32 * a13 + a31 * a12 * a23 -
		a13 * a22 * a31 - a23 * a32 * a11 - a33 * a12 * a21;
}

A3DMATRIX4 a3d_InverseTM(const A3DMATRIX4& mat)
{
	A3DMATRIX4 ret;
	a3d_InverseTM(mat, &ret);
	return ret;
}

void a3d_InverseTM(const A3DMATRIX4& matIn, A3DMATRIX4* pmatOut)
{
	float vDet;

	vDet = 1.0f / _Det(matIn._11, matIn._12, matIn._13,
		matIn._21, matIn._22, matIn._23,
		matIn._31, matIn._32, matIn._33);

	pmatOut->_11 = vDet * _Det(matIn._22, matIn._23, matIn._24,
		matIn._32, matIn._33, matIn._34,
		matIn._42, matIn._43, matIn._44);
	pmatOut->_12 = -vDet * _Det(matIn._12, matIn._13, matIn._14,
		matIn._32, matIn._33, matIn._34,
		matIn._42, matIn._43, matIn._44);
	pmatOut->_13 = vDet * _Det(matIn._12, matIn._13, matIn._14,
		matIn._22, matIn._23, matIn._24,
		matIn._42, matIn._43, matIn._44);
	pmatOut->_14 = -vDet * _Det(matIn._12, matIn._13, matIn._14,
		matIn._22, matIn._23, matIn._24,
		matIn._32, matIn._33, matIn._34);

	pmatOut->_21 = -vDet * _Det(matIn._21, matIn._23, matIn._24,
		matIn._31, matIn._33, matIn._34,
		matIn._41, matIn._43, matIn._44);
	pmatOut->_22 = vDet * _Det(matIn._11, matIn._13, matIn._14,
		matIn._31, matIn._33, matIn._34,
		matIn._41, matIn._43, matIn._44);
	pmatOut->_23 = -vDet * _Det(matIn._11, matIn._13, matIn._14,
		matIn._21, matIn._23, matIn._24,
		matIn._41, matIn._43, matIn._44);
	pmatOut->_24 = vDet * _Det(matIn._11, matIn._13, matIn._14,
		matIn._21, matIn._23, matIn._24,
		matIn._31, matIn._33, matIn._34);

	pmatOut->_31 = vDet * _Det(matIn._21, matIn._22, matIn._24,
		matIn._31, matIn._32, matIn._34,
		matIn._41, matIn._42, matIn._44);
	pmatOut->_32 = -vDet * _Det(matIn._11, matIn._12, matIn._14,
		matIn._31, matIn._32, matIn._34,
		matIn._41, matIn._42, matIn._44);
	pmatOut->_33 = vDet * _Det(matIn._11, matIn._12, matIn._14,
		matIn._21, matIn._22, matIn._24,
		matIn._41, matIn._42, matIn._44);
	pmatOut->_34 = -vDet * _Det(matIn._11, matIn._12, matIn._14,
		matIn._21, matIn._22, matIn._24,
		matIn._31, matIn._32, matIn._34);

	pmatOut->_41 = -vDet * _Det(matIn._21, matIn._22, matIn._23,
		matIn._31, matIn._32, matIn._33,
		matIn._41, matIn._42, matIn._43);
	pmatOut->_42 = vDet * _Det(matIn._11, matIn._12, matIn._13,
		matIn._31, matIn._32, matIn._33,
		matIn._41, matIn._42, matIn._43);
	pmatOut->_43 = -vDet * _Det(matIn._11, matIn._12, matIn._13,
		matIn._21, matIn._22, matIn._23,
		matIn._41, matIn._42, matIn._43);
	pmatOut->_44 = vDet * _Det(matIn._11, matIn._12, matIn._13,
		matIn._21, matIn._22, matIn._23,
		matIn._31, matIn._32, matIn._33);
}

A3DMATRIX4 a3d_InverseAffineMatrix(const A3DMATRIX4& mat)
{
	A3DMATRIX4 matInv;
	a3d_InverseAffineMatrix(mat, &matInv);
	return matInv;
}

A3DMATRIX4 a3d_InverseMatrix(const A3DMATRIX4& mat)
{
	A3DMATRIX4 matInv;
	a3d_InverseMatrix(mat, &matInv);
	return matInv;
}

inline float a3d_Determinant3(
	float _m11, float _m12, float _m13,
	float _m21, float _m22, float _m23,
	float _m31, float _m32, float _m33)
{
	return
		+_m11 * (_m22 * _m33 - _m23 * _m32)
		+ _m12 * (_m23 * _m31 - _m21 * _m33)
		+ _m13 * (_m21 * _m32 - _m22 * _m31);
}

float a3d_DeterminantMatrix(const A3DMATRIX4& matIn)
{
	return
		-matIn._14 * a3d_Determinant3(matIn._21, matIn._22, matIn._23, matIn._31, matIn._32, matIn._33, matIn._41, matIn._42, matIn._43)
		+ matIn._24 * a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._31, matIn._32, matIn._33, matIn._41, matIn._42, matIn._43)
		- matIn._34 * a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._21, matIn._22, matIn._23, matIn._41, matIn._42, matIn._43)
		+ matIn._44 * a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._21, matIn._22, matIn._23, matIn._31, matIn._32, matIn._33);
}

void a3d_InverseAffineMatrix(const A3DMATRIX4& matIn, A3DMATRIX4* pmatOut)
{
	pmatOut->_11 = matIn._11; pmatOut->_12 = matIn._21; pmatOut->_13 = matIn._31, pmatOut->_14 = 0.0f;
	pmatOut->_21 = matIn._12; pmatOut->_22 = matIn._22; pmatOut->_23 = matIn._32, pmatOut->_24 = 0.0f;
	pmatOut->_31 = matIn._13; pmatOut->_32 = matIn._23; pmatOut->_33 = matIn._33, pmatOut->_34 = 0.0f;

	pmatOut->_41 = -matIn._11 * matIn._41 - matIn._12 * matIn._42 - matIn._13 * matIn._43;
	pmatOut->_42 = -matIn._21 * matIn._41 - matIn._22 * matIn._42 - matIn._23 * matIn._43;
	pmatOut->_43 = -matIn._31 * matIn._41 - matIn._32 * matIn._42 - matIn._33 * matIn._43;
	pmatOut->_44 = 1.0f;
}

void a3d_InverseMatrix(const A3DMATRIX4& matIn, A3DMATRIX4* pmatOut)
{
	//D3DXMatrixInverse((D3DXMATRIX*) pmatOut, NULL, (D3DXMATRIX*) &matIn);
	// From Angelica 4

	float fDet = a3d_DeterminantMatrix(matIn);
	A3DMATRIX4 mResult;

	mResult._11 = a3d_Determinant3(matIn._22, matIn._23, matIn._24, matIn._32, matIn._33, matIn._34, matIn._42, matIn._43, matIn._44);
	mResult._12 = -a3d_Determinant3(matIn._12, matIn._13, matIn._14, matIn._32, matIn._33, matIn._34, matIn._42, matIn._43, matIn._44);
	mResult._13 = a3d_Determinant3(matIn._12, matIn._13, matIn._14, matIn._22, matIn._23, matIn._24, matIn._42, matIn._43, matIn._44);
	mResult._14 = -a3d_Determinant3(matIn._12, matIn._13, matIn._14, matIn._22, matIn._23, matIn._24, matIn._32, matIn._33, matIn._34);

	mResult._21 = -a3d_Determinant3(matIn._21, matIn._23, matIn._24, matIn._31, matIn._33, matIn._34, matIn._41, matIn._43, matIn._44);
	mResult._22 = a3d_Determinant3(matIn._11, matIn._13, matIn._14, matIn._31, matIn._33, matIn._34, matIn._41, matIn._43, matIn._44);
	mResult._23 = -a3d_Determinant3(matIn._11, matIn._13, matIn._14, matIn._21, matIn._23, matIn._24, matIn._41, matIn._43, matIn._44);
	mResult._24 = a3d_Determinant3(matIn._11, matIn._13, matIn._14, matIn._21, matIn._23, matIn._24, matIn._31, matIn._33, matIn._34);

	mResult._31 = a3d_Determinant3(matIn._21, matIn._22, matIn._24, matIn._31, matIn._32, matIn._34, matIn._41, matIn._42, matIn._44);
	mResult._32 = -a3d_Determinant3(matIn._11, matIn._12, matIn._14, matIn._31, matIn._32, matIn._34, matIn._41, matIn._42, matIn._44);
	mResult._33 = a3d_Determinant3(matIn._11, matIn._12, matIn._14, matIn._21, matIn._22, matIn._24, matIn._41, matIn._42, matIn._44);
	mResult._34 = -a3d_Determinant3(matIn._11, matIn._12, matIn._14, matIn._21, matIn._22, matIn._24, matIn._31, matIn._32, matIn._34);

	mResult._41 = -a3d_Determinant3(matIn._21, matIn._22, matIn._23, matIn._31, matIn._32, matIn._33, matIn._41, matIn._42, matIn._43);
	mResult._42 = a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._31, matIn._32, matIn._33, matIn._41, matIn._42, matIn._43);
	mResult._43 = -a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._21, matIn._22, matIn._23, matIn._41, matIn._42, matIn._43);
	mResult._44 = a3d_Determinant3(matIn._11, matIn._12, matIn._13, matIn._21, matIn._22, matIn._23, matIn._31, matIn._32, matIn._33);

	mResult /= fDet;
	*pmatOut = mResult;
}

A3DMATRIX4 a3d_TransformMatrix(const A3DVECTOR3& vecDir, const A3DVECTOR3& vecUp, const A3DVECTOR3& vecPos)
{
	A3DMATRIX4   mat;
	A3DVECTOR3   vecXAxis, vecYAxis, vecZAxis;

	vecZAxis = Normalize(vecDir);
	vecYAxis = Normalize(vecUp);
	vecXAxis = Normalize(CrossProduct(vecYAxis, vecZAxis));

	memset(&mat, 0, sizeof(mat));
	mat.m[0][0] = vecXAxis.x;
	mat.m[0][1] = vecXAxis.y;
	mat.m[0][2] = vecXAxis.z;

	mat.m[1][0] = vecYAxis.x;
	mat.m[1][1] = vecYAxis.y;
	mat.m[1][2] = vecYAxis.z;

	mat.m[2][0] = vecZAxis.x;
	mat.m[2][1] = vecZAxis.y;
	mat.m[2][2] = vecZAxis.z;

	mat.m[3][0] = vecPos.x;
	mat.m[3][1] = vecPos.y;
	mat.m[3][2] = vecPos.z;
	mat.m[3][3] = 1.0f;

	return mat;
}

A3DMATRIX4 a3d_RotateX(float vRad)
{
	A3DMATRIX4 ret = a3d_IdentityMatrix();
	ret.m[2][2] = ret.m[1][1] = (float)cos(vRad);
	ret.m[1][2] = (float)sin(vRad);
	ret.m[2][1] = (float)-ret.m[1][2];

	//	_KeepOrthogonal(ret);
	return ret;
}

A3DMATRIX4 a3d_RotateX(const A3DMATRIX4& mat, float vRad)
{
	return mat * a3d_RotateX(vRad);
}

A3DMATRIX4 a3d_RotateY(float vRad)
{
	A3DMATRIX4 ret = a3d_IdentityMatrix();
	ret.m[2][2] = ret.m[0][0] = (float)cos(vRad);
	ret.m[2][0] = (float)sin(vRad);
	ret.m[0][2] = -ret.m[2][0];
	//	_KeepOrthogonal(ret);
	return ret;
}

A3DMATRIX4 a3d_RotateY(const A3DMATRIX4& mat, float vRad)
{
	return mat * a3d_RotateY(vRad);
}

A3DMATRIX4 a3d_RotateZ(float vRad)
{
	A3DMATRIX4 ret = a3d_IdentityMatrix();
	ret.m[1][1] = ret.m[0][0] = (float)cos(vRad);
	ret.m[0][1] = (float)sin(vRad);
	ret.m[1][0] = -ret.m[0][1];
	//	_KeepOrthogonal(ret);
	return ret;
}

A3DMATRIX4 a3d_RotateZ(const A3DMATRIX4& mat, float vRad)
{
	return mat * a3d_RotateZ(vRad);
}

A3DMATRIX4 a3d_RotateAxis(const A3DVECTOR3& vRotAxis, float vRad)
{
	/*
		The derivation of this algorithm can be seen in rotation.pdf in my 文档 directory.
		The basic idea is to divide the original vector to two part: paralell to axis and
		perpendicular to axis, then only perpendicular part can be affected by this rotation.
		Now divide the rotation part onto the main axis on the rotation plane then it will
		be clear to see what composes the rotated vector. Finally we can get the transform
		matrix from a set of 3 equations.
		*/
	A3DVECTOR3 vecAxis = Normalize(vRotAxis);

	A3DMATRIX4 ret;
	float xx, xy, xz, yy, yz, zz, cosine, sine, one_cs, xsine, ysine, zsine;

	xx = vecAxis.x * vecAxis.x;
	xy = vecAxis.x * vecAxis.y;
	xz = vecAxis.x * vecAxis.z;
	yy = vecAxis.y * vecAxis.y;
	yz = vecAxis.y * vecAxis.z;
	zz = vecAxis.z * vecAxis.z;

	cosine = (float)cos(vRad);
	sine = (float)sin(vRad);
	one_cs = 1.0f - cosine;

	xsine = vecAxis.x * sine;
	ysine = vecAxis.y * sine;
	zsine = vecAxis.z * sine;

	ret._11 = xx + cosine * (1.0f - xx);
	ret._12 = xy * one_cs + zsine;
	ret._13 = xz * one_cs - ysine;
	ret._14 = 0.0f;

	ret._21 = xy * one_cs - zsine;
	ret._22 = yy + cosine * (1.0f - yy);
	ret._23 = yz * one_cs + xsine;
	ret._24 = 0.0f;

	ret._31 = xz * one_cs + ysine;
	ret._32 = yz * one_cs - xsine;
	ret._33 = zz + cosine * (1.0f - zz);
	ret._34 = 0.0f;

	ret._41 = 0.0f;
	ret._42 = 0.0f;
	ret._43 = 0.0f;
	ret._44 = 1.0f;

	//D3DXMatrixRotationAxis((D3DXMATRIX *)&ret, (D3DXVECTOR3*)&vecAxis, vRad);
	return ret;
}

A3DMATRIX4 a3d_RotateAxis(const A3DVECTOR3& vecPos, const A3DVECTOR3& vecAxis, float vRad)
{
	A3DMATRIX4 ret = a3d_Translate(-vecPos.x, -vecPos.y, -vecPos.z);
	ret = ret * a3d_RotateAxis(vecAxis, vRad);
	ret = ret * a3d_Translate(vecPos.x, vecPos.y, vecPos.z);

	return ret;
}

//	Rotate a position around axis X
A3DVECTOR3 a3d_RotatePosAroundX(const A3DVECTOR3& vPos, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateX(fRad);
	return vPos * mat;
}

//	Rotate a position around axis Y
A3DVECTOR3 a3d_RotatePosAroundY(const A3DVECTOR3& vPos, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateY(fRad);
	return vPos * mat;
}

//	Rotate a position around axis Z
A3DVECTOR3 a3d_RotatePosAroundZ(const A3DVECTOR3& vPos, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateZ(fRad);
	return vPos * mat;
}

/*	Rotate a position around arbitrary axis

	Return result position.

	vPos: position will do rotate
	vAxis: normalized axis
	fRad: rotation radian
	*/
A3DVECTOR3 a3d_RotatePosAroundAxis(const A3DVECTOR3& vPos, const A3DVECTOR3& vAxis, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateAxis(vAxis, fRad);
	return vPos * mat;
}

/*	Rotate a position around a line

	Return result position.

	vPos: position will do rotate
	vOrigin: point on line
	vDir: normalized line's direction
	fRad: rotation radian
	*/
A3DVECTOR3 a3d_RotatePosAroundLine(const A3DVECTOR3& vPos, const A3DVECTOR3& vOrigin, const A3DVECTOR3& vDir, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateAxis(vOrigin, vDir, fRad);
	return vPos * mat;
}

/*	Rotate a position around a line

	Return result vector.

	v: vector will do rotate
	vOrigin: point on line
	vDir: normalized line's direction
	fRad: rotation radian
	*/
A3DVECTOR3 a3d_RotateVecAroundLine(const A3DVECTOR3& v, const A3DVECTOR3& vOrigin, const A3DVECTOR3& vDir, float fRad)
{
	A3DMATRIX4 mat;
	mat.RotateAxis(vOrigin, vDir, fRad);
	return v * mat - mat.GetRow(3);
}

A3DMATRIX4 a3d_Scaling(float sx, float sy, float sz)
{
	A3DMATRIX4 ret = ZeroMatrix();
	ret.m[0][0] = sx;
	ret.m[1][1] = sy;
	ret.m[2][2] = sz;
	ret.m[3][3] = 1.0f;
	return ret;
}

A3DMATRIX4 a3d_Scaling(const A3DMATRIX4& mat, float sx, float sy, float sz)
{
	A3DMATRIX4 ret = mat;
	ret.m[0][0] *= sx;
	ret.m[0][1] *= sx;
	ret.m[0][2] *= sx;
	ret.m[0][3] *= sx;

	ret.m[1][0] *= sy;
	ret.m[1][1] *= sy;
	ret.m[1][2] *= sy;
	ret.m[1][3] *= sy;

	ret.m[2][0] *= sz;
	ret.m[2][1] *= sz;
	ret.m[2][2] *= sz;
	ret.m[2][3] *= sz;
	return ret;
}

A3DMATRIX4 a3d_ScalingRelative(const A3DMATRIX4& matRoot, float sx, float sy, float sz)
{
	A3DMATRIX4 matScale;
	matScale = InverseTM(matRoot) * a3d_Scaling(sx, sy, sz) * matRoot;

	return matScale;
}

A3DMATRIX4 a3d_Translate(float x, float y, float z)
{
	A3DMATRIX4 ret = a3d_IdentityMatrix();

	ret._41 = x;
	ret._42 = y;
	ret._43 = z;

	return ret;
}

A3DMATRIX4 a3d_ScaleAlongAxis(const A3DVECTOR3& vAxis, float fScale)
{
	/*	A3DMATRIX4 mat1, mat2;

		mat1.Clear();
		mat1._11 = mat1._22 = mat1._33 = 1.0f;
		mat1._14 = vAxis.x;
		mat1._24 = vAxis.y;
		mat1._34 = vAxis.z;

		mat2.Clear();
		mat2._11 = mat2._22 = mat2._33 = 1.0f;
		mat2._41 = (fScale - 1.0f) * vAxis.x;
		mat2._42 = (fScale - 1.0f) * vAxis.y;
		mat2._43 = (fScale - 1.0f) * vAxis.z;

		mat = mat1 * mat2;
		mat._14 = mat._24 = mat._34 = 0.0f;
		mat._44 = 1.0f;
		*/
	A3DMATRIX4 mat(A3DMATRIX4::IDENTITY);

	float s = fScale - 1.0f;
	float f1 = s * vAxis.x * vAxis.y;
	float f2 = s * vAxis.y * vAxis.z;
	float f3 = s * vAxis.x * vAxis.z;

	mat._11 = 1 + s * vAxis.x * vAxis.x;
	mat._22 = 1 + s * vAxis.y * vAxis.y;
	mat._33 = 1 + s * vAxis.z * vAxis.z;
	mat._12 = mat._21 = f1;
	mat._13 = mat._31 = f3;
	mat._23 = mat._32 = f2;

	return mat;
}

//	Multiply a vertex but don't consider translation factors (the fourth row of matrix),
//	this function can be used to transform a normal.
A3DVECTOR3 a3d_VectorMatrix3x3(const A3DVECTOR3& v, const A3DMATRIX4& mat)
{
	return A3DVECTOR3(v.x * mat._11 + v.y * mat._21 + v.z * mat._31,
		v.x * mat._12 + v.y * mat._22 + v.z * mat._32,
		v.x * mat._13 + v.y * mat._23 + v.z * mat._33);
}

A3DVECTOR3 a3d_RandDirH()
{
	A3DVECTOR3 vecDirH;

	float vRad = (rand() % 10000) / 10000.0f * 2.0f * A3D_PI;

	vecDirH.x = (float)cos(vRad);
	vecDirH.y = 0.0f;
	vecDirH.z = (float)sin(vRad);

	return vecDirH;
}

A3DMATRIX4 a3d_MirrorMatrix(const A3DVECTOR3& p, // IN: point on the plane
	const A3DVECTOR3& n) // IN: plane perpendicular direction
{
	A3DMATRIX4 ret;

	//V' = V - 2((V - P)*N)N)
	float dot = p.x*n.x + p.y*n.y + p.z*n.z;

	ret.m[0][0] = 1 - 2 * n.x*n.x;
	ret.m[1][0] = -2 * n.x*n.y;
	ret.m[2][0] = -2 * n.x*n.z;
	ret.m[3][0] = 2 * dot*n.x;

	ret.m[0][1] = -2 * n.y*n.x;
	ret.m[1][1] = 1 - 2 * n.y*n.y;
	ret.m[2][1] = -2 * n.y*n.z;
	ret.m[3][1] = 2 * dot*n.y;

	ret.m[0][2] = -2 * n.z*n.x;
	ret.m[1][2] = -2 * n.z*n.y;
	ret.m[2][2] = 1 - 2 * n.z*n.z;
	ret.m[3][2] = 2 * dot*n.z;

	ret.m[0][3] = 0;
	ret.m[1][3] = 0;
	ret.m[2][3] = 0;
	ret.m[3][3] = 1;

	return ret;
}

//	Clear AABB
void a3d_ClearAABB(A3DVECTOR3& vMins, A3DVECTOR3& vMaxs)
{
	vMins.Set(999999.0f, 999999.0f, 999999.0f);
	vMaxs.Set(-999999.0f, -999999.0f, -999999.0f);
}

//Use a vertex point to expand an AABB data;
void a3d_AddVertexToAABB(A3DVECTOR3& vMins, A3DVECTOR3& vMaxs, A3DVECTOR3& vPoint)
{
	for (int i = 0; i < 3; i++)
	{
		if (vPoint.m[i] < vMins.m[i])
			vMins.m[i] = vPoint.m[i];

		if (vPoint.m[i] > vMaxs.m[i])
			vMaxs.m[i] = vPoint.m[i];
	}
}

// Get the dir and up of a view within the cube map
// 0 ---- right
// 1 ---- left
// 2 ---- top
// 3 ---- bottom
// 4 ---- front
// 5 ---- back
bool a3d_GetCubeMapDirAndUp(int nFaceIndex, A3DVECTOR3 * pDir, A3DVECTOR3 * pUp)
{
	switch (nFaceIndex)
	{
	case 0: // Right
		*pDir = A3DVECTOR3(1.0f, 0.0f, 0.0f);
		*pUp = A3DVECTOR3(0.0f, 1.0f, 0.0f);
		break;
	case 1: // Left
		*pDir = A3DVECTOR3(-1.0f, 0.0f, 0.0f);
		*pUp = A3DVECTOR3(0.0f, 1.0f, 0.0f);
		break;
	case 2: // Top
		*pDir = A3DVECTOR3(0.0f, 1.0f, 0.0f);
		*pUp = A3DVECTOR3(0.0f, 0.0f, -1.0f);
		break;
	case 3: // Bottom
		*pDir = A3DVECTOR3(0.0f, -1.0f, 0.0f);
		*pUp = A3DVECTOR3(0.0f, 0.0f, 1.0f);
		break;
	case 4: // Front
		*pDir = A3DVECTOR3(0.0f, 0.0f, 1.0f);
		*pUp = A3DVECTOR3(0.0f, 1.0f, 0.0f);
		break;
	case 5: // Back
		*pDir = A3DVECTOR3(0.0f, 0.0f, -1.0f);
		*pUp = A3DVECTOR3(0.0f, 1.0f, 0.0f);
		break;
	default: // Error
		*pDir = A3DVECTOR3(0.0f);
		*pUp = A3DVECTOR3(0.0f);
		return false;
	}
	return true;
}

A3DMATRIX3 a3d_Matrix3Rotate(float fRad)
{
	A3DMATRIX3 mat;
	mat.Rotate(fRad);
	return mat;
}

A3DMATRIX3 a3d_Matrix3Rotate(const A3DMATRIX3& mat, float fRad)
{
	return mat * a3d_Matrix3Rotate(fRad);
}

A3DMATRIX3 a3d_Matrix3Translate(float x, float y)
{
	A3DMATRIX3 mat;
	mat.Translate(x, y);
	return mat;
}

A3DMATRIX3 a3d_Matrix3Translate(const A3DMATRIX3& mat, float x, float y)
{
	return mat * a3d_Matrix3Translate(x, y);
}

//Use a OBB data to expand an AABB data;
void a3d_ExpandAABB(A3DVECTOR3& vecMins, A3DVECTOR3& vecMaxs, const A3DOBB& obb)
{
	A3DVECTOR3 v[8];

	//Up 4 corner;
	v[0] = obb.Center + obb.ExtY - obb.ExtX + obb.ExtZ;
	v[1] = v[0] + obb.ExtX + obb.ExtX;	//	+ obb.ExtX * 2.0f;
	v[2] = v[1] - obb.ExtZ - obb.ExtZ;	//	+ obb.ExtZ * (-2.0f);
	v[3] = v[2] - obb.ExtX - obb.ExtX;	//	+ obb.ExtX * (-2.0f);

	//Down 4 corner;
	v[4] = obb.Center - obb.ExtY - obb.ExtX + obb.ExtZ;
	v[5] = v[4] + obb.ExtX + obb.ExtX;	//	+ obb.ExtX * 2.0f;
	v[6] = v[5] - obb.ExtZ - obb.ExtZ;	//	+ obb.ExtZ * (-2.0f);
	v[7] = v[6] - obb.ExtX - obb.ExtX;	//	+ obb.ExtX * (-2.0f);

	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j<8; j++)
		{
			if (vecMins.m[i] > v[j].m[i])
				vecMins.m[i] = v[j].m[i];

			if (vecMaxs.m[i] < v[j].m[i])
				vecMaxs.m[i] = v[j].m[i];
		}
	}
}

//Use a sub AABB data to expand an AABB data;
void a3d_ExpandAABB(A3DVECTOR3& vecMins, A3DVECTOR3& vecMaxs, const A3DAABB& subAABB)
{
	for (int i = 0; i<3; i++)
	{
		if (vecMins.m[i] > subAABB.Mins.m[i])
			vecMins.m[i] = subAABB.Mins.m[i];
		if (vecMaxs.m[i] < subAABB.Maxs.m[i])
			vecMaxs.m[i] = subAABB.Maxs.m[i];
	}
}

A3DMATRIX4 a3d_OrthoMatrixLH(float fWidth, float fHeight, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	m._11 = 2.0f / fWidth;
	m._22 = 2.0f / fHeight;
	m._33 = 1.0f / (fZFar - fZNear);
	m._43 = -fZNear * m._33;
	m._44 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = m._34 = 0.0f;
	m._41 = m._42 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_PerspectiveMatrixLH(float fWidth, float fHeight, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float f2ZN = 2.0f * fZNear;
	m._11 = f2ZN / fWidth;
	m._22 = f2ZN / fHeight;
	m._33 = fZFar / (fZFar - fZNear);
	m._43 = -fZNear * m._33;
	m._34 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = 0.0f;
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_PerspectiveFovMatrixLH(float fFovY, float fAspect, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fYScale = 1.0f / tanf(fFovY / 2.0f);
	float fXScale = fYScale / fAspect;
	m._11 = fXScale;
	m._22 = fYScale;
	m._33 = fZFar / (fZFar - fZNear);
	m._43 = -fZNear * m._33;
	m._34 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = 0.0f;
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_OrthoOffCenterMatrixLH(float fLeft, float fRight, float fBottom, float fTop, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fWidth = fRight - fLeft;
	float fHeight = fTop - fBottom;
	m._11 = 2.0f / fWidth;
	m._22 = 2.0f / fHeight;
	m._33 = 1.0f / (fZFar - fZNear);
	m._43 = -fZNear * m._33;
	m._44 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = m._34 = 0.0f;
	m._41 = -(fRight + fLeft) / fWidth;
	m._42 = -(fTop + fBottom) / fHeight;
	return m;
}

A3DMATRIX4 a3d_PerspectiveOffCenterMatrixLH(float fLeft, float fRight, float fBottom, float fTop, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fWidth = fRight - fLeft;
	float fHeight = fTop - fBottom;
	float f2ZN = 2.0f * fZNear;
	m._11 = f2ZN / fWidth;
	m._22 = f2ZN / fHeight;
	m._33 = fZFar / (fZFar - fZNear);
	m._43 = -fZNear * m._33;
	m._34 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = -(fRight + fLeft) / fWidth;
	m._32 = -(fTop + fBottom) / fHeight;
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_OrthoMatrixRH(float fWidth, float fHeight, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	m._11 = 2.0f / fWidth;
	m._22 = 2.0f / fHeight;
	m._33 = 1.0f / (fZNear - fZFar); //
	m._43 = fZNear * m._33; //
	m._44 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = m._34 = 0.0f;
	m._41 = m._42 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_PerspectiveMatrixRH(float fWidth, float fHeight, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float f2ZN = 2.0f * fZNear;
	m._11 = f2ZN / fWidth;
	m._22 = f2ZN / fHeight;
	m._33 = fZFar / (fZNear - fZFar); //
	m._43 = fZNear * m._33; //
	m._34 = -1.0f; //
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = 0.0f;
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_PerspectiveFovMatrixRH(float fFovY, float fAspect, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fYScale = 1.0f / tanf(fFovY / 2.0f);
	float fXScale = fYScale / fAspect;
	m._11 = fXScale;
	m._22 = fYScale;
	m._33 = fZFar / (fZNear - fZFar); //
	m._43 = fZNear * m._33; //
	m._34 = -1.0f; //
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = 0.0f;
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

A3DMATRIX4 a3d_OrthoOffCenterMatrixRH(float fLeft, float fRight, float fBottom, float fTop, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fWidth = fRight - fLeft;
	float fHeight = fTop - fBottom;
	m._11 = 2.0f / fWidth;
	m._22 = 2.0f / fHeight;
	m._33 = 1.0f / (fZNear - fZFar); //
	m._43 = fZNear * m._33; //
	m._44 = 1.0f;
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = m._32 = m._34 = 0.0f;
	m._41 = -(fRight + fLeft) / fWidth;
	m._42 = -(fTop + fBottom) / fHeight;
	return m;
}

A3DMATRIX4 a3d_PerspectiveOffCenterMatrixRH(float fLeft, float fRight, float fBottom, float fTop, float fZNear, float fZFar)
{
	A3DMATRIX4 m;
	float fWidth = fRight - fLeft;
	float fHeight = fTop - fBottom;
	float f2ZN = 2.0f * fZNear;
	m._11 = f2ZN / fWidth;
	m._22 = f2ZN / fHeight;
	m._33 = fZFar / (fZNear - fZFar); //
	m._43 = fZNear * m._33; //
	m._34 = -1.0f; //
	m._12 = m._13 = m._14 = 0.0f;
	m._21 = m._23 = m._24 = 0.0f;
	m._31 = (fRight + fLeft) / fWidth; //
	m._32 = (fTop + fBottom) / fHeight; //
	m._41 = m._42 = m._44 = 0.0f;
	return m;
}

bool a3d_RayIntersectTriangle(const A3DVECTOR3& vecStart, const A3DVECTOR3& vecDelta, A3DVECTOR3 * pTriVerts, float * pvFraction, A3DVECTOR3 * pVecPos)
{
	float t, u, v;
	A3DVECTOR3 v0, v1, v2;

	static const float ERR_T = 1e-6f;

	v0 = pTriVerts[0];
	v1 = pTriVerts[1];
	v2 = pTriVerts[2];

	// Find vectors for two edges sharing vert0
	A3DVECTOR3 edge1 = v1 - v0;
	A3DVECTOR3 edge2 = v2 - v0;

	// Begin calculating determinant - also used to calculate U parameter
	A3DVECTOR3 pvec;
	pvec = CrossProduct(vecDelta, edge2);

	// If determinant is near zero, ray lies in plane of triangle
	float det = DotProduct(edge1, pvec);
	if (det < ERR_T)
		return false;

	// Calculate distance from vert0 to ray origin
	A3DVECTOR3 tvec = vecStart - v0;

	// Calculate U parameter and test bounds
	u = DotProduct(tvec, pvec);
	if (u < -ERR_T || u > det + ERR_T)
		return false;

	// Prepare to test V parameter
	A3DVECTOR3 qvec;
	qvec = CrossProduct(tvec, edge1);

	// Calculate V parameter and test bounds
	v = DotProduct(vecDelta, qvec);
	if (v < -ERR_T || u + v > det + ERR_T)
		return false;

	// Calculate t, scale parameters, ray intersects triangle
	t = DotProduct(edge2, qvec);
	float fInvDet = 1.0f / det;
	t *= fInvDet;
	u *= fInvDet;
	v *= fInvDet;

	//If the line is short for touch that triangle;
	if (t < 0.0f || t > 1.0f)
		return false;

	*pvFraction = t;// * 0.99f;
	*pVecPos = vecStart + vecDelta * (*pvFraction);
	return true;
}