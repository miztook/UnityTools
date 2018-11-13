#include "NavCrowd.h"
#include "NavQuery.h"
#include "NavBaseDefine.h"
#include "NavFunctions.h"
#include <string.h>
#include <float.h>
#include <assert.h>

CNavCrowd::CNavCrowd()
{
	m_nCrowd = 0;
	m_NavQuery = 0;

	memset(m_targetPos, 0, sizeof(m_targetPos));
	m_targetRef = 0;

	m_nMaxAgents = 128;
}

CNavCrowd::~CNavCrowd()
{
	release();
}

bool CNavCrowd::isReady() const
{
	return m_NavQuery && m_NavQuery->isValid();
}

bool CNavCrowd::createNavCrowd(dtNavMesh* navMesh, int nMaxAgents, float agentRadius, float fHeightExt)
{
	release();

	m_nMaxAgents = nMaxAgents;
	m_nCrowd = dtAllocCrowd();

	if (!m_nCrowd->init(m_nMaxAgents, agentRadius, fHeightExt, navMesh))
	{
		release();
		return false;
	}

	// Make polygons with 'disabled' flag invalid.
	m_nCrowd->getEditableFilter(0)->setExcludeFlags(SAMPLE_POLYFLAGS_DISABLED);

	// Setup local avoidance params to different qualities.
	dtObstacleAvoidanceParams params;
	// Use mostly default settings, copy from dtCrowd.
	memcpy(&params, m_nCrowd->getObstacleAvoidanceParams(0), sizeof(dtObstacleAvoidanceParams));

	// Low (11)
	params.velBias = 0.5f;
	params.adaptiveDivs = 5;
	params.adaptiveRings = 2;
	params.adaptiveDepth = 1;
	m_nCrowd->setObstacleAvoidanceParams(0, &params);

	// Medium (22)
	params.velBias = 0.5f;
	params.adaptiveDivs = 5;
	params.adaptiveRings = 2;
	params.adaptiveDepth = 2;
	m_nCrowd->setObstacleAvoidanceParams(1, &params);

	// Good (45)
	params.velBias = 0.5f;
	params.adaptiveDivs = 7;
	params.adaptiveRings = 2;
	params.adaptiveDepth = 3;
	m_nCrowd->setObstacleAvoidanceParams(2, &params);

	// High (66)
	params.velBias = 0.5f;
	params.adaptiveDivs = 7;
	params.adaptiveRings = 3;
	params.adaptiveDepth = 3;

	m_nCrowd->setObstacleAvoidanceParams(3, &params);

	return true;
}

void CNavCrowd::release()
{
	if (m_nCrowd)
	{
		dtFreeCrowd(m_nCrowd);
		m_nCrowd = 0;
		m_nMaxAgents = 128;
	}
}

int CNavCrowd::getMaxAgentCount() const
{
	assert(m_nCrowd);
	return m_nCrowd->getAgentCount();
}

const dtCrowdAgent* CNavCrowd::getAgent(int idx) const
{
	assert(m_nCrowd);
	return m_nCrowd->getAgent(idx);
}

int CNavCrowd::addAgent(const float* pos, const SAgentParams& param)
{
	assert(m_nCrowd);

	dtCrowdAgentParams ap;
	memset(&ap, 0, sizeof(ap));
	ap.radius = param.radius;
	ap.height = param.height;
	ap.maxAcceleration = param.maxAcceleration;
	ap.maxSpeed = param.maxSpeed;
	ap.collisionQueryRange = param.collisionQueryRange;
	ap.pathOptimizationRange = param.pathOptimizationRange;
	ap.updateFlags = 0;

	if (param.bAnticipateTurns)
		ap.updateFlags |= DT_CROWD_ANTICIPATE_TURNS;

	if (param.bOptimizeVis)
		ap.updateFlags |= DT_CROWD_OPTIMIZE_VIS;

	if (param.bOptimizeTopo)
		ap.updateFlags |= DT_CROWD_OPTIMIZE_TOPO;

	if (param.bObstacleAvoidance)
		ap.updateFlags |= DT_CROWD_OBSTACLE_AVOIDANCE;

	if (param.bSeparation)
		ap.updateFlags |= DT_CROWD_SEPARATION;

	ap.obstacleAvoidanceType = param.obstacleAvoidanceType;
	ap.separationWeight = param.separationWeight;

	return m_nCrowd->addAgent(pos, &ap);
}

