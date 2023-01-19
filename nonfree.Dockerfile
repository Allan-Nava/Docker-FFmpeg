# syntax = docker/dockerfile:1.3-labs

ARG TARGET_OS="linux"
ARG CUDA_SDK_VERSION=11.5.0

FROM ghcr.io/Allan-Nava/ffmpeg-library-build:${TARGET_OS} AS ffmpeg-library-build

FROM nvidia/cuda:${CUDA_SDK_VERSION}-devel-ubuntu20.04 AS ffmpeg-build

SHELL ["/bin/bash", "-e", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,video

# Install build tools
RUN <<EOT
rm -rf /var/lib/apt/lists/*
sed -i -r 's!(deb|deb-src) \S+!\1 http://jp.archive.ubuntu.com/ubuntu/!' /etc/apt/sources.list
apt-get update
apt-get install -y \
    build-essential \
    clang \
    curl \
    libtool \
    make \
    cmake \
    git \
    subversion \
    mingw-w64 \
    mingw-w64-tools \
    nasm \
    p7zip \
    pkg-config \
    yasm
EOT

# ffmpeg-library-build image
COPY --from=ffmpeg-library-build / /

ENV TARGET_OS=${TARGET_OS} \
    PREFIX="/usr/local" \
    LDFLAGS="-L${PREFIX}/cuda/lib64" \
    CFLAGS="-I${PREFIX}/cuda/include" \
    WORKDIR="/workdir"

WORKDIR ${WORKDIR}

# Copy build script
ADD ./scripts/*.sh ./


#
# Audio
#



# Build fdk-aac
ENV FDK_AAC_VERSION=2.0.2
RUN <<EOT
source ./base.sh
download_and_unpack_file "https://download.sourceforge.net/opencore-amr/fdk-aac/fdk-aac-${FDK_AAC_VERSION}.tar.gz"
do_configure
do_make_and_make_install
echo -n "`cat ${PREFIX}/ffmpeg_configure_options` --enable-libfdk-aac" > ${PREFIX}/ffmpeg_configure_options
EOT

RUN bash ./build-tools.sh 

#
# HWAccel
#

# cuda-nvcc and libnpp
ARG CUDA_SDK_VERSION
ARG NVIDIA_DRIVER_VERSION=495.46
ADD ./cuda_${CUDA_SDK_VERSION}_${NVIDIA_DRIVER_VERSION}_windows.exe /tmp/cuda_${CUDA_SDK_VERSION}_${NVIDIA_DRIVER_VERSION}_windows.exe
RUN <<EOT
echo -n "`cat ${PREFIX}/ffmpeg_configure_options` --enable-cuda-nvcc --enable-libnpp" > ${PREFIX}/ffmpeg_configure_options
echo -n "`cat ${PREFIX}/ffmpeg_configure_options` --nvccflags='-gencode arch=compute_52,code=sm_52'" > ${PREFIX}/ffmpeg_configure_options
EOT


#
# Build ffmpeg
#
ARG FFMPEG_VERSION=5.1.2
ENV FFMPEG_VERSION="${FFMPEG_VERSION}"

# Run build
RUN bash ./build-ffmpeg.sh

# Copy artifacts
RUN <<EOT
mkdir -p /build/lib
cat <<'EOS' > ${PREFIX}/run.sh
#!/bin/sh
export PATH=$(dirname $0)/bin:$PATH
export LD_LIBRARY_PATH=$(dirname $0)/lib:$LD_LIBRARY_PATH
exec $@
EOS
    chmod +x ${PREFIX}/run.sh
    cp --archive --parents --no-dereference ${PREFIX}/run.sh /build
    cp --archive --parents --no-dereference ${PREFIX}/bin/ff* /build
#    cp --archive --parents --no-dereference ${PREFIX}/configure_options /build
#    cp --archive --parents --no-dereference ${PREFIX}/lib/*.so* /build
    cd /usr/local/cuda/targets/x86_64-linux/lib
    cp libnppig* /build/lib
    cp libnppif* /build/lib
    cp libnppicc* /build/lib
    cp libnppidei* /build/lib
    cp libnppc* /build/lib
EOT

#
# final ffmpeg image
#
FROM scratch AS ffmpeg

COPY --from=ffmpeg-build /build /
