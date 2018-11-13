
LOCAL_PATH:= $(call my-dir)

#lib: libiconv
include $(CLEAR_VARS)

LOCAL_MODULE := libiconv

TARGET_OUT := $(LOCAL_PATH)/../../../bin/$(APP_OPTIM)/$(TARGET_ARCH_ABI)/

LOCAL_CFLAGS := \
	-Wno-multichar \
	-DANDROID \
	-DLIBDIR="\"c\"" \
	-DBUILDING_LIBICONV \
	-DIN_LIBRARY

ICONV_DIR := ../../../../dependency/libiconv-1.13.1

LOCAL_C_INCLUDES += $(LOCAL_PATH)/$(ICONV_DIR)/
LOCAL_C_INCLUDES += $(LOCAL_PATH)/$(ICONV_DIR)/include
LOCAL_C_INCLUDES += $(LOCAL_PATH)/$(ICONV_DIR)/lib
LOCAL_C_INCLUDES += $(LOCAL_PATH)/$(ICONV_DIR)/libcharset/include

LOCAL_SRC_FILES := \
    $(ICONV_DIR)/lib/iconv.c 	\
	$(ICONV_DIR)/lib/relocatable.c	\
	$(ICONV_DIR)/libcharset/lib/localcharset.c	
	

include $(BUILD_STATIC_LIBRARY)

