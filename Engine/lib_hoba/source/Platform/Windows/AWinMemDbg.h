#pragma once

#include <crtdbg.h>
#include "ASys.h"

class AWinMemDbg
{
public:
	AWinMemDbg() 
	{
		MPS = 60;
		LastTime = ASys::GetMilliSecond();
	}

	void beginCheckPoint();

	bool endCheckPoint();

	void outputDifference(const char* funcname);

	void setAllocHook(bool enable, int nMaxAlloc = 1000);

	void outputMaxMemoryUsed(int* memKB);

	void getMemoryStats(int* peakMemKB, int* curMemKB);

	void dumpMemoryStates(const char* funcname);

	void registerFrame(auint32 now);
	float getMPS() const { return MPS; }

private:
	_CrtMemState		OldState;
	_CrtMemState		NewState;
	_CrtMemState		DiffState;
	_CrtMemState		CurrentState;

	auint32		LastTime;
	float MPS;
};
