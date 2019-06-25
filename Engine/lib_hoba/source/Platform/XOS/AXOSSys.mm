#include "ASys.h"

#include "compileconfig.h"
#ifdef A_PLATFORM_XOS

#include <glob.h>
#include <sys/utsname.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <vector>
#include "Reachability.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>


bool ASys::IOSGetCurLanguage(char* szLang, int nSize)
{
	NSArray* languages = [NSLocale preferredLanguages];    
    NSString* currentLanguage = [languages objectAtIndex:0];
	const char* str = [currentLanguage UTF8String];
	if(nSize <= (int)strlen(str) + 1)
		return false;

	strcpy(szLang, str);
	return true;
}

bool ASys::GetDocumentsDirectory(char* szDocumentDir, int nSize)
{
	NSString* homePath = NSHomeDirectory();
    NSString* docDir = @"/Documents";
    NSString* docDirectory = [homePath stringByAppendingString:docDir];

	const char* str = [docDirectory UTF8String];
	if(nSize <= (int)strlen(str) + 1)
		return false;

	strcpy(szDocumentDir, str);

	return true;
}

bool ASys::GetLibraryDirectory(char* szLibraryDir, int nSize)
{
	NSString* homePath = NSHomeDirectory();
    NSString* libDir = @"/Library/Caches/updateres";
    NSString* libDirectory = [homePath stringByAppendingString:libDir];

	const char* str = [libDirectory UTF8String];
	if(nSize <= (int)strlen(str) + 1)
		return false;

	strcpy(szLibraryDir, str);

	return true;
}

bool ASys::GetTmpDirectory(char* szTmpDir, int nSize)
{
	NSString* homePath = NSHomeDirectory();
    NSString* tmpDir = @"/tmp";
    NSString* tmpDirectory = [homePath stringByAppendingString:tmpDir];

	const char* str = [tmpDirectory UTF8String];
	if(nSize <= (int)strlen(str) + 1)
		return false;

	strcpy(szTmpDir, str);

	return true;
}

bool ASys::GetFilesInDirectory(std::vector<std::string>& arrFiles, const char* szDir)
{
    glob_t globbuf;
    struct stat fileinfo;
    std::string path(szDir);
    if( path[path.length()-1] == '/')
    {
        path += "*";
    }
    else
    {
        path += "/*";
    }
    int ret = glob(path.c_str(),GLOB_NOSORT,NULL,&globbuf);
    if( ret != 0)
    {
        if( ret == GLOB_NOMATCH )
        {
            return true;
        }
        
        return false;
    }

    path = szDir;
    if( path[path.length()-1] == '/')
    {
        path += ".*";
    }
    else
    {
        path += "/.*";
    }
    
    ret = glob(path.c_str(),GLOB_APPEND,NULL,&globbuf);
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

NSString* CharToNString( const char* szString)
{
    int strlenght = strlen(szString);
    NSString* outstring = [[NSString alloc] initWithBytes:szString length:strlenght encoding:NSUTF8StringEncoding];
    
    return outstring;
}

void ASys::OutputDebug(const char* format, ...)
{
    char str[1024];
        
    va_list va;
    va_start( va, format );
    vsprintf( str, format, va );
    va_end( va );
        
    strcat(str, "\n");
        
    NSString* output = CharToNString(str);
    NSLog(output);
    //[output release];
}

bool ASys::DeleteDirectory(const char* szDir)
{
	if(!ASys::IsFileExist(szDir))
		return true;
    int strLength = strlen(szDir);
    
    if( szDir[strLength-2] == '.' && szDir[strLength-1] == '/')
        return false;
    
    glob_t globbuf;
    struct stat fileinfo;
    std::string path(szDir);
    
    if( path[path.length()-1] == '/')
    {
        path += "*";
    }
    else
    {
        path += "/*";
    }
    int ret = glob(path.c_str(),GLOB_NOSORT,NULL,&globbuf);
    if( ret != 0)
    {
        if( ret == GLOB_NOMATCH )
        {
            rmdir( szDir);
            return true;
        }
        
        return false;
    }
    
    path = szDir;
    if( path[path.length()-1] == '/')
    {
        path += ".*";
    }
    else
    {
        path += "/.*";
    }
    
    ret = glob(path.c_str(),GLOB_APPEND,NULL,&globbuf);
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
        {
            if( strstr( globbuf.gl_pathv[i],".*") != NULL )
                continue;
            
            if( strstr( globbuf.gl_pathv[i],"./") != NULL )
                continue;
            
            if( strstr( globbuf.gl_pathv[i],"/.") != NULL )
                continue;
            
            DeleteDirectory(globbuf.gl_pathv[i]);
        }
        else
        {
            ChangeFileAttributes(globbuf.gl_pathv[i], S_IRWXU);
            DeleteFile(globbuf.gl_pathv[i]);
        }
    }
    if (rmdir( szDir) == 0)
        return true;

	return false;
}

auint64 ASys::GetFreeDiskSpaceSize()
{
    auint64 totalFreeSpace = 0;
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    if (dictionary) {
        totalFreeSpace = (auint64)[[dictionary objectForKey:NSFileSystemFreeSize] longLongValue];
    }

    return totalFreeSpace;
}

auint64 ASys::GetVirtualMemoryUsedSize()
{
	uint64_t memoryUsageInByte = 0;
    struct task_basic_info taskBasicInfo;
    mach_msg_type_number_t size = sizeof(taskBasicInfo);
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t) &taskBasicInfo, &size);
    
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (uint64_t) taskBasicInfo.resident_size;
    }
    return memoryUsageInByte;
}

auint64 ASys::GetPhysMemoryUsedSize()
{
    uint64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (uint64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte;
}

#endif	//	A_PLATFORM_XOS
