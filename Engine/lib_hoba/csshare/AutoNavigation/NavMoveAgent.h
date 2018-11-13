#ifndef _NAV_MOVEAGENT_H_
#define _NAV_MOVEAGENT_H_

class CNavQuery;

class CNavMoveAgent
{
public:
	CNavMoveAgent();
	~CNavMoveAgent();

public:
	enum State
	{
		NONE = 0,
		SEARCH,
		MOVING,
		FINISHED,

		STATE_FORCE_32_BIT_DO_NOT_USE = 0x7fffffff
	};

	static const int MAX_SMOOTH = 2048;

public:
	void setNavQuery(CNavQuery* query) { m_NavQuery = query; }

	bool isReady() const;

	void setPos(float pos[3])  { m_vPos[0] = pos[0];  m_vPos[1] = pos[1]; m_vPos[2] = pos[2]; }
	const float* getPos() const { return m_vPos; }

	void setSpeed(float speed) { m_fSpeed = speed; }
	float getSpeed() const { return m_fSpeed; }

	float getDistanceToMove() const { return m_distanceToMove; }
	float getDistanceCompleted() const { return m_distanceCompleted; }

	bool startMoveTo(float dest[3]);
	void cancelMove();

	State getState() const { return m_state; }
	void reset();

	void updateTick(unsigned int deltaTime);

	bool doSearchState();
	bool doMovingState(unsigned int deltaTime);
	bool doFinishedState();

	const float* getSmoothPath() const { return m_smoothPath; }
	const float* getSmoothDistance() const { return m_smoothDistance; }
	int getNumSmoothPath() const { return m_nSmoothPath; }

private:
	CNavQuery*		m_NavQuery;
	float			m_vPos[3];
	float			m_vDest[3];
	float			m_polyPickExt[3];
	State		m_state;

	float		m_smoothPath[MAX_SMOOTH * 3];
	float		m_smoothDistance[MAX_SMOOTH];
	int			m_nSmoothPath;

	float		m_fSpeed;
	int		m_iPath;
	float		m_distanceCompleted;
	float		m_distanceToMove;
};

#endif