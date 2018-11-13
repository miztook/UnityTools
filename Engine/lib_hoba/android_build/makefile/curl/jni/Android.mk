LOCAL_PATH:= $(call my-dir)

#lib: libcurl
include $(CLEAR_VARS)

LOCAL_MODULE := libcurl

TARGET_OUT := $(LOCAL_PATH)/../../../bin/$(APP_OPTIM)/$(TARGET_ARCH_ABI)/

LOCAL_CFLAGS    := 	-DANDROID_NDK \
					-D__ANDROID__ \
					-DCURL_STATICLIB 	\

CURL_DIR := ../../../../dependency/curl

LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(CURL_DIR)/include	\
					$(LOCAL_PATH)/$(CURL_DIR)/lib	\
					$(LOCAL_PATH)/$(CURL_DIR)/shim	\					

CURL_SRC_FILES := $(wildcard $(LOCAL_PATH)/$(CURL_DIR)/src/*.c)	
CURL_SRC_FILES += $(wildcard $(LOCAL_PATH)/$(CURL_DIR)/shim/*.c)	
CURL_SRC_FILES := $(CURL_SRC_FILES:$(LOCAL_PATH)/%=%)

LOCAL_SRC_FILES := $(CURL_SRC_FILES)

include $(BUILD_STATIC_LIBRARY)

