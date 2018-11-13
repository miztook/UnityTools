#include "NavQuery.h"
#include "HDetourCommon.h"
#include "NavBaseDefine.h"
#include "NavFunctions.h"
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <array>

using namespace HOBA;

CNavQuery::CNavQuery()
{
	m_navQuery = 0;

	m_filter.setIncludeFlags(SAMPLE_POLYFLAGS_ALL ^ SAMPLE_POLYFLAGS_DISABLED);
	m_filter.setExcludeFlags(0);

	/*
	m_straightPathOptions = 0;
	memset(m_straightPath, 0, sizeof(m_straightPath));
	memset(m_straightPathFlags, 0, sizeof(m_straightPathFlags));
	memset(m_straightPathPolys, 0, sizeof(m_straightPathPolys));
	memset(m_straightDistance, 0, sizeof(m_straightDistance));
	m_nstraightPath = 0;
	*/
}

CNavQuery::~CNavQuery()
{
	release();
}

void CNavQuery::release()
{
	if (m_navQuery)
	{
		dtFreeNavMeshQuery(m_navQuery);
		m_navQuery = 0;
	}
}

bool CNavQuery::createNavQuery(dtNavMesh* navMesh, int maxNodes)
{
	release();

	//create query
	dtStatus status;
	m_navQuery = dtAllocNavMeshQuery();
	status = m_navQuery->init(navMesh, maxNodes);
	if (dtStatusFailed(status))
	{
		release();
		assert(false);
		return false;
	}

	return true;
}

bool CNavQuery::queryPolygons(float pos[3], float ext[3])
{
	int polyCount = 0;
	if (m_navQuery)
	{
		const int MAX_SEARCH = 128;
		dtPolyRef polys[MAX_SEARCH];
		if (dtStatusFailed(m_navQuery->queryPolygons(pos, ext, &m_filter, polys, &polyCount, MAX_SEARCH)) || polyCount == 0)
			return false; // return DT_FAILURE | DT_INVALID_PARAM;
	}
	return true;
}

void CNavQuery::findNerestPoly(float pos[3], float ext[3], dtPolyRef* polyRef, float* nearestPoint)
{
	*polyRef = 0;
	if (m_navQuery)
	{
		m_navQuery->findNearestPoly(pos, ext, &m_filter, polyRef, nearestPoint);
	}
}

