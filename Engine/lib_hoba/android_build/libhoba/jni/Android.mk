HOBA_PATH := $(call my-dir)
LOCAL_PATH := $(HOBA_PATH)

#lib: libcurl
include $(CLEAR_VARS)
LOCAL_MODULE := curl
LOCAL_SRC_FILES := ../../../dependency/libcurl/Android/$(TARGET_ARCH_ABI)/libcurl.a
include $(PREBUILT_STATIC_LIBRARY)

#lib: libssl
include $(CLEAR_VARS)
LOCAL_MODULE := ssl
LOCAL_SRC_FILES := ../../../dependency/libcurl/Android/$(TARGET_ARCH_ABI)/libssl.a
include $(PREBUILT_STATIC_LIBRARY)

#lib: libcrypto
include $(CLEAR_VARS)
LOCAL_MODULE := crypto
LOCAL_SRC_FILES := ../../../dependency/libcurl/Android/$(TARGET_ARCH_ABI)/libcrypto.a
include $(PREBUILT_STATIC_LIBRARY)

#lib: libhoba
include $(CLEAR_VARS)
LOCAL_PATH := $(HOBA_PATH)
LOCAL_MODULE := hoba

TARGET_OUT := $(LOCAL_PATH)/../../../Plugins/Android/$(TARGET_ARCH_ABI)/

LOCAL_CFLAGS    := 	-DANDROID_NDK 	\
					-D__ANDROID__ 	\
					-D_7ZIP_PPMD_SUPPPORT  \

SOURCE_DIR := ../../../source
P7ZDECODE_DIR := ../../../dependency/p7zDecode
#ZLIB_DIR := ../../../dependency/zlib-1.2.8
CURLSHIM_DIR := ../../../dependency/curlShim

LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(SOURCE_DIR)	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/luavm/inc	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/pbc	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/Base	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/SkillCollision	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/Platform/Android	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../dependency/p7zDecode			\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../dependency/libcurl/Android/include	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../dependency/curlShim		\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../csshare/Common	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../csshare/AutoNavigation	\
					$(LOCAL_PATH)/$(SOURCE_DIR)/../updatelib	\
							
