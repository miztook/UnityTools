
LOCAL_PATH:= $(call my-dir)

#lib: libzlib
include $(CLEAR_VARS)

LOCAL_MODULE := libzlib

TARGET_OUT := $(LOCAL_PATH)/../../../bin/$(APP_OPTIM)/$(TARGET_ARCH_ABI)/

LOCAL_CFLAGS := \

ZLIB_DIR := ../../../../Dependency/zlib-1.2.8

LOCAL_C_INCLUDES := 	\
					$(LOCAL_PATH)/$(ZLIB_DIR)		\

LOCAL_SRC_FILES := \
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
	

include $(BUILD_STATIC_LIBRARY)