void CNavCrowd::removeAgent(int idx)
{
	assert(m_nCrowd);
	m_nCrowd->removeAgent(idx);
}

bool CNavCrowd::setAgentPosition(int idx, const float* pos)
{
	assert(m_nCrowd);
	if (!getAgent(idx))
		return false;

	m_nCrowd->updateAgentPos(idx, pos);
	return true;
}

bool CNavCrowd::getAgentParam(int idx, SAgentParams* param)
{
	assert(m_nCrowd);
	const dtCrowdAgent* ag = getAgent(idx);
	if (!ag)
		return false;

	param->radius = ag->params.radius;
	param->height = ag->params.height;
	param->maxAcceleration = ag->params.maxAcceleration;
	param->maxSpeed = ag->params.maxSpeed;
	param->collisionQueryRange = ag->params.collisionQueryRange;
	param->pathOptimizationRange = ag->params.pathOptimizationRange;

	param->bAnticipateTurns = (ag->params.updateFlags & DT_CROWD_ANTICIPATE_TURNS) != 0;
	param->bOptimizeVis = (ag->params.updateFlags & DT_CROWD_OPTIMIZE_VIS) != 0;
	param->bOptimizeTopo = (ag->params.updateFlags & DT_CROWD_OPTIMIZE_TOPO) != 0;
	param->bObstacleAvoidance = (ag->params.updateFlags & DT_CROWD_OBSTACLE_AVOIDANCE) != 0;
	param->bSeparation = (ag->params.updateFlags & DT_CROWD_SEPARATION) != 0;

	param->obstacleAvoidanceType = ag->params.obstacleAvoidanceType;
	param->separationWeight = ag->params.separationWeight;

	return true;
}

bool CNavCrowd::updateAgentParam(int idx, const SAgentParams& param)
{
	assert(m_nCrowd);
	if (!getAgent(idx))
		return false;

	dtCrowdAgentParams ap;
	memset(&ap, 0, sizeof(ap));
	ap.radius = param.radius;
	ap.height = param.height;
	ap.maxAcceleration = param.maxAcceleration;
	ap.maxSpeed = param.maxSpeed;
	ap.collisionQueryRange = param.collisionQueryRange;
	ap.pathOptimizationRange = param.pathOptimizationRange;
	ap.updateFlags = 0;

	if (param.bAnticipateTurns)
		ap.updateFlags |= DT_CROWD_ANTICIPATE_TURNS;

	if (param.bOptimizeVis)
		ap.updateFlags |= DT_CROWD_OPTIMIZE_VIS;

	if (param.bOptimizeTopo)
		ap.updateFlags |= DT_CROWD_OPTIMIZE_TOPO;

	if (param.bObstacleAvoidance)
		ap.updateFlags |= DT_CROWD_OBSTACLE_AVOIDANCE;

	if (param.bSeparation)
		ap.updateFlags |= DT_CROWD_SEPARATION;

	ap.obstacleAvoidanceType = param.obstacleAvoidanceType;
	ap.separationWeight = param.separationWeight;

	m_nCrowd->updateAgentParameters(idx, &ap);

	return true;
}

