ARG UB_PROJ_ID=32838267
ARG ALPINE_VER=3.20
####
FROM docker.io/alpine:$ALPINE_VER AS uboot-base

RUN apk add --no-cache curl
COPY resources/scripts/build-helpers/gitlab_packages.sh /usr/local/bin/gitlab_packages

####
FROM uboot-base AS uboot
ARG UB_PROJ_ID
# Project ID for raspi-alpine/crosscompile-uboot
RUN gitlab_packages -p "$UB_PROJ_ID" -a u-boot-blob -d uboot \
&&  gitlab_packages -p "$UB_PROJ_ID" -a u-boot-silent-blob -d uboot-silent

####
FROM uboot-base AS uboot_tool

# Project ID for raspi-alpine/crosscompile-uboot-tool
RUN PROJ_ID="33098050" \
&&  gitlab_packages -p "$PROJ_ID" -a uboot-tool

####
FROM docker.io/alpine:$ALPINE_VER AS keys

RUN apk add alpine-keys

####
FROM docker.io/alpine:$ALPINE_VER
LABEL org.opencontainers.image.description="Create minimal Linux images based on Alpine Linux for the Raspberry PI"
LABEL org.opencontainers.image.licenses="Apache-2.0"
ARG UB_PROJ_ID
ENV DEFAULT_UBOOT_PROJ_ID=$UB_PROJ_ID

RUN apk add --no-cache --upgrade curl dosfstools e2fsprogs-extra findutils \
	genimage git m4 mtools pigz tar u-boot-tools

ADD ./resources /resources
COPY --from=uboot /uboot/ /uboot/
COPY --from=uboot /uboot-silent/ /uboot-silent/
COPY --from=uboot_tool /uboot_tool /uboot_tool
COPY --from=keys /usr/share/apk/keys /usr/share/apk/keys-stable

RUN find /resources/scripts/build-helpers -name "*.sh" -exec install -t /usr/local/bin/ {} \; \
&&  cd /usr/local/bin && for file in *.sh; do mv -- "$file" "$(basename "$file" .sh)"; done \
&&  echo "installed:" && ls /usr/local/bin

WORKDIR /work

CMD ["/bin/sh", "/resources/build.sh"]
