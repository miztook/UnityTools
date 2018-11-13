#ifndef _A3DTYPES_H_
#define _A3DTYPES_H_

#include "ATypes.h"
#include "A3DVector.h"
#include "A3DMatrix.h"
#include "A3DQuaternion.h"
#include "ARect.h"

typedef aint32		A3DRESULT;	//	Return code data type;

typedef APointI		A3DPOINT2;
typedef ARectI		A3DRECT;
typedef auint32		HA3DFONT;

#define MAX_TEX_LAYERS		4
#define MAX_CLIP_PLANES		6	//	D3DMAXUSERCLIPPLANES = 32, but 6 is enough for us ?

class A3DCOLOR
{
public:
	//
	A3DCOLOR() : color(0xffffffff){ }
	A3DCOLOR(auint32 a, auint32 r, auint32 g, auint32 b) : color(((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)) {}
	A3DCOLOR(auint32 r, auint32 g, auint32 b) : color(((0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)){}
	A3DCOLOR(auint32 clr) :color(clr){}

	operator auint32() { return color; }

public:
	//
	auint32 getAlpha() const { return color >> 24; }
	auint32 getRed() const { return (color >> 16) & 0xff; }
	auint32 getGreen() const { return (color >> 8) & 0xff; }
	auint32 getBlue() const { return color & 0xff; }

	void set(auint32 a, auint32 r, auint32 g, auint32 b) { color = (((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)); }

	A3DCOLOR operator+(const A3DCOLOR& other) const
	{
		return A3DCOLOR(a_Min(getAlpha() + other.getAlpha(), 255u),
			a_Min(getRed() + other.getRed(), 255u),
			a_Min(getGreen() + other.getGreen(), 255u),
			a_Min(getBlue() + other.getBlue(), 255u));
	}

	bool operator==(const A3DCOLOR& other) const { return other.color == color; }
	bool operator!=(const A3DCOLOR& other) const { return other.color != color; }

	static A3DCOLOR interpolate(const A3DCOLOR& a, const A3DCOLOR& b, float d, bool alpha)
	{
		a_Clamp(d, 0.f, 1.f);
		const float inv = 1.0f - d;

		return A3DCOLOR(alpha ? (auint32)(a.getAlpha()*inv + b.getAlpha()*d) : 255,
			(auint32)(a.getRed()*inv + b.getRed()*d),
			(auint32)(a.getGreen()*inv + b.getGreen()*d),
			(auint32)(a.getBlue()*inv + b.getBlue()*d));
	}

	static A3DCOLOR multiply(const A3DCOLOR& a, const A3DCOLOR& b);

	void setAlpha(auint32 a) { color = ((a & 0xff) << 24) | (color & 0x00ffffff); }
	void setRed(auint32 r) { color = ((r & 0xff) << 16) | (color & 0xff00ffff); }
	void setGreen(auint32 g) { color = ((g & 0xff) << 8) | (color & 0xffff00ff); }
	void setBlue(auint32 b) { color = (b & 0xff) | (color & 0xffffff00); }

	A3DCOLOR changeRB() const
	{
		return A3DCOLOR(getAlpha(), getBlue(), getGreen(), getRed());
	}

	float getLuminance() const
	{
		return 0.3f*getRed() + 0.59f*getGreen() + 0.11f*getBlue();
	}

	auint32 getAverage() const
	{
		return (getRed() + getGreen() + getBlue()) / 3;
	}

	static const A3DCOLOR& White() { static A3DCOLOR m(255, 255, 255); return m; }
	static const A3DCOLOR& Red() { static A3DCOLOR m(255, 0, 0); return m; }
	static const A3DCOLOR& Green() { static A3DCOLOR m(0, 255, 0); return m; }
	static const A3DCOLOR& Blue() { static A3DCOLOR m(0, 0, 255); return m; }
	static const A3DCOLOR& Yellow() { static A3DCOLOR m(255, 255, 0); return m; }
	static const A3DCOLOR& Black() { static A3DCOLOR m(0, 0, 0); return m; }
	static const A3DCOLOR& Gray() { static A3DCOLOR m(192, 192, 192); return m; }
	static const A3DCOLOR& Cyan() { static A3DCOLOR m(0, 255, 255); return m; }
	static const A3DCOLOR& Magenta() { static A3DCOLOR m(255, 0, 255); return m; }
	static const A3DCOLOR& DarkRed() { static A3DCOLOR m(128, 0, 0); return m; }
	static const A3DCOLOR& DarkGreen() { static A3DCOLOR m(0, 128, 0); return m; }
	static const A3DCOLOR& DarkBlue() { static A3DCOLOR m(0, 0, 128); return m; }

	A3DCOLOR toBGRA() const { return A3DCOLOR(getAlpha(), getBlue(), getGreen(), getRed()); }

public:
	auint32 color;

public:
	static auint16 A8R8G8B8toA1R5G5B5(auint32 color);
	static auint32 A1R5G5B5toA8R8G8B8(auint16 color);
	static auint16 X8R8G8B8toA1R5G5B5(auint32 color);
	static auint16 A8R8G8B8toR5G6B5(auint32 color);
	static auint32 R5G6B5toA8R8G8B8(auint16 color);
	static auint16 R5G6B5toA1R5G5B5(auint16 color);
	static auint16 A1R5G5B5toR5G6B5(auint16 color);
	static auint16 RGB16(auint32 r, auint32 g, auint32 b);
	static auint16 RGBA16(auint32 r, auint32 g, auint32 b, auint32 a = 0xff);
	static auint16 RGB16from16(auint16 r, auint16 g, auint16 b);
};

//	Color value
class A3DCOLORVALUE
{
public:		//	Constructors and Destructors

	A3DCOLORVALUE() { r = g = b = a = 1.0f; }
	A3DCOLORVALUE(float _r, float _g, float _b) { r = _r; g = _g; b = _b; a = 1.0f; }
	A3DCOLORVALUE(float _r, float _g, float _b, float _a) { r = _r; g = _g; b = _b; a = _a; }
	A3DCOLORVALUE(float c) { r = c; g = c; b = c; a = c; }
	A3DCOLORVALUE(const A3DCOLORVALUE& v) { r = v.r; g = v.g; b = v.b; a = v.a; }
	A3DCOLORVALUE(A3DCOLOR Color);

public:		//	Attributes

	float r, g, b, a;

public:		//	Operations

	//	Operator *
	friend A3DCOLORVALUE operator * (const A3DCOLORVALUE& v, float s) { return A3DCOLORVALUE(v.r * s, v.g * s, v.b * s, v.a * s); }
	friend A3DCOLORVALUE operator * (float s, const A3DCOLORVALUE& v) { return A3DCOLORVALUE(v.r * s, v.g * s, v.b * s, v.a * s); }
	friend A3DCOLORVALUE operator * (const A3DCOLORVALUE& v1, const A3DCOLORVALUE& v2) { return A3DCOLORVALUE(v1.r*v2.r, v1.g*v2.g, v1.b*v2.b, v1.a*v2.a); }
	//	Operator + and -
	friend A3DCOLORVALUE operator + (const A3DCOLORVALUE& v1, const A3DCOLORVALUE& v2) { return A3DCOLORVALUE(v1.r + v2.r, v1.g + v2.g, v1.b + v2.b, v1.a + v2.a); }
	friend A3DCOLORVALUE operator - (const A3DCOLORVALUE& v1, const A3DCOLORVALUE& v2) { return A3DCOLORVALUE(v1.r - v2.r, v1.g - v2.g, v1.b - v2.b, v1.a - v2.a); }
	//	Operator != and ==
	friend bool operator != (const A3DCOLORVALUE& v1, const A3DCOLORVALUE& v2) { return (v1.r != v2.r || v1.g != v2.g || v1.b != v2.b || v1.a != v2.a); }
	friend bool operator == (const A3DCOLORVALUE& v1, const A3DCOLORVALUE& v2) { return (v1.r == v2.r && v1.g == v2.g && v1.b == v2.b && v1.a == v2.a); }
	//	Operator *=
	const A3DCOLORVALUE& operator *= (float s) { r *= s; g *= s; b *= s; a *= s; return *this; }
	const A3DCOLORVALUE& operator *= (const A3DCOLORVALUE& v) { r *= v.r; g *= v.g; b *= v.b; a *= v.a; return *this; }
	//	Operator += and -=
	const A3DCOLORVALUE& operator += (const A3DCOLORVALUE& v) { r += v.r; g += v.g; b += v.b; a += v.a; return *this; }
	const A3DCOLORVALUE& operator -= (const A3DCOLORVALUE& v) { r -= v.r; g -= v.g; b -= v.b; a -= v.a; return *this; }
	//	Operator =
	A3DCOLORVALUE& operator = (const A3DCOLORVALUE& v) { r = v.r; g = v.g; b = v.b; a = v.a; return *this; }
	A3DCOLORVALUE& operator = (A3DCOLOR Color);

	//	Set value
	void Set(float _r, float _g, float _b, float _a) { r = _r; g = _g; b = _b; a = _a; }

	//	Clamp values
	void ClampRoof() { if (r > 1.0f) r = 1.0f; if (g > 1.0f) g = 1.0f; if (b > 1.0f) b = 1.0f; if (a > 1.0f) a = 1.0f; }
	void ClampFloor() { if (r < 0.0f) r = 0.0f; if (g < 0.0f) g = 0.0f; if (b < 0.0f) b = 0.0f; if (a < 0.0f) a = 0.0f; }
	void Clamp()
	{
		if (r > 1.0f) r = 1.0f; else if (r < 0.0f) r = 0.0f;
		if (g > 1.0f) g = 1.0f; else if (g < 0.0f) g = 0.0f;
		if (b > 1.0f) b = 1.0f; else if (b < 0.0f) b = 0.0f;
		if (a > 1.0f) a = 1.0f; else if (a < 0.0f) a = 0.0f;
	}

	static A3DCOLORVALUE interpolate(const A3DCOLORVALUE& a, const A3DCOLORVALUE& b, float d, bool alpha)
	{
		a_Clamp(d, 0.f, 1.f);
		const float inv = 1.0f - d;

		return A3DCOLORVALUE(
			(a.getRed()*inv + b.getRed()*d),
			(a.getGreen()*inv + b.getGreen()*d),
			(a.getBlue()*inv + b.getBlue()*d),
			alpha ? (a.getAlpha()*inv + b.getAlpha()*d) : 1.0f);
	}

	void setAlpha(float v) { a = v; }
	void setRed(float v) { r = v; }
	void setGreen(float v) { g = v; }
	void setBlue(float v) { b = v; }

	float getAlpha() const { return a; }
	float getRed() const { return r; }
	float getGreen() const { return g; }
	float getBlue() const { return b; }

	//	Convert to A3DCOLOR
	A3DCOLOR ToRGBAColor() const;
};

struct A3DHSVCOLORVALUE
{
	float	h;
	float	s;
	float	v;
	float	a;
public:
	A3DHSVCOLORVALUE() { h = 0.0f; s = 0.0f; v = 0.0f; a = 0.0f; }
	A3DHSVCOLORVALUE(float _h, float _s, float _v, float _a) { h = _h; s = _s; v = _v; a = _a; }
	A3DHSVCOLORVALUE(float c) { h = c; s = c; v = c; a = c; }
};

//Viewport Parameters;
struct A3DVIEWPORTPARAM
{
	auint32	X;
	auint32	Y;
	auint32	Width;
	auint32	Height;
	float	MinZ;
	float	MaxZ;
};

struct A3DMATERIALPARAM
{
	A3DMATERIALPARAM()
		: Ambient(1.0f), Diffuse(1.0f), Emissive(1.0f), Specular(0.0f)
	{
		Power = 1.0f;
	}
	A3DCOLORVALUE   Diffuse;
	A3DCOLORVALUE   Ambient;
	A3DCOLORVALUE   Specular;
	A3DCOLORVALUE   Emissive;
	float           Power;
};

inline auint16 A3DCOLOR::A8R8G8B8toA1R5G5B5(auint32 c)
{
	return (auint16)((c & 0x80000000) >> 16 |
		(c & 0x00F80000) >> 9 |
		(c & 0x0000F800) >> 6 |
		(c & 0x000000F8) >> 3);
}

inline auint32 A3DCOLOR::A1R5G5B5toA8R8G8B8(auint16 c)
{
	return (((-((aint32)c & 0x00008000) >> (aint32)31) & 0xFF000000) |
		((c & 0x00007C00) << 9) | ((c & 0x00007000) << 4) |
		((c & 0x000003E0) << 6) | ((c & 0x00000380) << 1) |
		((c & 0x0000001F) << 3) | ((c & 0x0000001C) >> 2)
		);
}

inline auint16 A3DCOLOR::X8R8G8B8toA1R5G5B5(auint32 c)
{
	return (auint16)(0x8000 |
		(c & 0x00F80000) >> 9 |
		(c & 0x0000F800) >> 6 |
		(c & 0x000000F8) >> 3);
}

inline auint16 A3DCOLOR::A8R8G8B8toR5G6B5(auint32 c)
{
	return (auint16)((c & 0x00F80000) >> 8 |
		(c & 0x0000FC00) >> 5 |
		(c & 0x000000F8) >> 3);
}

inline auint32 A3DCOLOR::R5G6B5toA8R8G8B8(auint16 c)
{
	return 0xFF000000 |
		((c & 0xF800) << 8) |
		((c & 0x07E0) << 5) |
		((c & 0x001F) << 3);
}

inline auint16 A3DCOLOR::R5G6B5toA1R5G5B5(auint16 c)
{
	return 0x8000 | (((c & 0xFFC0) >> 1) | (c & 0x1F));
}

inline auint16 A3DCOLOR::A1R5G5B5toR5G6B5(auint16 c)
{
	return (((c & 0x7FE0) << 1) | (c & 0x1F));
}

inline auint16 A3DCOLOR::RGB16(auint32 r, auint32 g, auint32 b)
{
	return RGBA16(r, g, b);
}

inline auint16 A3DCOLOR::RGBA16(auint32 r, auint32 g, auint32 b, auint32 a/*=0xff*/)
{
	return (auint16)((a & 0x80) << 8 |
		(r & 0xF8) << 7 |
		(g & 0xF8) << 2 |
		(b & 0xF8) >> 3);
}

inline auint16 A3DCOLOR::RGB16from16(auint16 r, auint16 g, auint16 b)
{
	return (0x8000 |
		(r & 0x1F) << 10 |
		(g & 0x1F) << 5 |
		(b & 0x1F));
}

inline A3DCOLOR A3DCOLOR::multiply(const A3DCOLOR& a, const A3DCOLOR& b)
{
	A3DCOLORVALUE cv = A3DCOLORVALUE(a) * A3DCOLORVALUE(b);
	return cv.ToRGBAColor();
}

inline A3DCOLORVALUE::A3DCOLORVALUE(A3DCOLOR Color)
{
	static float fTemp = 1.0f / 255.0f;
	a = Color.getAlpha() * fTemp;
	r = Color.getRed() * fTemp;
	g = Color.getGreen() * fTemp;
	b = Color.getBlue() * fTemp;
}

inline A3DCOLORVALUE& A3DCOLORVALUE::operator = (A3DCOLOR Color)
{
	static float fTemp = 1.0f / 255.0f;
	a = Color.getAlpha() * fTemp;
	r = Color.getRed() * fTemp;
	g = Color.getGreen() * fTemp;
	b = Color.getBlue() * fTemp;
	return *this;
}

//	Convert color value to A3DCOLOR
inline A3DCOLOR A3DCOLORVALUE::ToRGBAColor() const
{
	int _a = (int)(a * 255);
	int _r = (int)(r * 255);
	int _g = (int)(g * 255);
	int _b = (int)(b * 255);
	return A3DCOLOR(min2(_a, 255), min2(_r, 255), min2(_g, 255), min2(_b, 255));
}

#define A3D_PI		3.1415926535f
#define A3D_2PI		6.2831853072f

//Warning: you must supply byte values as r, g and b or the result may be undetermined
#define A3DCOLORRGB(r, g, b) ((A3DCOLOR) (0xff000000 | ((r) << 16) | ((g) << 8) | (b)))
//Warning: you must supply byte values as r, g, b and a, or the result may be undetermined
#define A3DCOLORRGBA(r, g, b, a) ((A3DCOLOR) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b)))

#define A3DCOLOR_GETRED(color) ((unsigned char)(((color) & 0x00ff0000) >> 16))
#define A3DCOLOR_GETGREEN(color) ((unsigned char)(((color) & 0x0000ff00) >> 8))
#define A3DCOLOR_GETBLUE(color) ((unsigned char)(((color) & 0x000000ff)))
#define A3DCOLOR_GETALPHA(color) ((unsigned char)(((color) & 0xff000000) >> 24))

#define DEG2RAD(deg) ((deg) * A3D_PI / 180.0f)
#define RAD2DEG(rad) ((rad) * 180.0f / A3D_PI)

#define FLOATISZERO(x)	((x) > -1e-7f && (x) < 1e-7f)

#endif	//	_A3DTYPES_H_
