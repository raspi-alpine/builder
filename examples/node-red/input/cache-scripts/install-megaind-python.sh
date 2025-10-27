#!/bin/sh

# install megaind python library
cd /tmp/megaind-rpi/python || exit 1
python3 -m build --no-isolation --wheel
python3 -m installer ./dist/*.whl
