#ifndef _AFILEPACKMAN_H_
#define _AFILEPACKMAN_H_

#include "AFilePackBase.h"
#include <vector>

///////////////////////////////////////////////////////////////////////////
//
//	Define and Macro
//
///////////////////////////////////////////////////////////////////////////

//	#define AFPCK_VERSION	0x00010001
//	#define AFPCK_VERSION	0x00010002	//	Add compression
//  #define AFPCK_VERSION		0x00010003	//	The final release version on June 2002
//	#define AFPCK_VERSION		0x00020001	//	The version for element before Oct 2005
//#define AFPCK_VERSION		0x00020002	//	The version with safe header

///////////////////////////////////////////////////////////////////////////
//
//	Types and Global variables
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Declare of Global functions
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Class AFilePackMan
//
///////////////////////////////////////////////////////////////////////////

class AFilePackMan
{
public:

	AFilePackMan();
	~AFilePackMan();

	// Set algorithm id
	bool SetAlgorithmID(int id);

	// open an exist file package
	bool OpenFilePackage(const char* szPckFile, bool bCreateNew = false, bool bEncrypt = false);
	bool OpenFilePackage(const char* szPckFile, const char* szFolder, bool bEncrypt = false);
	bool OpenFilePackageInGame(const char* szPckFile, bool bEncrypt = false);
	bool OpenFilePackageInGame(const char* szPckFile, const char* szFolder, bool bEncrypt = false);
	bool CreateFilePackage(const char* szPckFile, const char* szFolder, bool bEncrypt = false);

	// close an opening file package
	bool CloseFilePackage(AFilePackBase* pFilePck);
	// close all opening file packages
	bool CloseAllPackages();
	bool FlushAllPackages();

	// get the number of file packages
	int GetNumPackages() { return (int)m_FilePcks.size(); }
	// get the specified file package
	AFilePackBase* GetFilePck(int index) { return m_FilePcks[index]; }
	// get the package using a path
	AFilePackBase* GetFilePck(const char * szPath);

private:

	std::vector<AFilePackBase*>	m_FilePcks;
};

extern AFilePackMan		g_AFilePackMan;
extern AFilePackMan     g_AUpdateFilePackMan;

#endif	//	_AFILEPACKMAN_H_
