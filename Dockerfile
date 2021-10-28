ARG CUDA_VERSION=10.2
ARG UBUNTU_VERSION=18.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS BUILDER

ARG BUILD_CORES=4

RUN apt update && apt upgrade -y \
    && DEBIAN_FRONTEND=noninteractive  apt -y install \
                      autoconf automake build-essential cmake git-core libass-dev \
                      libfreetype6-dev libgnutls28-dev libmp3lame-dev libsdl2-dev \
                      libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev \
                      libxcb-shm0-dev libxcb-xfixes0-dev ninja-build wget \
                      pkg-config texinfo yasm zlib1g-dev libunistring-dev \
                      python3-pip \
                      libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev \
                      libopus-dev \
                      build-essential yasm cmake libtool libc6 libc6-dev unzip wget \
                      libnuma1 libnuma-dev \
    && DEBIAN_FRONTEND=noninteractive apt -y install libaom-dev || echo "libaom not needed" \
    && apt autoremove && apt clean && rm -rf /var/lib/apt/lists/*
    
RUN pip3 install meson

RUN mkdir -p ~/ffmpeg_sources ~/bin \
    && cd ~

# install nasm
RUN cd ~/ffmpeg_sources && \
    wget https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2 && \
    tar xjvf nasm-2.15.05.tar.bz2 && \
    cd nasm-2.15.05 && \
    ./autogen.sh && \
    PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
    make -j $BUILD_CORES && \
    make install

# libav1d
RUN cd ~/ffmpeg_sources && \
    git clone --depth 1 https://code.videolan.org/videolan/dav1d.git && \
    mkdir -p dav1d/build && \
    cd dav1d/build && \
    PATH="$HOME/bin:$PATH" meson setup -Denable_tools=false -Denable_tests=false --default-library=static .. --prefix "$HOME/ffmpeg_build" --libdir="$HOME/ffmpeg_build/lib" && \
    ninja -j $BUILD_CORES && \
    ninja install

# libaom
RUN cd ~/ffmpeg_sources && \
    git clone --depth 1 https://aomedia.googlesource.com/aom && \
    mkdir -p aom_build && \
    cd aom_build && \
    PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_TESTS=OFF -DENABLE_NASM=on ../aom && \
    PATH="$HOME/bin:$PATH" make -j $BUILD_CORES && \
    make install 

# libsvtav1
RUN cd ~/ffmpeg_sources && \
    git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
    mkdir -p SVT-AV1/build && \
    cd SVT-AV1/build && \
    PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF .. && \
    PATH="$HOME/bin:$PATH" make -j $BUILD_CORES && \
    make install

# install nvheaders
RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
    && cd nv-codec-headers && git checkout sdk/8.1 \
    && make -j $BUILD_CORES && make install

RUN cd ~/ffmpeg_sources && \
    wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar xjvf ffmpeg-snapshot.tar.bz2 && \
    cd ffmpeg && \
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="$HOME/ffmpeg_build" --pkg-config-flags="--static" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib -L/usr/local/cuda/lib64" \
    --extra-cflags="-I$HOME/ffmpeg_build/include -I/usr/local/cuda/include" \
    --extra-libs="-lpthread -lm" --ld="g++" --bindir="$HOME/bin" --enable-gpl --enable-gnutls \
    --enable-libaom --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame \
    --enable-libopus --enable-libsvtav1 --enable-libdav1d --enable-libvorbis --enable-libvpx \
    --enable-libx264 --enable-libx265 --enable-nonfree --enable-cuda-nvcc --enable-libnpp  && \
    PATH="$HOME/bin:$PATH" make -j $BUILD_CORES && make install

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES video,compute,utility

RUN mv $HOME/bin/ffmpeg /bin/ffmpeg && \
    mv $HOME/bin/ffplay /bin/ffplay && \
    mv $HOME/bin/ffprobe /bin/ffprobe
RUN ls -al ~/bin && ffmpeg -version