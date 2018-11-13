#ifndef LUA_LIB
#define LUA_LIB
#endif

#ifdef _WIN32

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <winsock2.h>

#else
#include <time.h>
#include <string.h>
#include <sys/time.h>
#endif

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

extern "C"
{
	#include "lua_export.h"
}

#include <map>
#include <string>
#include <vector>

//#define PROFILE_PRINT OutputDebugString
#define PROFILE_PRINT UnityLog

namespace
{
struct FuncProfileRec
{
	long callcount;
	std::vector<timeval> callts;
    std::vector<long> callstatcount;
	float totalt;
	std::string name;
    long  statcount;

	FuncProfileRec() : callcount(0)
	{
		totalt = 0;
        statcount = 0;
		callts.reserve(100);
        callstatcount.reserve(100);
	}
};
static std::map<std::string,FuncProfileRec *>	s_rec;
static std::vector<FuncProfileRec *> funcIds;
static long totalstatcount =0;

#ifdef _WIN32

static LARGE_INTEGER liFreq;
int gettimeofday(timeval * val, struct timezone *)
{
	timeval& t = *val;
	static LARGE_INTEGER liTime;
	//QueryPerformanceFrequency(&liFreq);
	QueryPerformanceCounter(&liTime);
	t.tv_sec = (long)(liTime.QuadPart / liFreq.QuadPart);
	t.tv_usec = (long)( liTime.QuadPart * 1000000.0 / liFreq.QuadPart - t.tv_sec * 1000000.0);

	return 0;
}

#else

#endif

}


static void profiler_hook( lua_State * L, lua_Debug * ar)
{
	static const char * id = NULL;
	static char info[256];
	static size_t len=0;

	int event = ar->event;
	//if( event == LUA_HOOKCALL || event == LUA_HOOKRET || event == LUA_HOOKTAILRET)
	{
		static timeval now;
		FuncProfileRec * prec = NULL;

		if(event != LUA_HOOKCALL)
		{
			if(funcIds.empty())
				return;
							
			gettimeofday(&now,NULL);
			prec = funcIds.back();
			funcIds.pop_back();            
		}	
		else
		{
			lua_getinfo(L,"nS",ar); 
			//if( !strcmp(ar->what, "C"))
			if( ar->what[0] == 'C')
			{
				id = ar->name ? ar->name : "UNKNOWN";
                //sprintf(id,"%s",ar->name ? ar->name : "UNKNOWN" );
			}
			else 
			{
				len = strlen(ar->short_src);
				if(len <= LUA_IDSIZE -6 )
				{
					ar->short_src[len] = 58;
					int line = ar->linedefined;
					ar->short_src[len+1] = line/1000 + 48;
					ar->short_src[len+2] = (line%1000)/100 + 48;
					ar->short_src[len+3] = (line%100)/10 + 48;
					ar->short_src[len+4] = (line%10) + 48;
					ar->short_src[len+5] = 0;
				}
				id = ar->short_src;
				//sprintf(id,"%s:%d",ar->short_src, ar->linedefined);
			}

			static std::map<std::string,FuncProfileRec *>::iterator found;
			found = s_rec.find(id);
			if(found == s_rec.end())
			{
				prec = new  FuncProfileRec(); 
				s_rec[id] = prec;
				static char name[256];
				if(ar->what[0] == 'C')
				{
					sprintf(name,"[C]%s",ar->name);
				}
				else 
				{
					sprintf(name,"%s (%s)",ar->name ? ar->name : "",id);
				}
				prec->name = name;
			}
			else
			{
				prec = found->second;
			}
			funcIds.push_back(prec);

			//ª÷∏¥
			if( ar->what[0] != 'C')
				ar->short_src[len] = 0;
		}


		FuncProfileRec & rec = *prec;

		if( event == LUA_HOOKCALL)
		{
#if 0
			if(rec.callts.size() > 50) //µ›πÈµ˜”√Ã´∂‡¥Œ¡À
			{
				sprintf(info,"too deeply call: %s\n",rec.name.c_str());
				PROFILE_PRINT(info);
			}
#endif
			++rec.callcount;
            ++totalstatcount;
            rec.callstatcount.push_back(totalstatcount);
			gettimeofday(&now,NULL);
			rec.callts.push_back(now);
		}
		else
		{
            
			if( !rec.callts.empty() )
			{
				timeval& t = rec.callts.back(); 
				rec.totalt +=( (now.tv_sec - t.tv_sec)*1000.f + ( now.tv_usec - t.tv_usec)*0.001f);
				rec.callts.pop_back();
                rec.statcount += (totalstatcount - rec.callstatcount.back());
                rec.callstatcount.pop_back();
			}
		}
	}

}

static int profiler_init( lua_State * L)
{
	return  0;
}

static int profiler_start( lua_State * L)
{
	if(lua_gethook(L))
	{
		lua_pushstring(L,"has been started");
		lua_error(L);
		return 0;
	}
#ifdef _WIN32		
	QueryPerformanceFrequency(&liFreq);
#endif

    totalstatcount = 0;
	s_rec.clear();
	funcIds.clear();
	funcIds.reserve(50);
	lua_sethook(L,profiler_hook,LUA_MASKCALL | LUA_MASKRET ,0); 
	return 0;
}

static int profiler_stop( lua_State * L)
{
	lua_sethook(L,NULL,0,0);
	return 0;
}

