#include "UnityShaderAnalyzer.h"
#include <stdio.h>
#include <crtdbg.h>
#include "ShaderAnalyze.h"

#include "AWinMemDbg.h"
#include "AWinMiniDump.h"

#pragma comment(lib, "Angelica.lib")

IAGame* g_pAGame = NULL;

void AUI_Tick(auint32 timeSinceLastFrame){}
void AUI_Render() {}

int main()
{
#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	AWinMemDbg globalDbg;
	globalDbg.beginCheckPoint();

	{
		AWindow wnd = ASys::createWindow("UnityShaderAnalyzer", 1136, 640, 1.0f, true);
		HWND hwnd = wnd.m_Handle;

		char szCurrentDirectory[MAX_PATH];
		GetCurrentDirectoryA(MAX_PATH, szCurrentDirectory);

		AString strTempDirectory(szCurrentDirectory);
		strTempDirectory += "/tmp";

		AString strLibDirectory(szCurrentDirectory);
		strLibDirectory += "/Library/Caches/updateres";

		AFrameworkInitParam frameworkInitParam;
		frameworkInitParam.pszBaseDir = szCurrentDirectory;
		frameworkInitParam.pszDocumentDir = szCurrentDirectory;
		frameworkInitParam.pszLibraryDir = strLibDirectory;
		frameworkInitParam.pszTemporaryDir = (const char*)strTempDirectory;

		createEngine(frameworkInitParam, wnd);

		g_ShaderFileMap.clear();		
		//内置shader
		analyzeUnityShaders("builtin_shaders-5.3.6f1");

		writeShaderFileMap("ShaderMap_BuiltIn.txt");
		g_ShaderFileMap.clear();	
		//M1shader
		analyzeUnityShaders("Shaders");

		writeShaderFileMap("ShaderMap_M1.txt");
		g_ShaderFileMap.clear();
		//3rd
		analyzeUnityShaders("3rd");

		writeShaderFileMap("ShaderMap_3rd.txt");
		g_ShaderFileMap.clear();

		destroyEngine();
	}
	
	bool safe = globalDbg.endCheckPoint();
	_ASSERT(safe);

	globalDbg.outputMaxMemoryUsed();

	printf("Run Completed.\n");
	getchar();
	return 0;
}