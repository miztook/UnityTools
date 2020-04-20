#include "ElementJUPGenerator.h"
#include "AFramework.h"
#include <memory>

//#define JUP_SIZE_LIMIT    (((aint64)2) * ((aint64)1024) * ((aint64)1024) * ((aint64)1024))
#define JUP_SIZE_LIMIT    (((aint64)200) * ((aint64)1024) * ((aint64)1024))
//50000000

/*
param
{
PlatformType,
BaseVersion,
LastVersion,
NextVersion,
}

*/

//	Windows 1.0.0 1.0.0 1.0.1 "../M1Update/UpdateResource/LastVersion" "../M1Update/UpdateResource/NextVersion" "../M1Update/JupGenerate" 0
int main(int argc, char* argv[])
{
	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);
	HOBAInitParam param;
	param.pszBaseDir = tmp;
	param.pszDocumentDir = tmp;
	param.pszLibraryDir = tmp;
	param.pszTemporaryDir = tmp;

	g_pAFramework->Init(param);

	if (argc == 3)
	{
		printf("COMMAND: generate base version.txt!\r\n\r\n");
		g_pAFramework->Printf("COMMAND: generate base version.txt!\r\n\r\n");

		std::string baseVer = argv[1];
		std::string strOutputPath = argv[2];

		if (CElementJUPGenerator::GenerateBaseVersionTxt(baseVer, strOutputPath))
		{
			printf("JupGenerator Success!\r\n");
			g_pAFramework->Printf("JupGenerator Success!\r\n");

			//getchar();
			return 0;
		}
		else
		{
			printf("End JupGenerator, Fail\r\n");
			g_pAFramework->Printf("End JupGenerator, Fail\r\n");
			//getchar();
			return -1;
		}
	}
	else if (argc == 4)
	{
		printf("COMMAND: generate version.txt!\r\n\r\n");
		g_pAFramework->Printf("COMMAND: generate version.txt!\r\n\r\n");

		std::string baseVer = argv[1];
		std::string nextVer = argv[2];
		std::string strOutputPath = argv[3];

		if (CElementJUPGenerator::GenerateVersionTxt(baseVer, nextVer, strOutputPath))
		{
			printf("JupGenerator Success!\r\n");
			g_pAFramework->Printf("JupGenerator Success!\r\n");

			//getchar();
			return 0;
		}
		else
		{
			printf("End JupGenerator, Fail\r\n");
			g_pAFramework->Printf("End JupGenerator, Fail\r\n");
			//getchar();
			return -1;
		}
	}
	else if (argc == 9)
	{
		printf("COMMAND: generate jup and version.txt!\r\n\r\n");
		g_pAFramework->Printf("COMMAND: generate jup and version.txt!\r\n\r\n");
	}
	else
	{
		printf("param error!\r\n");
		g_pAFramework->Printf("param error!\r\n");

		printf("generate base version.txt, usage: HobaPackToolsCommand.exe\n<BaseVersion> \n<OutputPath>\n");
		g_pAFramework->Printf("generate base version.txt, usage: HobaPackToolsCommand.exe\n<BaseVersion> \n<OutputPath>\n");

		printf("generate jup and version.txt, usage: HobaPackToolsCommand.exe\n<PlatformType> \n<BaseVersion> \n<LastVersion> \n<NextVersion> \n<LastPath> \n<NextPath> \n<OutputPath> \n<SmallPack?1:0>\n");
		g_pAFramework->Printf("generate jup and version.txt, usage: HobaPackToolsCommand.exe\n<PlatformType> \n<BaseVersion> \n<LastVersion> \n<NextVersion> \n<LastPath> \n<NextPath> \n<OutputPath> \n<SmallPack?1:0>\n");

		//getchar();
		return -1;
	}

	//argc == 9
	std::string strPlatform = argv[1];
	std::string ver1 = argv[2];
	std::string ver2 = argv[3];
	std::string ver3 = argv[4];
	std::string strLastPath = argv[5];
	std::string strNextPath = argv[6];
	std::string strOutputPath = argv[7];
	std::string strSmall = argv[8];
	int iSmallPack = atoi(strSmall.c_str());
	bool bSmallPack = iSmallPack != 0;			//是否小包

	std::unique_ptr<CElementJUPGenerator> pCElementJUPGenerator(new CElementJUPGenerator);

	if (!pCElementJUPGenerator->Init(strLastPath, strNextPath, strOutputPath, bSmallPack))
	{
		return -1;
	}

	pCElementJUPGenerator->SetPlatform(strPlatform);
	pCElementJUPGenerator->SetVersion(ver1, ver2, ver3);

	printf("Platform: %s\r\n", strPlatform.c_str());
	g_pAFramework->Printf("Platform: %s\r\n", strPlatform.c_str());

	printf("BaseVerson: %s LastVersion: %s NextVersion: %s SmallPack: %d\r\n\r\n", ver1.c_str(), ver2.c_str(), ver3.c_str(), iSmallPack);
	g_pAFramework->Printf("BaseVerson: %s LastVersion: %s NextVersion: %s SmallPack: %d\r\n\r\n", ver1.c_str(), ver2.c_str(), ver3.c_str(), iSmallPack);

	const CElementJUPGenerator::SVersion& sversion = pCElementJUPGenerator->GetSVersion();		//要升级的版本
	SJupContent jupContent;
	std::vector<SJupContent> jupContentSplitList;
	std::string jupFileName;

	printf("Begin GenerateUpdateList......\r\n\r\n");
	g_pAFramework->Printf("Begin GenerateUpdateList......\r\n");

	if (!pCElementJUPGenerator->GenerateUpdateList(sversion, jupContent))
	{
		printf("End GenerateUpdateList, Fail\r\n");
		g_pAFramework->Printf("End GenerateUpdateList, Fail\r\n");
		goto FAIL;
	}
	
	printf("Split Jup......\r\n\r\n");
	g_pAFramework->Printf("Split Jup......\r\n");
	if (!pCElementJUPGenerator->SplitJup(jupContent, jupContentSplitList, JUP_SIZE_LIMIT))
	{
		printf("End GenerateJup, Fail\r\n");
		g_pAFramework->Printf("End GenerateJup, Fail\r\n");
		goto FAIL;
	}
	
	printf("Before Split: \r\n");
	g_pAFramework->Printf("Before Split: \r\n");

	jupContent.ToFileName(jupFileName);
	printf("\t%s\n", jupFileName.c_str());
	g_pAFramework->Printf("\t%s\n", jupFileName.c_str());

	printf("After Split: \r\n");
	g_pAFramework->Printf("After Split: \r\n");

	for (const auto& jup : jupContentSplitList)
	{
		jup.ToFileName(jupFileName);
		printf("\t%s\n", jupFileName.c_str());
		g_pAFramework->Printf("\t%s\n", jupFileName.c_str());

	}
	printf("\r\n");
	g_pAFramework->Printf("\r\n");

	printf("Begin GenerateJup......\r\n\r\n");
	g_pAFramework->Printf("Begin GenerateJup......\r\n");

	const auto& SVersion = pCElementJUPGenerator->GetSVersion();
	bool bForceMx0 = bSmallPack && (SVersion.BaseVersion == SVersion.LastVersion);
	for (const auto& jup : jupContentSplitList)
	{
		if (!pCElementJUPGenerator->GenerateJup(jup, bForceMx0))
		{
			printf("End GenerateJup, Fail\r\n");
			g_pAFramework->Printf("End GenerateJup, Fail\r\n");

			goto FAIL;
		}
	}

	printf("Begin GenerateVersionTxt......\r\n\r\n");
	g_pAFramework->Printf("Begin GenerateVersionTxt......\r\n");
	if (!pCElementJUPGenerator->GenerateVersionTxt(sversion))
	{
		printf("End GenerateVersion, Fail\r\n");
		g_pAFramework->Printf("End GenerateVersion, Fail\r\n");

		goto FAIL;
	}

	
	printf("Begin JupUpdateTxt......\r\n\r\n");
	g_pAFramework->Printf("Begin JupUpdateTxt......\r\n");
	pCElementJUPGenerator->ProcessUpdateList(jupContent);
	if (!pCElementJUPGenerator->GenerateJupUpdateText(jupContentSplitList))
	{
		printf("End GenerateJupUpdate, Fail\r\n");
		g_pAFramework->Printf("End GenerateJupUpdate, Fail\r\n");

		goto FAIL;
	}

	//pCElementJUPGenerator->OpenJupDir();

	printf("JupGenerator Success!\r\n");
	g_pAFramework->Printf("JupGenerator Success!\r\n");

	g_pAFramework->Release();

	//getchar();
	return 0;

FAIL:
	printf("End JupGenerator, Fail\r\n");
	g_pAFramework->Printf("End JupGenerator, Fail\r\n");

	g_pAFramework->Release();
	//getchar();
	return -1;
}