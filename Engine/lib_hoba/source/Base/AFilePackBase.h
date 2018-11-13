#ifndef _AFILEPACKBASE_H_
#define _AFILEPACKBASE_H_

#include "ATypes.h"
#include <cstdio>

 ///////////////////////////////////////////////////////////////////////////
 //
 //	Define and Macro
 //
 ///////////////////////////////////////////////////////////////////////////

#define MAX_FILE_PACKAGE	0x7fffff00U

//	#define AFPCK_VERSION	0x00010001
//	#define AFPCK_VERSION	0x00010002	//	Add compression
//  #define AFPCK_VERSION		0x00010003	//	The final release version on June 2002
//	#define AFPCK_VERSION		0x00020001	//	The version for element before Oct 2005
//#define AFPCK_VERSION		0x00020002	//	The version with safe header
#define AFPCK_VERSION		0x00020003	//	The version with esEngine

#define AFPCK_COPYRIGHT_TAG "Angelica File Package, Perfect World Co. Ltd. 2002~2008. All Rights Reserved. "

class AFilePackBase
{
public:		//	Types

	//	Package header flags
	enum
	{
		PACKFLAG_ENCRYPT = 0x80000000,
	};

	class CPackageFile
	{
	private:
		char		m_szPath[MAX_PATH];
		char		m_szPath2[MAX_PATH];
		char		m_szMode[32];

		FILE *		m_pFile1;
		FILE *		m_pFile2;

		aint64		m_size1;
		aint64		m_size2;

		aint64		m_filePos;

	public:
		inline auint32 GetPackageFileSize() { return (auint32)(m_size1 + m_size2); }

	public:
		CPackageFile();
		~CPackageFile();
		bool Open(const char * szFileName, const char * szMode);
		bool Phase2Open(auint32 dwOffset);
		bool Close();
		bool Flush();

		size_t read(void *buffer, size_t size, size_t count);
		size_t write(const void *buffer, size_t size, size_t count);
		void seek(aint64 offset, int origin);
		auint32 tell();
		void SetPackageFileSize(auint32 dwFileSize);
	};

public:

	AFilePackBase() {}
	virtual ~AFilePackBase() {}

	virtual bool Close() { return true; }
	virtual bool Flush() { return true; }
	virtual const char* GetFolder() const { return ""; }
	virtual bool IsFileExist(const char* szFileName) const { return false; }

	//	Open a shared file
	virtual void* OpenSharedFile(const char* szFileName, abyte** ppFileBuf, auint32* pdwFileLen) { return 0; }
	//	Close a shared file
	virtual void CloseSharedFile(void* dwFileHandle) {}
};

#endif	//	_AFILEPACKBASE_H_
