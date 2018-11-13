
#ifndef _ALINE_H_
#define _ALINE_H_

#include "ATypes.h"
#include "A3DVector.h"

#pragma warning (disable: 4786)

class ALine2D
{
public:
	//
	ALine2D(){}
	ALine2D(float xa, float ya, float xb, float yb) : start(xa, ya), end(xb, yb) {}
	ALine2D(const A3DVECTOR2& start, const A3DVECTOR2& end) : start(start), end(end) {}
	ALine2D(const ALine2D& other) { (*this) = other; }

	ALine2D& operator=(const ALine2D& other)
	{
		ASSERT(this != &other);
		start = other.start;
		end = other.end;
		return *this;
	}
	//
	ALine2D operator+(const A3DVECTOR2& point) const { return ALine2D(start + point, end + point); }
	ALine2D& operator+=(const A3DVECTOR2& point) { start += point; end += point; return *this; }

	ALine2D operator-(const A3DVECTOR2& point) const { return ALine2D(start - point, end - point); }
	ALine2D& operator-=(const A3DVECTOR2& point) { start -= point; end -= point; return *this; }

	bool operator==(const ALine2D& other) const
	{ return (start==other.start && end==other.end) || (end==other.start && start==other.end);}
	bool operator!=(const ALine2D& other) const
	{ return !(start==other.start && end==other.end) || (end==other.start && start==other.end);}

	//
	void setLine(const float& xa, const float& ya, const float& xb, const float& yb) { start = A3DVECTOR2(xa, ya); end = A3DVECTOR2(xb, yb);}
	void setLine(const A3DVECTOR2& nstart, const A3DVECTOR2& nend) { start = A3DVECTOR2(nstart); end = A3DVECTOR2(nend);}
	void setLine(const ALine2D& line) { start = A3DVECTOR2(line.start); end = A3DVECTOR2(line.end);}

	float getLength() const { return (start - end).Magnitude(); }

	float getLengthSQ() const { return (start - end).SquaredMagnitude(); }

	A3DVECTOR2 getMiddle() const { return (start + end) * 0.5f; }

	A3DVECTOR2 getVector() const { return A3DVECTOR2(end.x - start.x, end.y - start.y); }

public:
	A3DVECTOR2 start;
	A3DVECTOR2 end;
};


class ALine3D
{
public:
	//
	ALine3D(){}
	ALine3D(float xa, float ya, float za, float xb, float yb, float zb) : start(xa, ya, za), end(xb, yb, zb) {}
	ALine3D(const A3DVECTOR3& start, const A3DVECTOR3& end) : start(start), end(end) {}
	ALine3D(const ALine3D& other) { (*this) = other; }

	ALine3D& operator=(const ALine3D& other)
	{
		ASSERT(this != &other);
		start = other.start;
		end = other.end;
		return *this;
	}

	//
	ALine3D operator+(const A3DVECTOR3& point) const { return ALine3D(start + point, end + point); }
	ALine3D& operator+=(const A3DVECTOR3& point) { start += point; end += point; return *this; }

	ALine3D operator-(const A3DVECTOR3& point) const { return ALine3D(start - point, end - point); }
	ALine3D& operator-=(const A3DVECTOR3& point) { start -= point; end -= point; return *this; }

	bool operator==(const ALine3D& other) const { return (start==other.start && end==other.end) || (end==other.start && start==other.end);}
	bool operator!=(const ALine3D& other) const { return !(start==other.start && end==other.end) || (end==other.start && start==other.end);}

	//
	void setLine(const float& xa, const float& ya, const float& za, const float& xb, const float& yb, const float& zb) {start = A3DVECTOR3(xa, ya, za); end = A3DVECTOR3(xb, yb, zb);}
	void setLine(const A3DVECTOR3& nstart, const A3DVECTOR3& nend) {start = A3DVECTOR3(nstart); end = A3DVECTOR3(nend);}
	void setLine(const ALine3D& line) {start = A3DVECTOR3(line.start); end = A3DVECTOR3(line.end);}

	float getLength() const { return (start - end).Magnitude(); }
	float getLengthSQ() const { return (start - end).SquaredMagnitude(); }
	A3DVECTOR3 getMiddle() const { return (start + end) * 0.5f; }
	A3DVECTOR3 getVector() const { return end - start; }

public:
	A3DVECTOR3 start;
	A3DVECTOR3 end;

};

#endif