bool CNavQuery::recalcPathFindFollow(float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* outSmoothPathPoints, float* outSmoothDistance, int* numPoints)
{
	dtPolyRef		_startRef = 0;
	dtPolyRef		_endRef = 0;
	dtPolyRef		_polys[MAX_POLYS];		//path
	int		_npolys = 0;

	std::array<float, MAX_SMOOTH * 3> _smoothPath;
	std::array<float, MAX_SMOOTH> _smoothDistance;
	int		_nsmoothPath = 0;

	const int nInputVerts = *numPoints;
	*numPoints = 0;

	if (!m_navQuery)
	{
		return false;
	}

	dtStatus status;

	status = m_navQuery->findNearestPoly(startpos, polyPickExt, &m_filter, &_startRef, 0);

	status = m_navQuery->findNearestPoly(endpos, polyPickExt, &m_filter, &_endRef, 0);

	if (!_startRef || !_endRef)
	{
		_npolys = 0;
		_nsmoothPath = 0;
		return false;
	}

	status = m_navQuery->findPath(_startRef, _endRef, startpos, endpos, &m_filter, _polys, &_npolys, MAX_POLYS);
	assert(_npolys <= MAX_POLYS);

	_nsmoothPath = 0;

	if (_npolys)
	{
		// Iterate over the path to find smooth path on the detail mesh surface.
		dtPolyRef polys[MAX_POLYS];
		memcpy(polys, _polys, sizeof(dtPolyRef)*_npolys);
		int npolys = _npolys;

		float iterPos[3], targetPos[3];
		status = m_navQuery->closestPointOnPoly(_startRef, startpos, iterPos, 0);
		status = m_navQuery->closestPointOnPoly(polys[npolys - 1], endpos, targetPos, 0);

		_nsmoothPath = 0;

		dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
		_nsmoothPath++;

		// Move towards target a small advancement at a time until target reached or
		// when ran out of memory to store the path.
		while (npolys && _nsmoothPath < MAX_SMOOTH)
		{
			// Find location to steer towards.
			float steerPos[3];
			unsigned char steerPosFlag;
			dtPolyRef steerPosRef;

			if (!getSteerTarget(m_navQuery, iterPos, targetPos, SLOP,
				polys, npolys, steerPos, steerPosFlag, steerPosRef))
				break;

			bool endOfPath = (steerPosFlag & DT_STRAIGHTPATH_END) ? true : false;
			assert((steerPosFlag & DT_STRAIGHTPATH_OFFMESH_CONNECTION) == 0);

			// Find movement delta.
			float delta[3], len;
			dtVsub(delta, steerPos, iterPos);
			len = dtMathSqrtf(dtVdot(delta, delta));
			// If the steer target is end of path, do not move past the location.
			if (endOfPath && len < STEP_SIZE)
				len = 1;
			else
				len = STEP_SIZE / len;
			float moveTgt[3];
			dtVmad(moveTgt, iterPos, delta, len);

			// Move
			float result[3];
			dtPolyRef visited[16];
			int nvisited = 0;
			m_navQuery->moveAlongSurface(polys[0], iterPos, moveTgt, &m_filter,
				result, visited, &nvisited, 16);

			npolys = fixupCorridor(polys, npolys, MAX_POLYS, visited, nvisited);
			npolys = fixupShortcuts(polys, npolys, m_navQuery);

			float h = 0;
			m_navQuery->getPolyHeight(polys[0], result, &h);
			result[1] = h;
			dtVcopy(iterPos, result);

			// Handle end of path when close enough.
			if (endOfPath && inRange(iterPos, steerPos, SLOP, 1.0f))
			{
				// Reached end of path.
				dtVcopy(iterPos, targetPos);
				if (_nsmoothPath < MAX_SMOOTH)
				{
					dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
					_nsmoothPath++;
				}
				break;
			}

			// Store results.
			if (_nsmoothPath < MAX_SMOOTH)
			{
				dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
				_nsmoothPath++;
			}
		}
	}

	//calculate smooth distance
	_smoothDistance[0] = 0.0f;
	float fDist = 0.0f;
	for (int i = 1; i < _nsmoothPath; ++i)
	{
		float x = _smoothPath[i * 3] - _smoothPath[(i - 1) * 3];
		float y = _smoothPath[i * 3 + 1] - _smoothPath[(i - 1) * 3 + 1];
		float z = _smoothPath[i * 3 + 2] - _smoothPath[(i - 1) * 3 + 2];

		if (bOnlyXZ)
			_smoothDistance[i] = fDist + sqrtf(x*x + z*z);
		else
			_smoothDistance[i] = fDist + sqrtf(x*x + y*y + z*z);

		fDist = _smoothDistance[i];
	}

	//results
	int nsmoothPath = _nsmoothPath;
	const float* smoothPath = _smoothPath.data();
	const float* smoothDistance = _smoothDistance.data();
	*numPoints = nsmoothPath;

	if (nInputVerts >= nsmoothPath)
	{
		memcpy(outSmoothPathPoints, smoothPath, sizeof(float) * 3 * nsmoothPath);
		memcpy(outSmoothDistance, smoothDistance, sizeof(float) * nsmoothPath);
	}
	else
	{
		memcpy(outSmoothPathPoints, smoothPath, sizeof(float) * 3 * nInputVerts);
		memcpy(outSmoothDistance, smoothDistance, sizeof(float) * nInputVerts);
	}

	return _nsmoothPath > 0;
}

