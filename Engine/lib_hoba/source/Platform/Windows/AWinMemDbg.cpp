#include "AWinMemDbg.h"
#include "ASys.h"
#include "AFramework.h"

size_t g_maxAlloc = 1000;
auint32 g_BytesAllocated = 0;

int __cdecl MyAllocHook(
	int      nAllocType,
	void   * pvData,
	size_t   nSize,
	int      nBlockUse,
	long     lRequest,
	const unsigned char * szFileName,
	int      nLine
	)
{
	const char *operation[] = { "", "allocating", "re-allocating", "freeing" };
	const char *blockType[] = { "Free", "Normal", "CRT", "Ignore", "Client" };

	if ( nBlockUse == _CRT_BLOCK )   // Ignore internal C runtime library allocations
		return( TRUE );

	assert( ( nAllocType > 0 ) && ( nAllocType < 4 ) );
	assert( ( nBlockUse >= 0 ) && ( nBlockUse < 5 ) );

	if (nSize > g_maxAlloc && (nAllocType == 1 || nAllocType == 2))
	{
// 		ASys::OutputDebug("Memory operation in %s, line %d: %s a %d-byte '%s' block (#%ld)\n",
// 			szFileName, nLine, operation[nAllocType], nSize, 
// 			blockType[nBlockUse], lRequest );

		g_BytesAllocated += (int)nSize;
	}

	return( TRUE );         // Allow the memory operation to proceed
}

void AWinMemDbg::beginCheckPoint()
{
	_CrtMemCheckpoint(&OldState);
}

bool AWinMemDbg::endCheckPoint()
{
	_CrtMemCheckpoint(&NewState);

	int diff = _CrtMemDifference(&DiffState, &OldState, &NewState);
	return diff == 0;
}

void AWinMemDbg::outputDifference( const char* funcname )
{
	//ASys::OutputDebug("%s memory used: %0.2f M\n", funcname,
	//	DiffState.lSizes[_NORMAL_BLOCK] / 1048576.f);

	ASys::OutputDebug("%s memory used: %d bytes\n", funcname,
		DiffState.lSizes[_NORMAL_BLOCK]);
}

void AWinMemDbg::setAllocHook( bool enable, int nMaxAlloc /*= 1000*/ )
{
	if (enable)
	{
		_CrtSetAllocHook(MyAllocHook);
		g_maxAlloc = nMaxAlloc;
	}
	else
	{
		_CrtSetAllocHook(NULL);
	}
}

void AWinMemDbg::outputMaxMemoryUsed(int* memKB)
{
	_CrtMemCheckpoint(&OldState);

	g_pAFramework->DevPrintf("maximum memory used: %0.3f M\n", OldState.lHighWaterCount / 1048576.f);

	if (memKB)
		*memKB = (int)(OldState.lHighWaterCount / 1024.0f);
}

void AWinMemDbg::getMemoryStats(int* peakMemKB, int* curMemKB)
{
	_CrtMemCheckpoint(&CurrentState);

	*peakMemKB = (int)(CurrentState.lHighWaterCount / 1024.0f);
	*curMemKB = (int)(CurrentState.lTotalCount / 1024.0f);
}

void AWinMemDbg::dumpMemoryStates(const char* funcname)
{
	_CrtMemCheckpoint(&CurrentState);

// 	g_pAFramework->DevPrintf("%s [free block] memory used: %0.3f M\n", funcname, CurrentState.lSizes[_FREE_BLOCK] / 1048576.f);
// 	g_pAFramework->DevPrintf("%s [normal block] memory used: %0.3f M\n", funcname, CurrentState.lSizes[_NORMAL_BLOCK] / 1048576.f);
// 	g_pAFramework->DevPrintf("%s [crt block] memory used: %0.3f M\n", funcname, CurrentState.lSizes[_CRT_BLOCK] / 1048576.f);
// 	g_pAFramework->DevPrintf("%s [ignore block] memory used: %0.3f M\n", funcname, CurrentState.lSizes[_IGNORE_BLOCK] / 1048576.f);
// 	g_pAFramework->DevPrintf("%s [client block] memory used: %0.3f M\n", funcname, CurrentState.lSizes[_CLIENT_BLOCK] / 1048576.f);

	g_pAFramework->DevPrintf("%s [free block] memory used: %0.1f K\n", funcname, CurrentState.lSizes[_FREE_BLOCK] / 1024.f);
	g_pAFramework->DevPrintf("%s [normal block] memory used: %0.1f K\n", funcname, CurrentState.lSizes[_NORMAL_BLOCK] / 1024.f);
	g_pAFramework->DevPrintf("%s [crt block] memory used: %0.1f K\n", funcname, CurrentState.lSizes[_CRT_BLOCK] / 1024.f);
	g_pAFramework->DevPrintf("%s [ignore block] memory used: %0.1f K\n", funcname, CurrentState.lSizes[_IGNORE_BLOCK] / 1024.f);
	g_pAFramework->DevPrintf("%s [client block] memory used: %0.1f K\n", funcname, CurrentState.lSizes[_CLIENT_BLOCK] / 1024.f);
}

void AWinMemDbg::registerFrame(auint32 now)
{
	const auint32 milli = now - LastTime;

	if (milli >= 2000)
	{
		const float invMilli = 1.0f / (float)milli;
		MPS = (1000 * (float)g_BytesAllocated) * invMilli;
		g_BytesAllocated = 0;
		LastTime = now;
	}
}
