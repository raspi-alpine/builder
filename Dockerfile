FROM debian:bullseye-slim AS build_base

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

FROM alpine:3.15 as keys
RUN apk add --no-cache alpine-keys

FROM alpine:edge

RUN sed -E -e "s/^(.*community)/\1\n\1/" -e "s/(.*)community/\1testing/" -i /etc/apk/repositories

RUN apk add --no-cache --upgrade dosfstools e2fsprogs-extra findutils \
	genimage git m4 mtools pigz u-boot-tools

ADD ./resources /resources
COPY --from=uboot /uboot/ /uboot/
COPY --from=uboot_tool /uboot_tool /uboot_tool
COPY --from=keys /usr/share/apk/keys /usr/share/apk/keys-stable

RUN install /resources/scripts/find-deps.sh /usr/local/bin/find-deps && \
    install /resources/scripts/find-mods.sh /usr/local/bin/find-mods 

WORKDIR /work

CMD ["/bin/sh", "/resources/build.sh"]
