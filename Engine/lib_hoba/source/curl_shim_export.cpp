extern "C"
{
#include "curl_shim_export.h"
#include "LibCurlShim.h"
}

HAPI void CURL_curl_shim_initialize()
{
	curl_shim_initialize();
}

HAPI void CURL_curl_shim_cleanup()
{
	curl_shim_cleanup();
}

HAPI void* CURL_curl_shim_alloc_strings()
{
	return curl_shim_alloc_strings();
}

HAPI void* CURL_curl_shim_add_string_to_slist(
	void* lst, char* pInStr)
{
	return curl_shim_add_string_to_slist(lst, pInStr);
}

HAPI void* CURL_curl_shim_get_string_from_slist(
	void* lst, char** ppString)
{
	return curl_shim_get_string_from_slist(lst, ppString);
}

HAPI char* CURL_curl_shim_add_string(void* p, char* pInStr)
{
	return curl_shim_add_string(p, pInStr);
}

HAPI void CURL_curl_shim_free_strings(void* p)
{
	curl_shim_free_strings(p);
}

HAPI void CURL_curl_shim_free_slist(void* lst)
{
	curl_shim_free_slist(lst);
}

HAPI int CURL_curl_shim_install_delegates(void* handle,
	void* pvThis, void* pvWriteDel, void* pvReadDel, void* pvProgDel,
	void* pvDebugDel, void* pvHeaderDel, void* pvSSLContextDel,
	void* pvIoctlDel)
{
	return curl_shim_install_delegates(handle,
		pvThis, pvWriteDel, pvReadDel, pvProgDel,
		pvDebugDel, pvHeaderDel, pvSSLContextDel, pvIoctlDel);
}

HAPI void CURL_curl_shim_cleanup_delegates(void* pvThis)
{
	curl_shim_cleanup_delegates(pvThis);
}

HAPI void* CURL_curl_shim_alloc_fd_sets()
{
	return curl_shim_alloc_fd_sets();
}

HAPI void CURL_curl_shim_free_fd_sets(void* pvfdSets)
{
	curl_shim_free_fd_sets(pvfdSets);
}

HAPI int CURL_curl_shim_multi_fdset(void* pvMulti,
	void* pvfdSets, int* maxFD)
{
	return curl_shim_multi_fdset(pvMulti, pvfdSets, maxFD);
}

HAPI int CURL_curl_shim_select(int maxFD, void* pvfdSets,
	int timeoutMillis)
{
	return curl_shim_select(maxFD, pvfdSets, timeoutMillis);
}

HAPI void* CURL_curl_shim_multi_info_read(void* pvHandle,
	int* nMsgs)
{
	return curl_shim_multi_info_read(pvHandle, nMsgs);
}

HAPI void CURL_curl_shim_multi_info_free(void* pvMultiInfo)
{
	curl_shim_multi_info_free(pvMultiInfo);
}

// HAPI int CURL_curl_shim_formadd(int* pvPosts,
// 	void* pvItems, int nCount)
// {
// 	return curl_shim_formadd(pvPosts, pvItems, nCount);
// }

HAPI int CURL_curl_shim_install_share_delegates(
	void* handle, void* pvThis, void* pvLockDel, void* pvUnlockDel)
{
	return curl_shim_install_share_delegates(handle, pvThis, pvLockDel, pvUnlockDel);
}

HAPI void CURL_curl_shim_cleanup_share_delegates(void* pvThis)
{
	curl_shim_cleanup_share_delegates(pvThis);
}

HAPI char* CURL_curl_shim_get_version_char_ptr(
	void* p, int offset)
{
	return curl_shim_get_version_char_ptr(p, offset);
}

HAPI int CURL_curl_shim_get_version_int_value(
	void* p, int offset)
{
	return curl_shim_get_version_int_value(p, offset);
}

HAPI int CURL_curl_shim_get_number_of_protocols(
	void* p, int protOffset)
{
	return curl_shim_get_number_of_protocols(p, protOffset);
}

HAPI char* CURL_curl_shim_get_protocol_string(
	void* p, int protOffset, int nProt)
{
	return curl_shim_get_protocol_string(p, protOffset, nProt);
}