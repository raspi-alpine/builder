ARG DVER=3.15
FROM docker.io/alpine:$DVER AS uboot-base

RUN apk add --no-cache curl

COPY resources/scripts/latest-pkg.sh /usr/local/bin/latest-pkg

FROM uboot-base AS uboot

# Project ID for raspi-alpine/crosscompile-uboot
RUN PROJ_ID="32838267" \
&&  V="$(latest-pkg "$PROJ_ID")" \
&&  F="u-boot-blob-$V.tar.bz2" \
&&  wget "https://gitlab.com/api/v4/projects/$PROJ_ID/packages/generic/uboot/$V/$F" \
&&  wget "https://gitlab.com/api/v4/projects/$PROJ_ID/packages/generic/uboot/$V/$F.sha256" \
&&  sha256sum -c "$F.sha256" \
&&  mkdir uboot \
&&  tar -xvjf "$F" -C uboot

FROM uboot-base as uboot_tool

# Project ID for raspi-alpine/crosscompile-uboot-tool
RUN PROJ_ID="33098050" \
&&  V="$(latest-pkg "$PROJ_ID")" \
&&  F="uboot-tool-$V.tar.bz2" \
&&  echo "Fetching version: $V, with name $F" \
&&  wget "https://gitlab.com/api/v4/projects/$PROJ_ID/packages/generic/uboot-tool/$V/$F" \
&&  wget "https://gitlab.com/api/v4/projects/$PROJ_ID/packages/generic/uboot-tool/$V/$F.sha256" \
&&  sha256sum -c "$F.sha256" \
&&  tar -xvjf "$F"

FROM docker.io/alpine:$DVER as keys
RUN apk add --no-cache alpine-keys

FROM docker.io/alpine:edge

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
