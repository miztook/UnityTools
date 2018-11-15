#pragma once

#include <string>
#include <map>

void funcAnalyzeShader(const char* filename, void* args);
void funcAnalyzeShaderCompiled(const char* filename, void* args);

void analyzeUnityShaders(const char* dir);
void analyzeUnityShadersCompiled(const char* dir);

void writeShaderFileMap(const char* filename);

extern std::map<std::string, std::string>	g_ShaderFileMap;