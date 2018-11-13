#include "AFramework.h"
#include "AFI.h"
#include "ASys.h"
#include "AFilePackMan.h"

AFramework gFramework;
AFramework* g_pAFramework = &gFramework;

AFramework::AFramework()
{
}

AFramework::~AFramework()
{
}

bool AFramework::Init(const HOBAInitParam& param, bool bLog)
{
	af_Initialize(param.pszBaseDir, param.pszDocumentDir, param.pszLibraryDir, param.pszTemporaryDir);

	if (bLog && !m_log.Init("hoba.log", "hoba log file", false))
	{
		return false;
	}

	//	Default file package algorithm ID, user can change it in Startup()
	g_AFilePackMan.SetAlgorithmID(161);

	m_strESShader = af_GetBaseDir();
	m_strESShader.NormalizeDirName();
	m_strESShader.Append("es/shaders/");
	m_strESShader.NormalizeDirName();

	m_strESTexture = af_GetBaseDir();
	m_strESTexture.NormalizeDirName();
	m_strESTexture.Append("es/textures/");
	m_strESTexture.NormalizeDirName();

	return true;
}

void AFramework::Release()
{
	m_log.Release();

	af_Finalize();
}

void AFramework::Printf(const char *szMsg, ...)
{
	char szLogMsg[2048];
	va_list args_list;

	va_start(args_list, szMsg);
	vsnprintf(szLogMsg, sizeof(szLogMsg), szMsg, args_list);
	va_end(args_list);

	m_log.LogString(szLogMsg);
}
void AFramework::DevPrintf(const char* szMsg, ...)
{
	char szLogMsg[2048];
	va_list args_list;

	va_start(args_list, szMsg);
	vsnprintf(szLogMsg, sizeof(szLogMsg), szMsg, args_list);
	va_end(args_list);

	m_log.LogString(szLogMsg);
	ASys::OutputDebug(szLogMsg);
}

void AFramework::DevPrintfString(const char* szMsg)
{
	m_log.LogString(szMsg);
	ASys::OutputDebug(szMsg);
}

extern "C" void g_DevPrintf(const char* szMsg, ...)
{
	char szLogMsg[2048];
	va_list args_list;

	va_start(args_list, szMsg);
	vsnprintf(szLogMsg, sizeof(szLogMsg), szMsg, args_list);
	va_end(args_list);

	g_pAFramework->DevPrintfString(szLogMsg);
}