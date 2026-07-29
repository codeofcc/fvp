set -e
# CPU=i686
# ARCH=x86
# CROSS_PREFIX=$TOOLCHAIN/bin/i686-linux-android$API-
# USR_LIB=$SYSROOT/usr/lib/i686-linux-android/$API
# FFMPEG_EXTRA_CONFIGURE_FLAGS=--disable-asm
#--target-os=linux
# --arch=$ARCH \
# --cpu=$CPU \
# --cc=$CC \
# --cxx=$CXX \
# --cross-prefix=$CROSS_PREFIX \
# --enable-cross-compile \
# --sysroot=$SYSROOT \

# script_path=$(cd "$(dirname "$0")"; pwd)
# if [ -e "$PREFIX/lib/libavcodec.so" ]; then
#       exit 0
# fi
# export LDFLAGS=""
# export LIBRARY_PATH=""
FFMPEG_VERSION=8.1.2
# FFMPEG_SOURCE_DIR=$script_path/ffmpeg
if [ ! -d "$FFMPEG_SOURCE_DIR" ]; then
  echo ffmpeg Downloading...
  git clone -b n$FFMPEG_VERSION --depth 1 https://git.ffmpeg.org/ffmpeg.git $FFMPEG_SOURCE_DIR
fi

        # --sysroot=/snap/flutter/current \
#        --enable-cross-compile \
#        --cross-prefix=/snap/flutter/current/usr/bin \ /snap/flutter/current/usr/bin/clang 
#-march=$CPU
#     --sysroot=/snap/flutter/current \

#      --arch=x86_64 \
#        --cpu=x86-64 \
#         --target-os=linux \

export C_INCLUDE_PATH=$CPLUS_INCLUDE_PATH


if [ ! -d "$FFMPEG_BUILD_DIR" ]; then
  mkdir $FFMPEG_BUILD_DIR
fi



build_ffmpeg() {
    echo ffmpeg Configuring...
    echo "CC=$CC PREFIX=$PREFIX"
    $FFMPEG_SOURCE_DIR/configure \
        --cc=$CC \
        --prefix=$PREFIX \
        --disable-everything \
        --enable-network \
        --enable-protocols \
        --enable-demuxers \
        --enable-parsers \
        --enable-decoders \
        --enable-hwaccels \
        --enable-swscale \
        --enable-swresample \
        --extra-cflags="-Os -DVK_ENABLE_BETA_EXTENSIONS=0  $FFMPEG_EXTRA_CFLAGS  " \
        --extra-ldflags="$FFMPEG_EXTRA_LDFLAGS " \
        --pkg-config="pkg-config --static" \
        $SHARED_OR_STATIC_FLAG \
        $FFMPEG_EXTRA_CONFIGURE_FLAGSL
    echo ffmpeg Building...
    if [ -e "Makefile" ]; then
        make clean
    fi
    make -j$(nproc)
    echo ffmpeg Installing...
    make install
}
cd $FFMPEG_BUILD_DIR
echo $(pwd)
SHARED_OR_STATIC_FLAG="--disable-shared  --enable-static"
build_ffmpeg