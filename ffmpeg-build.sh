#!/bin/bash

export BASE_DIR=`cd "$(dirname "$0")" && pwd`
echo "Base directory set to ${BASE_DIR}"

export SRC_PATH=$BASE_DIR
export BUILD_DIR=$BASE_DIR/build


if [ -z "$ANDROID_NDK" ]; then
  echo "Please set ANDROID_NDK to the Android NDK folder"
  exit 1
fi

export

#Change to your local machine's architecture
HOST_OS_ARCH=darwin-x86_64

function configure_ffmpeg {

cd ${BASE_DIR}

  ABI=$1
  PLATFORM_VERSION=$2
  TOOLCHAIN_PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/${HOST_OS_ARCH}/bin
  local STRIP_COMMAND

  # Determine the architecture specific options to use
  case ${ABI} in
  armeabi-v7a)
    TOOLCHAIN_PREFIX=armv7a-linux-androideabi
    STRIP_COMMAND=arm-linux-androideabi-strip
    ARCH=armv7-a
    ;;
  arm64-v8a)
    TOOLCHAIN_PREFIX=aarch64-linux-android
    ARCH=aarch64
    ;;
  x86)
    TOOLCHAIN_PREFIX=i686-linux-android
    ARCH=x86
    EXTRA_CONFIG="--disable-asm"
    ;;
  x86_64)
    TOOLCHAIN_PREFIX=x86_64-linux-android
    ARCH=x86_64
    EXTRA_CONFIG="--disable-asm"
    ;;
  esac

  if [ -z ${STRIP_COMMAND} ]; then
    STRIP_COMMAND=${TOOLCHAIN_PREFIX}-strip
  fi

  echo "Configuring FFmpeg build for ${ABI}"
  echo "Toolchain path ${TOOLCHAIN_PATH}"
  echo "Command prefix ${TOOLCHAIN_PREFIX}"
  echo "Strip command ${STRIP_COMMAND}"


  $BASE_DIR/configure --prefix=$BUILD_DIR/${ABI} --bindir=$BUILD_DIR/$ABI/bin --target-os=android --arch=${ARCH} --enable-cross-compile --cc=${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}${PLATFORM_VERSION}-clang --strip=${TOOLCHAIN_PATH}/${STRIP_COMMAND} --disable-programs --disable-doc --enable-shared --disable-static --extra-cflags="-O3 -fPIC" ${EXTRA_CONFIG} --disable-everything --enable-encoder=aac --enable-muxer=mp4 --enable-protocol=file
  # The path where the resulting libraries and headers will be installed after `make install` is run. The resulting directory structure is "build/{armeabi-v7a,arm64-v8a,x86,x86_64}/{include, lib}".
#--prefix=$BUILD_DIR \
  # Target operating system name.
#  --target-os=android \
#  # Target CPU architecture e.g. armv7-a.
#  --arch=${ARCH} \
#  # We are compiling for a different target architecture than the host.
#  --enable-cross-compile \
#  # Path to the C compiler. In our case we\'re using clang.
#  --cc=${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}${PLATFORM_VERSION}-clang \
#  # Path to the strip binary for our target architecture.
#  --strip=${TOOLCHAIN_PATH}/${STRIP_COMMAND} \
#  # Optimize for size instead of speed.
##  --enable-small \
#  # Do not build command line programs. We don\'t need them as our app will be interacting with the FFmpeg API.
#  --disable-programs \
#  # Do not build documentation.
#  --disable-doc \
#  # Build shared libraries. We\'ll keep the FFmpeg .so files separate from our main shared library.
#  --enable-shared \
#  # Do not build static libraries.
#  --disable-static \
#  ${EXTRA_CONFIG} \
#  # Disable all modules. To keep the library size to a minimum we will explicitly specify the modules to be built below.
#  --disable-everything \
#  # Enable the MP4 decoder. For a list of supported decoders type ./configure --help.
#  --enable-encoder=aac \
#  # Enable the MP4 demuxer. For a list of supported demuxers type ./configure --help.
#  --enable-muxer=mp4

  return $?
}

function build_ffmpeg {

  configure_ffmpeg $1 $2

  if [ $? -eq 0 ]
  then
          make clean
          make -j12
          make install
          make clean
  else
          echo "FFmpeg configuration failed, please check the error log."
  fi
}

build_ffmpeg armeabi-v7a 21
build_ffmpeg arm64-v8a 21
build_ffmpeg x86 21
build_ffmpeg x86_64 21