#pragma once

#include "compileconfig.h"
#include "ATypes.h"
#include <type_traits>

#define ROUND_N_BYTES(x, n) ((x+(n-1)) & ~(n-1))
#define ROUND_4BYTES(x) ((x+3) & ~3)
#define ROUND_8BYTES(x) ((x+7) & ~7)
#define ROUND_16BYTES(x) ((x+15) & ~15)
#define ROUND_32BYTES(x) ((x+31) & ~31)

template <typename T>
struct TYPE_FUNDAMENTAL
{
	static_assert(std::is_fundamental<T>::value, "Type requires fundamental");
};

template <typename T>
struct TYPE_POINTER
{
	static_assert(std::is_pointer<T>::value, "Type requires pointer");
};

template <typename T>
struct TYPE_POLYMORPHIC
{
	static_assert(std::is_polymorphic<T>::value, "Type requires polymorphic");
};

template <typename T>
struct TYPE_ARITHMETIC
{
	static_assert(std::is_arithmetic<T>::value, "Type requires arithmetic");
};

template <typename T>
struct TYPE_POD
{
	static_assert(std::is_pod<T>::value, "Type requires POD");
};

template <typename T>
struct TYPE_TRIVIAL
{
	static_assert(std::is_trivial<T>::value, "Type requires trivial");
};

template <typename T>
struct TYPE_STANDARD_LAYOUT
{
	static_assert(std::is_standard_layout<T>::value, "Type requires standard_layout");
};

#ifndef CONTAINING_RECORD_STRICT
#define CONTAINING_RECORD_STRICT(address, type, field) (TYPE_STANDARD_LAYOUT<type>(), (type *)( \
	(char*)(address) - \
	offsetof(type, field)))
#endif

#define A_MAKEWORD(a, b)      ((auint16)(((auint8)(((ptr_t)(a)) & 0xff)) | ((auint16)((auint8)(((ptr_t)(b)) & 0xff))) << 8))
#define A_MAKEDWORD(a, b)   ((auint32)(((auint16)(((ptr_t)(a)) & 0xffff)) | ((auint32)((auint16)(((ptr_t)(b)) & 0xffff))) << 16))

#define F32_AS_DWORD(f)		(*((auint32*)&(f)))
#define DWORD_AS_F32(d)		(*((float*)&(d)))

#define FOURCC(c0, c1, c2, c3) (c0 | (c1 << 8) | (c2 << 16) | (c3 << 24))

#define		NAME_SIZE   32
#define		DEFAULT_SIZE	64

#define		FONT_TEXTURE_SIZE	512

#if defined (A_COMPILE_WITH_GLES2) || (defined (A_COMPILE_WITH_OPENGL) && defined(A_USE_WITH_GLES2))
#define		MAX_BONE_NUM		35
#define		MAX_TEXT_LENGTH		128			//每批次最大渲染字数
#else
#define		MAX_BONE_NUM		58
#define		MAX_TEXT_LENGTH		256			//每批次最大渲染字数
#endif

#define VS11	"vs_1_1"
#define VS20	"vs_2_0"
#define VS2A	"vs_2_a"
#define VS30	"vs_3_0"

#define PS11	"ps_1_1"
#define PS12	"ps_1_2"
#define PS13	"ps_1_3"
#define PS14	"ps_1_4"
#define PS20	"ps_2_0"
#define PS2A	"ps_2_a"
#define PS2B	"ps_2_b"
#define PS30	"ps_3_0"

//terrain
#define TILESIZE (533.33333f)
#define CHUNKSIZE ((TILESIZE) / 16.0f)
#define UNITSIZE (CHUNKSIZE / 8.0f)
#define ZEROPOINT (32.0f * (TILESIZE))

#define	CHUNKS_IN_TILE	16				//每个tile包括 16 X 16 个chunk

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p)      { if (p) { (p)->Release(); (p)=NULL; } }
#endif

#ifndef SAFE_DELETE
#define SAFE_DELETE(p)		{ if (p) { delete (p); (p) = NULL; } }
#endif