bool CNavQuery::getPathFindFollowDistance(float* retDist, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE /*= 0.5f*/, float SLOP /*= 0.01f*/, bool bOnlyXZ /*= false*/) const
{
	dtPolyRef		_startRef;
	dtPolyRef		_endRef;
	dtPolyRef		_polys[MAX_POLYS];		//path
	int		_npolys;

	std::array<float, MAX_SMOOTH * 3> _smoothPath;
	std::array<float, MAX_SMOOTH> _smoothDistance;
	int		_nsmoothPath;

	*retDist = 0.0f;

	if (!m_navQuery)
	{
		_npolys = 0;
		_nsmoothPath = 0;
		return false;
	}

	dtStatus status;

	status = m_navQuery->findNearestPoly(startpos, polyPickExt, &m_filter, &_startRef, 0);

	status = m_navQuery->findNearestPoly(endpos, polyPickExt, &m_filter, &_endRef, 0);

	if (!_startRef || !_endRef)
	{
		_npolys = 0;
		_nsmoothPath = 0;
		return false;
	}

	status = m_navQuery->findPath(_startRef, _endRef, startpos, endpos, &m_filter, _polys, &_npolys, MAX_POLYS);
	assert(_npolys <= MAX_POLYS);

	_nsmoothPath = 0;

	if (_npolys)
	{
		// Iterate over the path to find smooth path on the detail mesh surface.
		dtPolyRef polys[MAX_POLYS];
		memcpy(polys, _polys, sizeof(dtPolyRef)*_npolys);
		int npolys = _npolys;

		float iterPos[3], targetPos[3];
		status = m_navQuery->closestPointOnPoly(_startRef, startpos, iterPos, 0);
		status = m_navQuery->closestPointOnPoly(polys[npolys - 1], endpos, targetPos, 0);

		_nsmoothPath = 0;

		dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
		_nsmoothPath++;

		// Move towards target a small advancement at a time until target reached or
		// when ran out of memory to store the path.
		while (npolys && _nsmoothPath < MAX_SMOOTH)
		{
			// Find location to steer towards.
			float steerPos[3];
			unsigned char steerPosFlag;
			dtPolyRef steerPosRef;

			if (!getSteerTarget(m_navQuery, iterPos, targetPos, SLOP,
				polys, npolys, steerPos, steerPosFlag, steerPosRef))
				break;

			bool endOfPath = (steerPosFlag & DT_STRAIGHTPATH_END) ? true : false;
			assert((steerPosFlag & DT_STRAIGHTPATH_OFFMESH_CONNECTION) == 0);

			// Find movement delta.
			float delta[3], len;
			dtVsub(delta, steerPos, iterPos);
			len = dtMathSqrtf(dtVdot(delta, delta));
			// If the steer target is end of path, do not move past the location.
			if (endOfPath && len < STEP_SIZE)
				len = 1;
			else
				len = STEP_SIZE / len;
			float moveTgt[3];
			dtVmad(moveTgt, iterPos, delta, len);

			// Move
			float result[3];
			dtPolyRef visited[16];
			int nvisited = 0;
			m_navQuery->moveAlongSurface(polys[0], iterPos, moveTgt, &m_filter,
				result, visited, &nvisited, 16);

			npolys = fixupCorridor(polys, npolys, MAX_POLYS, visited, nvisited);
			npolys = fixupShortcuts(polys, npolys, m_navQuery);

			float h = 0;
			m_navQuery->getPolyHeight(polys[0], result, &h);
			result[1] = h;
			dtVcopy(iterPos, result);

			// Handle end of path when close enough.
			if (endOfPath && inRange(iterPos, steerPos, SLOP, 1.0f))
			{
				// Reached end of path.
				dtVcopy(iterPos, targetPos);
				if (_nsmoothPath < MAX_SMOOTH)
				{
					dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
					_nsmoothPath++;
				}
				break;
			}

			// Store results.
			if (_nsmoothPath < MAX_SMOOTH)
			{
				dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
				_nsmoothPath++;
			}
		}
	}

	//calculate smooth distance
	_smoothDistance[0] = 0.0f;
	float fDist = 0.0f;
	for (int i = 1; i < _nsmoothPath; ++i)
	{
		float x = _smoothPath[i * 3] - _smoothPath[(i - 1) * 3];
		float y = _smoothPath[i * 3 + 1] - _smoothPath[(i - 1) * 3 + 1];
		float z = _smoothPath[i * 3 + 2] - _smoothPath[(i - 1) * 3 + 2];

		if (bOnlyXZ)
			_smoothDistance[i] = fDist + sqrtf(x*x + z*z);
		else
			_smoothDistance[i] = fDist + sqrtf(x*x + y*y + z*z);

		fDist = _smoothDistance[i];
	}

	if (_nsmoothPath == 0)
		*retDist = 0.0f;
	else
		*retDist = _smoothDistance[_nsmoothPath - 1];

	return _nsmoothPath > 0;
}

