#include "UnityShaderAnalyzer.h"
#include <stdio.h>
#include <crtdbg.h>
#include "ShaderAnalyze.h"

int main()
{
#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);
	HOBAInitParam param;
	param.pszBaseDir = tmp;
	param.pszDocumentDir = tmp;
	param.pszLibraryDir = tmp;
	param.pszTemporaryDir = tmp;

	g_pAFramework->Init(param);

	g_ShaderFileMap.clear();		
	//内置shader
	analyzeUnityShaders("builtin_shaders-5.6.5f1");

	writeShaderFileMap("ShaderMap_BuiltIn.txt");
	g_ShaderFileMap.clear();	
	//M1shader
	analyzeUnityShaders("Outputs/Shader");

	writeShaderFileMap("ShaderMap_Output.txt");
	g_ShaderFileMap.clear();
	//3rd
	analyzeUnityShaders("3rd");

	writeShaderFileMap("ShaderMap_3rd.txt");
	g_ShaderFileMap.clear();
	
	printf("UnityShaderAnalyzer Success!\r\n");
	g_pAFramework->Printf("UnityShaderAnalyzer Success!\r\n");

	g_pAFramework->Release();

	getchar();
	return 0;
}