FROM debian:bullseye AS build_base

RUN apt-get update && \
    apt-get install -y bc bison build-essential device-tree-compiler flex \
	gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi git libssl-dev wget

FROM build_base AS uboot

RUN mkdir /uboot_build/ && \
    mkdir /uboot/

WORKDIR /uboot_build/

ENV UBOOT_VERSION=2021.10

RUN wget http://ftp.denx.de/pub/u-boot/u-boot-${UBOOT_VERSION}.tar.bz2 && \
    tar -xjf u-boot-${UBOOT_VERSION}.tar.bz2

WORKDIR /uboot_build/u-boot-${UBOOT_VERSION}/

# model a/b/zero
RUN make CROSS_COMPILE=arm-linux-gnueabi- distclean && \
    make CROSS_COMPILE=arm-linux-gnueabi- rpi_defconfig && \
    make CROSS_COMPILE=arm-linux-gnueabi- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi1.bin

# model zero w
RUN make CROSS_COMPILE=arm-linux-gnueabi- distclean && \
    make CROSS_COMPILE=arm-linux-gnueabi- rpi_0_w_defconfig && \
    make CROSS_COMPILE=arm-linux-gnueabi- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi0_w.bin

# model 2 b
RUN make CROSS_COMPILE=arm-linux-gnueabi- distclean && \
    make CROSS_COMPILE=arm-linux-gnueabi- rpi_2_defconfig && \
    make CROSS_COMPILE=arm-linux-gnueabi- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi2.bin

# model 3 (32 bit)
RUN make CROSS_COMPILE=arm-linux-gnueabi- distclean && \
    make CROSS_COMPILE=arm-linux-gnueabi- rpi_3_32b_defconfig && \
    make CROSS_COMPILE=arm-linux-gnueabi- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi3.bin

# model 4 (32 bit)
RUN make CROSS_COMPILE=arm-linux-gnueabi- distclean && \
    make CROSS_COMPILE=arm-linux-gnueabi- rpi_4_32b_defconfig && \
    make CROSS_COMPILE=arm-linux-gnueabi- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi4.bin

# 64 bit
RUN make CROSS_COMPILE=aarch64-linux-gnu- distclean && \
    make CROSS_COMPILE=aarch64-linux-gnu- rpi_arm64_defconfig && \
    make CROSS_COMPILE=aarch64-linux-gnu- -j8 u-boot.bin && \
    cp u-boot.bin /uboot/u-boot_rpi-64.bin

FROM build_base AS uboot_tool

ADD ./resources/uboot.c /uboot.c

RUN arm-linux-gnueabi-gcc -Wall -static -static-libgcc -o /uboot_tool /uboot.c


FROM alpine:3.14

RUN apk add --no-cache --upgrade alpine-sdk autoconf automake build-base confuse-dev \
	dosfstools e2fsprogs-extra findutils git linux-headers mtools pigz sudo uboot-tools

RUN git clone https://github.com/pengutronix/genimage.git /tmp/genimage && \
    cd /tmp/genimage && \
    ./autogen.sh && \
    ./configure CFLAGS='-g -O0' --prefix=/usr && \
    make install && \
    cd && \
    rm -rf /tmp/genimage


ADD ./resources/genext2fs /genext2fs

RUN cd /genext2fs && \
    echo | abuild-keygen -a -i -q && \
    abuild -F checksum && \
    abuild -F -P /tmp/pkg && \
    apk add /tmp/pkg/$(abuild -A)/genext2fs-1*.apk && \
    rm -rf /tmp/pkg/

ADD ./resources /resources
COPY --from=uboot /uboot/ /uboot/
COPY --from=uboot_tool /uboot_tool /uboot_tool

WORKDIR /work

CMD ["/bin/sh", "/resources/build.sh"]