bool CNavQuery::getPathFindFollowPoints(float* _outSmoothPoints, int* numpoints, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE /*= 0.5f*/, float SLOP /*= 0.01f*/, bool bOnlyXZ /*= false*/) const
{
	dtPolyRef		_startRef;
	dtPolyRef		_endRef;
	dtPolyRef		_polys[MAX_POLYS];		//path
	int		_npolys;

	std::array<float, MAX_SMOOTH * 3> _smoothPath;
	int		_nsmoothPath;

	const int intputNumPoints = *numpoints;
	*numpoints = 0;

	if (!m_navQuery)
	{
		_npolys = 0;
		_nsmoothPath = 0;
		return false;
	}

	dtStatus status;

	status = m_navQuery->findNearestPoly(startpos, polyPickExt, &m_filter, &_startRef, 0);

	status = m_navQuery->findNearestPoly(endpos, polyPickExt, &m_filter, &_endRef, 0);

	if (!_startRef || !_endRef)
	{
		_npolys = 0;
		_nsmoothPath = 0;
		return false;
	}

	status = m_navQuery->findPath(_startRef, _endRef, startpos, endpos, &m_filter, _polys, &_npolys, MAX_POLYS);
	assert(_npolys <= MAX_POLYS);

	_nsmoothPath = 0;

	if (_npolys)
	{
		// Iterate over the path to find smooth path on the detail mesh surface.
		dtPolyRef polys[MAX_POLYS];
		memcpy(polys, _polys, sizeof(dtPolyRef)*_npolys);
		int npolys = _npolys;

		float iterPos[3], targetPos[3];
		status = m_navQuery->closestPointOnPoly(_startRef, startpos, iterPos, 0);
		status = m_navQuery->closestPointOnPoly(polys[npolys - 1], endpos, targetPos, 0);

		_nsmoothPath = 0;

		dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
		_nsmoothPath++;

		// Move towards target a small advancement at a time until target reached or
		// when ran out of memory to store the path.
		while (npolys && _nsmoothPath < MAX_SMOOTH)
		{
			// Find location to steer towards.
			float steerPos[3];
			unsigned char steerPosFlag;
			dtPolyRef steerPosRef;

			if (!getSteerTarget(m_navQuery, iterPos, targetPos, SLOP,
				polys, npolys, steerPos, steerPosFlag, steerPosRef))
				break;

			bool endOfPath = (steerPosFlag & DT_STRAIGHTPATH_END) ? true : false;
			assert((steerPosFlag & DT_STRAIGHTPATH_OFFMESH_CONNECTION) == 0);

			// Find movement delta.
			float delta[3], len;
			dtVsub(delta, steerPos, iterPos);
			len = dtMathSqrtf(dtVdot(delta, delta));
			// If the steer target is end of path, do not move past the location.
			if (endOfPath && len < STEP_SIZE)
				len = 1;
			else
				len = STEP_SIZE / len;
			float moveTgt[3];
			dtVmad(moveTgt, iterPos, delta, len);

			// Move
			float result[3];
			dtPolyRef visited[16];
			int nvisited = 0;
			m_navQuery->moveAlongSurface(polys[0], iterPos, moveTgt, &m_filter,
				result, visited, &nvisited, 16);

			npolys = fixupCorridor(polys, npolys, MAX_POLYS, visited, nvisited);
			npolys = fixupShortcuts(polys, npolys, m_navQuery);

			float h = 0;
			m_navQuery->getPolyHeight(polys[0], result, &h);
			result[1] = h;
			dtVcopy(iterPos, result);

			// Handle end of path when close enough.
			if (endOfPath && inRange(iterPos, steerPos, SLOP, 1.0f))
			{
				// Reached end of path.
				dtVcopy(iterPos, targetPos);
				if (_nsmoothPath < MAX_SMOOTH)
				{
					dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
					_nsmoothPath++;
				}
				break;
			}

			// Store results.
			if (_nsmoothPath < MAX_SMOOTH)
			{
				dtVcopy(&_smoothPath[_nsmoothPath * 3], iterPos);
				_nsmoothPath++;
			}
		}
	}

	*numpoints = _nsmoothPath;

	if (intputNumPoints >= _nsmoothPath)
		memcpy(_outSmoothPoints, _smoothPath.data(), sizeof(float) * 3 * _nsmoothPath);
	else
		memcpy(_outSmoothPoints, _smoothPath.data(), sizeof(float)* 3 * intputNumPoints);

	return _nsmoothPath > 0;
}