P7ZDECODE_SRC_FILES := $(wildcard $(LOCAL_PATH)/$(P7ZDECODE_DIR)/*.c)
P7ZDECODE_SRC_FILES := $(P7ZDECODE_SRC_FILES:$(LOCAL_PATH)/%=%)
				
#ZLIB_SRC_FILES := \
				$(ZLIB_DIR)/adler32.c \
				$(ZLIB_DIR)/compress.c \
				$(ZLIB_DIR)/crc32.c \
				$(ZLIB_DIR)/deflate.c \
				$(ZLIB_DIR)/gzclose.c \
				$(ZLIB_DIR)/gzlib.c \
				$(ZLIB_DIR)/gzread.c \
				$(ZLIB_DIR)/gzwrite.c \
				$(ZLIB_DIR)/infback.c \
				$(ZLIB_DIR)/inffast.c \
				$(ZLIB_DIR)/inflate.c \
				$(ZLIB_DIR)/inftrees.c \
				$(ZLIB_DIR)/trees.c \
				$(ZLIB_DIR)/uncompr.c \
				$(ZLIB_DIR)/zutil.c \
				
CURL_SRC_FILES := $(wildcard $(LOCAL_PATH)/$(CURLSHIM_DIR)/*.c)
CURL_SRC_FILES := $(CURL_SRC_FILES:$(LOCAL_PATH)/%=%)
	
SRC_LUAVM_FILES := $(SOURCE_DIR)/luavm/src/auxiliar.c	\
					$(SOURCE_DIR)/luavm/src/buffer.c	\
					$(SOURCE_DIR)/luavm/src/except.c	\
					$(SOURCE_DIR)/luavm/src/inet.c	\
					$(SOURCE_DIR)/luavm/src/io.c	\
					$(SOURCE_DIR)/luavm/src/lapi.c	\
					$(SOURCE_DIR)/luavm/src/lauxlib.c	\
					$(SOURCE_DIR)/luavm/src/lbaselib.c	\
					$(SOURCE_DIR)/luavm/src/lcode.c	\
					$(SOURCE_DIR)/luavm/src/ldblib.c	\
					$(SOURCE_DIR)/luavm/src/ldebug.c	\
					$(SOURCE_DIR)/luavm/src/ldo.c	\
					$(SOURCE_DIR)/luavm/src/ldump.c	\
					$(SOURCE_DIR)/luavm/src/lfunc.c	\
					$(SOURCE_DIR)/luavm/src/lgc.c	\
					$(SOURCE_DIR)/luavm/src/linit.c	\
					$(SOURCE_DIR)/luavm/src/liolib.c	\
					$(SOURCE_DIR)/luavm/src/llex.c	\
					$(SOURCE_DIR)/luavm/src/lmathlib.c	\
					$(SOURCE_DIR)/luavm/src/lmem.c	\
					$(SOURCE_DIR)/luavm/src/loadlib.c	\
					$(SOURCE_DIR)/luavm/src/lobject.c	\
					$(SOURCE_DIR)/luavm/src/lopcodes.c	\
					$(SOURCE_DIR)/luavm/src/loslib.c	\
					$(SOURCE_DIR)/luavm/src/lparser.c	\
					$(SOURCE_DIR)/luavm/src/lstate.c	\
					$(SOURCE_DIR)/luavm/src/lstring.c	\
					$(SOURCE_DIR)/luavm/src/lstrlib.c	\
					$(SOURCE_DIR)/luavm/src/ltable.c	\
					$(SOURCE_DIR)/luavm/src/ltablib.c	\
					$(SOURCE_DIR)/luavm/src/ltm.c	\
					$(SOURCE_DIR)/luavm/src/luasocket.c	\
					$(SOURCE_DIR)/luavm/src/lundump.c	\
					$(SOURCE_DIR)/luavm/src/lvm.c	\
					$(SOURCE_DIR)/luavm/src/lzio.c	\
					$(SOURCE_DIR)/luavm/src/mime.c	\
					$(SOURCE_DIR)/luavm/src/options.c	\
					$(SOURCE_DIR)/luavm/src/print.c	\
					$(SOURCE_DIR)/luavm/src/select.c	\
					$(SOURCE_DIR)/luavm/src/tcp.c	\
					$(SOURCE_DIR)/luavm/src/timeout.c	\
					$(SOURCE_DIR)/luavm/src/udp.c	\
					$(SOURCE_DIR)/luavm/src/unix.c	\
					$(SOURCE_DIR)/luavm/src/usocket.c	\
					
SRC_PBC_FILES := 	\
					$(SOURCE_DIR)/pbc/src/pballoc.c	\
					$(SOURCE_DIR)/pbc/src/array.c	\
					$(SOURCE_DIR)/pbc/src/bootstrap.c	\
					$(SOURCE_DIR)/pbc/src/context.c	\
					$(SOURCE_DIR)/pbc/src/decode.c	\
					$(SOURCE_DIR)/pbc/src/map.c	\
					$(SOURCE_DIR)/pbc/src/pattern.c	\
					$(SOURCE_DIR)/pbc/src/proto.c	\
					$(SOURCE_DIR)/pbc/src/register.c	\
					$(SOURCE_DIR)/pbc/src/rmessage.c	\
					$(SOURCE_DIR)/pbc/src/stringpool.c	\
					$(SOURCE_DIR)/pbc/src/varint.c	\
					$(SOURCE_DIR)/pbc/src/wmessage.c	\
					$(SOURCE_DIR)/pbc/binding/lua/pbc-lua.c	\
							
SRC_UPDATE_FILES := $(wildcard $(LOCAL_PATH)/../../../updatelib/*.cpp)		
SRC_UPDATE_FILES := $(SRC_UPDATE_FILES:$(LOCAL_PATH)/%=%)
			
SRC_COMMON_FILES :=	$(SOURCE_DIR)/hoba_export.cpp	\
					$(SOURCE_DIR)/lua_export.c	\
					$(SOURCE_DIR)/luastate_export.cpp	\
					$(SOURCE_DIR)/fileimage_export.cpp	\
					$(SOURCE_DIR)/filepackage_export.cpp	\
					$(SOURCE_DIR)/bit.c	\
					$(SOURCE_DIR)/lpeg.c	\
					$(SOURCE_DIR)/lfs.c	\
					$(SOURCE_DIR)/lua_wrap.c	\
					$(SOURCE_DIR)/pb.c	\
					$(SOURCE_DIR)/snapshot.c	\
					$(SOURCE_DIR)/profiler.cpp	\
					$(SOURCE_DIR)/LuaUInt64.cpp	\
					$(SOURCE_DIR)/LuaUtility.cpp	\
					$(SOURCE_DIR)/navmesh_export.cpp	\
					$(SOURCE_DIR)/BinaryReadWrite.cpp		\
					$(SOURCE_DIR)/skillcollision_export.cpp		\
					$(SOURCE_DIR)/curl_export.cpp		\
					$(SOURCE_DIR)/curl_shim_export.cpp		\
						
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../source/Base/*.cpp)
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../source/SkillCollision/*.cpp)
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../source/Platform/Android/*.cpp)
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../source/Platform/Android/*.c)
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../csshare/AutoNavigation/*.cpp)
SRC_COMMON_FILES += $(wildcard $(LOCAL_PATH)/../../../csshare/Common/*.cpp)
SRC_COMMON_FILES := $(SRC_COMMON_FILES:$(LOCAL_PATH)/%=%)
		
			
LOCAL_SRC_FILES := 		\
					$(SRC_LUAVM_FILES)	\
					$(SRC_PBC_FILES)	\
					$(SRC_COMMON_FILES) \
					$(SRC_UPDATE_FILES)	\
					$(P7ZDECODE_SRC_FILES) \
					$(CURL_SRC_FILES)	\
					
LOCAL_STATIC_LIBRARIES := curl ssl crypto
LOCAL_LDLIBS    := -lz -llog -landroid

include $(BUILD_SHARED_LIBRARY)
