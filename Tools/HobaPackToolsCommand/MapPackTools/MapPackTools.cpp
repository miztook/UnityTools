#include "ElementJUPGenerator.h"
#include "AFramework.h"
#include <memory>
#include "../../Bin/MapPackToos.h"

std::vector<SAsset> g_MapAssetList;

//	Windows 1.0.0 "../M1Update/JupGenerate"
int main(int argc, char* argv[])
{
	if (argc != 5)
	{
		printf("param error!\r\n");
		g_pAFramework->Printf("param error!\r\n");

		printf("generate base version.txt, usage: MapPackTools.exe\t<Platform>\t<BaseVersion>\t<BasePath>\t<OutputPath>\n");
		g_pAFramework->Printf("generate base version.txt, usage: MapPackTools.exe\t<Platform>\t<BaseVersion>\t<BaseVersion>\t<OutputPath>\n");

		return -1;
	}

	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);
	HOBAInitParam param;
	param.pszBaseDir = tmp;
	param.pszDocumentDir = tmp;
	param.pszLibraryDir = tmp;
	param.pszTemporaryDir = tmp;

	g_pAFramework->Init(param);

	std::string strPlatform = argv[1];
	std::string baseVersion = argv[2];
	std::string strBasePath = argv[3];
	std::string strOutputPath = argv[4];

	std::unique_ptr<CElementJUPGenerator> pCElementJUPGenerator(new CElementJUPGenerator);

	if (!pCElementJUPGenerator->Init(strBasePath, strOutputPath))
	{
		return -1;
	}

	pCElementJUPGenerator->SetPlatform(strPlatform);
	pCElementJUPGenerator->SetVersion(baseVersion);

	printf("Platform: %s\r\n", strPlatform.c_str());
	g_pAFramework->Printf("Platform: %s\r\n", strPlatform.c_str());

	printf("BaseVerson: %s\r\n\r\n", baseVersion.c_str());
	g_pAFramework->Printf("BaseVerson: %s\r\n\r\n", baseVersion.c_str());

	const CElementJUPGenerator::SVersion& sversion = pCElementJUPGenerator->GetSVersion();
	SJupContent jupContent;

	initMapAssetList();
	for (const SAsset& asset : g_MapAssetList)
	{
		if (!pCElementJUPGenerator->GenerateUpdateList(
			sversion,
			asset.name,
			asset.assetbundles,
			asset.audios,
			asset.videos,
			jupContent))
		{
			printf("End GenerateUpdateList, Fail\r\n");
			g_pAFramework->Printf("End GenerateUpdateList, Fail\r\n");
			goto FAIL;
		}

		if (!pCElementJUPGenerator->GeneratePck(jupContent))
		{
			printf("End GenerateJup, Fail\r\n");
			g_pAFramework->Printf("End GenerateJup, Fail\r\n");

			goto FAIL;
		}
	}

	printf("Begin GenerateVersionTxt......\r\n\r\n");
	g_pAFramework->Printf("Begin GenerateVersionTxt......\r\n");
	if (!pCElementJUPGenerator->GenerateVersionTxt(sversion.BaseVersion, strOutputPath))
	{
		printf("End GenerateVersion, Fail\r\n");
		g_pAFramework->Printf("End GenerateVersion, Fail\r\n");

		goto FAIL;
	}

	printf("MapPackTools Success!\r\n");
	g_pAFramework->Printf("MapPackTools Success!\r\n");

	g_pAFramework->Release();

	//getchar();
	return 0;

FAIL:
	printf("End MapPackTools, Fail\r\n");
	g_pAFramework->Printf("End MapPackTools, Fail\r\n");

	g_pAFramework->Release();
	//getchar();
	return -1;
}