/*
bool CNavQuery::recalcPathFindStraight(float startpos[3], float endpos[3], float STEP_SIZE, float SLOP, bool bOnlyXZ)
{
	if (!m_navQuery)
	{
		m_npolys = 0;
		m_nstraightPath = 0;
		return false;
	}

	m_navQuery->findNearestPoly(startpos, m_polyPickExt, &m_filter, &m_startRef, 0);

	m_navQuery->findNearestPoly(endpos, m_polyPickExt, &m_filter, &m_endRef, 0);

	if (!m_startRef || !m_endRef)
	{
		m_npolys = 0;
		m_nstraightPath = 0;
		return false;
	}

	m_navQuery->findPath(m_startRef, m_endRef, startpos, endpos, &m_filter, m_polys, &m_npolys, MAX_POLYS);
	assert(m_npolys <= MAX_POLYS);

	m_nstraightPath = 0;

	if (m_npolys)
	{
		// In case of partial path, make sure the end point is clamped to the last polygon.
		float epos[3];
		dtVcopy(epos, endpos);
		if (m_polys[m_npolys - 1] != m_endRef)
			m_navQuery->closestPointOnPoly(m_polys[m_npolys - 1], endpos, epos, 0);

		m_navQuery->findStraightPath(startpos, epos, m_polys, m_npolys,
			m_straightPath, m_straightPathFlags,
			m_straightPathPolys, &m_nstraightPath, MAX_POLYS, m_straightPathOptions);
	}

	//calculate straight distance
	m_straightDistance[0] = 0.0f;
	float fDist = 0.0f;
	for (int i = 1; i < m_nstraightPath; ++i)
	{
		float x = m_straightDistance[i * 3] - m_straightDistance[(i - 1) * 3];
		float y = m_straightDistance[i * 3 + 1] - m_straightDistance[(i - 1) * 3 + 1];
		float z = m_straightDistance[i * 3 + 2] - m_straightDistance[(i - 1) * 3 + 2];

		if (bOnlyXZ)
			m_straightDistance[i] = fDist + sqrtf(x*x + z*z);
		else
			m_straightDistance[i] = fDist + sqrtf(x*x + y*y + z*z);

		fDist = m_straightDistance[i];
	}

	return m_nstraightPath > 0;
}
*/

bool CNavQuery::raycast(float startpos[3], float endpos[3], float polyPickExt[3], float& t, float* hitPos, float* hitNormal)
{
	dtPolyRef _polys[MAX_POLYS];
	int _npolys = 0;
	dtPolyRef _startRef = 0;

	if (!m_navQuery)
	{
		return false;
	}

	m_navQuery->findNearestPoly(startpos, polyPickExt, &m_filter, &_startRef, 0);

	if (!_startRef)
	{
		return false;
	}

	m_navQuery->raycast(_startRef, startpos, endpos, &m_filter, &t, hitNormal, _polys, &_npolys, MAX_POLYS);
	assert(_npolys <= MAX_POLYS);

	if (hitPos)
	{
		if (t > 1)
		{
			// No hit
			dtVcopy(hitPos, endpos);
		}
		else
		{
			// Hit
			dtVlerp(hitPos, startpos, endpos, t);
		}
		// Adjust height.
		if (_npolys > 0)
		{
			float h = 0;
			m_navQuery->getPolyHeight(_polys[_npolys - 1], hitPos, &h);
			hitPos[1] = h;
		}
	}

	return true;
}

bool CNavQuery::getPosHeight(float pos[3], float fExtRadius, float fExtHeight, float& fHeight)
{
	if (!m_navQuery)
		return false;

	float ext[3];
	ext[0] = fExtRadius;
	ext[1] = fExtHeight;
	ext[2] = fExtRadius;

	dtPolyRef polyRef;
	float nearest[3];
	m_navQuery->findNearestPoly(pos, ext, &m_filter, &polyRef, nearest);
	if (!polyRef)
		return false;

	float h = 0;
	m_navQuery->getPolyHeight(polyRef, nearest, &h);
	fHeight = h;
	return true;
}