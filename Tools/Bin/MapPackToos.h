#pragma once

#include <string>
#include <vector>

struct SAsset
{
	SAsset(const char* n,
		const std::vector<std::string>& assetbundleArray,
		const std::vector<std::string>& audioArray,
		const std::vector<std::string>& videoArray)
	{
		name = n;
		for (auto item : assetbundleArray)
		{
			assetbundles.push_back(item);
		}
		for (auto item : audioArray)
		{
			audios.push_back(item);
		}
		for (auto item : videoArray)
		{
			videos.push_back(item);
		}
	}

	std::string name;
	std::vector<std::string> assetbundles;
	std::vector<std::string> audios;
	std::vector<std::string> videos;
};

extern std::vector<SAsset> g_MapAssetList;

inline void initMapAssetList()
{
	{
		SAsset asset("1",
			{
				"city01",
				"city01blocksnew",
				"dn_pvp02_arena02",
				"dungn02_cave01",
				"dn_pvp03_skyarena",
				"dn_pvp03_skyarenablocksnew",
			},
			{
			},
			{
				"Dn01_Arena02.mp4",
				"Mall_CG01.mp4",
				"Mall_CG01_Loop.mp4",
				"Mall_CG02.mp4",
				"Mall_CG02_Loop.mp4",
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("2",
			{
				"dn_pvp02_arena01",
				"dungn03_qxgj01",
				"world02",
				"world02blocksnew",
				"dn_env02_mageplatform",
				"dn_evn01_dnest",
			},
			{
			},
			{
				"Dn03.mp4",
				"Quest1086.mp4",
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("3",
			{
				"dungn04_zuras01",
				"world03part1",
				"world03part1blocksnew",
				"world03part2",
				"world03part2blocksnew",
				"world04part2",
				"world04part2blocksnew",
			},
			{
			},
			{
				"Quest2090.mp4",
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("4",
			{
				"city02",
				"city02blocksnew",
				"dungn05_elfarch",
				"world04part1",
				"world04part1blocksnew",
			},
			{
			},
			{
				"Quest3330.mp4",
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("5",
			{
				"dungn06_empirerelic",
				"world05",
				"world05blocksnew",
				"dn_evn03_killerparty",
			},
			{
			},
			{
				"Quest4039.mp4",
				"Quest4222.mp4",
				"Quest4311-2.mp4",
			});
		g_MapAssetList.push_back(asset);
	}
}