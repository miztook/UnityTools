#ifndef _AASSIST_H_
#define _AASSIST_H_

#include "ATypes.h"
#include <stdio.h>

const int ROUNDING_ERROR_S32 = 0;
const float ROUNDING_ERROR_f32 = 0.000001f;
const afloat64 ROUNDING_ERROR_f64 = 0.000000000001;
///////////////////////////////////////////////////////////////////////////
//
//	Define and Macro
//
///////////////////////////////////////////////////////////////////////////

#define ARAND_MAX	RAND_MAX

#define min2(a, b) (((a) > (b)) ? (b) : (a))
#define min3(a, b, c) (min2(min2((a), (b)), (c)))
#define max2(a, b) (((a) > (b)) ? (a) : (b))
#define max3(a, b, c) (max2(max2((a), (b)), (c)))
#define min4(a, b, c, d) (min2(min2((a), (b)), min2((c), (d))))
#define max4(a, b, c, d) (max2(max2((a), (b)), max2((c), (d))))

//#ifndef max
//#define max max2
//#endif

//#ifndef min
//#define min min2
//#endif

///////////////////////////////////////////////////////////////////////////
//
//	Types and Global variables
//
///////////////////////////////////////////////////////////////////////////

//	Make ID from string
auint32 a_MakeIDFromString(const char* szStr);
auint32 a_MakeIDFromLowString(const char* szStr);
auint32 a_MakeIDFromFileName(const char* szFile);

void a_CRC32_InitChecksum(auint32& uCrcvalue);
void a_CRC32_Update(auint32& uCrcvalue, const auint8 data);
void a_CRC32_UpdateChecksum(auint32 &uCrcvalue, const void* pData, aint32 uLength);
void a_CRC32_FinishChecksum(auint32& uCrcvalue);
auint32 CRC32_BlockChecksum(const void* pData, aint32 length);

bool a_GetStringAfter(const char* szBuffer, const char* szTag, char* szResult);

//	Random number generator
bool a_InitRandom();
int a_Random();
float a_Random(float fMin, float fMax);
int a_Random(int iMin, int iMax);

//  export current memory log to file
void a_ExportMemLog(const char* szPath);

bool a_Equals(float a, float b, float eps = ROUNDING_ERROR_f32);
bool a_Equals(afloat64 a, afloat64 b, afloat64 eps = ROUNDING_ERROR_f64);

inline bool a_IsPowerOfTwo(auint32 x)
{
	return (x && !(x & (x - 1)));
}

inline auint32 a_CeilPowerOfTwo(auint32 x)
{
	--x;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	++x;
	return x;
}

inline auint32 a_FloorPowerOfTwo(auint32 x)
{
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	x++;
	return x >> 1;
}

///////////////////////////////////////////////////////////////////////////
//
//	Declare of Global functions
//
///////////////////////////////////////////////////////////////////////////

template <class T>
inline float a_Magnitude2D(T fX1, T fY1, T fX2, T fY2)
{
	return sqrtf((fX1 - fX2)*(fX1 - fX2) + (fY1 - fY2)*(fY1 - fY2));
}

template <class T>
inline T a_DotProduct(T fX1, T fY1, T fX2, T fY2)
{
	return fX1 * fX2 + fY1 * fY2;
}

template <class T>
inline float a_Normalize2D(T& x, T& y)
{
	float len = sqrtf(x*x + y*y);
	if (len > 0.0f)
	{
		x /= len;
		y /= len;
	}
	return len;
}

template <class T>
inline void a_Swap(T& lhs, T& rhs)
{
	T tmp;
	tmp = lhs;
	lhs = rhs;
	rhs = tmp;
}

template <class T>
inline const T& a_Min(const T& x, const T& y)
{
	return y < x ? y : x;
}

template <class T>
inline const T& a_Max(const T& x, const T& y)
{
	return y < x ? x : y;
}

template <class T>
inline const T& a_Min(const T& x, const T& y, const T& z)
{
	return a_Min(a_Min(x, y), z);
}

template <class T>
inline const T& a_Max(const T& x, const T& y, const T& z)
{
	return a_Max(a_Max(x, y), z);
}

template <class T>
inline void a_ClampRoof(T& x, const T& max)
{
	if (x > max) x = max;
}

template <class T>
inline void a_ClampFloor(T& x, const T& min)
{
	if (x < min) x = min;
}

template <class T>
inline T a_Clamp(T x, const T& min, const T& max)
{
	if (x < min) x = min;
	if (x > max) x = max;
	return x;
}

// new rand algorithm
static int randSeed = 0;

inline void	a_Srand_(unsigned seed) {
	randSeed = seed;
}

inline int	a_Rand_(void) {
	randSeed = (69069 * randSeed + 1);
	return randSeed & 0x7fff;
}

inline float a_Random_0_to_1() {
	union {
		auint32 d;
		float f;
	} u;
	u.d = (((auint32)a_Rand_() & 0x7fff) << 8) | 0x3f800000;
	return u.f - 1.0f;
}

inline float a_Random_minus1_to_1() {
	union {
		auint32 d;
		float f;
	} u;
	u.d = (((auint32)a_Rand_() & 0x7fff) << 8) | 0x40000000;
	return u.f - 3.0f;
}

inline int	a_RandInt(int lower, int upper)
{
	return lower + (int)((upper + 1 - lower) * a_Random_0_to_1());
}

inline float a_RandFloat(float lower, float upper)
{
	return lower + (upper - lower) * a_Random_0_to_1();
}

//inline void a_Int64ToString(AString& str, const aint64 val)
//{
//	str.Format("%lld", val);
//}

inline void a_StringToInt64(aint64& val, const char* pStr)
{
	if (!pStr || !pStr[0])
		val = (aint64)0;
	else
	{
		int ret = sscanf(pStr, "%lld", &val);  //\
					//ASSERT(ret == 1);
	}
}

inline const char* a_IntToString(int iValue)
{
	static char szBuf[20];
	sprintf(szBuf, "%d", iValue);

	return szBuf;
}

struct lua_State;

void a_SetLuaState(lua_State* L);

lua_State* a_GetLuaState();

#endif	//	_AASSIST_H_
