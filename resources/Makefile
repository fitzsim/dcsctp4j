# Minimal build steps that produce libdcsctp.a
# Copyright (C) 2025
# Author: Thomas Fitzsimmons <fitzsim@fitzsim.org>
# Version: 1
# SPDX-License-Identifier: Apache-2.0
#
# I could not get "gn" working on ppc64le [1] so I wrote this Makefile
# from scratch assuming all net/dcsctp .cc files were needed, and that
# headers that "gn" would have written could instead be stubbed out as
# empty files.  Runtime testing of Jitsi seems to confirm that the
# resulting libdcsctp.a satisfies libdcsctp4j.so's needs on ppc64le.
# 1. https://github.com/jitsi/dcsctp4j/issues/6#issuecomment-2635229005
#
S := $(VPATH)
# The -fPIC flag is needed so that generated objects are compatible
# with other objects in libdcsctp4j.so, which is built as a shared
# library.
CXXFLAGS += -fPIC
# The -DWEBRTC_POSIX flag specifies to dcsctp headers that we are
# building on a POSIX platform.
CXXFLAGS += -DWEBRTC_POSIX
# The -Wno-return-type eliminates some warnings reported by gcc 12.
CXXFLAGS += -Wno-return-type
# Add ../.. include paths to fix compilation errors due to missing
# include files.
CXXFLAGS += -I $(S)
CXXFLAGS += -I $(S)/third_party/abseil-cpp
CXXFLAGS += -I $(S)/third_party/crc32c/config
CXXFLAGS += -I $(S)/third_party/crc32c/src/include
# Assume all non-test .cc files are needed, even though a
# "gn"-configured build may omit some.  Assume all source files are in
# subdirectories and subsubdirectories.
TESTS = $(wildcard $(S)/net/dcsctp/*/*_test.cc $(S)/net/dcsctp/*/*/*_test.cc)
SOURCES = $(wildcard $(S)/net/dcsctp/*/*.cc $(S)/net/dcsctp/*/*/*.cc)
DIRS = $(wildcard $(S)/*/ $(S)/*/*/ $(S)/*/*/*/ $(S)/*/*/*/*/)
OBJECTS = $(patsubst %.cc,%.o,$(filter-out $(TESTS),$(SOURCES)))
# # Add ../../ object files to fix libdcsctp4j.so errors: first
# # compilation errors, then undefined symbol errors reported at runtime
# # by the dynamic linker.
OBJECTS += $(S)/api/units/time_delta.o
OBJECTS += $(S)/rtc_base/logging.o
OBJECTS += $(S)/rtc_base/string_encode.o
OBJECTS += $(S)/rtc_base/strings/string_builder.o
OBJECTS += $(S)/rtc_base/strings/string_format.o
OBJECTS += $(S)/third_party/crc32c/src/src/crc32c.o
OBJECTS += $(S)/third_party/crc32c/src/src/crc32c_portable.o
ifeq ($(strip $(OBJDIR)),)
$(error "Set OBJDIR to absolute path in which to store output objects")
endif
OBJECTS := $(addprefix $(OBJDIR)/,$(OBJECTS))
OBJDIRS := $(addprefix $(OBJDIR)/,$(DIRS))
$(OBJDIR)/%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@
$(OBJDIR)/libdcsctp.a: $(OBJECTS)
	$(AR) $(ARFLAGS) $@ $^
$(OBJECTS): | $(OBJDIRS)
$(OBJDIRS):
	@mkdir -p $(OBJDIRS)
