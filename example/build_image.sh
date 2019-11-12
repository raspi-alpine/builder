#!/bin/sh

docker run --rm -v "$PWD":/work -w /work -e GOOS=linux -e GOARCH=arm -e GOARM=5 golang:1.13-alpine go build -v -o ./app .

docker run --rm -it -v "$PWD":/input -v $PWD:/output bboehmke/raspi-alpine-builder