int CNavCrowd::hitTestAgents(const float* start, const float* position)
{
	assert(m_nCrowd);
	int isel = -1;

	float tsel = FLT_MAX;

	for (int i = 0; i < m_nCrowd->getAgentCount(); ++i)
	{
		const dtCrowdAgent* ag = m_nCrowd->getAgent(i);
		if (!ag->active) continue;
		float bmin[3], bmax[3];
		getAgentBounds(ag, bmin, bmax);
		float tmin, tmax;
		if (isectSegAABB(start, position, bmin, bmax, tmin, tmax))
		{
			if (tmin > 0 && tmin < tsel)
			{
				isel = i;
				tsel = tmin;
			}
		}
	}

	return isel;
}

bool CNavCrowd::setMoveTarget(int idx, const float* pos, bool adjust)
{
	assert(m_nCrowd);
	assert(isValid());

	const dtCrowdAgent* ag = getAgent(idx);
	if (!ag || !ag->active)
		return false;

	dtNavMeshQuery* navquery = m_NavQuery->getNavMeshQuery();
	const dtQueryFilter* filter = m_nCrowd->getFilter(0);
	const float* ext = m_nCrowd->getQueryExtents();

	if (adjust)
	{
		float vel[3];
		calcVel(vel, ag->npos, pos, ag->params.maxSpeed);
		m_nCrowd->requestMoveVelocity(idx, vel);
	}
	else
	{
		navquery->findNearestPoly(pos, ext, filter, &m_targetRef, m_targetPos);
		m_nCrowd->requestMoveTarget(idx, m_targetRef, m_targetPos);
	}

	return true;
}

void CNavCrowd::setAllMoveTarget(const float* pos, bool adjust)
{
	assert(m_nCrowd);
	assert(isValid());

	dtNavMeshQuery* navquery = m_NavQuery->getNavMeshQuery();
	const dtQueryFilter* filter = m_nCrowd->getFilter(0);
	const float* ext = m_nCrowd->getQueryExtents();

	if (adjust)
	{
		float vel[3];
		for (int i = 0; i < m_nCrowd->getAgentCount(); ++i)
		{
			const dtCrowdAgent* ag = m_nCrowd->getAgent(i);
			if (!ag->active)
				continue;
			calcVel(vel, ag->npos, pos, ag->params.maxSpeed);
			m_nCrowd->requestMoveVelocity(i, vel);
		}
	}
	else
	{
		navquery->findNearestPoly(pos, ext, filter, &m_targetRef, m_targetPos);
		for (int i = 0; i < m_nCrowd->getAgentCount(); ++i)
		{
			const dtCrowdAgent* ag = m_nCrowd->getAgent(i);
			if (!ag->active)
				continue;
			m_nCrowd->requestMoveTarget(i, m_targetRef, m_targetPos);
		}
	}
}

void CNavCrowd::updateTick(unsigned int deltaTime)
{
	if (!isValid())
		return;

	m_nCrowd->update(deltaTime * 0.001f, 0);
}

bool CNavCrowd::updateOneAgent(int idx, unsigned int deltaTime, const float* pos, const float* targetpos, float maxspeed, bool bIgnoreCollision, bool bKeepSpeed)
{
	if (!isValid())
		return false;

	const dtCrowdAgent* ag = getAgent(idx);
	if (!ag || !ag->active)
		return false;

	m_nCrowd->updateAgentPos(idx, pos);
	setMoveTarget(idx, targetpos, false);
	const dtCrowdAgentParams& params = ag->params;
	if (params.maxSpeed != maxspeed)
	{
		m_nCrowd->updateAgentMaxSpeed(idx, maxspeed);
	}

	return m_nCrowd->updateOneAgent(idx, deltaTime * 0.001f, bIgnoreCollision, bKeepSpeed);
}

bool CNavCrowd::cancelMove(int idx)
{
	const dtCrowdAgent* ag = getAgent(idx);
	if (!ag || !ag->active)
		return false;

	float pos[3];
	memcpy(pos, ag->npos, sizeof(pos));
	m_nCrowd->updateAgentPos(idx, pos);

	return true;
}

void CNavCrowd::cancelAllMove()
{
	for (int i = 0; i < m_nMaxAgents; ++i)
	{
		cancelMove(i);
	}
}