extern "C"
{
#include "navmesh_export.h"
}

#include "AutoNavigation.h"
#include <string.h>

HAPI CNavMesh* NM_LoadNavMesh(const char* path)
{
	CNavMesh* pNavMesh = new CNavMesh;
	if (!pNavMesh->load(path))
	{
		delete pNavMesh;
		return 0;
	}
	return pNavMesh;
}

HAPI CNavMesh* NM_LoadNavMeshFromMemory(unsigned char* bytes, int numBytes)
{
	CNavMesh* pNavMesh = new CNavMesh;
	if (!pNavMesh->loadFromMemory(bytes, numBytes))
	{
		delete pNavMesh;
		return 0;
	}
	return pNavMesh;
}

HAPI void NM_ClearNavMesh(CNavMesh* pNavMesh)
{
	if (pNavMesh)
	{
		delete pNavMesh;
		pNavMesh = 0;
	}
}

HAPI CNavQuery* NM_CreateNavQuery(CNavMesh* pNavMesh, int nMaxNodes)
{
	CNavQuery* pNavQuery = new CNavQuery;
	if (!pNavQuery->createNavQuery(pNavMesh->getDtNavMesh(), nMaxNodes))
	{
		delete pNavQuery;
		return 0;
	}
	return pNavQuery;
}

HAPI void NM_ClearNavQuery(CNavQuery* pNavQuery)
{
	if (pNavQuery)
	{
		delete pNavQuery;
		pNavQuery = 0;
	}
}

HAPI void NM_NavMeshGetVertexIndexCount(CNavMesh* pNavMesh, int* vcount, int* icount, int areaId)
{
	if (pNavMesh)
	{
		pNavMesh->getVertexIndexCount(*vcount, *icount, areaId);
	}
	else
	{
		*vcount = 0;
		*icount = 0;
	}
}

HAPI void NM_NavMeshFillVertexIndexBuffer(CNavMesh* pNavMesh, float vertices[], int vcount, int indices[], int icount, int areaId)
{
	if (pNavMesh)
		pNavMesh->fillVertexIndexBuffer(vertices, vcount, indices, icount, areaId);
}

HAPI bool NM_GetNearestValidPosition(CNavQuery* pNavQuery, float pos[3], float ext[3], float nearestPt[3])
{
	if (!pNavQuery)
		return false;

	dtPolyRef polyRef;
	pNavQuery->findNerestPoly(pos, ext, &polyRef, nearestPt);
	return polyRef != 0;
}

HAPI bool NM_RecalcPathFindFollow(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* outSmoothPathPoints, float* outSmoothDistance, int* numPoints)
{
	bool ret = pNavQuery->recalcPathFindFollow(startpos, endpos, polyPickExt, STEP_SIZE, SLOP, bOnlyXZ, outSmoothPathPoints, outSmoothDistance, numPoints);
	return ret;
}

HAPI bool NM_GetPathFindFollowDistance(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* fDistance)
{
	bool ret = pNavQuery->getPathFindFollowDistance(fDistance, startpos, endpos, polyPickExt, STEP_SIZE, SLOP, bOnlyXZ);
	return ret;
}

HAPI bool NM_GetPathFindFollowPoints(CNavQuery * pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* points, int* numPoints)
{
	bool ret = pNavQuery->getPathFindFollowPoints(points, numPoints, startpos, endpos, polyPickExt, STEP_SIZE, SLOP, bOnlyXZ);
	return ret;
}

HAPI bool NM_Raycast(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float& t)
{
	return pNavQuery->raycast(startpos, endpos, polyPickExt, t, NULL, NULL);
}

HAPI bool NM_GetPosHeight(CNavQuery* pNavQuery, float pos[3], float fExtRadius, float fExtHeight, float& fHeight)
{
	return pNavQuery->getPosHeight(pos, fExtRadius, fExtHeight, fHeight);
}

HAPI void NM_SetAreaCost(CNavQuery* pNavQuery, int areaId, float fCost)
{
	pNavQuery->getQueryFilter().setAreaCost(areaId, fCost);
}

HAPI float NM_GetAreaCost(CNavQuery* pNavQuery, int areaId)
{
	float fCost = pNavQuery->getQueryFilter().getAreaCost(areaId);
	return fCost;
}

/*
HAPI CNavMoveAgent* NM_CreateAgent(CNavQuery* pNavQuery)
{
	CNavMoveAgent* pNavAgent = new CNavMoveAgent;
	pNavAgent->setNavQuery(pNavQuery);

	return pNavAgent;
}

HAPI void NM_ClearAgent(CNavMoveAgent* pAgent)
{
	if (pAgent)
	{
		pAgent->setNavQuery(NULL);
		delete pAgent;
	}
}

HAPI bool NM_agentStartMoveTo(CNavMoveAgent* pAgent, float pos[3])
{
	return pAgent->startMoveTo(pos);
}

HAPI void NM_agentCancelMove(CNavMoveAgent* pAgent)
{
	pAgent->cancelMove();
}

HAPI int NM_agentGetState(CNavMoveAgent* pAgent)
{
	return pAgent->getState();
}

HAPI void NM_agentSetPos(CNavMoveAgent* pAgent, float pos[3])
{
	pAgent->setPos(pos);
}

HAPI void NM_agentGetPos(CNavMoveAgent* pAgent, float* pos)
{
	memcpy(pos, pAgent->getPos(), sizeof(float) * 3);
}

HAPI void NM_agentUpdateState(CNavMoveAgent* pAgent, int deltaTime)
{
	pAgent->updateTick((unsigned int)deltaTime);
}

HAPI float NM_agentGetDistanceToMove(CNavMoveAgent* pAgent)
{
	return pAgent->getDistanceToMove();
}

HAPI float NM_agentGetDistanceCompleted(CNavMoveAgent* pAgent)
{
	return pAgent->getDistanceCompleted();
}

HAPI void NM_agentSetSpeed(CNavMoveAgent* pAgent, float fSpeed)
{
	pAgent->setSpeed(fSpeed);
}

HAPI float NM_agentGetSpeed(CNavMoveAgent* pAgent)
{
	return pAgent->getSpeed();
}
*/

