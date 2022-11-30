#!/bin/sh

# make sure have latest image version if not passed as variable
# first try github
if [ -z "$DOCKIMAGE" ]; then
  DOCKIMAGE=ghcr.io/raspi-alpine/builder
  if ! docker image pull "$DOCKIMAGE"; then
    # fallback to gitlab if github fails
    DOCKIMAGE=registry.gitlab.com/raspi-alpine/builder/master
    docker image pull "$DOCKIMAGE"
  fi
fi
docker run --rm -it -v "$PWD"/input:/input -v "$PWD"/output:/output --env-file megaind.env "$DOCKIMAGE"
