#ifndef _CURL_SHIM_EXPORT_H_
#define _CURL_SHIM_EXPORT_H_

#include "baseDef.h"
#include <time.h>
#include <stdint.h>

HAPI void CURL_curl_shim_initialize();
HAPI void CURL_curl_shim_cleanup();
HAPI void* CURL_curl_shim_alloc_strings();
HAPI void* CURL_curl_shim_add_string_to_slist(
	void* lst, char* pInStr);
HAPI void* CURL_curl_shim_get_string_from_slist(
	void* lst, char** ppString);
HAPI char* CURL_curl_shim_add_string(void* p, char* pInStr);
HAPI void CURL_curl_shim_free_strings(void* p);
HAPI void CURL_curl_shim_free_slist(void* lst);

HAPI int CURL_curl_shim_install_delegates(void* handle,
	void* pvThis, void* pvWriteDel, void* pvReadDel, void* pvProgDel,
	void* pvDebugDel, void* pvHeaderDel, void* pvSSLContextDel,
	void* pvIoctlDel);
HAPI void CURL_curl_shim_cleanup_delegates(void* pvThis);

HAPI void* CURL_curl_shim_alloc_fd_sets();
HAPI void CURL_curl_shim_free_fd_sets(void* pvfdSets);
HAPI int CURL_curl_shim_multi_fdset(void* pvMulti,
	void* pvfdSets, int* maxFD);
HAPI int CURL_curl_shim_select(int maxFD, void* pvfdSets,
	int timeoutMillis);
HAPI void* CURL_curl_shim_multi_info_read(void* pvHandle,
	int* nMsgs);
HAPI void CURL_curl_shim_multi_info_free(void* pvMultiInfo);
  
//HAPI int CURL_curl_shim_formadd(int* pvPosts, void* pvItems, int nCount);

HAPI int CURL_curl_shim_install_share_delegates(
	void* handle, void* pvThis, void* pvLockDel, void* pvUnlockDel);
HAPI void CURL_curl_shim_cleanup_share_delegates(void* pvThis);

HAPI char* CURL_curl_shim_get_version_char_ptr(
	void* p, int offset);
HAPI int CURL_curl_shim_get_version_int_value(
	void* p, int offset);
HAPI int CURL_curl_shim_get_number_of_protocols(
	void* p, int protOffset);
HAPI char* CURL_curl_shim_get_protocol_string(
	void* p, int protOffset, int nProt);

#endif