static int profiler_stat( lua_State * L)
{
	if( s_rec.empty())
	{
		lua_pushnil(L);
		return 1;
	}
	lua_newtable(L);	//T

	int i=1;
	for(auto it = s_rec.begin(); it != s_rec.end(); ++it,++i)
	{
		FuncProfileRec & rec = *it->second;
		lua_pushnumber(L,i);
		lua_newtable(L); //T,i,t

		int index=0;
		lua_pushnumber(L,++index);//T,i,t,k
		lua_pushstring(L,rec.name.c_str()); //T,i,t,k,v
		lua_settable(L,-3);//T,i,t

		lua_pushnumber(L,++index);
		lua_pushnumber(L,rec.callcount);
		lua_settable(L,-3);

		lua_pushnumber(L,++index);
		lua_pushnumber(L,(double)(rec.totalt)); //∫¡√Î
		lua_settable(L,-3);
        
        lua_pushnumber(L,++index);
        lua_pushnumber(L,(double)(rec.statcount)); //∫¡√Î
        lua_settable(L,-3);


		lua_settable(L,-3); //T  
	}

	return 1;
}

static char getf[100];
static char setf[100];

//function(t,key)
//		local v = mt[key]
//		if v then return v end
//		v = mt['g_' .. key]
//		if v then return v(t) end
//		return nil
//end
static int cs_indexfunc(lua_State * L) //t,key
{
	lua_pushvalue(L,2); //args/key
	lua_gettable(L,lua_upvalueindex(1));//args/mt[key]
	if(lua_isnil(L,-1) == false)
		return  1;

	lua_pop(L,1); //args
	const char * key = lua_tostring(L,2);
	int i=3;
	while( *key)
		getf[++i] = *(key++);
	getf[++i] = 0;

	lua_pushlstring(L,getf,i); //args/getkey
	lua_gettable(L,lua_upvalueindex(1));//args/mt[get_key]
	if(lua_isnil(L,-1) == false)
	{
		lua_pushvalue(L,1);
		lua_call(L,1,1);
		return  1;
	}
	lua_pop(L,1); //args
	return 0;
}

static int cs_index(lua_State * L)
{
	lua_pushvalue(L,1);
	lua_pushcclosure(L,cs_indexfunc,1);
	return 1;
}

//function(t,key,value)
//		local v = mt['set_' .. key]
//		if v then v(t,value); return t end
//end

static int cs_newindexfunc(lua_State * L) //t,key
{
	const char * key = lua_tostring(L,2);
	int i=3;
	while( *key)
		setf[++i] = *(key++);
	setf[++i] = 0;

	lua_pushlstring(L,setf,i); //args/setkey
	lua_gettable(L,lua_upvalueindex(1));//args/mt[get_key]
	if(lua_isnil(L,-1) == false)
	{
		lua_pushvalue(L,1);
		lua_pushvalue(L,3);
		lua_call(L,2,1);
		return  1; 
	}
	lua_pop(L,1); //args
	return 0;
}

static int cs_newindex(lua_State * L)
{
	lua_pushvalue(L,1);
	lua_pushcclosure(L,cs_newindexfunc,1);
	return 1;
}

//function(t,key)
//		local v = mt[key]
//		if v then return v end
//		v = mt['get_' .. key]
//		if v then return v() end
//		return nil
//end
static int csmt_indexfunc(lua_State * L) //t,key
{
	lua_pushvalue(L,2); //args/key
	lua_gettable(L,lua_upvalueindex(1));//args/mt[key]
	if(lua_isnil(L,-1) == false)
		return  1;

	lua_pop(L,1); //args
	const char * key = lua_tostring(L,2);
	int i=3;
	while( *key)
		getf[++i] = *(key++);
	getf[++i] = 0;

	lua_pushlstring(L,getf,i); //args/getkey
	lua_gettable(L,lua_upvalueindex(1));//args/mt[get_key]
	if(lua_isnil(L,-1) == false)
	{
		lua_call(L,0,1);
		return  1;
	}
	lua_pop(L,1); //args
	return 0;
}

static int csmt_index(lua_State * L)
{
	lua_pushvalue(L,1);
	lua_pushcclosure(L,csmt_indexfunc,1);
	return 1;
}

//function(t,key,value)
//		local v = mt['set_' .. key]
//		if v then v(value); return t end
//end
static int csmt_newindexfunc(lua_State * L) //t,key
{
	const char * key = lua_tostring(L,2);
	int i=3;
	while( *key)
		setf[++i] = *(key++);
	setf[++i] = 0;

	lua_pushlstring(L,setf,i); //args/setkey
	lua_gettable(L,lua_upvalueindex(1));//args/mt[get_key]
	if(lua_isnil(L,-1) == false)
	{
		lua_pushvalue(L,3);
		lua_call(L,1,1);
		return  1;
	}
	lua_pop(L,1); //args
	return 0;
}

static int csmt_newindex(lua_State * L)
{
	lua_pushvalue(L,1);
	lua_pushcclosure(L,csmt_newindexfunc,1);
	return 1;
}

static const struct luaL_Reg profiler_funcs[] = {
  { "init",	profiler_init },
  { "start",	profiler_start },
  { "stop",	profiler_stop },
  { "stat",	profiler_stat },
  { NULL, NULL }
};

extern "C"
{
	int luaopen_profiler(lua_State *L)
	{
#if LUA_VERSION_NUM < 502
		luaL_register(L, "profiler", profiler_funcs);
#else
		luaL_newlib(L, profiler_funcs);
#endif

		getf[0] = 'g';
		getf[1] = 'e';
		getf[2] = 't';
		getf[3] = '_';

		setf[0] = 's';
		setf[1] = 'e';
		setf[2] = 't';
		setf[3] = '_';

		lua_pushcfunction(L, cs_index);
		lua_setglobal(L, "cs_index");
		lua_pushcfunction(L, cs_newindex);
		lua_setglobal(L, "cs_newindex");
		lua_pushcfunction(L, csmt_index);
		lua_setglobal(L, "csmt_index");
		lua_pushcfunction(L, csmt_newindex);
		lua_setglobal(L, "csmt_newindex");

		return 1;
	}
}
