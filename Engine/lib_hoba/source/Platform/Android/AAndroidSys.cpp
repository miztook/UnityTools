#include "ASys.h"

#include "compileconfig.h"
#if defined(A_PLATFORM_ANDROID)

#include "glob.h"
#include <ctype.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/time.h>
#include <android/log.h>
#include <vector>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cerrno>

bool ASys::GetDocumentsDirectory(char* szDocumentDir, int nSize)
{
	const char* str = "/sdcard/doc";

	if(nSize <= strlen(str) + 1)
		return false;

	strcpy(szDocumentDir, str);

	return true;
}

bool ASys::GetLibraryDirectory(char* szLibraryDir, int nSize)
{
	strcpy(szLibraryDir, "");
	return true;
}

bool ASys::GetTmpDirectory(char* szTmpDir, int nSize)
{
	strcpy(szTmpDir, "");
	return true;
}

bool ASys::GetFilesInDirectory(std::vector<AString>& arrFiles, const char* szDir)
{
    glob_t globbuf;
    struct stat fileinfo;
    AString path(szDir);
    if( path[path.GetLength()-1] == '/')
    {
        path += "*";
    }
    else
    {
        path += "/*";
    }
    int ret = glob((const char*)path,GLOB_NOSORT,NULL,&globbuf);
    if( ret != 0)
    {
        if( ret == GLOB_NOMATCH )
        {
            return true;
        }
        
        return false;
    }

    path = szDir;
    if( path[path.GetLength()-1] == '/')
    {
        path += ".*";
    }
    else
    {
        path += "/.*";
    }
    
    ret = glob((const char*)path,GLOB_APPEND,NULL,&globbuf);
    if( ret != 0)
    {
        if( ret == GLOB_NOMATCH )
        {
            return true;
        }
        
        return false;
    }
    
    for (int i = 0; i < globbuf.gl_pathc; ++i)
    {
        ret = lstat(globbuf.gl_pathv[i],&fileinfo);
        if( 1 == S_ISDIR(fileinfo.st_mode))
            continue;
        arrFiles.push_back(globbuf.gl_pathv[i]);
    }

    
    return true;
}

void ASys::OutputDebug(const char* format, ...)
{
	char str[1024];

	va_list va;
	va_start( va, format );
	vsprintf( str, format, va );
	va_end( va );

	strcat(str, "\n");

	__android_log_print(ANDROID_LOG_INFO, "Angelica", "%s", str);
}

bool ASys::DeleteDirectory(const char* szDir)
{
	if(!ASys::IsFileExist(szDir))
		return true;
        
    rmdir( szDir);
	return false;
}

auint64 ASys::GetFreeDiskSpaceSize()
{
	/*
	JNIWrapper jni;
	JNIEnv* pJNIEnv = jni.GetEnv();
	jclass classJNIActivity = pJNIEnv->GetObjectClass(g_JNIActivityObject);
	jmethodID methodGetAvailSDCardSize = pJNIEnv->GetStaticMethodID(classJNIActivity, "getSDCardAvailSize", "()J");
	aint64 freeSpace = pJNIEnv->CallStaticLongMethod(classJNIActivity,methodGetAvailSDCardSize);
	//LOGI("ASys::GetFreeDiskSpaceSize: %lld", freeSpace);
	return auint64(freeSpace);
	*/
	return 0;
}

int parseLine(char* line) {
	// This assumes that a digit will be found and the line ends in " Kb".
	int i = strlen(line);
	const char* p = line;
	while (*p <'0' || *p > '9') p++;
	line[i - 3] = '\0';
	i = atoi(p);
	return i;
}

auint64 ASys::GetVirtualMemoryUsedSize()
{
	FILE* file = fopen("/proc/self/status", "r");
	auint64 result = 0;
	char line[128];

	while (fgets(line, 128, file) != NULL) {
		if (strncmp(line, "VmSize:", 7) == 0) {
			result = (auint64)parseLine(line);
			break;
		}
	}
	fclose(file);
	return result;
}

auint64 ASys::GetPhysMemoryUsedSize()
{
	FILE* file = fopen("/proc/self/status", "r");
	auint64 result = 0;
	char line[128];

	while (fgets(line, 128, file) != NULL) {
		if (strncmp(line, "VmRSS:", 6) == 0) {
			result = (auint64)parseLine(line);
			break;
		}
	}
	fclose(file);
	return result;
}

#endif //A_PLATFORM_ANDROID
