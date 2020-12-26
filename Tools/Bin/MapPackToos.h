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
			},
			{
				"Cut_Maincastle_1.bnk",
				"Main_Castle_1.bnk",
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
				"world02",
				"world02blocksnew",
			},
			{
				"Cut_Map_2.bnk",
				"Map_2.bnk",
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
				"world03part1",
				"world03part1blocksnew",
				"world03part2",
				"world03part2blocksnew",
				"world04part2",
				"world04part2blocksnew",
			},
			{
				"Cut_Map_3.bnk",
				"Map_3.bnk",
				"Cut_Map_4.bnk",
				"Map_4.bnk",
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
				"world04part1",
				"world04part1blocksnew",
			},
			{
				"Main_Castle_2.bnk",
				"Cut_Map_4.bnk",
				"Map_4.bnk",
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
			},
			{
				"Cut_Map_5.bnk",
				"Map_5.bnk",
			},
			{
				"Quest4039.mp4",
				"Quest4222.mp4",
				"Quest4311-2.mp4",
				"Quest5011.mp4",
			});
		g_MapAssetList.push_back(asset);
	}
}