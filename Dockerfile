FROM alpine:3.10

RUN apk update && \
    apk add automake build-base git autoconf confuse-dev linux-headers \
            findutils mtools e2fsprogs-extra alpine-sdk dosfstools && \
    rm -rf /var/cache/apk/*

RUN git clone https://github.com/pengutronix/genimage.git /tmp/genimage && \
    cd /tmp/genimage && \
    ./autogen.sh && \
    ./configure CFLAGS='-g -O0' --prefix=/usr && \
    make install && \
    cd && \
    rm -rf /tmp/genimage


ADD ./resources/genext2fs /genext2fs

RUN cd /genext2fs && \
    abuild-keygen -a -i -q && \
    abuild -F -P /tmp/pkg && \
    apk add /tmp/pkg/x86_64/genext2fs-1*.apk && \
    rm -rf /tmp/pkg/

ADD ./resources /resources

WORKDIR /work
