#!/usr/bin/env bash
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <JAVA_HOME> <DEPOT_TOOLS_DIR> <WEBRTC_DIR> <ARCH>"
    echo "  JAVA_HOME: Path to Java installation"
    echo "  DEPOT_TOOLS_DIR: Directory containing Google depot tools"
    echo "  WEBRTC_DIR: Directory containing WebRTC source"
    echo "  ARCH: Architecture to build for (x86_64 or arm64)"
    exit 1
fi

set -e
export -n SHELLOPTS

JAVA_HOME=$1
DEPOT_TOOLS_DIR=$2 # Ignored
WEBRTC_DIR=$3
ARCH=$4

case $ARCH in
    "x86-64"|"x86_64"|"amd64"|"x64")
        JNAARCH=x86-64
        DEBARCH=x86_64
        GN_ARCH=x64
        GCC_ARCH=x86_64
        ;;
    "arm64"|"aarch64")
        JNAARCH=aarch64
        DEBARCH=arm64
        GN_ARCH=arm64
        GCC_ARCH=aarch64
        ;;
    "ppc64le")
        JNAARCH=ppc64le
        DEBARCH=ppc64el
        GN_ARCH=ppc64le
        GCC_ARCH=powerpc64le
        ;;
    *)
	echo "ERROR: Unsupported arch $ARCH"
	exit 1
	;;
esac

# apt install g++-{aarch64,powerpc64le,x86-64}-linux-gnu
TOOLCHAIN_FILE="cmake/$DEBARCH-linux-gnu.cmake"

if test \! -d $WEBRTC_DIR/.git -a -r $WEBRTC_DIR/.gclient -a -d $WEBRTC_DIR/src/.git; then
    WEBRTC_DIR=$WEBRTC_DIR/src
fi

WEBRTC_BUILD=out/linux-$GN_ARCH
WEBRTC_OBJ=$WEBRTC_DIR/../$WEBRTC_BUILD

PATH=$PATH:$DEPOT_TOOLS_DIR

startdir=$PWD

NCPU=$(nproc)
if [ -n "$NCPU" -a "$NCPU" -gt 1 ]
then
    MAKE_ARGS="-j $NCPU"
fi

cd $startdir/resources
# Build libdcsctp.a.
# FIXME: Is replacement logic for "gn gen" required?
XCXX=${GCC_ARCH}-linux-gnu-g++
XAR=${GCC_ARCH}-linux-gnu-ar
make $MAKE_ARGS VPATH="$WEBRTC_DIR" OBJDIR="$WEBRTC_OBJ/obj" CXX=$XCXX AR=$XAR
cd $startdir

if [ -n "$MAKE_ARGS" ]
then
    CMAKE_BUILD_ARGS=" -- $MAKE_ARGS"
fi

rm -rf cmake-build-linux-"$DEBARCH"
cmake -B cmake-build-linux-"$DEBARCH" \
    -DJAVA_HOME="$JAVA_HOME" \
    -DCMAKE_INSTALL_PREFIX="src/main/resources/linux-$JNAARCH" \
    -DWEBRTC_DIR="$WEBRTC_DIR" \
    -DWEBRTC_OBJ="$WEBRTC_OBJ" \
    -DCMAKE_TOOLCHAIN_FILE:PATH="$TOOLCHAIN_FILE" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo

cmake --build cmake-build-linux-"$DEBARCH" --target install $CMAKE_BUILD_ARGS
