﻿#include "AFilePackBase.h"
#include "ASys.h"
#include "AFI.h"
#include "AFramework.h"
#include "AAssist.h"

extern int	AFPCK_GUARDBYTE0;
extern int	AFPCK_GUARDBYTE1;
extern int	AFPCK_MASKDWORD;
extern int	AFPCK_CHECKMASK;

static const size_t NET_DISK_RW_MAX_SIZE = 1024 * 1024;	//
static const auint32 IO_TIMEOUT_ERROR_COUNT = 120000;		//

size_t _FileWrite(const void* buffer, const size_t num_byte, FILE* stream)
{
	if (!stream || !buffer)
	{
		//	g_pAFramework->DevPrintf(("Write Param ERROR! pBuffer:%d, fp:%d, FileSize:%d\n\n", (void*)buffer, (void*)stream, num_byte));
		return 0;
	}

	const long lBeginOffset = ftell(stream);
	if (lBeginOffset == -1L)
	{
		g_pAFramework->DevPrintf(("ftell ERROR, check whether devices support file seeking!!\n\n"));
		return 0;
	}

	const unsigned char* pBuf = (unsigned char*)buffer;
	size_t sizeMaxOnceWrite = NET_DISK_RW_MAX_SIZE;
	auint32 dwStartTimeCnt = ASys::GetMilliSecond();
	auint32 dwOffset = 0;
	while (dwOffset < num_byte)
	{
		auint32 dwWrite = min2(num_byte - dwOffset, sizeMaxOnceWrite);
		auint32 dwActuallyWrite = fwrite(pBuf + dwOffset, 1, dwWrite, stream);

		if (dwActuallyWrite == dwWrite)
		{
			dwOffset += dwWrite;
			dwStartTimeCnt = ASys::GetMilliSecond();
		}
		else
		{
			if ((int(ASys::GetMilliSecond() - dwStartTimeCnt)) > IO_TIMEOUT_ERROR_COUNT)
			{
				// ≥¨π?÷∏???±o‰√a”––￥??≥…π?
				g_pAFramework->DevPrintf("Write ERROR: SIZE:%d, OFFSET:%d, TRY_WRITE:%d\n\n", num_byte, dwOffset, dwWrite);
				return (size_t)dwOffset;
			}

			// μ?’?“a￥??ó￥?–￥??…???
			if (sizeMaxOnceWrite >= 2)
			{
				sizeMaxOnceWrite >>= 1;
			}

			// Ω′??o?±í??πè?a
			if (fseek(stream, lBeginOffset + dwOffset, SEEK_SET))
			{
				g_pAFramework->DevPrintf(("fseek ERROR, check whether devices support file seeking!!\n\n"));
				return (size_t)dwOffset;
			}
		}
	}

	return (size_t)dwOffset;
}

