#include "ShaderAnalyze.h"
#include "UnityShaderAnalyzer.h"

std::map<std::string, std::string>	g_ShaderFileMap;


void funcAnalyzeShaderCompiled(const char* filename, void* args)
{

}

void analyzeUnityShaders(const char* dir)
{
	printf("analyzing shaders %s\n\n", dir);

	std::string dirname = af_GetBaseDir();
	normalizeDirName(dirname);
	dirname.append(dir);
	Q_iterateFiles(dirname.c_str(), "*.*", 
		[&dirname](const char* filename)
	{
		if (!hasFileExtensionA(filename, "shader"))
			return;

		std::string dir = dirname;
		normalizeDirName(dir);
		std::string fullFileName = dir + filename;

		AFileImage File;
		if (!File.Open("", fullFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT | AFILE_TEMPMEMORY))
			return;

		char	szLine[AFILE_LINEMAXLEN];
		auint32 dwReadLen;

		bool bFind = false;
		std::string shaderName;
		while (File.ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
		{
			if (strncmp(szLine, "Shader ", 6) == 0)
			{
				shaderName.clear();
				bool bLeft = false;
				bool bRight = false;
				const char* p = szLine;
				while (*p++)
				{
					if (*p == '\"')
					{
						if (bLeft)
							bRight = true;
						else
							bLeft = true;

						continue;
					}

					if (bLeft && bRight)
						break;

					if (bLeft)
					{
						shaderName += (*p);
					}
				}

				bFind = true;
				break;
			}
		}

		if (bFind)
		{
			g_ShaderFileMap[shaderName] = filename;
		}
	}
		, dirname.c_str());

	printf("\n\n");
}

void analyzeUnityShadersCompiled(const char* dir)
{

}

void writeShaderFileMap(const char* filename)
{
	std::string strFileName = af_GetBaseDir();
	normalizeDirName(strFileName);
	strFileName += filename;

	FILE* file = fopen(strFileName.c_str(), "wt");
	if (!file)
		return;

	for (auto itr = g_ShaderFileMap.begin(); itr != g_ShaderFileMap.end(); ++itr)
	{
		fprintf(file, "%s\t\t\t\t\t\t%s\n", itr->first.c_str(), itr->second.c_str());
	}

	fclose(file);
}
