#ifndef _NAV_QUERY_H_
#define _NAV_QUERY_H_

#include "HDetourNavMeshQuery.h"

using namespace HOBA;

class CNavQuery
{
public:
	CNavQuery();
	~CNavQuery();

	static const int MAX_POLYS = 256;
	static const int MAX_SMOOTH = 2048;

public:
	bool isValid() const { return m_navQuery != 0; }
	bool createNavQuery(dtNavMesh* navMesh, int maxNodes = 4096);
	void release();

	dtNavMeshQuery* getNavMeshQuery() const { return m_navQuery; }
	dtQueryFilter& getQueryFilter() { return m_filter; }

	bool queryPolygons(float pos[3], float ext[3]);
	void findNerestPoly(float pos[3], float ext[3], dtPolyRef* polyRef, float* nearestPoint);
	bool recalcPathFindFollow(float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* outSmoothPathPoints, float* outSmoothDistance, int* numPoints);
	bool getPathFindFollowDistance(float* retDist, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE = 0.5f, float SLOP = 0.01f, bool bOnlyXZ = false) const;
	bool getPathFindFollowPoints(float* smoothPath, int* numpoints, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE = 0.5f, float SLOP = 0.01f, bool bOnlyXZ = false) const;

	//bool recalcPathFindStraight(float startpos[3], float endpos[3], float STEP_SIZE = 0.5f, float SLOP = 0.01f, bool bOnlyXZ = false);
	bool raycast(float startpos[3], float endpos[3], float polyPickExt[3], float& t, float* hitPos, float* hitNormal);
	bool getPosHeight(float pos[3], float fExtRadius, float fExtHeight, float& fHeight);

	/*
	const float* getSmoothPath() const { return m_smoothPath; }
	const float* getSmoothDistance() const { return m_smoothDistance; }
	int getNumSmoothPath() const { return m_nsmoothPath; }
	float getSmoothTotalDistance() const
	{
		if (m_nsmoothPath == 0)
			return 0.0f;
		return m_smoothDistance[m_nsmoothPath - 1];
	}

	const float* getStraightPath() const { return m_straightPath; }
	int getNumStraightPath() const { return m_nstraightPath; }
	const float* getStraightDistance() const { return m_straightDistance; }
	float getStraightTotalDistance() const
	{
		if (m_nstraightPath == 0)
			return 0.0f;
		return m_straightDistance[m_nstraightPath - 1];
	}
	*/

private:
	//query test
	dtNavMeshQuery*		m_navQuery;
	dtQueryFilter m_filter;

	/*
	dtPolyRef		m_startRef;
	dtPolyRef		m_endRef;
	dtPolyRef		m_polys[MAX_POLYS];		//path
	int		m_npolys;

	float		m_smoothPath[MAX_SMOOTH * 3];
	float		m_smoothDistance[MAX_SMOOTH];
	int		m_nsmoothPath;
	*/

	/*
	int		m_straightPathOptions;
	float		m_straightPath[MAX_POLYS * 3];
	unsigned char		m_straightPathFlags[MAX_POLYS];
	dtPolyRef				m_straightPathPolys[MAX_POLYS];
	int		m_nstraightPath;
	float		m_straightDistance[MAX_POLYS];
	*/
};

#endif