size_t _FileRead(void* buffer, const size_t num_byte, FILE* stream)
{
	if (!stream || !buffer)
	{
		//	g_pAFramework->DevPrintf(("Read Param ERROR! pBuffer:%d, fp:%d, FileSize:%d\n\n", (void*)buffer, (void*)stream, num_byte));
		return 0;
	}

	const long lBeginOffset = ftell(stream);
	if (lBeginOffset == -1L)
	{
		g_pAFramework->DevPrintf(("ftell ERROR, check whether devices support file seeking!!\n\n"));
		return 0;
	}

	unsigned char* pBuf = (unsigned char*)buffer;
	size_t sizeMaxOnceRead = NET_DISK_RW_MAX_SIZE;
	auint32 dwStartTimeCnt = ASys::GetMilliSecond();
	auint32 dwOffset = 0;
	while (dwOffset < num_byte)
	{
		auint32 dwRead = min2(num_byte - dwOffset, sizeMaxOnceRead);
		auint32 dwActuallyRead = fread(pBuf + dwOffset, 1, dwRead, stream);

		if (dwActuallyRead == dwRead)
		{
			dwOffset += dwRead;
			dwStartTimeCnt = ASys::GetMilliSecond();
		}
		else
		{
			if ((int(ASys::GetMilliSecond() - dwStartTimeCnt)) > IO_TIMEOUT_ERROR_COUNT)
			{
				g_pAFramework->DevPrintf("Read ERROR: SIZE:%d, OFFSET:%d, TRY_READ:%d\n\n", num_byte, dwOffset, dwRead);
				return (size_t)dwOffset;
			}

			if (sizeMaxOnceRead >= 2)
			{
				sizeMaxOnceRead >>= 1;
			}

			if (fseek(stream, lBeginOffset + dwOffset, SEEK_SET))
			{
				g_pAFramework->DevPrintf(("fseek ERROR, check whether devices support file seeking!!\n\n"));
				return (size_t)dwOffset;
			}
		}
	}

	return (size_t)dwOffset;
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement of AFilePackBase
//
///////////////////////////////////////////////////////////////////////////

AFilePackBase::CPackageFile::CPackageFile()
{
	m_pFile1 = NULL;
	m_pFile2 = NULL;

	m_size1 = 0;
	m_size2 = 0;

	m_filePos = 0;
}

AFilePackBase::CPackageFile::~CPackageFile()
{
}

bool AFilePackBase::CPackageFile::Open(const char * szFileName, const char * szMode)
{
	Close();

	m_pFile1 = fopen(szFileName, szMode);
	if (NULL == m_pFile1)
	{
		return false;
	}

	fseek(m_pFile1, 0, SEEK_END);
	m_size1 = ftell(m_pFile1);
	fseek(m_pFile1, 0, SEEK_SET);

	m_filePos = 0;
	strncpy(m_szPath, szFileName, MAX_PATH);
	strncpy(m_szMode, szMode, 32);

	strcpy(m_szPath2, m_szPath);
	af_ChangeFileExt(m_szPath2, MAX_PATH, ".pkx");
	return true;
}

bool AFilePackBase::CPackageFile::Phase2Open(auint32 dwOffset)
{
	if (dwOffset >= MAX_FILE_PACKAGE)
	{
		// we need the second file now;
		m_pFile2 = fopen(m_szPath2, m_szMode);
		if (NULL == m_pFile2)
		{
			if (ASys::StrCmpNoCase(m_szMode, "r+b") == 0 && !af_IsFileExist(m_szPath2))
			{
				// it is the first time we access the second file
				m_pFile2 = fopen(m_szPath2, "wb+");
				if (NULL == m_pFile2)
					return false;
			}
			else
				return false;
		}

		fseek(m_pFile2, 0, SEEK_END);
		m_size2 = ftell(m_pFile2);
		fseek(m_pFile2, 0, SEEK_SET);
	}

	return true;
}

bool AFilePackBase::CPackageFile::Close()
{
	if (m_pFile2)
	{
		fclose(m_pFile2);
		m_pFile2 = NULL;
	}

	if (m_pFile1)
	{
		fclose(m_pFile1);
		m_pFile1 = NULL;
	}

	m_size1 = 0;
	m_size2 = 0;
	m_filePos = 0;

	return true;
}

bool AFilePackBase::CPackageFile::Flush()
{
	if (m_pFile2)
	{
		fflush(m_pFile2);
	}
	if (m_pFile1)
	{
		fflush(m_pFile1);
	}

	return true;
}

size_t AFilePackBase::CPackageFile::read(void *buffer, size_t size, size_t count)
{
	size_t size_to_read = size * count;
	aint64 new_pos = m_filePos + size_to_read;

	if (new_pos <= MAX_FILE_PACKAGE)
	{
		// case 1: completely in file 1
		size_t readsize = _FileRead(buffer, size_to_read, m_pFile1);
		m_filePos += readsize;

		//	Bug fixed by dyx at 2013-4-24: if m_filePos is moved to MAX_FILE_PACKAGE after last reading operation at it happens,
		//	next reading operation will go to case 3 other than case 2, so we should reset m_pFile2's file pointer to
		//	ensure next reading operation to start at correct position.
		if (m_filePos == MAX_FILE_PACKAGE && m_pFile2)
			fseek(m_pFile2, 0, SEEK_SET);

		return readsize;
	}
	else if (m_filePos < MAX_FILE_PACKAGE)
	{
		// case 2: partial in file1 and partial in file 2
		size_t size_to_read1 = (size_t)(MAX_FILE_PACKAGE - m_filePos);
		size_t size_to_read2 = (size_t)(size_to_read - size_to_read1);

		// read from file1
		size_t readsize = _FileRead(buffer, size_to_read1, m_pFile1);
		if (readsize != size_to_read1)
		{
			m_filePos += readsize;
			return readsize;
		}

		if (m_pFile2)
		{
			// read from file2
			fseek(m_pFile2, 0, SEEK_SET);
			readsize += _FileRead((unsigned char*)buffer + size_to_read1, size_to_read2, m_pFile2);
		}

		m_filePos += readsize;
		return readsize;
	}
	else
	{
		// case 3: completely in file 2
		size_t readsize = _FileRead(buffer, size_to_read, m_pFile2);
		m_filePos += readsize;
		return readsize;
	}

	return 0;
}

size_t AFilePackBase::CPackageFile::write(const void *buffer, size_t size, size_t count)
{
	size_t size_to_write = size * count;
	aint64 new_size = m_filePos + size_to_write;

	if (new_size <= MAX_FILE_PACKAGE)
	{
		// case 1: completely in file 1
		size_t writesize = _FileWrite(buffer, size_to_write, m_pFile1);
		m_filePos += writesize;
		if (m_filePos > m_size1)
			m_size1 = m_filePos;
		return writesize;
	}
	else if (m_filePos < MAX_FILE_PACKAGE)
	{
		// case 2: partial in file1 and partial in file 2
		size_t size_to_write1 = MAX_FILE_PACKAGE - (aint32)m_filePos;
		size_t size_to_write2 = size_to_write - size_to_write1;

		// write to file1
		size_t writesize1 = _FileWrite(buffer, size_to_write1, m_pFile1);
		m_filePos += writesize1;
		if (m_filePos > m_size1)
			m_size1 = m_filePos;

		// By MSDN:
		// fwrite returns the number of full items actually written, which may be less than count if an error occurs.
		// Also, if an error occurs, the file-position indicator cannot be determined.
		if (writesize1 != size_to_write1)
		{
			fseek(m_pFile1, (long)m_filePos, SEEK_SET);
			return writesize1;
		}

		m_size1 = MAX_FILE_PACKAGE;

		if (!m_pFile2)
			Phase2Open(MAX_FILE_PACKAGE);

		// write to file2
		fseek(m_pFile2, 0, SEEK_SET);
		size_t writesize2 = _FileWrite((unsigned char*)buffer + size_to_write1, size_to_write2, m_pFile2);
		m_filePos += writesize2;
		if (m_filePos > m_size1 + m_size2)
			m_size2 = m_filePos - m_size1;
		return writesize1 + writesize2;
	}
	else
	{
		// case 3: completely in file 2

		//	Bug fixed by dyx at 2013-4-24: If last writing operation went to case 1,
		//	and m_filePos was moved to MAX_FILE_PACKAGE after writting at it happens. Then
		//	next writing operation will come to case 3 other than case 2, so we should check whether
		//	m_pFile2 has been existed or not.
		if (!m_pFile2)
		{
			Phase2Open(MAX_FILE_PACKAGE);
			fseek(m_pFile2, 0, SEEK_SET);
		}

		size_t writesize = _FileWrite(buffer, size_to_write, m_pFile2);
		m_filePos += writesize;
		if (m_filePos > m_size1 + m_size2)
			m_size2 = m_filePos - m_size1;
		return writesize;
	}

	return 0;
}

void AFilePackBase::CPackageFile::seek(aint64 offset, int origin)
{
	aint64 newpos = m_filePos;

	if (m_pFile2)
	{
		switch (origin)
		{
		case SEEK_SET:
			newpos = offset;
			break;

		case SEEK_CUR:
			newpos = m_filePos + offset;
			break;

		case SEEK_END:
			newpos = m_size1 + m_size2 + offset;
			break;
		}

		if (newpos < 0)
			newpos = 0;
		if (newpos > m_size1 + m_size2)
			newpos = m_size1 + m_size2;

		if (newpos < m_size1)
			fseek(m_pFile1, (long)newpos, SEEK_SET);
		else
			fseek(m_pFile2, (long)(newpos - m_size1), SEEK_SET);

		m_filePos = newpos;
	}
	else
	{
		fseek(m_pFile1, (long)offset, origin);
		m_filePos = ftell(m_pFile1);
	}

	return;
}

auint32 AFilePackBase::CPackageFile::tell()
{
	return (auint32)m_filePos;
}

void AFilePackBase::CPackageFile::SetPackageFileSize(auint32 dwFileSize)
{
	if (m_pFile2)
	{
		if (dwFileSize <= MAX_FILE_PACKAGE)
		{
			int fileHandle = ASys::Fileno(m_pFile1);
			ASys::SetFileSize(fileHandle, dwFileSize);
			m_size1 = dwFileSize;

			fclose(m_pFile2);
			m_pFile2 = NULL;
			remove(m_szPath2);
			m_size2 = 0;
		}
		else
		{
			int fileHandle = ASys::Fileno(m_pFile2);
			m_size2 = dwFileSize - MAX_FILE_PACKAGE;
			ASys::SetFileSize(fileHandle, (aint32)m_size2);
		}
	}
	else
	{
		int fileHandle = ASys::Fileno(m_pFile1);
		ASys::SetFileSize(fileHandle, dwFileSize);
		m_size1 = dwFileSize;
	}
}