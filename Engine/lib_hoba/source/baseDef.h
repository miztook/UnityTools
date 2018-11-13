#ifndef _BASEDEF_H_
#define _BASEDEF_H_

#ifdef LIBHOBA_EXPORTS
#define HAPI __declspec(dllexport)
#else
#define HAPI extern
#endif

#endif
