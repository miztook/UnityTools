#ifndef _NAVMESH_EXPORT_H_
#define _NAVMESH_EXPORT_H_

#include "baseDef.h"

class CNavMesh;
class CNavQuery;
class CNavMoveAgent;
class CNavCrowd;
struct SAgentParams;

HAPI CNavMesh* NM_LoadNavMesh(const char* path);
HAPI CNavMesh* NM_LoadNavMeshFromMemory(unsigned char* bytes, int numBytes);
HAPI void NM_ClearNavMesh(CNavMesh* pNavMesh);
HAPI CNavQuery* NM_CreateNavQuery(CNavMesh* pNavMesh, int nMaxNodes);
HAPI void NM_ClearNavQuery(CNavQuery* pNavQuery);

HAPI void NM_NavMeshGetVertexIndexCount(CNavMesh* pNavMesh, int* vcount, int* icount, int areaId);
HAPI void NM_NavMeshFillVertexIndexBuffer(CNavMesh* pNavMesh, float vertices[], int vcount, int indices[], int icount, int areaId);

HAPI bool NM_GetNearestValidPosition(CNavQuery* pNavQuery, float pos[3], float ext[3], float nearestPt[3]);
HAPI bool NM_RecalcPathFindFollow(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* smoothPathPoints, float* smoothDistance, int* numPoints);
HAPI bool NM_GetPathFindFollowDistance(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* fDistance);
HAPI bool NM_GetPathFindFollowPoints(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float STEP_SIZE, float SLOP, bool bOnlyXZ, float* points, int* numPoints);
HAPI bool NM_Raycast(CNavQuery* pNavQuery, float startpos[3], float endpos[3], float polyPickExt[3], float& t);
HAPI bool NM_GetPosHeight(CNavQuery* pNavQuery, float pos[3], float fExtRadius, float fExtHeight, float& fHeight);
HAPI void NM_SetAreaCost(CNavQuery* pNavQuery, int areaId, float fCost);
HAPI float NM_GetAreaCost(CNavQuery* pNavQuery, int areaId);

//agent
/*
HAPI CNavMoveAgent* NM_CreateAgent(CNavQuery* pNavQuery);
HAPI void NM_ClearAgent(CNavMoveAgent* pAgent);
HAPI bool NM_agentStartMoveTo(CNavMoveAgent* pAgent, float pos[3]);
HAPI void NM_agentCancelMove(CNavMoveAgent* pAgent);
HAPI int NM_agentGetState(CNavMoveAgent* pAgent);
HAPI void NM_agentSetPos(CNavMoveAgent* pAgent, float pos[3]);
HAPI void NM_agentGetPos(CNavMoveAgent* pAgent, float* pos);
HAPI void NM_agentUpdateState(CNavMoveAgent* pAgent, int deltaTime);
HAPI float NM_agentGetDistanceToMove(CNavMoveAgent* pAgent);
HAPI float NM_agentGetDistanceCompleted(CNavMoveAgent* pAgent);
HAPI void NM_agentSetSpeed(CNavMoveAgent* pAgent, float fSpeed);
HAPI float NM_agentGetSpeed(CNavMoveAgent* pAgent);
*/

//crowd
HAPI CNavCrowd* NM_CreateCrowd(CNavQuery* pNavQuery, int nMaxAgents, float agentRadius, float fHeightExt);
HAPI void NM_ClearCrowd(CNavCrowd* pNavCrowd);
HAPI bool NM_crowdIsValid(CNavCrowd* pNavCrowd);
HAPI int NM_crowdGetMaxAgentCount(CNavCrowd* pNavCrowd);
HAPI int NM_crowdGetActiveAgentCount(CNavCrowd* pNavCrowd);
HAPI bool NM_crowdGetAgentInfo(CNavCrowd* pNavCrowd, int idx, float pos[3], float targetPos[3], float vel[3]);
HAPI int NM_crowdAddAgent(CNavCrowd* pNavCrowd, float pos[3], const SAgentParams& param);
HAPI bool NM_crowdSetAgentPos(CNavCrowd* pNavCrowd, int idx, float pos[3]);
HAPI bool NM_crowdGetAgentParam(CNavCrowd* pNavCrowd, int idx, SAgentParams* param);
HAPI bool NM_crowdUpdateAgentParam(CNavCrowd* pNavCrowd, int idx, const SAgentParams& param);
HAPI void NM_crowdRemoveAgent(CNavCrowd* pNavCrowd, int idx);
HAPI bool NM_crowdSetMoveTarget(CNavCrowd* pNavCrowd, int idx, float pos[3]);
HAPI bool NM_crowdCancelMove(CNavCrowd* pNavCrowd, int idx);
HAPI void NM_crowdSetAllMoveTarget(CNavCrowd* pNavCrowd, float pos[3]);
HAPI void NM_crowdCancelAllMove(CNavCrowd* pNavCrowd);
HAPI void NM_crowdUpdateTick(CNavCrowd* pNavCrowd, int deltaTime);
HAPI bool NM_crowdUpdateOneAgent(CNavCrowd* pNavCrowd, int idx, int deltaTime, float pos[3], float targetPos[3], float maxspeed, bool bIgnoreCollision, bool bKeepSpeed);

#endif