HAPI CNavCrowd* NM_CreateCrowd(CNavQuery* pNavQuery, int nMaxAgents, float agentRadius, float fHeightExt)
{
	dtNavMeshQuery* navQuery = pNavQuery->getNavMeshQuery();
	if (!navQuery)
		return NULL;

	CNavCrowd* pCrowd = new CNavCrowd;
	dtNavMesh* navMesh = (dtNavMesh*)navQuery->getAttachedNavMesh();
	if (!pCrowd->createNavCrowd(navMesh, nMaxAgents, agentRadius, fHeightExt))
	{
		delete pCrowd;
		return NULL;
	}
	pCrowd->setNavQuery(pNavQuery);
	return pCrowd;
}

HAPI void NM_ClearCrowd(CNavCrowd* pNavCrowd)
{
	if (pNavCrowd)
	{
		delete pNavCrowd;
		pNavCrowd = 0;
	}
}

HAPI bool NM_crowdIsValid(CNavCrowd* pNavCrowd)
{
	return pNavCrowd->isValid();
}

HAPI int NM_crowdGetMaxAgentCount(CNavCrowd* pNavCrowd)
{
	return pNavCrowd->getMaxAgentCount();
}

HAPI int NM_crowdGetActiveAgentCount(CNavCrowd* pNavCrowd)
{
	if (!pNavCrowd || !pNavCrowd->isValid())
		return false;

	int nCount = 0;
	for (int i = 0; i < pNavCrowd->getMaxAgentCount(); ++i)
	{
		const HOBA::dtCrowdAgent* pAgent = pNavCrowd->getAgent(i);
		if (pAgent && pAgent->active)
			++nCount;
	}
	return nCount;
}

HAPI bool NM_crowdGetAgentInfo(CNavCrowd* pNavCrowd, int idx, float pos[3], float targetPos[3], float vel[3])
{
	const dtCrowdAgent* ag = pNavCrowd->getAgent(idx);
	if (!ag || !ag->active)
		return false;

	pos[0] = ag->npos[0];
	pos[1] = ag->npos[1];
	pos[2] = ag->npos[2];

	targetPos[0] = ag->targetPos[0];
	targetPos[1] = ag->targetPos[1];
	targetPos[2] = ag->targetPos[2];

	vel[0] = ag->vel[0];
	vel[1] = ag->vel[1];
	vel[2] = ag->vel[2];

	return true;
}

HAPI int NM_crowdAddAgent(CNavCrowd* pNavCrowd, float pos[3], const SAgentParams& param)
{
	return pNavCrowd->addAgent(pos, param);
}

HAPI bool NM_crowdSetAgentPos(CNavCrowd* pNavCrowd, int idx, float pos[3])
{
	return pNavCrowd->setAgentPosition(idx, pos);
}

HAPI bool NM_crowdGetAgentParam(CNavCrowd* pNavCrowd, int idx, SAgentParams* param)
{
	return pNavCrowd->getAgentParam(idx, param);
}

HAPI bool NM_crowdUpdateAgentParam(CNavCrowd* pNavCrowd, int idx, const SAgentParams& param)
{
	return pNavCrowd->updateAgentParam(idx, param);
}

HAPI void NM_crowdRemoveAgent(CNavCrowd* pNavCrowd, int idx)
{
	pNavCrowd->removeAgent(idx);
}

HAPI bool NM_crowdSetMoveTarget(CNavCrowd* pNavCrowd, int idx, float pos[3])
{
	return pNavCrowd->setMoveTarget(idx, pos, false);
}

HAPI bool NM_crowdCancelMove(CNavCrowd* pNavCrowd, int idx)
{
	return pNavCrowd->cancelMove(idx);
}

HAPI void NM_crowdSetAllMoveTarget(CNavCrowd* pNavCrowd, float pos[3])
{
	pNavCrowd->setAllMoveTarget(pos, false);
}

HAPI void NM_crowdCancelAllMove(CNavCrowd* pNavCrowd)
{
	pNavCrowd->cancelAllMove();
}

HAPI void NM_crowdUpdateTick(CNavCrowd* pNavCrowd, int deltaTime)
{
	pNavCrowd->updateTick((unsigned int)deltaTime);
}

HAPI bool NM_crowdUpdateOneAgent(CNavCrowd* pNavCrowd, int idx, int deltaTime, float pos[3], float targetPos[3], float maxspeed, bool bIgnoreCollision, bool bKeepSpeed)
{
	return pNavCrowd->updateOneAgent(idx, deltaTime, pos, targetPos, maxspeed, bIgnoreCollision, bKeepSpeed);
}


