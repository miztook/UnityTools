#include "NavMoveAgent.h"
#include "NavQuery.h"
#include <assert.h>
#include <string.h>

CNavMoveAgent::CNavMoveAgent()
{
	m_NavQuery = 0;
	m_state = NONE;
	m_fSpeed = 10.0f;

	memset(m_vPos, 0, sizeof(m_vPos));
	memset(m_vDest, 0, sizeof(m_vDest));

	memset(m_smoothPath, 0, sizeof(m_smoothPath));
	memset(m_smoothDistance, 0, sizeof(m_smoothDistance));
	m_nSmoothPath = 0;

	m_iPath = 0;
	m_distanceCompleted = 0;
	m_distanceToMove = 0;

	m_polyPickExt[0] = 1;
	m_polyPickExt[1] = 256;
	m_polyPickExt[2] = 1;
}

CNavMoveAgent::~CNavMoveAgent()
{
}

bool CNavMoveAgent::isReady() const
{
	return m_NavQuery && m_NavQuery->isValid();
}

bool CNavMoveAgent::startMoveTo(float dest[3])
{
	if (!isReady())
		return false;

	m_vDest[0] = dest[0];
	m_vDest[1] = dest[1];
	m_vDest[2] = dest[2];

	m_state = SEARCH;

	return true;
}

void CNavMoveAgent::cancelMove()
{
	reset();
}

void CNavMoveAgent::reset()
{
	m_state = NONE;
	m_iPath = 0;
	m_distanceCompleted = 0;
	m_distanceToMove = 0;
	m_nSmoothPath = 0;
}

void CNavMoveAgent::updateTick(unsigned int deltaTime)
{
	bool bContinue = false;

	do
	{
		switch (m_state)
		{
		case SEARCH:
			bContinue = doSearchState();
			break;
		case MOVING:
			bContinue = doMovingState(deltaTime);
			break;
		case FINISHED:
			bContinue = doFinishedState();
			break;
		default:
			bContinue = false;
			break;
		}
	} while (bContinue);
}

bool CNavMoveAgent::doSearchState()
{
	assert(isReady());

	int nSmoothPath = MAX_SMOOTH;
	if (!m_NavQuery->recalcPathFindFollow(m_vPos, m_vDest, m_polyPickExt, 1.0, 0.1f, true, m_smoothPath, m_smoothDistance, &nSmoothPath))
	{
		reset();
		return false;
	}
	m_nSmoothPath = nSmoothPath;

	m_distanceToMove = m_nSmoothPath > 0 ? m_smoothDistance[m_nSmoothPath - 1] : 0;
	m_state = MOVING;
	return true;
}

bool CNavMoveAgent::doMovingState(unsigned int deltaTime)
{
	assert(isReady());

	float distance = m_fSpeed * deltaTime * 0.001f;
	if (distance > 0)
	{
		if (m_distanceCompleted >= m_distanceToMove)
		{
			setPos(m_vDest);
			m_state = FINISHED;
			return false;
		}

		if (distance + m_distanceCompleted >= m_distanceToMove)
		{
			distance = m_distanceToMove - m_distanceCompleted;
		}

		m_distanceCompleted += distance;

		const float* fDistance = m_smoothDistance;
		for (int i = m_iPath; i<m_nSmoothPath; ++i)
		{
			if (fDistance[i] > m_distanceCompleted)
			{
				m_iPath = i;
				break;
			}
		}

		if (m_iPath >= 1)
		{
			float f2 = fDistance[m_iPath];
			float f1 = fDistance[m_iPath - 1];
			assert(f2 != f1);
			float r = (m_distanceCompleted - f1) / (f2 - f1);

			const float* fPositions = m_smoothPath;

			float pos[3];
			pos[0] = fPositions[3 * (m_iPath - 1)] * (1.0f - r) + fPositions[3 * m_iPath] * r;
			pos[1] = fPositions[3 * (m_iPath - 1) + 1] * (1.0f - r) + fPositions[3 * m_iPath + 1] * r;
			pos[2] = fPositions[3 * (m_iPath - 1) + 2] * (1.0f - r) + fPositions[3 * m_iPath + 2] * r;
			setPos(pos);

			return false;
		}
	}

	return false;
}

bool CNavMoveAgent::doFinishedState()
{
	assert(isReady());

	reset();
	m_state = NONE;
	return false;
}