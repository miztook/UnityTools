extern "C"
{
#include "packfunc_export.h"
}

#include "AFI.h"
#include "AFilePackMan.h"
#include "AFilePackage.h"
#include "AFilePackGame.h"
#include "ASys.h"
#include "FileOperate.h"
#include "elementpckdir.h"
#include "CMd5Hash.h"
#include <errno.h>

static bool g_bPackInited = false;
static const unsigned char g_zFileHead[4] = { 'X', 0xaf, 'Z', 0 };

char g_CalcPackFileMd5[64];
char g_CalcFileMd5[64];
char g_CalcMemMd5[64];

HAPI bool PackInitialize(bool bCreate)
{
	if (g_bPackInited)
	{
		if (!bCreate)
			return true;
		else
			PackFinalize(true);
	}

	const char* szBaseDir = af_GetBaseDir();
	const char* szLibraryDir = af_GetLibraryDir();
	ASSERT(strlen(szBaseDir) > 0 && strlen(szLibraryDir) > 0);

	int PackFileNum = sizeof(g_szPckDir) / sizeof(g_szPckDir[0]);
	for (int i = 0; i < PackFileNum; i++)
	{
		char szPckFile[MAX_PATH];
		sprintf(szPckFile, "%s/%s.pck", (const char*)szBaseDir, g_szPckDir[i][1]);
		g_AFilePackMan.OpenFilePackageInGame(szPckFile, g_szPckDir[i][0]);

		sprintf(szPckFile, "%s/%s.pck", (const char*)szLibraryDir, g_szPckDir[i][1]);
		FileOperate::MakeDir(szPckFile, strlen(szPckFile));

		ASys::ChangeFileAttributes(szPckFile, S_IRWXU);
		if (!g_AUpdateFilePackMan.OpenFilePackage(szPckFile, g_szPckDir[i][0]))
		{
			bool bCreateSucceed = false;

			bCreateSucceed = g_AUpdateFilePackMan.CreateFilePackage(szPckFile, g_szPckDir[i][0]);
			if (!bCreateSucceed)
			{
				g_AUpdateFilePackMan.CloseAllPackages();
				return false;
			}
		}
	}

	g_bPackInited = true;
	return true;
}

HAPI void PackFinalize(bool bForce)
{
	if (g_bPackInited || bForce)
	{
		g_AFilePackMan.CloseAllPackages();
		g_AUpdateFilePackMan.CloseAllPackages();
		g_bPackInited = false;
	}
}

HAPI void FlushWritePack()
{
	if (g_bPackInited)
	{
		g_AUpdateFilePackMan.FlushAllPackages();
	}
}

HAPI bool SaveAndOpenUpdatePack()
{
	if (g_bPackInited)
	{
		g_AUpdateFilePackMan.CloseAllPackages();

		const char* szLibraryDir = af_GetLibraryDir();
		ASSERT(strlen(szLibraryDir) > 0);

		int PackFileNum = sizeof(g_szPckDir) / sizeof(g_szPckDir[0]);
		for (int i = 0; i < PackFileNum; i++)
		{
			char szPckFile[MAX_PATH];

			sprintf(szPckFile, "%s/%s.pck", (const char*)szLibraryDir, g_szPckDir[i][1]);
			FileOperate::MakeDir(szPckFile, strlen(szPckFile));

			ASys::ChangeFileAttributes(szPckFile, S_IRWXU);
			if (!g_AUpdateFilePackMan.OpenFilePackage(szPckFile, g_szPckDir[i][0]))
			{
				return false;
			}
		}
	}
	return true;
}

HAPI bool IsFileInPack(const char* filename)
{
	int k = 0;
	while (filename[k] == '.' && filename[k + 1] == '/')
		k += 2;

	AFilePackage* pPack1 = (AFilePackage*)g_AUpdateFilePackMan.GetFilePck(filename + k);
	if (pPack1)
		return true;

	AFilePackGame *pPack = (AFilePackGame*)g_AFilePackMan.GetFilePck(filename + k);
	return (pPack != NULL);
}

HAPI bool AddCompressedDataToPack(const char* filename, const unsigned char* pData, int dataSize)
{
	if (pData == NULL || dataSize < 4 + sizeof(g_zFileHead))
		return false;
	if (memcmp(pData, g_zFileHead, sizeof(g_zFileHead)) != 0)
		return false;
	pData += (int)sizeof(g_zFileHead);
	dataSize -= (int)sizeof(g_zFileHead);

	int k = 0;
	while (filename[k] == '.'&& filename[k + 1] == '/')
		k += 2;

	int p = 0;
	AFilePackage *pPack = (AFilePackage*)g_AUpdateFilePackMan.GetFilePck(filename + k);
	if (pPack != NULL)
	{
		auint32 frealsize = 0;
		unsigned char *pSize = (unsigned char *)pData;
		frealsize = *((auint32 *)pData);

		AFilePackage::FILEENTRY entry;
		bool b;
		if (pPack->GetFileEntry(filename + k, &entry))
			b = pPack->ReplaceFileCompressed(filename + k, (abyte*)(pData + 4), frealsize, dataSize - 4);
		else
			b = pPack->AppendFileCompressed(filename + k, (abyte*)(pData + 4), frealsize, dataSize - 4);

		return b;
	}
	return false;
}

