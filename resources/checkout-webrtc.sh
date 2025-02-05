#!/usr/bin/env bash
DEPOT_TOOLS_REPO="https://chromium.googlesource.com/chromium/tools/depot_tools.git"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <DEPOT_TOOLS_DIR> <WEBRTC_DIR> <REV>"
    echo "  DEPOT_TOOLS_DIR: Directory for Google depot tools (may exist already)"
    echo "  WEBRTC_DIR: Directory for WebRTC checkout (may exist already)"
    echo "  REV: Revision of WebRTC to check out"
    exit 1
fi;

set -e
export -n SHELLOPTS # Makes depot-tools fail

DEPOT_TOOLS_DIR=$1 # Ignored
WEBRTC_DIR=$2
REV=$3

STARTDIR=$PWD
# branch-heads/6422 => branch-heads.
REFS=${REV%/*}
CONFIG=remote.origin.fetch=+refs/$REFS/*:refs/remotes/origin/$REFS/*
REPO=https://webrtc.googlesource.com/src/

# See if they specified the WebRTC src dir rather than its parent
if test "$(basename "$WEBRTC_DIR")" = "src"; then
    WEBRTC_DIR="$(dirname $WEBRTC_DIR)"
fi

if test \! -d "$WEBRTC_DIR"; then
    mkdir -p "$WEBRTC_DIR"
    cd "$WEBRTC_DIR"
    # Pretend that gclient was run to satisfy
    # "WEBRTC_DIR=$WEBRTC_DIR/src" condition in ubuntu-build.sh.
    touch .gclient
    git clone --config $CONFIG $REPO
    cd src
    git checkout $REV
    SINGLE_QUOTES="s%^.*'\([^']*\)'.*%\1%"
    # Clone third_party.  Only third_party/abseil-cpp is used in the
    # Makefile but we need ~4GiB of third_party repository history to
    # get the abseil-cpp import specified by DEPS.
    cd "$WEBRTC_DIR"/src
    LINES=$(grep -A 1 "'src/third_party'" DEPS)
    SPEC=$(echo "$LINES" | tail -n 1 | sed $SINGLE_QUOTES)
    SINCE="March 1, 2024"
    SPEC_REPO=${SPEC%@*}
    SPEC_REV=${SPEC#*@}
    git clone --shallow-since "$SINCE" $SPEC_REPO
    cd third_party
    git checkout $SPEC_REV
    # Clone crc32c under third_party, the revision specified in
    # DEPS.  third_party/crc32c is used in the Makefile.
    cd "$WEBRTC_DIR"/src
    LINES=$(grep -A 1 "'src/third_party/crc32c/src'" DEPS)
    SPEC=$(echo "$LINES" | tail -n 1 | sed $SINGLE_QUOTES)
    SINCE="January 1, 2021"
    SPEC_REPO=${SPEC%@*}
    SPEC_REV=${SPEC#*@}
    mkdir -p third_party/crc32c
    cd third_party/crc32c
    git clone --shallow-since "$SINCE" $SPEC_REPO src
    cd src
    git checkout $SPEC_REV
fi

cd "$STARTDIR"
