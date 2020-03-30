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

const char* dungeons[] =
{
	"dn_env02_mageplatform",
	"dn_evn01_dnest",
	"dn_evn03_killerparty",
	"dn_pvp01_guildbase",
	"dn_pvp02_arena01",
	"dn_pvp02_arena02",
	"dungn02_cave01",
	"dungn03_qxgj01",
	"dungn04_zuras01",
	"dungn05_elfarch",
	"dungn06_empirerelic",
};

inline void initMapAssetList()
{
	{
		SAsset asset("city01",
			{
				"city01",
				"city01blocksnew",
			},
			{
				"Cut_Maincastle_1.bnk",
				"Main_Castle_1.bnk",
				"Chinese/Voice_Maincastle_1.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("city02",
			{
				"city02",
				"city02blocksnew",
			},
			{
				"Main_Castle_2.bnk",
				"Chinese/Voice_Maincastle_2.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("dn_pvp03_skyarena",
			{
				"dn_pvp03_skyarena",
				"dn_pvp03_skyarenablocksnew",
			},
			{
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world02",
			{
				"world02",
				"world02blocksnew",
			},
			{
				"Cut_Map_2.bnk",
				"Map_2.bnk",
				"Chinese/Voice_Map_2.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world03part1",
			{
				"world03part1",
				"world03part1blocksnew",
			},
			{
				"Cut_Map_3.bnk",
				"Map_3.bnk",
				"Chinese/Voice_Map_3.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world03part2",
			{
				"world03part2",
				"world03part2blocksnew",
			},
			{
				"Cut_Map_3.bnk",
				"Map_3.bnk",
				"Chinese/Voice_Map_3.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world04part1",
			{
				"world04part1",
				"world04part1blocksnew",
			},
			{
				"Cut_Map_4.bnk",
				"Map_4.bnk",
				"Chinese/Voice_Map_4.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world04part2",
			{
				"world04part2",
				"world04part2blocksnew",
			},
			{
				"Cut_Map_4.bnk",
				"Map_4.bnk",
				"Chinese/Voice_Map_4.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	{
		SAsset asset("world05",
			{
				"world05",
				"world05blocksnew",
			},
			{
				"Cut_Map_5.bnk",
				"Map_5.bnk",
				"Chinese/Voice_Map_5.bnk",
			},
			{
			});
		g_MapAssetList.push_back(asset);
	}

	//
	for (const char* name : dungeons)
	{
		SAsset asset(name,
		{
			name,
		},
		{
		},
		{
		});
		g_MapAssetList.push_back(asset);
	}

}