HAPI bool UncompressToSepFile(const char* filename, const unsigned char* pData, int dataSize)
{
	int k = 0;
	while (filename[k] == '.' && filename[k + 1] == '/')
		k += 2;
	// check header
	if (pData == NULL || dataSize < sizeof(g_zFileHead) + 4)
		return false;
	if (memcmp(pData, g_zFileHead, sizeof(g_zFileHead)) != 0)
		return false;

	// read original size
	auint32* pOriginalFileLen = (auint32*)(pData + sizeof(g_zFileHead));
	auint32 originalFileLen = *(auint32*)pOriginalFileLen;
	const char* realfilename = filename + k;
	std::string strFile = af_GetLibraryDir();
	normalizeDirName(strFile);
	strFile = strFile + realfilename;

	// open file
	FileOperate::MakeDir(strFile.c_str(), strFile.length());
	ASys::ChangeFileAttributes(strFile.c_str(), S_IRWXU);

	FILE *fout = fopen(strFile.c_str(), "w+b");
	if (fout == NULL)
	{
		perror("perror says open failed");
		//		char* error = strerror(errno);
		//		printf("strerror says open failed: %s\n", strerror(errno)); // C4996
		//		printf("_strerror says open failed"); // C4996
		return false;
	}

	const auint32 blockSize = 4 * 1024 * 1024;
	// uncompress
	const unsigned char* pCompressedData = pData + sizeof(g_zFileHead) + 4;
	auint32 compressDataLen = dataSize - sizeof(g_zFileHead) - 4;
	bool retFlag = false;
	if (compressDataLen < originalFileLen)		// compressed data stored
	{
		unsigned char* buffer = new unsigned char[originalFileLen];
		auint32 uncompressLen = originalFileLen;
		if (0 == AFilePackage::Uncompress(pCompressedData, compressDataLen, buffer, &uncompressLen)
			&& uncompressLen == originalFileLen)
		{
			//fwrite(buffer, 1, originalFileLen, fout);

			auint32 nBlock = originalFileLen / blockSize;
			auint32 nLeft = originalFileLen % blockSize;

			const unsigned char* p = buffer;
			for (auint32 i = 0; i < nBlock; ++i)
			{
				fwrite(p, 1, blockSize, fout);
				p += blockSize;
			}

			if (nLeft > 0)
				fwrite(p, 1, nLeft, fout);

			retFlag = true;
		}
		delete[] buffer;
	}
	else		// original data stored
	{
		auint32 nBlock = originalFileLen / blockSize;
		auint32 nLeft = originalFileLen % blockSize;

		const unsigned char* p = pCompressedData;
		for (auint32 i = 0; i < nBlock; ++i)
		{
			fwrite(p, 1, blockSize, fout);
			p += blockSize;
		}

		if (nLeft > 0)
			fwrite(p, 1, nLeft, fout);

		//fwrite(pCompressedData, 1, originalFileLen, fout);
		retFlag = true;
	}

	fclose(fout);
	return retFlag;
}

HAPI const char* CalcPackFileMd5(const char* filename)
{
	if (strlen(filename) == 0)
	{
		g_CalcPackFileMd5[0] = 0;
		return NULL;
	}

	int k = 0;
	while (filename[k] == '.' && filename[k + 1] == '/')
		k += 2;

	//int p=0;
	AFilePackage* fPack1 = (AFilePackage*)g_AUpdateFilePackMan.GetFilePck(filename + k);
	if (fPack1 != NULL)
	{
		AFilePackage::FILEENTRY entry;

		if (fPack1->GetFileEntry(filename + k, &entry))
		{
			unsigned long size = entry.dwCompressedLength;
			unsigned char *dataBuffer = new unsigned char[size + 4 + sizeof(g_zFileHead)];
			memcpy(dataBuffer, g_zFileHead, sizeof(g_zFileHead));
			unsigned char *fbuf = dataBuffer + sizeof(g_zFileHead);

			*((auint32 *)fbuf) = entry.dwLength;

			auint32 realSize = entry.dwCompressedLength;
			fPack1->ReadCompressedFile(entry, fbuf + 4, &realSize);
			ASSERT(realSize == size);

			// calc md5
			//CMd5Hash::DigestString(dataBuffer, size + 4 + sizeof(g_zFileHead), g_CalcPackFileMd5, 64);
			FileOperate::CalcMemMd5(dataBuffer, size + 4 + sizeof(g_zFileHead), g_CalcPackFileMd5);

			delete[] dataBuffer;
			return g_CalcPackFileMd5;
		}
	}

	AFilePackGame* fPack = (AFilePackGame*)g_AFilePackMan.GetFilePck(filename + k);
	if (fPack != NULL)
	{
		AFilePackGame::FILEENTRY* entry = fPack->GetFileEntry(filename + k);

		if (entry)
		{
			unsigned long size = entry->dwCompressedLength;

			abyte *dataBuffer = (abyte*)malloc(size + 4 + sizeof(g_zFileHead));
			memcpy(dataBuffer, g_zFileHead, sizeof(g_zFileHead));
			unsigned char *fbuf = dataBuffer + sizeof(g_zFileHead);

			*((auint32 *)fbuf) = entry->dwLength;

			auint32 realSize = entry->dwCompressedLength;
			fPack->ReadCompressedFile(*entry, fbuf + 4, &realSize);
			ASSERT(realSize == size);

			// calc md5
			//CMd5Hash::DigestString(dataBuffer, size + 4 + sizeof(g_zFileHead), g_CalcPackFileMd5, 64);
			FileOperate::CalcMemMd5(dataBuffer, size + 4 + sizeof(g_zFileHead), g_CalcPackFileMd5);

			free(dataBuffer);
			return g_CalcPackFileMd5;
		}
	}

	g_CalcPackFileMd5[0] = 0;
	return NULL;
}

