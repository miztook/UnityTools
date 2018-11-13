#ifndef _A_TYPES_H_
#define _A_TYPES_H_

#include "compileconfig.h"

#include <cstdint>
#include <cfloat>
#include <cassert>

#if A_PLATFORM_WIN_DESKTOP

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <malloc.h>

#pragma warning(disable : 4251)
#pragma warning(disable : 4355) // this used in base initializer list
#pragma warning(disable : 4996)

#else

#include <alloca.h>

#endif

typedef uint8_t		auint8;
typedef uint16_t	auint16;
typedef uint32_t	auint32;
typedef uint64_t	auint64;

typedef	int8_t		aint8;
typedef int16_t		aint16;
typedef int32_t 	aint32;
typedef int64_t		aint64;

typedef float				afloat32;
typedef double				afloat64;

typedef char				achar;
typedef char16_t			auchar;
typedef auint8				abyte;

typedef intptr_t				aptrint;
typedef uintptr_t				auptrint;

typedef intptr_t				sptr_t;
typedef uintptr_t				ptr_t;

#define PTR_TO_INT32(x)		((aint32)((sptr_t)(x) & 0xffffffff))
#define PTR_TO_UINT32(x)	((auint32)((ptr_t)(x) & 0xffffffff))

#ifndef BYTE
typedef auint8 BYTE;
#endif

//平台相关定义
#if A_PLATFORM_WIN_DESKTOP

#define A_ALIGN(n)		__declspec(align(n))

#define AAlloca16( x )	((void *)((((uintptr_t)_alloca( (x)+15 )) + 15) & ~15))

#define A_DLL_EXPORT	__declspec(dllexport)
#define A_DLL_IMPORT	__declspec(dllimport)
#define A_DLL_LOCAL

#define LLD		"%I64d"
#define LLU		"%I64u"

typedef		HWND				window_type;
typedef		HDC					dc_type;
typedef		HGLRC				glcontext_type;

#else

#define A_ALIGN(n)		__attribute__((aligned(n)))

#define AAlloca16( x )	((void *)((((uintptr_t)alloca( (x)+15 )) + 15) & ~15))

#define A_DLL_EXPORT	__attribute__((visibility("default")))
#define A_DLL_IMPORT
#define A_DLL_LOCAL		__attribute__((visibility("hidden")))

#define LLD		"%lld"
#define LLU		"%llu"

typedef		void*				window_type;
typedef		void*				dc_type;
typedef		void*				glcontext_type;

#endif

#define A_MAX_BYTE		0xff
#define A_MAX_CHAR		0x7f
#define A_MAX_UINT16	0xffff
#define A_MAX_UINT32	0xffffffff
#define A_MAX_UINT64	0xffffffffffffffffU
#define A_MAX_INT16		0x7fff
#define A_MAX_INT32		0x7fffffff
#define A_MAX_INT64		0x7fffffffffffffff
#define A_MIN_FLT32		FLT_MIN
#define A_MAX_FLT32		FLT_MAX
#define A_MIN_FLT64		DBL_MIN
#define A_MAX_FLT64		DBL_MAX

#define		HI_UINT32(x)	(((x) >> 16) & 0xffff)
#define		LOW_UINT32(x)	((x) & 0xffff)

#ifdef      MAX_PATH
#undef      MAX_PATH
#endif
#define     MAX_PATH        260

#ifndef		QMAX_PATH
#define		QMAX_PATH	512
#endif

#ifndef NULL
#define NULL 0
#endif

//arm下的float, double和u64,s64在赋值时需要4字节对齐，必须注意struct内的对齐问题
#define MAKE_ALIGN4BYTES(x) x = (x+3) & ~3;

#define MAKE_ALIGN4BYTES_POINTER(p, base)	{ auint32 len = p - base;	\
	MAKE_ALIGN4BYTES(len)	\
	p = len + base; }

#define ABit( num )		( 1 << ( num ) )
#define AOffsetOf(s,m)   (auint32)&reinterpret_cast<const volatile abyte&>((((s *)0)->m))
#define AL(str)			L##str
#define A_SAFEDELETE(x) if ((x) != NULL) { delete x; x = NULL; }
#define A_SAFEDELETE_ARRAY(x) if ((x) != NULL) { delete[] x; x = NULL; }
#define A_SAFEFREE(x) if ((x) != NULL) { free(x); x = NULL; }

//	Text encoding.
enum ATextEncoding
{
	ATextEncodingUnknown = 0,	//	Unkown
	ATextEncodingSystem,		//	The current Windows or Linux Code-Page. This is only for system-API calls, user should NOT save files or net-transfer the result buffer.
	ATextEncodingUTF8,
	ATextEncodingGB2312,
	ATextEncodingGB18030,
	ATextEncodingBig5,
	ATextEncodingNUM,			//	Number of supported encoding
};

// MessageBox enum
enum AMessageStyle
{
	AMessageStyle_OK = 0,
	AMessageStyle_OK_CANCLE,
	AMessageStyle_YES_NO,
};

enum AMessageReturn
{
	AMessageReturn_OK = 0,
	AMessageReturn_CANCLE,
	AMessageReturn_NO,
	AMessageReturn_YES,
	AMessageReturn_OHTER
};

#if defined(_DEBUG) || defined(DEBUG)
#ifndef ASSERT
#define ASSERT	assert
#endif	//	ASSERT
#else
#undef ASSERT
#define ASSERT(x)
#endif

#define ASSERT_TODO ASSERT(false && "TODO");

//	Disable copy constructor and operator =
#define DISABLE_COPY_AND_ASSIGNMENT(ClassName)	\
	private:\
	ClassName(const ClassName&);\
	ClassName& operator = (const ClassName&);

//	Time structure
struct ATIME
{
	aint32	year;		//	year since 1900
	aint32	month;		//	[0, 11]
	aint32	day;		//	[1, 31]
	aint32	hour;		//	[0, 23]
	aint32	minute;		//	[0, 59]
	aint32	second;		//	[0, 59]
	aint32	wday;		//	day of week, [0, 6]
};

#endif //	_A_TYPES_H_