#ifndef SAFE_RELEASE_STRICT
#define SAFE_RELEASE_STRICT(p)      { if (p) { ULONG u = (p)->Release(); ASSERT(!u); (p)=NULL; } }
#endif

#ifndef RELEASE_ALL
#define RELEASE_ALL(x)			\
	ULONG rest = x->Release();	\
		while( rest > 0 )			\
	rest = x->Release();	\
	x = 0;
#endif

#ifndef ARRAY_COUNT
#define ARRAY_COUNT(a)		(sizeof(a)/sizeof(*a))
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(a)		(sizeof(a)/sizeof(*a))
#endif

#ifndef MAX
#define MAX(a,b) (a < b ? b : a)
#endif

#ifndef DELETE_ARRAY
#define DELETE_ARRAY(t, p)		{ delete[] (static_cast<t*>(p)); }
#endif

enum E_LOG_TYPE
{
	ELOG_GX = 0,
	ELOG_RES,
	ELOG_SOUND,
	ELOG_UI,

	ELOG_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_DRIVER_TYPE
{
	EDT_NULL = 0,
	EDT_DIRECT3D9,
	EDT_DIRECT3D11,
	EDT_OPENGL,
	EDT_GLES2,
	EDT_GLES3,
	EDT_COUNT,

	EDT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

inline const char* getEnumString(E_DRIVER_TYPE type)
{
	switch (type)
	{
	case EDT_DIRECT3D9:
		return "Direct3D9";
	case EDT_DIRECT3D11:
		return "Direct3D11";
	case EDT_OPENGL:
		return "OpenGL";
	case EDT_GLES2:
		return "GLES2";
	default:
		return "Unknown";
	}
}

enum E_TRANSFORMATION_STATE
{
	ETS_VIEW = 0,
	ETS_WORLD,
	ETS_PROJECTION,
	ETS_TEXTURE_0,
	ETS_TEXTURE_1,
	ETS_TEXTURE_2,
	ETS_TEXTURE_3,
	ETS_COUNT,

	ETS_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_VIDEO_DRIVER_FEATURE
{
	EVDF_RENDER_TO_TARGET = 0,
	EVDF_HARDWARE_TL,
	EVDF_TEXTURE_ADDRESS,
	EVDF_SEPARATE_UVWRAP,
	EVDF_MIP_MAP,
	EVDF_STENCIL_BUFFER,
	EVDF_VERTEX_SHADER_2_0,
	EVDF_VERTEX_SHADER_3_0,
	EVDF_PIXEL_SHADER_2_0,
	EVDF_PIXEL_SHADER_3_0,
	EVDF_TEXTURE_NSQUARE,
	EVDF_TEXTURE_NPOT,
	EVDF_COLOR_MASK,
	EVDF_MULTIPLE_RENDER_TARGETS,
	EVDF_MRT_COLOR_MASK,
	EVDF_MRT_BLEND_FUNC,
	EVDF_MRT_BLEND,
	EVDF_STREAM_OFFSET,
	EVDF_W_BUFFER,

	//! Supports Shader model 4
	EVDF_VERTEX_SHADER_4_0,
	EVDF_PIXEL_SHADER_4_0,
	EVDF_GEOMETRY_SHADER_4_0,
	EVDF_STREAM_OUTPUT_4_0,
	EVDF_COMPUTING_SHADER_4_0,

	//! Supports Shader model 4.1
	EVDF_VERTEX_SHADER_4_1,
	EVDF_PIXEL_SHADER_4_1,
	EVDF_GEOMETRY_SHADER_4_1,
	EVDF_STREAM_OUTPUT_4_1,
	EVDF_COMPUTING_SHADER_4_1,

	//! Supports Shader model 5.0
	EVDF_VERTEX_SHADER_5_0,
	EVDF_PIXEL_SHADER_5_0,
	EVDF_GEOMETRY_SHADER_5_0,
	EVDF_STREAM_OUTPUT_5_0,
	EVDF_TESSELATION_SHADER_5_0,
	EVDF_COMPUTING_SHADER_5_0,

	//! Supports texture multisampling
	EVDF_TEXTURE_MULTISAMPLING,
	EVDF_COUNT,

	EVDF_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum ECOLOR_FORMAT
{
	ECF_UNKNOWN = 0,

	//8
	ECF_A8,
	//16
	ECF_A8L8,

	ECF_A1R5G5B5,			//argb in dx9 and abgr in gl and dx11
	ECF_R5G6B5,

	//24
	ECF_R8G8B8,

	//32
	//ECF_A8B8G8R8,
	ECF_A8R8G8B8,			//argb in dx9 and abgr in gl and dx11

	//float for RenderTarget Buffer
	ECF_ARGB32F,

	//DXT
	ECF_DXT1,
	ECF_DXT3,
	ECF_DXT5,

	//PVR
	ECF_PVRTC1_RGB_2BPP,
	ECF_PVRTC1_RGBA_2BPP,
	ECF_PVRTC1_RGB_4BPP,
	ECF_PVRTC1_RGBA_4BPP,

	//ETC
	ECF_ETC1_RGB,
	ECF_ETC1_RGBA,

	//ATC
	ECF_ATC_RGB,
	ECF_ATC_RGBA_EXPLICIT,
	ECF_ATC_RGBA_INTERPOLATED,

	//DEPTH
	ECF_D16,
	ECF_D24,
	ECF_D24S8,
	ECF_D32,

	ECF_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

struct STexFormatDesc
{
	ECOLOR_FORMAT format;
	auint32 blockBytes;
	auint32 blockWidth;
	auint32 blockHeight;
	auint32 minWidth;
	auint32 minHeight;
	char text[32];
	bool hasAlpha;
};

static STexFormatDesc g_FormatDesc[] =
{
	{ ECF_UNKNOWN, 0, 0, 0, 0, 0, "UNKNOWN", false, },
	{ ECF_A8, 1, 1, 1, 1, 1, "A8", true, },
	{ ECF_A8L8, 2, 1, 1, 1, 1, "A8L8", true, },
	{ ECF_A1R5G5B5, 2, 1, 1, 1, 1, "A1R5G5B5", false, },
	{ ECF_R5G6B5, 2, 1, 1, 1, 1, "R5G6B5", false, },
	{ ECF_R8G8B8, 3, 1, 1, 1, 1, "R8G8B8", false, },
	{ ECF_A8R8G8B8, 4, 1, 1, 1, 1, "A8R8G8B8", true, },
	{ ECF_ARGB32F, 16, 1, 1, 1, 1, "ARGB32F", true },
	{ ECF_DXT1, 8, 4, 4, 4, 4, "DXT1", false, },
	{ ECF_DXT3, 16, 4, 4, 4, 4, "DXT3", true, },
	{ ECF_DXT5, 16, 4, 4, 4, 4, "DXT5", true, },
	{ ECF_PVRTC1_RGB_2BPP, 8, 8, 4, 16, 8, "PVRTC1_RGB_2BPP", false, },
	{ ECF_PVRTC1_RGBA_2BPP, 8, 8, 4, 16, 8, "PVRTC1_RGBA_2BPP", true, },
	{ ECF_PVRTC1_RGB_4BPP, 8, 4, 4, 8, 8, "PVRTC1_RGB_4BPP", false, },
	{ ECF_PVRTC1_RGBA_4BPP, 8, 4, 4, 8, 8, "PVRTC1_RGBA_4BPP", true, },
	{ ECF_ETC1_RGB, 8, 4, 4, 4, 4, "ETC1_RGB", false, },
	{ ECF_ETC1_RGBA, 8, 4, 4, 4, 4, "ETC1_RGBA", true, },
	{ ECF_ATC_RGB, 8, 4, 4, 4, 4, "ATC_RGB", false, },
	{ ECF_ATC_RGBA_EXPLICIT, 16, 4, 4, 4, 4, "ATC_RGBA_EXPLICIT", true, },
	{ ECF_ATC_RGBA_INTERPOLATED, 16, 4, 4, 4, 4, "ATC_RGBA_INTERPOLATED", true, },

	{ ECF_D16, 2, 1, 1, 1, 1, "DEPTH16", false, },
	{ ECF_D24, 4, 1, 1, 1, 1, "DEPTH24", false, },
	{ ECF_D24S8, 4, 1, 1, 1, 1, "DEPTH24STENCIL8", false, },
	{ ECF_D32, 4, 1, 1, 1, 1, "DEPTH32", false, },
};

inline bool hasAlpha(ECOLOR_FORMAT format)
{
	ASSERT(static_cast<auint32>(format) < ARRAY_COUNT(g_FormatDesc));
	return g_FormatDesc[format].hasAlpha;
}

inline auint32 getBytesPerPixelFromFormat(ECOLOR_FORMAT format)
{
	ASSERT(static_cast<auint32>(format) < ARRAY_COUNT(g_FormatDesc));
	return g_FormatDesc[format].blockBytes;
}

inline bool isCompressedFormat(ECOLOR_FORMAT format)
{
	ASSERT(static_cast<auint32>(format) < ARRAY_COUNT(g_FormatDesc));
	return g_FormatDesc[format].blockWidth > 1;
}

inline bool isCompressedWithAlphaFormat(ECOLOR_FORMAT format)
{
	return format == ECF_ETC1_RGBA;
}

inline const char* getColorFormatString(ECOLOR_FORMAT format)
{
	ASSERT(static_cast<auint32>(format) < ARRAY_COUNT(g_FormatDesc));
	return g_FormatDesc[format].text;
}

inline void getImageSize(ECOLOR_FORMAT format, auint32 width, auint32 height, auint32& w, auint32& h)
{
	ASSERT(static_cast<auint32>(format) < ARRAY_COUNT(g_FormatDesc));

	auint32 bw = g_FormatDesc[format].blockWidth;
	auint32 bh = g_FormatDesc[format].blockHeight;

	auint32 mw = g_FormatDesc[format].minWidth;
	auint32 mh = g_FormatDesc[format].minHeight;

	if (bw > 1)			//compressed
	{
		w = MAX(mw, (width + (bw - 1))) / bw;
		h = MAX(mh, (height + (bh - 1))) / bh;
	}
	else
	{
		w = width;
		h = height;
	}
}

inline void getImagePitchAndBytes(ECOLOR_FORMAT format, auint32 width, auint32 height, auint32& pitch, auint32& bytes)
{
	auint32 bpp = getBytesPerPixelFromFormat(format);

	auint32 w, h;
	getImageSize(format, width, height, w, h);

	pitch = w * bpp;
	bytes = pitch * h;
}

enum E_SHADER_VERSION
{
	ESV_VS_1_1 = 0,
	ESV_VS_2_0,
	ESV_VS_2_a,
	ESV_VS_3_0,
	ESV_VS_4_0,
	ESV_VS_4_1,
	ESV_VS_5_0,

	ESV_PS_1_1,
	ESV_PS_1_2,
	ESV_PS_1_3,
	ESV_PS_1_4,
	ESV_PS_2_0,
	ESV_PS_2_a,
	ESV_PS_2_b,
	ESV_PS_3_0,
	ESV_PS_4_0,
	ESV_PS_4_1,
	ESV_PS_5_0,

	ESV_GS_4_0,

	ESV_COUNT,

	ESV_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_VERTEX_TYPE
{
	EVT_INVALID = -1,
	EVT_P = 0,
	EVT_PC,			//for bounding box
	EVT_PC2,
	EVT_PCT,
	EVT_PCT2,
	EVT_PN,
	EVT_PNC,
	EVT_PNT,
	EVT_PNT2,
	EVT_PT,
	EVT_PNCT,
	EVT_PNCT2,
	EVT_PNT2B,
	EVT_PNT2WAB,
	EVT_PNTgT,
	EVT_PNTBCT2,
	EVT_COUNT,

	EVT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

inline bool vertexHasTexture(E_VERTEX_TYPE vType)
{
	switch (vType)
	{
	case EVT_PCT:
	case EVT_PCT2:
	case EVT_PNT:
	case EVT_PT:
	case EVT_PNCT:
	case EVT_PNCT2:
	case EVT_PNT2B:
	case EVT_PNT2WAB:
	case EVT_PNTgT:
	case EVT_PNTBCT2:
		return true;
	default:
		return false;
	}
}

inline bool vertexHasColor(E_VERTEX_TYPE type)
{
	return type == EVT_PC ||
		type == EVT_PC2 ||
		type == EVT_PCT ||
		type == EVT_PNC ||
		type == EVT_PNCT ||
		type == EVT_PNCT2 ||
		type == EVT_PNTBCT2;
}

enum E_MESHBUFFER_MAPPING
{
	EMM_SOFTWARE = 0,
	EMM_STATIC,
	EMM_DYNAMIC,
	EMM_COUNT,

	EMM_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_INDEX_TYPE
{
	EIT_16BIT = 0,
	EIT_32BIT,
	EIT_COUNT,

	EIT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_PRIMITIVE_TYPE
{
	EPT_POINTS = 0,
	EPT_LINE_STRIP,
	EPT_LINES,
	EPT_TRIANGLE_STRIP,
	EPT_TRIANGLES,
	EPT_COUNT,

	EPT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

inline auint32 getPrimitiveCount(E_PRIMITIVE_TYPE primType, auint32 count)
{
	auint32 p = 0;

	switch (primType)
	{
	case EPT_POINTS:
		p = count;
		break;
	case EPT_LINES:
		ASSERT(count >= 2);
		p = count / 2;
		break;
	case EPT_LINE_STRIP:
		ASSERT(count >= 2);
		p = count - 1;
		break;
	case EPT_TRIANGLE_STRIP:
		ASSERT(count >= 3);
		p = count - 2;
		break;
	case EPT_TRIANGLES:
		ASSERT(count >= 3);
		p = count / 3;
		break;
	default:
		ASSERT(false);
	}
	return p;
}

inline auint32 getIndexCount(E_PRIMITIVE_TYPE primType, auint32 primCount)
{
	auint32 p = 0;

	switch (primType)
	{
	case EPT_POINTS:
		p = primCount;
		break;
	case EPT_LINES:
		p = primCount * 2;
		break;
	case EPT_LINE_STRIP:
		p = primCount + 1;
		break;
	case EPT_TRIANGLE_STRIP:
		p = primCount + 2;
		break;
	case EPT_TRIANGLES:
		p = primCount * 3;
		break;
	default:
		ASSERT(false);
	}
	return p;
}

enum E_MATERIAL_TYPE
{
	EMT_2D = 0,
	EMT_LINE,
	EMT_SOLID,

	EMT_TERRAIN_MULTIPASS,

	EMT_ALPHA_TEST,
	EMT_TRANSAPRENT_ALPHA_BLEND_TEST,
	EMT_TRANSPARENT_ALPHA_BLEND,
	EMT_TRANSPARENT_ONE_ALPHA,
	EMT_TRANSPARENT_ADD_ALPHA,
	EMT_TRANSPARENT_ADD_COLOR,
	EMT_TRANSPARENT_MODULATE,
	EMT_TRANSPARENT_MODULATE_X2,
	EMT_TRANSPARENT_ONE_ONE,

	EMT_COUNT,

	EMT_FORCE_8BIT_DO_NOT_USE = 0x7f
};

enum E_COMPARISON_FUNC
{
	ECFN_NEVER = 0,
	ECFN_LESSEQUAL,
	ECFN_EQUAL,
	ECFN_LESS,
	ECFN_NOTEQUAL,
	ECFN_GREATEREQUAL,
	ECFN_GREATER,
	ECFN_ALWAYS,

	ECFN_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_BLEND_OP
{
	EBO_ADD = 0,
	EBO_SUBSTRACT,

	EBO_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_BLEND_FACTOR
{
	EBF_ZERO = 0,
	EBF_ONE,
	EBF_DST_COLOR,
	EBF_ONE_MINUS_DST_COLOR,
	EBF_SRC_COLOR,
	EBF_ONE_MINUS_SRC_COLOR,
	EBF_SRC_ALPHA,
	EBF_ONE_MINUS_SRC_ALPHA,
	EBF_DST_ALPHA,
	EBF_ONE_MINUS_DST_ALPHA,
	EBF_SRC_ALPHA_SATURATE,

	EBF_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_TEXTURE_OP
{
	ETO_DISABLE = 0,
	ETO_ARG1,
	ETO_MODULATE,
	ETO_MODULATE_X2,
	ETO_MODULATE_X4,

	ETO_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_TEXTURE_ARG
{
	ETA_CURRENT = 0,
	ETA_TEXTURE,
	ETA_DIFFUSE,

	ETA_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_TEXTURE_ADDRESS
{
	ETA_U = 0,
	ETA_V,
	ETA_W,
	ETA_COUNT,
};

enum E_TEXTURE_CLAMP
{
	ETC_REPEAT = 0,
	ETC_CLAMP,
	ETC_CLAMP_TO_BORDER,
	ETC_MIRROR,
	ETC_MIRROR_CLAMP,
	ETC_MIRROR_CLAMP_TO_BORDER,
	ETC_COUNT,

	ETC_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_TEXTURE_FILTER
{
	ETF_NONE = 0,
	ETF_BILINEAR,
	ETF_TRILINEAR,
	ETF_ANISOTROPIC_X1,
	ETF_ANISOTROPIC_X2,
	ETF_ANISOTROPIC_X4,
	ETF_ANISOTROPIC_X8,
	ETF_ANISOTROPIC_X16,

	ETF_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

inline auint8 getAnisotropic(E_TEXTURE_FILTER filter)
{
	switch (filter)
	{
	case ETF_ANISOTROPIC_X1:
		return 1;
	case ETF_ANISOTROPIC_X2:
		return 2;
	case ETF_ANISOTROPIC_X4:
		return 4;
	case ETF_ANISOTROPIC_X8:
		return 8;
	case ETF_ANISOTROPIC_X16:
		return 16;
	default:
		return 1;
	}
}

#define  MATERIAL_MAX_TEXTURES		7

enum E_LIGHT_TYPE
{
	ELT_POINT = 0,
	ELT_SPOT,
	ELT_DIRECTIONAL,
	ELT_ENV,

	ELT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_CULL_MODE
{
	ECM_NONE = 0,
	ECM_FRONT,
	ECM_BACK,

	ECM_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_ANTI_ALIASING_MODE
{
	EAAM_OFF = 0,
	EAAM_SIMPLE,
	EAAM_LINE_SMOOTH,

	EAAM_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

//雾
enum E_FOG_TYPE
{
	EFT_FOG_NONE = 0,
	EFT_FOG_EXP,
	EFT_FOG_EXP2,
	EFT_FOG_LINEAR,

	EFT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_GEOMETRY_TYPE
{
	EGT_CUBE = 0,
	EGT_SPHERE,
	EGT_SKYDOME,
	EGT_GRID,

	EGT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_VS_TYPE
{
	EVST_TERRAIN = 0,
	EVST_TERRAINWATER,

	EVST_DEFAULT_P,
	EVST_DEFAULT_PC,
	EVST_DEFAULT_PCT,
	EVST_DEFAULT_PN,
	EVST_DEFAULT_PNC,
	EVST_DEFAULT_PNCT,
	EVST_DEFAULT_PNCT2,
	EVST_DEFAULT_PNT,
	EVST_DEFAULT_PT,

	EVST_DISTANTBOARD,
	EVST_SCREENQUAD,

	EVST_SKINMODEL_SKIN_T1,
	EVST_SKINMODEL_RIGID_T1,
	EVST_SKINMODEL_SKIN_T1_ES,
	EVST_SKINMODEL_RIGID_T1_ES,

	EVST_LITMODEL_VERTEXLIGHT_T1,
	EVST_LITMODEL_LIGHTMAP_T2,

	//editors
	EVST_CUSTOM_BEGIN,

	EVST_CUSTOM_END = EVST_CUSTOM_BEGIN + 100,

	EVST_COUNT,

	EVST_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_PS_TYPE
{
	EPST_DEFAULT_P = 0,
	EPST_DEFAULT_PC,
	EPST_DEFAULT_PCT,
	EPST_DEFAULT_PN,
	EPST_DEFAULT_PNC,
	EPST_DEFAULT_PNCT,
	EPST_DEFAULT_PNCT2,
	EPST_DEFAULT_PNT,
	EPST_DEFAULT_PT,

	EPST_UI,
	EPST_UI_ALPHA,
	EPST_UI_ALPHACHANNEL,
	EPST_UI_ALPHA_ALPHACHANNEL,

	EPST_TERRAIN_1LAYER,
	EPST_TERRAIN_2LAYER,
	EPST_TERRAIN_3LAYER,
	EPST_TERRAIN_4LAYER,

	EPST_TERRAIN_WATER,

	EPST_DISTANTBOARD,

	//blend
	EPST_COMBINERS_MOD,
	EPST_COMBINERS_OPAQUE,

	EPST_COMBINERS_MOD_ES,
	EPST_COMBINERS_OPAQUE_ES,

	EPST_LITMODEL_LIGHTMAP_MOD,
	EPST_LITMODEL_LIGHTMAP_OPAQUE,
	EPST_LITMODEL_VERTEXLIGHT_MOD,
	EPST_LITMODEL_VERTEXLIGHT_OPAQUE,

	//editor
	EPST_CUSTOM_BEGIN,

	EPST_CUSTOM_END = EPST_CUSTOM_BEGIN + 100,

	EPST_COUNT,

	EPST_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_UNIFORM_TYPE
{
	EUT_FLOAT = 0,
	EUT_VEC2,
	EUT_VEC3,
	EUT_VEC4,
	EUT_MAT2,
	EUT_MAT3,
	EUT_MAT4,
	EUT_SAMPLER1D,
	EUT_SAMPLER2D,
	EUT_SAMPLER3D,

	EUT_COUNT,
	EUT_FORCE_8_BIT_DO_NOT_USE = 0x7f
};

enum E_MATERIAL_LIGHT
{
	EML_AMBIENT = 0,
	EML_DIFFUSE,
	EML_SPECULAR,

	EML_COUNT
};

enum E_RENDERINST_TYPE
{
	ERT_NONE = 0,
	ERT_SKY,
	ERT_TERRAIN,			//地形
	ERT_LITMESH,		//建筑
	ERT_MESH,					//角色模型,m2
	ERT_ALPHATEST,
	ERT_GFX,
	ERT_TRANSPARENT,
	ERT_WATER,
	ERT_UIGFX,				//UI特效

	ERT_WIRE,						//编辑

	ERT_COUNT,

	ERT_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_LEVEL
{
	EL_DISABLE = 0,
	EL_LOW,
	EL_FAIR,
	EL_GOOD,
	EL_HIGH,
	EL_ULTRA,

	EL_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_TERRAIN_BLOCK_LOAD
{
	ETBL_3X3 = 0,
	ETBL_5X5,
	ETBL_7X7,
	ETBL_9X9,
};

class IAdtLoadSizeChangedCallback
{
public:
	virtual void OnAdtLoadSizeChanged(E_TERRAIN_BLOCK_LOAD size) = 0;
};

enum E_INPUT_DEVICE
{
	EID_KEYBOARD = 0,
	EID_MOUSE,
	EID_JOYSTICK,

	EID_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_MOUSE_BUTTON
{
	EMB_NONE = 0,
	EMB_LEFT = 1,
	EMB_RIGHT = 2,
	EMB_MIDDLE = 4,

	EMB_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_MODIFIER_KEY
{
	EMK_NONE = 0,
	EMK_SHIFT = 1,
	EMK_CTRL = 2,
	EMK_ALT = 4,
	EMK_LEFTMOUSE = 8,
	EMK_RIGHTMOUSE = 16,
	EMK_MIDDLEMOUSE = 32,

	EMK_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};

enum E_INPUT_MESSAGE
{
	InputMessage_None = 0,
	Mouse_LeftButtonDown = 1,
	Mouse_LeftButtonUp,
	Mouse_RightButtonDown,
	Mouse_RightButtonUp,
	Mouse_Move,

	Key_Down = 100,
	Key_Up,
	Key_Char,
};

enum E_RECT_UVCOORDS
{
	ERU_00_11 = 0,
	ERU_01_10,
	ERU_10_01,
	ERU_11_00,

	ERU_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
};