HAPI const char* CalcFileMd5(const char* filename)
{
	if (FileOperate::CalcFileMd5(filename, g_CalcFileMd5))
		return g_CalcFileMd5;

	g_CalcFileMd5[0] = 0;
	return NULL;
}

HAPI const char* CalcMemMd5(const unsigned char* pData, int dataSize)
{
	if (FileOperate::CalcMemMd5(pData, dataSize, g_CalcMemMd5))
		return g_CalcMemMd5;

	g_CalcMemMd5[0] = 0;
	return NULL;
}

//创建压缩文件，把文件原内容加 g_zFileHead(4字节) + 原length（4字节) + zlibCompress(内容)
HAPI bool MakeCompressedFile(const char* srcFileName, const char* destFileName, bool bNoCompress)
{
	FILE* srcFile = fopen(srcFileName, "rb");
	if (!srcFile)
		return false;
	FILE* destFile = fopen(destFileName, "wb");
	if (!destFile)
	{
		fclose(srcFile);
		return false;
	}

	bool ret = true;

	auint32 nSrcSize = ASys::GetFileSize(srcFileName);
	auint32 nDestBufferSize = (auint32)(nSrcSize * 1.1f) + 12;		//zlib compress2 要求
	unsigned char* pSrcBuffer = new unsigned char[nSrcSize];
	unsigned char* pDestBuffer = new unsigned char[nDestBufferSize + sizeof(g_zFileHead) + 4];
	memset(pDestBuffer, 0, nDestBufferSize + sizeof(g_zFileHead) + 4);

	fread(pSrcBuffer, 1, nSrcSize, srcFile);
	fclose(srcFile);

	memcpy(pDestBuffer, g_zFileHead, sizeof(g_zFileHead));
	unsigned char *fbuf = pDestBuffer + sizeof(g_zFileHead);
	*((auint32 *)fbuf) = nSrcSize;

	auint32 compressedLength = nSrcSize;
	int nRetCode;
	if (bNoCompress)	  //不压缩
	{
		nRetCode = -1;
	}
	else
	{
		nRetCode = AFilePackage::Compress(pSrcBuffer, nSrcSize, pDestBuffer + sizeof(g_zFileHead) + 4, &compressedLength);
	}

	if (-2 == nRetCode)
		ret = false;

	if (0 != nRetCode || compressedLength == nSrcSize)			//这种情况压缩后大小等同于原大小,不压缩，用原文件内容
	{
		compressedLength = nSrcSize;
		memcpy(pDestBuffer + sizeof(g_zFileHead) + 4, pSrcBuffer, nSrcSize);
	}

	//check
	/*
	if (compressedLength < nSrcSize)
	{
		unsigned char* pDest = pDestBuffer + sizeof(g_zFileHead) + 4;
		auint32* pOriginalFileLen = (auint32*)(pDestBuffer + sizeof(g_zFileHead));
		auint32 originalFileLen = *(auint32*)pOriginalFileLen;
		unsigned char* pOrig = new unsigned char[originalFileLen];
		auint32 length = originalFileLen;
		AFilePackage::Uncompress(pDest, compressedLength, pOrig, &length);

		if (length != nSrcSize)
		{
			ASSERT(false);
		}

		if (memcmp(pOrig, pSrcBuffer, nSrcSize) != 0)
		{
			ASSERT(false);
		}

		delete[] pOrig;
	}
	*/

	auint32 nDestSize = sizeof(g_zFileHead) + 4 + compressedLength;
	fwrite(pDestBuffer, 1, nDestSize, destFile);						//写入压缩后内容

	fclose(destFile);

	delete[] pDestBuffer;
	delete[] pSrcBuffer;

	return ret;
}