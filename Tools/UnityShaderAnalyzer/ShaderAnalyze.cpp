#include "ShaderAnalyze.h"
#include "UnityShaderAnalyzer.h"

std::map<string_path, string_path>	g_ShaderFileMap;


void funcAnalyzeShader(const char* filename, void* args)
{
	if (!hasFileExtensionA(filename, "shader"))
		return;

	AString fullFileName = (const char*)args;
	fullFileName.NormalizeDirName();
	fullFileName += filename;

	AFileImage File;
	if (!File.Open("", fullFileName, AFILE_OPENEXIST | AFILE_TEXT | AFILE_TEMPMEMORY))
		return;

	char	szLine[AFILE_LINEMAXLEN];
	auint32 dwReadLen;

	bool bFind = false;
	AString shaderName;
	while (File.ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
	{
		if (strncmp(szLine, "Shader ", 6) == 0)
		{
			shaderName.Empty();
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
		g_ShaderFileMap[(const char*)shaderName] = filename;
	}
}

void funcAnalyzeShaderCompiled(const char* filename, void* args)
{

}

void analyzeUnityShaders(const char* dir)
{
	printf("analyzing shaders %s\n\n", dir);

	string_path dirname = af_GetBaseDir();
	dirname.normalizeDir();
	dirname.append(dir);
	Q_iterateFiles(dirname.c_str(), "*.*", funcAnalyzeShader, (void*)dirname.c_str(), dirname.c_str());

	printf("\n\n");
}

void analyzeUnityShadersCompiled(const char* dir)
{

}

void writeShaderFileMap(const char* filename)
{
	AString strFileName = af_GetBaseDir();
	strFileName.NormalizeDirName();
	strFileName += filename;

	FILE* file = fopen(strFileName, "wt");
	if (!file)
		return;

	for (auto itr = g_ShaderFileMap.begin(); itr != g_ShaderFileMap.end(); ++itr)
	{
		fprintf(file, "%s\t\t\t\t\t\t%s\n", itr->first.c_str(), itr->second.c_str());
	}

	fclose(file);
}
