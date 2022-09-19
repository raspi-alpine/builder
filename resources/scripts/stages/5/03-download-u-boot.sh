#!/bin/sh

# download u-boot if needed
[ -n "${UBOOT_PACKAGE}" ] && UBOOT_POSTFIX="-${UBOOT_PACKAGE}"

if [ -n "${UBOOT_VERSION}" ]; then
  _UV="-v ${UBOOT_VERSION}"
  colour_echo "checking u-boot version" "$Cyan"
  if ! _GITLAB_VERSION="$(gitlab_packages -p ${UBOOT_PROJ_ID} -l)"; then
    colour_echo "Problem checking version" "$Red"
    echo "$_GITLAB_VERSION"
    exit 1
  fi
  [ "${UBOOT_VERSION}" != "$_GITLAB_VERSION" ] && UB_DOWNLOAD="YES"
fi
if [ "${UBOOT_PROJ_ID}" != "$DEFAULT_UBOOT_PROJ_ID" ] || [ -n "$UB_DOWNLOAD" ]; then
  ab_cache -p /uboot${UBOOT_POSTFIX} -s gitlab_packages -a "$_UV -p ${UBOOT_PROJ_ID} -a u-boot${UBOOT_POSTFIX}-blob -d /uboot${UBOOT_POSTFIX}"
fi

colour_echo "copy uboot${UBOOT_POSTFIX} binaries" "$Cyan"
cp /uboot${UBOOT_POSTFIX}/* ${BOOTFS_PATH}/
