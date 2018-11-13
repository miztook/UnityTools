#ifndef _A_FRAMEWORK_H_
#define _A_FRAMEWORK_H_

#include "ATypes.h"
#include "AString.h"
#include "ALog.h"

typedef struct
{
	const char*         pszBaseDir;
	const char*         pszDocumentDir;
	const char*         pszLibraryDir;
	const char*         pszTemporaryDir;
}HOBAInitParam;

class AFramework
{
public:
	AFramework();
	virtual	~AFramework();

	bool			Init(const HOBAInitParam& pParam, bool bLog = true);
	void			Release();

	void			Printf(const char *szMsg, ...);
	void			DevPrintf(const char* szMsg, ...);
	void			DevPrintfString(const char* szMsg);

	const char*		GetESShaderDir() const { return m_strESShader; }
	const char*		GetESTextureDir() const { return m_strESTexture; }

protected:
	AString				m_strESShader;
	AString				m_strESTexture;
	ALog					m_log;
};

extern "C"
{
	extern void g_DevPrintf(const char* szMsg, ...);
}

extern AFramework*	 g_pAFramework;

#endif