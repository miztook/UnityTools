#include "fileImageTest.h"
#include <stdio.h>

#include "ATypes.h"

void FileImageTest()
{
	{
		AFileImage* pFile = FileImage_Open("lua\\Lplus.lua", true);
		printf("file len: %d\n", FileImage_GetFileLength(pFile));
		FileImage_Close(pFile);
	}

	{
		AFileImage* pFile = FileImage_Open("Maps\\GreenVillage.navmesh", false);
		printf("file len: %d\n", FileImage_GetFileLength(pFile));
		FileImage_Close(pFile);
	}

	ASSERT(FileImage_IsExist("Maps\\GreenVillage.navmesh"));
}
