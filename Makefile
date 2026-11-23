# language: makefile, file: Makefile, target: iOS ARM64 (Theos)
TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = tftmod
tftmod_FILES = Tweak.mm
tftmod_CFLAGS = -fobjc-arc -std=c++17 -O3 -fvisibility=hidden -Wall -Wextra -Wno-unused-parameter
tftmod_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS_MAKE_PATH)/library.mk
