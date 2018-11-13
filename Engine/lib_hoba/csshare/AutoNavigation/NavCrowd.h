#ifndef _NAV_CROWD_H_
#define _NAV_CROWD_H_

#include "HDetourCrowd.h"
using namespace HOBA;

class CNavQuery;

struct SAgentParams
{
	SAgentParams(float agentRadius, float agentHeight)
		: radius(agentRadius), height(agentHeight)
	{
		maxAcceleration = 8.0f;
		maxSpeed = 3.5f;
		collisionQueryRange = radius * 8.0f;
		pathOptimizationRange = radius * 16.0f;
		separationWeight = 2.0f;
		bAnticipateTurns = true;
		bOptimizeVis = true;
		bOptimizeTopo = true;
		bObstacleAvoidance = false;
		bSeparation = false;
		obstacleAvoidanceType = 3;
	}

	float	radius;
	float height;
	float maxAcceleration;
	float maxSpeed;
	float collisionQueryRange;
	float pathOptimizationRange;
	float separationWeight;
	bool bAnticipateTurns;
	bool bOptimizeVis;
	bool bOptimizeTopo;
	bool bObstacleAvoidance;
	bool bSeparation;
	unsigned char obstacleAvoidanceType;
};

class CNavCrowd
{
public:
	CNavCrowd();
	~CNavCrowd();

public:
	void setNavQuery(CNavQuery* query) { m_NavQuery = query; }

	bool isReady() const;

	bool isValid() const { return m_nCrowd != 0; }
	bool createNavCrowd(dtNavMesh* navMesh, int nMaxAgents, float agentRadius, float fHeightExt);
	void release();

	dtCrowd* getNavCrowd() const { return m_nCrowd; }

	int getMaxAgentCount() const;
	const dtCrowdAgent* getAgent(int idx) const;
	int addAgent(const float* pos, const SAgentParams& param);
	void removeAgent(int idx);
	bool setAgentPosition(int idx, const float* pos);
	bool getAgentParam(int idx, SAgentParams* param);
	bool updateAgentParam(int idx, const SAgentParams& param);
	int hitTestAgents(const float* start, const float* position);
	bool setMoveTarget(int idx, const float* pos, bool adjust);
	void setAllMoveTarget(const float* pos, bool adjust);
	bool cancelMove(int idx);
	void cancelAllMove();

	void updateTick(unsigned int deltaTime);

	//
	bool updateOneAgent(int idx, unsigned int deltaTime, const float* pos, const float* targetpos, float maxspeed, bool bIgnoreCollision, bool bKeepSpeed);

private:
	CNavQuery*		m_NavQuery;
	dtCrowd*		m_nCrowd;
	int				m_nMaxAgents;
	float m_targetPos[3];
	dtPolyRef m_targetRef;
};

#endif