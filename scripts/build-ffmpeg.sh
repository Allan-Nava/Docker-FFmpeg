#!/bin/bash -x

source ./base.sh

# Build ffmpeg
FFMPEG_VERSION=5.1.2
#curl -LO  "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"
#tar xf ffmpeg-${FFMPEG_VERSION}.tar.xz
#cd ffmpeg-5.1.2
#cat ${PREFIX}/ffmpeg_configure_options
#./configure --enable-zlib --enable-libopenjpeg --enable-libwebp --enable-lzma --enable-gnutls --enable-libsrt --enable-libvpx --enable-libx264 --enable-libx265 --enable-libopus --enable-libvorbis --enable-libmp3lame --enable-libass --enable-sdl2 --enable-cuda-nvcc --enable-libnpp --nvccflags="-gencode arch=compute_52,code=sm_52" --enable-cuda-llvm --enable-ffnvcodec --enable-cuvid --enable-nvdec --enable-nvenc \
#  --disable-autodetect \
#  --extra-ldflags="-L/usr/local/cuda-11.5/lib64" --extra-cflags="-I/usr/local/cuda-11.5/include/" \
#  --enable-nonfree \
#              --disable-debug \
#              --extra-libs="`cat ${PREFIX}/ffmpeg_extra_libs`" \
#              --disable-doc \
#              --enable-gpl \
#	      --enable-pthreads \
#              --enable-version3 \
#              --pkg-config-flags="--static" \
#              --prefix=${PREFIX} 

download_and_unpack_file "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"
case ${TARGET_OS} in
Linux | linux)
  ./configure `cat ${PREFIX}/ffmpeg_configure_options` \
              --disable-debug \
              --enable-gpl \
              --enable-version3 \
              --enable-static \
              --disable-indev=sndio \
              --disable-outdev=sndio \
              --extra-libs="`cat ${PREFIX}/ffmpeg_extra_libs`" \
              --pkg-config-flags="--static" \
              --prefix=${PREFIX} > ${PREFIX}/configure_options
  ;;
Darwin | darwin)
  HOST_OS="macos"
  HOST_ARCH="universal"
  BUILD_TARGET=
  CROSS_PREFIX=
  ;;
Windows | windows)
  ./configure `cat ${PREFIX}/ffmpeg_configure_options` \
              --arch="x86_64" \
              --cross-prefix="${CROSS_PREFIX}" \
              --disable-autodetect \
              --disable-debug \
              --disable-doc \
              --disable-w32threads \
              --enable-cross-compile \
              --enable-gpl \
              --enable-version3 \
              --extra-libs="-static -static-libgcc -static-libstdc++ -Wl,-Bstatic `cat ${PREFIX}/ffmpeg_extra_libs`" \
              --extra-cflags="--static" \
              --target-os="mingw64" \
              --pkg-config="pkg-config" \
              --pkg-config-flags="--static" \
              --prefix=${PREFIX} > ${PREFIX}/configure_options
  ;;
esac

do_make_and_make_install
