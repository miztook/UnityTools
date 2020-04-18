#include "AFilePackMan.h"
#include "AFilePackGame.h"
#include "ASys.h"
#include "AFI.h"
#include "AFramework.h"
#include "AFilePackage.h"
#include "ATempMemBuffer.h"
#include "AAssist.h"

int	AFPCK_GUARDBYTE0 = 0xfdfdfeee;
int	AFPCK_GUARDBYTE1 = 0xf00dbeef;
int AFPCK_MASKDWORD = 0xa8937462;
int	AFPCK_CHECKMASK = 0x59374231;

AFilePackMan g_AFilePackMan;
AFilePackMan g_AUpdateFilePackMan;

AFilePackMan::AFilePackMan() : m_FilePcks()
{
}

AFilePackMan::~AFilePackMan()
{
	CloseAllPackages();
}

bool AFilePackMan::CreateFilePackage(const char * szPckFile, const char* szFolder)
{
	AFilePackage * pFilePackage = new AFilePackage;
	if (!pFilePackage->Open(szPckFile, szFolder, AFilePackage::CREATENEW))
	{
		delete pFilePackage;
		g_pAFramework->DevPrintf("AFilePackMan::CreateFilePackage(), Can not open package [%s]", szPckFile);
		return false;
	}

	m_FilePcks.push_back(pFilePackage);

	return true;
}

bool AFilePackMan::OpenFilePackage(const char * szPckFile, bool bCreateNew)
{
	AFilePackage * pFilePackage = new AFilePackage;
	if (!pFilePackage->Open(szPckFile, bCreateNew ? AFilePackage::CREATENEW : AFilePackage::OPENEXIST))
	{
		delete pFilePackage;
		g_pAFramework->DevPrintf("AFilePackMan::OpenFilePackage(), Can not open package [%s]", szPckFile);
		return false;
	}

	//g_pAFramework->DevPrintf("Package Opened [%s]", szPckFile);
	m_FilePcks.push_back(pFilePackage);

	return true;
}

bool AFilePackMan::OpenFilePackage(const char * szPckFile, const char* szFolder)
{
	if (ASys::GetFileSize(szPckFile) == 0)
	{
		g_pAFramework->DevPrintf("AFilePackMan::OpenFilePackage(), %s File size = 0 or not exist", szPckFile);
		return false;
	}

	AFilePackage * pFilePackage = new AFilePackage;
	if (!pFilePackage->Open(szPckFile, szFolder, AFilePackage::OPENEXIST))
	{
		delete pFilePackage;
		g_pAFramework->DevPrintf("AFilePackMan::OpenFilePackage(), Can not open package [%s]", szPckFile);
		return false;
	}

	//g_pAFramework->DevPrintf("Package Opened [%s]", szPckFile);
	m_FilePcks.push_back(pFilePackage);

	return true;
}

bool AFilePackMan::OpenFilePackageInGame(const char* szPckFile)
{
	AFilePackGame* pFilePackage = new AFilePackGame;
	if (!pFilePackage->Open(szPckFile, AFilePackGame::OPENEXIST))
	{
		delete pFilePackage;
		g_pAFramework->DevPrintf("AFilePackMan::OpenFilePackageInGame(), Can not open package [%s]", szPckFile);
		return false;
	}

	//g_pAFramework->DevPrintf("Package Opened [%s]", szPckFile);
	m_FilePcks.push_back(pFilePackage);

	return true;
}

bool AFilePackMan::OpenFilePackageInGame(const char* szPckFile, const char* szFolder)
{
	AFilePackGame* pFilePackage = new AFilePackGame;
	if (!pFilePackage->Open(szPckFile, szFolder, AFilePackGame::OPENEXIST))
	{
		delete pFilePackage;
		g_pAFramework->DevPrintf("AFilePackMan::OpenFilePackageInGame(), Can not open package [%s]", szPckFile);
		return false;
	}

	//g_pAFramework->DevPrintf("Package Opened [%s]", szPckFile);
	m_FilePcks.push_back(pFilePackage);

	return true;
}

bool AFilePackMan::CloseFilePackage(AFilePackBase* pFilePck)
{
	for (auto itr = m_FilePcks.begin(); itr != m_FilePcks.end();)
	{
		if (*itr == pFilePck)
		{
			m_FilePcks.erase(itr++);
			pFilePck->Close();
			delete pFilePck;
			return true;
		}
		else
		{
			++itr;
		}
	}

	return false;
}

bool AFilePackMan::CloseAllPackages()
{
	for (auto itr = m_FilePcks.begin(); itr != m_FilePcks.end(); ++itr)
	{
		AFilePackBase* pFilePck = *itr;
		pFilePck->Close();
		delete pFilePck;
	}
	m_FilePcks.clear();
	std::vector<AFilePackBase*> v;
	m_FilePcks.swap(v);

	return true;
}

bool AFilePackMan::FlushAllPackages()
{
	for (AFilePackBase* pFilePck : m_FilePcks)
	{
		pFilePck->Flush();
	}

	return true;
}

AFilePackBase* AFilePackMan::GetFilePck(const char * szPath)
{
	char szLowPath[QMAX_PATH];
	strncpy(szLowPath, szPath, QMAX_PATH);
	ASys::Strlwr(szLowPath);
	AFilePackage::NormalizeFileName(szLowPath);

	for (AFilePackBase* pFilePck : m_FilePcks)
	{
		const char* strFolder = pFilePck->GetFolder();
		if (strstr(szLowPath, strFolder) == szLowPath)
		{
			return pFilePck;
		}
	}

	return NULL;
}

bool AFilePackMan::SetAlgorithmID(int id)
{
	switch (id)
	{
	case 111:
		AFPCK_GUARDBYTE0 = 0xab12908f;
		AFPCK_GUARDBYTE1 = 0xb3231902;
		AFPCK_MASKDWORD = 0x2a63810e;
		AFPCK_CHECKMASK = 0x18734563;
		break;

	default:
		AFPCK_GUARDBYTE0 = 0xfdfdfeee + id * 0x72341f2;
		AFPCK_GUARDBYTE1 = 0xf00dbeef + id * 0x1237a73;
		AFPCK_MASKDWORD = 0xa8937462 + id * 0xab2321f;
		AFPCK_CHECKMASK = 0x59374231 + id * 0x987a223;
		break;
	}

	return true;
}